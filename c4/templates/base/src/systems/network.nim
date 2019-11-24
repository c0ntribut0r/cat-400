import c4/systems/network/enet

import ../messages


type ServerNetworkSystem* = object of enet.ServerNetworkSystem
type ClientNetworkSystem* = object of enet.ClientNetworkSystem

proc run*(self: var ServerNetworkSystem) =
  enet.NetworkSystem(self).run()

proc run*(self: var ClientNetworkSystem) =
  enet.NetworkSystem(self).run()