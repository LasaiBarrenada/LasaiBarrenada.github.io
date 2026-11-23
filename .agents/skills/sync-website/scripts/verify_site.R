#!/usr/bin/env Rscript
# Verify all built outputs in _site/ against key structural and data invariants.

suppressPackageStartupMessages({
  library(jsonlite)
})

if (!file.exists("_quarto.yml")) {
  stop("Run verify_site.R from the website repository root (containing _quarto.yml).")
}

results <- list()
record_check <- function(name, ok, detail = "") {
  results[[length(results) + 1L]] <<- list(name = name, ok = isTRUE(ok), detail = detail)
}

# 1. Required built files exist and are non-empty
req_files <- c(
  "_site/index.html",
  "_site/projects/projects-page.html",
  "_site/speaking/speaking-page.html",
  "_site/Publications/publications-page.html",
  "_site/software/software-page.html",
  "_site/cv/cv-page.html",
  "_site/cv/cv.pdf",
  "_site/404.html",
  "_site/license/index.html",
  "_site/html/landing_page_styles.css",
  "_site/html/projects.css",
  "_site/html/timeline.css",
  "_site/html/software.css"
)
missing_req <- req_files[!file.exists(req_files) | file.info(req_files)$size <= 0]
record_check(
  "Built files non-empty",
  length(missing_req) == 0,
  if (length(missing_req) == 0) sprintf("%d files OK", length(req_files)) else paste("Missing/empty:", paste(missing_req, collapse = ", "))
)

# 2. _quarto.yml invariants
qy <- paste(readLines("_quarto.yml", encoding = "UTF-8", warn = FALSE), collapse = "\n")
has_search_false <- grepl("search:\\s*false", qy)
has_html_css_res <- grepl('html/\\*\\.css', qy)
record_check(
  "_quarto.yml invariants",
  has_search_false && has_html_css_res,
  sprintf("search:false=%s, html/*.css=%s", has_search_false, has_html_css_res)
)

# 3. CSS cache-busting query strings present on all 4 custom-styled pages
css_links <- list(
  c("_site/index.html",                     "html/landing_page_styles\\.css\\?v="),
  c("_site/projects/projects-page.html",    "../html/projects\\.css\\?v="),
  c("_site/speaking/speaking-page.html",    "../html/timeline\\.css\\?v="),
  c("_site/software/software-page.html",    "../html/software\\.css\\?v=")
)
bad_css_links <- character(0)
for (pair in css_links) {
  if (!file.exists(pair[1])) { bad_css_links <- c(bad_css_links, pair[1]); next }
  txt <- paste(readLines(pair[1], encoding = "UTF-8", warn = FALSE), collapse = "\n")
  if (!grepl(pair[2], txt, perl = TRUE)) bad_css_links <- c(bad_css_links, pair[1])
}
record_check(
  "CSS ?v= cache-busting links",
  length(bad_css_links) == 0,
  if (length(bad_css_links) == 0) "All 4 pages OK" else paste("Missing ?v= in:", paste(bad_css_links, collapse = ", "))
)

# 4. Pandoc 4-space escaped HTML regression check
r_pages <- c(
  "_site/projects/projects-page.html",
  "_site/speaking/speaking-page.html",
  "_site/software/software-page.html",
  "_site/cv/cv-page.html"
)
escaped_hits <- character(0)
for (pg in r_pages) {
  if (!file.exists(pg)) next
  txt <- paste(readLines(pg, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  if (grepl("&lt;div class=&quot;(proj|tl|sw|cv)-", txt, perl = TRUE)) {
    escaped_hits <- c(escaped_hits, pg)
  }
}
record_check(
  "Zero Pandoc escaped R-HTML",
  length(escaped_hits) == 0,
  if (length(escaped_hits) == 0) "Clean" else paste("Escaped tags in:", paste(escaped_hits, collapse = ", "))
)

# 5. Landing page & hero CSS rules
if (file.exists("_site/index.html") && file.exists("_site/html/landing_page_styles.css")) {
  idx_txt <- paste(readLines("_site/index.html", encoding = "UTF-8", warn = FALSE), collapse = "\n")
  lps_txt <- paste(readLines("_site/html/landing_page_styles.css", encoding = "UTF-8", warn = FALSE), collapse = "\n")
  ok_idx <- grepl("hero_cta", idx_txt, fixed = TRUE) &&
            grepl("hero_btn_primary", idx_txt, fixed = TRUE) &&
            grepl("projects/projects-page\\.html", idx_txt) &&
            grepl("Publications/publications-page\\.html", idx_txt) &&
            grepl("cv/cv\\.pdf", idx_txt) &&
            grepl("mailto:lasai\\.barrenadataleb@kuleuven\\.be", idx_txt) &&
            grepl("\\.hero_cta", lps_txt) &&
            grepl("\\.hero_btn_primary", lps_txt)
  record_check("Landing page CTA & mailto", ok_idx, if (ok_idx) "All hero CTAs & CSS OK" else "Missing CTA or CSS rule")
} else {
  record_check("Landing page CTA & mailto", FALSE, "Missing index.html or landing_page_styles.css")
}

# 6. Projects page structure
if (file.exists("_site/projects/projects-page.html")) {
  prj_txt <- paste(readLines("_site/projects/projects-page.html", encoding = "UTF-8", warn = FALSE), collapse = "\n")
  ok_prj <- grepl("proj-honours-grid", prj_txt, fixed = TRUE) &&
            grepl("proj-laurel-pill", prj_txt, fixed = TRUE) &&
            grepl("proj-grid", prj_txt, fixed = TRUE)
  record_check("Projects honours & grid", ok_prj, if (ok_prj) "Honours, laurel pill & grid OK" else "Missing projects grid elements")
}

# 7. Talks page JSON coordinates & timeline cards
extract_js_json <- function(lines, varname) {
  line <- lines[grepl(paste0("^(?:const|var)\\s+", varname, "\\s*=\\s*"), lines, perl = TRUE)][1]
  if (is.na(line)) return(NULL)
  json_str <- sub(paste0("^(?:const|var)\\s+", varname, "\\s*=\\s*"), "", line, perl = TRUE)
  json_str <- sub(";\\s*$", "", json_str, perl = TRUE)
  tryCatch(fromJSON(json_str, simplifyVector = FALSE), error = function(e) NULL)
}

if (file.exists("_site/speaking/speaking-page.html")) {
  spk_lines <- readLines("_site/speaking/speaking-page.html", encoding = "UTF-8", warn = FALSE)
  spk_txt   <- paste(spk_lines, collapse = "\n")
  confs_js  <- extract_js_json(spk_lines, "conferenceData")
  unis_js   <- extract_js_json(spk_lines, "universityData")
  valid_coords <- function(arr) {
    is.list(arr) && length(arr) > 0 && all(vapply(arr, function(x) {
      lon_val <- if (!is.null(x$long)) x$long else x$lng
      !is.null(x$lat) && !is.null(lon_val) && is.numeric(x$lat) && is.numeric(lon_val)
    }, logical(1)))
  }
  ok_spk <- valid_coords(confs_js) && valid_coords(unis_js) && grepl("tl-entry", spk_txt, fixed = TRUE)
  record_check(
    "Talks map & timeline",
    ok_spk,
    sprintf("confs=%d, unis=%d", if (is.list(confs_js)) length(confs_js) else 0L, if (is.list(unis_js)) length(unis_js) else 0L)
  )
}

# 8. Publications network & list consistency
if (file.exists("_site/Publications/publications-page.html")) {
  pub_lines <- readLines("_site/Publications/publications-page.html", encoding = "UTF-8", warn = FALSE)
  pub_txt   <- paste(pub_lines, collapse = "\n")
  nodes <- extract_js_json(pub_lines, "graphNodes")
  links <- extract_js_json(pub_lines, "graphLinks")
  pubs  <- extract_js_json(pub_lines, "allPublications")

  no_legacy_panel <- !grepl("pub-panel", pub_txt, fixed = TRUE) &&
                     !grepl("showPanel", pub_txt, fixed = TRUE) &&
                     !grepl("pubsByAuthor", pub_txt, fixed = TRUE)
  no_arxiv_glitch <- !grepl("arXiv preprint arXiv:, :", pub_txt, fixed = TRUE)

  consistent <- FALSE
  all_authored <- FALSE
  if (is.list(nodes) && is.list(links) && is.list(pubs) && length(pubs) > 0) {
    co_nodes <- Filter(function(n) identical(n$group, "coauthor"), nodes)
    consistent <- length(co_nodes) > 0 && all(vapply(co_nodes, function(n) {
      cnt <- sum(vapply(pubs, function(p) n$id %in% unlist(p$coauthors), logical(1)))
      identical(as.integer(cnt), as.integer(n$n_papers))
    }, logical(1)))
    all_authored <- all(vapply(pubs, function(p) {
      grepl("barre[nñ]", as.character(p$authors), ignore.case = TRUE)
    }, logical(1)))
  }
  ok_pub <- no_legacy_panel && no_arxiv_glitch && consistent && all_authored
  record_check(
    "Publications network & list",
    ok_pub,
    sprintf("nodes=%d, pubs=%d, panelRemoved=%s, consistent=%s",
            if (is.list(nodes)) length(nodes) else 0L,
            if (is.list(pubs)) length(pubs) else 0L,
            no_legacy_panel, consistent)
  )
}

# 9. Software page sections
if (file.exists("_site/software/software-page.html")) {
  sw_txt <- paste(readLines("_site/software/software-page.html", encoding = "UTF-8", warn = FALSE), collapse = "\n")
  ok_sw <- grepl("window.GITHUB_BUILD_CACHE", sw_txt, fixed = TRUE) &&
           grepl("gitlab-grid", sw_txt, fixed = TRUE) &&
           grepl("sw-card-osf", sw_txt, fixed = TRUE)
  record_check("Software GH/GL/OSF grids", ok_sw, if (ok_sw) "All 3 sections OK" else "Missing GH cache, GL grid, or OSF cards")
}

# 10. CV HTML & PDF sync
if (file.exists("_site/cv/cv-page.html") && file.exists("_site/cv/cv.pdf") && file.info("_site/cv/cv.pdf")$size > 0) {
  cv_txt <- paste(readLines("_site/cv/cv-page.html", encoding = "UTF-8", warn = FALSE), collapse = "\n")
  pdf_sync_ok <- TRUE
  sync_note <- "_site/cv/cv.pdf present"
  if (file.exists("cv/cv.pdf")) {
    h_src <- unname(tools::md5sum("cv/cv.pdf"))
    h_out <- unname(tools::md5sum("_site/cv/cv.pdf"))
    pdf_sync_ok <- identical(h_src, h_out)
    sync_note <- sprintf("cv.pdf md5 match=%s", pdf_sync_ok)
  }
  ok_cv <- grepl('id="refs"', cv_txt, fixed = TRUE) &&
           grepl("cv-conf-title", cv_txt, fixed = TRUE) &&
           grepl("cv.pdf", cv_txt, fixed = TRUE) &&
           pdf_sync_ok
  record_check("CV HTML & PDF sync", ok_cv, if (ok_cv) sprintf("HTML refs, talks & %s OK", sync_note) else sync_note)
} else {
  record_check("CV HTML & PDF sync", FALSE, "Missing _site/cv/cv-page.html or _site/cv/cv.pdf")
}

# Print summary
cat("========================================================================\n")
cat("SITE VERIFICATION REPORT\n")
cat("========================================================================\n")
n_fail <- 0L
for (r in results) {
  tag <- if (r$ok) "PASS" else "FAIL"
  if (!r$ok) n_fail <- n_fail + 1L
  cat(sprintf("[%s] %-28s | %s\n", tag, r$name, r$detail))
}
cat("------------------------------------------------------------------------\n")
cat(sprintf("Summary: %d passed, %d failed\n", length(results) - n_fail, n_fail))
quit(status = if (n_fail > 0L) 1L else 0L)
