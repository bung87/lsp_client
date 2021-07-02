import ./lsp_types

type LspNimEndpoint* =  LspEndpoint


proc start*(self:LspNimEndpoint)= discard
proc stop*(self:LspNimEndpoint)= discard
proc sendNotification*(self:LspNimEndpoint,noti:string)= discard
template callMethod*(self:LspNimEndpoint)= discard