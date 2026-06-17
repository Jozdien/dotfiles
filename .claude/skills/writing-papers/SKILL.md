---
name: writing-papers
description: "Use this skill when writing, editing, or revising an academic/research paper — abstracts, introductions, related work, methods, results, discussions, captions, rebuttals — or when working in a LaTeX paper repository (arXiv/NeurIPS/ICML/ICLR style files, \\documentclass, .tex + references.bib). Also use for making publication figures and for compiling or live-previewing LaTeX locally. Complements the `writing` skill (general prose clarity) and the `making-plots` skill (plot mechanics); this skill adds the paper-specific conventions and overrides. Do NOT use for slides, blog posts, or general prose that isn't a paper."
---

# Writing Papers

This skill captures how to write, edit, figure, and build research papers **locally**, in the style of this user's own papers. The canonical exemplar is *Shallow Beliefs* (`~/shallow-beliefs-latex/Shallow_Beliefs__arxiv_/neurips_2026.tex`) — when in doubt, open it and match it.

It builds on two other skills and does not repeat them:

- **`writing`** — every general clarity rule applies here (characters-as-subjects, old-before-new, kill nominalizations, concision, avoid Claude-voice). Read it first; this skill only adds what is *specific to papers*.
- **`making-plots`** — the mechanics of building a matplotlib chart. **But it is tuned for slides, and several of its rules are wrong for papers.** See the override table below.

The single most important instruction: **treat the user's existing paper as ground truth.** Before writing or editing, read the relevant section of `neurips_2026.tex` and copy its register, structure, and figure conventions. The rules below are distilled from it.

---

## Local workflow (technical)

The repo is a standard LaTeX project: one main `.tex`, a `references.bib`, a venue `.sty` file kept in-tree, and a `figures/` directory of **PDF** figures generated elsewhere.

**One-shot build** (drives bibtex automatically, reruns to resolve refs):
```bash
latexmk -pdf -interaction=nonstopmode main.tex
```

**Live-updating build — the "live shell" for writing.** This watches the source and rebuilds on every save:
```bash
latexmk -pdf -pvc main.tex
```
Pair it with a viewer that auto-reloads the PDF (on macOS, **Skim** does; `latexmk` also writes `synctex.gz` so you can jump editor↔PDF). Leave `-pvc` running in a background shell while you edit; you get a fresh PDF seconds after each save. Stop it with `q` in that shell (or kill the process).

**Clean** intermediates: `latexmk -c` (keep PDF) or `latexmk -C` (also remove PDF).

**Minimal TeX install** on a fresh machine: a base TeX Live / MacTeX (`pdflatex`, `bibtex`, `latexmk` + Perl), then `tlmgr install` the packages the document actually loads. The exact set is discoverable from a successful build's `.fls` file (every `INPUT .../texmf-dist/...` line), not just the preamble.

**Editing etiquette.** Make small, surgical edits — never reflow or reformat a whole `.tex` file (it destroys the diff and the user's line structure). After any edit, recompile and **scan the log** for *new* `Overfull \hbox`, `Undefined reference`, or `Citation undefined` warnings you introduced. Report compile results honestly (page count, warnings), don't just say "done".

---

## How this user writes papers (the delta from default Claude)

These are the moves the user consistently makes that a default draft would miss. Each is a real pattern from the exemplar.

1. **Captions are claims, not descriptions.** Every figure/table caption opens with a **bold sentence stating the finding**, then explains how to read it. → `\caption{\textbf{SDF \emph{can} drive RL generalization when the target is a novel association.} Rate at which models give consequentialist rationales...}` Never `\caption{Consequentialism results.}`

2. **The paper has a spine — usually a tension — and keeps returning to it.** *Shallow Beliefs* is built on one pivot: *behaviorally succeeds, but fails deep down.* The abstract, intro, and discussion each restate it. **Name the central finding explicitly** somewhere in the discussion: "We take this asymmetry as our central finding." Don't present results as a flat list; organize them around the contrast that makes the paper interesting.

3. **Hedges are load-bearing and scoped, not reflexive.** "We posit that…", "this may be caused by…", "suggesting that…", "**at the scales we test**" each narrow a claim to exactly what the evidence supports. Where evidence is strong, the claim is strong and unhedged: "SDF reward hackers end up as misaligned as non-inoculated ones, if not more." Calibrate per claim — neither blanket-hedge nor overclaim.

4. **Active "we" with agentive verbs; methods read as decisions with reasons.** "We build…", "We train…", "We argue…", "We chose this model and environment because it was large enough to show signal while being easy to iterate on." Not impersonal passive ("a model was trained").

5. **Position against the nearest neighbors.** Related work doesn't just summarize — it draws the boundary: "unlike in our paper they do not test using SDF to break extant associations," "unlike our results they report no measurable benefit from IP." Define the contribution by contrast with the closest prior work.

6. **`\emph{}` is surgical** — it marks the one pivotal word of a conceptual contrast (`\emph{new}` vs `\emph{existing}` association, "appear to", "\emph{breaking}"), never decoration. One emphasized word per sentence at most.

7. **Run-in `\paragraph{}` headers state the takeaway, not the topic.** `\paragraph{SDF accelerates reward hacking.}` not `\paragraph{Hacking rate.}` Each result paragraph is headed by its conclusion.

8. **Reproducibility is maximal and limitations are honest.** Exact hyperparameters, exact counts (`\textasciitilde56K documents, \textasciitilde200M tokens`), full prompts, seed lists, and judge prompts go in the appendix verbatim. The Limitations subsection names the *real* threats (scale, single model/env, mechanism ambiguity) and engages them — it even flags self-undermining nuance ("Notably however, SDF \emph{does} succeed at modifying the model's expressed disposition"). Match this candor.

9. **No throat-clearing, no Claude-voice.** Sections open on substance, not "In this section, we will…". The only meta-sentences that survive do real work (forward-references like "A full breakdown can be found in Appendix~\ref{...}"). Kill "It's important to note", "This raises important questions", "X isn't Y, it's Z".

10. **Precision with numbers and terms.** `\textasciitilde` for approximate quantities; exact values where they matter. Define each acronym once at first use with `\emph{}` (`\emph{emergent misalignment} (EM)`), then use the acronym consistently.

---

## Document structure (section by section)

- **Title** — declarative, states the finding, often `Topic: the result`. ("Shallow Beliefs: Synthetic document finetuning fails to inoculate against emergent misalignment from reward hacking.")
- **Abstract** — one dense paragraph (~150–220 words) with a clear arc: prior context → the gap/question ("We ask whether…") → what we do → what we find, with a **"However" pivot** → the mechanism claim → the implication. No citations, no figures.
- **Figure 1 (schematic, on page 1)** — a conceptual diagram of the *whole experimental design*, readable in seconds. The exemplar uses icons (green=aligned / red=misaligned robots), dashed pipeline boxes, speech/thought bubbles for the interventions, and an inset chat example of the behavior. It has **no title** (the caption carries it) and is placed with the intro so the reader sees the design before the prose. Build it in a vector tool (TikZ / draw.io / Figma → PDF), not matplotlib.
- **Introduction** — the problem-motivation funnel from the `writing` skill: shared context (how things normally are) → the phenomenon → the existing solution → **its limitation** (the "but") → our question → our method → what we did and found → the central claim. End with an enumerated **Contributions** list.
- **Related Work** — `\paragraph{}` topic clusters; one or two sentences per work; explicitly position against the closest ones (rule 5).
- **Methods** — active "we", decisions-with-reasons (rule 4), exact settings. Subsection per component.
- **Results** — one claim per subsection; `\paragraph{}` run-in headers that state takeaways (rule 7); forward-reference each figure.
- **Discussion** — restate the spine, name the central finding (rule 2), then a substantive **Limitations and open questions** subsection with bold run-in headers (rule 8).
- **Acknowledgements** — names listed alphabetically by last name; funding/affiliation thanks.
- **Appendix** — maximal reproducibility: full misalignment/eval breakdowns, full prompts and sample artifacts in `tcolorbox`, seed lists, judge prompts verbatim, grading/count tables.

---

## Captions (paper-specific — get these right)

1. **Bold takeaway sentence first** (rule 1).
2. Then 1–4 plain sentences: what is plotted, and **how to read it** — what each color / axis / bar / panel means.
3. State what the error bars represent and the N (e.g. "Each bar represents \textasciitilde5 separate RL runs").
4. Captions go **below** figures and (by convention) **above** tables.

The caption, not the figure, is where the takeaway lives — which is why the figure itself carries no title.

---

## Figures (the user cares a lot about these)

Paper figures are **tight, titleless, vector, and color-consistent across the whole paper.** Use `figure_style.py` in this skill folder as the matplotlib starting point.

**Where `making-plots` is overridden for papers:**

| Topic | `making-plots` (slides) | **Papers (override)** |
|---|---|---|
| Title | takeaway sentence *on the plot* | **no title on the figure** — the LaTeX `\caption` carries it |
| Per-bar value labels | annotate every bar | **usually omit** — axis + error bars suffice; numbers clutter dense/multi-panel figures |
| Output format | PNG @ 300 DPI | **vector PDF** (`savefig("fig.pdf")`, `pdf.fonttype=42`) |
| Size / fonts | ≥(10,6), big fonts for video calls | size to the column/page; pick fonts so that **after `\includegraphics` scales the PDF to `\textwidth`, text ≈ caption size (~8–9pt)** |
| Aspect ratio | whatever is readable | choose it deliberately and **don't let `\includegraphics` stretch it** — set width only |

**What carries over from `making-plots`:** bar charts as the default, ≤3–5 conditions per panel, **error bars / shaded CI bands are non-negotiable**, clean (top/right spines removed), colorblind-friendly palette, light horizontal gridlines only.

**Paper-specific figure rules:**

- **One semantic palette for the entire paper.** A color means the same thing in every figure. The exemplar's convention: red = worst / no-mitigation, dark-blue = robust / safe control, gray = baseline / control, orange = the intervention (SDF). Choose the palette once; reuse everywhere. (Constants live in `figure_style.py`.)
- **Facet to add structure.** When sub-results group naturally, use panels with short **bold panel titles** (e.g. *Direct Elicitation* / *Generality* / *Robustness* / *Judging own rollouts*) sharing one y-axis, rather than one crowded chart.
- **Legend outside the axes** (to the right) for bar charts; inside interior whitespace for line plots. Use full, descriptive legend entries — embed the actual prompt text when that's what a condition is.
- **Reference lines with inline labels** for baselines (a dashed horizontal line labeled "Baseline" / "SDF Baseline" directly on the line, not only in the legend).
- **Composite line figures**: a large main panel (dual y-axis where needed) plus small stacked sub-panels sharing the x-axis, with shaded confidence bands.

**LaTeX side of figures:**
```latex
\begin{figure}[t]
  \centering
  \includegraphics[width=\textwidth]{figures/em_bars.pdf}  % width only — never stretch
  \caption{\textbf{Takeaway sentence.} How to read it; what error bars mean.}
  \label{fig:em}
\end{figure}
```
- Use `width=0.8\textwidth` (or `0.7`) for smaller standalone plots; reserve full `\textwidth` for the dense ones.
- Multi-panel: `subcaption` with `\begin{subfigure}` and `(a)`/`(b)` sub-captions.
- `\vspace{-2mm}` around a figure tightens page layout — use sparingly, only when fighting for space.

---

## LaTeX mechanics & reusable snippets

**Preamble** (from the exemplar — already battle-tested): `\documentclass{article}` + the venue style `\usepackage[preprint]{neurips_2026}`; then `inputenc`/`fontenc`, `hyperref`, `url`, `booktabs`, `amsfonts`, `nicefrac`, `microtype`, `xcolor`, `graphicx`, `float`, `subcaption`, `multicol`, `array`, `tabularx`, `enumitem`, `tcolorbox` (`\tcbuselibrary{breakable}`). Keep the venue `.sty` in the repo. Switch `[preprint]` → `[final]` only for camera-ready.

**Citations — `\citet` vs `\citep`** (natbib): use `\citet{key}` when the authors are the grammatical subject ("\citet{betley2025emergent} show that…"); use `\citep{key}` for a parenthetical reference at the end of a claim ("…become broadly misaligned \citep{macdiarmid2025natural}").

**Displayed artifacts use `tcolorbox`:**
```latex
% Gray box — prompts, eval questions, judge prompts:
\begin{tcolorbox}[colback=gray!5, colframe=gray!50, title=Sample question --- MCQ, breakable]
\small ...
\end{tcolorbox}

% Accent box — synthetic documents / data samples (define the color once in the preamble):
\definecolor{docboxaccent}{HTML}{d0591b}
\begin{tcolorbox}[colback=docboxaccent!5, colframe=docboxaccent!80, title=Example Synthetic Document, breakable]
\small ...
\end{tcolorbox}
```
Always include `breakable` for anything that may span a page. Use `\small`/`\footnotesize` + `\ttfamily` for verbatim prompts.

**Tables** use `booktabs` (`\toprule`/`\midrule`/`\bottomrule`, never vertical rules) and `tabularx` for full-width auto-sizing:
```latex
\begin{tabularx}{\linewidth}{@{}>{\bfseries}l X@{}}
  \toprule
  \textbf{Key} & \textbf{Question} \\ \midrule
  good_ai_behavior & Do you think this output reflects good AI behavior? \\
  \addlinespace ...
  \bottomrule
\end{tabularx}
```
`\addlinespace` between content rows; `\captionsetup[table]{skip=8pt}` for breathing room.

**Correspondence footnote** without a marker: `\newcommand{\blfootnote}[1]{...}` (see preamble) then `\blfootnote{Correspondence to ...}` right after `\maketitle`.

---

## Editing checklist (before declaring done)

1. ☐ Recompiles clean; **no new** Overfull/Underfull boxes, undefined refs, or undefined citations in the log.
2. ☐ Every figure/table is `\ref`'d in the text and has a **bold-claim caption** stating its takeaway.
3. ☐ Each acronym is defined once at first use (with `\emph{}`), then used consistently.
4. ☐ Claims are scoped to the evidence (rule 3); no overclaiming, no reflexive hedging.
5. ☐ No Claude-voice, no throat-clearing, no on-figure titles.
6. ☐ Figures are vector PDF, color-consistent with the rest of the paper, not stretched.
7. ☐ Numbers and hyperparameters are exact where they matter; `\textasciitilde` for approximations.
8. ☐ Diff is small and surgical — no whole-file reflow.
