# Install only the R packages that are missing for the EIOM 2026 workshops.

required_packages <- c(
  "AmesHousing",
  "broom",
  "car",
  "httr2",
  "janitor",
  "jsonlite",
  "knitr",
  "lubridate",
  "patchwork",
  "performance",
  "ranger",
  "rpart",
  "scales",
  "tidymodels",
  "titanic",
  "tidyverse",
  "xml2"
)

installed_packages <- rownames(installed.packages())
missing_packages <- setdiff(required_packages, installed_packages)

if (length(missing_packages) > 0L) {
  install.packages(missing_packages, dependencies = TRUE)
}

package_status <- vapply(
  required_packages,
  requireNamespace,
  FUN.VALUE = logical(1),
  quietly = TRUE
)

if (!all(package_status)) {
  stop(
    "Certains paquets n'ont pas pu être chargés: ",
    paste(names(package_status)[!package_status], collapse = ", "),
    call. = FALSE
  )
}

message("Tous les paquets requis sont disponibles.")
