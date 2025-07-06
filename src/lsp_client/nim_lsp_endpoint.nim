import ./lsp_types
import chronos, chronos/asyncproc, chronos/streams/asyncstream, os, strutils, parseutils
import nim_jsonrpc_protocol
from osproc import execCmd
import json
import oolib

proc skipWhitespace(x: string, pos: int): int =
  result = pos
  while result < x.len and x[result] in Whitespace:
    inc result

class pub LspNimEndpoint:
  var
    id: int = 0
    process: AsyncProcessRef
    input: AsyncStreamReader
    output: AsyncStreamWriter
    err: AsyncStreamReader

  proc `new`() =
    self.process = nil
    self.input = nil
    self.output = nil
    self.err = nil

  proc setProcess*(p: AsyncProcessRef) =
    self.process = p
    self.input = self.process.stdoutStream()
    self.output = self.process.stdinStream()
    self.err = self.process.stderrStream()

  proc startProcess*() {.async.} =
    let process = await startProcess(findExe("nimlsp"), options = {},
                                   stdoutHandle = AsyncProcess.Pipe,
                                   stderrHandle = AsyncProcess.Pipe,
                                   stdinHandle = AsyncProcess.Pipe)
    self.setProcess(process)
  proc stopProcess*() = discard
  proc getId*(): int = self.id
  proc incId*() = inc self.id
  proc exitCode*(): int =
    let result = self.process.peekExitCode()
    if result.isOk():
      result.get()
    else:
      -1
  proc write*(p: pointer, len: int): Future[int] {.async.} =
    await self.output.write(p, len)
    result = len
  proc readError*(): Future[string] {.async.} =
    try:
      let data = await self.err.read()
      result = ""
      for b in data:
        result.add(char(b))
    except CatchableError:
      result = ""
  proc readMessage*(): Future[string] {.async.} =
    # Note: nimlsp debug build will produce debug info to stdout
    var contentLen = -1
    var headerStarted = false
    while true:
      let ln = await self.input.readLine()
      debugEcho ln
      if ln.len != 0:
        let sep = ln.find(':')
        if sep == -1:
          continue

        let valueStart = ln.skipWhitespace(sep + 1)
        case ln[0 ..< sep]
        of "Content-Type":
          if ln.find("utf-8", valueStart) == -1 and ln.find("utf8", valueStart) == -1:
            raise newException(UnsupportedEncoding, "only utf-8 is supported")
        of "Content-Length":
          if parseInt(ln, contentLen, valueStart) == 0:
            raise newException(MalformedFrame, "invalid Content-Length: " &
                                                ln.substr(valueStart))
        else:
          # Unrecognized headers are ignored
          continue
        headerStarted = true
      elif not headerStarted:
        continue
      else:
        if contentLen != -1:
          let data = await self.input.read(contentLen)
          result = ""
          for b in data:
            result.add(char(b))
          when defined(debugCommunication):
            stderr.write(result)
            stderr.write("\n")
          return result
        else:
          raise newException(MalformedFrame, "missing Content-Length header")

  proc send*(str: string): Future[void]{.async.} =
    var msg: string = "Content-Type: application/vscode-jsonrpc; charset=utf-8\r\n"
    msg = msg & "Content-Length: " & $str.len & "\r\n\r\n" & str
    debugEcho repr msg

    await self.output.write(msg)
    await self.output.finish()

  proc roundtrip*(str: string): Future[string]{.async.} =
    var msg: string = "Content-Type: application/vscode-jsonrpc; charset=utf-8\r\n"
    msg = msg & "Content-Length: " & $str.len & "\r\n\r\n" & str
    debugEcho repr msg

    await self.output.write(msg)
    await self.output.finish()
    result = await self.readMessage()

  proc sendNotification*(`method`: string): Future[void]{.async.} =
    let jo = initGRequest(`method` = `method`)
    let str = $ % jo
    await self.send(str)

  proc sendNotification*[T](`method`: string, params: T): Future[void]{.async.} =
    let jo = initGRequest(`method` = `method`, params = cast[JsonNode](params))
    let str = $ % jo
    await self.send(str)

  proc callMethod*(`method`: string): Future[string]{.async.} =
    let id = self.getId()
    self.incId()
    let jo = initGRequest(id = id, `method` = `method`)
    let str = $ % jo
    result = await self.roundtrip(str)

  proc callMethod*[T](`method`: string, params: T): Future[string]{.async.} =
    let id = self.getId()
    self.incId()
    let jo = initGRequest(id = id, `method` = `method`, params = cast[JsonNode](params))
    let str = $ % jo
    result = await self.roundtrip(str)
