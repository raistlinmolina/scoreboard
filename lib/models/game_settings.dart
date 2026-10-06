import 'dart:convert';

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

  GameSettings({
    required this.home,
    required this.away,
    this.periodCount = 2,
    this.periodMinutes = 20,
    List<int>? penaltyPresetsSeconds,
    this.maxPenaltiesPerTeam = 4,
    this.hornOnPeriodEnd = true,
    this.clockFontScale = 1.0,
  }) : penaltyPresetsSeconds =
           penaltyPresetsSeconds ?? const [120, 180, 300]; // 2:00, 3:00, 5:00

  /// Sensible defaults for a fresh install.
  factory GameSettings.defaults() => GameSettings(
    home: Team(name: 'HOME'),
    away: Team(name: 'AWAY'),
  );

  Map<String, dynamic> toJson() => {
    'home': home.toJson(),
    'away': away.toJson(),
    'periodCount': periodCount,
    'periodMinutes': periodMinutes,
    'penaltyPresetsSeconds': penaltyPresetsSeconds,
    'maxPenaltiesPerTeam': maxPenaltiesPerTeam,
    'hornOnPeriodEnd': hornOnPeriodEnd,
    'clockFontScale': clockFontScale,
  };

  factory GameSettings.fromJson(Map<String, dynamic> json) => GameSettings(
    home: Team.fromJson((json['home'] as Map).cast<String, dynamic>()),
    away: Team.fromJson((json['away'] as Map).cast<String, dynamic>()),
    periodCount: (json['periodCount'] as num?)?.toInt() ?? 2,
    periodMinutes: (json['periodMinutes'] as num?)?.toInt() ?? 20,
    // Prefer the new seconds-based key; migrate from the old minutes-based key
    // if present (older saved settings).
    penaltyPresetsSeconds: _readPresets(json),
    maxPenaltiesPerTeam: (json['maxPenaltiesPerTeam'] as num?)?.toInt() ?? 4,
    hornOnPeriodEnd: json['hornOnPeriodEnd'] as bool? ?? true,
    clockFontScale: (json['clockFontScale'] as num?)?.toDouble() ?? 1.0,
  );

  static List<int> _readPresets(Map<String, dynamic> json) {
    final secs = json['penaltyPresetsSeconds'] as List<dynamic>?;
    if (secs != null) {
      return secs.map((e) => (e as num).toInt()).toList();
    }
    final mins = json['penaltyPresetsMinutes'] as List<dynamic>?;
    if (mins != null) {
      return mins.map((e) => (e as num).toInt() * 60).toList();
    }
    return const [120, 180, 300];
  }

  String encode() => jsonEncode(toJson());

  static GameSettings decode(String s) =>
      GameSettings.fromJson(jsonDecode(s) as Map<String, dynamic>);

  GameSettings copy() => GameSettings.decode(encode());
}
