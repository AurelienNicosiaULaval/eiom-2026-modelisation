# Données pédagogiques EIOM 2026

## Bibliothèques publiques du Québec

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
