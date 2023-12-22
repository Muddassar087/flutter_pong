import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

void main() {
  runApp(
    GameWidget(
      game: PongGame(),
    ),
  );
}

class PongGame extends FlameGame with KeyboardEvents, HasCollisionDetection {
  late Paddle leftPaddle;
  late Paddle rightPaddle;
  late Ball ball;

  late TextComponent scoreLeft;
  late TextComponent scoreRight;

  bool shouldComputerPlay = true;

  double paddleHeight = 100;
  double paddWidth = 10;

  int leftScore = 0;
  int rightScore = 0;

  @override
  FutureOr<void> onLoad() {
    leftPaddle = Paddle(
      position: Vector2(0 + (paddWidth), size.y / 2),
      size: Vector2(paddWidth, paddleHeight),
    );

    rightPaddle = Paddle(
      position: Vector2((size.x - paddWidth), size.y / 2),
      size: Vector2(paddWidth, paddleHeight),
    );

    ball = Ball(radius: 10, position: Vector2(size.x * .5, size.y * .5))
      ..movement = randomVector();

    scoreLeft = TextComponent(
        text: "$leftScore",
        size: Vector2(20, 20),
        textRenderer: TextPaint(style: const TextStyle(fontSize: 35)))
      ..position = Vector2(50, 25)
      ..anchor = Anchor.center;

    scoreRight = TextComponent(
        text: "$rightScore",
        size: Vector2(20, 20),
        textRenderer: TextPaint(style: const TextStyle(fontSize: 35)))
      ..position = Vector2(size.x - 50, 25)
      ..anchor = Anchor.center;

    add(
      RectangleComponent(
        size: Vector2(2, size.y),
        position: Vector2(size.x * .5, 0),
      )..anchor = Anchor.topCenter,
    );

    add(leftPaddle);
    add(rightPaddle);
    add(ball);
    add(scoreLeft);
    add(scoreRight);

    return super.onLoad();
  }

  Vector2 randomVector() =>
      Vector2(Random().nextDouble() + 0.2, Random().nextDouble() + 0.8);

  @override
  void update(double dt) {
    if (leftPaddle.movement == PaddleMovement.up) {
      leftPaddle.updatePos((speed * dt) * -1, screenSize: size);
    } else if (leftPaddle.movement == PaddleMovement.down) {
      leftPaddle.updatePos((speed * dt) * 1, screenSize: size);
    }

    if (shouldComputerPlay) {
      leftPaddle.movement = computerPaddleMovements(
          paddlePosition: leftPaddle.position,
          ballPosition: ball.position,
          dt: dt);
    }

    if (shouldComputerPlay) {
      rightPaddle.movement = computerPaddleMovements(
          paddlePosition: rightPaddle.position,
          ballPosition: ball.position,
          dt: dt);
    }

    if (rightPaddle.movement == PaddleMovement.up) {
      rightPaddle.updatePos((speed * dt) * -1, screenSize: size);
    } else if (rightPaddle.movement == PaddleMovement.down) {
      rightPaddle.updatePos((speed * dt) * 1, screenSize: size);
    }

    ball.updatePos(
      dt * speed,
      screenSize: size,
      onUpdateLeftScore: () => scoreLeft.text = "${++leftScore}",
      onUpdateRightScore: () => scoreRight.text = "${++rightScore}",
    );

    if (rightScore > 5 && rightScore <= 6 || leftScore > 5 && leftScore <= 6) {
      speed = 700;
    }

    super.update(dt);
  }

  @override
  KeyEventResult onKeyEvent(
    RawKeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final isKeyDown = event is RawKeyDownEvent;
    if (isKeyDown) {
      if (event.logicalKey == LogicalKeyboardKey.keyW) {
        leftPaddle.movement = PaddleMovement.up;
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyS) {
        leftPaddle.movement = PaddleMovement.down;
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        rightPaddle.movement = PaddleMovement.up;
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        rightPaddle.movement = PaddleMovement.down;
        return KeyEventResult.handled;
      }
    }

    leftPaddle.movement = PaddleMovement.idle;
    rightPaddle.movement = PaddleMovement.idle;

    return KeyEventResult.ignored;
  }
}

enum PaddleMovement {
  up,
  down,
  idle,
}

class Paddle extends RectangleComponent with CollisionCallbacks {
  Paddle({
    super.position,
    super.size,
    this.movement = PaddleMovement.idle,
  }) : super(
          anchor: Anchor.center,
        );

  PaddleMovement movement;

  /// MOVEMENT SPEED

  void updatePos(double dy, {required Vector2 screenSize}) {
    position = Vector2(position.x, position.y + dy);

    position.y = position.y.clamp(
      0 + (size.y / 2),
      screenSize.y - (size.y / 2),
    );
  }

  @override
  FutureOr<void> onLoad() {
    add(RectangleHitbox());
    return super.onLoad();
  }
}

class Ball extends CircleComponent with CollisionCallbacks {
  Ball({
    super.radius,
    super.position,
  }) : super(anchor: Anchor.center);

  late Vector2 movement;

  void updatePos(
    double change, {
    required Vector2 screenSize,
    required VoidCallback onUpdateRightScore,
    required VoidCallback onUpdateLeftScore,
  }) {
    position += Vector2(movement.x * change, movement.y * change);

    double minX = 0 + radius;
    double maxX = screenSize.x - radius;

    double minY = 0 + radius;
    double maxY = screenSize.y - radius;

    position.x = position.x.clamp(minX, maxX);
    position.y = position.y.clamp(minY, maxY);

    if (position.y == maxY) {
      movement = Vector2(movement.x, -movement.y);
    }

    if (position.y == minY) {
      movement = Vector2(movement.x, -(movement.y));
    }

    if (position.x == minX) {
      movement = Vector2(-movement.x, movement.y);
      onUpdateRightScore();
    }

    if (position.x == maxX) {
      movement = Vector2(-movement.x, movement.y);
      onUpdateLeftScore();
    }
  }

  @override
  Future<void> onLoad() {
    add(CircleHitbox());
    return super.onLoad();
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Paddle) {
      movement = Vector2(-movement.x, movement.y);
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}

double previousDistance =
    double.infinity; // Initialize previousDistance to a large value
double speed = 500;

PaddleMovement computerPaddleMovements(
    {required Vector2 paddlePosition,
    required Vector2 ballPosition,
    required double dt}) {
  // Calculate the current distance between the paddle and the ball
  double currentDistance = paddlePosition.distanceTo(ballPosition);

  // Check if the current distance is significantly smaller than the previous distance
  if (currentDistance < previousDistance) {
    // Adjust the threshold as needed
    // Calculate new positions for moving the paddle down and up
    Vector2 tempDown =
        Vector2(paddlePosition.x, paddlePosition.y + (speed * dt));
    Vector2 tempUp = Vector2(paddlePosition.x, paddlePosition.y - (speed * dt));

    // Calculate distances from the new positions to the ball
    double distanceDown = tempDown.distanceTo(ballPosition);
    double distanceUp = tempUp.distanceTo(ballPosition);

    previousDistance = currentDistance;

    // Check which movement direction (up or down) brings the paddle closer to the ball
    if (distanceDown < distanceUp) {
      return PaddleMovement.down;
    } else {
      return PaddleMovement.up;
    }
  }
  previousDistance = currentDistance;
  // If the current distance is not significantly smaller, return idle
  return PaddleMovement.idle;
}
