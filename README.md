# Daily Planner Pro

A full-featured daily planner app built with **Flutter**, targeting **Android** and **Windows Desktop**.

Rebuilt from the React/Tailwind Gemini Canvas original — dark theme, German UI, all features preserved.

## Features

- **Aufgaben** mit Priorität (Niedrig/Mittel/Hoch), Projekt, Notizen und Unteraufgaben
- **Markdown-Notizen** als eigener Eintragstyp mit Vorschau
- **Projekte** mit Farbkodierung (Standard: Arbeit/Privat)
- **Tagesbasierte Ansicht** — Mini-Kalender zum Navigieren
- **Sortierung**: Manuell (Drag & Drop), nach Priorität, nach Projekt
- **Gruppierung** nach Projekt
- **Filter** nach Projekt
- **Detailansicht** — alle Felder bearbeiten, Unteraufgaben verwalten
- **Persistenz** via SharedPreferences (JSON)
- **Responsives Layout**: Drawer-Sidebar auf Android, persistente Sidebar auf Windows

## Setup

### Voraussetzungen

- Flutter SDK ≥ 3.22 — https://flutter.dev/docs/get-started/install
- Android: Android Studio + SDK
- Windows: Visual Studio 2022 mit "Desktop development with C++"

### Projekt initialisieren

```bash
# 1. Ins Projektverzeichnis wechseln
cd Todo-App-

# 2. Flutter-Plattformdateien generieren
flutter create --platforms=android,windows --project-name daily_planner_pro .

# 3. Abhängigkeiten installieren
flutter pub get

# 4. Code analysieren
flutter analyze
```

### Starten

```bash
# Android (verbundenes Gerät oder Emulator)
flutter run -d android

# Windows Desktop
flutter run -d windows

# Release Build
flutter build apk --release          # Android APK
flutter build windows --release      # Windows EXE
```

## Projektstruktur

```
lib/
├── main.dart                    # Entry point
├── app.dart                     # MaterialApp + Theme
├── utils/
│   ├── constants.dart           # Farben, Theme, Enums
│   └── date_utils.dart          # Datums-Hilfsfunktionen (Deutsch)
├── models/
│   ├── subtask.dart
│   ├── project.dart
│   └── planner_item.dart        # Unified Task/Note model
├── providers/
│   └── planner_provider.dart    # State + Persistenz
├── widgets/
│   ├── startup_modal.dart
│   ├── mini_calendar.dart
│   ├── sidebar.dart
│   ├── sort_menu.dart
│   ├── quick_entry_card.dart
│   ├── task_detail.dart
│   ├── task_item.dart
│   └── task_list.dart
└── screens/
    └── planner_screen.dart      # Responsives Layout
```
