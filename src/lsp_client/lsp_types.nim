import asynctools, asyncdispatch, faststreams/asynctools_adapters, faststreams/textio
import strutils, parseutils, json
import oop_utils/standard_class

type
  BaseProtocolError* = object of Defect

  MalformedFrame* = object of BaseProtocolError
  UnsupportedEncoding* = object of BaseProtocolError

proc skipWhitespace(x: string, pos: int): int =
  result = pos
  while result < x.len and x[result] in Whitespace:
    inc result
# type
#   LspEndpointObj = object of RootObj
#     process*: AsyncProcess
#     id*: int
#   LspEndpoint* = ref LspEndpointObj
class(LspEndpoint):
  ctor(newLspEndpoint) proc() =
    self:
      id = 0
      process = default(AsyncProcess)

  method start*() {.base.} = discard
  method setProcess*(p: AsyncProcess) = self.process = p
  method stop*() {.base.} = discard
  method sendNotification*(noti: string): Future[string]{.base.} # = ""
  method sendNotification*[T](`method`: string, params: T): Future[string]{.base.} # = ""
  method callMethod*(`method`: string): Future[string] {.base.} # = ""
  method callMethod*[T](`method`: string, params: T): Future[string] {.base.} #= ""

  method readMessage*(): Future[string] {.async.} =
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
          let s = `@`(input.read(contentLen))
          result = cast[string](s)
          when defined(debugCommunication):
            stderr.write(result)
            stderr.write("\n")
            return result
          else:
            return result
        else:
          raise newException(MalformedFrame, "missing Content-Length header")
