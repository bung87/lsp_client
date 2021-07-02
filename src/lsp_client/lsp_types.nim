type 
  LspEndpointObj = object of RootObj
  LspEndpoint* = ref LspEndpointObj

proc start*(self:LspEndpoint) = discard
proc stop*(self:LspEndpoint)= discard
proc sendNotification*(self:LspEndpoint,noti:string)= discard
template callMethod*(self:LspEndpoint)= discard