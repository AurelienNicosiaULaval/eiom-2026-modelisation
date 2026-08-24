# EIOM 2026 - Modéliser pour comprendre et prédire

Ce dépôt contient le support public de trois matinées de formation en R pour l'École interdisciplinaire outils et méthodes 2026.

Site public: https://aureliennicosiaulaval.github.io/eiom-2026-modelisation/

## Contenu

- Jour 1: régression linéaire multiple et diagnostics
- Jour 2: régression logistique, seuils et calibration avec les données Titanic
- Jour 3: arbres, forêts aléatoires, validation temporelle et décision surveillable avec les demandes 311 de Montréal
- Diagnostic de départ, tutoriels, pratiques et projet intégrateur

## Rendu local

```sh
Rscript scripts/installer_paquets.R
Rscript scripts/preparer_donnees.R
quarto render
Rscript scripts/valider_projet.R
Rscript scripts/verifier_site.R
```

Le site est généré dans `_site/`.

## Données

Les données intégrées sont des extraits reproductibles de sources officielles québécoises. Leur provenance, leur licence et leurs limites sont documentées dans `data/README.md`.

## Matériel enseignant

Le dossier local `instructeur/` contient les corrigés, le guide d'animation et les plans de repli. Il est volontairement exclu du dépôt public par `.gitignore`.

## Publication

Chaque poussée sur `main` valide le projet, reconstruit le site Quarto, vérifie les liens locaux et publie automatiquement le résultat sur GitHub Pages.
