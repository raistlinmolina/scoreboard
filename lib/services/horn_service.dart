import 'package:audioplayers/audioplayers.dart';

/// Plays the horn sound. Uses a bundled asset by default.
class HornService {
  final AudioPlayer _player = AudioPlayer();

  /// Plays the horn. Safe to call repeatedly; restarts if already playing.
  Future<void> play() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/horn.wav'));
    } catch (_) {
      // Audio can fail on some platforms/emulators; ignore so the UI still
      // works without sound.
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
