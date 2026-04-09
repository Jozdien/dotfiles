---
name: tinker-api
description: Use whenever the user mentions Tinker, tinker-cookbook, or wants to fine-tune/train/sample from open-weight LLMs (Qwen, Llama, DeepSeek, etc.) via the Tinker API. Covers SL, RL (PPO, GRPO, DPO, RLHF), custom losses, renderers, checkpointing, logprobs, vision models, and the OpenAI-compatible inference endpoint.
---

# Tinker API

Tinker is a training API for LLM fine-tuning from Thinking Machines Lab. You write a training loop that runs on your CPU-only machine (data, environment, loss function). Tinker handles distributed GPU training on the backend. It supports LoRA fine-tuning of open-weight models (Qwen3, Llama3, DeepSeek, etc.), including vision-language models.

**Docs:** https://tinker-docs.thinkingmachines.ai
**LLM-friendly docs:** https://tinker-docs.thinkingmachines.ai/llms-full.txt
**Cookbook repo:** https://github.com/thinking-machines-lab/tinker-cookbook

## Installation

```bash
# The core SDK
uv add tinker

# The cookbook (clone + editable install, NOT a pip/uv package)
git clone https://github.com/thinking-machines-lab/tinker-cookbook.git
cd tinker-cookbook
uv pip install -e .
```

**Important:** `tinker-cookbook` is NOT available as a standalone package on PyPI. You cannot `uv add tinker-cookbook` or `pip install tinker-cookbook`. You must clone the repo and do an editable install (`uv pip install -e .`). The cookbook provides renderers, hyperparameter utilities, training loop abstractions, example recipes, and evaluation tooling.

Set the API key: `export TINKER_API_KEY=<your key>` (get one from https://tinker-console.thinkingmachines.ai).

## Core Architecture

Tinker has three main client objects:

1. **`ServiceClient`** — Entry point. Creates training and sampling clients. Near-instant.
2. **`TrainingClient`** — Corresponds to a fine-tuned model. Runs `forward_backward`, `optim_step`, saves/loads checkpoints. Creation takes a moment (allocates GPU resources).
3. **`SamplingClient`** — Generates text from a base model or fine-tuned checkpoint.

Plus a **`RestClient`** for listing checkpoints, downloading weights, publishing models, etc.

## Quick Reference: Minimal Training + Sampling

```python
import tinker
from tinker import types
import numpy as np

# 1. Connect
service_client = tinker.ServiceClient()

# 2. Create a training client (LoRA fine-tuning)
training_client = service_client.create_lora_training_client(
    base_model="Qwen/Qwen3-30B-A3B",  # or any supported model
    rank=32,  # LoRA rank, default 32
)
tokenizer = training_client.get_tokenizer()

# 3. Prepare data as Datum objects
#    Each Datum has: model_input (tokens) + loss_fn_inputs (targets, weights, etc.)
prompt_tokens = tokenizer.encode("Translate: hello\nResult:", add_special_tokens=True)
completion_tokens = tokenizer.encode(" hola\n\n", add_special_tokens=False)
tokens = prompt_tokens + completion_tokens
weights = [0]*len(prompt_tokens) + [1]*len(completion_tokens)

input_tokens = tokens[:-1]
target_tokens = tokens[1:]  # Next-token prediction: targets are shifted by 1
weights = weights[1:]

datum = types.Datum(
    model_input=types.ModelInput.from_ints(tokens=input_tokens),
    loss_fn_inputs=dict(weights=weights, target_tokens=target_tokens),
)

# 4. Train
for step in range(10):
    fwdbwd_future = training_client.forward_backward([datum], "cross_entropy")
    optim_future = training_client.optim_step(types.AdamParams(learning_rate=1e-4))
    fwdbwd_result = fwdbwd_future.result()
    optim_result = optim_future.result()

    logprobs = np.concatenate([o['logprobs'].tolist() for o in fwdbwd_result.loss_fn_outputs])
    w = np.array(weights)
    print(f"Step {step}: loss = {-np.dot(logprobs, w) / w.sum():.4f}")

# 5. Sample from trained model
sampling_client = training_client.save_weights_and_get_sampling_client(name="my-model")
prompt = types.ModelInput.from_ints(tokenizer.encode("Translate: goodbye\nResult:"))
params = types.SamplingParams(max_tokens=20, temperature=0.0, stop=["\n"])
result = sampling_client.sample(prompt=prompt, sampling_params=params, num_samples=4).result()
for seq in result.sequences:
    print(tokenizer.decode(seq.tokens))
```

## Key Concepts

### Datum (Training Data Format)

Every training example is a `types.Datum` with:
- `model_input`: a `ModelInput` (token sequence, possibly with image chunks for VLMs)
- `loss_fn_inputs`: a dict of tensors consumed by the loss function (e.g., `target_tokens`, `weights`, `logprobs`, `advantages`)

Tensors can be numpy arrays or torch tensors.

### Futures (Non-Blocking API)

Most Tinker methods return a `Future`. The request is submitted immediately; call `.result()` to block until done.

**Critical performance pattern:** Submit `forward_backward` and `optim_step` before waiting on either. Tinker operates on ~10s clock cycles — if you don't have a request queued when a cycle starts, you miss it.

```python
# GOOD: overlap requests
fwdbwd_future = training_client.forward_backward(data, "cross_entropy")
optim_future = training_client.optim_step(adam_params)  # submit immediately
fwdbwd_result = fwdbwd_future.result()  # now wait
optim_result = optim_future.result()

# BAD: sequential (wastes clock cycles)
fwdbwd_result = training_client.forward_backward(data, "cross_entropy").result()
optim_result = training_client.optim_step(adam_params).result()
```

### Async API

Every method has an `_async` variant for asyncio:
```python
future = await client.forward_backward_async(data, loss_fn)
result = await future  # double-await pattern
```

### Loss Functions

Built-in losses (pass as string to `forward_backward`):

| Loss | Use Case | Required `loss_fn_inputs` |
|------|----------|--------------------------|
| `"cross_entropy"` | Supervised learning | `target_tokens`, `weights` |
| `"importance_sampling"` | On-policy RL (REINFORCE) | `target_tokens`, `logprobs` (sampling), `advantages` |
| `"ppo"` | PPO clipped objective | Same as importance_sampling |
| `"cispo"` | CISPO (clipped IS for PG) | Same as importance_sampling |
| `"dro"` | Direct Reward Optimization | Same as importance_sampling |

PPO/CISPO accept `loss_fn_config` for clip thresholds:
```python
training_client.forward_backward(data, "ppo", loss_fn_config={"clip_low_threshold": 0.9, "clip_high_threshold": 1.1})
```

DRO accepts a `beta` parameter:
```python
training_client.forward_backward(data, "dro", loss_fn_config={"beta": 0.05})
```

**Custom loss functions** via `forward_backward_custom`:
```python
def my_loss(data, logprobs):
    loss = ...  # arbitrary differentiable function of logprobs
    return loss, {"my_metric": loss.item()}

training_client.forward_backward_custom(data, my_loss)
```
This costs ~1.5x FLOPs (extra forward pass) and up to 3x wall time vs built-in losses.

### Renderers (Chat Templates for Training)

Tinker's renderers (from `tinker_cookbook`) convert message lists to token sequences with per-token loss weights. They handle the full lifecycle: supervised data prep, generation prompts, response parsing.

```python
from tinker_cookbook import renderers, tokenizer_utils, model_info

tokenizer = tokenizer_utils.get_tokenizer("Qwen/Qwen3-30B-A3B")
renderer_name = model_info.get_recommended_renderer_name("Qwen/Qwen3-30B-A3B")
renderer = renderers.get_renderer(renderer_name, tokenizer)

messages = [
    {"role": "system", "content": "Be concise."},
    {"role": "user", "content": "What is 2+2?"},
    {"role": "assistant", "content": "4."},
]

# For supervised learning: get tokens + loss weights
model_input, weights = renderer.build_supervised_example(messages)

# For sampling: get a generation prompt
prompt = renderer.build_generation_prompt(messages[:-1])
stop_sequences = renderer.get_stop_sequences()

# Parse sampled tokens back to a message
message, success = renderer.parse_response(sampled_tokens)
```

Default renderers produce tokens identical to HuggingFace `apply_chat_template`. This matters if you plan to use the OpenAI-compatible inference endpoint.

### Vision / Multimodal

For VLMs (e.g., `Qwen/Qwen3-VL-30B-A3B-Instruct`), use `ImageChunk` in `ModelInput`:

```python
import requests
from tinker import types

image_data = requests.get("https://example.com/image.png").content
model_input = tinker.ModelInput(chunks=[
    types.EncodedTextChunk(tokens=tokenizer.encode("<|im_start|>user\n<|vision_start|>")),
    types.ImageChunk(data=image_data, format="png"),
    types.EncodedTextChunk(tokens=tokenizer.encode("<|vision_end|>What is this?<|im_end|>\n<|im_start|>assistant\n")),
])
```

Or use the higher-level `Qwen3VLRenderer` / `Qwen3VLInstructRenderer` which handles special tokens automatically:

```python
from tinker_cookbook.renderers import Message, TextPart, ImagePart

messages = [
    Message(role="user", content=[
        ImagePart(type="image", image="https://example.com/img.png"),
        TextPart(type="text", text="What is this?"),
    ])
]
prompt = renderer.build_generation_prompt(messages)
```

## Saving, Loading, and Checkpoints

```python
# Save for sampling (lightweight, weights only)
sampling_client = training_client.save_weights_and_get_sampling_client(name="step-100")

# Save full state (weights + optimizer, for resuming training)
path = training_client.save_state(name="step-100").result().path  # "tinker://..."

# Resume training from full state
training_client = service_client.create_training_client_from_state_with_optimizer(path)

# Load weights into existing client
training_client.load_state(path)
```

## Sampling and Logprobs

```python
# Basic sampling
prompt = types.ModelInput.from_ints(tokenizer.encode("Hello"))
params = types.SamplingParams(max_tokens=100, temperature=0.7, stop=[tokenizer.eos_token_id])
result = sampling_client.sample(prompt, sampling_params=params, num_samples=8).result()

# Compute logprobs for a given sequence (prefill)
logprobs = sampling_client.compute_logprobs(prompt).result()

# Top-k logprobs per position
result = sampling_client.sample(
    prompt, num_samples=1,
    sampling_params=types.SamplingParams(max_tokens=1),
    include_prompt_logprobs=True,
    topk_prompt_logprobs=5,
).result()
# result.topk_prompt_logprobs: list of [(token_id, logprob), ...] per position
```

## OpenAI-Compatible Inference Endpoint

After saving a sampler checkpoint, you can query it via the OpenAI API:

```python
from openai import OpenAI

client = OpenAI(
    base_url="https://tinker.thinkingmachines.dev/services/tinker-prod/oai/api/v1",
    api_key=os.getenv("TINKER_API_KEY"),
)

# Use a tinker:// sampler path as the "model"
response = client.completions.create(
    model="tinker://<run-id>/sampler_weights/<checkpoint>",
    prompt="The capital of France is",
    max_tokens=50, temperature=0.7,
)
# Also supports /chat/completions (uses HF chat template on the server)
```

## Downloading Weights

```python
rest_client = service_client.create_rest_client()
url_response = rest_client.get_checkpoint_archive_url_from_tinker_path(
    sampling_client.model_path
).result()
# url_response.url is a signed download URL
# Download as .tar.gz:
import requests
with open("model.tar.gz", "wb") as f:
    f.write(requests.get(url_response.url).content)
```

## Available Models

Check programmatically:
```python
for m in service_client.get_server_capabilities().supported_models:
    print(m.model_name)
```

Key model families (as of the docs): Qwen3 (including Qwen3.5, Qwen3-VL), Llama 3.x, DeepSeek V3.1, OpenAI gpt-oss, Kimi K2. MoE models are more cost-effective. Use Instruction/Hybrid models for task-specific fine-tuning; Base models for full post-training pipelines.

## Hyperparameter Guidance

### Learning Rate
Most important hyperparameter. Tinker cookbook provides a utility:
```python
from tinker_cookbook.hyperparam_utils import get_lr
lr = get_lr("meta-llama/Llama-3.1-8B")  # returns recommended LR
```

LoRA requires ~10-100x higher LR than full fine-tuning (varies by model size). The optimal LR does NOT depend on LoRA rank.

### Batch Size
Smaller batches (e.g., 128) tend to give better SL fine-tuning performance at the cost of longer training. Aim for ≥100 training steps.

### LoRA Rank
Default 32. For RL, small ranks work as well as large ranks. For SL on large datasets, increase rank so that LoRA param count ≥ number of completion tokens. Check with:
```python
from tinker_cookbook.hyperparam_utils import get_lora_param_count
get_lora_param_count("meta-llama/Llama-3.1-8B", lora_rank=32)
```

## Cookbook Recipes

The cookbook (`tinker_cookbook/recipes/`) has ready-to-run examples. These require the cloned cookbook repo:

```bash
# Supervised learning (basic)
python -m tinker_cookbook.recipes.sl_basic

# Supervised learning (minimal loop, no abstractions)
python -m tinker_cookbook.recipes.sl_loop

# RL on GSM8K (math reasoning)
python -m tinker_cookbook.recipes.rl_basic

# RL (minimal loop, no abstractions)
python -m tinker_cookbook.recipes.rl_loop
```

Additional recipes in the repo: chat SL (Tulu3), math reasoning RL, preference learning (RLHF pipeline), tool use, prompt distillation, multi-agent RL.

## Common Patterns

### SL with Renderer (Recommended)
```python
from tinker_cookbook.supervised.data import conversation_to_datum

datum = conversation_to_datum(
    messages,        # list of {"role": ..., "content": ...}
    renderer,
    max_length=32768,
    train_on_what=renderers.TrainOnWhat.ALL_ASSISTANT_MESSAGES,
)
```

### RL Training Loop (Sketch)
```python
for iteration in range(num_iters):
    # 1. Sample rollouts
    sampling_client = training_client.save_weights_and_get_sampling_client(name=str(iteration))
    prompts = [renderer.build_generation_prompt(msgs) for msgs in batch]
    rollouts = [sampling_client.sample(p, sampling_params=params, num_samples=group_size) for p in prompts]

    # 2. Score rollouts with reward function
    rewards = [reward_fn(rollout) for rollout in rollouts]

    # 3. Compute advantages (e.g., group-centered: subtract mean reward per prompt)
    # 4. Build Datum objects with target_tokens, sampling logprobs, advantages
    # 5. forward_backward with "ppo" or "importance_sampling"
    # 6. optim_step
```

### Computing KL Penalty for Rewards
The cookbook's `incorporate_kl_penalty` function can add a KL term to the reward (mathematically correct alternative to the GRPO-style KL regularization in the loss).

## Gotchas and Tips

1. **Clock cycles:** Tinker training runs on ~10s clock cycles. Always overlap `forward_backward` and `optim_step` submissions to avoid wasting cycles.
2. **Sampling is nondeterministic** even at temperature=0 due to batching. Use multiple samples and majority voting for evaluation.
3. **Token shifting:** For cross-entropy, targets must be shifted by 1 from inputs (next-token prediction). `input_tokens = tokens[:-1]`, `target_tokens = tokens[1:]`, `weights = weights[1:]`.
4. **Renderer compatibility:** If you'll use the OpenAI-compatible endpoint for inference, use default renderers to ensure token compatibility with HF chat templates.
5. **LoRA LR scaling:** Don't reuse your full-finetuning LR for LoRA — it needs to be much higher. Use `get_lr()` or `get_lora_lr_over_full_finetune_lr()`.
6. **All losses sum token-level losses** over sequence length (not mean). Adjust advantages accordingly if you want different aggregation.
7. **tinker-cookbook is not a standalone package** — clone the repo and `uv pip install -e .`.

## Further Documentation

For the full API reference (all method signatures, types, and parameters), consult:
- https://tinker-docs.thinkingmachines.ai/llms-full.txt (LLM-optimized single file)
- https://tinker-docs.thinkingmachines.ai/ (rendered docs site)
- The `docs/` folder in the tinker-cookbook repo mirrors the docs site