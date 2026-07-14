# Verify local links and assets in the rendered public site.

suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(stringr)
  library(tibble)
  library(xml2)
})

site_dir <- normalizePath("_site", mustWork = TRUE)
html_files <- list.files(site_dir, pattern = "\\.html$", recursive = TRUE, full.names = TRUE)

extract_references <- function(html_file) {
  document <- read_html(html_file)
  hrefs <- xml_attr(xml_find_all(document, "//a[@href] | //link[@href]"), "href")
  sources <- xml_attr(
    xml_find_all(document, "//img[@src] | //script[@src] | //iframe[@src]"),
    "src"
  )

  tibble(
    page = html_file,
    reference = c(hrefs, sources)
  )
}

references <- map_dfr(html_files, extract_references) |>
  filter(
    !is.na(reference),
    reference != "",
    !str_starts(reference, "#"),
    !str_detect(reference, "^(https?:|mailto:|tel:|data:|javascript:)")
  ) |>
  mutate(
    reference_clean = str_remove(reference, "[?#].*$"),
    reference_clean = URLdecode(reference_clean),
    target = if_else(
      str_starts(reference_clean, "/"),
      file.path(site_dir, str_remove(reference_clean, "^/")),
      file.path(dirname(page), reference_clean)
    ),
    target = if_else(
      str_ends(target, "/"),
      file.path(target, "index.html"),
      target
    ),
    exists = file.exists(target)
  )

broken <- references |>
  filter(reference_clean != "", !exists) |>
  distinct(page, reference, target)

if (nrow(broken) > 0L) {
  print(broken, n = Inf)
  stop("Le site contient des liens ou ressources locales introuvables.", call. = FALSE)
}

message(
  "Vérification des liens réussie pour ",
  length(html_files),
  " pages HTML."
)
