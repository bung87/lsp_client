include lsp_client
include lsp_client / nim_lsp_endpoint
import jsonschema
import os


jsonSchema:
  ClientInfo:
    name: string
    version ?: string

let endPoint = LspNimEndpoint()
let client = newLspClient(endPoint)

echo client.initialize(
      initializationOptions = some(create(ClientInfo, name = "moe", version = some("0.2.0"))),
      processId = getCurrentProcessId(),
      rootPath = none(string),
      rootUri = "/home/fox/git/moe",
      capabilities = create(ClientCapabilities,
        workspace = none(WorkspaceClientCapabilities),
        textDocument = none(TextDocumentClientCapabilities),
        window = none(WindowClientCapabilities),
        experimental = none(JsonNode)
  ),
  trace = none(string),
  workspaceFolders = none(seq[WorkspaceFolder]))
