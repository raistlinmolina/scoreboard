import 'package:flutter_test/flutter_test.dart';
import 'package:scoreboard/models/game_settings.dart';
import 'package:scoreboard/services/game_controller.dart';
import 'package:scoreboard/services/horn_service.dart';
import 'package:scoreboard/services/settings_store.dart';

/// A horn that records calls instead of playing audio (no platform needed).
class FakeHorn implements HornService {
  int plays = 0;
  @override
  Future<void> play() async => plays++;
  @override
  Future<void> dispose() async {}
}

/// In-memory settings store so tests avoid the SharedPreferences platform.
class FakeStore extends SettingsStore {
  GameSettings _settings = GameSettings.defaults();
  @override
  Future<GameSettings> load() async => _settings;
  @override
  Future<void> save(GameSettings settings) async => _settings = settings;
}

void main() {
  late GameController c;
  late FakeHorn horn;

  setUp(() async {
    horn = FakeHorn();
    c = GameController(store: FakeStore(), horn: horn);
    await c.init();
  });

  test('scores increment and decrement, never below zero', () {
    expect(c.homeScore, 0);
    c.addGoal(TeamSide.home);
    c.addGoal(TeamSide.home);
    expect(c.homeScore, 2);
    c.removeGoal(TeamSide.home);
    expect(c.homeScore, 1);
    c.removeGoal(TeamSide.home);
    c.removeGoal(TeamSide.home); // extra, should clamp
    expect(c.homeScore, 0);
  });

  test('home goal with horn plays the horn, away goal does not', () {
    c.addGoal(TeamSide.home, withHorn: true);
    expect(horn.plays, 1);
    c.addGoal(TeamSide.away, withHorn: false);
    expect(horn.plays, 1);
  });

  test('penalties respect max per team and can be cleared', () {
    final maxP = c.settings.maxPenaltiesPerTeam;
    for (var i = 0; i < maxP + 2; i++) {
      c.addPenalty(TeamSide.home, '$i', 2);
    }
    expect(c.homePenalties.length, maxP); // capped

    final first = c.homePenalties.first;
    c.clearPenalty(TeamSide.home, first);
    expect(c.homePenalties.length, maxP - 1);

    c.clearAllPenalties(TeamSide.home);
    expect(c.homePenalties, isEmpty);
  });

  test('resetClock restores full period length and stops', () {
    expect(c.remainingSeconds, c.settings.periodMinutes * 60);
    c.adjustClock(-120); // only works while stopped
    expect(c.remainingSeconds, c.settings.periodMinutes * 60 - 120);
    c.resetClock();
    expect(c.remainingSeconds, c.settings.periodMinutes * 60);
    expect(c.isRunning, false);
  });

  test('period navigation is bounded', () {
    expect(c.period, 1);
    c.previousPeriod(); // can't go below 1
    expect(c.period, 1);
    c.nextPeriod();
    expect(c.period, 2);
    c.nextPeriod(); // default periodCount = 2, can't exceed
    expect(c.period, 2);
  });

  test('newGame resets everything', () {
    c.addGoal(TeamSide.home);
    c.addGoal(TeamSide.away);
    c.addPenalty(TeamSide.home, '7', 2);
    c.nextPeriod();
    c.newGame();
    expect(c.homeScore, 0);
    expect(c.awayScore, 0);
    expect(c.homePenalties, isEmpty);
    expect(c.period, 1);
    expect(c.remainingSeconds, c.settings.periodMinutes * 60);
  });

  test('clock display formats mm:ss', () {
    expect(c.clockDisplay, '20:00');
    c.adjustClock(-1);
    expect(c.clockDisplay, '19:59');
  });
}
