import 'dart:io';
import 'package:flutter/material.dart';
import '../models/game_settings.dart';
import '../services/game_controller.dart';

/// One team's score block: logo + name on top, then a large score flanked by
/// minus (−) and plus (+) buttons. The home team's plus also sounds the horn.
class TeamPanel extends StatelessWidget {
  final GameController controller;
  final TeamSide side;
  final Color accent;

  const TeamPanel({
    super.key,
    required this.controller,
    required this.side,
    required this.accent,
  });

  Team get _team =>
      side == TeamSide.home ? controller.settings.home : controller.settings.away;

  int get _score =>
      side == TeamSide.home ? controller.homeScore : controller.awayScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.4), width: 2),
      ),
      child: Column(
        children: [
          // --- Logo + name ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _logo(),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  _team.name,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // --- Score row: [−] [big score] [+] ---
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _sideButton(
                  icon: Icons.remove,
                  tooltip: 'Remove goal',
                  onTap: () => controller.removeGoal(side),
                ),
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Text(
                        '$_score',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: accent,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
                _sideButton(
                  icon: Icons.add,
                  tooltip: 'Add goal',
                  // Home plus sounds the horn, like the old GOAL button.
                  onTap: () => controller.addGoal(
                    side,
                    withHorn: side == TeamSide.home,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _logo() {
    final path = _team.logoPath;
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(path),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _logoPlaceholder(),
        ),
      );
    }
    return _logoPlaceholder();
  }

  Widget _logoPlaceholder() => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: accent.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(Icons.shield, color: accent),
  );

  /// A large circular +/- button sized to sit beside the score digits.
  Widget _sideButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: accent.withValues(alpha: 0.25),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Icon(icon, color: accent, size: 32),
          ),
        ),
      ),
    );
  }
}
