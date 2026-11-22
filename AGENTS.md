# AI Assistant Memory — Lasai Barreñada's Academic Website

Personal academic Quarto website for Lasai Barreñada, a medical statistician at KU Leuven.  
**Live URL:** https://lasaibarrenada.github.io/  
**Source repo:** https://github.com/LasaiBarrenada/LasaiBarrenada.github.io/

---

## Before you do anything

**Always read `MAINTENANCE.md` before touching any file.** It is the authoritative guide to how every part of the site works, and it is kept up to date after every session. This AGENTS.md is a quick-start summary; MAINTENANCE.md has the full detail.

## After every change

**Always update both `MAINTENANCE.md` and `AGENTS.md` at the end of every session (or after any meaningful change).** Both files must stay in sync with the actual state of the site. If you add, remove, or modify any feature, page, style rule, or gotcha, document it in both files before finishing.

---

## Project structure

```
_quarto.yml                  # Site config: navbar, footer, theme, freeze, search:false
_variables.yml               # Global variables, e.g. last_updated date
index.qmd                    # Landing page (hero, particle canvas, Easter egg)
projects/
  projects-page.qmd          # Non-linear Milestones & Honours + filterable Bento grid (reads projects.xlsx)
  projects.xlsx              # Data source for projects grid, honours strip, and OSF paper links
speaking/
  speaking-page.qmd          # Talks page — reads conferences.xlsx + Leaflet map
  conferences.xlsx           # Data source for talks timeline, map, and CV presentations
  geocache.csv               # Cached city coordinates for the Talks Leaflet map
Publications/
  publications-page.qmd      # Co-authorship network (D3) + searchable paper list from Google Scholar
software/
  software-page.qmd          # Software page — GitHub (R build cache + JS), KU Leuven GitLab (R), OSF (R)
cv/
  cv-page.qmd                # HTML CV page (freeze:false, dynamic talks, JS author bolding)
  cv.qmd                     # PDF CV source (quarto-cv-pdf format, dynamic talks)
  cv.pdf                     # Rendered PDF linked from cv-page
  peer_bib.bib               # BibTeX publications list
html/
  styles.scss                # Global SCSS: fonts, colors, navbar responsive rules
  projects.css               # Honours strip, filter bar, and 2-column Bento grid CSS for Projects page
  timeline.css               # Timeline CSS for speaking page
  software.css               # Card grid CSS for the software page
  landing_page_styles.css    # Hero section layout
  seo.html                   # Meta tags injected into every page <head>
img/
  lb_logo_opt1.svg           # Navbar logo (LB initials)
  favicon.svg                # Browser tab icon
  lasai_headshot.png         # Profile photo on landing page
  website_thumbnail.png      # Social preview image
  logo_kuleuven.svg          # KU Leuven logo (spare, not used on site)
  logo_umcutrecht.svg        # UMC Utrecht logo (spare, not used on site)
  logo_msk.jpeg              # Memorial Sloan Kettering logo (spare, not used on site)
resources/                   # Talk slides & poster files on main branch (not copied to _site/)
404.qmd                      # Custom 404 page — styled HTML with {NA} R theme + home button
license/index.qmd            # License page (MIT code + copyright content)
MAINTENANCE.md               # Full maintenance guide — always read this first
AGENTS.md                    # This file
```

---

## Key site behaviours

### Freeze
`execute: freeze: true` globally — R code is cached in `_freeze/` and only re-runs when the cache is deleted. **Exceptions:** `projects-page.qmd`, `speaking-page.qmd`, `software-page.qmd`, `Publications/publications-page.qmd`, and `cv/cv-page.qmd` all have `freeze: false` — they always re-execute on render. The Publications page also bypasses the `scholar` package cache and explicitly fetches the complete profile list.

### Deployment
```bash
quarto render        # builds _site/
quarto preview       # local hot-reload at localhost:22222
quarto publish gh-pages   # push to GitHub Pages
```
`_quarto.yml` lists `"html/*.css"` under `project: resources:` so Quarto always copies custom CSS files (`landing_page_styles.css`, `projects.css`, `timeline.css`, `software.css`) to `_site/html/`. Their `<link>` tags in `index.qmd`, `projects/projects-page.qmd`, `speaking/speaking-page.qmd`, and `software/software-page.qmd` include `?v=20261122` cache-busting query strings — bump `?v=YYYYMMDD` whenever editing any CSS file in `html/`.

### Search
Disabled globally with `search: false` in `_quarto.yml`. Do NOT add it back without being asked — it was intentionally removed.

### Navbar & Footer
- Logo: `img/lb_logo_opt1.svg`, max-height 44px desktop / 28px mobile
- Title: `"Lasai Barreñada"` (short — `"Medical Statistician | FWO Postdoctoral Fellow | Prediction models, Healthcare, Research"` is in `description-meta` for SEO only)
- Tabs (left): Home, Projects, **Talks** (file is in `speaking/`), CV, Publications, Software
- Social icons (right): Google Scholar, ORCID, LinkedIn, email — all with `aria-label`
- Footer `Last updated` reads `{{< var last_updated >}}` from `_variables.yml`
- Mobile: logo flush left, hamburger flush right — controlled by `@media (max-width: 991.98px)` in `styles.scss`

The landing-page hero uses 6rem of top padding and start-aligns `.hero_content` in `html/landing_page_styles.css` so its heading clears the pinned navbar without being vertically centered on desktop.

---

## Landing page (`index.qmd`)

The hero section has:
- A **particle animation** canvas (`#hero-canvas`) — 60 floating dots with connecting lines, drawn with vanilla JS. `pointer-events: none` on the canvas so clicks pass through.
- An **interactive LOESS Easter egg** — click on the hero background to place blue data points. At 10 points, a LOESS curve (tricube kernel, span=0.75) is fitted and R² is shown in the top-right. A "⟳ Random data" button (top-right, `top:56px`) auto-generates 10 random points. 11th click resets everything. Both `#random-btn` and the top-right hint text are hidden below `700px` on mobile so they don't overlap the hero title.
- Profile photo (`img/lasai_headshot.png`, `alt="Lasai Barreñada"`), bio text in `<p>` tags (with valid `mailto:lasai.barrenadataleb@kuleuven.be`), and quick-action CTA buttons (`.hero_cta` / `.hero_btn` in `html/landing_page_styles.css`: **Explore Projects →**, **Publications**, **CV (PDF)**) inside the `{=html}` block.
- Quarto 1.9+ can hoist the first hero heading into the page title block if it is an `<h1>`; the hero now uses `.hero_title`, and `#title-block-header` is hidden in `html/landing_page_styles.css` to keep the page flush under the navbar.

---

## Projects page (`projects/projects-page.qmd`)

- R chunk `tl-projects` reads `projects/projects.xlsx` (including `Category`, `Status`, `First_Author`, and `OSF_ID` columns synced from `resources/Curriculum.xlsx` first-author papers) and renders two non-linear sections inside `.column-body-outset`:
  1. **Milestones & Honours** (`.proj-honours-grid`): Horizontal strip for `Category %in% c("Milestone", "Award")` sorted by `-Year, -Month`. The PhD defended milestone uses `.proj-honour-milestone` (green accent) and `.proj-laurel-pill` with inline SVG laurel branches flanking `"Dr. Barreñada"`; awards use `.proj-honour-award` (gold accent + 🏆).
  2. **Research Projects** (`.proj-filter-bar` + `.proj-grid`): Interactive category filter pills (`All`, `Methodology`, `Clinical Utility`, `Ovarian Cancer`, `Preprints & Upcoming`) above a responsive 2-column Bento grid (1 column below `760px`). Cards display category-colored top accents, status pills (`Published`, `Accepted`, `Preprint`, `Upcoming`), 3-line clamped summaries with `Read more ▸` / `Show less ▾` toggles (auto-hidden when not truncated), and footer link pills.
- ⚠️ No line of generated HTML may start with 4+ spaces — Pandoc treats that as a code block.
- Styled via `html/projects.css`.

---

## Talks page (`speaking/speaking-page.qmd`)

- Navbar tab is labelled **"Talks"** — the file lives in `speaking/`.
- Filter pill bar (`All | Talks | Posters`, `.tl-filter-bar` / `.tl-filter-btn`) filters timeline entries (`data-type` / `data-year`) and automatically hides empty year dividers.
- Same timeline structure as projects (R chunk `tl-speaking`, year dividers, `html/timeline.css`).
- **Map**: R chunk `map-data` reads `conferences.xlsx` with `openxlsx`, resolves city coordinates via a local cache (`speaking/geocache.csv`), queries ArcGIS only for uncached cities, and injects coordinates as JS arrays (`conferenceData`, `universityData`). The map is built with **Leaflet.js** + public OpenStreetMap tiles. Rendering stops if geocoding returns missing coordinates. Red circles = conferences (grouped by city so multiple talks in one city share a marker and multi-entry popup); blue pulsing circles = affiliated institutions (KU Leuven, UMC Utrecht, Memorial Sloan Kettering). Popups on click, works on mobile. No travel arcs. Zoom constrained to a single world view (`minZoom: 2`, `maxBounds`).
- **Map ↔ timeline linking**: each timeline entry has a unique `id` (e.g., `talk-iscb-2024`, disambiguated with `make.unique(..., sep = "-")` in R). Conference popups have "Show in timeline ↓" links (`window._scrollToEntry`, which also resets active filters if hidden) that smooth-scroll to the entry and highlight it with a blue pulse (`tl-highlight` class). Timeline cards have a "Locate on map ↑" link (`window._focusMapEntry`) that pans to the city's marker and opens its popup.
- **University popups**: UMC Utrecht and MSK show "Visiting Researcher" below the name; KU Leuven does not (home institution).
- Affiliated institutions are defined in the `map-data` R chunk as a `uni_coords` data frame.
- Talk slides and posters are stored in `resources/` on `main` (not bundled into `_site/`) and linked from `speaking/conferences.xlsx` via `https://github.com/LasaiBarrenada/LasaiBarrenada.github.io/blob/main/resources/<file>`.
- ⚠️ Same 4-space indentation constraint as the projects page.

---

## Publications page (`Publications/publications-page.qmd`)

- Pulls publication records live from **Google Scholar** (user ID `uPOL3NkAAAAJ`) via `scholar::get_publications(..., flush = TRUE)`, resolving truncated (`...`) author lists through a 4-layer pipeline (because `scholar::get_complete_authors()` often returns `NA`):
  1. Local BibTeX files (`../cv/peer_bib_auto.bib`, `../cv/other_bib_auto.bib`, `../cv/peer_bib.bib`, title Jaccard `>= 0.75`), handling Zotero trailing particles, BibLaTeX `family=`/`prefix=` fields, and `{IOTA 6 Collaborators}`.
  2. OpenAlex works filtered by ORCID `0000-0001-8020-0210` (`per-page=100`, Jaccard `>= 0.70`), excluding `type == "dataset"` and `Replication Data`/`Correction` entries.
  3. OpenAlex title search fallback (`per-page=5`, Jaccard `>= 0.75`, requiring `Barreñada` in authors).
  4. `scholar::get_complete_authors()` fallback.
- Excludes non-authored Scholar entries (no `barre[nñ]` author match, e.g., third-party award announcements), drops duplicate preprints when title Jaccard similarity `>= 0.28` against a published paper, and normalizes malformed arXiv venue strings.
- Author deduplication: `manual_corrections` (particles/abbreviations), Stage 1 transliterated grouping preferring accented spellings (`M Martínez-García`, `S García-Gutiérrez`), and Stage 2 automatic initial-prefix merging (`A Vickers` → `AJ Vickers`, `E Steyerberg` → `EW Steyerberg`) guarded by a same-paper co-occurrence check so distinct collaborators like `H Lee` and `HC Lee` never merge. Corporate group authors (`Collaborators`/`Consortium`/`Group`/`Committee`) stay in displayed `authors` but are excluded from collaborator nodes.
- Builds a **D3 force-directed co-authorship network** (`W = 860`, `H = 600`) for co-authors with `>= 2` shared papers, ordered via `hclust` (`order_idx`) into community sectors, scaled dynamically over `[minP, maxP]` (`distScale` `[225, 92]`, `rScale` `[8, 22]`, dynamic legend), with label stroke halos, clamped edges/tooltips, and wider touch targets (`hitSel`, min radius 20 px).
- Renders a **full searchable, sortable publication list** (`#pub-list-section`) below the network from `allPublications`, featuring live search (`#pub-search`), a **Year | Citations** sort toggle (`.pub-sort-btn`), author self-bolding, preprint/citation badges, and direct filtering when clicking a co-author node in the graph (cleared by re-clicking the node, clicking the center node, clicking the SVG background, or clicking the filter pill's `×`).
- ⚠️ D3 hover tooltips use `mouseover` — on touch screens tap nodes to filter the publication list directly.

---

## Software page (`software/software-page.qmd`)

- Three sections — GitHub uses a build-time R cache + client-side JS refresh, while KU Leuven GitLab and OSF are fetched at build time by R:
  1. **GitHub** repos (username `LasaiBarrenada`): R chunk `github-build-cache` pre-fetches owned repos and `CONTRIB_REPOS` into `window.GITHUB_BUILD_CACHE` for instant rendering (no spinner flash) and automatic fallback if the browser hits GitHub's 60 req/hr limit; client-side JS refreshes live in the background.
  2. **GitLab (KU Leuven)** projects (username `u0158158` at `gitlab.kuleuven.be`): R chunk `gitlab-projects` fetches owned and `contributed_projects` via GitLab API v4, deduplicates by `id`, excludes archived and `gitlab_exclude` (`u0158158`), fetches `/languages` per project (preferring programming languages over HTML/CSS/SCSS/JS), and renders `.sw-card-gitlab` cards sorted by `last_activity_at`.
  3. **OSF** projects (user ID `pgkjv`) via the OSF API v2 (R chunk `osf-projects`, because the OSF API does not support CORS).
- Page has `freeze: false` so GitHub build cache, GitLab projects, and OSF data refresh on every render.
- All three sections use a responsive 2-column card grid (`html/software.css`).
- **GitHub cards** show: repo name (linked), description, language with colour dot, star count, contributor badge, topic tags, and relative "Updated X ago" timestamp.
- **GitLab cards** show: `path_with_namespace` (linked), `"GitLab"` badge (`.sw-gitlab-badge`), description, topic pills (`.sw-topic-gitlab`), primary language dot, and absolute `"Updated Mon YYYY"` timestamp.
- **OSF cards** show: project title (linked), "OSF" badge (dark blue `#214370`), category label, description, tags, related paper links, child components (fetched via `/nodes/{id}/children/`, shown in a shaded "Components" box), and absolute date ("Updated Mar 2026"). Only top-level projects are shown (child components filtered out by `root.data.id === node.id`). Sorted by most recently modified.
- **Related papers on OSF cards**: looked up in two ways — (1) via an `OSF_ID` column in `projects/projects.xlsx` (preferred, avoids duplication), or (2) via the `osf_extra_papers` named list in the R chunk (for papers not in the spreadsheet). Both sources are merged; multiple papers per project are supported.
- **Excluded repos** are listed in the `EXCLUDE_REPOS` array: `LasaiBarrenada.github.io`, `LasaiBarrenada`, `web_resources`, `quarto_mc_template`, `academicpages.github.io`, `BD_Colegios_Email`, `Disenos-de-registro`, `NTTS2021_Hackathon_UCM`.
- Forked repos are hidden. External repos the user contributes to are listed in `CONTRIB_REPOS` as `owner/repo` strings (`BavoDC/CalibrationCurves`, `thomas-sounack/TRIPOD-Code`, `benvancalster/PerfMeasuresOverview`) — fetched individually and shown with a "Contributor" badge.
- Archived repos are automatically filtered out.
- Graceful fallback for both APIs: if client-side GitHub fetch fails without a build cache, or if OSF fails at build time, a message with a direct link to the respective profile is shown.
- ⚠️ The GitHub public API allows 60 requests/hour unauthenticated, mitigated by `window.GITHUB_BUILD_CACHE`. OSF has no strict documented limit.

---

## CV pages (`cv/cv-page.qmd`, `cv/cv.qmd`, `cv/cv_onlypubs.qmd`)

- `cv/cv-page.qmd` has `freeze: false`, reads Conference Presentations directly from `speaking/conferences.xlsx` (`cv-conferences` chunk), includes Fellowships/Grants/Peer Review synced with `cv/cv.qmd`, and bolds `"Barreñada, L."` inside `#refs` via an inline `DOMContentLoaded` script (because Pandoc's `citeproc` runs after `post-quarto` Lua filters in HTML mode).
- `cv/cv.qmd` reads Conference Presentations dynamically from `speaking/conferences.xlsx` (`cv-pdf-conferences` chunk) and uses `highlight-author.lua` for PDF author bolding.

---

## Timeline CSS (`html/timeline.css`)

Used by the speaking page (`projects/projects-page.qmd` uses `html/projects.css`). Contains:
- `.tl-wrapper`, `.tl-entry`, `.tl-date`, `.tl-card`, `.tl-title`, `.tl-venue`
- `.tl-links`, `.tl-links a`, `.tl-award` (gold award style with 🏆)
- `.tl-type`, `.tl-type-talk`, `.tl-type-poster`, `.tl-type-upcoming`
- `.tl-filter-bar`, `.tl-filter-btn` — filter pill bar on the Talks page
- `.tl-year-divider` — bold blue year label with a dash on the timeline line
- `.tl-toggle`, `.tl-summary` — expand/collapse animation (`max-height: 800px` when open)
- `@media (max-width: 600px)` mobile rules

**Do not inline timeline styles in the page files.** Both pages load this file with a `<link>` tag.

---

## Global styles (`html/styles.scss`)

- Body and heading font: **Inter** (loaded from Bunny Fonts `fonts.bunny.net`)
- Accent colour: `#007BFF`
- Navbar responsive block at `@media (max-width: 991.98px)`:
  - Logo shrinks to 28px
  - Container-fluid uses `flex-wrap: wrap` — **must stay `wrap`** so the collapse menu drops to a new row; `nowrap` causes the mobile menu to overlap
  - `.navbar-brand`: `order:0`, `margin-right:auto`, `flex-shrink:0`
  - `.navbar-toggler`: `order:1`, `margin-left:0.5rem`, `flex-shrink:0`
  - `.navbar-collapse`: `order:2`, `flex-basis:100%` — ensures full-width second row
  - Social icons get `flex-wrap: wrap` on mobile to avoid horizontal overflow
  - ⚠️ Do NOT add `margin-left: auto` to the toggler — it conflicts with `margin-right: auto` on the brand and causes overlap.
  - ⚠️ Do NOT change `flex-wrap: wrap` to `nowrap` on the container-fluid — it breaks the mobile menu.

---

## Common gotchas

| Gotcha | Detail |
|---|---|
| 4-space indent in R-generated HTML | Pandoc treats it as a code block — keep all `sprintf` templates ≤ 3 spaces |
| Freeze not updating | Delete the relevant `_freeze/<page>/` folder and re-render |
| Search reappearing | It's disabled with `search: false` — removing the line re-enables the default (on) |
| Hamburger overlapping logo | `margin-left: auto` on toggler conflicts with `margin-right: auto` on brand — use only the brand's auto margin |
| Mobile menu overlaps content | Container-fluid must use `flex-wrap: wrap` (not `nowrap`) — the collapse div needs to drop to a second row |
| D3 tooltips on mobile | The Publications network uses `mouseover` for hover tooltips; transparent `hitSel` targets (min radius 20 px) handle mobile taps to filter the list |
| HTML CV author bolding | Pandoc `citeproc` runs after `post-quarto` Lua filters in HTML output, so `cv-page.qmd` bolds `Barreñada, L.` in `#refs` via JS |
| Logo SVG needs explicit dimensions | SVGs without `width`/`height` attributes collapse to zero in some browsers |
| Map geocoding needs internet (first time) | Uncached cities in `speaking/speaking-page.qmd` use `tidygeocoder`; once cached in `speaking/geocache.csv`, renders work offline |
