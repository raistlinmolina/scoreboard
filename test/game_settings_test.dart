import 'package:flutter_test/flutter_test.dart';
import 'package:scoreboard/models/game_settings.dart';

void main() {
  group('GameSettings penalty presets (seconds)', () {
    test('defaults are 2:00, 3:00, 5:00 in seconds', () {
      final s = GameSettings.defaults();
      expect(s.penaltyPresetsSeconds, [120, 180, 300]);
    });

    test('JSON round-trip preserves second-based presets and clock scale', () {
      final s = GameSettings.defaults()
        ..penaltyPresetsSeconds = [90, 120, 300] // incl. 1:30
        ..clockFontScale = 1.8;
      final restored = GameSettings.decode(s.encode());
      expect(restored.penaltyPresetsSeconds, [90, 120, 300]);
      expect(restored.clockFontScale, 1.8);
    });

    test('migrates old minutes-based presets to seconds', () {
      // Simulate settings saved by an older build (minutes list).
      final restored = GameSettings.fromJson({
        'home': {'name': 'HOME'},
        'away': {'name': 'AWAY'},
        'penaltyPresetsMinutes': [2, 3, 5],
      });
      expect(restored.penaltyPresetsSeconds, [120, 180, 300]);
    });

    test('clockFontScale defaults to 1.0 when absent', () {
      final restored = GameSettings.fromJson({
        'home': {'name': 'HOME'},
        'away': {'name': 'AWAY'},
      });
      expect(restored.clockFontScale, 1.0);
    });
  });
}
