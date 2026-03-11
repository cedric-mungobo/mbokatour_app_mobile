# Release Notes v1.0.2

Date: 2026-03-11

## What’s New

- ajout des ecrans Favoris et Historique des visites
- amelioration de l'affichage des medias portrait et paysage sur la home
- cartes plus lisibles avec un rendu visuel allégé
- correction et renforcement du chargement des donnees via l'API
- meilleure stabilite generale de l'application

## Nouveautes

- ajout de l'ecran `Favoris`
- ajout de l'ecran `Historique des visites`
- ajout du chargement API des favoris utilisateur
- ajout du chargement API de l'historique des visites

## Home

- refonte du header home
- bottom navigation extraite en composant reutilisable
- simplification des categories en mode texte
- ajustement de la grille media sur la home
- support d'un affichage different selon media portrait ou paysage
- fallback front si l'API ne fournit pas `width`, `height` ou `orientation`

## Medias

- ajout d'un resolver local pour detecter le ratio des images et videos
- cartes paysage affichees en `16:9`
- cartes portrait affichees avec taille fixe
- reduction de l'overlay noir sur les cards pour un rendu plus clair

## Place details

- remplacement des icones `like` et `favorite`
- ajout du `pull-to-refresh`

## Technique

- meilleure gestion de la cle API dans les requetes
- messages d'erreur plus explicites pour les erreurs `401`
- conservation des erreurs `Dio` pour faciliter le debug

## Version

- application version: `1.0.2`
- build number: `3`
