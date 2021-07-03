import ./lsp_types
import asynctools, asyncdispatch, os, strutils, asyncnet
import nim_jsonrpc_protocol
from osproc import execCmd
import json
import oop_utils/standard_class

class(LspNimEndpoint of LspEndpoint):
  ctor(newLspNimEndpoint)
  method start*() =
    self.setProcess startProcess(findExe("nimlsp"), options = {poDemon})
  method stop*() = discard

  method roundtrip*(str: string): Future[string]{.async.} =
    var msg: string = "Content-Type: application/vscode-jsonrpc; charset=utf-8\r\n"
    msg = msg & "Content-Length: " & $str.len & "\r\n\r\n" & str
    debugEcho repr msg

    let written = await self.write(msg[0].addr, msg.len)
    doAssert written == msg.len
    echo await self.readError()
    result = await self.readMessage()

  method send*(str: string): Future[void]{.async.} =
    var msg: string = "Content-Type: application/vscode-jsonrpc; charset=utf-8\r\n"
    msg = msg & "Content-Length: " & $str.len & "\r\n\r\n" & str
    debugEcho repr msg

    let written = await self.write(msg[0].addr, msg.len)
    doAssert written == msg.len
    echo await self.readError()

  method sendNotification*(`method`: string): Future[void]{.async.} =
    let id = self.getId()
    self.incId()
    let jo = initGRequest(id = id, `method` = `method`)
    let str = $ % jo
    await self.send(str)

  method sendNotification*[T](`method`: string, params: T): Future[void]{.async.}

  method callMethod*[T](`method`: string, params: T): Future[string]{.async.} =
    # if not isValid(cast[JsonNode](params),typedesc[type params]):
    #   raise newException(ValueError)
    let id = self.getId()
    self.incId()
    let jo = initGRequest(id = id, `method` = `method`, params = cast[JsonNode](params))
    let str = $ % jo
    result = await self.roundtrip(str)

  method callMethod*(`method`: string): Future[string]{.async.} =
    # if not isValid(cast[JsonNode](params),typedesc[type params]):
    #   raise newException(ValueError)
    let id = self.getId()
    self.incId()
    let jo = initGRequest(id = id, `method` = `method`)
    let str = $ % jo
    result = await self.roundtrip(str)
