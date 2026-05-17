---
name: model-pricing
description: >
  Pricing tables for Tinker, Claude, and OpenAI API models (inference, training, caching, batch).
  Trigger whenever the user is estimating costs for API-based workflows — evals, training runs,
  grading, inference budgets, model cost comparisons, or any "how much will this cost" question.
---

# Model Pricing Reference

All prices are **USD per million tokens (MTok)** unless otherwise noted.
Pricing data was last verified in **May 2026**. If a user mentions a model not listed here
or explicitly asks to check for updated pricing, consult the official pages:

- **Tinker**: https://tinker-docs.thinkingmachines.ai/tinker/models/ (or https://thinkingmachines.ai/tinker/)
- **Claude (Anthropic)**: https://platform.claude.com/docs/en/about-claude/pricing
- **OpenAI**: https://developers.openai.com/api/docs/pricing

Do NOT visit these links by default — only if the user asks about a model not in this file,
or explicitly requests a live pricing check.

---

## Tinker (Thinking Machines Lab)

Tinker is a training API for fine-tuning open-source models via LoRA. Pricing has three
columns: **Prefill** (processing input tokens, forward pass only), **Sample** (generating
output tokens, forward + sampling), and **Train** (forward + backward pass for gradient
computation). Storage is charged at $0.10/GB-month.

MoE models are priced by active parameters, making them cheaper than dense models of
similar total size.

Models with a `:peft:` suffix support extended context at higher prices (listed as a
separate row below the base context entry).

| Model | Tinker ID | Arch | Context | Prefill | Sample | Train |
|---|---|---|---|---|---|---|
| Nemotron-3-Nano-30B-A3B-BF16 (50% off) | nvidia/NVIDIA-Nemotron-3-Nano-30B-A3B-BF16 | MoE | 64K | $0.13 | $0.33 | $0.40 |
| Nemotron-3-Super-120B-A12B-BF16 (50% off) | nvidia/NVIDIA-Nemotron-3-Super-120B-A12B-BF16 | MoE | 64K | $0.38 | $0.96 | $1.16 |
|   ↳ extended context | nvidia/NVIDIA-Nemotron-3-Super-120B-A12B-BF16:peft:262144 | MoE | 256K | $0.76 | $1.92 | $2.32 |
| Qwen3.6-35B-A3B | Qwen/Qwen3.6-35B-A3B | MoE | 64K | $0.36 | $0.89 | $1.07 |
| Qwen3.6-27B | Qwen/Qwen3.6-27B | Dense | 64K | $1.24 | $3.73 | $3.73 |
| Qwen3.5-4B | Qwen/Qwen3.5-4B | Dense | 64K | $0.22 | $0.67 | $0.67 |
| Qwen3.5-27B | Qwen/Qwen3.5-27B | Dense | 64K | $1.24 | $3.73 | $3.73 |
| Qwen3.5-35B-A3B | Qwen/Qwen3.5-35B-A3B | MoE | 64K | $0.36 | $0.89 | $1.07 |
| Qwen3.5-397B-A17B | Qwen/Qwen3.5-397B-A17B | MoE | 64K | $2.00 | $5.00 | $6.00 |
|   ↳ extended context | Qwen/Qwen3.5-397B-A17B:peft:262144 | MoE | 256K | $4.00 | $10.00 | $12.00 |
| Qwen3-4B-Instruct-2507 | Qwen/Qwen3-4B-Instruct-2507 | Dense | 32K | $0.07 | $0.22 | $0.22 |
| Qwen3-8B | Qwen/Qwen3-8B | Dense | 32K | $0.13 | $0.40 | $0.40 |
| Qwen3-30B-A3B | Qwen/Qwen3-30B-A3B | MoE | 32K | $0.12 | $0.30 | $0.36 |
| Qwen3-VL-30B-A3B-Instruct | Qwen/Qwen3-VL-30B-A3B-Instruct | MoE | 32K | $0.18 | $0.44 | $0.53 |
| Qwen3-32B | Qwen/Qwen3-32B | Dense | 32K | $0.49 | $1.47 | $1.47 |
| Qwen3-235B-A22B-Instruct-2507 | Qwen/Qwen3-235B-A22B-Instruct-2507 | MoE | 32K | $0.68 | $1.70 | $2.04 |
| Qwen3-VL-235B-A22B-Instruct | Qwen/Qwen3-VL-235B-A22B-Instruct | MoE | 32K | $1.02 | $2.56 | $3.07 |
| Llama-3.2-1B | meta-llama/Llama-3.2-1B | Dense | 32K | $0.03 | $0.09 | $0.09 |
| Llama-3.2-3B | meta-llama/Llama-3.2-3B | Dense | 32K | $0.06 | $0.18 | $0.18 |
| Llama-3.1-8B | meta-llama/Llama-3.1-8B | Dense | 32K | $0.13 | $0.40 | $0.40 |
| Llama-3.1-70B | meta-llama/Llama-3.1-70B | Dense | 32K | $1.05 | $3.16 | $3.16 |
| DeepSeek-V3.1 | deepseek-ai/DeepSeek-V3.1 | MoE | 32K | $1.13 | $2.81 | $3.38 |
| GPT-OSS-120B | openai/gpt-oss-120b | MoE | 32K | $0.18 | $0.44 | $0.52 |
|   ↳ extended context | openai/gpt-oss-120b:peft:131072 | MoE | 128K | $0.63 | $1.54 | $1.82 |
| GPT-OSS-20B | openai/gpt-oss-20b | MoE | 32K | $0.12 | $0.30 | $0.36 |
| Kimi-K2-Thinking | moonshotai/Kimi-K2-Thinking | MoE | 32K | $0.98 | $2.44 | $2.93 |
| Kimi-K2.5 | moonshotai/Kimi-K2.5 | MoE | 32K | $1.47 | $3.66 | $4.40 |
|   ↳ extended context | moonshotai/Kimi-K2.5:peft:131072 | MoE | 128K | $5.15 | $12.81 | $15.40 |
| Kimi-K2.6 | moonshotai/Kimi-K2.6 | MoE | 32K | $1.47 | $3.66 | $4.40 |
|   ↳ extended context | moonshotai/Kimi-K2.6:peft:131072 | MoE | 128K | $5.15 | $12.81 | $15.40 |

**Note on Tinker IDs:** These are the strings you pass to `create_lora_training_client(base_model=...)` or `create_sampling_client(base_model=...)`. Some models also have a `-Base` or `-Instruct` variant (e.g. `Qwen/Qwen3-8B-Base`, `meta-llama/Llama-3.1-8B-Instruct`); check the docs page if needed.

---

## Claude (Anthropic)

Claude models are accessed via the Anthropic Messages API, Amazon Bedrock, and Vertex AI.
Prices below are for the **first-party API**. Bedrock/Vertex may differ slightly (regional
endpoints add a 10% premium).

### Standard Pricing

| Model | API Model ID | Input | Output | Context | Max Output |
|---|---|---|---|---|---|
| Claude Opus 4.7 | claude-opus-4-7 | $5.00 | $25.00 | 1M | 128K |
| Claude Opus 4.6 | claude-opus-4-6 | $5.00 | $25.00 | 1M | 128K |
| Claude Opus 4.5 | claude-opus-4-5-20250929 | $5.00 | $25.00 | 1M | 128K |
| Claude Opus 4.1 | claude-opus-4-1-20250620 | $15.00 | $75.00 | 200K | 64K |
| Claude Sonnet 4.6 | claude-sonnet-4-6 | $3.00 | $15.00 | 1M | 64K |
| Claude Sonnet 4.5 | claude-sonnet-4-5-20250929 | $3.00 | $15.00 | 200K | 64K |
| Claude Haiku 4.5 | claude-haiku-4-5-20251001 | $1.00 | $5.00 | 200K | 64K |
| Claude Haiku 3.5 (retired on 1st-party; Bedrock/Vertex only) | claude-3-5-haiku-20241022 | $0.80 | $4.00 | 200K | 8K |

### Prompt Caching

Caching lets you reuse long prefixes across calls. Write cost is higher; read (hit) cost
is much lower.

| Model | 5-min Cache Write | 1-hr Cache Write | Cache Hit / Refresh |
|---|---|---|---|
| Opus 4.7 / 4.6 / 4.5 | $6.25 | $10.00 | $0.50 |
| Sonnet 4.6 / 4.5 | $3.75 | $6.00 | $0.30 |
| Haiku 4.5 | $1.25 | $2.00 | $0.10 |

### Batch API

The Message Batches API processes requests asynchronously at **50% of standard pricing**.
For example, Sonnet 4.6 batch: $1.50 input / $7.50 output.

### Extended Output (Beta)

Opus 4.7/4.6 and Sonnet 4.6 support up to **300K output tokens** via the Batches API
with the `output-300k-2026-03-24` beta header.

---

## OpenAI

All prices below are **Standard tier** per million tokens. OpenAI also offers:
- **Batch API**: 50% off standard pricing (24-hour turnaround).
- **Flex processing**: Same as Batch rates, variable latency.
- **Priority processing**: ~2x standard pricing for lower latency (select models).
- **Prompt caching**: Discounts vary — GPT-5.x family gets ~90% off cached input;
  GPT-4.1 family ~75% off; GPT-4o/o-series ~50% off. Cache persists 5–10 min.

### Flagship / Current Models

| Model | Input | Cached Input | Output | Context |
|---|---|---|---|---|
| gpt-5.5 | $5.00 | $0.50 | $30.00 | 1M (short ctx pricing shown; long ctx 2x input, 1.5x output) |
| gpt-5.5-pro | $30.00 | — | $180.00 | 1M |
| gpt-5.4 | $2.50 | $0.25 | $15.00 | 1M (short ctx pricing shown) |
| gpt-5.4-mini | $0.75 | $0.075 | $4.50 | 128K |
| gpt-5.4-nano | $0.20 | $0.02 | $1.25 | 128K |

### Previous-Generation Models

| Model | Input | Cached Input | Output | Context |
|---|---|---|---|---|
| gpt-4.1 | $2.00 | $0.50 | $8.00 | 1M |
| gpt-4.1-mini | $0.40 | $0.10 | $1.60 | 1M |
| gpt-4.1-nano | $0.10 | $0.025 | $0.40 | 1M |
| gpt-4o | $2.50 | $1.25 | $10.00 | 128K |
| gpt-4o-mini | $0.15 | $0.075 | $0.60 | 128K |

### Legacy / Completions

| Model | Input | Output | Context |
|---|---|---|---|
| davinci-002 | $2.00 | $2.00 | 16K |

---

## Quick Cost Estimation Tips

When helping users estimate costs:

1. **Factor in prompt caching — but only when it's actually enabled.** Caching is
   usually the single biggest cost lever for eval-style workloads, but it works
   differently across providers:
   - **OpenAI**: Caching is **automatic** — no code changes needed. Any prompt ≥1024
     tokens with a repeated prefix gets cached pricing automatically. So for OpenAI
     cost estimates, you can generally assume caching applies when there's a shared
     prefix (e.g. a constant system prompt across eval calls).
   - **Claude (Anthropic)**: Caching is **opt-in**. The code must explicitly include
     `cache_control` breakpoints in the API request (either per-block or via the
     "automatic caching" mode, which still requires a top-level `cache_control` field).
     Only factor in cached-input pricing if the user's code explicitly uses prompt
     caching, or if you're advising them to add it.
   When caching is active, the savings are large: Claude cache hits cost ~90% less than
   base input (e.g. Sonnet 4.6: $0.30 vs $3.00/MTok). OpenAI discounts are 75–90%
   depending on model family. This can easily change a cost estimate by 5–10x on the
   input side.

2. **Identify the operation.** Inference (input + output tokens)? Training (Tinker uses
   per-token train pricing)? Evaluation (many inference calls)?

3. **Estimate token counts.** A typical English word ≈ 1.3 tokens. A 1-page document
   ≈ 500–800 tokens. A 10K-example eval with ~500 tokens input + ~200 tokens output
   per example = ~5M input tokens + ~2M output tokens.

4. **Calculate.** `cost = (input_tokens / 1M × input_price) + (output_tokens / 1M × output_price)`.
   For Tinker training: `cost = tokens_processed / 1M × train_price`.

5. **Batch API (only if the user asks or latency is irrelevant).** Both Claude and OpenAI
   offer a Batch/async API at 50% off standard pricing with ~24h turnaround. Don't
   default to suggesting this — most people want real-time results — but mention it if
   the user is specifically looking for ways to cut costs and can tolerate the delay.

6. **If the user's model isn't listed,** check the official pricing pages linked at the top
   of this file.