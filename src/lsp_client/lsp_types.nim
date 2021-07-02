type 
  LspEndpointObj = object of RootObj
  LspEndpoint* = ref LspEndpointObj

proc start*(self:LspEndpoint)
proc stop*(self:LspEndpoint)
proc sendNotification*(self:LspEndpoint,noti:string)
template callMethod*(self:LspEndpoint)