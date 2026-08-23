# Données pédagogiques EIOM 2026

## Ventes immobilières d'Ames, Iowa

Les données du jour 1 sont chargées directement avec `AmesHousing::make_ames()`. Elles décrivent 2 930 ventes résidentielles à Ames, en Iowa. Le jeu complet contient la réponse `Sale_Price` et 80 caractéristiques des propriétés. La matinée 1 utilise principalement `Gr_Liv_Area`, `Overall_Qual`, `Year_Built` et `Garage_Cars`.

Source méthodologique: Dean De Cock (2011), *Ames, Iowa: Alternative to the Boston Housing Data as an End of Semester Regression Project*, Journal of Statistics Education, 19(3). https://doi.org/10.1080/10691898.2011.11889627

Paquet R: Max Kuhn (2020), `AmesHousing`, version 0.0.4. https://CRAN.R-project.org/package=AmesHousing

Une ligne représente une vente résidentielle. Les montants sont en dollars américains et la surface habitable au-dessus du sol est exprimée en pieds carrés. Ces données observationnelles permettent d'étudier des associations et la prédiction, mais ne suffisent pas à identifier des effets causaux.

## Bibliothèques publiques du Québec, ressource complémentaire

Fichier: `bibliotheques_quebec_2024.csv`

Source: Bibliothèque et Archives nationales du Québec, Enquête annuelle sur les bibliothèques publiques du Québec, ressource 2024 publiée sur Données Québec.

Page officielle: https://www.donneesquebec.ca/recherche/dataset/statistiques_des_bibliotheques_publiques_du_quebec

Licence vérifiée le 14 juillet 2026 dans l'API CKAN de Données Québec: Attribution (CC-BY 4.0).

Une ligne représente une bibliothèque publique ou un centre régional. Les indicateurs sont administratifs et déclarés. Ils ne mesurent pas directement la qualité du service, la satisfaction ni l'accessibilité.

## Demandes de services citoyennes 311 de Montréal

Fichier: `requetes_311_montreal_2024_eiom.csv`

Source: Ville de Montréal, demandes de services citoyennes 311 publiées sur Données Québec.

Page officielle: https://www.donneesquebec.ca/recherche/dataset/vmtl-requete-311

Licence vérifiée le 14 juillet 2026 dans l'API CKAN de Données Québec: Attribution (CC-BY 4.0).

Le fichier pédagogique contient un échantillon déterministe de 18 000 requêtes créées en 2024. Une ligne représente une demande de service, pas une personne. Les lignes sont sélectionnées dans l'entrepôt CKAN public selon l'ordre du condensat MD5 de l'identifiant, ce qui évite de télécharger la ressource complète tout en rendant l'extrait reproductible.

La cible pédagogique `issue_7_jours` distingue les demandes dont le dernier statut enregistré est `Terminée` dans les sept jours suivant la création. Cette fenêtre ne constitue pas une norme de service officielle de la Ville de Montréal. Elle fournit une définition opérationnelle commune pour apprendre à estimer une probabilité et à comparer des modèles.

Seules les caractéristiques disponibles à la création sont utilisées comme prédicteurs. Le dernier statut, sa date et le délai calculé servent uniquement à construire la réponse. Les processus et certains attributs peuvent varier entre arrondissements. Certaines demandes peuvent aussi être transférées dans un autre système, selon la documentation officielle. Ces limites doivent accompagner toute interprétation.

## Reproduction

Le script `scripts/preparer_donnees.R` interroge les ressources officielles, vérifie les champs attendus, prépare les variables et reconstruit les deux fichiers.
