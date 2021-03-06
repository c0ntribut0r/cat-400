{.used.}
import logging
import net
import strformat

import sdl2/sdl as sdllib

import c4/sugar
import c4/entities
import c4/threads
import c4/systems/network/enet
import c4/systems/physics/simple
import c4/systems/video/sdl

import ../systems/network
import ../systems/physics
import ../systems/video
import ../messages


# New client connection handling

method processLocal*(self: ref ServerNetworkSystem, message: ref ConnectionOpenedMessage) =
  # client just connected - send this info to physics system
  message.send("physics")


proc getEntityDescribingMessages(self: Entity, kind: EntityKind): seq[ref EntityMessage] =
  # helper to send all entity info over network
  result.add((ref CreateTypedEntityMessage)(
    entity: self,
    kind: kind,
  ))
  result.add((ref SetDimensionMessage)(
    entity: self,
    width: self[ref Physics].width,
    height: self[ref Physics].height,
  ))
  result.add((ref SetPositionMessage)(
    entity: self,
    x: self[ref Physics].position.x,
    y: self[ref Physics].position.y,
  ))


method process*(self: ref PhysicsSystem, message: ref ConnectionOpenedMessage) =
  # send world info to newly connected client
  for msg in self.player.getEntityDescribingMessages(player):
    msg.peer = message.peer
    msg.send("network")

  for entity in self.enemies:
    for msg in entity.getEntityDescribingMessages(enemy):
      msg.peer = message.peer
      msg.send("network")

  for entity in self.walls:
    for msg in entity.getEntityDescribingMessages(wall):
      msg.peer = message.peer
      msg.send("network")


# then all local messages are by default sent to corresponding peers


method processRemote*(self: ref ClientNetworkSystem, message: ref CreateTypedEntityMessage) =
  # when entity is created, draw it on screen
  procCall self.as(ref EnetClientNetworkSystem).processRemote(message)  # create entity, generate mapping
  let color = case message.kind
    of wall: wallColor
    of player: playerColor
    of enemy: enemyColor

  message.entity[ref Video] = (ref Video)(color: color)


method processRemote*(self: ref ClientNetworkSystem, message: ref SetDimensionMessage) =
  try:
    procCall self.as(ref EnetClientNetworkSystem).processRemote(message)
  except KeyError:
    return

  let video = message.entity[ref Video]
  video.width = message.width
  video.height = message.height


method processRemote*(self: ref ClientNetworkSystem, message: ref SetPositionMessage) =
  try:
    procCall self.as(ref EnetClientNetworkSystem).processRemote(message)
  except KeyError:
    return

  let video = message.entity[ref Video]
  video.x = message.x
  video.y = message.y
