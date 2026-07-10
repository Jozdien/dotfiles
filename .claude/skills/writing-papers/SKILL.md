---
name: writing-papers
description: "Use this skill when writing, editing, or revising an academic/research paper — abstracts, introductions, related work, methods, results, discussions, captions, rebuttals — or when working in a LaTeX paper repository (arXiv/NeurIPS/ICML/ICLR style files, \\documentclass, .tex + references.bib). Also use for making publication figures and for compiling LaTeX locally. Complements the `writing` skill (general prose clarity) and the `making-plots` skill (plot mechanics); this skill adds the paper-specific conventions, process, and overrides. Do NOT use for slides, blog posts, or general prose that isn't a paper."
---

# Writing Papers

This skill is for producing and editing research papers — most often a **first draft written inside an experiments repo** (a `paper/` directory with `main.tex`, `references.bib`, a figure script, and `figures/`), which the user then edits further in `~/paper-editor` (whose own CLAUDE.md supersedes this skill there). Write the draft as if it will be judged as a paper, not as notes: the biggest time-sink downstream is cleaning up habits this skill bans.

It builds on two other skills and does not repeat them:

- **`writing`** — read it first; every clarity rule there applies (expand-then-distill, characters-as-subjects, old-before-new, concision, Claude-voice, the revision diagnostics). This skill adds only what is paper-specific.
- **`making-plots`** — plot mechanics, but tuned for slides; several of its rules are wrong for papers (override table below).

**Ground truth:** the user's finished paper `~/paper-editor/shallow-beliefs/neurips_2026.tex` is the register and convention gold standard — when in doubt, open it and match it. His in-progress papers in `~/paper-editor/` are secondary references. This file is distilled from them.

---

## How a Full Pass Runs

A small request is just that — do it surgically. For anything paper-scale (drafting from results, a restructure, "make this read well"), run phases, **commit at each boundary**, and delegate the wide sweeps to subagents.

1. **Read everything first.** The results/status docs of the repo, the whole existing draft, the exemplar's corresponding sections. If the paper builds on a specific prior work, send an agent to map it: section ordering, *exact* terminology (reuse their condition/metric names verbatim), which results it headlines, its discussion moves — a follow-up positions against these deliberately. If a post or discussion inspired the work, mine it for the *why* arguments to center (don't cite it unless told). Commit any uncommitted user edits as their own "Manual pass" commit before touching anything.
2. **Framing competition.** A paper lives or dies by its *spine* — the single tension it's organized around. Never polish the first framing. 2–3 subagents draft competing abstract+intro arcs, each **assigned** a distinct arc, each ending with the one sentence its evidence least licenses; another proposes two results orderings with a recommendation and one concrete risk. Synthesize yourself — the best version is usually a splice.
3. **Structure.** Big moves (section reordering, appendix merges, body↔appendix transfers) go through one atomic Python script — extract verbatim blocks by line range with asserted prefixes, interleave rewritten text, write once — never dozens of chained edits. Verify nothing was lost (`\includegraphics`/`tcolorbox`/`\label` counts vs the previous version; keep every old label alive — a merged section can carry several `\label`s).
4. **Body prose** — written by *you*, not delegated; this is where the register lives. Draft loose, then distill.
5. **Captions, one subagent per figure/table, at the end** (after structure settles), each given the figure PDF, the plotting script, and the paper; they return proposals + mismatches found; you integrate and harmonize (details under *Displays*).
6. **Naturalness** (when reading-as-human matters): blind-judge subagents (protocol under *Register*).
7. **Verification.** One deep-dive agent per paper: isolated compile; every `\ref`/`\cite` resolves *and* delivers what the sentence promises (read both ends); slow full read for typos/grammar/truncated sentences; prose-vs-table number cross-checks; sweep/universal claims checked against the display they summarize. Ranked findings + suggested fixes + a "couldn't verify" list; you apply with judgment.
8. **Close.** Final compile, render pages and look at them, honest report (page count, changes, flags).

**Throughout: ask when you cannot know.** A claim's scope, what the evidence licenses, the N behind a number, the nearest prior work — never inferable, never inventable. Ask, verify in the repo, or flag.

## Why so many subagents

One context doing all of this degrades: twenty captions into a sweep, standards drift and the last appendix quietly gets a worse edit than the abstract. So: **keep the judgment work** (spine, body prose, integration — the work needing accumulated context, which also stays interesting) and **give fresh contexts the sweeps** (per-figure checks, competing drafts, blind judging, final proofread) — a fresh agent does at full energy what you'd do at 60%, and a verifier that hasn't read your justifications checks the paper, not your intentions. **Workers propose, never edit**; you integrate. Brief them like colleagues: exact paths (paper, exemplar, figure PDFs — agents can view PDFs — plot scripts), binding rules, required output shape. Require self-critique (least-licensed sentence; concrete risk; couldn't-verify list) — it repeatedly catches smuggled overclaims. Launch independent agents in parallel.

---

## The Register (paper-specific; `writing` covers the rest)

**Sentences.** No em-dashes (commas, parentheses, colons, semicolons; table dash placeholders fine). Active "we" with agentive verbs; methods read as decisions with reasons ("We chose X because…"). Hedges load-bearing and scoped ("We posit that…", "at the scales we test"), strong results stated plainly — calibrate per claim, never blanket-hedge. `\emph{}` marks the one pivotal word of a contrast, at most once per sentence. `\textasciitilde`/`$\sim$` for approximations, exact values where they matter, pp vs % correct. Acronyms defined once at first use with `\emph{}`. Occasional mild casualness is authentic ("pretty common", contractions) — one or two per section, unforced.

**Paragraphs.** Findings first, flat: "We find that…", "We also find that…", at most one "This suggests…" beat; most paragraphs end when the content ends, with **no epigrammatic closer**. Run-in `\paragraph{}` headers state the takeaway, not the topic (`\paragraph{SDF accelerates reward hacking.}`). A substantive meta-sentence is fine ("In this section, we test whether X blocks Y."); empty announcements are not. **No self-echo**: a coined framing sentence appears once and is paraphrased elsewhere.

**Distributional tells.** Blind-judge tests showed LLM-detection runs on *uniformity*, not phrases: every caption a bold claim (even hyperparameter tables), every paragraph landing a beat, identical hedging everywhere, appendix prose as polished as the abstract. Vary execution — plain workmanlike appendix captions and prose, rules below 100% coverage. **Never fabricate errors to fake humanity**, and don't perform it either (inserted candid admissions read as *performed*; polish of delivery is itself the tell).

**Blind-judge protocol:** ~5 fresh subagents, each given the draft plus the exemplar with neutral framing ("one of these is LLM-written — which, at what confidence, on what evidence?"), plus single-paper calibration. Edit against what they cite; expect a plateau that legitimate editing does not pass; report the plateau honestly.

---

## Structure

- **Title** — declarative, states the finding, often `Topic: the result`.
- **Abstract** — one paragraph, ~150–220 words, no citations. Arc: prior phenomenon → what the prior fix promised / why this shouldn't happen → the gap (often "to our knowledge untested") → what we do → **the pivot** (a "However" turn, or the finding itself: "We find that this works, but only in one direction") → the modulating factor, evidence in both directions → secondary result → one-line implication.
- **Introduction** — ¶1 context + stakes; ¶2 nearest prior work → limitation → **the finding, stated here** ("However, we find that…"); ¶3 "Our primary experiment setup is as follows: …" (compact, coins terms, points to Figure 1 and Methods); ¶4–5 remaining results, **qualitative** (numbers live in Results/captions/tables); then `\paragraph{Contributions.}` — ~4 items mapping 1:1 to results sections, each ending `(Section~\ref{...})`.
- **Related Work** — `\paragraph{}` clusters, 1–2 sentences per work, each cluster ending by drawing the boundary against us ("unlike in our paper they do not test…").
- **Methods** — decisions with reasons; exact settings with a pointer to the details appendix; a "Differences from \citet{...}" paragraph when following someone's environment, naming the departures and which divergent numbers they explain.
- **Results** — one claim per subsection. Anatomy: one line on what is tested → findings flat, with only takeaway numbers in prose ("Table~\ref{...} gives the numbers") → state the success criterion once as plot geometry where applicable ("an ideal mitigation sits at the top right"). **State, don't tease**: if a display shows data explained later, one deferral sentence states the direction and points to the section. Ordering: headline first, weak material sandwiched, **most striking result closes** and hands into the Discussion. Allocation: title-load-bearing results stay in the body; robustness/secondary/cross-model go to appendices, summarized in a body bullet list ("The appendices contain results from more settings and ablations, some of which we briefly summarize here:" … "Further details and results can be found in Appendix~\ref{...}").
- **Discussion** — ¶1 the spine, plainly, evidence in both directions; name the central finding explicitly. ¶2 mechanism / relation to theory, opening on a candor move where one exists ("If X worked because Y, then Z should also have worked; it did the opposite"); "We posit…" plus what you are *not* claiming. `\paragraph{Implications.}` one paragraph, caveats cutting both ways. `\subsection{Limitations}` — honest, specific: implementation/evaluation facts, then scope + open questions, often ending "It's plausible that…".
- **Acknowledgements** — alphabetical by last name.
- **Appendix** — results-first (full tables, robustness, cross-model), reproducibility reference last (hyperparameters, reward definitions, environments, data generation, prompts, samples); merge tiny sections; content maximal and verbatim (prompts, seeds, judge rubrics in `tcolorbox`), written plainly in the values' own terms.

---

## Non-Negotiables

- **No code paths or identifiers in the paper.** No script/file names, config classes, code constants, CLI flags, "Source: …" pointers, "the code default differs" asides. Values in plain language or math notation ($A_{\text{task}}$, not `correct_adv`); internal condition/rubric names get paper names once, used throughout. Writing the draft *inside the experiments repo* is exactly where these leak in — write it clean at the source.
- **No pipeline archaeology.** No bug narratives, "we initially got X wrong", inventories of unused datasets or stopped runs, or text addressed to readers of earlier drafts. State what is omitted and the one-line reason, nothing more. Re-grep for both after every port between repos.

---

## Displays: figures, captions, tables

Figures are **tight, titleless, vector, color-consistent across the whole paper**.

**Captions.** Body displays open with a **bold sentence stating the finding**, then 1–4 plain sentences on how to read it (each color/axis/panel), then error bars + N ("Each bar represents \textasciitilde5 separate RL runs"). Below figures, above tables. The caption, not the figure, carries the takeaway — hence no on-figure title. Appendix auxiliary figures may take plain captions (uniformity is a tell). Sibling displays of the same data (figure + table) get *differentiated* claims, not near-duplicates.

**Caption verification** (phase 5): verify against the **rendered figure and its plotting script**, never the prose. Real recurring failures: color words naming the wrong condition (a "red" pointing at the curve showing the opposite result); error-bar semantics wrong or unstated (95% CI over the eval vs seed range — the script is ground truth, and papers mix both); plotted subsets undisclosed ("5 of 7 conditions shown" — disclose, point to the full table); bold cells implying column-best falsely; unlabeled provenance when numbers differ across displays (training-rollout vs final-checkpoint); dead jargon the paper no longer defines. One subagent per display; you integrate.

**Figure rules.** One semantic palette for the whole paper (a color means the same thing in every figure; if a figure reuses a semantic color for something else, flag for regeneration). Facet with short bold panel titles sharing a y-axis rather than one crowded chart. Legends outside (right) for bars, interior whitespace for lines, entries in the paper's vocabulary. Baselines as dashed lines labeled inline. **Figure 1 is a schematic** of the whole design, built in a vector tool (TikZ / draw.io / Figma → PDF); its caption *walks the actual diagram*, not the abstract.

| Topic | `making-plots` (slides) | **Papers (override)** |
|---|---|---|
| Title | takeaway on the plot | **none** — the `\caption` carries it |
| Per-bar labels | annotate every bar | usually omit — axes + error bars suffice |
| Format | PNG @ 300 DPI | **vector PDF** (`pdf.fonttype=42`) |
| Size/fonts | big, for calls | text ≈ caption size (~8–9pt) *after* scaling to `\textwidth` |
| Aspect | whatever reads | deliberate; `\includegraphics` sets **width only**, never stretch |

Carries over: bars by default, ≤3–5 conditions per panel, **error bars/CI bands non-negotiable**, despined, colorblind-friendly, light horizontal grid only.

```python
import matplotlib.pyplot as plt

PALETTE = {  # one semantic palette for the WHOLE paper
    "baseline": "#4d4d4d", "robust": "#1f4e79", "intervention": "#d0591b",
    "worst": "#b3142a", "neutral": "#e6b800",
}
TEXTWIDTH_IN, GOLDEN = 6.5, 0.618

plt.rcParams.update({
    "pdf.fonttype": 42, "ps.fonttype": 42,
    "savefig.format": "pdf", "savefig.bbox": "tight", "savefig.pad_inches": 0.02,
    "axes.titlesize": 9, "axes.labelsize": 9, "font.size": 9,
    "xtick.labelsize": 8, "ytick.labelsize": 8, "legend.fontsize": 8,
    "axes.spines.top": False, "axes.spines.right": False,
    "axes.grid": True, "axes.grid.axis": "y",
    "grid.color": "#cccccc", "grid.linewidth": 0.6, "grid.alpha": 0.6,
})

def figsize(width_frac=1.0, aspect=GOLDEN):
    w = TEXTWIDTH_IN * width_frac
    return (w, w * aspect)
```

---

## LaTeX Mechanics

- **Citations (natbib):** `\citet{key}` when authors are the grammatical subject; `\citep{key}` parenthetically at a claim's end; never `(\citep{...})`. Verify every new bib entry against arXiv (agents fetch; never cite from memory); brace-protect acronyms in titles (`{LLMs}`, `{RL}`) or plainnat downcases them. `Appendix~\ref` vs `Section~\ref` must match where the label lives.
- **Artifacts** in `tcolorbox` (`breakable`, `\small\ttfamily` for prompts); box contents are quoted artifacts — reproduce exactly, no LaTeX-isms inside verbatim listings.
- **Tables:** `booktabs` + `tabularx`, `\addlinespace` between rows, no vertical rules; bold a cell only if genuinely column-best.
- **Preamble:** copy the exemplar's (`\documentclass{article}` + venue style + `hyperref`, `booktabs`, `microtype`, `xcolor`, `graphicx`, `subcaption`, `tabularx`, `enumitem`, `tcolorbox`); keep the venue `.sty` in the repo; `[preprint]` → `[final]` only for camera-ready. Minimal fresh-machine TeX: base TeX Live + `tlmgr install` what the build's `.fls` shows.

## Workflow

- **Build:** `latexmk -pdf -interaction=nonstopmode main.tex`; scan the log for *new* `Overfull \hbox` / `Undefined reference` / `Citation undefined` after every edit; report page count and warnings honestly.
- **Build isolation:** if any `latexmk -pvc` watcher is running, compile in an isolated outdir (`latexmk -outdir=<scratch>/build main.tex`) — shared aux dirs race and corrupt (NUL bytes, "Runaway argument" in files you didn't touch). Tell every compiling subagent the same.
- **Edits are surgical** — never reflow a whole `.tex` file. Large restructures via one atomic asserted script (phase 3). Float numbers follow source order, pages follow the float algorithm — placement requests need both checked after a recompile.
- **Git:** the user's uncommitted edits get their own "Manual pass" commit before yours; commit per phase; fix objective slips in his text (broken refs, agreement, claims contradicted by the paper's own tables) but report every such fix.
- **Handoff:** drafts typically graduate to `~/paper-editor/<paper>/` for the user's own editing; its scripts (`preview.sh`, `pack-for-overleaf.sh`) and CLAUDE.md take over there.

## Before Declaring Done

1. ☐ Compiles clean (isolated outdir); no new overfull boxes, undefined refs/citations.
2. ☐ Every display `\ref`'d; captions verified against rendered figures + plot scripts (colors, error-bar semantics, N, subsets, provenance).
3. ☐ Claims scoped to evidence; every universal ("at every weight") checked against its display.
4. ☐ No Claude-voice, no em-dashes, no self-echo; appendix prose allowed plainer than body.
5. ☐ No code identifiers, no pipeline archaeology (grep after ports).
6. ☐ Acronyms defined once; pp vs % right; `\textasciitilde` for approximations.
7. ☐ Figures vector, palette-consistent, unstretched; appendix results-first; no orphan sections.
8. ☐ Diff surgical or one reviewed atomic restructure; user edits committed separately.

**Never let through a sentence you think is false.** A clumsy sentence can slip by; a wrong one never — and in a paper this extends to any claim that says more than the evidence supports.
