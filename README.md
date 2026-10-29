# 🌍 Explorez votre ville

Application mobile **cross-platform** (Android, iOS, Web, Desktop) développée en **Flutter** pour explorer, enregistrer et commenter des lieux ville par ville, avec météo en temps réel, géolocalisation et carte interactive.

## ✨ Fonctionnalités

- 🔎 **Recherche de ville** et exploration des lieux associés
- ⭐ **Villes favorites** et gestion de ses lieux (ajout, modification)
- 💬 **Commentaires et notation** des lieux
- 🌦️ **Météo en temps réel** de la ville (API externe)
- 📍 **Géolocalisation GPS** et **carte interactive**
- 🌙 **Mode sombre / clair** persistant
- ✨ Interface animée (transitions, Lottie)

## 📸 Aperçu

Les captures d'écran de l'application sont dans le dossier [`captures_App/`](captures_App/).

## 🏗️ Architecture

Le code est organisé en modules clairs (`lib/`) :

| Dossier | Rôle |
|---|---|
| `db/` | Base de données **SQLite** (DBHelper) : villes, lieux, commentaires |
| `models/` | Classes de données : `Lieu`, `Ville`, `Commentaire`, `Weather` |
| `providers/` | Gestion d'état centralisée (**Provider**) |
| `screens/` | Écrans principaux de l'application |
| `utils/` | Services externes : API lieux, géocodage, météo, géolocalisation |
| `widgets/` | Composants réutilisables (cartes, formulaires, barres) |

**Gestion d'état (Provider) :**
- `LieuProvider` — cœur du système : ville courante, liste filtrée/triée des lieux, recherche, synchronisation DB ↔ APIs
- `CommentProvider` — chargement et ajout des commentaires
- `LocationProvider` — position GPS de l'utilisateur
- `ThemeProvider` — mode sombre/clair persistant (SharedPreferences)

**Base de données (SQLite / sqflite) :**
- Tables : `villes`, `lieux`, `commentaires`
- Relations avec intégrité référentielle : `lieux.ville_id → villes`, `commentaires.lieu_id → lieux`
- Persistance locale des préférences via **SharedPreferences** (ville actuelle, favoris, coordonnées GPS)

## 🧰 Stack technique

- **Flutter / Dart** (cross-platform)
- **Provider** — gestion d'état
- **sqflite** — base de données SQLite locale (+ `sqflite_common_ffi` pour web/desktop)
- **http** — appels aux API REST
- **geolocator** — géolocalisation GPS
- **flutter_map** + **latlong2** — carte interactive
- **shared_preferences** — persistance des préférences
- **lottie**, **animated_text_kit**, **flutter_staggered_animations** — animations

## ⚙️ Configuration des clés d'API

Ce projet utilise des API externes (Google Places, OpenWeatherMap). Pour le lancer :

1. Copiez `lib/secrets.example.dart` en `lib/secrets.dart`
2. Renseignez vos propres clés dans `lib/secrets.dart`

> `lib/secrets.dart` est ignoré par Git : vos clés restent privées.

## 🚀 Lancer le projet

```bash
flutter pub get
flutter run
```
