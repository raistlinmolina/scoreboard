import 'dart:io';
import 'package:flutter/material.dart';

/// Renders a team logo from either a bundled asset (path starting with
/// "asset://") or a local file path. Falls back to a shield placeholder.
class TeamLogo extends StatelessWidget {
  final String? path;
  final double size;
  final Color accent;
  final double radius;

  const TeamLogo({
    super.key,
    required this.path,
    required this.accent,
    this.size = 48,
    this.radius = 8,
  });

  static const String assetPrefix = 'asset://';

  @override
  Widget build(BuildContext context) {
    final p = path;
    if (p != null && p.isNotEmpty) {
      if (p.startsWith(assetPrefix)) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.asset(
            p.substring(assetPrefix.length),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _placeholder(),
          ),
        );
      }
      if (File(p).existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.file(
            File(p),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _placeholder(),
          ),
        );
      }
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: accent.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(radius),
    ),
    child: Icon(Icons.shield, color: accent),
  );
}
