# FJ Game

Jeu de familles bibliques multijoueur. Les joueurs collectent des familles de 4 personnages bibliques en s'interrogeant mutuellement via des descripteurs tirés de versets bibliques.

## Prérequis

- Flutter SDK >= 3.22
- Dart >= 3.4

## Installation

```bash
flutter pub get
```

## ⚠️ Configuration Firebase (obligatoire avant de lancer)

Ce projet utilise Firebase (Project number : `562318926511`).

**Android** — Télécharger `google-services.json` depuis la [console Firebase](https://console.firebase.google.com) et le placer dans `android/app/`.

**iOS** — Télécharger `GoogleService-Info.plist` et le placer dans `ios/Runner/`.

Services Firebase activés : **Email/Password** + **Anonymous Auth**

## Génération du code Riverpod

À exécuter après chaque modification des providers annotés `@riverpod` :

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Lancement

```bash
flutter run
```

## Analyse statique

```bash
flutter analyze
```
