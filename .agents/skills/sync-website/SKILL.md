---
name: sync-website
description: >-
  Use when the user asks to sync, update, redo, or rebuild the academic website
  after making manual edits to spreadsheets, Zotero BibTeX exports, slides/posters,
  CV content, bio text, or CSS styles. Detects changed tracked, untracked, and
  gitignored source files (using git plus an MD5 checksum snapshot), propagates
  updates across derived files, rebuilds the CV PDF and full Quarto site,
  verifies all outputs locally, and stops before committing or publishing.
---

# Sync Website After Manual Changes

Rebuild and synchronize the entire academic Quarto site from manually edited source files, verifying everything locally and stopping before `git commit` or `quarto publish gh-pages`.

> Read `MAINTENANCE.md` before editing any site file (mandatory repo rule), and consult [references/source-mapping.md](./references/source-mapping.md) whenever propagating spreadsheet, BibTeX, CV, or CSS changes.

---

## Step 1 — Detect Manually Changed Files

Run the change-detection script from the repository root (try sandboxed first; on Windows OneDrive `exebox` errors, retry with `BypassSandbox: true` keeping the same `toolSummary`):

```bash
Rscript .agents/skills/sync-website/scripts/detect_changes.R
```

Review the three sections printed by the script:
1. **Changed files by category**: shows tracked edits (`git status`), commits since the last recorded sync (`git diff`), and checksum diffs from `.agents/skills/sync-website/.sync_state.json` (which detects edits to gitignored `resources/Curriculum.xlsx`).
2. **Actionable sync hints**: flags unlinked files in `resources/`, first-author papers in `resources/Curriculum.xlsx` missing from `projects/projects.xlsx`, `cv/peer_bib_auto.bib` entries missing from `cv/peer_bib.bib`, review/grant/prize counts from `Curriculum.xlsx`, CSS files needing `?v=` bumps, and stale `_variables.yml` dates.
3. **Active `quarto preview` warning**: if a preview process is running, be careful of `site_libs/` races during renders (render single files one by one or stop preview temporarily).

Inspect the actual diff or contents of every flagged file before editing downstream targets.

---

## Step 2 — Propagate Manual Changes to Derived Files

Apply only the updates warranted by the detected changes, following [references/source-mapping.md](./references/source-mapping.md):

1. **Spreadsheets & slides (`resources/Curriculum.xlsx`, `resources/`, `projects/projects.xlsx`, `speaking/conferences.xlsx`)**:
   - Sync new first-author papers from `Curriculum.xlsx` (`Papers` sheet) into `projects/projects.xlsx` without overwriting existing hand-written `Summary` prose, `OSF_ID` values, or `Milestone`/`Award` rows.
   - Link any newly added slides or posters in `resources/` inside `speaking/conferences.xlsx` using `https://github.com/LasaiBarrenada/LasaiBarrenada.github.io/blob/main/resources/<URL-encoded-filename>`. Do **not** add `resources/` to `_quarto.yml` `project: resources:`.
   - Keep `Type` (`Oral`, `Poster`, or blank for upcoming), `Year`, `Month`, and `Location` clean in `speaking/conferences.xlsx`. If a new city lacks coordinates offline, `speaking/speaking-page.qmd` will geocode it into `speaking/geocache.csv` on render.
2. **Publications & BibTeX (`cv/peer_bib_auto.bib`, `cv/other_bib_auto.bib`, `cv/peer_bib.bib`, `cv/other_bib.bib`)**:
   - **NEVER manually edit `cv/peer_bib.bib` or any other `cv/*.bib` file** — all `.bib` files are Zotero-managed. If `detect_changes.R` flags published DOIs in `Curriculum.xlsx` or entries in `cv/peer_bib_auto.bib` missing from `cv/peer_bib.bib`, include an advisory reminder in your final report asking the user to re-export from Zotero.
   - `Publications/publications-page.qmd` resolves truncated Google Scholar author lists automatically from `peer_bib_auto.bib` → `other_bib_auto.bib` → `peer_bib.bib` → OpenAlex → Scholar; check if any new collaborator variant needs a `manual_corrections` entry.
3. **Dual CVs (`cv/CV.qmd` and `cv/cv-page.qmd`)**:
   - Keep Experience, Education, Awards & Prizes, Peer Review counts/journals (from `Curriculum.xlsx` `Reviews`), Fellowships, Grants, and Memberships aligned in **both** `cv/CV.qmd` (PDF) and `cv/cv-page.qmd` (HTML). (Conference Presentations and Publications load dynamically from `speaking/conferences.xlsx` and `peer_bib.bib`.)
4. **Custom CSS cache-busters (`html/*.css`)**:
   - Whenever `landing_page_styles.css`, `projects.css`, `timeline.css`, or `software.css` changes, bump `?v=YYYYMMDD` on its `<link>` tag in `index.qmd`, `projects/projects-page.qmd`, `speaking/speaking-page.qmd`, or `software/software-page.qmd`.
5. **Global date & navigation (`_variables.yml`, `_quarto.yml`)**:
   - Update `_variables.yml` (`last_updated: "<Month> <YYYY>"`) if the current month/year changed.
   - Keep `search: false` and `- "html/*.css"` intact in `_quarto.yml`.

---

## Step 3 — Rebuild CV PDF and Full Website

1. **Rebuild CV PDF first** (always when `cv/CV.qmd`, `cv/*.bib`, `cv/*.csl`, `cv/*.lua`, or `speaking/conferences.xlsx` changed, or if doing a full redo):
   ```bash
   quarto render cv/CV.qmd
   ```
   Verify `cv/cv.pdf` updated before full-site assembly (so `cv/cv-page.qmd` copies the fresh `cv.pdf` resource into `_site/cv/cv.pdf`).
2. **Clear stale `_freeze/` only if needed**:
   - `projects-page.qmd`, `speaking-page.qmd`, `software-page.qmd`, `Publications/publications-page.qmd`, and `cv/cv-page.qmd` have `freeze: false` and always re-execute.
   - Delete `_freeze/<page>/` only if you modified R code on another frozen page.
3. **Rebuild the whole website**:
   ```bash
   quarto render
   ```
   - Never pass multiple `.qmd` paths in one `quarto render a.qmd b.qmd` call (Quarto overwrites the earlier output). If `quarto preview` causes a `site_libs/` race during `quarto render`, render modified pages one at a time or pause `quarto preview`.
   - Expect `Publications` (Google Scholar + OpenAlex), `Software` (GitHub + KU Leuven GitLab + OSF), and `Speaking` (ArcGIS if uncached cities) to require network access.

---

## Step 4 — Verify All Built Outputs

Run the automated verification suite across `_site/`:

```bash
Rscript .agents/skills/sync-website/scripts/verify_site.R
```

Fix any `FAIL` reported (e.g., missing HTML/PDF output, mismatched `cv/cv.pdf` vs `_site/cv/cv.pdf`, Pandoc 4-space escaped HTML tags, missing `?v=` CSS links, geocoding `NA`s, or co-author count mismatches), re-render the affected target, and re-run `verify_site.R` until it exits with code `0`.

---

## Step 5 — Sync Docs, Skill Files & Snapshot, Then Stop for Review

1. Update **`MAINTENANCE.md`**, **`AGENTS.md`**, and the **`sync-website` skill** (this `SKILL.md`, [references/source-mapping.md](./references/source-mapping.md), [scripts/detect_changes.R](./scripts/detect_changes.R), and [scripts/verify_site.R](./scripts/verify_site.R)) whenever a change introduces or alters pages, data files, spreadsheet columns, CSS files, verification invariants, or build/freeze rules.
2. Record the new baseline checksum snapshot and HEAD commit:
   ```bash
   Rscript .agents/skills/sync-website/scripts/detect_changes.R --update-state
   ```
3. **Stop before committing or publishing**: Do **not** run `git commit` or `quarto publish gh-pages`. Report the detected manual changes, propagated updates, rebuilt pages, and verification results to the user so they can preview and publish when ready.
