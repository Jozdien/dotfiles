---
name: making-dashboards
description: Build interactive single-page HTML dashboards for browsing structured experiment data (eval transcripts, training rollouts, model comparisons, sample-level results). Use this skill whenever the user wants to create a dashboard, data browser, eval viewer, results explorer, or any interactive UI for navigating hierarchical experiment outputs. Also trigger when the user wants to deploy an existing dashboard to Cloudflare Pages or similar static hosting.
---

# Interactive Experiment Dashboards

Build single-page HTML dashboards for browsing structured experiment data. The core use case: a researcher has hundreds of eval transcripts, training rollouts, or model comparison results spread across directories, and wants a fast, interactive way to navigate and inspect them without clicking through file explorers or opening individual JSON files.

The output is always a **single self-contained HTML file** — no React, no bundler, no npm. The HTML embeds CSS, JavaScript, and a navigation index inline. Detail data (full transcripts, eval samples) is either embedded or lazy-loaded at runtime depending on data size.

## Design philosophy

The guiding principle: **maximize information density without clutter**. A busy researcher should be able to scan dozens of runs, spot the interesting ones, and drill into details — all without leaving the page or losing their place.

### 1. Single page, progressive disclosure

Never split the dashboard across multiple pages. Use a sidebar + content panel layout where the navigation hierarchy is always visible on the left and the detail view fills the right. The user should never lose context about where they are.

The navigation hierarchy should match the natural structure of the data. For ML experiments this is typically something like: experiment group → run → checkpoint/step → eval type → individual sample. Each level is a click deeper, but the parent levels stay visible.

### 2. Embed navigation metadata, lazy-load detail

Generate a JSON index at build time containing just enough metadata to render the full navigation tree: names, scores, classifications, truncated summaries, file paths. Embed this in the HTML so the sidebar and list views render instantly.

Example index structure:
```json
{
  "sweeps": {
    "lr_sweep_0507": {
      "runs": {
        "run_42": {
          "score": 0.83,
          "status": "completed",
          "steps": [500, 1000, 2000],
          "eval_summary": {"pass_rate": 0.71, "n": 204},
          "detail_path": "runs/run_42/transcript.json"
        }
      }
    }
  }
}
```

Full content (transcripts, conversations, raw eval outputs) should be fetched on demand when the user clicks into a specific item. This keeps the initial load fast regardless of how much data exists.

The index should be informative enough that most scanning can happen without drilling in. For example, if items have scores, show the scores in the list view with color coding so the user can spot outliers immediately.

#### Size thresholds

- **Index under ~1MB / ~2000 items**: embed as `const IX = {...}` directly. Sidebar renders instantly.
- **Index 1–5MB or 2000–20,000 items**: still embed, but paginate or virtualize the sidebar list in the browser.
- **Index >5MB or >20,000 items**: shard into per-group index files loaded on demand.
- **Detail data under ~5MB total**: embed everything in a second object (`const DETAIL = {...}`) — eliminates lazy-loading complexity entirely.
- **Detail data >5MB**: lazy-load via `fetch()`, cached in a module-level object.

#### Local file access

`fetch()` fails on `file://` URLs due to browser same-origin policy. If the dashboard may be opened locally (not served via HTTP):

- For small datasets, embed all detail data and skip `fetch()` entirely.
- Otherwise, instruct the user to serve via `python3 -m http.server 8080` — the generation script or Claude Code should print this instruction on completion.

### 3. Density through typography, not through hiding

Achieve high information density via small fonts (10-13px for navigation, 13px for content), compact spacing, single-character or short badges, tabular-nums for numeric alignment, and truncated text with ellipsis. Use visual hierarchy (font size, weight, color opacity) rather than borders and boxes to separate information layers.

Don't use tabs or accordions to hide information the user needs to scan. If there are 30 runs, show all 30 in the sidebar — don't paginate or collapse them. Use expandable cards only for individual samples where showing full content inline would break the flow.

### 4. Always include a filter/search input

Place a text input at the top of the sidebar that filters the navigation list client-side. For most dashboards, substring match on item names/labels is sufficient. For dashboards with scores or classifications, also support filter expressions like `score>0.8` or `status:failed`. This is essential once the item count exceeds a few dozen.

### 5. Semantic color, consistently applied

Use a small palette of semantic colors applied consistently across all views:
- **Green** for good/aligned/passing
- **Red** for bad/misaligned/failing
- **Amber** for warnings/intermediate/needs-attention
- **Accent color** (e.g., indigo) for selection/active state

These colors should mean the same thing everywhere — in score chips, badges, chart elements, sample classifications. The user should be able to scan any section and immediately read good-vs-bad without consulting a legend.

For score values on a numeric scale, use dynamic color thresholds (e.g., green for low-concern scores, amber for mid-range, red for high-concern). Apply these thresholds consistently.

### 6. Dark mode by default, light mode achievable

Use a dark background (deep navy/near-black, e.g. `#080814`) with light text. Research dashboards are often used in long sessions and dark mode reduces eye strain. Use subtle borders (`rgba(255,255,255,.06)`) and translucent backgrounds for panels and cards.

Define all colors via CSS custom properties on `:root` so that a light theme can be added by overriding the variables without restructuring any CSS. Don't hardcode colors in component styles.

Maintain a clear text hierarchy with 3 tiers of text opacity:
- Primary text: high contrast (e.g., `#e4e4f0`)
- Secondary text: medium (e.g., `#9090b0`)
- Tertiary text / labels: dim (e.g., `#606080`)

### 7. App-like frame, not a document

Set `height: 100vh; overflow: hidden` on the body and manage scrolling per-panel. The sidebar scrolls independently from the content area. This creates a fixed-frame feel where navigation is always accessible — the page never scrolls away from the controls.

Use fast transitions (0.12-0.15s) for hover effects and state changes to keep the UI feeling responsive.

---

## Architecture

### When to use a generation script vs. writing HTML directly

**Use a Python generation script** (`scripts/generate_dashboard.py`) when the dashboard will be regenerated as new data arrives — it lives in the repo, maybe CI runs it, and the data directory is an input. The script walks the data, builds the index, and emits the HTML.

**Write the HTML file directly** when the request is a one-off exploration tool for a specific dataset. Skip the indirection of a script that generates a script — just produce the HTML with data embedded inline.

### Generation script (when applicable)

The generation script should:

1. **Walk the data directory** to discover all runs, eval results, transcripts, etc.
2. **Build an index** — a JSON-serializable dict containing the navigation tree with metadata (scores, classifications, paths, truncated summaries)
3. **Generate the HTML** as a single f-string containing the CSS, the index as `const IX = <json>;`, and all JavaScript

The script should handle:
- **Caching**: If any expensive parsing is needed (e.g., extracting data from zip files, parsing log files), cache results to sidecar files (e.g., `.corrected.json`, `rollouts.json`) and only re-parse when the source file is newer.
- **Data correction**: If upstream data has known bugs (e.g., incorrect classifications), fix them at generation time rather than in the browser.

### HTML structure

```html
<body>
  <div class="topbar">  <!-- Fixed top bar with title + top-level selectors -->
  <div class="main">
    <aside class="sidebar">  <!-- Fixed-width, independently scrollable, includes filter input -->
    <div class="content">    <!-- Fills remaining width, independently scrollable -->
  </div>
  <div class="footer">  <!-- Generation timestamp -->
</body>
```

### JavaScript patterns

- **State machine**: A small set of global variables tracking the current selection at each level of the hierarchy (e.g., `curSweep`, `curRun`, `curStep`). All state changes should go through a central `setState()` function that updates the UI and syncs to the URL hash.
- **URL hash state**: Sync selection to `location.hash` (e.g., `#sweep=lr_sweep_0507&run=run_42&step=2000`) so that refreshing preserves position and users can share links to specific items. Parse the hash on load to restore state, and listen for `hashchange` to support browser back/forward navigation.
- **Lazy loading**: `fetch()` for detail data (when not fully embedded), with results cached in a module-level object (e.g., `const _cache = {}`) to avoid re-fetching.
- **Expandable cards**: Toggle an `open` class on click, which controls `display: none/block` on the card body via CSS.
- **HTML escaping**: A helper that creates a text node to safely escape user content — never insert raw data via innerHTML.

### CSS approach

All custom CSS using CSS custom properties for the color system. Layout via flexbox. No framework.

Key patterns:
- Sidebar items with `border-left: 2px solid transparent` that lights up with the accent color when active
- Pill buttons for step/checkpoint selection (tiny, compact, colored borders)
- Score chips: large number + tiny label underneath
- Chat message bubbles: role-specific background colors (system = accent tint, user = blue tint, assistant = green tint)
- Custom scrollbar styling (thin, translucent)

There is creative freedom in the aesthetics — colors, specific spacing values, font choices, border radii, etc. The principles above are the constraints; within them, choose what looks good for the specific dashboard.

---

## Deployment

### Small data (< 500 MB total, < 20,000 files)

Use **Cloudflare Pages** for free, zero-config static hosting:

1. Write a deploy script that:
   - Regenerates the dashboard HTML
   - Creates a staging directory containing only the files the dashboard fetches at runtime (use `find` with targeted path patterns + hardlinks to avoid copying)
   - Deploys via `wrangler pages deploy <staging-dir> --project-name <name> --branch main`

2. Credentials needed: `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` (store in `.env`)

3. The deploy script should document first-time setup in comments (creating an API token, required permissions: "Cloudflare Pages → Edit" and "Account Settings → Read")

Example staging approach — cherry-pick only files the dashboard needs:
```bash
find runs \( \
    -name "transcript_*.json" -path "*/evals/petri/*" -o \
    -name "*.eval" -path "*/evals/mgs/*" -o \
    -name "*.png" -path "*/plots/*" \
  \) -print0 | while IFS= read -r -d '' f; do
  mkdir -p "$STAGING/$(dirname "$f")"
  cp -l "$f" "$STAGING/$(dirname "$f")/"
done
```

### Large data (> 500 MB or > 20,000 files)

Cloudflare Pages won't work at this scale (25 MB per-file limit, 20,000 file limit per deployment). Consider:

- **Cloudflare R2** (object storage) for the data files, with Pages serving just the HTML. The dashboard fetches data from the R2 bucket URL.
- **Pre-extract** any compressed files (zips, archives) at generation time rather than doing client-side extraction.
- **Shard the index** — instead of one large JSON blob, split into per-group index files loaded on demand.
- **Paginate sample lists** in the browser rather than rendering hundreds of items at once.

The HTML file itself stays small regardless of data volume — the architecture scales by pushing more to lazy-loading.

---

## Adapting to different data

The specific data structure varies by project. The principles above are constant, but the navigation hierarchy, the metadata shown in list views, the detail renderers, and the color-coding thresholds should all be adapted to the data at hand.

For each new dashboard, start by understanding:
1. What is the natural hierarchy of the data? (e.g., experiment → run → checkpoint → eval → sample)
2. What metadata should be visible at each level without drilling in? (e.g., scores, pass rates, classifications)
3. What does "detail view" look like for a leaf item? (e.g., a conversation transcript, a chart, raw JSON)
4. What constitutes "good" vs "bad" for color coding?

Then map these answers onto the architecture above.