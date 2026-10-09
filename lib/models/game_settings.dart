import 'dart:convert';
import 'dart:ui' show Color;

/// Which side of the scoreboard a team is on. The "home" side owns the horn.
enum TeamSide { home, away }

/// A team's configurable identity: name and optional logo image path.
class Team {
  String name;
  String? logoPath; // local file path to a picked logo image, or null

  Team({required this.name, this.logoPath});

  Map<String, dynamic> toJson() => {'name': name, 'logoPath': logoPath};

  factory Team.fromJson(Map<String, dynamic> json) => Team(
    name: json['name'] as String? ?? 'TEAM',
    logoPath: json['logoPath'] as String?,
  );

  Team copy() => Team(name: name, logoPath: logoPath);
}

/// User-configurable colors for the scoreboard, chosen for TV contrast. Stored
/// as 32-bit ARGB ints.
class ScoreboardColors {
  int background; // whole-screen background
  int clockRunning; // clock text while running
  int clockStopped; // clock text while stopped
  int homeAccent; // home team color (score, borders, buttons)
  int awayAccent; // away team color

  ScoreboardColors({
    required this.background,
    required this.clockRunning,
    required this.clockStopped,
    required this.homeAccent,
    required this.awayAccent,
  });

  factory ScoreboardColors.defaults() => ScoreboardColors(
    background: 0xFF000000, // black — best TV contrast
    clockRunning: 0xFF69F0AE, // green accent
    clockStopped: 0xFFFFFFFF, // white
    homeAccent: 0xFFFFB74D, // orange
    awayAccent: 0xFF4FC3F7, // light blue
  );

  Color get backgroundColor => Color(background);
  Color get clockRunningColor => Color(clockRunning);
  Color get clockStoppedColor => Color(clockStopped);
  Color get homeAccentColor => Color(homeAccent);
  Color get awayAccentColor => Color(awayAccent);

  Map<String, dynamic> toJson() => {
    'background': background,
    'clockRunning': clockRunning,
    'clockStopped': clockStopped,
    'homeAccent': homeAccent,
    'awayAccent': awayAccent,
  };

  factory ScoreboardColors.fromJson(Map<String, dynamic> json) {
    final d = ScoreboardColors.defaults();
    return ScoreboardColors(
      background: (json['background'] as num?)?.toInt() ?? d.background,
      clockRunning: (json['clockRunning'] as num?)?.toInt() ?? d.clockRunning,
      clockStopped: (json['clockStopped'] as num?)?.toInt() ?? d.clockStopped,
      homeAccent: (json['homeAccent'] as num?)?.toInt() ?? d.homeAccent,
      awayAccent: (json['awayAccent'] as num?)?.toInt() ?? d.awayAccent,
    );
  }

  ScoreboardColors copy() => ScoreboardColors.fromJson(toJson());
}

/// Configurable game settings, persisted between sessions.
class GameSettings {
  Team home;
  Team away;

  int periodCount; // number of periods
  int periodMinutes; // length of each period in minutes

  /// Preset penalty durations in SECONDS, offered as quick buttons. Stored as
  /// seconds so durations like 1:30 (90s) are representable.
  List<int> penaltyPresetsSeconds;

  /// Maximum concurrent penalties shown per team (roster/box size).
  int maxPenaltiesPerTeam;

  /// Sound the horn automatically when a period's clock reaches zero.
  bool hornOnPeriodEnd;

  /// Multiplier applied to the central clock's font size (1.0 = default).
  double clockFontScale;

  /// Multiplier applied to the team score digits (1.0 = default).
  double scoreFontScale;

  /// Configurable colors for TV contrast.
  ScoreboardColors colors;

  /// Saved team library so teams (with logos) can be reused across games.
  List<Team> teamLibrary;

  GameSettings({
    required this.home,
    required this.away,
    this.periodCount = 2,
    this.periodMinutes = 20,
    List<int>? penaltyPresetsSeconds,
    this.maxPenaltiesPerTeam = 4,
    this.hornOnPeriodEnd = true,
    this.clockFontScale = 1.0,
    this.scoreFontScale = 1.0,
    ScoreboardColors? colors,
    List<Team>? teamLibrary,
  }) : penaltyPresetsSeconds =
           penaltyPresetsSeconds ?? const [90, 240, 600], // 1:30, 4:00, 10:00
       colors = colors ?? ScoreboardColors.defaults(),
       teamLibrary = teamLibrary ?? [];

  /// Sensible defaults for a fresh install. Pre-loads PINGÜINOS (with the
  /// bundled logo) as the home team and into the team library.
  factory GameSettings.defaults() {
    final penguins = Team(
      name: 'PINGÜINOS',
      logoPath: 'asset://assets/branding/icon.png',
    );
    return GameSettings(
      home: penguins.copy(),
      away: Team(name: 'AWAY'),
      teamLibrary: [penguins.copy()],
    );
  }

  Map<String, dynamic> toJson() => {
    'home': home.toJson(),
    'away': away.toJson(),
    'periodCount': periodCount,
    'periodMinutes': periodMinutes,
    'penaltyPresetsSeconds': penaltyPresetsSeconds,
    'maxPenaltiesPerTeam': maxPenaltiesPerTeam,
    'hornOnPeriodEnd': hornOnPeriodEnd,
    'clockFontScale': clockFontScale,
    'scoreFontScale': scoreFontScale,
    'colors': colors.toJson(),
    'teamLibrary': teamLibrary.map((t) => t.toJson()).toList(),
  };

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    final d = GameSettings.defaults();
    Team readTeam(String key, Team fallback) {
      final v = json[key];
      if (v is Map) {
        return Team.fromJson(v.cast<String, dynamic>());
      }
      return fallback;
    }

    return GameSettings(
      home: readTeam('home', d.home),
      away: readTeam('away', d.away),
      periodCount: (json['periodCount'] as num?)?.toInt() ?? d.periodCount,
      periodMinutes:
          (json['periodMinutes'] as num?)?.toInt() ?? d.periodMinutes,
      // Prefer the new seconds-based key; migrate from the old minutes-based
      // key if present (older saved settings).
      penaltyPresetsSeconds: _readPresets(json),
      maxPenaltiesPerTeam:
          (json['maxPenaltiesPerTeam'] as num?)?.toInt() ??
          d.maxPenaltiesPerTeam,
      hornOnPeriodEnd: json['hornOnPeriodEnd'] as bool? ?? d.hornOnPeriodEnd,
      clockFontScale:
          (json['clockFontScale'] as num?)?.toDouble() ?? d.clockFontScale,
      scoreFontScale:
          (json['scoreFontScale'] as num?)?.toDouble() ?? d.scoreFontScale,
      colors: json['colors'] is Map
          ? ScoreboardColors.fromJson(
              (json['colors'] as Map).cast<String, dynamic>(),
            )
          : d.colors,
      teamLibrary: (json['teamLibrary'] is List)
          ? (json['teamLibrary'] as List<dynamic>)
                .whereType<Map>()
                .map((e) => Team.fromJson(e.cast<String, dynamic>()))
                .toList()
          : d.teamLibrary,
    );
  }

  static List<int> _readPresets(Map<String, dynamic> json) {
    final secs = json['penaltyPresetsSeconds'] as List<dynamic>?;
    if (secs != null) {
      return secs.map((e) => (e as num).toInt()).toList();
    }
    final mins = json['penaltyPresetsMinutes'] as List<dynamic>?;
    if (mins != null) {
      return mins.map((e) => (e as num).toInt() * 60).toList();
    }
    return const [90, 240, 600];
  }

  String encode() => jsonEncode(toJson());

  static GameSettings decode(String s) =>
      GameSettings.fromJson(jsonDecode(s) as Map<String, dynamic>);

  GameSettings copy() => GameSettings.decode(encode());
}
