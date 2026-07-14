# Prepare the fixed teaching extracts used by the EIOM 2026 workshops.
# Sources: Données Québec / BAnQ and Ville de Montréal / Données Québec.

library(dplyr)
library(httr2)
library(jsonlite)
library(lubridate)
library(readr)
library(stringr)

find_project_root <- function(path = getwd()) {
  current <- normalizePath(path, mustWork = FALSE)
  repeat {
    if (file.exists(file.path(current, "_quarto.yml"))) return(current)
    parent <- dirname(current)
    if (identical(parent, current)) {
      stop("Impossible de trouver la racine du projet.", call. = FALSE)
    }
    current <- parent
  }
}

parse_number_fr <- function(x) {
  if (is.numeric(x)) return(as.numeric(x))
  x <- gsub("\u00a0", " ", as.character(x), fixed = TRUE)
  parse_number(x, locale = locale(decimal_mark = ",", grouping_mark = " "))
}

ratio_if_possible <- function(numerator, denominator) {
  if_else(
    !is.na(numerator) & !is.na(denominator) & denominator > 0,
    numerator / denominator,
    NA_real_
  )
}

map_code <- function(x, mapping) {
  x <- str_squish(as.character(x))
  mapped <- unname(mapping[x])
  if_else(is.na(mapped), na_if(x, ""), mapped)
}

root <- find_project_root()
data_dir <- file.path(root, "data")
raw_dir <- file.path(data_dir, "raw")
dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)

access_date <- as.Date("2026-07-14")

# Libraries of Quebec
bibliotheques_url <- paste0(
  "https://www.donneesquebec.ca/recherche/dataset/",
  "231a38a8-f28e-4bef-82ea-dc98a14c1b6f/resource/",
  "01183d3e-c79c-4d09-915c-f35ffe4dfda8/download/",
  "statistiques_bibliotheques_quebec_2024.csv"
)
bibliotheques_raw_path <- file.path(raw_dir, "statistiques_bibliotheques_quebec_2024.csv")
download.file(bibliotheques_url, bibliotheques_raw_path, mode = "wb", quiet = TRUE)

bibliotheques_source <- read_delim(
  bibliotheques_raw_path,
  delim = ";",
  locale = locale(encoding = "UTF-8", decimal_mark = ","),
  show_col_types = FALSE
)

required_bibliotheques <- c(
  "Bibliothèque ou Centre régional",
  "Région administrative",
  "Population desservie",
  "Catégorie de la bibl.",
  "Modalités d'abonnement",
  "Visites (Total)",
  "Prêts / Tous les doc. (Total)",
  "Usagers inscrits (Total)",
  "Progr. / Toutes les activités (Total)",
  "Dép. fonct. / Toutes les dépenses ($)"
)

missing_bibliotheques <- setdiff(required_bibliotheques, names(bibliotheques_source))
if (length(missing_bibliotheques) > 0L) {
  stop(
    "Variables absentes de la source des bibliothèques: ",
    paste(missing_bibliotheques, collapse = ", "),
    call. = FALSE
  )
}

bibliotheques <- bibliotheques_source |>
  transmute(
    bibliotheque = `Bibliothèque ou Centre régional`,
    region_administrative = `Région administrative`,
    population_desservie = parse_number_fr(`Population desservie`),
    categorie_bibliotheque = `Catégorie de la bibl.`,
    modalites_abonnement = `Modalités d'abonnement`,
    visites_total = parse_number_fr(`Visites (Total)`),
    prets_total = parse_number_fr(`Prêts / Tous les doc. (Total)`),
    usagers_inscrits_total = parse_number_fr(`Usagers inscrits (Total)`),
    activites_total = parse_number_fr(`Progr. / Toutes les activités (Total)`),
    depenses_fonctionnement_total = parse_number_fr(`Dép. fonct. / Toutes les dépenses ($)`),
    visites_par_habitant = ratio_if_possible(visites_total, population_desservie),
    prets_par_habitant = ratio_if_possible(prets_total, population_desservie),
    usagers_inscrits_par_habitant = ratio_if_possible(usagers_inscrits_total, population_desservie),
    depenses_par_habitant = ratio_if_possible(depenses_fonctionnement_total, population_desservie),
    source_csv_url = bibliotheques_url,
    access_date = access_date
  ) |>
  arrange(region_administrative, bibliotheque)

if (nrow(bibliotheques) != 188L || ncol(bibliotheques) != 16L) {
  stop("La table des bibliothèques n'a pas les dimensions attendues.", call. = FALSE)
}

write_csv(
  bibliotheques,
  file.path(data_dir, "bibliotheques_quebec_2024.csv"),
  na = ""
)

# Montreal 311 service requests
#
# The CKAN datastore query avoids downloading the complete 786 MB resource.
# The deterministic MD5 ordering fixes the teaching sample even if the API
# changes its default row order. Only 2024 requests are retained so every
# record has substantially more than seven days of follow-up at extraction.
requete_311_resource_id <- "2cfa0e06-9be4-49a6-b7f1-ee9f2363a872"
requete_311_api <- "https://donnees.montreal.ca/api/3/action/datastore_search_sql"
requete_311_page <- paste0(
  "https://www.donneesquebec.ca/recherche/dataset/",
  "vmtl-requete-311"
)

requete_311_sql <- paste0(
  'SELECT "ID_UNIQUE", "NATURE", "ACTI_NOM", "TYPE_LIEU_INTERV", ',
  '"ARRONDISSEMENT_GEO", "DDS_DATE_CREATION", "PROVENANCE_ORIGINALE", ',
  '"DERNIER_STATUT", "DATE_DERNIER_STATUT" ',
  'FROM "', requete_311_resource_id, '" ',
  'WHERE "NATURE" = \'Requete\' ',
  'AND "DDS_DATE_CREATION" >= \'2024-01-01\' ',
  'AND "DDS_DATE_CREATION" < \'2025-01-01\' ',
  'AND "ID_UNIQUE" IS NOT NULL ',
  'ORDER BY md5("ID_UNIQUE") LIMIT 18000'
)

requete_311_response <- request(requete_311_api) |>
  req_url_query(sql = requete_311_sql) |>
  req_retry(max_tries = 3) |>
  req_perform()

requete_311_payload <- resp_body_json(
  requete_311_response,
  simplifyVector = TRUE
)

if (!isTRUE(requete_311_payload$success)) {
  stop("L'API des requêtes 311 n'a pas retourné un résultat valide.", call. = FALSE)
}

requete_311_source <- as_tibble(requete_311_payload$result$records)

required_requetes_311 <- c(
  "ID_UNIQUE", "NATURE", "ACTI_NOM", "TYPE_LIEU_INTERV",
  "ARRONDISSEMENT_GEO", "DDS_DATE_CREATION", "PROVENANCE_ORIGINALE",
  "DERNIER_STATUT", "DATE_DERNIER_STATUT"
)

missing_requetes_311 <- setdiff(required_requetes_311, names(requete_311_source))
if (length(missing_requetes_311) > 0L) {
  stop(
    "Variables absentes de la source 311: ",
    paste(missing_requetes_311, collapse = ", "),
    call. = FALSE
  )
}

write_csv(
  requete_311_source,
  file.path(raw_dir, "requetes_311_montreal_2024_source_eiom.csv"),
  na = ""
)

month_labels <- c(
  "Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
  "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"
)
weekday_labels <- c(
  "Dimanche", "Lundi", "Mardi", "Mercredi",
  "Jeudi", "Vendredi", "Samedi"
)

requetes_311 <- requete_311_source |>
  mutate(
    date_heure_creation = ymd_hms(DDS_DATE_CREATION, tz = "America/Toronto"),
    date_heure_dernier_statut = ymd_hms(
      DATE_DERNIER_STATUT,
      tz = "America/Toronto",
      quiet = TRUE
    ),
    delai_dernier_statut_jours = as.numeric(
      difftime(
        date_heure_dernier_statut,
        date_heure_creation,
        units = "days"
      )
    )
  ) |>
  transmute(
    identifiant_requete = ID_UNIQUE,
    date_creation = as.Date(date_heure_creation, tz = "America/Toronto"),
    mois_creation = factor(
      month(date_heure_creation),
      levels = 1:12,
      labels = month_labels
    ) |>
      as.character(),
    jour_semaine = factor(
      wday(date_heure_creation),
      levels = 1:7,
      labels = weekday_labels
    ) |>
      as.character(),
    plage_horaire = case_when(
      hour(date_heure_creation) < 6 ~ "Nuit, 0 h à 5 h 59",
      hour(date_heure_creation) < 12 ~ "Matin, 6 h à 11 h 59",
      hour(date_heure_creation) < 18 ~ "Après-midi, 12 h à 17 h 59",
      TRUE ~ "Soir, 18 h à 23 h 59"
    ),
    activite = na_if(str_squish(ACTI_NOM), ""),
    type_lieu = na_if(str_squish(TYPE_LIEU_INTERV), ""),
    arrondissement = na_if(str_squish(ARRONDISSEMENT_GEO), ""),
    provenance = na_if(str_squish(PROVENANCE_ORIGINALE), ""),
    dernier_statut = na_if(str_squish(DERNIER_STATUT), ""),
    date_dernier_statut = as.Date(
      date_heure_dernier_statut,
      tz = "America/Toronto"
    ),
    delai_dernier_statut_jours = round(delai_dernier_statut_jours, 3),
    issue_7_jours = if_else(
      dernier_statut == "Terminée" &
        !is.na(delai_dernier_statut_jours) &
        delai_dernier_statut_jours <= 7,
      "terminee_7_jours",
      "non_terminee_7_jours"
    ),
    source_page_url = requete_311_page,
    access_date = access_date
  ) |>
  arrange(date_creation, identifiant_requete)

prevalence_311 <- mean(requetes_311$issue_7_jours == "non_terminee_7_jours")
if (
  nrow(requetes_311) != 18000L ||
    n_distinct(requetes_311$identifiant_requete) != 18000L ||
    prevalence_311 < 0.30 || prevalence_311 > 0.60 ||
    min(requetes_311$date_creation) < as.Date("2024-01-01") ||
    max(requetes_311$date_creation) >= as.Date("2025-01-01")
) {
  stop("L'échantillon 311 ne respecte pas les contrôles attendus.", call. = FALSE)
}

write_csv(
  requetes_311,
  file.path(data_dir, "requetes_311_montreal_2024_eiom.csv"),
  na = ""
)

message("Données préparées et validées dans ", data_dir)
