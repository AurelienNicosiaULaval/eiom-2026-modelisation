# Run lightweight structural checks before rendering or publication.

library(readr)
library(stringr)
library(dplyr)

if (!requireNamespace("AmesHousing", quietly = TRUE)) {
  stop("Le paquet AmesHousing est requis.", call. = FALSE)
}

if (!requireNamespace("titanic", quietly = TRUE)) {
  stop("Le paquet titanic est requis.", call. = FALSE)
}

if (!requireNamespace("chromote", quietly = TRUE)) {
  stop("Le paquet chromote est requis pour exporter les PDF.", call. = FALSE)
}

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("Le paquet jsonlite est requis pour exporter les PDF.", call. = FALSE)
}

required_files <- c(
  "_quarto.yml",
  "index.qmd",
  "programme.qmd",
  "diagnostic.qmd",
  "preparation.qmd",
  "ressources.qmd",
  "scripts/exporter_presentations_pdf.R",
  "scripts/generer_cahiers_guides.py",
  "data/bibliotheques_quebec_2024.csv",
  "data/requetes_311_montreal_2024_eiom.csv",
  "telechargements/canevas/eiom-2026-jour1-missions-guidees.qmd",
  "telechargements/canevas/eiom-2026-jour2-missions-guidees.qmd",
  "telechargements/canevas/eiom-2026-jour3-missions-guidees.qmd",
  "telechargements/eiom-2026-jour1-cahier-qmd.zip",
  "telechargements/eiom-2026-jour2-cahier-qmd.zip",
  "telechargements/eiom-2026-jour3-cahier-qmd.zip",
  "jour1/slides.qmd",
  "jour1/tutoriel.qmd",
  "jour1/pratique.qmd",
  "jour1/missions/mission1.qmd",
  "jour1/missions/mission2.qmd",
  "jour1/missions/mission3.qmd",
  "jour2/slides.qmd",
  "jour2/tutoriel.qmd",
  "jour2/pratique.qmd",
  "jour2/missions/mission1.qmd",
  "jour2/missions/mission2.qmd",
  "jour2/missions/mission3.qmd",
  "jour3/slides.qmd",
  "jour3/tutoriel.qmd",
  "jour3/pratique.qmd",
  "jour3/missions/mission1.qmd",
  "jour3/missions/mission2.qmd",
  "jour3/missions/mission3.qmd",
  "projet-integrateur.qmd"
)

private_files <- c(
  "instructeur/guide-animation.qmd",
  "instructeur/checklist-logistique.qmd",
  "instructeur/provenance-reutilisation.qmd",
  "instructeur/corriges/jour1.qmd",
  "instructeur/audit-pedagogique-jour1.qmd",
  "instructeur/audit-pedagogique-jour2.qmd",
  "instructeur/conducteur-matinee2.qmd",
  "instructeur/corriges/jour2.qmd",
  "instructeur/audit-pedagogique-jour3.qmd",
  "instructeur/conducteur-matinee3.qmd",
  "instructeur/script-demo-jour3.R",
  "instructeur/corriges/jour3.qmd"
)

missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files) > 0L) {
  stop("Fichiers requis absents: ", paste(missing_files, collapse = ", "), call. = FALSE)
}

if (dir.exists("instructeur")) {
  missing_private_files <- private_files[!file.exists(private_files)]
  if (length(missing_private_files) > 0L) {
    stop(
      "Fichiers privés attendus absents: ",
      paste(missing_private_files, collapse = ", "),
      call. = FALSE
    )
  }
}

qmd_files <- list.files(".", pattern = "\\.qmd$", recursive = TRUE, full.names = TRUE)

duplicate_sync_files <- list.files(
  ".",
  pattern = " [23]\\.(qmd|html)$",
  recursive = TRUE,
  full.names = TRUE
)
if (length(duplicate_sync_files) > 0L) {
  stop(
    "Copies synchronisées ambiguës détectées: ",
    paste(duplicate_sync_files, collapse = ", "),
    call. = FALSE
  )
}

missing_embed <- qmd_files[!vapply(
  qmd_files,
  function(path) any(str_detect(readLines(path, warn = FALSE), "embed-resources:\\s*true")),
  logical(1)
)]
if (length(missing_embed) > 0L) {
  stop("embed-resources: true absent de: ", paste(missing_embed, collapse = ", "), call. = FALSE)
}

text_files <- list.files(
  ".",
  pattern = "\\.(qmd|md|R|yml|yaml|scss|css|js)$",
  recursive = TRUE,
  full.names = TRUE
)
text_files <- text_files[!str_detect(text_files, "(^|/)(_site|tmp)/")]
text_files <- text_files[!str_detect(
  text_files,
  "(^|/)(\\.quarto|_freeze|site_libs)/"
)]
text_files <- text_files[!str_detect(
  text_files,
  "^\\./instructeur/audit-contenu-2026-08-24\\.md$"
)]
has_em_dash <- vapply(
  text_files,
  function(path) any(str_detect(
    readLines(path, warn = FALSE),
    fixed(intToUtf8(0x2014))
  )),
  logical(1)
)
if (any(has_em_dash)) {
  stop("Tiret cadratin détecté dans: ", paste(text_files[has_em_dash], collapse = ", "), call. = FALSE)
}

bibliotheques <- read_csv("data/bibliotheques_quebec_2024.csv", show_col_types = FALSE)
ames <- AmesHousing::make_ames()
titanic <- titanic::titanic_train
requetes_311 <- read_csv(
  "data/requetes_311_montreal_2024_eiom.csv",
  show_col_types = FALSE
)

stopifnot(nrow(bibliotheques) == 188L)
stopifnot(nrow(ames) == 2930L)
stopifnot(ncol(ames) == 81L)
stopifnot(identical(
  levels(ames$Overall_Qual),
  c(
    "Very_Poor", "Poor", "Fair", "Below_Average", "Average",
    "Above_Average", "Good", "Very_Good", "Excellent",
    "Very_Excellent"
  )
))
stopifnot(nrow(titanic) == 891L)
stopifnot(ncol(titanic) == 12L)
stopifnot(sum(titanic$Survived) == 342L)
stopifnot(sum(is.na(titanic$Age)) == 177L)
stopifnot(
  all(
    c("PassengerId", "Survived", "Pclass", "Sex", "Age", "Fare") %in%
      names(titanic)
  )
)
stopifnot(
  all(
    c("Sale_Price", "Gr_Liv_Area", "Overall_Qual", "Year_Built", "Garage_Cars") %in%
      names(ames)
  )
)
stopifnot(nrow(requetes_311) == 18000L)
stopifnot(n_distinct(requetes_311$identifiant_requete) == 18000L)
stopifnot(
  all(
    c("non_terminee_7_jours", "terminee_7_jours") %in%
      unique(requetes_311$issue_7_jours)
  )
)
stopifnot(min(requetes_311$date_creation) >= as.Date("2024-01-01"))
stopifnot(max(requetes_311$date_creation) < as.Date("2025-01-01"))
stopifnot(sum(requetes_311$date_creation < as.Date("2024-10-01")) == 14351L)
stopifnot(sum(requetes_311$date_creation >= as.Date("2024-10-01")) == 3649L)
stopifnot(sum(requetes_311$issue_7_jours == "non_terminee_7_jours") == 7772L)

jour3_slide_count <- sum(
  str_detect(
    readLines("jour3/slides.qmd", warn = FALSE),
    "^##\\s+"
  )
)
stopifnot(jour3_slide_count == 48L)

extract_note_minutes <- function(path) {
  lines <- readLines(path, warn = FALSE)
  notes <- which(lines == "::: {.notes}")
  minutes <- vapply(
    notes,
    function(index) {
      following <- lines[seq.int(
        index + 1L,
        min(index + 4L, length(lines))
      )]
      timing <- following[str_detect(following, "^[0-9]+ minutes?\\.")]
      if (length(timing) == 0L) {
        return(0)
      }
      as.numeric(str_match(timing[[1]], "^([0-9]+)")[, 2])
    },
    numeric(1)
  )
  sum(minutes)
}

stopifnot(extract_note_minutes("jour2/slides.qmd") == 210)
stopifnot(extract_note_minutes("jour3/slides.qmd") == 210)

stopifnot(any(str_detect(
  readLines("jour1/missions/mission2.qmd", warn = FALSE),
  fixed("contributions")
)))
stopifnot(any(str_detect(
  readLines("jour2/missions/mission1.qmd", warn = FALSE),
  fixed("sexe * classe")
)))
stopifnot(any(str_detect(
  readLines("jour2/missions/mission2.qmd", warn = FALSE),
  fixed("max(abs(probabilites_originales - probabilites_recodees))")
)))

workflow <- readLines(".github/workflows/publish.yml", warn = FALSE)
stopifnot(any(str_detect(
  workflow,
  fixed("Rscript scripts/exporter_presentations_pdf.R")
)))

export_pdf_script <- readLines(
  "scripts/exporter_presentations_pdf.R",
  warn = FALSE
)
stopifnot(any(str_detect(
  export_pdf_script,
  fixed("required_image_page = c(5L")
)))
stopifnot(any(str_detect(
  export_pdf_script,
  fixed("pdf_has_image_on_page")
)))

pdf_links <- c(
  "jour1/index.qmd" = "eiom-2026-jour1-regression-lineaire.pdf",
  "jour2/index.qmd" = "eiom-2026-jour2-regression-logistique.pdf",
  "jour3/index.qmd" = "eiom-2026-jour3-apprentissage-automatique.pdf"
)
stopifnot(all(vapply(
  names(pdf_links),
  function(path) any(str_detect(
    readLines(path, warn = FALSE),
    fixed(pdf_links[[path]])
  )),
  logical(1)
)))

cahiers_guides <- tibble(
  jour = 1:3,
  qmd = file.path(
    "telechargements/canevas",
    paste0("eiom-2026-jour", 1:3, "-missions-guidees.qmd")
  ),
  archive = file.path(
    "telechargements",
    paste0("eiom-2026-jour", 1:3, "-cahier-qmd.zip")
  )
)

for (indice in seq_len(nrow(cahiers_guides))) {
  jour <- cahiers_guides$jour[[indice]]
  cahier_path <- cahiers_guides$qmd[[indice]]
  archive_path <- cahiers_guides$archive[[indice]]
  cahier <- readLines(cahier_path, warn = FALSE)

  stopifnot(any(str_detect(cahier, fixed("embed-resources: true"))))
  stopifnot(sum(str_detect(cahier, fixed("# Mission"))) == 3L)
  stopifnot(sum(str_detect(cahier, fixed("### Réponse de l'équipe"))) >= 10L)

  sources <- file.path(
    paste0("jour", jour),
    "missions",
    paste0("mission", 1:3, ".qmd")
  )
  questions_sources <- unlist(lapply(
    sources,
    function(path) {
      lignes <- readLines(path, warn = FALSE)
      str_squish(lignes[str_detect(lignes, fixed("?"))])
    }
  ))
  questions_cahier <- str_squish(cahier[str_detect(cahier, fixed("?"))])
  questions_manquantes <- setdiff(questions_sources, questions_cahier)
  if (length(questions_manquantes) > 0L) {
    stop(
      "Questions absentes du cahier du jour ", jour, ": ",
      paste(questions_manquantes, collapse = " | "),
      call. = FALSE
    )
  }

  contenu_archive <- utils::unzip(archive_path, list = TRUE)$Name
  stopifnot(basename(cahier_path) %in% contenu_archive)
  stopifnot("LISEZ-MOI.txt" %in% contenu_archive)
  if (jour == 3L) {
    stopifnot(
      "data/requetes_311_montreal_2024_eiom.csv" %in% contenu_archive
    )
  }

  pages_publiques <- c(
    paste0("jour", jour, "/index.qmd"),
    paste0("jour", jour, "/pratique.qmd"),
    "ressources.qmd"
  )
  stopifnot(all(vapply(
    pages_publiques,
    function(path) any(str_detect(
      readLines(path, warn = FALSE),
      fixed(basename(cahier_path))
    )),
    logical(1)
  )))
}

mission2_jour3 <- readLines("jour3/missions/mission2.qmd", warn = FALSE)
stopifnot(any(str_detect(mission2_jour3, fixed("sections 19 à 25"))))
stopifnot(!any(str_detect(mission2_jour3, fixed('importance = "permutation"'))))

message("Validation structurelle réussie.")
