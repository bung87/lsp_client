import ./lsp_types
import asynctools, asyncdispatch, os, strutils, asyncnet

from osproc import execCmd

type LspNimEndpoint* = ref object of LspEndpoint
  process: AsyncProcess

# proc respond(request: RequestMessage, data: JsonNode) =
#   outs.sendJson create(ResponseMessage, "2.0", parseId(request["id"]), some(data), none(ResponseError)).JsonNode

# proc error(request: RequestMessage, errorCode: int, message: string, data: JsonNode) =
#   outs.sendJson create(ResponseMessage, "2.0", parseId(request["id"]), none(JsonNode), some(create(ResponseError, errorCode, message, data))).JsonNode

# proc notify(notification: string, data: JsonNode) =
#   outs.sendJson create(NotificationMessage, "2.0", notification, some(data)).JsonNode

proc start*(self: LspNimEndpoint) =
  self.process = startProcess(findExe("nimlsp"))
proc stop*(self: LspNimEndpoint) = discard
proc sendNotification*(self: LspNimEndpoint, noti: string) = discard
template callMethod*(self: LspNimEndpoint) = discard
