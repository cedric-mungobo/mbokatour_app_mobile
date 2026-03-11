# Media API Requirements

Objectif: permettre à l'application mobile d'afficher correctement les medias selon leur format `portrait`, `landscape` ou `square`.

## Champs a ajouter

Pour chaque media retourne dans une place, ajouter uniquement:

- `width`: largeur reelle du media en pixels
- `height`: hauteur reelle du media en pixels
- `orientation`: `portrait`, `landscape` ou `square`

## Exemple attendu

```json
{
  "id": 55,
  "type": "photo",
  "image_url": "https://cdn.example.com/places/12/main.jpg",
  "is_primary": true,
  "width": 1080,
  "height": 1350,
  "orientation": "portrait"
}
```

## Regle de calcul

- `portrait` si `height > width`
- `landscape` si `width > height`
- `square` si `width == height` ou ratio tres proche de `1:1`
