import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_settings.dart';

/// Persists [GameSettings] (team names/logos, colors, period/penalty config,
/// team library) across launches AND app updates.
///
/// Durability notes:
///  - SharedPreferences data is retained across normal in-place app updates
///    (same applicationId + same signing key). An update does NOT reconfigure.
///  - [GameSettings.fromJson] merges field-by-field onto defaults, so adding
///    new settings in a future version never discards existing saved values —
///    old blobs load fine and gain the new fields at their defaults.
///  - We keep a backup copy of the last successfully-saved JSON. If the primary
///    value ever fails to parse (e.g. partial write), we fall back to the
///    backup before giving up and using defaults.
///
/// Methods are overridable so tests can substitute an in-memory store.
class SettingsStore {
  static const String _key = 'game_settings';
  static const String _backupKey = 'game_settings_backup';

  Future<GameSettings> load() async {
    final prefs = await SharedPreferences.getInstance();

    final primary = prefs.getString(_key);
    final fromPrimary = _tryDecode(primary);
    if (fromPrimary != null) return fromPrimary;

    // Primary missing/corrupt — try the backup.
    final backup = prefs.getString(_backupKey);
    final fromBackup = _tryDecode(backup);
    if (fromBackup != null) {
      // Repair the primary from the good backup.
      await prefs.setString(_key, backup!);
      return fromBackup;
    }

    return GameSettings.defaults();
  }

  GameSettings? _tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return GameSettings.decode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(GameSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = settings.encode();
    // Keep the previous good value as a backup before overwriting the primary.
    final previous = prefs.getString(_key);
    if (previous != null && previous.isNotEmpty) {
      await prefs.setString(_backupKey, previous);
    }
    await prefs.setString(_key, encoded);
  }
}
