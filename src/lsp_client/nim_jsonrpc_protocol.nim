import strutils
import sequtils
import macros
import typetraits
import json

const CRLF = "\r\n"
const JSONRPC_VERSION = "2.0"

type
  GRequest*[I: int|string|void = int, P] = object
    jsonrpc: string
    `method`: string
    id: I
    params: P # omitted


  Request*[T] = concept o, type M
    o.jsonrpc is string
    o.method is string
    type TransposedType = stripGenericParams(M)[T]
    o is TransposedType
    o.id is string or o.id is SomeNumber
    o.params is T or void # omitted

  BatchRequest* = seq[JsonNode]

  Response* = concept o
    o.jsonrpc is string
    o.method is string
    o.id is string or o.id is SomeNumber

  SuccessResponse* = concept o of Response
    o.result is string

  Error*[T] = concept o
    o.code is SomeNumber
    o.message is string
    o.data is T or void # omitted

  ErrorResponse* = concept o of Response
    o.error is Error
    o.id is string or o.id is SomeNumber
    o.jsonrpc is string

  GErrorResponse[I: int|string, T] = object
    error: T
    id: I
    jsonrpc: string

  ServerError* = range[32000..32099]

proc camelCase(label: string): string =
  let tokens = label.split(" ")
  result = tokens[0].toLowerAscii & tokens[1..^1].mapIt(capitalizeAscii(it)).join("")

macro errdef*(name: untyped, val: typed): untyped =
  let constName = ident(camelCase(name.repr))
  # let cmt = newCommentStmtNode(name.repr)
  quote:
    const `constName`* = `val`

# http://xmlrpc-epi.sourceforge.net/specs/rfc.fault_codes.php

errdef(Parse Error, -32700)
errdef(Invalid Request, -32600)
errdef(Method Not Found, -32601)
errdef(Invalid Params, -32602)
errdef(Internal Error, -32603)

# Defined by JSON RPC
# https://microsoft.github.io/language-server-protocol/specification
errdef(Server Error Start, -32099)
errdef(Server Error End, -32000)
errdef(Server Not Initialized, -32002)
errdef(Unknown Error Code, -32001)

proc initGErrorResponse*[P: int|string, T](id: P, error: T, jsonrpc = JSONRPC_VERSION): GErrorResponse[P, T] =
  result.id = id
  result.jsonrpc = jsonrpc
  result.error = error

proc jErrorResponse*[T, P: int|string](id: P, error: openarray[T], jsonrpc = JSONRPC_VERSION): JsonNode{.noInit.} =
  result = newJObject()
  result["id"] = %id
  result["jsonrpc"] = %jsonrpc
  result["error"] = %error

template jErrorResponse*[P: int|string](id: P, jsonrpc = JSONRPC_VERSION, error: untyped): untyped =
  let result = newJObject()
  result["id"] = %id
  result["jsonrpc"] = %jsonrpc
  result["error"] = %*error
  result

proc initGRequest*[P: int|string, T](id: P, `method`: string, params: T, jsonrpc = JSONRPC_VERSION): GRequest[P, T] =
  result.id = id
  result.method = `method`
  result.jsonrpc = jsonrpc
  result.params = params

proc initGRequest*[P: int|string](id: P, `method`: string, jsonrpc = JSONRPC_VERSION): GRequest[P, void] =
  result.id = id
  result.method = `method`
  result.jsonrpc = jsonrpc

proc initGRequest*(`method`: string, jsonrpc = JSONRPC_VERSION): GRequest[void, void] =
  result.method = `method`
  result.jsonrpc = jsonrpc

proc initGRequest*[T](`method`: string, params: T, jsonrpc = JSONRPC_VERSION): GRequest[void, T] =
  result.method = `method`
  result.jsonrpc = jsonrpc
  result.params = params

proc jRequest*[P: int|string](id: P, `method`: string, jsonrpc = JSONRPC_VERSION): JsonNode{.noInit.} =
  result = newJObject()
  result["id"] = %id
  result["method"] = %`method`
  result["jsonrpc"] = %jsonrpc

template jRequest*[P: int|string](id: P, `method`: string, params: untyped, jsonrpc = JSONRPC_VERSION): untyped =
  let result = newJObject()
  result["id"] = %id
  result["method"] = %`method`
  result["jsonrpc"] = %jsonrpc
  result["params"] = %*params
  result

proc `$`*(self: var BatchRequest): string =
  self.join(CRLF)

when isMainModule:
  assert parseError == -32700
  type RP = object
    subtrahend: int
    bar: string

  let rp = RP(subtrahend: 1, bar: "baz")
  let c = GRequest[int, RP](id: 1, `method`: "aaa", params: rp, jsonrpc: "2.0")
  const ec = """{"jsonrpc":"2.0","method":"aaa","id":1,"params":{"subtrahend":1,"bar":"baz"}}"""
  assert $(%c) == ec

  let f = initGRequest(id = 1, `method` = "aaa", params = rp)
  assert $(%f) == ec

  let d = jRequest(id = 1, `method` = "aaa", params = ["a", "b"])
  const dc = """{"id":1,"method":"aaa","jsonrpc":"2.0","params":["a","b"]}"""
  assert $d == dc

  echo jRequest(id = 1, `method` = "aaa", params = {"name": "Isaac", "books": ["Robot Dreams", 1]})

  let g = jRequest(id = 1, `method` = "aaa")

  let j = jRequest(id = 1, `method` = "aaa")

  var b: BatchRequest = @[]

  b.add g
  b.add j

  let bc = @[g, j]

  echo b

