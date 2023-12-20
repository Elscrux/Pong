import 'dart:async';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/extensions.dart';
import 'package:flame/geometry.dart';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

import '../game/game.dart';
import 'mystery_box.dart';
import 'paddle.dart';

class Ball extends CircleComponent
    with CollisionCallbacks, HasGameRef<PongGame> {
  static const double initialSpeed = 500;
  double speed = initialSpeed;
  double speedIncrease = 5;
  late Vector2 direction;

  late Color startColor = Colors.yellow;
  late Color endColor = Colors.red;

  late CircleHitbox _hitbox;

  Ball(double yDirection) {
    direction = Vector2(Random().nextDouble(), yDirection).normalized();
    radius = 10;
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() {
    updateSpeed(initialSpeed);
    _hitbox = CircleHitbox(radius: radius);
    add(_hitbox);

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    position += direction * speed * dt;

    if ((gameRef.size.y / 2 - position.y).abs() < 20) {
      gameRef.world.enemyScored(this);
      someoneScored();
    } else if ((position.y - gameRef.size.y / -2).abs() < 20) {
      gameRef.world.playerScored(this);
      someoneScored();
    }
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is MysteryBox) {
      return;
    }

    if (other is ScreenHitbox) {
      if ((intersectionPoints.first.x - gameRef.size.x / -2).abs() < 0.001) {
        direction = Vector2(-direction.x, direction.y);
      } else if ((intersectionPoints.first.x - gameRef.size.x / 2).abs() <
          0.001) {
        direction = Vector2(-direction.x, direction.y);
      } else if ((intersectionPoints.first.y - gameRef.size.y / -2).abs() <
          0.001) {
        direction = Vector2(direction.x, -direction.y);
      } else if ((intersectionPoints.first.y - gameRef.size.y / 2).abs() <
          0.001) {
        direction = Vector2(direction.x, -direction.y);
      }
      ballReflected();
      return;
    }

    final ballRay = Ray2(
      origin: position - direction * radius * 4,
      direction: direction,
    );

    var raycast = gameRef.collisionDetection
        .raycast(ballRay, ignoreHitboxes: [_hitbox], maxDistance: 1000000);

    if (raycast == null || raycast.reflectionRay == null) {
      return;
    }

    direction = raycast.reflectionRay!.direction;

    if (other is Paddle) {
      var newX = direction.x + other.currentVelocity.clamp(-5, 5) / 10;
      direction = Vector2(newX, direction.y).normalized();
    }

    ballReflected();
  }

  void someoneScored() {
    updateSpeed(initialSpeed);
  }

  void ballReflected() {
    updateSpeed(speed + speedIncrease);
  }

  void updateSpeed(double newSpeed) {
    speed = newSpeed;
    updateColor();
  }

  void updateColor() {
    double redFactor = ((speed - initialSpeed) / initialSpeed).clamp(0, 1);
    paint = Paint()..color = Color.lerp(startColor, endColor, redFactor)!;
  }

  void reset(double nextDirection) {
    position = Vector2.zero();
    direction = Vector2(Random().nextDouble(), nextDirection).normalized();
  }

  void speedEffect() {
    var particleTimer = TimerComponent(
        period: 0.01,
        repeat: true,
        onTick: () => gameRef.world.add(ParticleSystemComponent(
              position: position,
              particle: Particle.generate(
                count: 5,
                lifespan: 0.25,
                generator: (i) => AcceleratedParticle(
                  acceleration: Vector2.random(),
                  speed: (-direction + (Vector2.random())) * 50,
                  lifespan: Random().nextDouble() * 2,
                  child: CircleParticle(
                    radius: radius / 5,
                    paint: Paint()
                      ..color = Color.lerp(
                          Colors.red, Colors.orange, Random().nextDouble())!,
                  ),
                ),
              ),
            )));
    add(particleTimer);
    add(TimerComponent(period: 2, onTick: () => remove(particleTimer)));
  }
}

class TemporaryBall extends Ball with HasWorldReference<PongWorld> {
  TemporaryBall(Vector2 position, double direction) : super(direction) {
    this.position = position;
    startColor = Colors.green;
    endColor = Colors.blue;
  }

  @override
  void reset(double nextDirection) {
    world.remove(this);
  }
}
