---
name: tinker
description: "Use this skill whenever the user wants to train, fine-tune, or do inference with language models using the Tinker API. Trigger on any mention of 'tinker' or when the user wants to do LoRA fine-tuning, supervised fine-tuning (SFT), reinforcement learning (RL), DPO, RLHF, or preference learning on open-weight models like Llama, Qwen, DeepSeek, Kimi, or GPT-OSS using a managed training API."
---

# Tinker API

Tinker is a managed training API from [Thinking Machines Lab](https://thinkingmachines.ai/tinker/). You write a Python loop on your CPU—your data, loss function, training logic—and Tinker runs the GPU computation across distributed clusters. It uses LoRA fine-tuning exclusively (default rank 32).

**Docs:** https://tinker-docs.thinkingmachines.ai/tinker/
**Cookbook:** https://tinker-docs.thinkingmachines.ai/cookbook/
**Tutorials:** https://tinker-docs.thinkingmachines.ai/tutorials/
**GitHub:** [SDK](https://github.com/thinking-machines-lab/tinker) · [Cookbook](https://github.com/thinking-machines-lab/tinker-cookbook)

## Installation

```bash
uv pip install tinker            # SDK only (import tinker + CLI)
uv pip install tinker-cookbook    # Cookbook (includes SDK)
export TINKER_API_KEY="..."      # Get from https://tinker-console.thinkingmachines.ai
```

## Two-Layer Architecture

**`tinker` (SDK):** Low-level primitives—`forward_backward`, `optim_step`, `sample`, `save_state`. Full control over every step. Use for custom loops or novel algorithms.

**`tinker-cookbook`:** Higher-level abstractions—`SupervisedDataset`, `ChatDatasetBuilder`, `RLDatasetBuilder`, `Env`/`EnvGroupBuilder`, `Renderer`, `Completer`, eval framework, configs. Use for standard SFT/RL/DPO/RLHF workflows.

## Core API

```python
import tinker
from tinker import types

service_client = tinker.ServiceClient()
training_client = service_client.create_lora_training_client(
    base_model="Qwen/Qwen3-8B", rank=32
)
sampling_client = service_client.create_sampling_client(base_model="Qwen/Qwen3-8B")
tokenizer = training_client.get_tokenizer()
```

### forward_backward — compute gradients

**Token shifting is critical:** For next-token prediction, targets must be shifted by 1 from inputs. Weights must also be shifted.

```python
prompt_tokens = tokenizer.encode("Translate: hello\nResult:", add_special_tokens=True)
completion_tokens = tokenizer.encode(" hola", add_special_tokens=False)
all_tokens = prompt_tokens + completion_tokens
all_weights = [0]*len(prompt_tokens) + [1]*len(completion_tokens)

input_tokens = all_tokens[:-1]       # everything except last
target_tokens = all_tokens[1:]       # everything except first (shifted by 1)
weights = all_weights[1:]            # also shifted

datum = types.Datum(
    model_input=types.ModelInput.from_ints(tokens=input_tokens),
    loss_fn_inputs=dict(weights=weights, target_tokens=target_tokens)
)
future = await training_client.forward_backward_async(data=[datum], loss_fn="cross_entropy")
result = await future.result_async()
# result.loss — scalar loss
# result.loss_fn_outputs — list of per-datum dicts with 'logprobs' (for computing custom metrics)
```

### optim_step — update weights

```python
await (await training_client.optim_step_async(
    types.AdamParams(learning_rate=1e-4, beta1=0.9, beta2=0.95, eps=1e-8)
)).result_async()
```

For recommended learning rates (LoRA needs ~10-100x higher LR than full fine-tuning):
```python
from tinker_cookbook.hyperparam_utils import get_lr
lr = get_lr("Qwen/Qwen3-8B")  # returns recommended LR for this model
```

### sample — generate text

```python
prompt = types.ModelInput.from_ints(tokenizer.encode("The capital of France is"))
params = types.SamplingParams(max_tokens=50, temperature=0.7, stop=["\n"])
result = await sampling_client.sample_async(prompt=prompt, num_samples=1, sampling_params=params)
print(tokenizer.decode(result.sequences[0].tokens))
```

### Logprobs

```python
# Prompt logprobs (for RL scoring)
logprobs = await sampling_client.compute_logprobs_async(prompt)

# Top-k logprobs per position (for distillation)
result = await sampling_client.sample_async(
    prompt, num_samples=1,
    sampling_params=types.SamplingParams(max_tokens=1),
    include_prompt_logprobs=True, topk_prompt_logprobs=5,
)
# result.topk_prompt_logprobs: [None, [(token_id, logprob), ...], ...]
```

### save_state / load_state — checkpointing

```python
# Save weights → get sampling client for eval
sampling_client = training_client.save_weights_and_get_sampling_client(name="checkpoint-1")

# Save full state (weights + optimizer) for resuming
training_client.save_state(name="step-100")

# Resume with optimizer state
training_client = await service_client.create_training_client_from_state_with_optimizer_async(
    path="tinker://run-id/weights/step-100"
)
```

## Clock Cycles and Pipelining

Tinker's backend runs on clock cycles — each cycle does a `forward_backward` + `optim_step`. If you don't have a request queued when a cycle starts, you miss it. The practical consequence:

```python
# GOOD: overlap requests — submit both before awaiting either
fwdbwd_future = await training_client.forward_backward_async(data, "cross_entropy")
optim_future = await training_client.optim_step_async(adam_params)  # submit immediately
fwdbwd_result = await fwdbwd_future.result_async()
optim_result = await optim_future.result_async()

# BAD: sequential — wastes clock cycles
fwdbwd_result = (await training_client.forward_backward_async(data, "cross_entropy")).result_async()
await fwdbwd_result
optim_result = (await training_client.optim_step_async(adam_params)).result_async()
await optim_result
```

Also: `sample_async(prompt, num_samples=16)` for multiple samples; `asyncio.gather(...)` for parallel prompts. Set `TINKER_SUBPROCESS_SAMPLING=1` to avoid GIL contention during CPU-heavy reward computation.

See [Clock Cycles & Pipelining](https://tinker-docs.thinkingmachines.ai/tinker/under-the-hood/).

## SFT Workflow

Create `TrainingClient` → tokenize examples into `Datum` objects with loss masks → `forward_backward_async(loss_fn="cross_entropy")` → `optim_step_async` → periodically `save_weights_and_get_sampling_client()` to evaluate.

### Using Cookbook Helpers (Recommended)

```python
from tinker_cookbook.supervised.data import conversation_to_datum
from tinker_cookbook import renderers, tokenizer_utils, model_info

tokenizer = tokenizer_utils.get_tokenizer("Qwen/Qwen3-8B")
renderer_name = model_info.get_recommended_renderer_name("Qwen/Qwen3-8B")
renderer = renderers.get_renderer(renderer_name, tokenizer)

messages = [
    {"role": "user", "content": "What is 2+2?"},
    {"role": "assistant", "content": "4."},
]

# One-liner: messages → Datum
datum = conversation_to_datum(
    messages, renderer, max_length=32768,
    train_on_what=renderers.TrainOnWhat.ALL_ASSISTANT_MESSAGES,
)
```

Renderers also provide lower-level methods:
```python
model_input, weights = renderer.build_supervised_example(messages)  # tokens + loss weights
prompt = renderer.build_generation_prompt(messages[:-1])            # for sampling
stop_sequences = renderer.get_stop_sequences()
message, success = renderer.parse_response(sampled_tokens)          # parse output back
```

See [Cookbook SFT](https://tinker-docs.thinkingmachines.ai/cookbook/supervised-learning/), [First SFT tutorial](https://tinker-docs.thinkingmachines.ai/tutorials/basics/first-sft/), [SFT with Config](https://tinker-docs.thinkingmachines.ai/tutorials/cookbook-abstractions/sft-with-config/).

## RL Workflow

1. Create `TrainingClient`
2. `save_weights_and_get_sampling_client()` → on-policy sampler
3. Sample rollouts, compute rewards and log-probs (`compute_logprobs_async`)
4. Build `Datum` with `logprobs` and `advantages` in `loss_fn_inputs`
5. `forward_backward_async(data, "importance_sampling")` → `optim_step_async`
6. Repeat from 2

```python
rl_datum = types.Datum(
    model_input=types.ModelInput.from_ints(tokens=tokens),
    loss_fn_inputs=dict(
        target_tokens=target_tokens, weights=weights,
        logprobs=sampling_logprobs,  # from the rollout policy
        advantages=advantages,        # reward - baseline
    )
)
```

The cookbook provides `Env`, `MessageEnv`, `ProblemEnv`, `EnvGroupBuilder`, `RLDatasetBuilder`, and `compute_advantages`. See [Cookbook RL](https://tinker-docs.thinkingmachines.ai/cookbook/rl/), [First RL tutorial](https://tinker-docs.thinkingmachines.ai/tutorials/basics/first-rl/), [Env & EnvGroupBuilder](https://tinker-docs.thinkingmachines.ai/tutorials/cookbook-abstractions/env-and-envgroupbuilder/).

## Loss Functions

Pass as `loss_fn` to `forward_backward_async`. All built-in losses **sum** (not mean) token-level losses over the sequence. Adjust advantages accordingly if you want different aggregation.

| Loss | Use Case | Required `loss_fn_inputs` |
|------|----------|--------------------------|
| `"cross_entropy"` | SFT — next-token prediction | `target_tokens`, `weights` |
| `"importance_sampling"` | RL — policy gradient with off-policy correction | `target_tokens`, `logprobs`, `advantages` |
| `"ppo"` | RL — PPO clipped objective | same as importance_sampling |
| `"cispo"` | RL — clipped importance sampling, pessimistic objective | same as importance_sampling |
| `"dro"` | RL — direct reward optimization | same as importance_sampling |

PPO/CISPO accept `loss_fn_config` for clip thresholds:
```python
training_client.forward_backward(data, "ppo", loss_fn_config={"clip_low_threshold": 0.9, "clip_high_threshold": 1.1})
```

DRO accepts a `beta` parameter:
```python
training_client.forward_backward(data, "dro", loss_fn_config={"beta": 0.05})
```

**Custom loss** via `forward_backward_custom_async`. You provide a Python function that receives logprobs and returns a scalar loss. This costs ~1.5x FLOPs (extra forward pass) and up to ~3x wall time vs built-in losses—important to know for DPO and other custom objectives.

```python
def my_loss(data, logprobs):
    loss = ...  # arbitrary differentiable function of logprobs
    return loss, {"my_metric": loss.item()}

training_client.forward_backward_custom(data, my_loss)
```

Math details: https://tinker-docs.thinkingmachines.ai/tinker/losses/

## Preference Learning (DPO / RLHF)

**DPO:** `forward_backward_custom_async` with DPO loss. Uses `Comparison` objects (chosen/rejected pairs). Start with `dpo_beta=0.1`, LR ~1e-5. See [DPO Guide](https://tinker-docs.thinkingmachines.ai/cookbook/preferences/dpo-guide/).

**RLHF:** Three-stage pipeline: (1) SFT, (2) reward model, (3) RL against reward model. The cookbook's `incorporate_kl_penalty` can add a KL term to the reward (mathematically correct alternative to GRPO-style KL regularization in the loss). See [RLHF Example](https://tinker-docs.thinkingmachines.ai/cookbook/preferences/rlhf-example/).

Tutorial: https://tinker-docs.thinkingmachines.ai/tutorials/advanced/dpo-preferences/

## Renderers and Completers

**Renderers** bridge chat-format data to token sequences—chat templates, loss masking, vision inputs. Use `model_info.get_recommended_renderer_name(model)` to pick the right one. **Mismatched renderers silently degrade training.** Default renderers produce tokens identical to HuggingFace `apply_chat_template`—important if you plan to use the OpenAI-compatible endpoint for inference. See [Rendering tutorial](https://tinker-docs.thinkingmachines.ai/tutorials/core-concepts/rendering/).

**Completers** abstract sampling policies. `TinkerTokenCompleter` for token-level, `TinkerMessageCompleter` for message-level chat. See [Completers tutorial](https://tinker-docs.thinkingmachines.ai/tutorials/core-concepts/completers/).

## Evaluation

```python
from tinker_cookbook.eval.benchmarks import run_benchmarks, BenchmarkConfig
results = await run_benchmarks(
    ["gsm8k", "mmlu_pro", "ifeval"], sampling_client, renderer,
    BenchmarkConfig(save_dir="evals/step500"),
)
```

12+ benchmarks: GSM8K, MATH-500, MMLU-Pro, MMLU-Redux, GPQA, IFEval, MBPP, C-Eval, SuperGPQA, IFBench, AIME 2025, AIME 2026. Integrates with Inspect AI. See [Eval docs](https://tinker-docs.thinkingmachines.ai/cookbook/eval/).

## Weight Export and Deployment

```python
from tinker_cookbook.weights import download, build_hf_model, publish_to_hf_hub

download(rest_client, checkpoint_path, output_dir)          # Download LoRA checkpoint
build_hf_model(base_model, lora_dir, output_dir)            # Merge LoRA into base model
publish_to_hf_hub(base_model, lora_dir, repo_id)            # Push to HuggingFace Hub
```

See [Export to HF](https://tinker-docs.thinkingmachines.ai/tutorials/deployment/export-hf/), [Publish to Hub](https://tinker-docs.thinkingmachines.ai/tutorials/deployment/publish-hub/), [Build LoRA Adapter](https://tinker-docs.thinkingmachines.ai/tutorials/deployment/lora-adapter/).

## Vision (VLM) Support

For VLM models (e.g. Qwen3-VL), use `ImageChunk` directly or the higher-level VLM renderers:

```python
# Low-level: manual ImageChunk
model_input = tinker.ModelInput(chunks=[
    types.EncodedTextChunk(tokens=tokenizer.encode("<|im_start|>user\n<|vision_start|>")),
    types.ImageChunk(data=image_bytes, format="png"),
    types.EncodedTextChunk(tokens=tokenizer.encode("<|vision_end|>Describe this image<|im_end|>\n<|im_start|>assistant\n")),
])

# High-level: VLM renderer with Message/ImagePart
from tinker_cookbook.renderers import Message, TextPart, ImagePart
messages = [Message(role="user", content=[
    ImagePart(type="image", image="https://example.com/img.png"),
    TextPart(type="text", text="What is this?"),
])]
prompt = renderer.build_generation_prompt(messages)
```

## OpenAI-Compatible API (Beta)

Tinker provides an OpenAI-compatible inference endpoint for trained models. Use the `tinker://` sampler path as the model name. See [docs](https://tinker-docs.thinkingmachines.ai/tinker/compatible-apis/openai/).

## CLI

```bash
tinker run list              # List training runs
tinker run info <run-id>     # Run details
tinker checkpoint list       # List checkpoints
tinker checkpoint download   # Download checkpoint
```

Full CLI docs: https://tinker-docs.thinkingmachines.ai/tinker/cli/

## Available Models

The Tinker ID (passed to `base_model=...`) uses the HuggingFace convention, e.g. `"Qwen/Qwen3-8B"`, `"meta-llama/Llama-3.1-8B"`. Check programmatically:
```python
for m in service_client.get_server_capabilities().supported_models:
    print(m.model_name)
```

This list may change—check https://tinker-docs.thinkingmachines.ai/tinker/models/ for the latest.

**Qwen** (16 models): Qwen3.6-35B-A3B (MoE), Qwen3.6-27B, Qwen3.5-4B, Qwen3.5-27B, Qwen3.5-35B-A3B (MoE), Qwen3.5-397B-A17B (MoE), Qwen3-4B-Instruct-2507, Qwen3-8B-Base, Qwen3-8B, Qwen3-30B-A3B-Base (MoE), Qwen3-30B-A3B (MoE), Qwen3-30B-A3B-Instruct-2507 (MoE), Qwen3-VL-30B-A3B-Instruct (MoE, Vision), Qwen3-32B, Qwen3-235B-A22B-Instruct-2507 (MoE), Qwen3-VL-235B-A22B-Instruct (MoE, Vision)

**Llama** (6): Llama-3.2-1B, Llama-3.2-3B, Llama-3.1-8B, Llama-3.1-8B-Instruct, Llama-3.1-70B, Llama-3.3-70B-Instruct

**DeepSeek** (2): DeepSeek-V3.1 (MoE), DeepSeek-V3.1-Base (MoE)

**Moonshot** (3): Kimi-K2-Thinking (MoE), Kimi-K2.5 (MoE), Kimi-K2.6 (MoE)

**OpenAI** (2): GPT-OSS-120B (MoE), GPT-OSS-20B (MoE)

**NVIDIA** (2): Nemotron-3-Nano-30B-A3B-BF16 (MoE), Nemotron-3-Super-120B-A12B-BF16 (MoE)

## Pricing (USD per million tokens)

All prices per million tokens. MoE models priced by active parameters. Storage: $0.10/GB-month. **Prices may change—check the [rate card](https://tinker-console.thinkingmachines.ai/rate-card) or [Tinker homepage](https://thinkingmachines.ai/tinker/) for up-to-date pricing.**

| Model | Context | Prefill | Sample | Train |
|-------|---------|---------|--------|-------|
| Nemotron-3-Nano-30B-A3B† | 64K | $0.13 | $0.33 | $0.40 |
| Nemotron-3-Super-120B-A12B† | 64K | $0.38 | $0.96 | $1.16 |
| Nemotron-3-Super-120B-A12B† | 256K | $0.76 | $1.92 | $2.32 |
| Qwen3.6-35B-A3B | 64K | $0.36 | $0.89 | $1.07 |
| Qwen3.6-27B | 64K | $1.24 | $3.73 | $3.73 |
| Qwen3.5-35B-A3B | 64K | $0.36 | $0.89 | $1.07 |
| Qwen3.5-27B | 64K | $1.24 | $3.73 | $3.73 |
| Qwen3.5-397B-A17B | 64K | $2.00 | $5.00 | $6.00 |
| Qwen3.5-397B-A17B | 256K | $4.00 | $10.00 | $12.00 |

†Limited-time 50% discount. Pricing for Qwen3-8B, Llama, DeepSeek, Moonshot, and GPT-OSS models: see the rate card.

**Pricing terms:** Prefill = input tokens (forward only). Sample = output tokens (forward + sampling). Train = forward + backward pass.

## Cookbook Recipes

Ready-to-run recipes in `tinker_cookbook/recipes/`, each with a README and expected results: Chat SL (SFT on Tulu3-style data), Math RL (GSM8K), Code RL, Preference (DPO + RLHF pipeline), Tool Use / Search-R1, Prompt Distillation, Model Distillation (single/multi-teacher), Multi-Agent RL (self-play/cross-play), Rubric Grading, Verifiers RL, VLM Classifier, Harbor RL, Agent RL, SDFT, True-Thinking Score.

Full list: https://tinker-docs.thinkingmachines.ai/cookbook/recipes/

## Hyperparameter Guidance

**Learning rate:** Most important hyperparameter. Use `from tinker_cookbook.hyperparam_utils import get_lr; lr = get_lr(model_name)`. LoRA requires ~10-100x higher LR than full fine-tuning. Optimal LR does NOT depend on LoRA rank.

**LoRA rank:** Default 32. For RL, small ranks work as well as large. For SL on large datasets, increase rank so that LoRA param count ≥ number of completion tokens:
```python
from tinker_cookbook.hyperparam_utils import get_lora_param_count
get_lora_param_count("meta-llama/Llama-3.1-8B", lora_rank=32)
```

**Batch size:** Smaller batches (e.g. 128) tend to give better SL results at the cost of longer training. Aim for ≥100 training steps.

See [SL Hyperparameters](https://tinker-docs.thinkingmachines.ai/tutorials/advanced/sl-hyperparams/), [RL Hyperparameters](https://tinker-docs.thinkingmachines.ai/tutorials/advanced/rl-hyperparams/).

## Advanced Topics

These have dedicated tutorial pages:

- [Sequence Extension](https://tinker-docs.thinkingmachines.ai/tutorials/advanced/sequence-extension/) — training beyond context length
- [Multi-Agent RL](https://tinker-docs.thinkingmachines.ai/tutorials/advanced/multi-agent/) — self-play and cross-play
- [Prompt Distillation](https://tinker-docs.thinkingmachines.ai/tutorials/advanced/prompt-distillation/) — bake system prompts into weights
- [Custom Environments](https://tinker-docs.thinkingmachines.ai/tutorials/cookbook-abstractions/custom-environment/)

## Common Pitfalls

- **Token shifting:** `input_tokens = tokens[:-1]`, `target_tokens = tokens[1:]`, `weights = weights[1:]`. Forgetting this silently trains on garbage.
- **Pipelining:** Submit `forward_backward_async` and `optim_step_async` back-to-back before awaiting. Sequential calls waste clock cycles.
- **Renderer mismatch:** Use `model_info.get_recommended_renderer_name()` — never hardcode. Wrong renderer silently degrades training.
- **Sampler desync:** Always create a new sampling client after saving weights.
- **Type construction:** Use `ModelInput.from_ints()`, `conversation_to_datum()`, `renderer.build_supervised_example()` — not manual dicts.
- **LoRA LR:** Don't reuse full-finetuning LRs for LoRA — it needs to be much higher. Use `get_lr()`.
- **RL group semantics:** Advantages are centered within each group.
- **Loss aggregation:** All built-in losses sum (not mean) token-level losses.
- **Sampling nondeterminism:** Even at temperature=0, sampling can be nondeterministic due to batching. Use multiple samples + majority voting for evals.
- **Custom loss cost:** `forward_backward_custom` costs ~1.5x FLOPs and up to ~3x wall time vs built-in losses.