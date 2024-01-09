# Flutter-Pong

## Game Idea
The game is based on the well-known game of Pong.
On both sides of the board there is a paddle, one of which you can control yourself, and one which is controlled by an ai opponent.
There is a ball that is moving on board and each player tries to move their paddle in order to reflect the ball to the other side.
If the ball passes through the defense of a paddle, the player will score one point.

### Mystery-Boxes
In addition to the traditional pong features, this version of Pong introduces a new element to the game, Mystery-Boxes.
Mystery-Boxes spawn at random in the middle of the game board.
When a Mystery-Box is hit by a ball, a random effect is applied.

1. Extra Ball
   - An additional ball is spawned at the place of the mystery box. The ball vanishes once it scored once.
2. Resizing Paddles
   - One of the two paddle is either decreased or increased in size at random to make the game easier or more difficult.
3. Speed Boosts
   - The speed of the ball is increased significantly, making it more challenging to hit the ball. 

## Earable Integration
The eSense Earable is integrated via the eSense Flutter API and is used to control the player's paddle.
This is achieved by analyzing the eSense gyroscope data stream and transforming it into commands for the player paddle.

## Project Structure
- components:
  - Flame Components that are placed in the world, include capsuled logic per 
- eSense:
  - eSense Logic for discovery and connection to an eSense earable device
- game:
  - Game logic and scene setup
- widgets
  - Widgets displayed in Flutter
