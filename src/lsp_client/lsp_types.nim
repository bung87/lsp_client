import asynctools, asyncdispatch, faststreams/asynctools_adapters, faststreams/textio
import strutils, parseutils, json

type
  BaseProtocolError* = object of Defect

  MalformedFrame* = object of BaseProtocolError
  UnsupportedEncoding* = object of BaseProtocolError

proc skipWhitespace(x: string, pos: int): int =
  result = pos
  while result < x.len and x[result] in Whitespace:
    inc result
type
  LspEndpointObj = object of RootObj
    process*: AsyncProcess
    id*: int
  LspEndpoint* = ref LspEndpointObj

proc start*(self: LspEndpoint) = discard
proc stop*(self: LspEndpoint) = discard
template sendNotification*(self: LspEndpoint, noti: string): string = ""
template sendNotification*(self: LspEndpoint, `method`: string, params: typed): string = ""
template callMethod*(self: LspEndpoint, `method`: string): string = ""
template callMethod*(self: LspEndpoint, `method`: string, params: typed): string = ""

proc readMessage*(self: LspEndpoint): Future[string] {.async.} =
  var contentLen = -1
  var headerStarted = false

  let input = asyncPipeInput(self.process.outputHandle)
  while input.readable:
    let ln = await input.readLine()
    if ln.len != 0:
      headerStarted = true
      let sep = ln.find(':')
      if sep == -1:
        raise newException(MalformedFrame, "invalid header line: " & ln)

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
        discard
    elif not headerStarted:
      continue
    else:
      if contentLen != -1:
        result = cast[string](input.read(contentLen))
        when defined(debugCommunication):
          stderr.write(result)
          stderr.write("\n")
          return result
        else:
          return result
      else:
        raise newException(MalformedFrame, "missing Content-Length header")
