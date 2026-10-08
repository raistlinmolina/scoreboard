import 'package:flutter_test/flutter_test.dart';
import 'package:scoreboard/models/game_settings.dart';

void main() {
  group('GameSettings penalty presets (seconds)', () {
    test('defaults are 1:30, 4:00, 10:00 in seconds', () {
      final s = GameSettings.defaults();
      expect(s.penaltyPresetsSeconds, [90, 240, 600]);
    });

    test('JSON round-trip preserves second-based presets and clock scale', () {
      final s = GameSettings.defaults()
        ..penaltyPresetsSeconds = [90, 120, 300] // incl. 1:30
        ..clockFontScale = 1.8
        ..scoreFontScale = 2.2;
      final restored = GameSettings.decode(s.encode());
      expect(restored.penaltyPresetsSeconds, [90, 120, 300]);
      expect(restored.clockFontScale, 1.8);
      expect(restored.scoreFontScale, 2.2);
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
      expect(restored.scoreFontScale, 1.0);
    });

    test('colors round-trip and default sensibly', () {
      final s = GameSettings.defaults();
      // Defaults: black background, orange home, light-blue away.
      expect(s.colors.background, 0xFF000000);
      s.colors.homeAccent = 0xFFFF0000;
      final restored = GameSettings.decode(s.encode());
      expect(restored.colors.homeAccent, 0xFFFF0000);
      expect(restored.colors.background, 0xFF000000);
    });

    test('team library round-trips and defaults include PINGÜINOS', () {
      final s = GameSettings.defaults();
      expect(s.home.name, 'PINGÜINOS');
      expect(s.teamLibrary.any((t) => t.name == 'PINGÜINOS'), isTrue);

      s.teamLibrary.add(Team(name: 'TIGERS', logoPath: '/tmp/t.png'));
      final restored = GameSettings.decode(s.encode());
      expect(restored.teamLibrary.map((t) => t.name), contains('TIGERS'));
      expect(
        restored.teamLibrary.firstWhere((t) => t.name == 'TIGERS').logoPath,
        '/tmp/t.png',
      );
    });
  });
}
