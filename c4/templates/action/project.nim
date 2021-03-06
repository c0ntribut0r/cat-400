import c4/processes
import c4/threads

import src/systems/physics
import src/systems/input
import src/systems/video
import src/systems/network

import src/scenarios/init
import src/scenarios/connection
import src/scenarios/entity
import src/scenarios/impersonation
import src/scenarios/player_actions
import src/scenarios/position


when isMainModule:
  run("server"):
    spawn("network"):
      logging.addHandler(logging.newConsoleLogger(levelThreshold=getCmdLogLevel(), fmtStr="[$datetime] server $levelname: "))
      let network = new(ServerNetworkSystem)
      network.init(port=Port(9000))
      network.run()
      network.dispose()

    spawn("physics"):
      logging.addHandler(logging.newConsoleLogger(levelThreshold=getCmdLogLevel(), fmtStr="[$datetime] physics $levelname: "))
      let physics = new(PhysicsSystem)
      physics.init()
      physics.run()
      physics.dispose()

    joinAll()

  run("client"):
    spawn("network"):
      logging.addHandler(logging.newConsoleLogger(levelThreshold=getCmdLogLevel(), fmtStr="[$datetime] client $levelname: "))
      let network = new(ClientNetworkSystem)
      network.init()
      network.connect(host="localhost", port=Port(9000))
      network.run()
      network.dispose()

    spawn("input"):
      logging.addHandler(logging.newConsoleLogger(levelThreshold=getCmdLogLevel(), fmtStr="[$datetime] input $levelname: "))
      var input = new(InputSystem)
      input.init()
      input.run()
      input.dispose()

    spawn("video"):
      logging.addHandler(logging.newConsoleLogger(levelThreshold=getCmdLogLevel(), fmtStr="[$datetime] video $levelname: "))
      let video = new(VideoSystem)
      video.init()
      video.run()
      video.dispose()

    joinAll()

  processes.dieTogether()
