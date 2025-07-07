import lsp_client
import lsp_client / nim_lsp_endpoint
import lsp_client/jsonschema
import os
import chronos
import moe_doc_caps

jsonSchema:
  ClientInfo:
    name: string
    version ?: string

let endPoint = LspNimEndpoint.new()
let client = newLspClient(endPoint)

let caps = create(ClientCapabilities,
        workspace = none(WorkspaceClientCapabilities),
        textDocument = some(createDocCaps()),
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
echo "initialize:\n", resp.JsonNode
waitFor client.initialized()
echo "initialized:\n"
let resp2 = waitFor client.shutdown()
echo resp2.JsonNode
echo waitFor client.exit()
