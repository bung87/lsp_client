import ./lsp_types
import asynctools, asyncdispatch, os, strutils, asyncnet
import nim_jsonrpc_protocol
from osproc import execCmd
import json
import oop_utils/standard_class

class(LspNimEndpoint of LspEndpoint):
  ctor(newLspNimEndpoint)
  method start*() =
    self.setProcess startProcess(findExe("nimlsp"), options = {})
  method stop*() = discard

  method sendNotification*(noti: string): Future[string]{.async.} #= ""
  method sendNotification*[T](`method`: string, params: T): Future[string]{.async.}

  method callMethod*[T](`method`: string, params: T): Future[string]{.async.} =
    # if not isValid(cast[JsonNode](params),typedesc[type params]):
    #   raise newException(ValueError)
    let id = self.getId()
    self.incId()
    let jo = initGRequest(id = id, `method` = `method`, params = cast[JsonNode](params))

    let str = $ % jo
    var msg: string = "Content-Type: application/vscode-jsonrpc; charset=utf-8\r\n"
    msg = msg & "Content-Length: " & $str.len & "\r\n\r\n" & str
    debugEcho repr msg

    let written = await self.write(msg.addr, msg.len)
    doAssert written == msg.len
    echo await self.readError()
    result = await self.readMessage()
    echo result
