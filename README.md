# Todopen

A todo app for web and Android, with free cloud sync over your own Dropbox.

**[Open the web app](https://reosfire.github.io/Todo/)**

**Android** — download `app-release.apk` from the latest successful
[Build Android APK run](https://github.com/reosfire/Todo/actions/workflows/android.yml)
(the APK is attached to the run as an artifact), then open it on your phone.
You may need to allow installing apps from unknown sources.

## Features

- **Tasks** — create, edit, reorder, and complete tasks with drag-and-drop
- **Lists & Folders** — organize tasks into lists, group lists into collapsible folders
- **Tags** — label tasks with colored tags for quick filtering
- **Recurring Tasks** — daily, weekly, monthly, or yearly recurrence rules
- **Smart Lists** — auto-filtered views like *Today*, *Upcoming*, and *All Tasks*
- **Search** — across titles, notes, tags and list names
- **Dropbox Sync** — optional, offline-first, conflict-free across your devices
- **Dark Mode** — follows your system theme automatically

## Sync

Sync is optional: the app is fully usable without an account, and your data
stays on your device until you connect Dropbox.

When you do connect it, the app stores its data in your own Dropbox, in a
folder dedicated to the app. There is no server in between and no account to
create — your tasks go from your devices to your Dropbox and back.

Editing works the same whether you are online or not. Changes apply instantly
and upload in the background, so you can add tasks on a plane and have them
appear everywhere once you reconnect. If you edited the same task on two
devices while both were offline, both edits are kept rather than one
overwriting the other — for example, renaming a task on your phone while
ticking it off on your laptop leaves it renamed *and* completed.

Sync is designed to stay light on data: opening the app on a new device
downloads roughly 150 KB for a couple thousand tasks, and everyday edits like
ticking a checkbox cost a few hundred bytes.

## Privacy

Your tasks are stored locally on your device and, if you enable sync, in your
own Dropbox account. Nothing is sent anywhere else, and there is no analytics
or tracking.

## License

This project is provided as-is for personal use.
