# Scoreboard

An inline hockey scoreboard built with Flutter, for **Android** and
**Chromebook** (web). Landscape, large, clearly readable from across a rink.

## Features

- **Game clock** — large central countdown; tap it or the big START/STOP button
  to run/pause. Adjust by ±1s / ±1min when stopped.
- **Periods** — configurable count and length; step between periods.
- **Scores** — per-team goal +/- with a prominent GOAL button.
- **Penalties** — add per player number with configurable preset durations
  (e.g. 2/3/5 min); they count down only while the clock runs, auto-clear at
  zero, and can be cleared individually or all at once. Max concurrent
  penalties per team is configurable.
- **Horn** — manual horn button; the home-team GOAL button sounds the horn, and
  the horn sounds automatically at period end (configurable).
- **Teams** — configurable names and logos (pick an image from the device).
- Keeps the screen awake during a game; locked to landscape.

## Settings

Open the menu (⋮) → **Settings** to configure team names/logos, period count
and length, penalty presets, max penalties per team, and the period-end horn.
Settings persist between sessions. The menu also has **Reset clock** and
**New game** (resets scores, penalties, period and clock).

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
