import 'dart:io';
import 'package:flutter/material.dart';
import '../models/game_settings.dart';
import '../models/penalty.dart';
import '../services/game_controller.dart';

/// One team's half of the scoreboard: logo, name, big score, goal controls,
/// and the list of active penalties with controls.
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

  List<Penalty> get _penalties =>
      side == TeamSide.home ? controller.homePenalties : controller.awayPenalties;

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
          const SizedBox(height: 4),

          // --- Big score ---
          Expanded(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Text(
                '$_score',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: accent,
                  fontFeatures: const [],
                ),
              ),
            ),
          ),

          // --- Goal controls ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _roundButton(
                icon: Icons.remove,
                tooltip: 'Remove goal',
                onTap: () => controller.removeGoal(side),
                filled: false,
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.black,
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => controller.addGoal(
                    side,
                    withHorn: side == TeamSide.home,
                  ),
                  icon: const Icon(Icons.sports_hockey),
                  label: const Text('GOAL'),
                ),
              ),
              const SizedBox(width: 12),
              _roundButton(
                icon: Icons.add,
                tooltip: 'Add goal (no horn)',
                onTap: () => controller.addGoal(side),
                filled: false,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // --- Penalties ---
          _penaltyHeader(context),
          const SizedBox(height: 4),
          Expanded(
            child: _penalties.isEmpty
                ? const Center(
                    child: Text(
                      'No penalties',
                      style: TextStyle(color: Colors.white38),
                    ),
                  )
                : ListView.separated(
                    itemCount: _penalties.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, i) =>
                        _penaltyTile(_penalties[i]),
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

  Widget _penaltyHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'PENALTIES',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white70,
          ),
        ),
        Row(
          children: [
            TextButton.icon(
              onPressed: () => _showAddPenalty(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
            if (_penalties.isNotEmpty)
              TextButton.icon(
                onPressed: () => controller.clearAllPenalties(side),
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Clear'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _penaltyTile(Penalty p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: accent.withValues(alpha: 0.25),
            child: Text(
              '#${p.playerNumber}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              p.display,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
          IconButton(
            tooltip: 'Clear this penalty',
            icon: const Icon(Icons.close),
            onPressed: () => controller.clearPenalty(side, p),
          ),
        ],
      ),
    );
  }

  Widget _roundButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool filled = true,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? accent : Colors.white10,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: filled ? Colors.black : Colors.white),
          ),
        ),
      ),
    );
  }

  /// Parses a duration string into seconds. Accepts "m:ss" (e.g. "1:30"),
  /// "mm:ss", or a plain integer number of seconds (e.g. "90"). Returns null
  /// if the input is empty or invalid.
  int? _parseDuration(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    if (text.contains(':')) {
      final parts = text.split(':');
      if (parts.length != 2) return null;
      final m = int.tryParse(parts[0].trim());
      final s = int.tryParse(parts[1].trim());
      if (m == null || s == null || s < 0 || s > 59 || m < 0) return null;
      final total = m * 60 + s;
      return total > 0 ? total : null;
    }
    final secs = int.tryParse(text);
    if (secs == null || secs <= 0) return null;
    return secs;
  }

  Future<void> _showAddPenalty(BuildContext context) async {
    final presets = controller.settings.penaltyPresetsSeconds;
    final numberController = TextEditingController();
    final customController = TextEditingController();
    // Selected preset in seconds; -1 means "use the custom field".
    int selectedSeconds = presets.isNotEmpty ? presets.first : 120;

    String fmt(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Add penalty — ${_team.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: numberController,
                keyboardType: TextInputType.number,
                maxLength: 3,
                decoration: const InputDecoration(
                  labelText: 'Player number',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Duration',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: presets
                    .map(
                      (s) => ChoiceChip(
                        label: Text(fmt(s)),
                        selected: selectedSeconds == s,
                        onSelected: (_) => setState(() {
                          selectedSeconds = s;
                          customController.clear();
                        }),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: customController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'Custom (m:ss or seconds)',
                  hintText: 'e.g. 1:30',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  // Any custom entry overrides the chosen preset.
                  if (v.trim().isNotEmpty) {
                    setState(() => selectedSeconds = -1);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final custom = _parseDuration(customController.text);
                final seconds = custom ?? selectedSeconds;
                if (seconds <= 0) return; // nothing valid chosen
                controller.addPenalty(side, numberController.text, seconds);
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
