import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scoreboard/models/game_settings.dart';
import 'package:scoreboard/services/game_controller.dart';
import 'package:scoreboard/services/horn_service.dart';
import 'package:scoreboard/services/settings_store.dart';
import 'package:scoreboard/screens/scoreboard_screen.dart';

class _FakeHorn implements HornService {
  @override
  Future<void> play() async {}
  @override
  Future<void> dispose() async {}
}

class _FakeStore extends SettingsStore {
  @override
  Future<GameSettings> load() async => GameSettings.defaults();
  @override
  Future<void> save(GameSettings settings) async {}
}

void main() {
  testWidgets('Scoreboard shows clock, scores and START', (tester) async {
    // Scoreboard is designed for a wide landscape surface.
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = GameController(store: _FakeStore(), horn: _FakeHorn());
    await controller.init();

    await tester.pumpWidget(
      MaterialApp(home: ScoreboardScreen(controller: controller)),
    );
    await tester.pump();

    // Default settings: 20-minute period => clock shows 20:00.
    expect(find.text('20:00'), findsOneWidget);
    // Two starting scores of 0 (home and away).
    expect(find.text('0'), findsNWidgets(2));
    // Start button present.
    expect(find.text('START'), findsOneWidget);
    // Period indicator.
    expect(find.text('1 / 2'), findsOneWidget);
  });
}
