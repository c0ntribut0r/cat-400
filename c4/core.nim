from posix import fork
from parseopt import nil
from logging import nil
from ospaths import joinPath
from os import getAppDir

from strutils import join, toLowerAscii, toUpperAscii, parseEnum
from strformat import `&`
from utils.helpers import index
from sequtils import mapIt

from conf import config, Mode
from server import run
from client import run


const 
  frameworkVersion = staticRead("version.txt")

  logLevels = logging.LevelNames.mapIt(it.toLowerAscii).join("|")
  modes = Mode.mapIt($it).join("|")
  help = &"""
    -v, --version - print version
    -l, --loglevel=[{logLevels}] - specify log level
    -h, --help - print help
    -m, --mode=[{modes}] - launch server/client/both 
  """


proc run*() =
  var mode = Mode.both

  # TODO: use https://github.com/c-blake/cligen?
  for kind, key, value in parseopt.getopt():
    case kind
      of parseopt.cmdLongOption, parseopt.cmdShortOption:
        case key
          of "version", "v":
            echo(config.version)
            echo("C4 " & frameworkVersion)
            echo("Nim " & NimVersion)
            echo("Compiled @ " & CompileDate & " " & CompileTime)
            return
          of "loglevel", "l":
            config.logLevel = logging.LevelNames.index(value.toUpperAscii)
          of "help", "h":
            echo help
            return
          of "mode", "m":
            mode = parseEnum[Mode](value)
          else:
            echo("Unknown option: " & key & "=" & value)
            return
      else: discard

  if mode == Mode.both:
    return   # TODO https://nim-lang.org/docs/osproc.html
    # TODO: no way to check whether any of processes was killed (but they should be killed simultaneously)
    # TODO: addQuitProc?

  let
    logFile = joinPath(getAppDir(), (if mode == Mode.server: "server.log" else: "client.log"))
    logFmtStr = "[$datetime] " & (if mode == Mode.server: "SERVER" else: "CLIENT") & " $levelname: "
  logging.addHandler(logging.newRollingFileLogger(logFile, maxLines=1000, levelThreshold=config.logLevel, fmtStr=logFmtStr))
  logging.addHandler(logging.newConsoleLogger(levelThreshold=config.logLevel, fmtStr=logFmtStr))
  logging.debug("Version " & frameworkVersion)

  if mode == Mode.server:
    server.run(config)
  else:
    client.run(config)
