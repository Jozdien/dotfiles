---
name: model-pricing
description: >
  Pricing tables for Tinker, Claude, and OpenAI API models (inference, training, caching, batch).
  Trigger whenever the user is estimating costs for API-based workflows — evals, training runs,
  grading, inference budgets, model cost comparisons, or any "how much will this cost" question.
---

# Model Pricing Reference

All prices are **USD per million tokens (MTok)** unless otherwise noted.
Pricing data was last verified on **July 10, 2026**. If a user mentions a model not listed here
or explicitly asks to check for updated pricing, consult the official pages:

- **Tinker**: https://tinker-docs.thinkingmachines.ai/tinker/models/ (models + pricing merged into one page; the rate card now requires console login)
- **Claude (Anthropic)**: https://platform.claude.com/docs/en/about-claude/pricing
- **OpenAI**: https://developers.openai.com/api/docs/pricing

Do NOT visit these links by default — only if the user asks about a model not in this file,
or explicitly requests a live pricing check.

---

## Tinker (Thinking Machines Lab)

Tinker is a training API for fine-tuning open-source models via LoRA. Pricing has three
columns: **Prefill** (processing input tokens, forward pass only), **Sample** (generating
output tokens, forward + sampling), and **Train** (forward + backward pass for gradient
computation).

MoE models are priced by active parameters, making them cheaper than dense models of
similar total size.

Models with a `:peft:` suffix support extended context at higher prices (listed as a
separate row below the base context entry).

| Model | Tinker ID | Arch | Context | Prefill | Sample | Train |
|---|---|---|---|---|---|---|
| Nemotron-3-Ultra-550B-A55B-BF16 (50% off, limited time) | nvidia/NVIDIA-Nemotron-3-Ultra-550B-A55B-BF16 | MoE | 64K | $1.66 | $4.15 | $4.98 |
|   ↳ extended context | nvidia/NVIDIA-Nemotron-3-Ultra-550B-A55B-BF16:peft:262144 | MoE | 256K | $3.32 | $8.30 | $9.96 |
| Nemotron-3-Super-120B-A12B-BF16 (50% off, limited time) | nvidia/NVIDIA-Nemotron-3-Super-120B-A12B-BF16 | MoE | 64K | $0.38 | $0.96 | $1.16 |
|   ↳ extended context | nvidia/NVIDIA-Nemotron-3-Super-120B-A12B-BF16:peft:262144 | MoE | 256K | $0.76 | $1.92 | $2.32 |
| Nemotron-3-Nano-30B-A3B-BF16 (50% off, limited time) | nvidia/NVIDIA-Nemotron-3-Nano-30B-A3B-BF16 | MoE | 64K | $0.13 | $0.33 | $0.40 |
| Kimi-K2.6 (vision) | moonshotai/Kimi-K2.6 | MoE | 32K | $1.47 | $3.66 | $4.40 |
|   ↳ extended context | moonshotai/Kimi-K2.6:peft:131072 | MoE | 128K | $5.15 | $12.81 | $15.40 |
| Kimi-K2.5 (**retiring July 12, 2026** → K2.6) | moonshotai/Kimi-K2.5 | MoE | 32K | $1.47 | $3.66 | $4.40 |
| Qwen3.6-35B-A3B (vision) | Qwen/Qwen3.6-35B-A3B | MoE | 64K | $0.36 | $0.89 | $1.07 |
| Qwen3.6-27B (vision) | Qwen/Qwen3.6-27B | Dense | 64K | $1.24 | $3.73 | $3.73 |
| Qwen3.5-397B-A17B (vision) | Qwen/Qwen3.5-397B-A17B | MoE | 64K | $2.00 | $5.00 | $6.00 |
|   ↳ extended context | Qwen/Qwen3.5-397B-A17B:peft:262144 | MoE | 256K | $4.00 | $10.00 | $12.00 |
| Qwen3.5-35B-A3B-Base | Qwen/Qwen3.5-35B-A3B-Base | MoE | 64K | $0.36 | $0.89 | $1.07 |
| Qwen3.5-9B (vision) / 9B-Base | Qwen/Qwen3.5-9B, Qwen/Qwen3.5-9B-Base | Dense | 64K | $0.44 | $1.33 | $1.33 |
| Qwen3.5-4B (vision) | Qwen/Qwen3.5-4B | Dense | 64K | $0.22 | $0.67 | $0.67 |
| Qwen3-8B | Qwen/Qwen3-8B | Dense | 32K | $0.13 | $0.40 | $0.40 |
| GPT-OSS-120B | openai/gpt-oss-120b | MoE | 32K | $0.18 | $0.44 | $0.52 |
|   ↳ extended context | openai/gpt-oss-120b:peft:131072 | MoE | 128K | $0.63 | $1.54 | $1.82 |
| GPT-OSS-20B | openai/gpt-oss-20b | MoE | 32K | $0.12 | $0.30 | $0.36 |
| DeepSeek-V3.1 | deepseek-ai/DeepSeek-V3.1 | MoE | 32K | $1.13 | $2.81 | $3.38 |

**Retired June 12, 2026:** all Llama models, Kimi-K2-Thinking, DeepSeek-V3.1-Base,
Qwen3-8B-Base, and all other Qwen3.0 models (Qwen3-8B is the sole survivor), including the
dedicated Qwen3-VL models. Replacements per model:
https://tinker-docs.thinkingmachines.ai/tinker/model-deprecations/

**Note:** Storage pricing is no longer published on the public models page; the rate card
(tinker.thinkingmachines.ai/rate-card) requires login.

---

## Claude (Anthropic)

Claude models are accessed via the Anthropic Messages API, Amazon Bedrock, and Vertex AI.
Prices below are for the **first-party API**. Bedrock/Vertex regional and multi-region
endpoints add a 10% premium over global endpoints. On the first-party API, requesting US
data residency (`inference_geo: "us"`) adds a 1.1x multiplier on all token categories
(supported on Opus 4.6 / Sonnet 4.6 and later).

### Standard Pricing

| Model | API Model ID | Input | Output | Context | Max Output |
|---|---|---|---|---|---|
| Claude Fable 5 | claude-fable-5 | $10.00 | $50.00 | 1M | 128K |
| Claude Mythos 5 (limited availability) | claude-mythos-5 | $10.00 | $50.00 | 1M | 128K |
| Claude Opus 4.8 | claude-opus-4-8 | $5.00 | $25.00 | 1M | 128K |
| Claude Opus 4.7 (legacy) | claude-opus-4-7 | $5.00 | $25.00 | 1M | 128K |
| Claude Opus 4.6 (legacy) | claude-opus-4-6 | $5.00 | $25.00 | 1M | 128K |
| Claude Opus 4.5 (legacy) | claude-opus-4-5-20251101 | $5.00 | $25.00 | 200K | 64K |
| Claude Opus 4.1 (**deprecated, retires Aug 5, 2026**) | claude-opus-4-1-20250805 | $15.00 | $75.00 | 200K | 32K |
| Claude Sonnet 5 | claude-sonnet-5 | $3.00 (intro **$2.00** through Aug 31, 2026) | $15.00 (intro **$10.00**) | 1M | 128K |
| Claude Sonnet 4.6 (legacy) | claude-sonnet-4-6 | $3.00 | $15.00 | 1M | 128K |
| Claude Sonnet 4.5 (legacy) | claude-sonnet-4-5-20250929 | $3.00 | $15.00 | 200K | 64K |
| Claude Haiku 4.5 | claude-haiku-4-5-20251001 | $1.00 | $5.00 | 200K | 64K |

Notes:
- **No long-context premium**: 1M-context models bill at the same per-token rate across the
  full window (the old >200K-input tier is gone).
- **Tokenizer caveat for cross-model cost comparisons**: Opus 4.7+, Sonnet 5, and Fable/Mythos 5
  use a newer tokenizer that produces ~30% more tokens for the same text than Sonnet 4.6 and
  earlier — equal sticker price ≠ equal cost per character.
- Haiku 3.5 (claude-3-5-haiku) is **retired** on the first-party API (Feb 19, 2026).
- Model IDs from 4.6 onward are dateless pinned snapshots — don't append a date suffix.

### Prompt Caching

Multipliers on base input price: 5-min write = 1.25x, 1-hr write = 2x, cache hit/read = 0.1x.

| Model | 5-min Cache Write | 1-hr Cache Write | Cache Hit / Refresh |
|---|---|---|---|
| Fable 5 / Mythos 5 | $12.50 | $20.00 | $1.00 |
| Opus 4.8 / 4.7 / 4.6 / 4.5 | $6.25 | $10.00 | $0.50 |
| Sonnet 5 (intro, through Aug 31, 2026) | $2.50 | $4.00 | $0.20 |
| Sonnet 5 (from Sept 1, 2026) / Sonnet 4.6 / 4.5 | $3.75 | $6.00 | $0.30 |
| Haiku 4.5 | $1.25 | $2.00 | $0.10 |

### Batch API

The Message Batches API processes requests asynchronously at **50% of standard pricing**
(stacks with caching multipliers). E.g. Sonnet 5 batch: $1.50 input / $7.50 output
(intro: $1/$5); Opus 4.8 batch: $2.50/$12.50; Fable 5 batch: $5/$25.

### Extended Output (Beta)

Opus 4.8/4.7/4.6, Sonnet 5, and Sonnet 4.6 support up to **300K output tokens** via the
Batches API with the `output-300k-2026-03-24` beta header.

### Fast Mode (research preview, first-party API only)

`fast-mode-2026-02-01` beta + `speed: "fast"`: Opus 4.8 at $10/$50 per MTok. (Opus 4.7
fast mode is $30/$150 and is removed July 24, 2026; Opus 4.6 fast mode already removed.)
Not available with Batch.

---

## OpenAI

All prices below are **Standard tier** per million tokens. OpenAI also offers:
- **Batch API**: 50% off standard pricing (24-hour turnaround).
- **Flex processing**: Same as Batch rates, variable latency.
- **Priority processing**: ~2x standard pricing for lower latency (gpt-5.6 tiers, gpt-5.5,
  gpt-5.4, gpt-5.4-mini; short-context rates only).
- **Prompt caching**: Automatic for prompts ≥1024 tokens with a repeated prefix. Cached
  reads are ~90% off input across gpt-5.4/5.5/5.6. **GPT-5.6 changed the model**: cache
  writes now billed at 1.25x input (reported in `cache_write_tokens`), fixed 30-min minimum
  TTL, and explicit `prompt_cache_breakpoint` markers are supported. Pre-5.6 models have no
  write fee (TTL ~5–10 min, up to 1h; 24h extended caching on gpt-5.5 and older).

### Flagship / Current Models

The **GPT-5.6 family** (launched July 9, 2026) uses capability tiers: **Sol** (flagship),
**Terra** (balanced), **Luna** (fast/cheap). All three: ~1M context, 128K max output.
Long-context pricing (input above ~272K tokens): 2x input, 1.5x output — verify the
threshold on the pricing page if it matters; it's not clearly documented.

| Model | Input | Cached Input | Output | Context |
|---|---|---|---|---|
| gpt-5.6-sol (alias gpt-5.6) | $5.00 | $0.50 | $30.00 | 1M (long ctx: $10.00 in / $45.00 out) |
| gpt-5.6-terra | $2.50 | $0.25 | $15.00 | 1M (long ctx: $5.00 in / $22.50 out) |
| gpt-5.6-luna | $1.00 | $0.10 | $6.00 | 1M |
| gpt-5.5 | $5.00 | $0.50 | $30.00 | 1M |
| gpt-5.5-pro | $30.00 | — | $180.00 | 1M |
| gpt-5.4 | $2.50 | $0.25 | $15.00 | 1M |
| gpt-5.4-pro | $30.00 | — | $180.00 | 1M |
| gpt-5.4-mini | $0.75 | $0.075 | $4.50 | 128K |
| gpt-5.4-nano | $0.20 | $0.02 | $1.25 | 128K |

There is no gpt-5.6-mini/-nano — Luna fills the cheap tier.

### Legacy Models (off the main pricing page, still callable)

| Model | Input | Cached Input | Output | Context |
|---|---|---|---|---|
| gpt-4.1 | $2.00 | $0.50 | $8.00 | 1M |
| gpt-4.1-mini | $0.40 | $0.10 | $1.60 | 1M |
| gpt-4o | $2.50 | $1.25 | $10.00 | 128K |
| gpt-4o-mini | $0.15 | $0.075 | $0.60 | 128K |

Notable shutdowns: `gpt-5-*` (original 2025-08-07 snapshots), `o3`, `o3-pro` shut down
Dec 11, 2026; `gpt-5.x-codex` variants and `gpt-5-chat-latest` July 23, 2026;
`gpt-4.1-nano` and `gpt-4o-2024-05-13` snapshots, plus older GPT-4/o1/o3-mini/o4-mini
snapshots, Oct 23, 2026. Check https://developers.openai.com/api/docs/deprecations
before recommending a legacy model.

---

## Quick Cost Estimation Tips

When helping users estimate costs:

1. **Factor in prompt caching — but only when it's actually enabled.** Caching is
   usually the single biggest cost lever for eval-style workloads, but it works
   differently across providers:
   - **OpenAI**: Caching is **automatic** — no code changes needed. Any prompt ≥1024
     tokens with a repeated prefix gets cached pricing automatically. So for OpenAI
     cost estimates, you can generally assume caching applies when there's a shared
     prefix (e.g. a constant system prompt across eval calls). On GPT-5.6+, also budget
     the 1.25x cache-write fee on first-time prefixes.
   - **Claude (Anthropic)**: Caching is **opt-in**. The code must explicitly include
     `cache_control` breakpoints in the API request (either per-block or via the
     "automatic caching" mode, which still requires a top-level `cache_control` field).
     Only factor in cached-input pricing if the user's code explicitly uses prompt
     caching, or if you're advising them to add it.
   When caching is active, the savings are large: cache reads cost ~90% less than base
   input on both providers (e.g. Sonnet 5: $0.30 vs $3.00/MTok). This can easily change
   a cost estimate by 5–10x on the input side.

2. **Identify the operation.** Inference (input + output tokens)? Training (Tinker uses
   per-token train pricing)? Evaluation (many inference calls)?

3. **Estimate token counts.** A typical English word ≈ 1.3 tokens. A 1-page document
   ≈ 500–800 tokens. A 10K-example eval with ~500 tokens input + ~200 tokens output
   per example = ~5M input tokens + ~2M output tokens. Caveat: the newest Claude models
   (Opus 4.7+, Sonnet 5, Fable 5) tokenize ~30% denser-than-before (more tokens per word),
   so scale estimates up when using them.

4. **Calculate.** `cost = (input_tokens / 1M × input_price) + (output_tokens / 1M × output_price)`.
   For Tinker training: `cost = tokens_processed / 1M × train_price`.

5. **Batch API (only if the user asks or latency is irrelevant).** Both Claude and OpenAI
   offer a Batch/async API at 50% off standard pricing with ~24h turnaround. Don't
   default to suggesting this — most people want real-time results — but mention it if
   the user is specifically looking for ways to cut costs and can tolerate the delay.

6. **If the user's model isn't listed,** check the official pricing pages linked at the top
   of this file.
