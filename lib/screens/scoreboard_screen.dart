import 'package:flutter/material.dart';
import '../models/game_settings.dart';
import '../services/game_controller.dart';
import '../widgets/team_panel.dart';
import 'settings_screen.dart';

/// The main scoreboard: home panel | center clock & controls | away panel.
class ScoreboardScreen extends StatelessWidget {
  final GameController controller;

  const ScoreboardScreen({super.key, required this.controller});

  static const Color homeAccent = Color(0xFFFFB74D); // orange
  static const Color awayAccent = Color(0xFF4FC3F7); // light blue

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TeamPanel(
                      controller: controller,
                      side: TeamSide.home,
                      accent: homeAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(flex: 4, child: _centerColumn(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TeamPanel(
                      controller: controller,
                      side: TeamSide.away,
                      accent: awayAccent,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
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
        Expanded(
          child: Center(
            child: GestureDetector(
              onTap: controller.startStop,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Text(
                  controller.clockDisplay,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    color: controller.isRunning
                        ? Colors.greenAccent
                        : Colors.white,
                  ),
                ),
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
