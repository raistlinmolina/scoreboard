import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'services/game_controller.dart';
import 'screens/scoreboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Scoreboards live in landscape and should never dim mid-game.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  WakelockPlus.enable();

  final controller = GameController();
  await controller.init();

  runApp(ScoreboardApp(controller: controller));
}

class ScoreboardApp extends StatelessWidget {
  final GameController controller;

  const ScoreboardApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moli-ScoreBoard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: ScoreboardScreen(controller: controller),
    );
  }
}
