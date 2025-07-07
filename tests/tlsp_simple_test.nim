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
  TEST_PROJECT_DIR = currentSourcePath.parentDir() / "test_project"
  MAIN_FILE_PATH = TEST_PROJECT_DIR / "src/main.nim"
  TYPES_FILE_PATH = TEST_PROJECT_DIR / "src/types.nim" 

proc runSimpleLspTest() {.async.} =
  ## Runs a simple LSP test suite
  echo "Starting Simple LSP Client Test"
  echo "=".repeat(40)
  
  # Setup
  let endPoint = LspNimEndpoint.new()
  let client = newLspClient(endPoint)
  
  let mainUri = "file://" & MAIN_FILE_PATH
  let typesUri = "file://" & TYPES_FILE_PATH
  
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
      rootUri = "file://" & TEST_PROJECT_DIR,
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
    doAssert mainSymbols["result"].isSome and mainSymbols["result"].get.len > 0, "Should find symbols in main.nim"
    echo &"   ✓ Found {mainSymbols[\"result\"].get.len} symbols in main.nim"
    
    let typesSymbols = await client.documentSymbol(
      textDocument = TextDocumentIdentifier.create(uri = typesUri)
    )
    doAssert typesSymbols["result"].isSome and typesSymbols["result"].get.len > 0, "Should find symbols in types.nim"
    echo &"   ✓ Found {typesSymbols[\"result\"].get.len} symbols in types.nim"
    
    # Test hover
    echo "\n4. Testing hover..."
    let userHover = await client.hover(
      textDocument = TextDocumentIdentifier.create(uri = typesUri),
      position = Position.create(line = 14, character = 4),
      workDoneToken = none(string)
    )
    doAssert userHover["result"].isSome, "Hover on User type should return a result"
    let hoverData = userHover["result"].get
    doAssert hoverData.hasKey("contents"), "Hover result should have contents"
    echo "   ✓ Hover on User type successful"
    
    # Test completion
    echo "\n5. Testing completion..."
    let completion = await client.completion(
      textDocument = TextDocumentIdentifier.create(uri = typesUri),
      position = Position.create(line = 20, character = 10),
      workDoneToken = none(string),
      context = none(CompletionContext)
    )
    doAssert completion["result"].isSome, "Completion should return a result"
    let completionData = completion["result"].get
    var itemCount = 0
    if completionData.kind == JObject and completionData.hasKey("items"):
      itemCount = completionData["items"].len
      let isIncomplete = completionData["isIncomplete"].getBool()
      echo &"   ✓ Found {itemCount} completion items (incomplete: {isIncomplete})"
    elif completionData.kind == JArray:
      itemCount = completionData.len
      echo &"   ✓ Found {itemCount} completion items"
    doAssert itemCount > 0, "Should find completion items"
    
    # Test definition
    echo "\n6. Testing go-to-definition..."
    let definition = await client.definition(
      textDocument = TextDocumentIdentifier.create(uri = mainUri),
      position = Position.create(line = 4, character = 17),
      workDoneToken = none(string),
      partialResultToken = none(string)
    )
    doAssert definition["result"].isSome and definition["result"].get.len > 0, "Should find definition"
    echo &"   ✓ Found {definition[\"result\"].get.len} definition location(s)"
    
    # Test signature help
    echo "\n7. Testing signature help..."
    let signature = await client.signatureHelp(
      textDocument = TextDocumentIdentifier.create(uri = mainUri),
      position = Position.create(line = 17, character = 25),
      workDoneToken = none(string),
      context = none(SignatureHelpContext)
    )
    doAssert signature["result"].isSome, "Signature help should return a result"
    let signatureData = signature["result"].get
    if signatureData.kind != JNull and signatureData.hasKey("signatures"):
      let signatures = signatureData["signatures"]
      echo &"   ✓ Found {signatures.len} signature(s)"
      if signatureData.hasKey("activeSignature") and signatureData["activeSignature"].kind != JNull:
        echo &"     Active signature: {signatureData[\"activeSignature\"].getInt()}"
      if signatureData.hasKey("activeParameter") and signatureData["activeParameter"].kind != JNull:
        echo &"     Active parameter: {signatureData[\"activeParameter\"].getInt()}"
    else:
      echo "   ⚠ No signatures available (null result)"
    
    # Test rename (read-only)
    echo "\n8. Testing rename..."
    let rename = await client.rename(
      textDocument = TextDocumentIdentifier.create(uri = mainUri),
      position = Position.create(line = 12, character = 6),
      newName = "testUsers",
      workDoneToken = none(string)
    )
    doAssert rename["result"].isSome, "Rename should return a result"
    let renameData = rename["result"].get
    doAssert renameData.hasKey("changes") or renameData.hasKey("documentChanges"), "Rename should return changes or documentChanges"
    echo "   ✓ Rename operation returned changes"
    
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
    echo "✅ All LSP tests passed successfully!"
    
  except Exception as e:
    echo &"\n✗ Test failed with error: {e.msg}"
    echo "Stacktrace:"
    echo getStackTrace(e)

# Run the test when this module is executed
when isMainModule:
  waitFor runSimpleLspTest() 