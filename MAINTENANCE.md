# Website Maintenance Guide

Personal academic website built with [Quarto](https://quarto.org/).  
**Live URL:** https://lasaibarrenada.github.io/  
**Source repo:** https://github.com/LasaiBarrenada/LasaiBarrenada.github.io/

---

## Quick Reference

| What do you want to update? | File to edit |
|---|---|
| Bio text / photo | `index.qmd` |
| Add a new project | `projects/projects.xlsx` |
| Add a conference talk | `speaking/conferences.xlsx` |
| Add a CV entry (job, education, award…) | `cv/cv.qmd` |
| Add a publication to the CV PDF | `cv/peer_bib.bib` |
| Replace the CV PDF | `cv/cv.pdf` |
| Refresh publications network (new paper) | Delete `_freeze/Publications/` then render |
| Replace navbar logo | `img/lb_logo_opt1.svg` |
| Replace browser tab icon (favicon) | `img/favicon.svg` |
| Exclude/include a GitHub repo on Software page | Edit `EXCLUDE_REPOS` in `software/software-page.qmd` |
| Link a paper to an OSF card on Software page | Add the OSF node ID in the `OSF_ID` column of `projects/projects.xlsx`, or add to `osf_extra_papers` in the R chunk |
| Change navbar links or social icons | `_quarto.yml` |
| Change global font / colours | `html/styles.scss` |
| Change landing-page styles | `html/landing_page_styles.css` |
| Change timeline styles (projects & speaking) | `html/timeline.css` |
| Change page footer text | `_quarto.yml` → `page-footer` |
| Update "last updated" date | `_variables.yml` |
| Edit the license page | `license/index.qmd` |

---

## 1. How to Rebuild and Deploy

**Render the site locally** (generates `_site/`):
```bash
quarto render
```

**Preview locally** (hot-reload):
```bash
quarto preview
```

**Publish to GitHub Pages:**
```bash
quarto publish gh-pages
```
This pushes the rendered `_site/` to the `gh-pages` branch automatically.

---

## 2. The Freeze Mechanism

`execute: freeze: true` is set globally in `_quarto.yml`. This means:

- **R code chunks are only executed once.** Results are cached in `_freeze/`.
- On subsequent renders Quarto uses the cached output — it does **not** re-run R.
- This keeps the build fast and reproducible without needing R dependencies installed on the server.

**Exceptions:** The **Projects**, **Speaking**, **Software**, and **Publications** pages have `freeze: false` set in their YAML header, so they always re-execute when rendered. The Publications page also sets `flush = TRUE` in `get_publications()` to bypass the `scholar` package cache and requests the complete profile list. Projects, Speaking, and Software can be rendered directly after changing their data sources; Publications refreshes from Google Scholar on every render.

**When you MUST delete the freeze cache** (to force re-execution on other pages):

| Situation | Cache folder to delete |
|---|---|
| Any other R-code change | The folder matching the changed `.qmd` |

After deleting, run `quarto render` and the R code will re-execute and create a new cache.

---

## 3. Landing Page — `index.qmd`

### Update bio text
The bio lives inside the `{=html}` block. Edit the three `<p>` paragraphs directly:

```html
<p>I'm a final-year PhD student at KU Leuven ...</p>
```

### Replace profile photo
1. Save the new photo as `img/lasai_headshot.png` (overwrite the existing file).
2. Recommended: square crop, at least 600×600 px.
3. No code changes needed — the page references this filename directly.

### Interactive regression Easter egg
The hero background canvas has an interactive feature on top of the particle animation:

1. A hint ("Click anywhere to place data points") appears in the top-right in site-blue (`#007BFF`) at opacity 0.65, fading very slowly.
2. Clicking on the background (not on links/buttons) places a blue dot with a white border and a pop-in animation. A counter ("3 / 10") tracks progress.
3. At **10 dots**, a **LOESS curve** (span = 0.75, tricube kernel) is fitted through the points and drawn as a solid blue line. The **R²** value and the message "This is basically my job :)" appear in the top-right corner of the canvas.
4. A **"⟳ Random data"** button appears just below the tagline (top-right, `top: 56px`). Clicking it clears any existing dots, generates 10 new random points spread across the canvas, and immediately fits + displays the LOESS and R². Clicking it again regenerates a fresh random set.
5. Clicking anywhere on the canvas (11th click, or first click after a random set) clears everything and the cycle restarts.

### Quarto version note
Quarto 1.9+ can hoist the first hero heading into the page title block when it sees an `<h1>` inside the landing-page HTML. The hero now uses `.hero_title` instead, and `#title-block-header` is hidden in `html/landing_page_styles.css` so the landing page stays flush under the navbar.

The hero uses 6rem of top padding and aligns `.hero_content` to the start so the "Hi, I'm Lasai" heading remains below the pinned navbar instead of being vertically centered on desktop.


Key parameters in the `<script>` block of `index.qmd`:
- `MAX_DOTS` — number of points before the curve is drawn (default: 10)
- `0.75` in `computeLoess()` — the LOESS span (smoothing parameter)
- `hintOpacity` — initial opacity of the hint text (default: 0.65)
- `top: 56px` in `#random-btn` CSS — positions the button below the "This is basically my job :)" line

Resizing the browser window clears dots and resets the hint.

---

## 4. Projects Page — `projects/projects-page.qmd`

The page is a vertical HTML timeline generated by an R chunk (`tl-projects`) that reads `projects/projects.xlsx`. This works the same way as the speaking page — the R code builds the HTML cards from the spreadsheet data.

Both pages share the same timeline CSS from `html/timeline.css` (see §10). **Year dividers** are automatically inserted between entries from different years to visually separate them.

Because the R output is inserted into Markdown before Pandoc processes it, **no line of generated HTML may start with 4+ spaces** (same constraint as the speaking page). Keep all `sprintf()` / `paste0()` templates at ≤ 3-space indentation.

### Add a new project
Open `projects/projects.xlsx` and add a new row. The columns are:

| Column | Description | Example |
|---|---|---|
| `Title` | Paper/project title | Clustered Flexible Calibration… |
| `Year` | Four-digit year | 2026 |
| `Month` | Numeric month (used for sorting) | 3 |
| `Venue` | Journal name or "arXiv preprint" | BMJ Open |
| `Link_1_name` | Label for the first link | Paper |
| `Link_1` | URL for the first link | https://… |
| `Link_2_name` | Label for the second link | Code |
| `Link_2` | URL for the second link | https://… |
| `Link_3_name` | Label for an optional third link (leave blank if none) | Package |
| `Link_3` | URL for the optional third link | https://… |
| `Summary` | 2–3 sentence plain-language summary | Two or three sentences… |

If `Link_1` is **left blank**, the project is displayed as **Upcoming** — grey hollow dot, grey card, and an "Upcoming" badge. Once published, fill in the links and the project switches to the normal blue style.

### Award links
If any `Link_X_name` contains the word "Award" (case-insensitive), the link button is automatically rendered in a **gold award style** with a 🏆 icon. This is handled by the R code in `projects-page.qmd` and styled via `.tl-award` in `html/timeline.css`.

Freeze is disabled on this page, so just edit the Excel and re-render — no need to delete cache folders.

---

## 5. Talks Page — `speaking/speaking-page.qmd`

The page appears as **"Talks"** in the navbar (renamed from "Speaking"). The page has two sections:

1. **Timeline** — an R chunk (`tl-speaking`) reads the Excel, builds HTML cards, and outputs them via `cat()` with `results='asis'`. Shares timeline CSS with the projects page via `html/timeline.css`. **Year dividers** are automatically inserted between entries from different years.
2. **Map** — an R chunk (`map-data`) geocodes conference cities and injects the coordinates as JSON for the **Leaflet** interactive map.

The map uses **Leaflet.js** with public OpenStreetMap tiles, so it does not require an API key. Conference locations and affiliated institutions are geocoded from their city names at render time using the ArcGIS geocoder. Rendering stops with a clear error if the geocoding service is unavailable or a city has no result, rather than generating a map without points. Clicking any marker opens a styled popup. The map works on both desktop and mobile with native touch support. Zoom is constrained (`minZoom: 2`, `maxBounds`) so only a single world view is shown.

### Map → timeline linking
Each timeline entry has a unique `id` attribute (e.g., `talk-iscb-2024`), generated by the R code from `Code_Name` and `Year`. Conference marker popups include a **"Show in timeline ↓"** link. Clicking it smooth-scrolls to the matching timeline entry and applies a 2-second blue pulse highlight (`tl-highlight` class → `tl-flash` animation in `html/timeline.css`). The ID is computed identically in both R and JS: `talk-{code_name}-{year}`, lowercased with non-alphanumeric characters replaced by hyphens.

### University popup labels
UMC Utrecht and Memorial Sloan Kettering popups show **"Visiting Researcher"** below the institution name. KU Leuven does not (it's the home institution). This is handled in the JS `universityData.forEach` block with a conditional on `d.name`.

Because the R output is inserted into Markdown before Pandoc processes it, **no line of generated HTML may start with 4+ spaces** — Pandoc would treat it as a code block and escape the tags. Keep all `sprintf()` / `paste0()` templates at ≤ 3-space indentation.

### Add a new talk or poster
Open `speaking/conferences.xlsx` and add a new row. The columns are:

| Column | Description | Example |
|---|---|---|
| `Conference` | Full conference name | International Society for Clinical Biostatistics |
| `Code_Name` | Short acronym shown on the timeline | ISCB |
| `Year` | Four-digit year | 2026 |
| `Month` | Numeric month (used for sorting) | 7 |
| `Location` | City name (used for geocoding the map) | Geneva |
| `Title` | Full talk/poster title | Multicenter calibration… |
| `Type` | `Oral` or `Poster` (leave blank for upcoming) | Oral |
| `Link_1_name` | Label for the first link button | Slides |
| `Link_1` | URL for the first link | https://… |
| `Link_2_name` | Label for an optional second link (leave blank if none) | Paper |
| `Link_2` | URL for the optional second link | https://… |

### Add or change an affiliated institution on the map
The list of institutions is defined in the `map-data` R chunk inside `speaking-page.qmd`:
```r
uni_coords <- data.frame(
  name  = c("KU Leuven", "UMC Utrecht", "Memorial Sloan Kettering"),
  city  = c("Leuven",    "Utrecht",     "New York")
)
```
Add or remove rows as needed. The geocoding will resolve city names automatically.

Freeze is disabled on this page, so just edit the Excel and re-render — no need to delete cache folders.

---

## 6. Publications Page — `Publications/publications-page.qmd`

The page pulls data live from **Google Scholar** (user ID `uPOL3NkAAAAJ`) using the `scholar` R package. The co-authorship network is built automatically from your publication list.

### When a new paper appears on Google Scholar
1. Run `quarto render Publications/publications-page.qmd` (or render the full site).
2. The R code will fetch the complete profile list with a fresh Scholar request, re-run the deduplication pipeline, and rebuild the network.

### Author name deduplication
The pipeline automatically handles accent variants (e.g. `M Martinez-Garcia` ≡ `M Martínez-García`). For cases that cannot be resolved automatically — typically Dutch/Belgian particle names or abbreviated compound surnames — a `manual_corrections` vector is defined near the top of the R chunk:

```r
manual_corrections <- c(
  "G Collins"       = "GS Collins",
  "BV Calster"      = "B Van Calster",
  "BD Moor"         = "B De Moor",
  "JYJ Verbakel"    = "JY Verbakel",
  "JF Calatrava"    = "J Fernández Calatrava",
  "JCGS de Cueto"   = "JC Gálvez Sainz de Cueto",
  "Rén Armañanzas"  = "R Armañanzas"
)
```

If a new co-author appears under two different name formats, add a new entry here:
```r
"Garbled form"  = "Canonical form"
```

### Publication deduplication (preprint + journal)
The pipeline also detects preprint/working-paper duplicates by comparing titles with Jaccard similarity. If a preprint you have on Google Scholar gets published and the two entries persist simultaneously, the preprint will be automatically dropped when Jaccard similarity ≥ 0.28 with the published version. No manual action needed.

### The network only shows co-authors with ≥ 2 shared papers
This is controlled by the `filter(n_papers >= 2)` line in the R chunk. Change `2` to any other threshold if needed.

### Visual enhancements (D3)
The network uses several visual techniques implemented in the `<script>` block:

- **Focus + dim**: Hovering or clicking a node highlights it and its connected links/nodes; everything else fades to 12% opacity (`DIM_OPACITY`). When a node is selected (clicked), hover on other nodes does not change the focus — only clicking a new node or the background changes it.
- **Gradient nodes**: Each node uses an SVG radial gradient (lighter centre, darker edge) defined in `<defs>`. The centre node also has a glow filter (`feGaussianBlur` + `feMerge`); coauthor nodes have a drop shadow (`feDropShadow`).
- **Curved links**: Links are `<path>` elements with quadratic Bézier curves instead of straight `<line>` elements. Adjacent links alternate curve direction (`sign = i % 2`) so they don't overlap.
- **Entrance animation**: Nodes start at `r = 0` and scale in with `d3.easeBackOut` (slight overshoot); links and labels fade in. The animation fires 400 ms after page load to let the simulation settle first.

---

## 7. CV

The CV exists in two forms:

| File | Purpose |
|---|---|
| `cv/cv-page.qmd` | **HTML page** shown on the website — renders the CV content directly with styled sections, a table of contents, and a "Download PDF" button at the top |
| `cv/cv.qmd` | **PDF source** using `quarto-cv-pdf` format — generates `cv.pdf` for download |

Both files should be kept in sync when you add new entries.

### Add a new entry (job, talk, award, etc.)
Update **both** files:

1. **`cv-page.qmd`** — Add an entry using the Quarto div pattern:
```markdown
:::: {.cv-entry}
::: {.cv-entry-title}
Institution Name
:::
::: {.cv-entry-date}
MM/YYYY – MM/YYYY
:::
::::
::: {.cv-entry-detail}
Role description, City
:::
```

2. **`cv/cv.qmd`** — Add the corresponding entry using LaTeX `\hfill` for dates:
```markdown
**Institution Name**

Role description (City) \hfill MM/YYYY–MM/YYYY
```

Then re-render `cv/cv.qmd` to regenerate the PDF.

### Add a publication to the CV
Publications on the HTML page are rendered automatically from `cv/peer_bib.bib` using Quarto's bibliography support (`nocite: '@*'`). Add the BibTeX entry to the bib file and it will appear on both the HTML page and in the PDF.

**BibTeX entry format example:**
```bibtex
@article{barrenada2025example,
  author  = {Barreñada, Lasai and Van Calster, Ben},
  title   = {Title of the paper},
  journal = {Journal Name},
  year    = {2025},
  volume  = {10},
  pages   = {123--130},
  doi     = {10.xxxx/xxxxx}
}
```

### Replace the CV PDF only
Overwrite `cv/cv.pdf` with the new file. The HTML page links to this file via the download button.

### Technical notes
- `cv-page.qmd` uses `engine: knitr` (needed for the inline R expression `Sys.Date()`). Without it, Quarto falls back to Jupyter/Python and fails.
- `cv-page.qmd` has `freeze: true` since publications from the bib file don't change often. Delete `_freeze/cv/cv-page/` when you add a new publication to force re-rendering.

---

## 8. Software Page — `software/software-page.qmd`

The page fetches data from two platforms using client-side JS — no R code, no freeze cache:

1. **GitHub** (username `LasaiBarrenada`) — public repositories displayed in a card grid.
2. **OSF** (user ID `pgkjv`) — public top-level projects displayed in a separate card grid below.

### How it works — GitHub
A `<script>` block calls `https://api.github.com/users/LasaiBarrenada/repos?type=owner&sort=pushed&per_page=100` on page load. Repos are displayed in a responsive 2-column card grid (1 column on mobile). Each card shows the repo name (linked), description, primary language with a coloured dot, star count, fork badge (if applicable), topic tags, and a relative "Updated X ago" timestamp.

### Configuration — GitHub (inside the first `<script>` block)
| Variable | Purpose |
|---|---|
| `USERNAME` | GitHub username to fetch repos from (currently `LasaiBarrenada`) |
| `EXCLUDE_REPOS` | Array of repo names to hide — currently `LasaiBarrenada.github.io` (website), `LasaiBarrenada` (profile config), `web_resources` (web assets) |
| `CONTRIB_REPOS` | Array of `owner/repo` strings for external repos the user contributes to — fetched individually and shown with a "Contributor" badge |
| `LANG_COLORS` | Map of language names → hex colours for the dot indicator |

### How it works — OSF
The OSF API does **not** support CORS, so OSF data is fetched at **build time by an R chunk** (`osf-projects`), not in the browser. The R code calls `https://api.osf.io/v2/users/pgkjv/nodes/` using `jsonlite::fromJSON()`, filters to top-level public projects (where `root.data.id == node.id`), and generates HTML cards via `cat()` with `results='asis'`. The page has `freeze: false` so OSF data refreshes on every render.

Cards show the project title (linked to OSF), an "OSF" badge (dark blue `#214370`), category label, description, tags, related paper links (if any), child components (if any), and an absolute date ("Updated Mar 2026"). Cards are sorted by most recently modified.

### Child components on OSF cards
Each OSF card fetches its first-level child components via `/nodes/{id}/children/` at render time (one API call per top-level project). Children are shown in a shaded box labelled "Components" with a left navy border. Each child is a linked item showing an emoji icon (by category), the component title, and a small category label. All child categories are shown.

### Related papers on OSF cards
Each OSF card can show links to associated published papers. Papers are looked up from two sources (both are merged):

1. **`projects/projects.xlsx`** — if a row has a value in the `OSF_ID` column matching the OSF node ID, the paper title and `Link_1` URL are shown on the card. This is the preferred method since it avoids duplicating paper metadata.
2. **`osf_extra_papers`** — a named list in the R chunk for papers that are not in `projects.xlsx`. Add entries like:
```r
osf_extra_papers <- list(
  "uxvhq" = list(list(title = "Paper title", url = "https://doi.org/..."))
)
```
Multiple papers per project are supported in both sources.

### Configuration — OSF (inside the R chunk `osf-projects`)
| Variable | Purpose |
|---|---|
| OSF user ID | Hardcoded in the API URL (`pgkjv`) — change there if needed |
| `cat_labels` | Named vector mapping OSF category slugs → friendly display labels |
| `osf_extra_papers` | Named list of extra paper links for OSF projects not in `projects.xlsx` |
| `truncate_title()` | Truncates paper titles to 58 characters + "..." on OSF cards (full title shown on hover via `title` attribute) |

### Styling
Card grid styles are in `html/software.css`. The page loads this file with a `<link>` tag. Do not inline styles in the page file. OSF-specific styles (`.sw-osf-badge`, `.sw-osf-category`, `.sw-topic-osf`, `.sw-card-osf:hover`, `.sw-section-heading`, `.sw-papers`, `.sw-paper-link`) are also in `software.css`.

### Gotchas
- The GitHub public API allows **60 requests/hour** without authentication. This is sufficient for a personal site but will fail if the page is loaded very frequently in a short time. If rate-limited, a fallback message with a link to the GitHub profile is shown.
- The OSF public API has no documented unauthenticated rate limit, but is similarly generous. If it fails, a fallback message with a link to the OSF profile is shown.
- Archived repos are automatically excluded (GitHub). Forked repos are filtered out from the main fetch.
- To showcase external repos the user contributes to (via commits/PRs), add the upstream `owner/repo` path to the `CONTRIB_REPOS` array — these are fetched individually and shown with a "Contributor" badge.
- Each entry in `CONTRIB_REPOS` uses one extra API call, so keep the list short to stay within the 60 req/hr limit.

---

## 9. Site-wide Settings — `_quarto.yml`

Search is **disabled** (`search: false`). The website title is set to `"Lasai Barreñada"` (short form — the full "Medical Statistician & Researcher" description is in `description-meta` for SEO only). The navbar tab for talks is labelled **"Talks"** (the page file remains in the `speaking/` folder).

### Change your name or description (appears in browser tab / SEO)
```yaml
title-meta: "Your Name"
description-meta: "Your description"
```

### Add a new page to the navbar
Add an entry under `website: navbar: left:`:
```yaml
- text: New Page
  href: folder/new-page.qmd
```
Then create `folder/new-page.qmd` with at minimum a YAML header:
```yaml
---
title: New Page
---
```

### Update social links (GitHub, Twitter/Bluesky, ORCID…)
Edit the items under `website: navbar: right:`. Each item has a `text` (icon) and `href` (URL).

### Update the footer year or template credit
Edit `website: page-footer: left`.

---

## 10. Global Styles

| File | Controls |
|---|---|
| `html/styles.scss` | Global font (Inter for body and headings), link colours, spacing, **navbar responsive sizing** — applied to all pages |
| `html/timeline.css` | Shared timeline styles for Projects and Speaking pages (cards, dots, dates, links, badges, award styling, expand/collapse, mobile breakpoints) |
| `html/landing_page_styles.css` | Hero section layout on the landing page |
| `html/seo.html` | Meta tags injected into every page `<head>` |

### Navbar responsive behaviour
The navbar logo scales down on mobile screens (max-height 28px below 992px). The hamburger toggle is pushed to the right and the logo stays flush left. These rules are defined in `html/styles.scss` inside a `@media (max-width: 991.98px)` block.

**Important:** the container-fluid must use `flex-wrap: wrap` (not `nowrap`) so that the Bootstrap collapse div can drop to a full-width second row beneath the logo + hamburger. With `nowrap`, the expanded mobile menu overlaps instead of stacking. The collapse gets `order: 2; flex-basis: 100%` and the social-icon row gets `flex-wrap: wrap` to avoid horizontal overflow.

---

## 11. Images and Branding

| File | Purpose |
|---|---|
| `img/lasai_headshot.png` | Profile photo on the landing page |
| `img/lb_logo_opt1.svg` | Navbar logo — "LB" initials with R prompt `>` and sigmoid curve. Referenced in `_quarto.yml` → `navbar: logo` |
| `img/favicon.svg` | Browser tab icon — blue rounded square with "LB". Referenced in `_quarto.yml` → `favicon` |
| `img/website_thumbnail.png` | Social preview image (Twitter/Open Graph) |
| `img/logo_kuleuven.svg` | KU Leuven logo (spare, not currently used on site) |
| `img/logo_umcutrecht.svg` | UMC Utrecht logo (spare, not currently used on site) |
| `img/logo_msk.jpeg` | Memorial Sloan Kettering logo (spare, not currently used on site) |
| `projects/*.png` | Project thumbnail images referenced in the projects page |

### Replace the navbar logo
Overwrite `img/lb_logo_opt1.svg` (or create a new file and update the `logo:` path in `_quarto.yml`). The SVG **must** include explicit `width` and `height` attributes — without them, some browsers collapse it to zero size. The navbar CSS constrains the logo to max 44px tall (28px on mobile).

### Replace the favicon
Overwrite `img/favicon.svg` (or create a new file and update the `favicon:` path in `_quarto.yml`). Keep it simple — favicons display at 16–32px.

---

## 12. License Page — `license/index.qmd`

The license page (linked in the footer) contains:

- An **MIT License** covering the website source code.
- A **copyright notice** for written content, publications, talks, and images.
- An **acknowledgement** of the original template by Marvin Schmitt.

Edit `license/index.qmd` directly. No R code, no freeze cache.

---

## 13. Variables File — `_variables.yml`

Small global variables used across the site (e.g. the "last updated" date in the footer). Edit directly:

```yaml
last_updated: "February 2026"
```
