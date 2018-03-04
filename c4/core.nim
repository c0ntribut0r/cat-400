from strutils import format
from posix import fork
from parseopt import nil
from logging import nil
from ospaths import joinPath
from os import getAppDir

from strutils import join
from utils.helpers import index

from conf import config, Mode
from server import run
from client import run


const 
  frameworkVersion = staticRead("version.txt")
  help = """
    -v, --version - print version
    --loglevel=[$logLevels] - specify log level
    -h, --help - print help
    -s, --server - launch server only (without client)
  """.format([
    "logLevels", logging.LevelNames.join("|"),
  ])


proc run*() =
  # TODO: use https://github.com/c-blake/cligen
  # parse command line options
  for kind, key, val in parseopt.getopt():
    case kind
      of parseopt.cmdLongOption, parseopt.cmdShortOption:
        case key
          of "version", "v":
            echo("Nim version " & NimVersion)
            echo("Framework version " & frameworkVersion)
            echo("Project version " & config.version)
            return
          of "loglevel":
            config.logLevel = logging.LevelNames.index(val)  # overwrite default log level
          of "help", "h":
            echo help
            return
          of "server", "s":
            config.mode = Mode.server
          else:
            echo("Unknown option: " & key & "=" & val)
            return
      else: discard

  # separate this process into "client" and "server" processes
  # TODO: `fork()` is available on Unix only; user some other function
  # https://nim-lang.org/docs/osproc.html
  let
    childPid = if config.mode == Mode.server: 1 else: fork()
    isServerProcess = childPid != 0
 
  if childPid < 0:
    raise newException(SystemError, "Error forking a process")

  # the following code will be executed by both processes

  # set up logging
  let
    logFile = joinPath(getAppDir(), (if isServerProcess: "server.log" else: "client.log"))
    logFmtStr = "[$datetime] " & (if isServerProcess: "SERVER" else: "CLIENT") & " $levelname: "
  logging.addHandler(logging.newRollingFileLogger(logFile, maxLines=1000, levelThreshold=config.logLevel, fmtStr=logFmtStr))
  logging.addHandler(logging.newConsoleLogger(levelThreshold=config.logLevel, fmtStr=logFmtStr))
  logging.debug("Version " & frameworkVersion)

  # TODO: no way to check whether any of processes was killed (but they should be killed simultaneously)
  # TODO: addQuitProc?
  if isServerProcess:
    server.run(config)
  else:
    client.run(config)
