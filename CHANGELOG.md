# Changelog

All notable changes to **Moli-ScoreBoard** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project aims to follow [Semantic Versioning](https://semver.org/).

Note on `pubspec.yaml` versions: the build version is `MAJOR.MINOR.PATCH+BUILD`
(e.g. `1.0.0+1`). Bump the `+BUILD` number for every APK you install over a
previous one.

## [Unreleased]

### Added
- **Edit time** button: freely set the clock from a dialog (accepts `m:ss` or a
  plain number of seconds). Available while the clock is stopped.

### Changed
- **Smaller Start/Stop button**, placed next to the new Edit button instead of
  spanning the full width.
- **Penalties are now readable on phones**: each team's penalties show in a
  vertical list sorted soonest-to-expire first (instead of a cramped horizontal
  strip), with the penalty area given more height so at least ~2 per team are
  visible and the rest scroll.
- **Penalty box decluttered**: removed the "TEAM — PENALTIES" title; Add and
  Clear are compact icon buttons stacked on the outer edge, freeing the full
  box for penalty rows.

### Removed
- The ±1s / ±1min clock-adjust chips (replaced by the Edit time dialog).

## [1.0.0]

First feature-complete build of the inline-hockey scoreboard (Android + web).

### Added
- **Game clock**: large central mm:ss countdown; tap it or the Start/Stop
  button to run/pause. Configurable size.
- **Periods**: configurable count and length; step between periods.
- **Scores**: per-team score with side +/- controls; configurable size. The
  home-team goal sounds the horn.
- **Penalties**: add per player number with configurable preset durations
  (default `1:30 / 4:00 / 10:00`) or a custom `m:ss`; they count down only while
  the clock runs, auto-clear at zero, and can be cleared individually or all at
  once. Configurable max concurrent penalties per team.
- **Horn**: manual horn button, home-goal horn, and automatic period-end horn
  (configurable).
- **Teams**: configurable names and logos, plus a reusable **team library** to
  save teams (with logos) and reload them for future games.
- **Keyboard shortcuts** (handy on a Chromebook/TV with a keyboard):
  `Space` = start/stop, `1` / `2` = home goal +/-, `9` / `0` = away goal +/-.
- **Configurable colors** (background, clock running/stopped, each team accent)
  for best contrast on a TV.
- **PINGÜINOS** preloaded as the default home team, using the bundled penguin
  logo (also added as the app launcher icon).
- Keeps the screen awake during a game; locked to landscape.
- Settings persist between sessions and survive in-app updates (new settings in
  future versions merge onto existing config instead of resetting it).

### Changed
- Picked team logos are copied into the app's permanent documents folder so a
  saved logo survives even if the OS clears the image picker's cache.
- App renamed to **Moli-ScoreBoard** (Android label, app title, web manifest).

### Packaging
- Play-publishable setup: release signing config, store assets, and docs.

[Unreleased]: https://github.com/raistlinmolina/scoreboard/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/raistlinmolina/scoreboard/releases/tag/v1.0.0
