import os
export os
import osproc
import options
export options
import tables
export tables
import parseopt
import logging

when isMainModule:
  import unittest

type
  ProcessName* = string  ## each process must have a unique name; process will be accessible by this name


var processes = initTable[ProcessName, Process]()
const mainProcessName* = "master"


proc getProcessName(): string =
  for kind, key, value in parseopt.getopt():
    if kind == parseopt.cmdLongOption and key == "process":
      return value

  mainProcessName


let processName*: ProcessName = getProcessName()


template run*(name: ProcessName, code: untyped) =
  ## Runs new process which executes all instructions before this call, plus `code` content.
  if processName == mainProcessName:
    if processes.hasKey(name):
      raise newException(KeyError, "Process with name '" & name & "' already exists")

    logging.debug "Starting '" & name & "' process"
    processes[name] = startProcess(
      command=getAppFilename(),
      args=commandLineParams() & " --process=" & name,
      options={poParentStreams},
    )

  elif processName == name:
    logging.debug "Running '" & name & "' process"

    try:
      code
      quit()
    except Exception as exc:
      # log any exception before dying
      logging.fatal "Exception: " & exc.msg & "\n" & exc.getStackTrace()
      raise

proc dieTogether*(checkInterval: int = 1000) =
  ## Monitors existing processes. If one process is not running anymore, terminates all other processes as well.
  assert processName == mainProcessName
  var shutdown = false

  while true:
    for name, process in processes:
      if not process.running:
        logging.debug "Process '" & name & "' not running -> shutting down"
        shutdown = true
        break

    if shutdown:
      for process in processes.values:
        if process.running:
          process.kill()
      break

    sleep checkInterval


when isMainModule:
  suite "processes":
    run("process1") do:
      for _ in 0..10:
        echo processName
        sleep 100

    run("process2") do:
      for _ in 0..10:
        echo processName
        sleep 100

    dieTogether()

    test "run":
      assert true
