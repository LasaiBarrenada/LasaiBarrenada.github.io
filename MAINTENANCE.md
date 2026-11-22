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
| Add a conference talk | `speaking/conferences.xlsx` (auto-updates Talks page + HTML & PDF CVs) |
| Add talk slides / poster PDF | `resources/` (linked via GitHub `blob/main/resources/<file>` in `speaking/conferences.xlsx`) |
| Force re-geocoding of a city | Remove its row from `speaking/geocache.csv` (or delete the file) and render |
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
| Change projects page styles | `html/projects.css` |
| Change timeline styles (speaking) | `html/timeline.css` |
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

**Exceptions:** The **Projects**, **Speaking**, **Software**, **Publications**, and **CV** (`cv/cv-page.qmd`) pages all have `freeze: false` set in their YAML header, so they always re-execute when rendered. The Publications page also sets `flush = TRUE` in `get_publications()` to bypass the `scholar` package cache and requests the complete profile list. Projects, Speaking, Software, and CV can be rendered directly after changing their data sources; Publications refreshes from Google Scholar on every render.

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

### Hero layout, CTA buttons & photo
- Three quick-action CTA buttons (`.hero_cta` / `.hero_btn` in `html/landing_page_styles.css`) sit below the bio paragraphs: **Explore Projects →**, **Publications**, and **CV (PDF)**.
- The headshot `<img src="/img/lasai_headshot.png" alt="Lasai Barreñada"/>` includes accessible `alt` text, and the email link uses a valid `mailto:lasai.barrenadataleb@kuleuven.be` href.

### Interactive regression Easter egg
The hero background canvas has an interactive feature on top of the particle animation:

1. A hint ("Click anywhere to place data points") appears in the top-right in site-blue (`#007BFF`) at opacity 0.65, fading very slowly (hidden when viewport width `< 700px` so it doesn't collide with the heading on mobile).
2. Clicking on the background (not on links/buttons) places a blue dot with a white border and a pop-in animation. A counter ("3 / 10") tracks progress.
3. At **10 dots**, a **LOESS curve** (span = 0.75, tricube kernel) is fitted through the points and drawn as a solid blue line. The **R²** value and the message "This is basically my job :)" appear in the top-right corner of the canvas.
4. A **"⟳ Random data"** button appears just below the tagline (top-right, `top: 56px`; hidden below `700px` on mobile). Clicking it clears any existing dots, generates 10 new random points spread across the canvas, and immediately fits + displays the LOESS and R². Clicking it again regenerates a fresh random set.
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

The page is a **non-linear two-section portfolio** generated by an R chunk (`tl-projects`) that reads `projects/projects.xlsx` and is styled via `html/projects.css` (using `.column-body-outset` for wider desktop cards):

1. **Milestones & Honours** (`.proj-honours-grid`): Horizontal multi-column strip displaying rows where `Category` is `Milestone` or `Award`.
   - **PhD Milestone** (`.proj-honour-milestone`): Green top border, laurel-tinted background, and green laureate link pill (`.proj-laurel-pill`) with symmetric inline SVG laurel branches (`.tl-laurel`).
   - **Awards** (`.proj-honour-award`): Gold top border, warm gold tint, and 🏆 award pill (`.proj-award-pill`).
2. **Research Projects** (`.proj-filter-bar` + `.proj-grid`): Interactive category filter pills (`All`, `Methodology`, `Clinical Utility`, `Ovarian Cancer`, `Preprints & Upcoming`) above a responsive 2-column Bento grid (1 column below `760px`).
   - Each card shows category & status badges (`Published`, `Accepted`, `Preprint`, `Upcoming`), date, linked title, venue, a 3-line clamped summary preview with an automatic `Read more ▸` / `Show less ▾` toggle when truncated, and footer pill links (`Paper`, `Preprint`, `Code`, `Package`, `CRAN`).
   - Upcoming entries (`Status == "Upcoming"` or blank `Link_1`) render with dashed muted borders (`.proj-card-upcoming`).

Because the R output is inserted into Markdown before Pandoc processes it, **no line of generated HTML may start with 4+ spaces** (same constraint as the speaking page). Keep all `sprintf()` / `paste0()` templates at ≤ 3-space indentation.

### Add or update a project
Open `projects/projects.xlsx` and add or edit a row. The columns are:

| Column | Description | Example |
|---|---|---|
| `Title` | Paper/project title | Clustered Flexible Calibration… |
| `Year` | Four-digit year | 2026 |
| `Month` | Numeric month (used for sorting; blank for undated upcoming) | 11 |
| `Venue` | Journal name, preprint server, or institution | Diagnostic and Prognostic Research |
| `OSF_ID` | Optional OSF node ID (also links papers onto OSF Software cards) | ngcj2 |
| `Link_1_name` | Label for the first link (or `"Dr. Barreñada"` / `"Award"`) | Paper |
| `Link_1` | URL for the first link (leave blank for upcoming) | https://… |
| `Link_2_name` | Label for the second link | Code |
| `Link_2` | URL for the second link | https://… |
| `Link_3_name` | Label for an optional third link (leave blank if none) | Package |
| `Link_3` | URL for the optional third link | https://… |
| `Summary` | 2–3 sentence plain-language summary | Two or three sentences… |
| `Category` | Section/filter tag (`Methodology`, `Clinical Utility`, `Ovarian Cancer`, `Milestone`, `Award`) | Clinical Utility |
| `Status` | Badge label (`Published`, `Accepted`, `Preprint`, `Upcoming`, `Milestone`, `Award`) | Published |
| `First_Author` | `TRUE` / `FALSE` / `NA` (tracks first-author paper coverage from `resources/Curriculum.xlsx`) | TRUE |

Freeze is disabled on this page, so just edit the Excel and re-render — no need to delete cache folders.

---

## 5. Talks Page — `speaking/speaking-page.qmd`

The page appears as **"Talks"** in the navbar (renamed from "Speaking"). The page has two sections:

1. **Timeline** — a filter pill bar (`All | Talks | Posters`, `.tl-filter-bar` / `.tl-filter-btn` in `html/timeline.css`) lets visitors filter by presentation type (`data-type` / `data-year`), and an R chunk (`tl-speaking`) reads the Excel, builds HTML cards, and outputs them via `cat()` with `results='asis'`. Shares timeline CSS with the projects page via `html/timeline.css`. **Year dividers** are automatically inserted between entries from different years (and hidden automatically when no entries in that year match the active filter).
2. **Map** — an R chunk (`map-data`) reads `conferences.xlsx` with `openxlsx`, checks a local geocoding cache (`speaking/geocache.csv`), queries ArcGIS only for new/uncached cities, and injects the coordinates as JSON for the **Leaflet** interactive map.

The map uses **Leaflet.js** with public OpenStreetMap tiles, so it does not require an API key. Conference locations and affiliated institutions are geocoded from their city names at render time using the ArcGIS geocoder and persisted in `speaking/geocache.csv` so subsequent renders are fast and work offline. Rendering stops with a clear error if the geocoding service is unavailable for an uncached city or returns no result, rather than generating a map without points. Clicking any marker opens a styled popup. The map works on both desktop and mobile with native touch support. Zoom is constrained (`minZoom: 2`, `maxBounds`) so only a single world view is shown.

### Map ↔ timeline linking & grouped city markers
Each timeline entry has a unique `id` attribute (e.g., `talk-iscb-2024`), generated in R from `Code_Name` and `Year` with `make.unique(..., sep = "-")` so multiple talks at the same conference/year stay distinct. Both `tl-speaking` and `map-data` sort by `-Year, -Month` so IDs match identically.

- **Map → timeline**: Conference markers are grouped by city so multiple talks in the same city share one marker instead of stacking; its popup lists every talk at that city, each with its own **"Show in timeline ↓"** link (`window._scrollToEntry`). Clicking it resets any active filter if needed, smooth-scrolls to the matching timeline entry, and applies a 2-second blue pulse highlight (`tl-highlight` class → `tl-flash` animation in `html/timeline.css`).
- **Timeline → map**: Every timeline card includes a **"Locate on map ↑"** link (`window._focusMapEntry`) that smooth-scrolls to the map, pans/zooms to that city's marker, and opens its popup.

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

### Talk slides and poster files (`resources/`)
Slides and poster files (PDFs, PPTX, HTML decks) live in the top-level `resources/` folder on the `main` branch rather than a separate `web_resources` repository. Because `resources/` is not listed in `_quarto.yml` → `project: resources:`, Quarto does **not** bundle these files into `_site/` / `gh-pages`; instead, `speaking/conferences.xlsx` links directly to them on GitHub via `https://github.com/LasaiBarrenada/LasaiBarrenada.github.io/blob/main/resources/<filename>` (URL-encoded if the filename contains spaces or special characters).

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

The page pulls your publication list live from **Google Scholar** (user ID `uPOL3NkAAAAJ`) using the `scholar` R package (`flush = TRUE`), resolves complete author lists for truncated entries (`...`), filters out non-authored entries (such as award announcements about you), and builds the interactive D3 co-authorship network and searchable publication list.

### When a new paper appears on Google Scholar
1. Run `quarto render Publications/publications-page.qmd` (or render the full site).
2. The R code fetches the complete profile list (`flush = TRUE`), resolves full author lists, re-runs deduplication, and rebuilds both `graphNodes`/`graphLinks` and `allPublications`.

### Multi-source full-author resolution (`graph-data` chunk)
Google Scholar truncates multi-author entries in the profile table with `, ...` and `scholar::get_complete_authors()` frequently returns `NA` under Google Scholar rate limits. For every truncated paper, `graph-data` resolves full author lists through a 4-tier fallback chain (formatted cleanly to `Initials Surname` while preserving multi-word particles like `Van Calster`, `van Smeden`, `De Cock Campo` and corporate groups like `IOTA 6 Collaborators`):

1. **Layer 1 — Local BibTeX files** (`cv/peer_bib_auto.bib`, `cv/other_bib_auto.bib`, `cv/peer_bib.bib`, in priority order) matched by normalized title Jaccard similarity (`>= 0.75`). Handles Zotero trailing particles (e.g., `Calster, Ben Van`), BibLaTeX `family=...`/`prefix=...` entries, and braced group authors.
2. **Layer 2a — OpenAlex ORCID works** (`https://api.openalex.org/works?filter=author.orcid:https://orcid.org/0000-0001-8020-0210&per-page=100`) matched by normalized title Jaccard similarity (`>= 0.70`), excluding `type == "dataset"` and `Replication Data` / `Correction` / `Erratum` records.
3. **Layer 2b — OpenAlex title search fallback** (`>= 0.75` similarity, verified to contain a `Barreñada` author), also excluding datasets/corrections.
4. **Layer 3 — `scholar::get_complete_authors()` fallback** if still unresolved.

After full author resolution, any Scholar entry where no author matches `barre[nñ]` (such as third-party prize announcements) is excluded. Malformed Scholar venue strings (e.g., `arXiv preprint arXiv:, :2610.37353`) are formatted cleanly (`arXiv:2610.37353`), and `Clean_pubs` / `pubs_by_author` / `allPublications` are consistently ordered by `-year, -cites`.

### Author name deduplication
Two-stage canonicalization handles surface variants and initial differences:

1. **`manual_corrections`** near the middle of `graph-data` maps abbreviations, particles, and encoding artefacts before automated grouping:
```r
manual_corrections <- c(
  "G Collins"        = "GS Collins",
  "JF Calatrava"     = "J Fernández Calatrava",
  "JCGS de Cueto"    = "JC Gálvez Sainz de Cueto",
  "JYJ Verbakel"     = "JY Verbakel",
  "BV Calster"       = "B Van Calster",
  "BD Moor"          = "B De Moor",
  "BDC Campo"        = "B De Cock Campo",
  "B De Cock"        = "B De Cock Campo",
  "TH Bourne"        = "T Bourne",
  "RR Zegarra"       = "R Ramirez Zegarra",
  "Rén Armañanzas"   = "R Armañanzas"
)
```
2. **Stage 1 (accent/case preference)** groups names sharing the same transliterated lowercase key (`M Martinez-Garcia` ≡ `M Martínez-García`), preferring forms with accented Unicode characters, longer initials, and higher frequency.
3. **Stage 2 (initial-prefix merge with co-occurrence guard)** automatically merges unambiguous initial prefixes sharing an exact surname (e.g., `A Vickers` → `AJ Vickers`, `E Steyerberg` → `EW Steyerberg`) **only** when the two forms have zero co-occurrence on the same paper — preventing distinct authors like `H Lee` and `HC Lee` on the *Nature Medicine* paper from being merged. Corporate/consortium names (`Collaborators`, `Consortium`, `Group`, `Committee`) are kept in the paper's `authors` string but excluded from collaborator counts.

If a new co-author appears under an unexpected abbreviation or nickname, add an entry to `manual_corrections`:
```r
"Garbled form"  = "Canonical form"
```

### Publication deduplication (preprint + journal)
The pipeline detects preprint/working-paper duplicates (`arxiv|biorxiv|medrxiv|zenodo|preprint|working paper|statistics spain`) by comparing titles with Jaccard similarity. If a preprint on Google Scholar gets published and both entries appear simultaneously, the preprint is dropped when Jaccard similarity ≥ 0.28 with a published paper.

### The network only shows co-authors with ≥ 2 shared papers
This is controlled by the `filter(n_papers >= 2)` line in the R chunk. Change `2` to any other threshold if needed. Co-authors are ordered via hierarchical clustering (`stats::hclust(..., method = "average")` on a binary co-author × paper matrix) and assigned `order_idx` so D3 initializes research communities in adjacent radial sectors.

### Visual enhancements & searchable publication list (D3 + JS)
The network (`W = 860`, `H = 600`) uses several visual and usability enhancements in the `<script>` block:

- **Scaled radial geometry & clustered initialization**: `colorScale`, `rScale` (`[8, 22]`), and `distScale` (`[225, 92]`) scale over actual `[minP, maxP]` counts so outer nodes stay cleanly inside the SVG bounds (`padX = 56`, `padTop = 30`, `padBottom = 28`), initialized by `order_idx` with light centering forces and collision radius `+ 22`.
- **Focus + dim**: Hovering or clicking a node highlights it and its connected links/nodes; everything else fades to 12% opacity (`DIM_OPACITY`). When a node is selected (clicked), hover on other nodes does not change the focus — only clicking a new node or the background changes it.
- **Label halos & clamped tooltips**: Co-author surname labels render with a `#f4f8fd` `paint-order: stroke` halo for legibility across links, and `#graph-tooltip` coordinates are clamped inside `#graph-container` bounds. The legend dynamically renders actual `minP` and `maxP` shared-paper counts.
- **Mobile touch hit targets**: Transparent overlay circles (`hitSel`, minimum radius 20 px) handle pointer, drag, and tap events so smaller co-author nodes remain easy to tap on touch screens.
- **Gradient nodes & curved links**: Each node uses a radial gradient + drop shadow (center node uses `center-glow`); links alternate quadratic Bézier curve direction (`sign = i % 2`).
- **Full searchable publication list (`#pub-list-section`)**: Below the chart, R injects `allPublications` (deduplicated, sorted by `-year, -cites`) and JS renders a publication list with a live search box (`#pub-search`), a **Sort: Year | Citations** toggle (`.pub-sort-btn` — Year groups entries under year headers; Citations renders a flat list sorted by citation count with year badges), author self-highlighting, preprint/citation badges, and a count indicator. Clicking any co-author node in the D3 network filters `#pub-full-list` directly and highlights the selected collaborator's links (clicking the node again, clicking the center node, clicking the SVG background, or clicking the filter pill's `×` clears the filter and restores all publications).

---

## 7. CV

The CV exists in two forms:

| File | Purpose |
|---|---|
| `cv/cv-page.qmd` | **HTML page** shown on the website — renders the CV content directly (`freeze: false`), pulls Conference Presentations from `speaking/conferences.xlsx`, bolds `"Barreñada, L."` in `#refs` via JS, and includes a TOC + "Download PDF" button |
| `cv/cv.qmd` | **PDF source** using `quarto-cv-pdf` format — pulls Conference Presentations from `speaking/conferences.xlsx` and generates `cv.pdf` for download |

Both files should be kept in sync when you add new jobs, education, awards, grants, or fellowships. **Conference presentations** are read automatically from `speaking/conferences.xlsx` in both files, so you only need to update the spreadsheet.

### Add a new entry (job, education, award, grant, etc.)
Update **both** files (Conference Presentations are automatic via `speaking/conferences.xlsx`):

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
- `cv-page.qmd` uses `engine: knitr` (needed for `Sys.Date()` and the `cv-conferences` R chunk).
- `cv-page.qmd` has `freeze: false` so `Sys.Date()`, `speaking/conferences.xlsx`, and `peer_bib.bib` always stay up to date on render.
- In HTML output, Pandoc's built-in `citeproc` runs after `post-quarto` Lua filters, so `cv-page.qmd` bolds `Barreñada, L.` inside `#refs` via a small `DOMContentLoaded` script instead of `highlight-author.lua` (which is used for the PDF CVs `cv.qmd` and `cv_onlypubs.qmd`).

---

## 8. Software Page — `software/software-page.qmd`

The page displays repositories from three platforms (`freeze: false`):

1. **GitHub** (username `LasaiBarrenada`) — pre-fetched at build time by R (`github-build-cache` chunk) into `window.GITHUB_BUILD_CACHE` for instant rendering, and refreshed in the browser via client-side JS.
2. **GitLab (KU Leuven)** (username `u0158158` at `gitlab.kuleuven.be`) — owned and contributed public projects fetched at build time by R (`gitlab-projects` chunk) and displayed under **GitLab Projects (KU Leuven)**.
3. **OSF** (user ID `pgkjv`) — public top-level projects fetched at build time by R (`osf-projects` chunk) and displayed in a separate card grid below.

### How it works — GitHub
1. **Build-time cache (`github-build-cache`)**: At render time, R fetches owned repos and `CONTRIB_REPOS` from GitHub's API (using `curl` with a `User-Agent` header when available) and embeds trimmed metadata in `window.GITHUB_BUILD_CACHE`.
2. **Instant render + live refresh**: On page load, if `window.GITHUB_BUILD_CACHE` is populated, cards render immediately with zero spinner flash. A background `fetch()` to `https://api.github.com/users/LasaiBarrenada/repos?type=owner&sort=pushed&per_page=100` (plus `CONTRIB_REPOS`) refreshes star counts and push dates. If the live request fails (e.g., 403 unauthenticated rate limit on shared institutional Wi-Fi), the build-time cards remain visible instead of showing an error.
3. Repos are displayed in a responsive 2-column card grid (1 column on mobile), sorted by stars descending. Each card shows the repo name (linked), description, primary language with a coloured dot, star count, contributor badge (if applicable), topic tags, and a relative "Updated X ago" timestamp.

### Configuration — GitHub (inside the first `<script>` block)
| Variable | Purpose |
|---|---|
| `USERNAME` | GitHub username to fetch repos from (currently `LasaiBarrenada`) |
| `EXCLUDE_REPOS` | Array of repo names to hide — currently `LasaiBarrenada.github.io` (website), `LasaiBarrenada` (profile config), `web_resources` (web assets) |
| `CONTRIB_REPOS` | Array of `owner/repo` strings for external repos the user contributes to — fetched individually and shown with a "Contributor" badge |
| `LANG_COLORS` | Map of language names → hex colours for the dot indicator |

### How it works — GitLab (KU Leuven)
The `gitlab-projects` R chunk queries both `https://gitlab.kuleuven.be/api/v4/users/u0158158/projects?per_page=100` and `.../contributed_projects?per_page=100` at build time, deduplicates by project `id`, excludes archived projects and `gitlab_exclude` (`u0158158`), sorts by `last_activity_at` descending, and fetches `/api/v4/projects/{id}/languages` for each project (preferring programming languages such as `R` over `HTML`/`CSS`/`SCSS`/`JavaScript`). Cards display the full `path_with_namespace`, a red-orange `"GitLab"` badge (`.sw-gitlab-badge`), description, topic pills (`.sw-topic-gitlab`), primary language dot, and `"Updated Mon YYYY"`.

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
Card grid styles are in `html/software.css`. The page loads this file with a `<link>` tag. Do not inline styles in the page file. GitLab-specific styles (`.sw-gitlab-badge`, `.sw-topic-gitlab`, `.sw-card-gitlab:hover`) and OSF-specific styles (`.sw-osf-badge`, `.sw-osf-category`, `.sw-topic-osf`, `.sw-card-osf:hover`, `.sw-section-heading`, `.sw-papers`, `.sw-paper-link`) are also in `software.css`.

### Gotchas
- The GitHub public API allows **60 requests/hour** without authentication. Because `github-build-cache` embeds build-time data in `window.GITHUB_BUILD_CACHE`, visitors on shared networks won't hit a broken empty page if the live browser fetch is rate-limited (the error fallback only appears if both the live fetch and build-time cache are unavailable).
- The OSF public API has no documented unauthenticated rate limit, but is similarly generous. If it fails, a fallback message with a link to the OSF profile is shown.
- Archived repos are automatically excluded (GitHub). Forked repos are filtered out from the main fetch.
- To showcase external repos the user contributes to (via commits/PRs), add the upstream `owner/repo` path to the `CONTRIB_REPOS` array — these are fetched individually and shown with a "Contributor" badge.
- Each entry in `CONTRIB_REPOS` uses one extra API call, so keep the list short to stay within the 60 req/hr limit.

---

## 9. Site-wide Settings — `_quarto.yml`

Search is **disabled** (`search: false`). The website title is set to `"Lasai Barreñada"` (short form — the full `"Medical Statistician | FWO Postdoctoral Fellow | Prediction models, Healthcare, Research"` description is in `description-meta` for SEO only). The navbar tab for talks is labelled **"Talks"** (the page file remains in the `speaking/` folder). The `navbar: right:` social links are Google Scholar, ORCID, LinkedIn, and email (all with `aria-label` attributes), and the footer's "Last updated" reads `{{< var last_updated >}}` from `_variables.yml`.

Under `project: resources:`, `img/**`, `html/*.css`, and `_redirects` are declared explicitly so Quarto always copies all custom CSS files into `_site/html/` even when `<link>` tags use cache-busting query strings (`?v=YYYYMMDD`).

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
| `html/styles.scss` | Global font (Inter via Bunny Fonts `fonts.bunny.net` for body and headings), link colours, spacing, **navbar responsive sizing** — applied to all pages |
| `html/projects.css` | Non-linear Projects page styles (Milestones & Honours strip, filter bar, 2-column Bento grid, category accents, 3-line summary toggle) |
| `html/timeline.css` | Timeline styles for the Speaking page (cards, dots, dates, links, badges, filter pills `.tl-filter-bar`, expand/collapse with `max-height: 800px`, mobile breakpoints) |
| `html/software.css` | Card grid, GitLab badge, and OSF component card styles on the Software page |
| `html/landing_page_styles.css` | Hero section layout and `.hero_cta` / `.hero_btn` buttons on the landing page |
| `html/seo.html` | Meta tags injected into every page `<head>` |

Whenever you modify one of the standalone custom CSS files (`landing_page_styles.css`, `projects.css`, `timeline.css`, `software.css`), also bump the `?v=YYYYMMDD` cache-busting query string on its `<link>` tag in the corresponding `.qmd` file (`index.qmd`, `projects/projects-page.qmd`, `speaking/speaking-page.qmd`, or `software/software-page.qmd`) so browsers and GitHub Pages CDN don't pair newly deployed HTML with stale cached CSS.

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

Small global variables used across the site — notably `last_updated`, which renders in the page footer via `{{< var last_updated >}}`. Edit directly:

```yaml
last_updated: "November 2026"
```
