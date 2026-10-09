import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/game_settings.dart';
import '../models/penalty.dart';
import 'horn_service.dart';
import 'settings_store.dart';

/// Central game state and logic: the period clock, scores, penalties and the
/// horn. A [ChangeNotifier] so the UI rebuilds on every tick/change.
class GameController extends ChangeNotifier {
  final SettingsStore _store;
  final HornService _horn;

  GameController({SettingsStore? store, HornService? horn})
    : _store = store ?? SettingsStore(),
      _horn = horn ?? HornService();

  GameSettings _settings = GameSettings.defaults();
  GameSettings get settings => _settings;

  // --- Clock ---
  int _remainingSeconds = 0; // in the current period
  bool _running = false;
  int _period = 1;
  Timer? _ticker;

  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _running;
  int get period => _period;
  int get periodCount => _settings.periodCount;

  String get clockDisplay {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // --- Scores ---
  int _homeScore = 0;
  int _awayScore = 0;
  int get homeScore => _homeScore;
  int get awayScore => _awayScore;

  // --- Penalties ---
  final List<Penalty> _homePenalties = [];
  final List<Penalty> _awayPenalties = [];
  List<Penalty> get homePenalties => List.unmodifiable(_homePenalties);
  List<Penalty> get awayPenalties => List.unmodifiable(_awayPenalties);

  /// Loads persisted settings and resets the clock to a full period.
  Future<void> init() async {
    _settings = await _store.load();
    _resetClockToPeriod();
    notifyListeners();
  }

  void _resetClockToPeriod() {
    _remainingSeconds = _settings.periodMinutes * 60;
  }

  // ---------------- Clock control ----------------

  void startStop() => _running ? stop() : start();

  void start() {
    if (_running || _remainingSeconds <= 0) return;
    _running = true;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  void stop() {
    _running = false;
    _ticker?.cancel();
    _ticker = null;
    notifyListeners();
  }

  void _tick() {
    if (_remainingSeconds > 0) {
      _remainingSeconds--;
    }

    // Penalties only run while the game clock runs.
    _tickPenalties(_homePenalties);
    _tickPenalties(_awayPenalties);

    if (_remainingSeconds <= 0) {
      stop();
      if (_settings.hornOnPeriodEnd) {
        _horn.play();
      }
    }
    notifyListeners();
  }

  void _tickPenalties(List<Penalty> list) {
    for (final p in list) {
      p.tick();
    }
    list.removeWhere((p) => p.isExpired);
  }

  /// Reset the current period's clock back to full length (does not change
  /// scores or penalties).
  void resetClock() {
    stop();
    _resetClockToPeriod();
    notifyListeners();
  }

  /// Advance to the next period (if any), resetting the clock.
  void nextPeriod() {
    if (_period < _settings.periodCount) {
      _period++;
      resetClock();
    }
  }

  void previousPeriod() {
    if (_period > 1) {
      _period--;
      resetClock();
    }
  }

  /// Adjust the clock by [seconds] (positive or negative), clamped to the
  /// period length. Useful for quick corrections. Only when stopped.
  void adjustClock(int seconds) {
    if (_running) return;
    final max = _settings.periodMinutes * 60;
    _remainingSeconds = (_remainingSeconds + seconds).clamp(0, max);
    notifyListeners();
  }

  /// Set the clock directly to [seconds] (free edit). Clamped to >= 0. Only
  /// applies when stopped so you can't edit a running clock out from under it.
  void setClock(int seconds) {
    if (_running) return;
    _remainingSeconds = seconds < 0 ? 0 : seconds;
    notifyListeners();
  }

  // ---------------- Scores ----------------

  void addGoal(TeamSide side, {bool withHorn = false}) {
    if (side == TeamSide.home) {
      _homeScore++;
    } else {
      _awayScore++;
    }
    if (withHorn) _horn.play();
    notifyListeners();
  }

  void removeGoal(TeamSide side) {
    if (side == TeamSide.home) {
      if (_homeScore > 0) _homeScore--;
    } else {
      if (_awayScore > 0) _awayScore--;
    }
    notifyListeners();
  }

  // ---------------- Penalties ----------------

  List<Penalty> _listFor(TeamSide side) =>
      side == TeamSide.home ? _homePenalties : _awayPenalties;

  /// Adds a penalty for a team, given a duration in SECONDS. Ignored if the
  /// team is already at the max or the duration is non-positive.
  void addPenalty(TeamSide side, String playerNumber, int seconds) {
    final list = _listFor(side);
    if (list.length >= _settings.maxPenaltiesPerTeam) return;
    if (seconds <= 0) return;
    list.add(
      Penalty(
        playerNumber: playerNumber.trim().isEmpty ? '--' : playerNumber.trim(),
        totalSeconds: seconds,
      ),
    );
    notifyListeners();
  }

  /// Clears one specific penalty (e.g. released early).
  void clearPenalty(TeamSide side, Penalty penalty) {
    _listFor(side).remove(penalty);
    notifyListeners();
  }

  /// Clears all penalties for a team.
  void clearAllPenalties(TeamSide side) {
    _listFor(side).clear();
    notifyListeners();
  }

  // ---------------- Horn ----------------

  void soundHorn() => _horn.play();

  // ---------------- Full reset / settings ----------------

  /// Resets scores, penalties, period and clock for a brand-new game.
  void newGame() {
    stop();
    _homeScore = 0;
    _awayScore = 0;
    _homePenalties.clear();
    _awayPenalties.clear();
    _period = 1;
    _resetClockToPeriod();
    notifyListeners();
  }

  /// Applies and persists new settings. If the period length changed and the
  /// clock is at a fresh period, reset it to the new length.
  Future<void> applySettings(GameSettings newSettings) async {
    final clockWasFull = _remainingSeconds == _settings.periodMinutes * 60;
    _settings = newSettings;
    await _store.save(_settings);
    if (clockWasFull && !_running) {
      _resetClockToPeriod();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _horn.dispose();
    super.dispose();
  }
}
