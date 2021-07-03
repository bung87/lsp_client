import ./lsp_types
import asynctools, asyncdispatch, os, strutils, asyncnet
import nim_jsonrpc_protocol
from osproc import execCmd
import json
import oop_utils/standard_class
# type LspNimEndpoint* = ref object of LspEndpoint
class(LspNimEndpoint of LspEndpoint):
  # ctor(newLspNimEndpoint) proc() =
  #   self:
  #     id = 0
  #     process = default(AsyncProcess)

  method start*() =
    self.setProcess startProcess(findExe("nimlsp"))
  method stop*() = discard

  method sendNotification*(noti: string): Future[string]{.async.} #= ""
  method sendNotification*[T](`method`: string, params: T): Future[string]{.async.}
  # template callMethod*(self: LspEndpoint,`method`:string):string = ""
  # template callMethod*(self: LspEndpoint,`method`:string,params:typed):string = ""

  method callMethod*[T](`method`: string, params: T){.async.} =
    # if not isValid(params,type params):
    #   raise newException(ValueError)
    let id = self.id
    inc self.id
    let jo = initGRequest(id = id, `method` = `method`, params = params)

    let str = % jo
    var msg = "Content-Length: " & $str.len & "\r\n\r\n" & str
    await self.process.inputHandle.write(msg.addr, msg.len)
    await self.readMessage()
