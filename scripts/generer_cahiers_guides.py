#!/usr/bin/env python3
"""Générer les cahiers QMD guidés et leurs trousses de téléchargement."""

from __future__ import annotations

import re
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo


RACINE = Path(__file__).resolve().parents[1]
DOSSIER_CANEVA = RACINE / "telechargements" / "canevas"
DOSSIER_TELECHARGEMENTS = RACINE / "telechargements"
URL_SITE = "https://aureliennicosiaulaval.github.io/eiom-2026-modelisation"

CONFIGURATIONS = {
    1: {
        "theme": "Régression linéaire multiple et diagnostics",
        "paquets": ["tidyverse", "AmesHousing", "scales", "patchwork", "broom"],
    },
    2: {
        "theme": "Régression logistique avec les données Titanic",
        "paquets": ["tidyverse", "titanic", "janitor", "tidymodels", "broom"],
    },
    3: {
        "theme": "Arbres, forêts aléatoires et validation temporelle",
        "paquets": ["tidyverse", "tidymodels", "rpart", "ranger"],
    },
}

STYLE_REPONSE = """
<style>
.response-area {
  min-height: 7rem;
  margin: 1.25rem 0 1.75rem;
  padding: 1rem 1.15rem;
  border: 2px solid #8fb8bc;
  border-radius: 0.55rem;
  background: #f7fbfb;
}
.response-area h3 {
  margin-top: 0;
  color: #0f5f63;
}
</style>
""".strip()

BLOC_REPONSE = """
::: {.response-area}
### Réponse de l'équipe

_Écrivez ici votre réponse, vos résultats et l'interprétation demandée._

:::
""".strip()


def separer_entete(texte: str) -> tuple[str, str, str]:
    """Séparer le titre, le sous-titre et le corps d'un fichier QMD."""
    lignes = texte.splitlines()
    if not lignes or lignes[0].strip() != "---":
        raise ValueError("L'entête YAML est absent.")

    fin = next(
        (indice for indice, ligne in enumerate(lignes[1:], start=1) if ligne.strip() == "---"),
        None,
    )
    if fin is None:
        raise ValueError("L'entête YAML n'est pas fermé.")

    entete = "\n".join(lignes[1:fin])
    corps = "\n".join(lignes[fin + 1 :]).strip()

    titre = re.search(r'^title:\s*"(.+)"\s*$', entete, flags=re.MULTILINE)
    sous_titre = re.search(r'^subtitle:\s*"(.+)"\s*$', entete, flags=re.MULTILINE)
    if titre is None or sous_titre is None:
        raise ValueError("Le titre ou le sous-titre de la mission est absent.")

    return titre.group(1), sous_titre.group(1), corps


def section_demande_reponse(titre: str | None) -> bool:
    """Repérer les sections dans lesquelles l'équipe doit écrire."""
    if titre is None:
        return False
    return bool(
        re.match(r"^##\s+\d+\.", titre)
        or titre.startswith("## Votre verdict")
        or titre.startswith("## Votre production")
        or titre.startswith("## Après la mission")
    )


def ajouter_zones_reponse(corps: str) -> str:
    """Ajouter une zone de réponse après chaque étape de travail."""
    resultat: list[str] = []
    titre_courant: str | None = None

    for ligne in corps.splitlines():
        if ligne.startswith("## "):
            if section_demande_reponse(titre_courant):
                resultat.extend(["", BLOC_REPONSE, ""])
            titre_courant = ligne
        resultat.append(ligne)

    if section_demande_reponse(titre_courant):
        resultat.extend(["", BLOC_REPONSE])

    return "\n".join(resultat).strip()


def entete_cahier(jour: int, configuration: dict) -> str:
    """Construire l'entête et le mode d'emploi du cahier."""
    paquets = ", ".join(f'"{paquet}"' for paquet in configuration["paquets"])
    complement_donnees = ""

    if jour == 3:
        complement_donnees = f"""
## Données du jour 3

La trousse ZIP contient déjà le fichier `data/requetes_311_montreal_2024_eiom.csv`. Si vous avez téléchargé seulement ce QMD, exécutez une fois le bloc suivant pour obtenir le fichier public utilisé dans l'atelier.

```{{r}}
#| eval: false
fichier_311 <- "data/requetes_311_montreal_2024_eiom.csv"

if (!file.exists(fichier_311)) {{
  dir.create("data", showWarnings = FALSE)
  download.file(
    "{URL_SITE}/data/requetes_311_montreal_2024_eiom.csv",
    fichier_311,
    mode = "wb"
  )
}}
```
""".strip()

    return f"""---
title: "Cahier guidé des missions du jour {jour}"
subtitle: "{configuration['theme']}"
lang: fr
format:
  html:
    embed-resources: true
    toc: true
    toc-depth: 3
    code-copy: true
    code-overflow: wrap
editor: source
execute:
  echo: true
  warning: false
  message: false
---

{STYLE_REPONSE}

## Identification

Noms: _Écrivez ici._

Équipe: _Écrivez ici._

Date: _Écrivez ici._

## Mode d'emploi

Ce cahier rassemble les trois missions de la journée dans le même ordre et avec les mêmes questions que les énoncés en ligne.

1. Enregistrez le QMD dans un dossier consacré à la journée.
2. Ouvrez-le dans RStudio, Positron ou un autre éditeur compatible avec Quarto.
3. Exécutez seulement les blocs de la mission annoncée par la personne animatrice.
4. Remplacez les espaces de réponse par vos résultats, vos graphiques et vos interprétations.
5. Enregistrez souvent le fichier.

Les blocs portent volontairement l'option `#| eval: false`. Cette option évite que toute la journée soit exécutée automatiquement lors d'un rendu. Vous pouvez quand même exécuter un bloc au moment prévu avec le bouton d'exécution de votre éditeur. Pour inclure ensuite ses résultats dans un document HTML, remplacez son option par `#| eval: true`.

::: {{.callout-important}}
Ne consultez pas une mission avant son ouverture dans la présentation. Cette règle est essentielle au jour 3, où le test futur doit rester fermé jusqu'à la mission finale.
:::

## Préparer les paquets R

Le bloc suivant installe uniquement les paquets manquants. Exécutez-le une fois avant l'atelier si nécessaire.

```{{r}}
#| eval: false
paquets_requis <- c({paquets})
paquets_manquants <- setdiff(
  paquets_requis,
  rownames(installed.packages())
)

if (length(paquets_manquants) > 0) {{
  install.packages(paquets_manquants, dependencies = TRUE)
}}
```

{complement_donnees}
""".strip()


def contenu_cahier(jour: int) -> tuple[str, list[Path]]:
    """Assembler les trois missions d'une journée."""
    parties = [entete_cahier(jour, CONFIGURATIONS[jour])]
    sources: list[Path] = []

    for numero in (1, 2, 3):
        source = RACINE / f"jour{jour}" / "missions" / f"mission{numero}.qmd"
        titre, sous_titre, corps = separer_entete(source.read_text(encoding="utf-8"))
        sources.append(source)
        url = f"{URL_SITE}/jour{jour}/missions/mission{numero}.html"
        parties.extend(
            [
                "",
                "---",
                "",
                f"# {titre}",
                "",
                f"_{sous_titre}_",
                "",
                f"[Ouvrir l'énoncé en ligne]({url})",
                "",
                ajouter_zones_reponse(corps),
            ]
        )

    return "\n".join(parties).strip() + "\n", sources


def verifier_contenu(cahier: str, sources: list[Path]) -> None:
    """Vérifier que chaque ligne utile des énoncés est conservée."""
    for source in sources:
        _, _, corps = separer_entete(source.read_text(encoding="utf-8"))
        lignes_manquantes = [
            ligne
            for ligne in corps.splitlines()
            if ligne.strip() and ligne not in cahier
        ]
        if lignes_manquantes:
            raise RuntimeError(
                f"Le cahier ne reprend pas tout le contenu de {source}: "
                f"{lignes_manquantes[0]}"
            )


def ajouter_fichier_zip(archive: ZipFile, nom: str, contenu: bytes) -> None:
    """Ajouter un fichier avec des métadonnées stables."""
    info = ZipInfo(nom, date_time=(2026, 8, 26, 8, 0, 0))
    info.compress_type = ZIP_DEFLATED
    info.external_attr = 0o100644 << 16
    archive.writestr(info, contenu, compress_type=ZIP_DEFLATED, compresslevel=9)


def creer_trousse(jour: int, qmd: Path) -> Path:
    """Créer une trousse ZIP autonome pour une journée."""
    destination = DOSSIER_TELECHARGEMENTS / f"eiom-2026-jour{jour}-cahier-qmd.zip"
    instructions = f"""EIOM 2026 - Cahier QMD guidé du jour {jour}

1. Décompressez toute la trousse dans un même dossier.
2. Ouvrez {qmd.name} dans RStudio ou Positron.
3. Exécutez les blocs une mission à la fois, au moment annoncé.
4. Écrivez vos réponses directement dans les zones prévues.
5. Conservez le dossier data avec le QMD lorsqu'il est présent.
"""

    with ZipFile(destination, "w") as archive:
        ajouter_fichier_zip(archive, qmd.name, qmd.read_bytes())
        ajouter_fichier_zip(archive, "LISEZ-MOI.txt", instructions.encode("utf-8"))
        if jour == 3:
            donnees = RACINE / "data" / "requetes_311_montreal_2024_eiom.csv"
            ajouter_fichier_zip(
                archive,
                "data/requetes_311_montreal_2024_eiom.csv",
                donnees.read_bytes(),
            )

    return destination


def main() -> None:
    DOSSIER_CANEVA.mkdir(parents=True, exist_ok=True)
    DOSSIER_TELECHARGEMENTS.mkdir(parents=True, exist_ok=True)

    for jour in (1, 2, 3):
        cahier, sources = contenu_cahier(jour)
        verifier_contenu(cahier, sources)
        qmd = DOSSIER_CANEVA / f"eiom-2026-jour{jour}-missions-guidees.qmd"
        qmd.write_text(cahier, encoding="utf-8")
        trousse = creer_trousse(jour, qmd)
        print(f"Jour {jour}: {qmd.relative_to(RACINE)}")
        print(f"Jour {jour}: {trousse.relative_to(RACINE)}")


if __name__ == "__main__":
    main()
