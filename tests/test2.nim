include lsp_client
include lsp_client / nim_lsp_endpoint
import jsonschema
import os
import chronos
include moe_doc_caps

jsonSchema:
  ClientInfo:
    name: string
    version ?: string

let endPoint = LspNimEndpoint.new()
let client = newLspClient(endPoint)

let caps = create(ClientCapabilities,
        workspace = none(WorkspaceClientCapabilities),
        textDocument = some(docCaps),
        window = none(WindowClientCapabilities),
        experimental = none(JsonNode))

let resp = waitFor client.initialize(
      initializationOptions = some(create(ClientInfo, name = "moe", version = some("0.2.0"))),
      processId = getCurrentProcessId(),
      rootPath = none(string),
      rootUri = "file://" & currentSourcePath,
      capabilities = caps,
  trace = none(string),
  workspaceFolders = none(seq[WorkspaceFolder]))
echo "initialize:\n"
waitFor client.initialized()
echo "initialized:\n"
const currentSource = staticRead(currentSourcepath)
const uri = "file://" & currentSourcePath
let current = TextDocumentItem.create(uri = uri, languageId = "nim", version = 1, text = currentSource)
waitFor client.didOpen(current)
let symbolResp = waitFor client.documentSymbol(textDocument = TextDocumentIdentifier.create(uri = "file://" &
    currentSourcePath))

echo symbolResp.JsonNode
waitFor client.didClose(TextDocumentIdentifier.create(uri = uri))

let resp2 = waitFor client.shutdown()

echo waitFor client.exit()
