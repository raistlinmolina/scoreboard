import 'package:flutter/material.dart';
import '../models/game_settings.dart';
import '../services/game_controller.dart';
import 'team_logo.dart';

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
              TeamLogo(path: _team.logoPath, accent: accent, size: 48),
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

          // --- Score with corner +/- buttons ---
          // The digits fill the whole area (so they're as large as the clock),
          // with the −/+ controls floating in the bottom corners so they don't
          // shrink the number.
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Explicit size from available height × user scale, so
                          // the score grows regardless of panel width. scaleDown
                          // only shrinks if it would overflow horizontally.
                          final base = constraints.maxHeight * 0.9;
                          final fontSize =
                              (base * controller.settings.scoreFontScale)
                                  .clamp(24.0, 2000.0);
                          return FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '$_score',
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w900,
                                color: accent,
                                height: 1.0,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: _sideButton(
                    icon: Icons.remove,
                    tooltip: 'Remove goal',
                    onTap: () => controller.removeGoal(side),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: _sideButton(
                    icon: Icons.add,
                    tooltip: 'Add goal',
                    // Home plus sounds the horn, like the old GOAL button.
                    onTap: () => controller.addGoal(
                      side,
                      withHorn: side == TeamSide.home,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
