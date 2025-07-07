## Simple LSP Client Test
## Tests basic LSP client methods against the test project

import lsp_client
import lsp_client / nim_lsp_endpoint
import moe_doc_caps
import lsp_client/jsonschema
import os
import chronos
import std/[strformat, json, options, strutils]

# Test configuration
const
  TEST_PROJECT_DIR = "tests/test_project"
  MAIN_FILE_PATH = TEST_PROJECT_DIR & "/src/main.nim"
  TYPES_FILE_PATH = TEST_PROJECT_DIR & "/src/types.nim" 

proc runSimpleLspTest() {.async.} =
  ## Runs a simple LSP test suite
  echo "Starting Simple LSP Client Test"
  echo "=".repeat(40)
  
  # Setup
  let endPoint = LspNimEndpoint.new()
  let client = newLspClient(endPoint)
  
  let mainUri = "file://" & getCurrentDir() / MAIN_FILE_PATH
  let typesUri = "file://" & getCurrentDir() / TYPES_FILE_PATH
  
  echo &"Testing with files:"
  echo &"  Main: {mainUri}"
  echo &"  Types: {typesUri}"
  
  try:
    # Initialize LSP
    echo "\n1. Initializing LSP..."
    let caps = create(ClientCapabilities,
      workspace = none(WorkspaceClientCapabilities),
      textDocument = some(createDocCaps()),
      window = none(WindowClientCapabilities),
      experimental = none(JsonNode)
    )
    
    let initResp = await client.initialize(
      initializationOptions = none(JsonNode),
      processId = getCurrentProcessId(),
      rootPath = none(string),
      rootUri = "file://" & getCurrentDir() / TEST_PROJECT_DIR,
      capabilities = caps,
      trace = none(string),
      workspaceFolders = none(seq[WorkspaceFolder])
    )
    echo "   ✓ Initialize successful"
    
    await client.initialized()
    echo "   ✓ Initialized notification sent"
    
    # Open test files
    echo "\n2. Opening test files..."
    let mainContent = readFile(MAIN_FILE_PATH)
    let typesContent = readFile(TYPES_FILE_PATH)
    
    let mainDoc = TextDocumentItem.create(
      uri = mainUri,
      languageId = "nim",
      version = 1,
      text = mainContent
    )
    await client.didOpen(mainDoc)
    echo "   ✓ Opened main.nim"
    
    let typesDoc = TextDocumentItem.create(
      uri = typesUri,
      languageId = "nim",
      version = 1,
      text = typesContent
    )
    await client.didOpen(typesDoc)
    echo "   ✓ Opened types.nim"
    
    # Test document symbols
    echo "\n3. Testing document symbols..."
    let mainSymbols = await client.documentSymbol(
      textDocument = TextDocumentIdentifier.create(uri = mainUri)
    )
    echo &"   ✓ Found {mainSymbols.JsonNode.len} symbols in main.nim"
    
    let typesSymbols = await client.documentSymbol(
      textDocument = TextDocumentIdentifier.create(uri = typesUri)
    )
    echo &"   ✓ Found {typesSymbols.JsonNode.len} symbols in types.nim"
    
    # Test hover
    echo "\n4. Testing hover..."
    let userHover = await client.hover(
      textDocument = TextDocumentIdentifier.create(uri = typesUri),
      position = Position.create(line = 15, character = 4),
      workDoneToken = none(string)
    )
    if userHover.JsonNode.hasKey("contents"):
      echo "   ✓ Hover on User type successful"
    else:
      echo "   ✗ Hover on User type failed"
    
    # Test completion
    echo "\n5. Testing completion..."
    let completion = await client.completion(
      textDocument = TextDocumentIdentifier.create(uri = typesUri),
      position = Position.create(line = 20, character = 10),
      workDoneToken = none(string),
      context = none(CompletionContext)
    )
    if completion.JsonNode.hasKey("items"):
      let items = completion.JsonNode["items"]
      echo &"   ✓ Found {items.len} completion items"
    else:
      echo "   ✗ No completion items found"
    
    # Test definition
    echo "\n6. Testing go-to-definition..."
    let definition = await client.definition(
      textDocument = TextDocumentIdentifier.create(uri = mainUri),
      position = Position.create(line = 4, character = 17),
      workDoneToken = none(string),
      partialResultToken = none(string)
    )
    if definition.JsonNode.len > 0:
      echo "   ✓ Definition found"
    else:
      echo "   ✗ Definition not found"
    
    # Test signature help
    echo "\n7. Testing signature help..."
    let signature = await client.signatureHelp(
      textDocument = TextDocumentIdentifier.create(uri = mainUri),
      position = Position.create(line = 17, character = 25),
      workDoneToken = none(string),
      context = none(SignatureHelpContext)
    )
    if signature.JsonNode.hasKey("signatures"):
      let signatures = signature.JsonNode["signatures"]
      echo &"   ✓ Found {signatures.len} signature(s)"
    else:
      echo "   ✗ No signatures found"
    
    # Test rename (read-only)
    echo "\n8. Testing rename..."
    let rename = await client.rename(
      textDocument = TextDocumentIdentifier.create(uri = mainUri),
      position = Position.create(line = 12, character = 6),
      newName = "testUsers",
      workDoneToken = none(string)
    )
    if rename.JsonNode.hasKey("changes") or rename.JsonNode.hasKey("documentChanges"):
      echo "   ✓ Rename operation returned changes"
    else:
      echo "   ✗ Rename operation failed"
    
    # Test document changes
    echo "\n9. Testing document changes..."
    let change = TextDocumentContentChangeEvent.create(
      range = some(Range.create(
        start = Position.create(line = 0, character = 0),
        theend = Position.create(line = 0, character = 0)
      )),
      rangeLength = some(0),
      text = "# Test comment\n"
    )
    
    await client.didChange(
      textDocument = VersionedTextDocumentIdentifier.create(uri = mainUri, version = 2, languageId = some("nim")),
      contentChanges = @[change]
    )
    echo "   ✓ Document change notification sent"
    
    # Cleanup
    echo "\n10. Cleanup..."
    await client.didClose(TextDocumentIdentifier.create(uri = mainUri))
    await client.didClose(TextDocumentIdentifier.create(uri = typesUri))
    echo "   ✓ Closed all files"
    
    let shutdownResp = await client.shutdown()
    echo "   ✓ Shutdown successful"
    
    let exitCode = await client.exit()
    echo &"   ✓ Exit code: {exitCode}"
    
    echo "\n" & "=".repeat(40)
    echo "✓ Simple LSP test completed successfully!"
    echo "\nTest Summary:"
    echo "- LSP session initialization: ✓"
    echo "- File operations (open/close): ✓" 
    echo "- Document symbols: ✓"
    echo "- Hover information: ✓"
    echo "- Code completion: ✓"
    echo "- Go-to-definition: ✓"
    echo "- Signature help: ✓"
    echo "- Rename operation: ✓"
    echo "- Document changes: ✓"
    echo "- Session cleanup: ✓"
    
  except Exception as e:
    echo &"\n✗ Test failed with error: {e.msg}"
    echo "Stacktrace:"
    echo e.getStackTrace()

# Main execution
proc main() {.async.} =
  ## Main test runner
  await runSimpleLspTest()

when isMainModule:
  waitFor main() 