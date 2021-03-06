import tables
import sequtils

import c4/sugar
import c4/threads
import c4/systems/physics/simple
import c4/entities

import ../messages


const
  movementQuant* = 0.03
  paddleMovementSpeed* = 0.5
  ballSpeed* = 1.0

type
  PhysicsSystem* = object of SimplePhysicsSystem
    ball*: Entity
    paddles*: array[2, Entity]
    gates*: array[2, Entity]
    walls*: seq[Entity]

  Physics* = object of SimplePhysics
    movementRemains*: float

  Control* {.inheritable.} = object
  PlayerControl* = object of Control
  AIControl* = object of Control


method getComponents*(self: ref PhysicsSystem): Table[Entity, ref SimplePhysics] =
  cast[Table[Entity, ref SimplePhysics]](getComponents(ref Physics))

method init*(self: ref PhysicsSystem) =
  # ball
  self.ball = newEntity()
  self.ball[ref Physics] = (ref Physics)(position: (x: 0.5, y: 0.5), width: 0.02, height: 0.02)

  # paddles
  self.paddles[0] = newEntity()
  self.paddles[0][ref Physics] = (ref Physics)(position: (x: 0.5, y: 0.05), width: 0.25, height: 0.01)
  self.paddles[0][ref Control] = new(AIControl)
  self.paddles[1] = newEntity()
  self.paddles[1][ref Physics] = (ref Physics)(position: (x: 0.5, y: 0.95), width: 0.25, height: 0.01)
  self.paddles[1][ref Control] = new(PlayerControl)

  # gates
  self.gates[0] = newEntity()
  self.gates[0][ref Physics] = (ref Physics)(position: (x: 0.5, y: 0.0), width: 1.0, height: 0.02)
  self.gates[1] = newEntity()
  self.gates[1][ref Physics] = (ref Physics)(position: (x: 0.5, y: 1.0), width: 1.0, height: 0.02)

  # walls
  let leftWall = newEntity()
  leftWall[ref Physics] = (ref Physics)(position: (x: 0.0, y: 0.5), width: 0.02, height: 1.0)
  self.walls.add(leftWall)

  let rightWall = newEntity()
  rightWall[ref Physics] = (ref Physics)(position: (x: 1.0, y: 0.5), width: 0.02, height: 1.0)
  self.walls.add(rightWall)


method update*(self: ref PhysicsSystem, dt: float) =
  procCall self.as(ref SimplePhysicsSystem).update(dt)

  for entity in self.paddles:
    let physics = entity[ref Physics]
    if physics.movementRemains > 0:
      physics.movementRemains -= dt
      if physics.movementRemains < 0:
        physics.movementRemains = 0
        physics.speed = (x: 0.0, y: 0.0)

  for entity, physics in getComponents(ref Physics):
    if physics.position != physics.previousPosition:
      (ref SetPositionMessage)(
        entity: entity,
        x: physics.position.x,
        y: physics.position.y,
      ).send("network")

  # simple AI logic
  for entity in toSeq(getComponents(ref Control).pairs).filterIt(it[1] of ref AIControl).mapIt(it[0]):
    let
      entityX = entity[ref Physics].position.x
      ballX = self.ball[ref Physics].position.x

    const delta = 0.02

    if abs(entityX - ballX) > delta:
      if entityX < ballX:
        (ref MoveMessage)(direction: right).send()
      else:
        (ref MoveMessage)(direction: left).send()
