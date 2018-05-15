## This module defines Entity - a base unit for representing a game object.

import tables


type
  Entity* = int16  # uint doesn't check boundaries
  ## Entity is just an int which may have components of any type.

var
  entities: set[Entity] = {}  # set[int32] won't compile
  # destructors: seq[proc(entity: Entity) {.closure.}]  # registered destructors which will be called on entity deletion


# ---- Entity ----
proc newEntity*(): Entity =
  ## Return new Entity or raises error if limit exceeded
  result = low(Entity)
  while result in entities:
    result += 1  # TODO: pretty dumb

  entities.incl(result)  # add entity to global entities registry

proc delete*(entity: Entity) =
  ## Delete the Entity
  # TODO: delete all components related to this entity
  # for destructor in destructors:
  #   destructor(entity)
  entities.excl(entity)  # will not alert if entity does not exist

# ---- Components ----
proc getComponents*(t: typedesc): ref Table[Entity, t] =
  ## Returns a table of components for all entities (`Table[Entity, t]`)
  var table {.global.} = newTable[Entity, t]()
  return table

  # var table {.global.}: TableRef[Entity, t] 
  # if table.isNil:
  #   table = newTable[Entity, t]()
  #   if destructors.isNil:  # this line may be called even earlier than `var` declarations of this file
  #     destructors = @[]  # thus we need to init whatever we need
  #   destructors.add(proc(entity: Entity) {.closure.} = echo "Destroyed " & t.name & " for entity " & $entity)
  #   # destructors.add(proc(entity: Entity) {.closure.} = discard getComponents(t); echo "OK")
  #   echo "Table just initialized for type " & $t.name
  # return table


template has*(entity: Entity, t: typedesc): bool = getComponents(t).hasKey(entity)
template del*(entity: Entity, t: typedesc) = getComponents(t).del(entity)
template `[]`*(entity: Entity, t: typedesc): var typed = getComponents(t)[entity]
template `[]=`*(entity: Entity, t: typedesc, value: t) = getComponents(t)[entity] = value
