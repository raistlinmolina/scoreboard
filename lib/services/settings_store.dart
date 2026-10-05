import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_settings.dart';

/// Persists [GameSettings] (team names/logos, period and penalty config).
///
/// Methods are overridable so tests can substitute an in-memory store without
/// the SharedPreferences platform channel.
class SettingsStore {
  static const String _key = 'game_settings';

  Future<GameSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return GameSettings.defaults();
    try {
      return GameSettings.decode(raw);
    } catch (_) {
      return GameSettings.defaults();
    }
  }

  Future<void> save(GameSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, settings.encode());
  }
}
