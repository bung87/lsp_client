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
      input = default(AsyncInputStream)
      output = default(AsyncOutputStream)
      err = default(AsyncInputStream)

  method start*() {.base.} # = discard
  method setProcess*(p: AsyncProcess) =
    self.process = p
    self.input = asyncPipeInput(self.process.outputHandle)
    self.output = asyncPipeOutput(self.process.inputHandle)
    self.err = asyncPipeInput(self.process.errorHandle)
  method getId*(): int = self.id
  method incId*() = inc self.id
  # method write*(s:string):Future[int] {.async.} = result = await self.output.write(s)
  method write*(p: pointer, len: int): Future[int] {.async.} = result = await self.process.inputHandle.write(p, len)
  method stop*() {.base.} # = discard
  method sendNotification*(noti: string): Future[string]{.base.} # = ""
  method sendNotification*[T](`method`: string, params: T): Future[string]{.base.} # = ""
  method callMethod*(`method`: string): Future[string] {.base.} # = ""
  method callMethod*[T](`method`: string, params: T): Future[string] {.base.} #= ""
  method readError*(): Future[string]{.async.} =
    while self.err.readable:
      let s = await self.err.readLine()
      result = result & s & "\n"

  method readMessage*(): Future[string] {.async.} =
    # Note: nimlsp debug build will produce debug info to stdout
    var contentLen = -1
    var headerStarted = false

    # let input = asyncPipeInput(self.process.outputHandle)
    while self.input.readable:
      let ln = await self.input.readLine()
      debugEcho ln
      if ln.len != 0:
        let sep = ln.find(':')
        if sep == -1:
          continue

          # raise newException(MalformedFrame, "invalid header line: " & repr ln)

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
          let s = `@`(self.input.read(contentLen))
          result = cast[string](s)
          echo result
          when defined(debugCommunication):
            stderr.write(result)
            stderr.write("\n")
            return result
          else:
            return result
        else:
          raise newException(MalformedFrame, "missing Content-Length header")
