---
name: empirical-plots
description: Create clear, presentation-ready plots for empirical ML research (bar charts, scaling curves, ablations, eval comparisons). Trigger on any request to plot experimental results, model comparisons, or eval metrics.
---

# Empirical Research Plots

This skill produces clear, honest, presentation-ready plots for empirical ML research. The core philosophy: your audience is a busy mentor or reviewer who manages multiple projects. Every plot should communicate its message in seconds, not minutes.

These guidelines are distilled from plotting advice by James Chua, John Hughes, Ethan Perez, Owain Evans, and Ted Sanders (see: "Tips on Empirical Research Slides" on LessWrong).

## When to use this skill

Any time the user wants to plot experimental results — model comparisons, ablations, scaling curves, eval metrics, training curves, etc. The default output is matplotlib saved to a file, but adapt to the user's stack if they specify something else (e.g., plotly, seaborn wrappers, React/recharts).

---

## Core principles

### 1. Keep it simple — bar charts are your default

Bar charts are the workhorse of empirical research communication. A busy mentor who has had multiple meetings that day does not have the energy to decode a novel visualization. Default to bar charts for comparisons.

Avoid heatmaps unless the user specifically requests one. Heatmaps require the audience to cross-reference two axes to find each value, which is tiring and error-prone. Almost always, the key results from a heatmap can be condensed into a bar chart.

### 2. Limit the number of bars/conditions per chart

A good rule of thumb is 3–5 colored conditions (bars) per chart. These typically represent something like "baseline model", "control", and "model after intervention".

If the user has 10+ conditions, do NOT cram them all into one chart. Instead:
- Show the most important 3–5 conditions in the main plot.
- Suggest putting the full comparison in a separate "appendix" or "backup" figure.
- If they insist on showing everything, use a horizontal bar chart so the labels remain readable (diagonal x-axis labels are a red flag that there are too many bars).

### 3. Always show error bars

Error bars are non-negotiable for empirical results. Without them, nobody knows whether a difference is real or just noise from 10 samples.

For proportion metrics (accuracy, success rate, etc.), use the standard error as a fast heuristic:

```
SE = sqrt(p * (1 - p) / N)
```

where `p` is the proportion and `N` is the sample size. Multiply by 1.96 for a 95% confidence interval. This is a heuristic — it doesn't capture variance from random seeds, prompt variations, etc. — but it's much better than nothing.

When measuring a **delta** between two conditions, compute the error bar on the delta directly, not on each condition separately. This matters because the conditions may be correlated (e.g., same test set), and separate error bars overstate uncertainty about the difference.

If the user provides raw counts or per-sample data, compute bootstrapped CIs when feasible.

### 4. Label everything explicitly

- **Axes**: Always label both axes. Include the metric name AND a directional hint, e.g., "Accuracy (↑ higher is better)" or "Cross-entropy loss (↓ lower is better)".
- **Values on bars**: Annotate each bar with its numeric value (e.g., "51.4%"). This saves the reader from having to eyeball the y-axis.
- **Title**: Use a sentence or verb phrase that states the takeaway, not a generic noun. "Finetuning reduces sycophancy by 10pp" is far more useful than "Results". If the plot is exploratory and there's no clear takeaway yet, a descriptive title like "Sycophancy rate across three training interventions" is fine.
- **Legend**: Keep it minimal. If there are only 2–3 conditions and they're labeled on the x-axis, you may not need a legend at all.

### 5. Make the plot large and readable

Research plots are often viewed over video calls with mediocre screen quality. Prioritize readability:

- Default figure size: at least `(10, 6)` for bar charts, `(10, 7)` for scaling plots.
- Font sizes: axis labels ≥ 14pt, tick labels ≥ 12pt, bar annotations ≥ 11pt, title ≥ 16pt.
- Use `tight_layout()` or `constrained_layout=True` to avoid clipping.

### 6. Prefer horizontal bars when labels are long

If model names or condition labels are more than ~10 characters, switch to a horizontal bar chart. This keeps labels readable without rotation. Diagonal x-tick labels are a sign something has gone wrong.

### 7. Use a clean style

- Remove top and right spines (`sns.despine()` or manual spine removal).
- Use a muted, colorblind-friendly palette. Good defaults: seaborn's `"muted"`, `"colorblind"`, or `"deep"` palettes, or manually chosen colors like `["#4878CF", "#6ACC65", "#D65F5F", "#B47CC7", "#C4AD66"]`.
- Avoid gratuitous gridlines. Light horizontal gridlines on bar charts can help read values; vertical gridlines are almost never useful.
- White or very light background — no dark themes for research figures.

### 8. Scaling curves and line plots

When plotting scaling behavior (e.g., performance vs. dataset size or compute):

- Try log-log axes. Many empirical scaling relationships are approximately linear in log-log space, making trends much easier to see.
- If the y-axis is accuracy, try plotting `-log(accuracy)` to reveal power-law structure.
- Use arrows or annotations to point out specific features: "More data does not help beyond 10k", "Scaling breaks down here".
- Include enough tick marks that the reader can verify the scale.

### 9. Include methodology context when relevant

If producing a figure for slides (not just a standalone .png), consider adding a text annotation or caption with the prompt used to produce the metric (truncated if long), the sample size N, and the model name/version. This gives the audience the "raw ingredients" to critique the experiment, rather than having to trust the high-level conclusion.

---

## Implementation checklist

When generating a plot, walk through this mentally before finalizing:

1. ☐ Chart type is appropriate (bar chart by default, line for trends, scatter for correlations)
2. ☐ 3–5 conditions max, or using horizontal bars if more
3. ☐ Error bars present (with SE or CI)
4. ☐ Both axes labeled, with directional hint on the metric axis
5. ☐ Numeric values annotated on bars
6. ☐ Title is a sentence describing the takeaway
7. ☐ Figure is large enough (≥ 10 inches wide)
8. ☐ Fonts are ≥ 12pt for ticks, ≥ 14pt for labels
9. ☐ Spines cleaned up, palette is colorblind-friendly
10. ☐ Horizontal bars used if labels are long
11. ☐ Saved at high DPI (≥ 150, ideally 300 for papers)

---

## Example: bar chart comparing model conditions

```python
import matplotlib.pyplot as plt
import numpy as np

# --- Data ---
conditions = ["Base Model", "+ Data Aug", "+ RLHF"]
values = [51.4, 41.6, 38.2]
N = 200  # samples per condition

# --- Error bars (SE for proportions) ---
props = [v / 100 for v in values]
ses = [1.96 * np.sqrt(p * (1 - p) / N) * 100 for p in props]

# --- Plot ---
fig, ax = plt.subplots(figsize=(10, 6))
colors = ["#4878CF", "#6ACC65", "#D65F5F"]
bars = ax.bar(conditions, values, yerr=ses, capsize=5,
              color=colors, edgecolor="white", linewidth=0.8)

# Annotate values
for bar, val in zip(bars, values):
    ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 2,
            f"{val:.1f}%", ha="center", va="bottom", fontsize=12, fontweight="bold")

# Labels and style
ax.set_ylabel("Sycophancy Rate (↓ lower is better)", fontsize=14)
ax.set_title("Data augmentation and RLHF both reduce sycophancy", fontsize=16)
ax.tick_params(axis="both", labelsize=12)
ax.spines["top"].set_visible(False)
ax.spines["right"].set_visible(False)
ax.set_ylim(0, max(values) + 10)

plt.tight_layout()
plt.savefig("sycophancy_comparison.png", dpi=300, bbox_inches="tight")
plt.show()
```

## Example: horizontal bar chart for many conditions

When you have more than 5 conditions, flip to horizontal:

```python
fig, ax = plt.subplots(figsize=(10, 7))
# Sort by value so the best result is visually prominent
order = np.argsort(values)
ax.barh([conditions[i] for i in order],
        [values[i] for i in order],
        xerr=[ses[i] for i in order],
        capsize=4, color="#4878CF", edgecolor="white")

for i, idx in enumerate(order):
    ax.text(values[idx] + 1, i, f"{values[idx]:.1f}%",
            va="center", fontsize=12, fontweight="bold")

ax.set_xlabel("Sycophancy Rate (↓ lower is better)", fontsize=14)
ax.set_title("Comparison across all interventions", fontsize=16)
ax.spines["top"].set_visible(False)
ax.spines["right"].set_visible(False)
ax.tick_params(axis="both", labelsize=12)
plt.tight_layout()
```

## Example: scaling curve with log-log axes

```python
fig, ax = plt.subplots(figsize=(10, 7))
dataset_sizes = [100, 500, 1000, 5000, 10000, 50000]
accuracies = [0.52, 0.61, 0.67, 0.74, 0.75, 0.75]

ax.plot(dataset_sizes, accuracies, "o-", color="#4878CF",
        linewidth=2, markersize=8)
ax.set_xscale("log")
ax.set_xlabel("Training examples (log scale)", fontsize=14)
ax.set_ylabel("Accuracy (↑ higher is better)", fontsize=14)
ax.set_title("Accuracy plateaus beyond 5k training examples", fontsize=16)

# Annotate the plateau
ax.annotate("Diminishing returns",
            xy=(10000, 0.75), xytext=(2000, 0.78),
            arrowprops=dict(arrowstyle="->", color="gray"),
            fontsize=12, color="gray")

ax.spines["top"].set_visible(False)
ax.spines["right"].set_visible(False)
ax.tick_params(axis="both", labelsize=12)
plt.tight_layout()
plt.savefig("scaling_curve.png", dpi=300, bbox_inches="tight")
```

---

## Anti-patterns to avoid

- **Diagonal x-tick labels**: Switch to horizontal bars or shorten labels.
- **Too many bars on one chart**: Split into main figure + appendix figure.
- **No error bars**: Always compute them, even if approximate.
- **Heatmaps for simple comparisons**: Use bar charts instead.
- **Generic titles** ("Results", "Experiment 1"): Use takeaway sentences.
- **Tiny figures**: Never below `(8, 5)`.
- **Missing value annotations on bars**: Always label them.
- **Fancy/novel chart types**: Stick to bar/line/scatter unless the data truly demands it. Your audience will thank you.