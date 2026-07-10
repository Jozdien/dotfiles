---
name: tinker
description: "Use this skill whenever the user wants to train, fine-tune, or do inference with language models using the Tinker API. Trigger on any mention of 'tinker' or when the user wants to do LoRA fine-tuning, supervised fine-tuning (SFT), reinforcement learning (RL), DPO, RLHF, distillation, or preference learning on open-weight models like Qwen, DeepSeek, Kimi, Nemotron, or GPT-OSS using a managed training API."
---

# Tinker API

Tinker is a managed training API from [Thinking Machines Lab](https://thinkingmachines.ai/tinker/). You write the training loop in Python on your machine — data, loss function, logic — and Tinker runs the GPU computation on distributed clusters. LoRA fine-tuning only (default rank 32). Facts here were verified 2026-07-10; the model lineup and prices drift, so check the docs when currency matters.

**Docs:** https://tinker-docs.thinkingmachines.ai/tinker/ · [Cookbook](https://tinker-docs.thinkingmachines.ai/cookbook/) · [Tutorials](https://tinker-docs.thinkingmachines.ai/tutorials/) · [Changelog](https://tinker-docs.thinkingmachines.ai/changelog/)
**GitHub:** [SDK](https://github.com/thinking-machines-lab/tinker) · [Cookbook](https://github.com/thinking-machines-lab/tinker-cookbook)
**Official Claude Code skills:** `/plugin marketplace add thinking-machines-lab/tinker-cookbook` installs [`/tinker:research`](https://github.com/thinking-machines-lab/tinker-cookbook/tree/main/skills/research) (research workflow + 10 API reference files) and [`/tinker:debug`](https://github.com/thinking-machines-lab/tinker-cookbook/tree/main/skills/debug) (triage for slow training, output mismatch vs vLLM/SGLang, service errors, renderer bugs). Reach for those references when this file isn't deep enough — but note their model list predates the June 2026 retirements.

## Setup

```bash
uv pip install tinker            # SDK + `tinker` CLI
uv pip install tinker-cookbook   # cookbook as a library (includes SDK);
                                 # or clone the repo + `pip install -e .` to run/modify recipes
export TINKER_API_KEY="..."      # from the console: https://tinker.thinkingmachines.ai
```

| Env var | Purpose |
|---|---|
| `TINKER_API_KEY` | Required |
| `HF_TOKEN` | Gated HF datasets/models (e.g. GPQA), publishing to the Hub |
| `WANDB_API_KEY` | Optional W&B logging (`wandb_project` in train configs) |
| `TINKER_PROJECT_ID` | Default project for new runs |
| `TINKER_SUBPROCESS_SAMPLING=1` | Avoid GIL contention when reward computation is CPU-heavy |

Smoke test: `tinker.ServiceClient().create_lora_training_client(base_model="Qwen/Qwen3-8B", rank=32).get_info()`

## What to use for what

Two layers. The **SDK** (`import tinker`) gives primitives — `forward_backward`, `optim_step`, `sample`, `save_state` — for custom loops and novel algorithms. The **cookbook** (`tinker_cookbook`) supplies renderers, datasets, environments, training loops, evals, and export. Default to the cookbook for standard workflows; check `tinker_cookbook/recipes/` first — most tasks have a working recipe to modify rather than build from zero.

| Task | Start from | Depth |
|---|---|---|
| SFT on chat/instruction data | `tinker_cookbook.supervised.train` + `recipes/chat_sl/` | [SFT docs](https://tinker-docs.thinkingmachines.ai/cookbook/supervised-learning/), [tutorial](https://tinker-docs.thinkingmachines.ai/tutorials/basics/first-sft/) |
| RL with verifiable rewards (GRPO) | `tinker_cookbook.rl.train` + `recipes/math_rl/`, `code_rl/` | [RL docs](https://tinker-docs.thinkingmachines.ai/cookbook/rl/), [tutorial](https://tinker-docs.thinkingmachines.ai/tutorials/basics/first-rl/) |
| Multi-turn / tool-use RL | `MessageEnv` + `recipes/search_tool/`, `harbor_rl/`, `multiplayer_rl/` | [Custom envs](https://tinker-docs.thinkingmachines.ai/tutorials/cookbook-abstractions/custom-environment/) |
| DPO | `tinker_cookbook.preference.train_dpo` | [DPO guide](https://tinker-docs.thinkingmachines.ai/cookbook/preferences/dpo-guide/) |
| RLHF (SFT → RM → RL) | `recipes/preference/` | [RLHF example](https://tinker-docs.thinkingmachines.ai/cookbook/preferences/rlhf-example/) |
| Distillation (on-policy or SFT-on-traces) | `tinker_cookbook.distillation` + `recipes/distillation/` | [recipes](https://tinker-docs.thinkingmachines.ai/cookbook/recipes/) |
| Benchmark a checkpoint | `tinker_cookbook.eval.benchmarks` | [Eval docs](https://tinker-docs.thinkingmachines.ai/cookbook/eval/) |
| Custom loss / novel algorithm | raw SDK loop, `forward_backward_custom` | [Losses](https://tinker-docs.thinkingmachines.ai/tinker/losses/) |
| Export / serve weights | `tinker_cookbook.weights`, CLI, OpenAI-compatible endpoint | [Export](https://tinker-docs.thinkingmachines.ai/tutorials/deployment/export-hf/) |

Other recipes: prompt distillation, rubric grading, verifiers RL, VLM classifier, SDFT, true-thinking score, plus minimal `sl_basic.py`/`rl_basic.py` starting points.

## Models

Model IDs follow the HuggingFace convention (`base_model="Qwen/Qwen3-8B"`). Live list: `service_client.get_server_capabilities().supported_models` or https://tinker-docs.thinkingmachines.ai/tinker/models/ (now a merged "Models & Pricing" page).

Lineup as of 2026-07-10:

| Family | Models |
|---|---|
| Qwen | Qwen3.6-35B-A3B (MoE, V), Qwen3.6-27B (V), Qwen3.5-397B-A17B (MoE, V), Qwen3.5-35B-A3B-Base (MoE), Qwen3.5-9B (V), Qwen3.5-9B-Base, Qwen3.5-4B (V), Qwen3-8B |
| Moonshot | Kimi-K2.6 (MoE, reasoning, V); Kimi-K2.5 retires 2026-07-12 |
| NVIDIA | Nemotron-3 Nano-30B-A3B / Super-120B-A12B / Ultra-550B-A55B (all `NVIDIA-...-BF16`, MoE hybrid) |
| OpenAI | GPT-OSS-120B, GPT-OSS-20B (MoE, reasoning) |
| DeepSeek | DeepSeek-V3.1 (MoE, hybrid) |

(V) = vision. Extended context via `:peft:` suffix (e.g. `openai/gpt-oss-120b:peft:131072`): Nemotron Super/Ultra and Qwen3.5-397B to 256K, Kimi and GPT-OSS-120B to 128K, at ~2-4x base price.

**Retired June 12, 2026:** all Llama models, Kimi-K2-Thinking, DeepSeek-V3.1-Base, the dedicated Qwen3-VL models, and all Qwen3.0 models except Qwen3-8B. Replacement mapping: https://tinker-docs.thinkingmachines.ai/tinker/model-deprecations/ (roughly: Llama instruct → Qwen3.5-9B or Qwen3.6-27B; small bases → Qwen3.5-9B-Base / Qwen3.5-35B-A3B-Base; 30B-class → Qwen3.6-35B-A3B).

**Model type drives training decisions:**

| Type | Implications | Examples |
|---|---|---|
| Base | No instruction following out of the box; full post-training pipeline | Qwen3.5-9B-Base, Qwen3.5-35B-A3B-Base |
| Reasoning | Always emits chain-of-thought; needs high `max_tokens`; training data should include thinking | GPT-OSS, Kimi-K2.6 |
| Hybrid | Thinking and non-thinking modes — the renderer variant selects the mode, and the wrong one silently corrupts training | Qwen3.x, DeepSeek-V3.1, Nemotron-3 |
| Vision | Needs a VL renderer + `image_processor` | Qwen3.5/3.6 models, Kimi-K2.6 |

**Cost:** MoE models are priced by active params — Qwen3.6-35B-A3B (3B active: $0.36/$0.89/$1.07 prefill/sample/train per MTok) undercuts Qwen3.6-27B dense ($1.24/$3.73/$3.73) at similar quality, so prefer MoE. Full tables live in the **model-pricing** skill. Nemotron prices are a limited-time 50% discount.

## Core SDK

```python
import tinker
from tinker import types

service_client = tinker.ServiceClient()
training_client = service_client.create_lora_training_client(
    base_model="Qwen/Qwen3-8B", rank=32,   # also: train_mlp/train_attn/train_unembed flags
)
tokenizer = training_client.get_tokenizer()
sampling_client = service_client.create_sampling_client(base_model="Qwen/Qwen3-8B")  # or model_path="tinker://..."
```

The SDK retries failed HTTP calls itself (10 attempts, exponential backoff) — do not add retry wrappers. Client errors (400/401/404/422) raise immediately. All methods have `_async` variants returning futures.

### forward_backward — and the token-shifting rule

For next-token prediction, targets and weights are the input sequence **shifted by one**. Getting this wrong silently trains on garbage:

```python
all_tokens  = prompt_tokens + completion_tokens
all_weights = [0]*len(prompt_tokens) + [1]*len(completion_tokens)
datum = types.Datum(
    model_input=types.ModelInput.from_ints(tokens=all_tokens[:-1]),
    loss_fn_inputs=dict(target_tokens=all_tokens[1:], weights=all_weights[1:]),
)
future = await training_client.forward_backward_async(data=[datum], loss_fn="cross_entropy")
result = await future.result_async()   # .metrics, .loss_fn_outputs (per-datum logprobs etc.)
```

In practice, let the cookbook build datums (it handles shifting): `conversation_to_datum(...)` or `renderer.build_supervised_example(...)` — see SFT below. `forward()` is the no-gradient variant for held-out loss only — never in a training loop.

### optim_step, pipelining, and clock cycles

Tinker's backend runs on clock cycles; a `forward_backward` + `optim_step` executes each cycle, and an empty queue misses the cycle. **Submit requests back-to-back before awaiting** — this is the #1 performance lever ([under the hood](https://tinker-docs.thinkingmachines.ai/tinker/under-the-hood/)):

```python
fb_future = await training_client.forward_backward_async(data, "cross_entropy")
optim_future = await training_client.optim_step_async(types.AdamParams(learning_rate=lr))
next_batch = prepare_batch(i + 1)          # CPU work overlaps GPU work
fb_result = await fb_future.result_async()
optim_result = await optim_future.result_async()
```

Same principle for sampling and evals: batch prompts with `asyncio.gather`, use `num_samples=k`, never a sequential loop.

### sample and logprobs

```python
prompt = types.ModelInput.from_ints(tokenizer.encode("The capital of France is"))
result = await sampling_client.sample_async(
    prompt=prompt, num_samples=4,
    sampling_params=types.SamplingParams(max_tokens=256, temperature=0.7, stop=["\n"]),
)
result.sequences[0].tokens / .logprobs / .stop_reason   # stop_reason: "length" | "stop"

logprobs = await sampling_client.compute_logprobs_async(prompt)     # score without generating (RL)
# Top-k per-position logprobs (distillation): include_prompt_logprobs=True, topk_prompt_logprobs=5
```

Sampling is nondeterministic even at temperature=0 (batching effects) — use multiple samples/majority voting for evals.

### Checkpoints

Two kinds: **state** (`save_state`) = weights + optimizer, for resuming; **sampler** (`save_weights_for_sampler`) = weights only, for inference/export. `save_weights_and_get_sampling_client(name=...)` is the in-loop shortcut for eval-while-training (ephemeral — not durably saved).

```python
training_client.save_state(name="step-100")                       # → tinker://.../weights/...
sc = training_client.save_weights_and_get_sampling_client(name="ckpt-1")
training_client = await service_client.create_training_client_from_state_with_optimizer_async(path="tinker://...")
```

Cookbook helpers handle the bookkeeping (`checkpoints.jsonl` in the log dir):

```python
from tinker_cookbook import checkpoint_utils
await checkpoint_utils.save_checkpoint_async(training_client=tc, name="step_100",
    log_path=log_path, loop_state={"batch": 100}, kind="both")
record = checkpoint_utils.get_last_checkpoint(log_path)            # → resume from record.state_path
```

Record every `tinker://` path in the project's checkpoint log (per CLAUDE.md) — paths are painful to rediscover later, and checkpoints can have TTLs.

## SFT

Cookbook path: renderer + dataset builder + `supervised.train.Config`. Key knobs: `learning_rate` (use `get_lr`), `lr_schedule` (`"linear"` usual), `num_epochs`, `batch_size` (**in tokens**, 128 default), `train_on_what`.

```python
from tinker_cookbook import model_info, renderers, tokenizer_utils
from tinker_cookbook.supervised.data import conversation_to_datum

model = "Qwen/Qwen3-8B"
renderer = renderers.get_renderer(model_info.get_recommended_renderer_name(model),
                                  tokenizer_utils.get_tokenizer(model))
datum = conversation_to_datum(
    [{"role": "user", "content": "What is 2+2?"}, {"role": "assistant", "content": "4."}],
    renderer, max_length=32768,
    train_on_what=renderers.TrainOnWhat.ALL_ASSISTANT_MESSAGES,   # or LAST_ASSISTANT_MESSAGE, ALL_TOKENS, CUSTOMIZED, ...
)   # reduction="mean" by default: per-example weights normalized to sum to 1; "none" = raw token-sum loss
```

For a full training run use `tinker_cookbook.supervised.train.Config` with a dataset builder — built-ins `NoRobotsBuilder`/`Tulu3Builder`, your own JSONL via `FromConversationFileBuilder(file_path="data.jsonl")` (lines of `{"messages": [...]}`), or `SupervisedDatasetFromHFDataset`. Configs are `chz` classes → CLI-overridable and serialized to `config.json`. See [SFT with config](https://tinker-docs.thinkingmachines.ai/tutorials/cookbook-abstractions/sft-with-config/).

**Before training on any new dataset:** decode 3-5 built datums back to text and read them — check role markers, BOS/EOS, and that `weights` mask exactly the completion tokens. Data formatting is the top source of silent bugs.

## RL

GRPO-style: for each problem, sample `group_size` rollouts, compute rewards, center advantages **within the group**, update with an off-policy-corrected loss.

Cookbook path — implement an env, wrap in builders, run `rl.train.Config`:

- **`ProblemEnv`** (single-turn Q→A): implement `get_question`, `check_answer`, `check_format`, `get_reference_answer`. Reward = `check_answer + format_coef*(check_format - 1)`. `require_stop_sequence_for_format=True` makes format require a clean stop.
- **`MessageEnv`** (multi-turn / tools): implement `initial_observation() -> list[Message]` and `step(message) -> MessageStepResult(reward, episode_done, next_messages, metrics, logs)`; bridge with `EnvFromMessageEnv(renderer=..., message_env=..., max_trajectory_tokens=...)`.
- Envs are **single-use** (one episode; no reset) — builders create fresh ones. `EnvGroupBuilder.compute_group_rewards` supports group-level scoring; `cleanup()` for sandboxes. `AsyncConfig(max_steps_off_policy=...)` enables async off-policy rollouts for slow envs.

Raw-SDK path (custom algorithms) — build datums from rollouts yourself:

```python
rl_datum = types.Datum(
    model_input=types.ModelInput.from_ints(tokens=tokens),
    loss_fn_inputs=dict(
        target_tokens=target_tokens, weights=weights,
        logprobs=sampling_logprobs,   # from the rollout policy
        advantages=advantages,        # reward - group baseline
    ),
)
await training_client.forward_backward_async([rl_datum], "importance_sampling")
```

Then re-save weights and **create a new sampling client** each iteration. Watch `kl_sample_train_v1` in metrics — stable training keeps KL < 0.01.

## Loss functions

Built-in losses **sum** token-level losses (no mean) — scale weights/advantages if you want different aggregation.

| `loss_fn` | Use | Required `loss_fn_inputs` |
|---|---|---|
| `"cross_entropy"` | SFT | `target_tokens`, `weights` |
| `"importance_sampling"` | RL default | `target_tokens`, `logprobs`, `advantages` |
| `"ppo"` | RL, clipped | same; `loss_fn_config={"clip_low_threshold": 0.9, "clip_high_threshold": 1.1}` |
| `"cispo"` | RL, clipped IS | same as ppo |
| `"dro"` | direct reward optimization | same; `loss_fn_config={"beta": 0.05}` |

**Custom losses** via `forward_backward_custom(data, fn)` — `fn(data, logprobs) -> (loss, metrics)`, any differentiable function of logprobs. Costs ~1.5x FLOPs and up to ~3x wall time vs built-ins (extra forward pass). Math: https://tinker-docs.thinkingmachines.ai/tinker/losses/

## Preference learning

**DPO** (`preference.train_dpo`): chosen/rejected conversation pairs via `DPODatasetBuilderFromComparisons` + a `ComparisonBuilder` (built-ins: HHH, HelpSteer3, UltraFeedback; custom = return `list[(chosen_messages, rejected_messages)]`). Start `dpo_beta=0.1`, LR ~1e-5 (much lower than SFT), and **start from an SFT checkpoint**, not a raw base. Implemented as a custom loss, so expect the custom-loss overhead. [Guide](https://tinker-docs.thinkingmachines.ai/cookbook/preferences/dpo-guide/) · [tutorial](https://tinker-docs.thinkingmachines.ai/tutorials/advanced/dpo-preferences/)

**RLHF** (`recipes/preference/`): SFT → reward model (supervised on comparisons via `ChatDatasetBuilderFromComparisons`) → RL against the RM (`PairwisePreferenceRLDatasetBuilder` + `PreferenceModelBuilderFromChatRenderer`). Stages chain by checkpoint: SFT **state** initializes RL, RM **sampler** weights provide the reward. Validate RM accuracy before stage 3. `incorporate_kl_penalty` adds KL-to-reference to the reward (the mathematically clean alternative to in-loss KL). [Example](https://tinker-docs.thinkingmachines.ai/cookbook/preferences/rlhf-example/)

## Distillation

`tinker_cookbook.distillation.train_on_policy`: student samples, teacher scores via per-token KL — the KL penalty is the only supervision (`kl_penalty_coef=1.0`, `kl_discount_factor=0.0`; raise the discount for long sequences). `TeacherConfig(base_model=..., load_checkpoint_path=...)` + `PromptOnlyDatasetBuilder(dataset_name="deepmath" | "tulu3", ...)` bound together in `DistillationDatasetConfig`; pass several configs for multi-teacher. Use higher LoRA rank (~128) and LR ~1e-4. Off-policy distillation = plain SFT on teacher-generated traces (`recipes/distillation/off_policy_reasoning.py`).

## Renderers

Renderers convert chat messages ↔ tokens: chat template, loss masks, stop sequences, response parsing, vision. **Always resolve automatically** — a mismatched renderer (or the wrong thinking-mode variant of the right one) silently degrades training:

```python
renderer_name = model_info.get_recommended_renderer_name(model_name)   # never hardcode
```

Variants encode thinking mode: e.g. `qwen3_5` vs `qwen3_5_disable_thinking`, `kimi_k26[_disable_thinking|_preserve_thinking]`, `gpt_oss_{low,medium,high}_reasoning`, `nemotron3[_disable_thinking]`. Pick `_disable_thinking` for direct-answer behavior from hybrid models. Default renderers match HF `apply_chat_template` token-for-token (matters if serving via the OpenAI-compatible endpoint later).

Key methods: `build_generation_prompt(messages)`, `build_supervised_example(messages) -> (ModelInput, weights)`, `get_stop_sequences()`, `parse_response(tokens)`, `parse_response_streaming(tokens)`, `create_conversation_prefix_with_tools(tool_specs)`.

**Breaking change (cookbook ≥0.4.0):** `parse_response` returns `tuple[Message, ParseTermination]`, not `(Message, bool)`. `ParseTermination` is a StrEnum (`STOP_SEQUENCE`/`EOS`/`MALFORMED`) — every value is truthy, so old `if not success:` checks silently never fire. Use `termination.is_clean` (or `.is_stop_sequence` for strict format checks).

**Vision:** pass content parts — `{"role": "user", "content": [{"type": "image", "image_url": "..."}, {"type": "text", "text": "..."}]}` — with a VL renderer and `image_processor` passed to `get_renderer()`. Low-level: `types.ImageChunk(data=image_bytes, format="png")` inside `ModelInput(chunks=[...])`.

**Completers** wrap sampling for reuse across backends: `TinkerTokenCompleter` (tokens + logprobs; RL rollouts) and `TinkerMessageCompleter` (messages in/out; evals, tool loops). Recreate them after saving weights — they hold a sampling client. [Tutorial](https://tinker-docs.thinkingmachines.ai/tutorials/core-concepts/completers/)

## Evaluation

Set up eval **before** training and get a baseline score. Registered benchmarks (in `tinker_cookbook/eval/benchmarks/`): gsm8k, math500, aime, hmmt, mmlu_pro, mmlu_redux, gpqa (needs `HF_TOKEN`), ceval, supergpqa, ifeval, ifbench, arena_hard, bfcl, longbench, livecodebench, mbpp, swe_bench, tau2_bench, terminal_bench (code/agentic ones need a sandbox).

```python
from tinker_cookbook.eval.benchmarks import run_benchmarks, BenchmarkConfig, load_trajectories
results = await run_benchmarks(["gsm8k", "ifeval"], sampling_client, renderer,
                               BenchmarkConfig(save_dir="evals/step500"))       # .for_model(name) = tuned defaults
wrong = load_trajectories("evals/step500", "gsm8k", incorrect_only=True)        # read failures, not just scores
```

Results persist as `trajectories.jsonl` + `result.json`; interrupted runs resume (examples matched by content hash). During training, pass `evaluator_builders=[lambda: BenchmarkEvaluator("gsm8k", renderer, max_examples=100)]` + `eval_every=N` to any train Config — scores land in `metrics.jsonl` as `eval/<name>/score`. Custom evaluators are async callables `(SamplingClient) -> dict[str, float]` (or `TrainingClient` for NLL-style); custom benchmarks subclass `BenchmarkBuilder` reusing the RL `MessageEnv` protocol. [Inspect AI](https://inspect.aisi.org.uk/) tasks wrap via `InspectAPIFromTinkerSampling`. [Eval tutorial](https://tinker-docs.thinkingmachines.ai/tutorials/core-concepts/evaluations/)

## Monitoring a run

Training writes to `log_path` — check these actively, especially the first ~10 steps:

| File | Contents |
|---|---|
| `metrics.jsonl` | Per-step scalars: loss, `entropy`, `kl_sample_train_v1`, `optim/lr`, `env/all/reward/total`, `eval/*/score`, `time/*` |
| `config.json`, `code.diff` | Resolved config + git diff at launch — verify before walking away |
| `checkpoints.jsonl` | Checkpoint records with `tinker://` paths |
| `iteration_NNNNNN/train_rollout_summaries.jsonl` | Per-trajectory rewards (RL) |
| `iteration_NNNNNN/train.html`, `train_logtree.json` | Full rollout transcripts — read actual outputs, not just reward curves |
| `timing_gantt.html`, `trace_events.jsonl` | Per-op timing; Perfetto trace for pipelining diagnosis |

`pd.read_json("metrics.jsonl", lines=True)` for quick plots. Healthy RL: rewards trending up, KL < 0.01, entropy not collapsing, and transcripts showing real capability rather than reward hacking.

## Serving trained models

**Export** (`tinker_cookbook.weights`):

```python
from tinker_cookbook import weights
adapter = weights.download(tinker_path="tinker://run-id/sampler_weights/final", output_dir="./adapter")
weights.build_hf_model(base_model="Qwen/Qwen3-8B", adapter_path=adapter, output_path="./model", dtype="bfloat16")
weights.build_lora_adapter(base_model=..., adapter_path=adapter, output_path="./peft")  # PEFT format for vLLM/SGLang
weights.publish_to_hf_hub(model_path="./model", repo_id="user/my-model", private=True)
```

`download()` needs a **sampler** checkpoint path, not a state path. For output-mismatch debugging vs vLLM/SGLang, use the cookbook merge (not a hand-rolled script) and see `/tinker:debug`.

**OpenAI-compatible endpoint (beta):** `/chat/completions` + `/completions` against base URL `https://tinker.thinkingmachines.dev/services/tinker-prod/oai/api/v1`, with your `tinker://.../sampler_weights/...` path as the `model`. Streaming yields reasoning chunks before answer chunks; `separate_reasoning` defaults true; `reasoning_effort` takes minimal/low/medium/high or a float 0.0-1.0; **no tool calling**. [Docs](https://tinker-docs.thinkingmachines.ai/tinker/compatible-apis/openai/)

**CLI:**

```bash
tinker run list / run info <RUN_ID>            # --format json for scripting
tinker checkpoint list [--run-id ID] / info / download <PATH> -o ./adapter
tinker checkpoint publish / unpublish / set-ttl <PATH> --ttl 86400 / delete <PATH>
tinker checkpoint push-hf <PATH> --repo user/model    # raw adapter; merge via weights.build_hf_model first if needed
```

Cloud checkpoint organization: cookbook `stores/` module + `FsspecStorage` (s3/gs/az) — [storage docs](https://tinker-docs.thinkingmachines.ai/cookbook/storage/).

## Hyperparameters

**Learning rate** is the one that matters most. LoRA needs ~10x the full-fine-tuning LR; optimal LR is independent of rank:

```python
from tinker_cookbook.hyperparam_utils import get_lr, get_lora_param_count
lr = get_lr("Qwen/Qwen3-8B", is_lora=True)     # formula-based; Qwen (and legacy Llama) families only
```

| Scenario | LR | Batch | LoRA rank |
|---|---|---|---|
| SFT | `get_lr()` (~1e-4 to 5e-4) | 128 (tokens!) | 32 |
| RL / GRPO | 1e-5 to 4e-5 | 128 problems x group 4-16 | 32 |
| DPO | ~1e-5 | 256 | 32 |
| Distillation | ~1e-4 | 1024 x group 4 | 128 |

Rules of thumb: LR scales ~sqrt(batch size); aim for ≥100 (ideally 1000+) optimizer steps; smaller SL batches train slower but often land better. For SL on large datasets, size rank so LoRA params (`get_lora_param_count`) ≥ completion tokens; for RL, small ranks match large ones. `lr_schedule`: linear (usual), cosine, constant. RL `num_substeps>1` (minibatch updates) requires PPO; lower LR accordingly. [SL hyperparams](https://tinker-docs.thinkingmachines.ai/tutorials/advanced/sl-hyperparams/) · [RL hyperparams](https://tinker-docs.thinkingmachines.ai/tutorials/advanced/rl-hyperparams/)

## Pitfalls checklist

- **Sequential API calls** — submit `forward_backward_async` + `optim_step_async` before awaiting either; gather sampling calls. The #1 performance mistake.
- **Token shifting** (raw SDK) — inputs `tokens[:-1]`, targets `tokens[1:]`, weights shifted too; prefer cookbook datum builders.
- **Renderer mismatch / wrong thinking variant** — always `get_recommended_renderer_name()`; wrong choice degrades training silently.
- **Sampler desync** — after saving weights, make a *new* sampling client (and new completers); stale ones sample old weights.
- **`parse_response` truthiness** (cookbook ≥0.4.0) — returns `ParseTermination` StrEnum, always truthy; check `.is_clean`, never `if not ok:`.
- **LoRA LR** — ~10x full-fine-tune LR; use `get_lr()`, don't port LRs from papers doing full fine-tuning.
- **`batch_size` is in tokens** for SL, not examples.
- **Loss aggregation** — built-ins sum token losses; cookbook SFT datums default to `reduction="mean"` (weights normalized per example). Know which you're getting before comparing losses or scaling advantages.
- **Advantages are centered per group** — a group with identical rewards contributes zero gradient; degenerate groups (all-correct/all-wrong) waste compute.
- **Envs are single-use** — fresh env per episode via the builder.
- **DPO from an SFT checkpoint**, not a raw base; DPO/RL LRs are ~10-20x lower than SFT.
- **`forward()` ≠ training** — no gradients; eval only.
- **Custom losses cost ~1.5x FLOPs / up to 3x wall time** — relevant for DPO and `forward_backward_custom`.
- **Nondeterministic sampling even at temp 0** — batch effects; use multiple samples for evals.
- **Don't wrap Tinker calls in retries** — the SDK already retries; wrappers compound delays and duplicate work.
- **Verify before scaling** — decode a few datums, run tiny (small model, few steps), check `config.json`/`code.diff`, then launch the real run and watch the first steps in `metrics.jsonl`.

## Advanced topics

[Sequence extension](https://tinker-docs.thinkingmachines.ai/tutorials/advanced/sequence-extension/) (train past context length) · [Multi-agent RL](https://tinker-docs.thinkingmachines.ai/tutorials/advanced/multi-agent/) · [Prompt distillation](https://tinker-docs.thinkingmachines.ai/tutorials/advanced/prompt-distillation/) · [Rendering internals](https://tinker-docs.thinkingmachines.ai/tutorials/core-concepts/rendering/) · [CLI reference](https://tinker-docs.thinkingmachines.ai/tinker/cli/)
