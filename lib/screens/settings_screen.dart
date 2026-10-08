import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/game_settings.dart';
import '../services/game_controller.dart';
import '../widgets/team_logo.dart';

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

          const SizedBox(height: 24),
          _sectionTitle('Colors (TV contrast)'),
          _colorRow(
            'Background',
            _draft.colors.background,
            (v) => setState(() => _draft.colors.background = v),
          ),
          _colorRow(
            'Clock (running)',
            _draft.colors.clockRunning,
            (v) => setState(() => _draft.colors.clockRunning = v),
          ),
          _colorRow(
            'Clock (stopped)',
            _draft.colors.clockStopped,
            (v) => setState(() => _draft.colors.clockStopped = v),
          ),
          _colorRow(
            'Home team',
            _draft.colors.homeAccent,
            (v) => setState(() => _draft.colors.homeAccent = v),
          ),
          _colorRow(
            'Away team',
            _draft.colors.awayAccent,
            (v) => setState(() => _draft.colors.awayAccent = v),
          ),
        ],
      ),
    );
  }

  // High-contrast palette suited to TV displays.
  static const List<int> _palette = [
    0xFF000000, // black
    0xFFFFFFFF, // white
    0xFFF44336, // red
    0xFFFF9800, // orange
    0xFFFFB74D, // light orange
    0xFFFFEB3B, // yellow
    0xFF4CAF50, // green
    0xFF69F0AE, // green accent
    0xFF00BCD4, // cyan
    0xFF4FC3F7, // light blue
    0xFF2196F3, // blue
    0xFF9C27B0, // purple
    0xFFE91E63, // pink
    0xFF9E9E9E, // grey
  ];

  Widget _colorRow(String label, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 150, child: Text(label)),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _palette.map((c) {
                final selected = c == value;
                return GestureDetector(
                  onTap: () => onChanged(c),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.white : Colors.white24,
                        width: selected ? 3 : 1,
                      ),
                    ),
                    child: selected
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: _contrastOn(c),
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Pick black/white check mark for visibility on a given swatch.
  Color _contrastOn(int argb) {
    final c = Color(argb);
    final luminance = c.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
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
    final team = side == TeamSide.home ? _draft.home : _draft.away;
    final logoPath = team.logoPath;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => _pickLogo(side),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: (logoPath != null && logoPath.isNotEmpty)
                        ? TeamLogo(
                            path: logoPath,
                            accent: Colors.orangeAccent,
                            size: 64,
                            radius: 10,
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.add_a_photo),
                          ),
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
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _loadFromLibrary(side, nameController),
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: const Text('Load team'),
                ),
                TextButton.icon(
                  onPressed: () => _saveToLibrary(side, nameController),
                  icon: const Icon(Icons.bookmark_add, size: 18),
                  label: const Text('Save team'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Saves the current side's team (name + logo) into the reusable library.
  /// Replaces an existing library entry with the same name.
  void _saveToLibrary(TeamSide side, TextEditingController nameController) {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      _toast('Enter a team name before saving.');
      return;
    }
    final logo =
        side == TeamSide.home ? _draft.home.logoPath : _draft.away.logoPath;
    setState(() {
      _draft.teamLibrary.removeWhere(
        (t) => t.name.toLowerCase() == name.toLowerCase(),
      );
      _draft.teamLibrary.add(Team(name: name, logoPath: logo));
      _draft.teamLibrary.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    });
    _toast('Saved "$name" to the team library.');
  }

  /// Lets the user pick a saved team from the library into this side.
  Future<void> _loadFromLibrary(
    TeamSide side,
    TextEditingController nameController,
  ) async {
    if (_draft.teamLibrary.isEmpty) {
      _toast('No saved teams yet. Use "Save team" first.');
      return;
    }
    final chosen = await showDialog<Team>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Load team'),
        children: _draft.teamLibrary
            .map(
              (t) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, t),
                child: Row(
                  children: [
                    TeamLogo(path: t.logoPath, accent: Colors.orangeAccent, size: 32),
                    const SizedBox(width: 12),
                    Expanded(child: Text(t.name)),
                    IconButton(
                      tooltip: 'Delete from library',
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () {
                        setState(() => _draft.teamLibrary.remove(t));
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
    if (chosen == null) return;
    setState(() {
      if (side == TeamSide.home) {
        _draft.home = chosen.copy();
      } else {
        _draft.away = chosen.copy();
      }
      nameController.text = chosen.name;
    });
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
