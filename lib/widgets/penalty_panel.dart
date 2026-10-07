import 'package:flutter/material.dart';
import '../models/game_settings.dart';
import '../models/penalty.dart';
import '../services/game_controller.dart';

/// One team's penalties: a header with Add/Clear and a list of countdown
/// timers. Shown below the clock, each team on its own side.
class PenaltyPanel extends StatelessWidget {
  final GameController controller;
  final TeamSide side;
  final Color accent;

  const PenaltyPanel({
    super.key,
    required this.controller,
    required this.side,
    required this.accent,
  });

  Team get _team =>
      side == TeamSide.home ? controller.settings.home : controller.settings.away;

  List<Penalty> get _penalties =>
      side == TeamSide.home ? controller.homePenalties : controller.awayPenalties;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context),
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
                    scrollDirection: Axis.horizontal,
                    itemCount: _penalties.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => _penaltyTile(_penalties[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            '${_team.name} — PENALTIES',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: accent,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: accent.withValues(alpha: 0.25),
                child: Text(
                  '#${p.playerNumber}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Clear this penalty',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => controller.clearPenalty(side, p),
              ),
            ],
          ),
          Text(
            p.display,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
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
                if (seconds <= 0) return;
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
