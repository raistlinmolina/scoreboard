/// A single active penalty: the penalized player's number and the remaining
/// time. Penalties count down while the game clock runs.
class Penalty {
  final String playerNumber; // e.g. "17"
  int remainingSeconds;
  final int totalSeconds;

  Penalty({
    required this.playerNumber,
    required this.totalSeconds,
  }) : remainingSeconds = totalSeconds;

  bool get isExpired => remainingSeconds <= 0;

  /// Decrement by one second (floored at zero).
  void tick() {
    if (remainingSeconds > 0) remainingSeconds--;
  }

  String get display {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
