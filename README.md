# Scoreboard

An inline hockey scoreboard built with Flutter, for **Android** and
**Chromebook** (web). Landscape, large, clearly readable from across a rink.

## Features

- **Game clock** — large central countdown; tap it or the big START/STOP button
  to run/pause. Adjust by ±1s / ±1min when stopped. Configurable size.
- **Periods** — configurable count and length; step between periods.
- **Scores** — per-team score with +/- controls; configurable size. The home
  team's + sounds the horn.
- **Penalties** — add per player number with configurable preset durations
  (e.g. 1:30 / 4:00 / 10:00) or a custom m:ss time; they count down only while
  the clock runs, auto-clear at zero, and can be cleared individually or all at
  once. Shown below the clock, each team on its side.
- **Horn** — manual horn button; home-team goal sounds the horn, and it sounds
  automatically at period end (configurable).
- **Teams** — configurable names and logos, plus a reusable **team library**
  so you can save teams (with logos) and reload them for future games.
- **Colors** — every color (background, clock, each team) is configurable for
  best contrast on a TV.
- Keeps the screen awake during a game; locked to landscape.

## Keyboard shortcuts

Handy on a Chromebook/TV with a keyboard:

- **Space** — start/stop the clock
- **1** / **2** — home goals + / −
- **9** / **0** — away goals + / −

## Settings

Open the menu (⋮) → **Settings** to configure team names/logos (and the team
library), period count and length, penalty presets, max penalties per team,
the period-end horn, clock/score sizes, and all colors. Settings persist
between sessions. The menu also has **Reset clock** and **New game** (resets
scores, penalties, period and clock).

## Horn sound

The app ships a placeholder horn at `assets/sounds/horn.wav`. Replace that file
with your own horn sound (keep the same path/filename) to customise it.

## Run / build

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install).

```bash
flutter pub get
flutter run                 # on a connected Android device or Chrome
flutter build apk --release # Android
flutter build web --release # Chromebook / web
```

> Note: the Android release build currently signs with the debug key. Configure
> a proper release keystore before distributing.
