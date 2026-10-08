import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_settings.dart';
import '../services/game_controller.dart';
import '../widgets/team_panel.dart';
import '../widgets/penalty_panel.dart';
import 'settings_screen.dart';

/// The main scoreboard. Top row: home score | center clock & controls | away
/// score. Bottom row: home penalties | away penalties (under the clock).
///
/// Keyboard shortcuts (useful with a Chromebook/TV + keyboard):
///   Space = start/stop clock
///   1 = +home goal   2 = -home goal
///   9 = +away goal   0 = -away goal
class ScoreboardScreen extends StatefulWidget {
  final GameController controller;

  const ScoreboardScreen({super.key, required this.controller});

  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  final FocusNode _focusNode = FocusNode();

  GameController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    // Grab keyboard focus so shortcuts work immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.space) {
      controller.startStop();
    } else if (key == LogicalKeyboardKey.digit1 ||
        key == LogicalKeyboardKey.numpad1) {
      controller.addGoal(TeamSide.home, withHorn: true);
    } else if (key == LogicalKeyboardKey.digit2 ||
        key == LogicalKeyboardKey.numpad2) {
      controller.removeGoal(TeamSide.home);
    } else if (key == LogicalKeyboardKey.digit9 ||
        key == LogicalKeyboardKey.numpad9) {
      controller.addGoal(TeamSide.away);
    } else if (key == LogicalKeyboardKey.digit0 ||
        key == LogicalKeyboardKey.numpad0) {
      controller.removeGoal(TeamSide.away);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final colors = controller.settings.colors;
        final homeAccent = colors.homeAccentColor;
        final awayAccent = colors.awayAccentColor;
        return Scaffold(
          backgroundColor: colors.backgroundColor,
          body: SafeArea(
            child: KeyboardListener(
              focusNode: _focusNode,
              autofocus: true,
              onKeyEvent: _handleKey,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    // --- TOP: scores + clock ---
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: TeamPanel(
                              controller: controller,
                              side: TeamSide.home,
                              accent: homeAccent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Center grows with the clock font scale, but capped
                          // so the score panels keep width to stay large.
                          Expanded(
                            flex: (4 * controller.settings.clockFontScale)
                                .round()
                                .clamp(4, 8),
                            child: _centerColumn(context),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 4,
                            child: TeamPanel(
                              controller: controller,
                              side: TeamSide.away,
                              accent: awayAccent,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // --- BOTTOM: penalties, each team on its side ---
                    Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          Expanded(
                            child: PenaltyPanel(
                              controller: controller,
                              side: TeamSide.home,
                              accent: homeAccent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: PenaltyPanel(
                              controller: controller,
                              side: TeamSide.away,
                              accent: awayAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _centerColumn(BuildContext context) {
    return Column(
      children: [
        // --- Top bar: period + settings/menu ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _periodControl(),
            Row(
              children: [
                IconButton(
                  tooltip: 'Horn',
                  iconSize: 30,
                  icon: const Icon(Icons.volume_up),
                  onPressed: controller.soundHorn,
                ),
                PopupMenuButton<String>(
                  tooltip: 'Menu',
                  onSelected: (v) => _onMenu(context, v),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'settings', child: Text('Settings')),
                    PopupMenuItem(value: 'reset_clock', child: Text('Reset clock')),
                    PopupMenuItem(value: 'new_game', child: Text('New game')),
                  ],
                ),
              ],
            ),
          ],
        ),

        // --- Big clock ---
        // The clock's font size is derived from the available area and then
        // multiplied by the user's clockFontScale, so the Settings slider has a
        // direct, visible effect. FittedBox(scaleDown) only shrinks if a very
        // large scale would overflow, so it never clips off-screen.
        Expanded(
          child: Center(
            child: GestureDetector(
              onTap: controller.startStop,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Base size at scale 1.0 is a fraction of the available
                  // height, leaving headroom so increasing the scale visibly
                  // enlarges the clock before FittedBox has to scale it down.
                  final base = constraints.maxHeight * 0.55;
                  final fontSize = (base * controller.settings.clockFontScale)
                      .clamp(24.0, 2000.0);
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        controller.clockDisplay,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          height: 1.0,
                          color: controller.isRunning
                              ? controller.settings.colors.clockRunningColor
                              : controller.settings.colors.clockStoppedColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // --- Clock adjust (when stopped) ---
        if (!controller.isRunning)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _adjustChip('-1:00', () => controller.adjustClock(-60)),
              _adjustChip('-0:01', () => controller.adjustClock(-1)),
              _adjustChip('+0:01', () => controller.adjustClock(1)),
              _adjustChip('+1:00', () => controller.adjustClock(60)),
            ],
          ),
        const SizedBox(height: 8),

        // --- Start/stop (big, easy) ---
        SizedBox(
          width: double.infinity,
          height: 72,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  controller.isRunning ? Colors.redAccent : Colors.green,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: controller.startStop,
            icon: Icon(
              controller.isRunning ? Icons.pause : Icons.play_arrow,
              size: 32,
            ),
            label: Text(controller.isRunning ? 'STOP' : 'START'),
          ),
        ),
      ],
    );
  }

  Widget _periodControl() {
    return Row(
      children: [
        IconButton(
          tooltip: 'Previous period',
          icon: const Icon(Icons.chevron_left),
          onPressed: controller.previousPeriod,
        ),
        Column(
          children: [
            const Text(
              'PERIOD',
              style: TextStyle(fontSize: 11, color: Colors.white54),
            ),
            Text(
              '${controller.period} / ${controller.periodCount}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        IconButton(
          tooltip: 'Next period',
          icon: const Icon(Icons.chevron_right),
          onPressed: controller.nextPeriod,
        ),
      ],
    );
  }

  Widget _adjustChip(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ActionChip(label: Text(label), onPressed: onTap),
    );
  }

  Future<void> _onMenu(BuildContext context, String value) async {
    switch (value) {
      case 'settings':
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SettingsScreen(controller: controller),
          ),
        );
        break;
      case 'reset_clock':
        controller.resetClock();
        break;
      case 'new_game':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Start a new game?'),
            content: const Text(
              'This resets scores, penalties, period and clock.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('New game'),
              ),
            ],
          ),
        );
        if (ok == true) controller.newGame();
        break;
    }
  }
}
