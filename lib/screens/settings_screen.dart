import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/game_settings.dart';
import '../services/game_controller.dart';

/// Edit team names/logos and game configuration (periods, penalties, horn).
class SettingsScreen extends StatefulWidget {
  final GameController controller;

  const SettingsScreen({super.key, required this.controller});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late GameSettings _draft;
  final _picker = ImagePicker();

  late TextEditingController _homeName;
  late TextEditingController _awayName;
  late TextEditingController _presets;

  @override
  void initState() {
    super.initState();
    _draft = widget.controller.settings.copy();
    _homeName = TextEditingController(text: _draft.home.name);
    _awayName = TextEditingController(text: _draft.away.name);
    _presets = TextEditingController(
      text: _draft.penaltyPresetsSeconds.map(_fmtSeconds).join(', '),
    );
  }

  @override
  void dispose() {
    _homeName.dispose();
    _awayName.dispose();
    _presets.dispose();
    super.dispose();
  }

  Future<void> _pickLogo(TeamSide side) async {
    try {
      final x = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (x == null) return;
      setState(() {
        if (side == TeamSide.home) {
          _draft.home.logoPath = x.path;
        } else {
          _draft.away.logoPath = x.path;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not pick image: $e')));
    }
  }

  String _fmtSeconds(int s) =>
      '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  /// Parses a comma/space separated list of durations into seconds. Each entry
  /// may be "m:ss" (e.g. "1:30") or a plain number of seconds.
  List<int> _parsePresets(String text) {
    final parts = text
        .split(RegExp(r'[,\s]+'))
        .where((s) => s.trim().isNotEmpty);
    final out = <int>[];
    for (final p in parts) {
      final t = p.trim();
      int? secs;
      if (t.contains(':')) {
        final seg = t.split(':');
        if (seg.length == 2) {
          final m = int.tryParse(seg[0].trim());
          final s = int.tryParse(seg[1].trim());
          if (m != null && s != null && s >= 0 && s <= 59 && m >= 0) {
            secs = m * 60 + s;
          }
        }
      } else {
        secs = int.tryParse(t);
      }
      if (secs != null && secs > 0 && secs <= 3600) out.add(secs);
    }
    return out.isEmpty ? const [90, 240, 600] : out;
  }

  Future<void> _save() async {
    _draft.home.name =
        _homeName.text.trim().isEmpty ? 'HOME' : _homeName.text.trim();
    _draft.away.name =
        _awayName.text.trim().isEmpty ? 'AWAY' : _awayName.text.trim();
    _draft.penaltyPresetsSeconds = _parsePresets(_presets.text);
    await widget.controller.applySettings(_draft);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Teams'),
          _teamEditor(TeamSide.home, 'Home team', _homeName),
          const SizedBox(height: 12),
          _teamEditor(TeamSide.away, 'Away team', _awayName),

          const SizedBox(height: 24),
          _sectionTitle('Clock'),
          _stepperRow(
            label: 'Periods',
            value: _draft.periodCount,
            min: 1,
            max: 9,
            onChanged: (v) => setState(() => _draft.periodCount = v),
          ),
          _stepperRow(
            label: 'Minutes per period',
            value: _draft.periodMinutes,
            min: 1,
            max: 60,
            onChanged: (v) => setState(() => _draft.periodMinutes = v),
          ),
          const SizedBox(height: 8),
          Text(
            'Clock size',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
          Row(
            children: [
              const Icon(Icons.text_fields, size: 18),
              Expanded(
                child: Slider(
                  value: _draft.clockFontScale.clamp(0.5, 3.0),
                  min: 0.5,
                  max: 3.0,
                  divisions: 25,
                  label: '${(_draft.clockFontScale * 100).round()}%',
                  onChanged: (v) =>
                      setState(() => _draft.clockFontScale = v),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '${(_draft.clockFontScale * 100).round()}%',
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Score size',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
          Row(
            children: [
              const Icon(Icons.tag, size: 18),
              Expanded(
                child: Slider(
                  value: _draft.scoreFontScale.clamp(0.5, 3.0),
                  min: 0.5,
                  max: 3.0,
                  divisions: 25,
                  label: '${(_draft.scoreFontScale * 100).round()}%',
                  onChanged: (v) =>
                      setState(() => _draft.scoreFontScale = v),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '${(_draft.scoreFontScale * 100).round()}%',
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          _sectionTitle('Penalties'),
          TextField(
            controller: _presets,
            decoration: const InputDecoration(
              labelText: 'Penalty presets (m:ss, comma-separated)',
              hintText: '2:00, 3:00, 5:00',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          _stepperRow(
            label: 'Max penalties shown per team',
            value: _draft.maxPenaltiesPerTeam,
            min: 1,
            max: 10,
            onChanged: (v) => setState(() => _draft.maxPenaltiesPerTeam = v),
          ),

          const SizedBox(height: 24),
          _sectionTitle('Horn'),
          SwitchListTile(
            title: const Text('Sound horn at period end'),
            value: _draft.hornOnPeriodEnd,
            onChanged: (v) => setState(() => _draft.hornOnPeriodEnd = v),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      t.toUpperCase(),
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: Colors.orangeAccent,
      ),
    ),
  );

  Widget _teamEditor(
    TeamSide side,
    String label,
    TextEditingController nameController,
  ) {
    final logoPath =
        side == TeamSide.home ? _draft.home.logoPath : _draft.away.logoPath;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _pickLogo(side),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: (logoPath != null &&
                        logoPath.isNotEmpty &&
                        File(logoPath).existsSync())
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(File(logoPath), fit: BoxFit.cover),
                      )
                    : const Icon(Icons.add_a_photo),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: label,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            if (logoPath != null && logoPath.isNotEmpty)
              IconButton(
                tooltip: 'Remove logo',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(() {
                  if (side == TeamSide.home) {
                    _draft.home.logoPath = null;
                  } else {
                    _draft.away.logoPath = null;
                  }
                }),
              ),
          ],
        ),
      ),
    );
  }

  Widget _stepperRow({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 36,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}
