#!/usr/bin/env Rscript
# Detect manually changed source files via git status/diff + MD5 checksum snapshot,
# and print actionable propagation hints for syncing derived files.

suppressPackageStartupMessages({
  library(jsonlite)
  library(openxlsx)
})

args <- commandArgs(trailingOnly = TRUE)
update_state <- "--update-state" %in% args

if (!file.exists("_quarto.yml")) {
  stop("Run detect_changes.R from the website repository root (containing _quarto.yml).")
}

state_file <- ".agents/skills/sync-website/.sync_state.json"

norm_path <- function(p) {
  p <- gsub("\\\\", "/", p)
  sub("^\\./", "", trimws(p))
}

copy_safe_temp <- function(path) {
  if (!file.exists(path)) return(NULL)
  ext <- tools::file_ext(path)
  tmp <- tempfile(fileext = if (nzchar(ext)) paste0(".", ext) else "")
  ok <- suppressWarnings(tryCatch(file.copy(path, tmp, overwrite = TRUE), error = function(e) FALSE))
  if (isTRUE(ok) && file.exists(tmp)) return(tmp)

  if (.Platform$OS.type == "windows") {
    src_win <- normalizePath(path, winslash = "\\", mustWork = FALSE)
    dst_win <- normalizePath(tmp,  winslash = "\\", mustWork = FALSE)
    ps_cmd <- sprintf(
      "$s=[System.IO.File]::Open('%s','Open','Read','ReadWrite');$d=[System.IO.File]::Create('%s');try{$s.CopyTo($d)}finally{$d.Close();$s.Close()}",
      gsub("'", "''", src_win),
      gsub("'", "''", dst_win)
    )
    status <- suppressWarnings(system2("powershell", c("-NoProfile", "-Command", ps_cmd), stdout = FALSE, stderr = FALSE))
    if (status == 0 && file.exists(tmp)) return(tmp)
  }
  NULL
}

safe_md5 <- function(path) {
  h <- suppressWarnings(tryCatch(unname(tools::md5sum(path)), error = function(e) NA_character_))
  if (!is.na(h) && nzchar(h)) return(h)
  tmp <- copy_safe_temp(path)
  if (!is.null(tmp)) {
    on.exit(unlink(tmp), add = TRUE)
    h2 <- suppressWarnings(tryCatch(unname(tools::md5sum(tmp)), error = function(e) NA_character_))
    if (!is.na(h2) && nzchar(h2)) return(h2)
  }
  NA_character_
}

run_git <- function(git_args) {
  out <- suppressWarnings(tryCatch(
    system2("git", c("-c", "core.quotepath=false", git_args), stdout = TRUE, stderr = FALSE),
    error = function(e) character(0)
  ))
  if (!is.null(attr(out, "status")) && attr(out, "status") != 0) return(character(0))
  out
}

collect_watched_files <- function() {
  candidates <- c(
    "_quarto.yml", "_variables.yml", "index.qmd", "404.qmd", ".gitignore",
    "license/index.qmd",
    "projects/projects-page.qmd", "projects/projects.xlsx",
    "speaking/speaking-page.qmd", "speaking/conferences.xlsx", "speaking/geocache.csv",
    "Publications/publications-page.qmd",
    "software/software-page.qmd",
    list.files("resources", full.names = TRUE, recursive = FALSE),
    list.files("cv", pattern = "\\.(bib|qmd|csl|lua|md)$", full.names = TRUE),
    list.files("html", pattern = "\\.(css|scss|html|lua)$", full.names = TRUE),
    list.files("img", full.names = TRUE, recursive = FALSE)
  )
  candidates <- norm_path(candidates)
  candidates <- candidates[file.exists(candidates) & !dir.exists(candidates)]
  # Deduplicate case-insensitively on Windows while keeping canonical casing
  keys <- tolower(candidates)
  candidates[!duplicated(keys)]
}

watched_files <- sort(collect_watched_files())
current_head  <- trimws(paste(run_git(c("rev-parse", "HEAD")), collapse = ""))
current_hashes <- vapply(watched_files, safe_md5, character(1))
names(current_hashes) <- watched_files

if (update_state) {
  dir.create(dirname(state_file), recursive = TRUE, showWarnings = FALSE)
  state_obj <- list(
    updated_at  = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
    head_commit = current_head,
    files       = as.list(current_hashes)
  )
  writeLines(toJSON(state_obj, auto_unbox = TRUE, pretty = TRUE), state_file, useBytes = TRUE)
  cat(sprintf(
    "Updated %s (%d watched files, HEAD %s).\n",
    state_file, length(current_hashes), substr(current_head, 1, 7)
  ))
  quit(status = 0L)
}

# ── Load prior snapshot ───────────────────────────────────────────────────────
saved_state <- if (file.exists(state_file)) {
  tryCatch(fromJSON(state_file, simplifyVector = FALSE), error = function(e) NULL)
} else {
  NULL
}

# ── Detect changes via 3 layers: git status, git diff since snapshot, MD5 ─────
is_ignored_output <- function(p) {
  grepl("^(_site|_freeze|\\.quarto)/", p) ||
    tolower(p) == tolower(state_file)
}

git_status_lines <- run_git(c("status", "-uall", "--porcelain"))
git_changed <- character(0)
for (ln in git_status_lines) {
  if (nchar(ln) < 4) next
  p <- trimws(substr(ln, 4, nchar(ln)))
  if (grepl(" -> ", p, fixed = TRUE)) {
    p <- trimws(sub("^.* -> ", "", p))
  }
  p <- sub('^"(.*)"$', "\\1", p)
  p <- norm_path(p)
  if (nzchar(p) && !is_ignored_output(p)) {
    git_changed <- c(git_changed, p)
  }
}

commit_changed <- character(0)
if (!is.null(saved_state) && !is.null(saved_state$head_commit) &&
    nzchar(saved_state$head_commit) && nzchar(current_head) &&
    saved_state$head_commit != current_head) {
  diff_lines <- run_git(c("diff", "--name-only", saved_state$head_commit, current_head))
  diff_lines <- norm_path(diff_lines)
  commit_changed <- diff_lines[nzchar(diff_lines) & !is_ignored_output(diff_lines)]
}

hash_changed <- character(0)
hash_notes   <- character(0)
if (!is.null(saved_state) && is.list(saved_state$files)) {
  prev_files <- unlist(saved_state$files)
  prev_keys  <- tolower(names(prev_files))
  curr_keys  <- tolower(names(current_hashes))

  for (idx in seq_along(current_hashes)) {
    f <- names(current_hashes)[idx]
    k <- curr_keys[idx]
    m <- match(k, prev_keys)
    if (is.na(m)) {
      hash_changed <- c(hash_changed, f)
      hash_notes[tolower(f)] <- "new-file"
    } else if (!is.na(current_hashes[idx]) && current_hashes[idx] != unname(prev_files[m])) {
      hash_changed <- c(hash_changed, f)
      hash_notes[tolower(f)] <- "modified"
    }
  }
  for (idx in seq_along(prev_files)) {
    k <- prev_keys[idx]
    if (!(k %in% curr_keys)) {
      f_old <- names(prev_files)[idx]
      hash_changed <- c(hash_changed, f_old)
      hash_notes[tolower(f_old)] <- "deleted"
    }
  }
}

# Union all detected paths case-insensitively
all_paths <- c(git_changed, commit_changed, hash_changed)
all_paths <- all_paths[!duplicated(tolower(all_paths))]

categorize_file <- function(p) {
  pl <- tolower(p)
  if (grepl("^resources/curriculum\\.xlsx$", pl)) return("Master Spreadsheet (Curriculum.xlsx)")
  if (grepl("^resources/", pl))                   return("Talk Slides & Posters (resources/)")
  if (grepl("^projects/projects\\.xlsx$", pl))    return("Projects Data (projects.xlsx)")
  if (grepl("^speaking/(conferences\\.xlsx|geocache\\.csv)$", pl)) return("Talks Data (conferences/geocache)")
  if (grepl("^cv/.*\\.bib$", pl))                 return("BibTeX Files (cv/*.bib)")
  if (grepl("^cv/.*\\.(qmd|csl|lua)$", pl))       return("CV Sources (cv/)")
  if (grepl("^html/", pl))                        return("Styles & Head Meta (html/)")
  if (grepl("^img/", pl))                         return("Images & Branding (img/)")
  if (grepl("\\.qmd$", pl) || grepl("^(_quarto\\.yml|_variables\\.yml)$", pl)) return("Pages & Site Config (.qmd/.yml)")
  "Other Workspace Files"
}

cat("========================================================================\n")
cat("WEBSITE CHANGE DETECTION REPORT\n")
cat("========================================================================\n")
if (is.null(saved_state)) {
  cat("Baseline snapshot: NOT INITIALIZED (run --update-state after review)\n")
} else {
  cat(sprintf("Baseline snapshot: %s (commit %s)\n",
              saved_state$updated_at,
              substr(saved_state$head_commit, 1, 7)))
}
cat(sprintf("Current git HEAD : %s\n", substr(current_head, 1, 7)))
cat(sprintf("Watched files    : %d\n\n", length(watched_files)))

cat("── 1. CHANGED FILES BY CATEGORY ────────────────────────────────────────\n")
if (length(all_paths) == 0) {
  cat("No manual source changes detected since last snapshot / clean git state.\n\n")
} else {
  cats <- vapply(all_paths, categorize_file, character(1))
  for (ct in unique(cats)) {
    cat(sprintf("\n[%s]\n", ct))
    pts <- sort(all_paths[cats == ct])
    for (p in pts) {
      pl <- tolower(p)
      srcs <- character(0)
      if (pl %in% tolower(git_changed))    srcs <- c(srcs, "git-working")
      if (pl %in% tolower(commit_changed)) srcs <- c(srcs, "git-committed")
      if (pl %in% tolower(hash_changed))   srcs <- c(srcs, paste0("checksum:", hash_notes[pl]))
      cat(sprintf("  - %-52s (%s)\n", p, paste(srcs, collapse = ", ")))
    }
  }
  cat("\n")
}

# ── Helper functions for actionable hints ─────────────────────────────────────
clean_ascii_lower <- function(x) {
  out <- iconv(x, from = "UTF-8", to = "ASCII//TRANSLIT")
  bad <- is.na(out) & !is.na(x)
  if (any(bad)) out[bad] <- iconv(x[bad], from = "UTF-8", to = "ASCII", sub = "")
  out[is.na(out)] <- ""
  tolower(trimws(out))
}

norm_title <- function(t) {
  t <- clean_ascii_lower(t)
  t <- gsub("[^a-z0-9 ]", " ", t)
  trimws(gsub("\\s+", " ", t))
}

title_tokens <- function(s) {
  stops <- c("a", "an", "and", "for", "in", "of", "on", "or", "the", "to", "with", "using", "based")
  toks <- unique(strsplit(norm_title(s), " ")[[1]])
  toks[nzchar(toks) & !(toks %in% stops)]
}

jaccard_sim <- function(a, b) {
  ta <- title_tokens(a); tb <- title_tokens(b)
  u <- length(union(ta, tb))
  if (u == 0) return(0)
  length(intersect(ta, tb)) / u
}

overlap_sim <- function(a, b) {
  ta <- title_tokens(a); tb <- title_tokens(b)
  m <- min(length(ta), length(tb))
  if (m == 0) return(0)
  length(intersect(ta, tb)) / m
}

read_xlsx_safe <- function(path, sheet = 1) {
  tmp <- copy_safe_temp(path)
  if (is.null(tmp)) return(NULL)
  on.exit(unlink(tmp), add = TRUE)
  suppressWarnings(tryCatch(read.xlsx(tmp, sheet = sheet), error = function(e) NULL))
}

extract_bib_titles <- function(path) {
  if (!file.exists(path)) return(character(0))
  txt <- paste(readLines(path, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  starts <- gregexpr("(?m)^@", txt, perl = TRUE)[[1]]
  if (length(starts) == 1 && starts[1] == -1) return(character(0))
  ends <- c(starts[-1] - 1L, nchar(txt))
  titles <- character(0)
  for (k in seq_along(starts)) {
    block <- substr(txt, starts[k], ends[k])
    m <- regexpr("(?i)(?:^|\\n)\\s*title\\s*=\\s*\\{", block, perl = TRUE)
    if (m < 0) next
    start_pos <- as.integer(m) + attr(m, "match.length")
    chars <- strsplit(substr(block, start_pos, nchar(block)), "")[[1]]
    depth <- 1L; end_rel <- length(chars)
    for (idx in seq_along(chars)) {
      if (chars[idx] == "{") depth <- depth + 1L
      else if (chars[idx] == "}") {
        depth <- depth - 1L
        if (depth == 0L) { end_rel <- idx - 1L; break }
      }
    }
    raw <- paste0(chars[seq_len(end_rel)], collapse = "")
    titles <- c(titles, trimws(gsub("\\s+", " ", gsub("[{}]", "", raw))))
  }
  titles
}

cat("── 2. ACTIONABLE SYNC HINTS ────────────────────────────────────────────\n")

# Hint A: Curriculum.xlsx sync checks
if (file.exists("resources/Curriculum.xlsx")) {
  papers_df <- read_xlsx_safe("resources/Curriculum.xlsx", sheet = "Papers")
  proj_df   <- read_xlsx_safe("projects/projects.xlsx", sheet = 1)
  if (!is.null(papers_df) && !is.null(proj_df) && "Name" %in% names(papers_df)) {
    fa_col <- if ("First.author" %in% names(papers_df)) papers_df[["First.author"]] else rep(NA, nrow(papers_df))
    fa_vals <- tolower(trimws(as.character(fa_col)))
    is_fa   <- !is.na(fa_col) & (fa_vals %in% c("true", "yes", "1", "x", "si", "sí"))
    fa_idx  <- which(is_fa & !is.na(papers_df[["Name"]]))
    proj_titles <- as.character(proj_df[["Title"]][!is.na(proj_df[["Title"]])])
    proj_links_blob <- tolower(paste(c(
      as.character(proj_df[["Link_1"]]),
      as.character(proj_df[["Link_2"]]),
      as.character(proj_df[["Link_3"]])
    ), collapse = " "))
    doi_col <- if ("doi" %in% names(papers_df)) as.character(papers_df[["doi"]]) else rep(NA_character_, nrow(papers_df))

    missing_fa <- character(0)
    for (idx in fa_idx) {
      ft <- as.character(papers_df[["Name"]][idx])
      d  <- tolower(trimws(doi_col[idx]))
      doi_hit <- !is.na(d) && nzchar(d) && (
        grepl(d, proj_links_blob, fixed = TRUE) ||
        grepl(sub("^.*/", "", d), proj_links_blob, fixed = TRUE)
      )
      j_sims <- vapply(proj_titles, function(pt) jaccard_sim(ft, pt), numeric(1))
      o_sims <- vapply(proj_titles, function(pt) overlap_sim(ft, pt), numeric(1))
      matched <- doi_hit ||
                 (length(j_sims) > 0 && max(j_sims) >= 0.45) ||
                 (length(o_sims) > 0 && max(o_sims) >= 0.60)
      if (!matched) missing_fa <- c(missing_fa, ft)
    }
    cat(sprintf("* Curriculum Papers: %d total, %d first-author | projects.xlsx rows: %d\n",
                sum(!is.na(papers_df[["Name"]])), length(fa_idx), nrow(proj_df)))
    if (length(missing_fa) > 0) {
      cat("  -> First-author papers NOT matched in projects/projects.xlsx:\n")
      for (mt in missing_fa) cat("     -", mt, "\n")
    } else {
      cat("  -> All first-author papers in Curriculum.xlsx match projects/projects.xlsx.\n")
    }

    # Check published DOIs in Curriculum.xlsx against cv/peer_bib.bib and first-author projects.xlsx links
    peer_bib_txt <- if (file.exists("cv/peer_bib.bib")) {
      tolower(paste(readLines("cv/peer_bib.bib", encoding = "UTF-8", warn = FALSE), collapse = "\n"))
    } else ""
    has_doi_idx <- which(!is.na(papers_df[["Name"]]) & !is.na(doi_col) & nzchar(trimws(doi_col)))
    missing_bib_dois <- character(0)
    missing_proj_dois <- character(0)
    for (idx in has_doi_idx) {
      d <- tolower(trimws(doi_col[idx]))
      ttl <- as.character(papers_df[["Name"]][idx])
      if (!grepl(d, peer_bib_txt, fixed = TRUE)) {
        missing_bib_dois <- c(missing_bib_dois, sprintf("%s (doi:%s)", ttl, trimws(doi_col[idx])))
      }
      if (idx %in% fa_idx && !grepl(d, proj_links_blob, fixed = TRUE) &&
          !grepl(sub("^.*/", "", d), proj_links_blob, fixed = TRUE)) {
        missing_proj_dois <- c(missing_proj_dois, sprintf("%s (doi:%s)", ttl, trimws(doi_col[idx])))
      }
    }
    if (length(missing_bib_dois) > 0) {
      cat("  -> ADVISORY (re-export from Zotero — do NOT manually edit cv/peer_bib.bib):\n")
      cat("     Published DOIs in Curriculum.xlsx missing from cv/peer_bib.bib:\n")
      for (md in missing_bib_dois) cat("     -", md, "\n")
    }
    if (length(missing_proj_dois) > 0) {
      cat("  -> Published first-author DOIs in Curriculum.xlsx missing from projects/projects.xlsx links:\n")
      for (md in missing_proj_dois) cat("     -", md, "\n")
    }
  } else {
    cat("* Could not read Curriculum.xlsx [Papers] or projects/projects.xlsx.\n")
  }

  confs_cur <- read_xlsx_safe("resources/Curriculum.xlsx", sheet = "Conferences")
  confs_web <- read_xlsx_safe("speaking/conferences.xlsx", sheet = 1)
  revs_cur  <- read_xlsx_safe("resources/Curriculum.xlsx", sheet = "Reviews")
  priz_cur  <- read_xlsx_safe("resources/Curriculum.xlsx", sheet = "Prizes")
  grnt_cur  <- read_xlsx_safe("resources/Curriculum.xlsx", sheet = "Grants")

  if (!is.null(confs_cur) && !is.null(confs_web)) {
    cat(sprintf("* Curriculum Conferences: %d rows | speaking/conferences.xlsx: %d rows\n",
                nrow(confs_cur), nrow(confs_web)))
  }
  if (!is.null(revs_cur)) {
    jrn_col <- if ("Journal" %in% names(revs_cur)) unique(trimws(as.character(revs_cur[["Journal"]]))) else character(0)
    jrn_col <- jrn_col[!is.na(jrn_col) & nzchar(jrn_col)]
    cat(sprintf("* Curriculum Reviews: %d rows across %d unique journals (check CV Peer Review text)\n",
                nrow(revs_cur), length(jrn_col)))
  }
  if (!is.null(priz_cur) && !is.null(grnt_cur)) {
    cat(sprintf("* Curriculum Prizes: %d rows | Grants: %d rows\n", nrow(priz_cur), nrow(grnt_cur)))
  }
}

# Hint B: Unlinked files in resources/
confs_web <- if (exists("confs_web")) confs_web else read_xlsx_safe("speaking/conferences.xlsx", sheet = 1)
res_files <- list.files("resources", full.names = FALSE, recursive = FALSE)
res_files <- res_files[!grepl("\\.xlsx?$", res_files, ignore.case = TRUE)]
if (length(res_files) > 0 && !is.null(confs_web)) {
  raw_links <- c(as.character(confs_web[["Link_1"]]), as.character(confs_web[["Link_2"]]))
  raw_links <- raw_links[!is.na(raw_links) & nzchar(raw_links)]
  dec_links <- vapply(raw_links, function(u) tryCatch(utils::URLdecode(u), error = function(e) u), character(1))
  links_text <- paste(c(raw_links, dec_links), collapse = " ")
  unlinked <- character(0)
  for (rf in res_files) {
    enc <- utils::URLencode(enc2utf8(rf), reserved = TRUE)
    if (!grepl(rf, links_text, fixed = TRUE) && !grepl(enc, links_text, fixed = TRUE)) {
      unlinked <- c(unlinked, rf)
    }
  }
  if (length(unlinked) > 0) {
    cat("* Unlinked files in resources/ (add to speaking/conferences.xlsx if relevant):\n")
    for (uf in unlinked) {
      url <- paste0(
        "https://github.com/LasaiBarrenada/LasaiBarrenada.github.io/blob/main/resources/",
        utils::URLencode(enc2utf8(uf), reserved = TRUE)
      )
      cat("  ->", uf, "\n     URL:", url, "\n")
    }
  } else {
    cat("* All slide/poster files in resources/ are linked in speaking/conferences.xlsx.\n")
  }
}

# Hint C: cv/peer_bib_auto.bib vs cv/peer_bib.bib
auto_titles <- extract_bib_titles("cv/peer_bib_auto.bib")
peer_titles <- extract_bib_titles("cv/peer_bib.bib")
if (length(auto_titles) > 0 && length(peer_titles) > 0) {
  missing_bib <- character(0)
  for (at in auto_titles) {
    sims <- vapply(peer_titles, function(pt) jaccard_sim(at, pt), numeric(1))
    if (max(sims) < 0.75) missing_bib <- c(missing_bib, at)
  }
  if (length(missing_bib) > 0) {
    cat("* ADVISORY (re-export from Zotero — do NOT manually edit cv/peer_bib.bib):\n")
    cat("  Entries in cv/peer_bib_auto.bib missing from cv/peer_bib.bib:\n")
    for (mb in missing_bib) cat("  ->", mb, "\n")
  } else {
    cat(sprintf("* All %d entries in cv/peer_bib_auto.bib match cv/peer_bib.bib.\n", length(auto_titles)))
  }
}

# Hint D: CSS cache-busting strings
css_map <- list(
  list(css = "html/landing_page_styles.css", qmd = "index.qmd"),
  list(css = "html/projects.css",           qmd = "projects/projects-page.qmd"),
  list(css = "html/timeline.css",           qmd = "speaking/speaking-page.qmd"),
  list(css = "html/software.css",           qmd = "software/software-page.qmd")
)
today_ver <- format(Sys.Date(), "%Y%m%d")
for (item in css_map) {
  if (!file.exists(item$qmd)) next
  qtxt <- paste(readLines(item$qmd, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  m <- regexpr(paste0(basename(item$css), "(\\?v=[^\"' >]+)?"), qtxt, perl = TRUE)
  cur_ref <- if (m > 0) regmatches(qtxt, m) else "(not found)"
  if (tolower(item$css) %in% tolower(all_paths)) {
    cat(sprintf("* CSS changed (%s): bump ?v= to ?v=%s in %s (currently %s)\n",
                item$css, today_ver, item$qmd, cur_ref))
  }
}

# Hint E: _variables.yml date freshness
if (file.exists("_variables.yml")) {
  vtxt <- paste(readLines("_variables.yml", encoding = "UTF-8", warn = FALSE), collapse = "\n")
  cur_month_en <- paste(month.name[as.integer(format(Sys.Date(), "%m"))], format(Sys.Date(), "%Y"))
  if (!grepl(cur_month_en, vtxt, fixed = TRUE)) {
    cat(sprintf("* _variables.yml last_updated differs from '%s' (%s)\n",
                cur_month_en, trimws(vtxt)))
  } else {
    cat(sprintf("* _variables.yml matches '%s'.\n", cur_month_en))
  }
}

# Hint F: Active quarto preview check on Windows
if (.Platform$OS.type == "windows") {
  tl <- suppressWarnings(tryCatch(system2("cmd", c("/c", "tasklist /FO CSV /NH"), stdout = TRUE, stderr = FALSE), error = function(e) character(0)))
  has_quarto <- any(grepl('"quarto', tl, ignore.case = TRUE))
  if (has_quarto) {
    cat("* WARNING: A quarto process is running in the background (likely quarto preview). Render one file at a time or pause preview to avoid site_libs/ races.\n")
  }
}

cat("\n── 3. RECOMMENDED REBUILD TARGETS ──────────────────────────────────────\n")
cat("* Always rebuild full site (`quarto render`) before finishing, and verify with verify_site.R.\n")
needs_cv_pdf <- any(grepl("^cv/|^speaking/conferences\\.xlsx$|^resources/curriculum\\.xlsx$", tolower(all_paths)))
if (needs_cv_pdf) {
  cat("* Render `quarto render cv/CV.qmd` FIRST so cv/cv.pdf is updated before copying to _site/cv/cv.pdf.\n")
} else {
  cat("* Check whether `quarto render cv/CV.qmd` is needed (run whenever CV/BibTeX/talks change).\n")
}
cat("* Auto-refreshing pages (freeze: false): Projects, Talks, Software, Publications, HTML CV.\n")
