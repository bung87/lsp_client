import ./lsp_types
import asynctools, asyncdispatch, os, strutils, asyncnet

from osproc import execCmd

type LspNimEndpoint* = ref object of LspEndpoint
  process: AsyncProcess

proc start*(self: LspNimEndpoint) =
  self.process = startProcess(findExe("nimlsp"))
proc stop*(self: LspNimEndpoint) = discard
proc sendNotification*(self: LspNimEndpoint, noti: string) = discard
template callMethod*(self: LspNimEndpoint) = discard
