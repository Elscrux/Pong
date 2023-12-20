import 'dart:async';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/extensions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/game.dart';
import 'ball.dart';
import 'paddle.dart';

class MysteryBox extends SpriteComponent
    with CollisionCallbacks, HasWorldReference<PongWorld> {
  MysteryBox(Vector2 position, {double frequency = 5})
      : super(size: Vector2(50, 50), position: position) {
    anchor = Anchor.center;
    add(RectangleHitbox(size: size));
  }

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('mystery-box.png');

    return super.onLoad();
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Ball) {
      mystery(other);
      world.remove(this);
    }
  }

  void mystery(Ball ball) {
    switch (Random().nextInt(3)) {
      case 0:
        addTemporaryBall();
        break;
      case 1:
        changeBallSpeed(ball);
        break;
      case 2:
        paddleSizeMod();
        break;
      default:
        break;
    }
  }

  void addTemporaryBall() {
    world.add(TemporaryBall(position, Random().nextBool() ? 1 : -1));
  }

  void changeBallSpeed(Ball ball) {
    ball.updateSpeed(ball.speed * (1 + Random().nextDouble() / 2));
    ball.speedEffect();
  }

  void paddleSizeMod() {
    var unaffectedPaddles = [world.playerPaddle, world.enemyPaddle]
        .where((paddle) => paddle.length == Paddle.initialLength)
        .toList();

    if (unaffectedPaddles.isEmpty) {
      return;
    }

    var paddle = unaffectedPaddles.random();
    var factor = Random().nextBool() ? -0.5 : 0.5;
    var originalColor = paddle.paint;
    var offset = paddle.length * factor;
    paddle.length += offset;
    if (factor < 0) {
      paddle.paint = Paint()..color = Colors.red;
    } else {
      paddle.paint = Paint()..color = Colors.green;
    }
    paddle.add(TimerComponent(
        period: 10,
        onTick: () {
          paddle.length -= offset;
          paddle.paint = originalColor;
        }));
  }
}
