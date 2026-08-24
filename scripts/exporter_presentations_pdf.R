# Export the rendered RevealJS presentations as downloadable PDF files.

site_dir <- normalizePath("_site", mustWork = TRUE)
output_dir <- file.path(site_dir, "telechargements")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

chrome_candidates <- unique(c(
  Sys.getenv("CHROME_BIN", unset = ""),
  unname(Sys.which(c(
    "google-chrome",
    "google-chrome-stable",
    "chromium",
    "chromium-browser"
  ))),
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
))

chrome_candidates <- chrome_candidates[
  nzchar(chrome_candidates) & file.exists(chrome_candidates)
]

if (length(chrome_candidates) == 0L) {
  stop(
    "Chrome ou Chromium est requis pour exporter les présentations en PDF.",
    call. = FALSE
  )
}

chrome <- chrome_candidates[[1]]

presentations <- data.frame(
  source = c(
    "jour1/slides.html",
    "jour2/slides.html",
    "jour3/slides.html"
  ),
  output = c(
    "eiom-2026-jour1-regression-lineaire.pdf",
    "eiom-2026-jour2-regression-logistique.pdf",
    "eiom-2026-jour3-apprentissage-automatique.pdf"
  ),
  expected_pages = c(40L, 43L, 48L),
  stringsAsFactors = FALSE
)

read_pdf_pages <- function(path) {
  pdfinfo <- Sys.which("pdfinfo")
  if (!nzchar(pdfinfo)) {
    return(NA_integer_)
  }

  information <- system2(
    pdfinfo,
    shQuote(path),
    stdout = TRUE,
    stderr = TRUE
  )
  pages_line <- information[grepl("^Pages:", information)]
  if (length(pages_line) != 1L) {
    return(NA_integer_)
  }

  as.integer(trimws(sub("^Pages:", "", pages_line)))
}

for (index in seq_len(nrow(presentations))) {
  input_path <- file.path(site_dir, presentations$source[[index]])
  output_path <- file.path(output_dir, presentations$output[[index]])

  if (!file.exists(input_path)) {
    stop("Présentation HTML absente: ", input_path, call. = FALSE)
  }

  input_url <- paste0(
    "file://",
    URLencode(normalizePath(input_path), reserved = FALSE),
    "?print-pdf"
  )

  arguments <- c(
    "--headless=new",
    "--disable-gpu",
    "--no-sandbox",
    "--run-all-compositor-stages-before-draw",
    "--virtual-time-budget=10000",
    paste0("--print-to-pdf=", shQuote(output_path)),
    "--no-pdf-header-footer",
    shQuote(input_url)
  )

  output <- system2(
    chrome,
    arguments,
    stdout = TRUE,
    stderr = TRUE
  )
  status <- attr(output, "status")

  if (!is.null(status) && status != 0L) {
    stop(
      "Échec de l'export PDF de ", presentations$source[[index]],
      ": ", paste(output, collapse = "\n"),
      call. = FALSE
    )
  }

  if (!file.exists(output_path) || file.info(output_path)$size < 50000) {
    stop("PDF absent ou incomplet: ", output_path, call. = FALSE)
  }

  connection <- file(output_path, open = "rb")
  signature <- rawToChar(readBin(connection, what = "raw", n = 4L))
  close(connection)
  if (!identical(signature, "%PDF")) {
    stop("Signature PDF invalide: ", output_path, call. = FALSE)
  }

  pages <- read_pdf_pages(output_path)
  if (!is.na(pages) && pages != presentations$expected_pages[[index]]) {
    stop(
      "Nombre de pages inattendu pour ", output_path,
      ": ", pages, " au lieu de ",
      presentations$expected_pages[[index]],
      call. = FALSE
    )
  }

  message(
    "PDF exporté: ", output_path,
    if (!is.na(pages)) paste0(" (", pages, " pages)") else ""
  )
}

message("Les trois présentations PDF sont prêtes au téléchargement.")
