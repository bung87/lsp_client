include lsp_client
include lsp_client / nim_lsp_endpoint
import jsonschema
import os
import asyncdispatch

jsonSchema:
  ClientInfo:
    name: string
    version ?: string

let endPoint = newLspNimEndpoint()
let client = newLspClient(endPoint)
let caps = create(ClientCapabilities,
        workspace = none(WorkspaceClientCapabilities),
        textDocument = none(TextDocumentClientCapabilities),
        window = none(WindowClientCapabilities),
        experimental = none(JsonNode))

echo "initialize:\n", waitFor client.initialize(
      initializationOptions = some(create(ClientInfo, name = "moe", version = some("0.2.0"))),
      processId = getCurrentProcessId(),
      rootPath = none(string),
      rootUri = "file://" & currentSourcePath,
      capabilities = caps,
  trace = none(string),
  workspaceFolders = none(seq[WorkspaceFolder]))
echo "initialized:\n", waitFor client.initialized()
