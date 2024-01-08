import 'dart:async';
import 'dart:math';

import 'package:flame/events.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../components/ball.dart';
import '../components/mystery_box.dart';
import '../components/paddle.dart';

class PongGame extends FlameGame<PongWorld>
    with HasCollisionDetection, HorizontalDragDetector {
  PongGame() : super(world: PongWorld());

  /// Tilt the player paddle by [i] pixels
  void tilt(double i) {
    world.tilt(i);
  }

  @override
  void handleHorizontalDragUpdate(DragUpdateDetails details) {
    super.handleHorizontalDragUpdate(details);

    tilt(details.delta.dx);
  }
}

class PongWorld extends World with HasGameRef<PongGame> {
  final double _paddleOffset = 75;
  int _playerScore = 0;
  int _enemyScore = 0;
  final Ball _ball = Ball(-1);
  late Paddle playerPaddle;
  late Paddle enemyPaddle;
  late TextComponent _scoreText;
  late TimerComponent mysteryBoxTimer;

  @override
  FutureOr<void> onLoad() {
    var size = gameRef.size;

    // Init game objects
    playerPaddle = Paddle(0, size.y / 2 - _paddleOffset);
    enemyPaddle = AiPaddle(0, -size.y / 2 + _paddleOffset, -1);
    _scoreText = TextComponent()
      ..text = '$_enemyScore\n$_playerScore'
      ..position = Vector2(-size.x / 2 + 10, 2.5)
      ..anchor = Anchor.centerLeft;
    var middleLine = RectangleComponent(
      size: Vector2(size.x, 2.5),
      position: Vector2(-size.x / 2, 0),
    );
    mysteryBoxTimer = TimerComponent(
        period: 4,
        removeOnFinish: false,
        repeat: true,
        onTick: () {
          if (Random().nextDouble() < 0.25) {
            addMysteryBox();
          }
        });

    addAll([
      ScreenHitbox(),
      _ball,
      playerPaddle,
      enemyPaddle,
      _scoreText,
      middleLine,
      mysteryBoxTimer
    ]);

    return super.onLoad();
  }

  /// Add a [MysteryBox] to the game
  void addMysteryBox() {
    add(MysteryBox(
        Vector2(
            map(Random().nextDouble(), 0, 1, -gameRef.size.x / 2 + 5,
                gameRef.size.x / 2 - 5),
            0),
        frequency: 5));
  }

  /// Tilt the player paddle by [x] units
  void tilt(double x) {
    playerPaddle.move(x);
  }

  /// Called when the player scores by moving
  /// the [ball] past the other enemies paddle
  void playerScored(Ball ball) {
    _playerScore++;
    _updateScore();
    ball.reset(1);
  }

  /// Called when the enemy scores by moving
  /// the [ball] past the other player's paddle
  void enemyScored(Ball ball) {
    _enemyScore++;
    _updateScore();
    ball.reset(-1);
  }

  void _updateScore() {
    _scoreText = _scoreText..text = '$_enemyScore\n$_playerScore';
  }
}

double map(double value, double min, double max, double newMin, double newMax) {
  return (value - min) / (max - min) * (newMax - newMin) + newMin;
}
