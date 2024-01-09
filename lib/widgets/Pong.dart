import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_todo_example/eSense/ESenseConnection.dart';

import '../game/game.dart';
import 'esense_dialog.dart';

class PongWidget extends StatefulWidget {
  final PongGame pongGame;
  final ESenseDialog eSenseDialog;

  const PongWidget(
      {Key? key, required this.pongGame, required this.eSenseDialog})
      : super(key: key);

  @override
  State<PongWidget> createState() => _PongWidgetState();
}

class _PongWidgetState extends State<PongWidget> {
  ESenseConnection? eSenseConnection;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter-Pong'),
      ),
      body: Align(
        alignment: Alignment.topLeft,
        child: Stack(
          children: [
            SizedBox(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: GameWidget(game: widget.pongGame)),
            Positioned(
              right: 5,
              child: TextButton.icon(
                onPressed: () {
                  _openEarableConnect(context);
                },
                icon: const Icon(Icons.bluetooth),
                label: const Text(
                  'ESense',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _openEarableConnect(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) => widget.eSenseDialog)
        .then((deviceName) => {
      // Start eSense connection based on the device name
      if (deviceName != null)
        {
          eSenseConnection?.dispose(),
          eSenseConnection = ESenseConnection(
              eSenseDeviceName: deviceName,
              tiltFunction: widget.pongGame.tilt),
        }
    });
  }
}
