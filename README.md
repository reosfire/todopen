A todo app written with flutter supporting web and mobile platforms. Supports free cloud sync via dropbox.

## Features

- **Tasks** — create, edit, reorder, and complete tasks with drag-and-drop support
- **Lists & Folders** — organize tasks into lists, group lists into collapsible folders
- **Tags** — label tasks with colored tags for quick filtering
- **Recurring Tasks** — set daily, weekly, monthly, or yearly recurrence rules
- **Smart Lists** — auto-filtered views like *Today*, *Upcoming*, and *All Tasks*
- **Dropbox Sync** — real-time two-way sync via Dropbox API with PKCE OAuth, longpoll-based change detection, and per-entity file storage
- **Dark Mode** — follows system theme automatically

## Getting Started

### Prerequisites

- Flutter SDK 3.9+
- A Dropbox app key (optional, for sync)

### Run locally

```bash
flutter pub get
flutter run -d web-server --web-port=8080
```

### Build android APK (optimized)

```bash
flutter build apk --release --shrink --obfuscate --split-debug-info=build/debug-info
```

## License

This project is provided as-is for personal use.
