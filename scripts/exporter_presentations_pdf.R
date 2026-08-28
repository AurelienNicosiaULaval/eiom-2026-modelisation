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

if (!requireNamespace("chromote", quietly = TRUE)) {
  stop(
    "Le paquet R chromote est requis pour attendre les figures et les équations.",
    call. = FALSE
  )
}

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("Le paquet R jsonlite est requis pour écrire les PDF.", call. = FALSE)
}

Sys.setenv(CHROMOTE_CHROME = chrome)
options(chromote.timeout = 30)

chrome_args <- chromote::default_chrome_args()
if (identical(Sys.getenv("CI"), "true")) {
  chrome_args <- c(
    chrome_args,
    "--no-sandbox",
    "--disable-dev-shm-usage",
    "--disable-gpu"
  )
}
chromote::set_chrome_args(unique(chrome_args))

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
  expected_pages = c(40L, 43L, 49L),
  required_image_page = c(5L, NA_integer_, NA_integer_),
  stringsAsFactors = FALSE
)

jour_cible <- Sys.getenv("EIOM_PRESENTATION_JOUR", unset = "")
if (nzchar(jour_cible)) {
  presentations <- presentations[
    presentations$source == paste0("jour", jour_cible, "/slides.html"),
    ,
    drop = FALSE
  ]
  if (nrow(presentations) == 0L) {
    stop("Jour de présentation inconnu: ", jour_cible, call. = FALSE)
  }
}

read_pdf_pages <- function(path) {
  pdfinfo <- Sys.which("pdfinfo")
  if (!nzchar(pdfinfo)) {
    stop("L'outil pdfinfo de Poppler est requis.", call. = FALSE)
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

pdf_has_image_on_page <- function(path, page) {
  pdfimages <- Sys.which("pdfimages")
  if (!nzchar(pdfimages)) {
    stop("L'outil pdfimages de Poppler est requis.", call. = FALSE)
  }

  inventory <- system2(
    pdfimages,
    c("-list", shQuote(path)),
    stdout = TRUE,
    stderr = TRUE
  )
  image_lines <- inventory[grepl("^\\s*[0-9]+\\s+[0-9]+\\s+image\\s+", inventory)]
  if (length(image_lines) == 0L) {
    return(FALSE)
  }

  image_pages <- as.integer(sub("^\\s*([0-9]+).*$", "\\1", image_lines))
  page %in% image_pages
}

export_pdf <- function(input_url, output_path, required_image_page = NA_integer_) {
  session <- chromote::ChromoteSession$new(width = 1155, height = 770)
  on.exit(session$close(), add = TRUE)
  session$default_timeout <- 60
  session$go_to(input_url)

  required_page_js <- if (is.na(required_image_page)) {
    "null"
  } else {
    as.character(required_image_page)
  }

  readiness_script <- paste(
    "new Promise((resolve, reject) => {",
    "  const delay = ms => new Promise(done => setTimeout(done, ms));",
    "  const waitFor = async (test, label) => {",
    "    for (let attempt = 0; attempt < 400; attempt += 1) {",
    "      if (test()) return;",
    "      await delay(50);",
    "    }",
    "    throw new Error('Délai dépassé: ' + label);",
    "  };",
    "  (async () => {",
    "    await waitFor(() => window.Reveal && Reveal.isReady(), 'Reveal');",
    paste0("    const requiredImagePage = ", required_page_js, ";"),
    "    const slides = [...document.querySelectorAll('.reveal .slides > section')];",
    "    const requiredSlide = requiredImagePage === null ? null : slides[requiredImagePage - 1];",
    "    const requiredImages = requiredSlide ? [...requiredSlide.querySelectorAll('img')] : [];",
    "    const images = [...document.querySelectorAll(\"img[data-src^='data:image/']\")];",
    "    images.forEach(image => {",
    "      image.src = image.dataset.src;",
    "      image.removeAttribute('data-src');",
    "    });",
    "    requiredImages.forEach(image => {",
    "      image.classList.remove('r-stretch', 'stretch');",
    "      image.style.setProperty('display', 'block', 'important');",
    "      image.style.setProperty('width', '88%', 'important');",
    "      image.style.setProperty('height', 'auto', 'important');",
    "      image.style.setProperty('max-width', '88%', 'important');",
    "      image.style.setProperty('max-height', '500px', 'important');",
    "      image.style.setProperty('margin', '0 auto', 'important');",
    "    });",
    "    await Promise.all(images.map(image => image.complete ? Promise.resolve() :",
    "      new Promise((done, fail) => { image.onload = done; image.onerror = fail; })",
    "    ));",
    "    await Promise.all(images.map(image => image.decode ? image.decode() : Promise.resolve()));",
    "    if (document.fonts && document.fonts.ready) await document.fonts.ready;",
    "    const printStyle = document.createElement('style');",
    "    printStyle.textContent = \"@media print { .reveal .slides section img.r-stretch[src^='data:image/'] { display:block!important; width:auto!important; height:auto!important; max-width:88%!important; max-height:500px!important; margin:0 auto!important; } }\";",
    "    document.head.appendChild(printStyle);",
    "    if (document.querySelector('.math')) {",
    "      await waitFor(() => window.MathJax && MathJax.Hub, 'MathJax');",
    "      await new Promise(done => MathJax.Hub.Queue(['Typeset', MathJax.Hub, document], done));",
    "    }",
    "    Reveal.layout();",
    "    await new Promise(done => requestAnimationFrame(() => requestAnimationFrame(done)));",
    "    await delay(500);",
    "    if (requiredImagePage !== null) {",
    "      const imageVisible = image => {",
    "        const box = image.getBoundingClientRect();",
    "        const style = getComputedStyle(image);",
    "        return image.complete && image.naturalWidth > 0 && box.width > 300 && box.height > 200 &&",
    "          style.display !== 'none' && style.visibility !== 'hidden';",
    "      };",
    "      if (!requiredImages.length || requiredImages.some(image => !imageVisible(image))) {",
    "        throw new Error('Figure absente ou sans dimensions à la page ' + requiredImagePage);",
    "      }",
    "    }",
    "    resolve({ imageCount: images.length });",
    "  })().catch(error => reject(error));",
    "})",
    sep = "\n"
  )

  session$Runtime$evaluate(
    readiness_script,
    awaitPromise = TRUE,
    returnByValue = TRUE
  )

  result <- session$Page$printToPDF(
    printBackground = TRUE,
    preferCSSPageSize = TRUE
  )
  writeBin(jsonlite::base64_dec(result$data), output_path)
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

  export_pdf(
    input_url,
    output_path,
    presentations$required_image_page[[index]]
  )

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

  required_image_page <- presentations$required_image_page[[index]]
  if (!is.na(required_image_page)) {
    has_image <- pdf_has_image_on_page(output_path, required_image_page)
    if (identical(has_image, FALSE)) {
      stop(
        "Figure absente de la page ", required_image_page,
        " dans ", output_path,
        call. = FALSE
      )
    }
  }

  message(
    "PDF exporté: ", output_path,
    if (!is.na(pages)) paste0(" (", pages, " pages)") else ""
  )
}

message(
  if (nzchar(jour_cible)) {
    paste0("La présentation PDF du jour ", jour_cible, " est prête au téléchargement.")
  } else {
    "Les trois présentations PDF sont prêtes au téléchargement."
  }
)
