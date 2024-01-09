import 'package:flutter/material.dart';

import 'game/game.dart';
import 'widgets/Pong.dart';
import 'widgets/esense_dialog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(PongApp());
}

class PongApp extends StatelessWidget {
  final PongGame pongGame = PongGame();

  PongApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: PongWidget(pongGame: pongGame, eSenseDialog: ESenseDialog()));
  }
}
