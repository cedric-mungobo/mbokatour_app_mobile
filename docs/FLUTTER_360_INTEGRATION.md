# Flutter 360 Integration (MbokaTour)

## Objectif

Afficher une visite 360 dans Flutter a partir du `GET /api/places/{id}`.

Le backend renvoie la visite dans `place.immersive_tour` (si un tour est publie).

## Donnees utiles dans la reponse API

Dans `PlaceResource`, tu recois:

- `immersive_tour`
  - `id`
  - `title`
  - `start_scene_id`
  - `scenes[]`
    - `id`
    - `name`
    - `panorama_url`
    - `instruction_text`
    - `highlight_hotspot_id`
    - `hotspots[]`
      - `id`
      - `yaw`
      - `pitch`
      - `label`
      - `action_type`
      - `target_scene_id`
      - `payload`

## Comportement attendu dans Flutter

### 1. Charger le lieu

- Appel API: `GET /api/places/{placeId}`
- Verifier `immersive_tour != null`

Si `immersive_tour` est null:
- masquer le bouton "Visite 360" ou afficher "Pas encore disponible"

### 2. Indexer les scenes par ID

Construire une map pour navigation rapide:

- `scenesById[scene.id] = scene`

### 3. Choisir la scene initiale

- utiliser `immersive_tour.start_scene_id`
- fallback: premiere scene de `immersive_tour.scenes`

### 4. Afficher le panorama

Recommande pour MVP:

- Flutter + `WebView`
- viewer web 360 (Pannellum / Three.js)

Flutter envoie a la WebView:

- `panorama_url`
- `hotspots[]` de la scene courante

### 5. Clic sur hotspot

Si `action_type == "go_to_scene"`:

- lire `target_scene_id`
- retrouver la scene cible dans `scenesById`
- recharger le viewer avec le nouveau `panorama_url`
- afficher les hotspots de cette nouvelle scene

Important:

- idealement, rester sur le **meme ecran Flutter**
- seul le panorama change (experience fluide)

## Flow UX (resume)

1. Utilisateur ouvre un lieu
2. Clique "Visite 360"
3. Flutter charge `immersive_tour`
4. Flutter affiche `start_scene`
5. Utilisateur clique un hotspot
6. Flutter charge la scene cible (autre panorama)

## Exemple de logique (pseudo-code)

```dart
final tour = place['immersive_tour'];
if (tour == null) return;

final scenes = tour['scenes'] as List;
final scenesById = <int, Map<String, dynamic>>{
  for (final s in scenes) s['id'] as int: Map<String, dynamic>.from(s),
};

int currentSceneId = (tour['start_scene_id'] as int?) ?? (scenes.first['id'] as int);

void loadScene(int sceneId) {
  final scene = scenesById[sceneId];
  if (scene == null) return;
  currentSceneId = sceneId;

  webViewController.runJavaScript(
    'window.loadPanorama(${jsonEncode(scene)});',
  );
}

void onHotspotTap(Map<String, dynamic> hotspot) {
  if (hotspot['action_type'] == 'go_to_scene') {
    final targetId = hotspot['target_scene_id'] as int?;
    if (targetId != null) loadScene(targetId);
  }
}
```

## Types de hotspots (actuel)

- `go_to_scene`: navigation vers une autre scene
- `info`: afficher un message/overlay (via `payload`)

## Notes pratiques

- `yaw/pitch` sont fournis par le backend (places en admin)
- `initial_yaw` est actuellement gere cote admin en valeur par defaut (0)
- `highlight_hotspot_id` peut servir a pulser/mettre en avant un hotspot cote viewer

## Recommandation d'integration

Commencer par:

- un seul ecran Flutter "Visite360Screen"
- un viewer web embarque
- navigation scene->scene dans le meme ecran

Ensuite (plus tard):

- preload des scenes suivantes
- analytics des hotspots cliques
- mode hors-ligne/cache
