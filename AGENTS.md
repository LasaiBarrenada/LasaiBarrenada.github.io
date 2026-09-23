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
  projects-page.qmd          # Timeline page — reads projects.xlsx via R
  projects.xlsx              # Data source for projects timeline
speaking/
  speaking-page.qmd          # Talks page — reads conferences.xlsx + Leaflet map
  conferences.xlsx           # Data source for talks timeline and map
Publications/
  publications-page.qmd      # Co-authorship network (D3) from Google Scholar
software/
  software-page.qmd          # Software page — GitHub (client JS) + OSF (R build-time)
cv/
  cv-page.qmd                # HTML CV page (freeze:true)
  cv.qmd                     # PDF CV source (quarto-cv-pdf format)
  cv.pdf                     # Rendered PDF linked from cv-page
  peer_bib.bib               # BibTeX publications list
html/
  styles.scss                # Global SCSS: fonts, colors, navbar responsive rules
  timeline.css               # Shared timeline CSS for projects + speaking pages
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
404.qmd                      # Custom 404 page — styled HTML with {NA} R theme + home button
license/index.qmd            # License page (MIT code + copyright content)
MAINTENANCE.md               # Full maintenance guide — always read this first
AGENTS.md                    # This file
```

---

## Key site behaviours

### Freeze
`execute: freeze: true` globally — R code is cached in `_freeze/` and only re-runs when the cache is deleted. **Exceptions:** `projects-page.qmd`, `speaking-page.qmd`, `software-page.qmd`, and `Publications/publications-page.qmd` all have `freeze: false` — they always re-execute on render. The Publications page also bypasses the `scholar` package cache and explicitly fetches the complete profile list.

### Deployment
```bash
quarto render        # builds _site/
quarto preview       # local hot-reload at localhost:22222
quarto publish gh-pages   # push to GitHub Pages
```

### Search
Disabled globally with `search: false` in `_quarto.yml`. Do NOT add it back without being asked — it was intentionally removed.

### Navbar
- Logo: `img/lb_logo_opt1.svg`, max-height 44px desktop / 28px mobile
- Title: `"Lasai Barreñada"` (short — description is in `description-meta` for SEO only)
- Tabs (left): Home, Projects, **Talks** (file is in `speaking/`), CV, Publications, Software
- Social icons (right): GitHub, LinkedIn, ORCID, Google Scholar, ResearchGate, Bluesky, email, RSS
- Mobile: logo flush left, hamburger flush right — controlled by `@media (max-width: 991.98px)` in `styles.scss`

---

## Landing page (`index.qmd`)

The hero section has:
- A **particle animation** canvas (`#hero-canvas`) — 60 floating dots with connecting lines, drawn with vanilla JS. `pointer-events: none` on the canvas so clicks pass through.
- An **interactive LOESS Easter egg** — click on the hero background to place blue data points. At 10 points, a LOESS curve (tricube kernel, span=0.75) is fitted and R² is shown in the top-right. A "⟳ Random data" button (top-right, `top:56px`) auto-generates 10 random points. 11th click resets everything.
- Profile photo (`img/lasai_headshot.png`) and bio text in `<p>` tags inside the `{=html}` block.
- Quarto 1.9+ can hoist the first hero heading into the page title block if it is an `<h1>`; the hero now uses `.hero_title`, and `#title-block-header` is hidden in `html/landing_page_styles.css` to keep the page flush under the navbar.

---

## Projects page (`projects/projects-page.qmd`)

- R chunk `tl-projects` reads `projects/projects.xlsx`, sorts by `-Year, -Month`, and builds HTML cards via `sprintf()`/`paste0()` with `cat(..., results='asis')`.
- **Year dividers** are inserted automatically when the year changes between entries.
- Upcoming projects (no `Link_1`) get a grey hollow dot, grey card, and "Upcoming" badge.
- Links with "Award" in the name get a **gold style** with 🏆 icon (class `tl-award`).
- ⚠️ No line of generated HTML may start with 4+ spaces — Pandoc treats that as a code block.
- Shares all timeline CSS from `html/timeline.css`.

---

## Talks page (`speaking/speaking-page.qmd`)

- Navbar tab is labelled **"Talks"** — the file lives in `speaking/`.
- Same timeline structure as projects (R chunk `tl-speaking`, year dividers, `html/timeline.css`).
- **Map**: R chunk `map-data` geocodes conference and institution city names with ArcGIS and injects coordinates as JS arrays (`conferenceData`, `universityData`). The map is built with **Leaflet.js** + public OpenStreetMap tiles. Rendering stops if geocoding returns missing coordinates. Red circles = conferences; blue pulsing circles = affiliated institutions (KU Leuven, UMC Utrecht, Memorial Sloan Kettering). Popups on click, works on mobile. No travel arcs. Zoom constrained to a single world view (`minZoom: 2`, `maxBounds`).
- **Map → timeline linking**: each timeline entry has a unique `id` (e.g., `talk-iscb-2024`). Conference popups have a "Show in timeline ↓" link that smooth-scrolls to the entry and highlights it with a blue pulse animation (`tl-highlight` class).
- **University popups**: UMC Utrecht and MSK show "Visiting Researcher" below the name; KU Leuven does not (home institution).
- Affiliated institutions are defined in the `map-data` R chunk as a `uni_coords` data frame.
- ⚠️ Same 4-space indentation constraint as the projects page.

---

## Publications page (`Publications/publications-page.qmd`)

- Pulls data live from **Google Scholar** (user ID `uPOL3NkAAAAJ`) via the `scholar` R package.
- Builds a **D3 force-directed co-authorship network** — nodes = co-authors, edges = shared papers, minimum 2 shared papers to appear.
- Author name deduplication: accent variants are normalised; a `manual_corrections` vector handles edge cases (Dutch particle names, compound surnames).
- Preprint/journal deduplication: Jaccard similarity ≥ 0.28 drops the preprint.
- The page fetches the complete Google Scholar profile list with `flush = TRUE` on every render, so new publications do not require manual cache deletion.
- ⚠️ D3 tooltips use `mouseover` — they do NOT work on mobile touch devices.

---

## Software page (`software/software-page.qmd`)

- Two sections — GitHub is client-side JS, OSF is fetched at build time by R:
  1. **GitHub** repos (username `LasaiBarrenada`) via the GitHub REST API (client-side JS).
  2. **OSF** projects (user ID `pgkjv`) via the OSF API v2 (R chunk `osf-projects`, because the OSF API does not support CORS).
- Page has `freeze: false` so OSF data refreshes on every render.
- Both sections use a responsive 2-column card grid (`html/software.css`).
- **GitHub cards** show: repo name (linked), description, language with colour dot, star count, fork badge, topic tags, and relative "Updated X ago" timestamp.
- **OSF cards** show: project title (linked), "OSF" badge (dark blue `#214370`), category label, description, tags, related paper links, child components (fetched via `/nodes/{id}/children/`, shown in a shaded "Components" box), and absolute date ("Updated Mar 2026"). Only top-level projects are shown (child components filtered out by `root.data.id === node.id`). Sorted by most recently modified.
- **Related papers on OSF cards**: looked up in two ways — (1) via an `OSF_ID` column in `projects/projects.xlsx` (preferred, avoids duplication), or (2) via the `osf_extra_papers` named list in the R chunk (for papers not in the spreadsheet). Both sources are merged; multiple papers per project are supported.
- **Excluded repos** are listed in the `EXCLUDE_REPOS` array: `LasaiBarrenada.github.io`, `LasaiBarrenada` (profile config), `web_resources`.
- Forked repos are hidden. External repos the user contributes to are listed in `CONTRIB_REPOS` as `owner/repo` strings (currently `BavoDC/CalibrationCurves`, `thomas-sounack/TRIPOD-Code`) — fetched individually and shown with a "Contributor" badge.
- Archived repos are automatically filtered out.
- Graceful fallback for both APIs: if either fails (rate limit, network), a message with a direct link to the respective profile is shown.
- ⚠️ The GitHub public API allows 60 requests/hour unauthenticated. OSF has no strict documented limit. Both sufficient for a personal site.

---

## Timeline CSS (`html/timeline.css`)

Shared between projects and speaking pages. Contains:
- `.tl-wrapper`, `.tl-entry`, `.tl-date`, `.tl-card`, `.tl-title`, `.tl-venue`
- `.tl-links`, `.tl-links a`, `.tl-award` (gold award style with 🏆)
- `.tl-type`, `.tl-type-talk`, `.tl-type-poster`, `.tl-type-upcoming`
- `.tl-year-divider` — bold blue year label with a dash on the timeline line
- `.tl-toggle`, `.tl-summary` — expand/collapse animation
- `@media (max-width: 600px)` mobile rules

**Do not inline timeline styles in the page files.** Both pages load this file with a `<link>` tag.

---

## Global styles (`html/styles.scss`)

- Body and heading font: **Inter** (loaded from Bunny Fonts)
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
| D3 tooltips on mobile | The Publications network uses `mouseover` — no touch support |
| Logo SVG needs explicit dimensions | SVGs without `width`/`height` attributes collapse to zero in some browsers |
| Map geocoding needs internet | The `map-data` chunk in speaking-page uses `tidygeocoder` — requires network access on render |
