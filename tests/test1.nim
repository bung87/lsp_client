import lsp_client
import lsp_client / nim_lsp_endpoint

let endPoint = LspNimEndpoint()
let client = newLspClient(endPoint)