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

  /// Preset penalty durations (minutes) offered as quick buttons.
  List<int> penaltyPresetsMinutes;

  /// Maximum concurrent penalties shown per team (roster/box size).
  int maxPenaltiesPerTeam;

  /// Sound the horn automatically when a period's clock reaches zero.
  bool hornOnPeriodEnd;

  GameSettings({
    required this.home,
    required this.away,
    this.periodCount = 2,
    this.periodMinutes = 20,
    List<int>? penaltyPresetsMinutes,
    this.maxPenaltiesPerTeam = 4,
    this.hornOnPeriodEnd = true,
  }) : penaltyPresetsMinutes = penaltyPresetsMinutes ?? const [2, 3, 5];

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
    'penaltyPresetsMinutes': penaltyPresetsMinutes,
    'maxPenaltiesPerTeam': maxPenaltiesPerTeam,
    'hornOnPeriodEnd': hornOnPeriodEnd,
  };

  factory GameSettings.fromJson(Map<String, dynamic> json) => GameSettings(
    home: Team.fromJson((json['home'] as Map).cast<String, dynamic>()),
    away: Team.fromJson((json['away'] as Map).cast<String, dynamic>()),
    periodCount: (json['periodCount'] as num?)?.toInt() ?? 2,
    periodMinutes: (json['periodMinutes'] as num?)?.toInt() ?? 20,
    penaltyPresetsMinutes:
        ((json['penaltyPresetsMinutes'] as List<dynamic>?) ?? const [2, 3, 5])
            .map((e) => (e as num).toInt())
            .toList(),
    maxPenaltiesPerTeam: (json['maxPenaltiesPerTeam'] as num?)?.toInt() ?? 4,
    hornOnPeriodEnd: json['hornOnPeriodEnd'] as bool? ?? true,
  );

  String encode() => jsonEncode(toJson());

  static GameSettings decode(String s) =>
      GameSettings.fromJson(jsonDecode(s) as Map<String, dynamic>);

  GameSettings copy() => GameSettings.decode(encode());
}
