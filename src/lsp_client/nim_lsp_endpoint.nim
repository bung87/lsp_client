import ./lsp_types
import asynctools, asyncdispatch, os, strutils, asyncnet
import nim_jsonrpc_protocol
from osproc import execCmd
import json

type LspNimEndpoint* = ref object of LspEndpoint

proc start*(self: LspNimEndpoint) =
  self.process = startProcess(findExe("nimlsp"))
proc stop*(self: LspNimEndpoint) = discard
proc sendNotification*(self: LspNimEndpoint, noti: string) = discard

proc callMethod*[T](self: LspNimEndpoint,`method`:string,params:T){.multiSync.} = 
  if not isValid(params,type params):
    raise newException(ValueError)
  let id = self.id
  inc self.id
  let jo = initGRequest(id=id,`method`= `method`,params=params)
  
  let str = % jo
  var msg = "Content-Length: " & $str.len & "\r\n\r\n" & str
  await self.process.inputHandle.write(msg.addr,msg.len)
  await self.readMessage()
