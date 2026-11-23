# Website Source-to-Target Mapping & Technical Reference

Reference for the `sync-website` skill. Read relevant sections when translating manual source changes into derived files.

---

## 1. Manual Source → Derived Target Matrix

| Manual source file(s) | Automated by | Derived files to inspect / update | Rendered targets in `_site/` |
|---|---|---|---|
| `resources/Curriculum.xlsx` (`Papers`) | Manual + hint in `detect_changes.R` | `projects/projects.xlsx` (first-author papers); advisory reminder only if missing from Zotero `cv/peer_bib.bib` | `_site/projects/projects-page.html`, `_site/cv/cv-page.html`, `cv/cv.pdf` |
| `resources/Curriculum.xlsx` (`Conferences`) | Manual + hint | `speaking/conferences.xlsx` | `_site/speaking/speaking-page.html`, `_site/cv/cv-page.html`, `cv/cv.pdf` |
| `resources/Curriculum.xlsx` (`Reviews`, `Prizes`, `Grants`) | Manual + hint | `cv/CV.qmd` & `cv/cv-page.qmd`; major awards/PhD milestones → `projects/projects.xlsx` | `_site/cv/cv-page.html`, `cv/cv.pdf`, `_site/projects/projects-page.html` |
| `resources/<slides or poster>` | Hint in `detect_changes.R` | `speaking/conferences.xlsx` (`Link_1`/`Link_2`) via `https://github.com/LasaiBarrenada/LasaiBarrenada.github.io/blob/main/resources/<URL-encoded-name>` | Not bundled in `_site/` (linked to `main` branch on GitHub) |
| `projects/projects.xlsx` | Direct R read (`tl-projects`, `osf-projects`) | Check `OSF_ID` links if software OSF cards reference the paper | `_site/projects/projects-page.html`, `_site/software/software-page.html` |
| `speaking/conferences.xlsx` | Direct R read (`tl-speaking`, `map-data`, `cv-conferences`, `cv-pdf-conferences`) | Rebuild `cv/CV.qmd` for `cv/cv.pdf`; `speaking/geocache.csv` auto-updates on new cities | `_site/speaking/speaking-page.html`, `_site/cv/cv-page.html`, `cv/cv.pdf` |
| `cv/peer_bib_auto.bib` / `cv/other_bib_auto.bib` | Layer 1 on Publications page + BibTeX hint | **Read-only Zotero exports** — never edit `cv/*.bib` manually; flag missing entries for Zotero re-export | `_site/Publications/publications-page.html`, `_site/cv/cv-page.html`, `cv/cv.pdf` |
| `cv/peer_bib.bib`, `cv/CV.qmd`, `cv/cv-page.qmd`, `*.csl`, `*.lua` | Quarto citeproc / Lua filters | Keep `cv/CV.qmd` and `cv/cv-page.qmd` prose synced (**never manually edit `cv/*.bib`**); render `cv/CV.qmd` before `cv/cv-page.qmd` | `cv/cv.pdf`, `_site/cv/cv.pdf`, `_site/cv/cv-page.html` |
| `html/landing_page_styles.css` | `_quarto.yml` resource copy | Bump `?v=YYYYMMDD` on `<link>` in `index.qmd` | `_site/html/landing_page_styles.css`, `_site/index.html` |
| `html/projects.css` | `_quarto.yml` resource copy | Bump `?v=YYYYMMDD` on `<link>` in `projects/projects-page.qmd` | `_site/html/projects.css`, `_site/projects/projects-page.html` |
| `html/timeline.css` | `_quarto.yml` resource copy | Bump `?v=YYYYMMDD` on `<link>` in `speaking/speaking-page.qmd` | `_site/html/timeline.css`, `_site/speaking/speaking-page.html` |
| `html/software.css` | `_quarto.yml` resource copy | Bump `?v=YYYYMMDD` on `<link>` in `software/software-page.qmd` | `_site/html/software.css`, `_site/software/software-page.html` |
| `html/styles.scss`, `_quarto.yml`, `_variables.yml`, `html/seo.html` | Global Quarto config | Full rebuild required | Entire `_site/` |
| `index.qmd`, `404.qmd`, `license/index.qmd`, `img/*` | Direct Quarto render | Check `_site/index.html` hero CTA / links | Matching HTML + `_site/img/*` |

---

## 2. Spreadsheet Schemas

### `projects/projects.xlsx` (15 columns, sheet `Sheet 1`)
| Column | Allowed values / notes |
|---|---|
| `Title` | Paper, milestone, or award title |
| `Year` | 4-digit year (optional/blank for undated upcoming work) |
| `Month` | Numeric month `1`–`12` for sorting |
| `Venue` | Journal, preprint server, or issuing body |
| `OSF_ID` | Optional 5-char OSF node ID (`erju9`, `36n8m`, `ngcj2`) — links paper onto Software OSF card |
| `Link_1_name` / `Link_1` | Primary pill label (`Paper`, `Preprint`, `CRAN`, `Code`, `Dr. Barreñada`, `Award`) + URL |
| `Link_2_name` / `Link_2`, `Link_3_name` / `Link_3` | Optional secondary/tertiary pills + URLs |
| `Summary` | Plain-language 2–3 sentence summary (preserve existing prose during syncs) |
| `Category` | `Milestone`, `Award`, `Methodology`, `Clinical Utility`, or `Ovarian Cancer` |
| `Status` | `Published`, `Accepted`, `Preprint`, `Upcoming`, `Milestone`, or `Award` |
| `First_Author` | `TRUE`, `FALSE`, or blank |

### `speaking/conferences.xlsx` (11 columns, sheet `Sheet1`)
| Column | Notes |
|---|---|
| `Location` | City name geocoded via `speaking/geocache.csv` / ArcGIS |
| `Conference.name`, `Code_Name` | Full name + short code (`ISCB`, `ISUOG`, `MEMTAB`, `ENAR`, etc.) |
| `Title` | Talk or poster title |
| `Year`, `Month` | Numeric year and month (used for sorting and IDs) |
| `Type` | `Oral`, `Poster`, or blank (`Upcoming`) |
| `Link_1_name` / `Link_1`, `Link_2_name` / `Link_2` | Pill labels (`Slides`, `Poster`, `Paper`) + URLs (`resources/` links point to `main` on GitHub) |

---

## 3. Live External Data Sources Refreshed at Render

These pages set `freeze: false` and pull fresh external data automatically on every render:
- **Publications (`Publications/publications-page.qmd`)**: Google Scholar (`uPOL3NkAAAAJ`, `flush = TRUE`) + OpenAlex ORCID `0000-0001-8020-0210` + OpenAlex title search.
- **Software (`software/software-page.qmd`)**: GitHub API (`LasaiBarrenada` + `CONTRIB_REPOS` into `window.GITHUB_BUILD_CACHE`), KU Leuven GitLab (`gitlab.kuleuven.be` user `u0158158`), OSF API (`pgkjv` + child components).
- **Talks (`speaking/speaking-page.qmd`)**: ArcGIS geocoder via `tidygeocoder` only for cities absent from `speaking/geocache.csv`.
- **Projects (`projects/projects-page.qmd`)** & **HTML CV (`cv/cv-page.qmd`)**: Re-read Excel/BibTeX files on every render.

---

## 4. Critical Repo Gotchas

- **Windows OneDrive sandbox**: `run_command` with `BypassSandbox: false` fails with `exebox: creating sandbox`; always try sandboxed first on new commands, then retry with `BypassSandbox: true` using the exact same `toolSummary`.
- **PowerShell 5.1**: Does not support `&&`; inside `"..."`, `$var` is expanded by PowerShell (`res$col` breaks unless using single quotes, `[[...]]`, or a `.R` file).
- **Locked `.xlsx` files**: If Excel has a workbook open, use `.NET FileStream(..., 'Open', 'Read', 'ReadWrite')` (already built into `detect_changes.R`).
- **Pandoc 4-space rule**: Never let any line emitted by R `cat()` / `sprintf()` (`results='asis'`) start with 4+ leading spaces; Pandoc parses it as a literal code block.
- **No multi-file `quarto render`**: Never pass `quarto render a.qmd b.qmd`; render either the full project (`quarto render`) or one `.qmd` file per command.
- **`quarto preview` race**: If `quarto preview` is watching the workspace, `quarto render` can hit a `site_libs/` rename error (`os error 2` / `os error 3`). Pause preview or render affected pages individually.
- **Preserve global settings**: Keep `search: false` and `- "html/*.css"` in `_quarto.yml`. Keep `<link rel="stylesheet" href="...">` paths relative in subdirectory pages (`../html/...css?v=YYYYMMDD`).
- **Zotero-managed BibTeX (`cv/*.bib`)**: **NEVER manually edit `cv/peer_bib.bib` or any `cv/*.bib` file** — they are managed/exported by Zotero. Only report missing entries as an advisory reminder for the user to re-export.
- **Mandatory docs & skill sync**: Always keep `MAINTENANCE.md`, `AGENTS.md`, and `.agents/skills/sync-website/` (`SKILL.md`, `references/source-mapping.md`, `scripts/detect_changes.R`, `scripts/verify_site.R`) updated whenever pages, source files, spreadsheet schemas, CSS files, verification checks, or build/freeze rules change.
