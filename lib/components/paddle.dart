import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/game.dart';
import 'ball.dart';

/// Generic paddle
class Paddle extends RectangleComponent
    with CollisionCallbacks, HasGameRef<PongGame> {
  double currentVelocity = 0;
  static const double initialLength = 100;
  late RectangleHitbox _hitbox;

  /// Create a paddle at [x] and [y]
  Paddle(double x, double y)
      : super(size: Vector2(initialLength, 20), position: Vector2(x, y)) {
    paint = Paint()..color = Colors.white;

    anchor = Anchor.center;

    _hitbox = RectangleHitbox(size: size);
    add(_hitbox);
  }

  /// Move the paddle by [offset] pixels
  void move(double offset) {
    if (gameRef.size.x / 2 - (position.x + offset).abs() < size.x / 2) {
      return;
    }

    position.x += offset;

    currentVelocity = offset;
  }

  /// Get the length of the paddle
  double get length => size.x;

  /// Set the length of the paddle to [newLength]
  set length(double newLength) {
    var factor = newLength / size.x;
    size.x = newLength;
    _hitbox.scale.x *= factor;
  }
}

enum Direction { left, right }

/// Paddle controlled by the AI
class AiPaddle extends Paddle {
  final speed = 150;
  final double accelerationMult = 0.5;
  int accelerationSteps = 0;
  double facingDirection;
  Direction currentDirection = Direction.left;

  /// Create a paddle at [x] and [y] facing [facingDirection]
  AiPaddle(double x, double y, this.facingDirection) : super(x, y);

  @override
  void update(double dt) {
    super.update(dt);

    var approachingBalls = gameRef.world
        .descendants()
        .whereType<Ball>()
        .where(
            (ball) => ball.direction.y.isNegative == facingDirection.isNegative)
        .toList();

    if (approachingBalls.isEmpty) {
      // No ball approaching - return to middle
      if (center.x.abs() < 75) {
        return;
      }

      if (center.x > 0) {
        accelerate(-dt);
      } else {
        accelerate(dt);
      }
    } else {
      Ball closestBall = approachingBalls.first;
      double closestDistance = (closestBall.position.y - center.y).abs();
      for (var ball in approachingBalls) {
        var distance = (ball.position.y - center.y).abs();
        if (distance < closestDistance) {
          closestBall = ball;
          distance = closestDistance;
        }
      }

      if ((closestBall.position.x - center.x).abs() < 10) {
        return;
      }

      if (closestBall.position.x > center.x) {
        accelerate(dt);
      } else {
        accelerate(-dt);
      }
    }
  }

  void accelerate(double dt) {
    Direction nextDirection = dt > 0 ? Direction.right : Direction.left;

    if (currentDirection != nextDirection) {
      accelerationSteps = 0;
    } else {
      accelerationSteps += 1;
    }

    move(speed * acceleration() * dt);

    currentDirection = nextDirection;
  }

  double acceleration() {
    return 1 + log(1 + accelerationSteps) * accelerationMult;
  }
}
