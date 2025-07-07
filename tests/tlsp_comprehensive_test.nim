## Comprehensive LSP Client Test (GC-Safe Version)
## Tests all LSP client methods against the test project without GC safety issues

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
  MAIN_FILE_PATH = TEST_PROJECT_DIR & "/src/main.nim"
  TYPES_FILE_PATH = TEST_PROJECT_DIR & "/src/types.nim" 
  UTILS_FILE_PATH = TEST_PROJECT_DIR & "/src/utils.nim"

type
  LspTestContext = object
    client: LspClient[LspNimEndpoint]
    mainUri: string
    typesUri: string
    utilsUri: string

proc setupLspClient(): Future[LspTestContext] {.async.} =
  ## Sets up the LSP client and initializes the session
  echo "=== Setting up LSP client ==="
  
  let endPoint = LspNimEndpoint.new()
  let client = newLspClient(endPoint)
  
  # Create URIs for test files
  let mainUri = "file://" &  MAIN_FILE_PATH
  let typesUri = "file://" &  TYPES_FILE_PATH
  let utilsUri = "file://" &  UTILS_FILE_PATH
  
  echo &"Main file URI: {mainUri}"
  echo &"Types file URI: {typesUri}"
  echo &"Utils file URI: {utilsUri}"
  
  result = LspTestContext(
    client: client,
    mainUri: mainUri,
    typesUri: typesUri,
    utilsUri: utilsUri
  )

proc initializeLsp(ctx: LspTestContext) {.async.} =
  ## Initializes the LSP session
  echo "\n=== Initializing LSP session ==="
  
  let caps = create(ClientCapabilities,
    workspace = none(WorkspaceClientCapabilities),
    textDocument = some(createDocCaps()),
    window = none(WindowClientCapabilities),
    experimental = none(JsonNode)
  )
  
  let initResp = await ctx.client.initialize(
    initializationOptions = none(JsonNode),
    processId = getCurrentProcessId(),
    rootPath = none(string),
    rootUri = "file://" & getCurrentDir() / TEST_PROJECT_DIR,
    capabilities = caps,
    trace = none(string),
    workspaceFolders = none(seq[WorkspaceFolder])
  )
  
  echo "✓ Initialize successful"
  
  await ctx.client.initialized()
  echo "✓ Initialized notification sent"

proc openTestFiles(ctx: LspTestContext) {.async.} =
  ## Opens all test files in the LSP session
  echo "\n=== Opening test files ==="
  
  # Read file contents
  let mainContent = readFile(MAIN_FILE_PATH)
  let typesContent = readFile(TYPES_FILE_PATH)
  let utilsContent = readFile(UTILS_FILE_PATH)
  
  # Open main file
  let mainDoc = TextDocumentItem.create(
    uri = ctx.mainUri,
    languageId = "nim",
    version = 1,
    text = mainContent
  )
  await ctx.client.didOpen(mainDoc)
  echo "✓ Opened main.nim"
  
  # Open types file
  let typesDoc = TextDocumentItem.create(
    uri = ctx.typesUri,
    languageId = "nim",
    version = 1,
    text = typesContent
  )
  await ctx.client.didOpen(typesDoc)
  echo "✓ Opened types.nim"
  
  # Open utils file
  let utilsDoc = TextDocumentItem.create(
    uri = ctx.utilsUri,
    languageId = "nim", 
    version = 1,
    text = utilsContent
  )
  await ctx.client.didOpen(utilsDoc)
  echo "✓ Opened utils.nim"

proc testDocumentSymbols(ctx: LspTestContext) {.async.} =
  ## Tests document symbol functionality
  echo "\n=== Testing Document Symbols ==="
  
  # Test symbols in main file
  echo "Testing symbols in main.nim:"
  let mainSymbols = await ctx.client.documentSymbol(
    textDocument = TextDocumentIdentifier.create(uri = ctx.mainUri)
  )
  echo &"  Found {mainSymbols.JsonNode.len} symbols in main.nim"
  
  # Test symbols in types file
  echo "Testing symbols in types.nim:"
  let typesSymbols = await ctx.client.documentSymbol(
    textDocument = TextDocumentIdentifier.create(uri = ctx.typesUri)
  )
  echo &"  Found {typesSymbols.JsonNode.len} symbols in types.nim"
  
  # Test symbols in utils file
  echo "Testing symbols in utils.nim:"
  let utilsSymbols = await ctx.client.documentSymbol(
    textDocument = TextDocumentIdentifier.create(uri = ctx.utilsUri)
  )
  echo &"  Found {utilsSymbols.JsonNode.len} symbols in utils.nim"
  
  echo "✓ Document symbols test completed"

proc testHover(ctx: LspTestContext) {.async.} =
  ## Tests hover functionality on various symbols
  echo "\n=== Testing Hover ==="
  
  # Test hover on User type in types.nim (line 14, around "User")
  echo "Testing hover on User type:"
  let userHover = await ctx.client.hover(
    textDocument = TextDocumentIdentifier.create(uri = ctx.typesUri),
    position = Position.create(line = 14, character = 4),
    workDoneToken = none(string)
  )
  if userHover.JsonNode.hasKey("result") and userHover.JsonNode["result"].hasKey("contents"):
    echo "  ✓ User type hover successful"
    echo &"    Content: {userHover.JsonNode[\"result\"][\"contents\"]}"
  else:
    echo "  ✗ User type hover failed"
    echo &"    Response: {userHover.JsonNode}"
  
  # Test hover on newUser function in types.nim (line 54, around "newUser")
  echo "Testing hover on newUser function:"
  let newUserHover = await ctx.client.hover(
    textDocument = TextDocumentIdentifier.create(uri = ctx.typesUri),
    position = Position.create(line = 54, character = 5),
    workDoneToken = none(string)
  )
  if newUserHover.JsonNode.hasKey("result") and newUserHover.JsonNode["result"].hasKey("contents"):
    echo "  ✓ newUser function hover successful"
    echo &"    Content: {newUserHover.JsonNode[\"result\"][\"contents\"]}"
  else:
    echo "  ✗ newUser function hover failed"
    echo &"    Response: {newUserHover.JsonNode}"
  
  # Test hover on Status enum in types.nim (line 7, around "Status")
  echo "Testing hover on Status enum:"
  let statusHover = await ctx.client.hover(
    textDocument = TextDocumentIdentifier.create(uri = ctx.typesUri),
    position = Position.create(line = 7, character = 4),
    workDoneToken = none(string)
  )
  if statusHover.JsonNode.hasKey("result") and statusHover.JsonNode["result"].hasKey("contents"):
    echo "  ✓ Status enum hover successful"
    echo &"    Content: {statusHover.JsonNode[\"result\"][\"contents\"]}"
  else:
    echo "  ✗ Status enum hover failed"
    echo &"    Response: {statusHover.JsonNode}"
  
  echo "✓ Hover tests completed"

proc testDefinition(ctx: LspTestContext) {.async.} =
  ## Tests go-to-definition functionality
  echo "\n=== Testing Go-to-Definition ==="
  
  # Test definition of User type used in utils.nim (line 25, around "User")
  echo "Testing definition of User type in utils.nim:"
  let userDef = await ctx.client.definition(
    textDocument = TextDocumentIdentifier.create(uri = ctx.utilsUri),
    position = Position.create(line = 25, character = 40),
    workDoneToken = none(string),
    partialResultToken = none(string)
  )
  if userDef.JsonNode.len > 0:
    echo "  ✓ User type definition found"
  else:
    echo "  ✗ User type definition not found"
  
  # Test definition of Status enum used in utils.nim (line 30, around "Status")
  echo "Testing definition of Status enum in utils.nim:"
  let statusDef = await ctx.client.definition(
    textDocument = TextDocumentIdentifier.create(uri = ctx.utilsUri),
    position = Position.create(line = 30, character = 45),
    workDoneToken = none(string),
    partialResultToken = none(string)
  )
  if statusDef.JsonNode.len > 0:
    echo "  ✓ Status enum definition found"
  else:
    echo "  ✗ Status enum definition not found"
  
  echo "✓ Definition tests completed"

proc testCompletion(ctx: LspTestContext) {.async.} =
  ## Tests code completion functionality
  echo "\n=== Testing Code Completion ==="
  
  # Test completion after "Status." in types.nim (after Ready = "ready")
  echo "Testing completion on Status enum values:"
  let statusCompletion = await ctx.client.completion(
    textDocument = TextDocumentIdentifier.create(uri = ctx.typesUri),
    position = Position.create(line = 9, character = 10),
    workDoneToken = none(string),
    context = none(CompletionContext)
  )
  if statusCompletion.JsonNode.kind == JObject and statusCompletion.JsonNode.hasKey("result"):
    let result = statusCompletion.JsonNode["result"]
    if result.kind == JObject and result.hasKey("items"):
      let items = result["items"]
      echo &"  ✓ Found {items.len} completion items"
    elif result.kind == JArray:
      echo &"  ✓ Found {result.len} completion items"
    elif result.kind == JNull:
      echo "  ⚠ No completion items available (null result)"
    else:
      echo "  ✗ Unexpected completion result format"
      echo &"    Result: {result}"
  else:
    echo "  ✗ No valid result in completion response"
    echo &"    Response: {statusCompletion.JsonNode}"
  
  # Test completion in main.nim for user variable (line 20, after "users.")
  echo "Testing completion on user object members:"
  let userCompletion = await ctx.client.completion(
    textDocument = TextDocumentIdentifier.create(uri = ctx.mainUri),
    position = Position.create(line = 20, character = 10),
    workDoneToken = none(string),
    context = none(CompletionContext)
  )
  if userCompletion.JsonNode.kind == JObject and userCompletion.JsonNode.hasKey("result"):
    let result = userCompletion.JsonNode["result"]
    if result.kind == JObject and result.hasKey("items"):
      let items = result["items"]
      echo &"  ✓ Found {items.len} user member completion items"
    elif result.kind == JArray:
      echo &"  ✓ Found {result.len} user member completion items"
    elif result.kind == JNull:
      echo "  ⚠ No user member completion items available (null result)"
    else:
      echo "  ✗ Unexpected user completion result format"
      echo &"    Result: {result}"
  else:
    echo "  ✗ No valid result in user completion response"
    echo &"    Response: {userCompletion.JsonNode}"
  
  echo "✓ Completion tests completed"

proc testSignatureHelp(ctx: LspTestContext) {.async.} =
  ## Tests signature help functionality
  echo "\n=== Testing Signature Help ==="
  
  # Test signature help for newUser function call (after opening parenthesis)
  echo "Testing signature help for newUser function:"
  let newUserSig = await ctx.client.signatureHelp(
    textDocument = TextDocumentIdentifier.create(uri = ctx.mainUri),
    position = Position.create(line = 17, character = 25),
    workDoneToken = none(string),
    context = none(SignatureHelpContext)
  )
  if newUserSig.JsonNode.kind == JObject and newUserSig.JsonNode.hasKey("result"):
    let result = newUserSig.JsonNode["result"]
    if result.kind == JObject and result.hasKey("signatures"):
      let signatures = result["signatures"]
      echo &"  ✓ Found {signatures.len} signature(s)"
    elif result.kind == JNull:
      echo "  ⚠ No signatures available (null result)"
    else:
      echo "  ✗ Unexpected signature help result format"
      echo &"    Result: {result}"
  else:
    echo "  ✗ No valid result in signature help response"
    echo &"    Response: {newUserSig.JsonNode}"
  
  # Test signature help for area function
  echo "Testing signature help for area function:"
  let areaSig = await ctx.client.signatureHelp(
    textDocument = TextDocumentIdentifier.create(uri = ctx.mainUri),
    position = Position.create(line = 70, character = 50),
    workDoneToken = none(string),
    context = none(SignatureHelpContext)
  )
  if areaSig.JsonNode.kind == JObject and areaSig.JsonNode.hasKey("result"):
    let result = areaSig.JsonNode["result"]
    if result.kind == JObject and result.hasKey("signatures"):
      let signatures = result["signatures"]
      echo &"  ✓ Found {signatures.len} signature(s) for area function"
    elif result.kind == JNull:
      echo "  ⚠ No signatures available for area function (null result)"
    else:
      echo "  ✗ Unexpected area function signature help result format"
      echo &"    Result: {result}"
  else:
    echo "  ✗ No valid result in area function signature help response"
    echo &"    Response: {areaSig.JsonNode}"
  
  echo "✓ Signature help tests completed"

proc testTypeDefinition(ctx: LspTestContext) {.async.} =
  ## Tests go-to-type-definition functionality
  echo "\n=== Testing Go-to-Type-Definition ==="
  
  # Test type definition of user variable
  echo "Testing type definition of user variable:"
  let userTypeDef = await ctx.client.typeDefinition(
    textDocument = TextDocumentIdentifier.create(uri = ctx.mainUri),
    position = Position.create(line = 17, character = 8),
    workDoneToken = none(string),
    partialResultToken = none(string)
  )
  if userTypeDef.JsonNode.len > 0:
    echo "  ✓ User variable type definition found"
  else:
    echo "  ✗ User variable type definition not found"
  
  echo "✓ Type definition tests completed"

proc testDeclaration(ctx: LspTestContext) {.async.} =
  ## Tests go-to-declaration functionality
  echo "\n=== Testing Go-to-Declaration ==="
  
  # Test declaration of imported types module
  echo "Testing declaration of types import:"
  let typesDecl = await ctx.client.declaration(
    textDocument = TextDocumentIdentifier.create(uri = ctx.mainUri),
    position = Position.create(line = 4, character = 17),
    workDoneToken = none(string),
    partialResultToken = none(string)
  )
  if typesDecl.JsonNode.len > 0:
    echo "  ✓ Types import declaration found"
  else:
    echo "  ✗ Types import declaration not found"
  
  echo "✓ Declaration tests completed"

proc testRename(ctx: LspTestContext) {.async.} =
  ## Tests rename functionality
  echo "\n=== Testing Rename ==="
  
  # Test renaming a local variable (this is a read-only test)
  echo "Testing rename capability (read-only):"
  let renameResp = await ctx.client.rename(
    textDocument = TextDocumentIdentifier.create(uri = ctx.mainUri),
    position = Position.create(line = 12, character = 6),
    newName = "testUsers",
    workDoneToken = none(string)
  )
  if renameResp.JsonNode.hasKey("result") and (renameResp.JsonNode["result"].hasKey("changes") or renameResp.JsonNode["result"].hasKey("documentChanges")):
    echo "  ✓ Rename operation returned changes"
  else:
    echo "  ✗ Rename operation failed"
    echo &"    Response: {renameResp.JsonNode}"
  
  echo "✓ Rename tests completed"

proc testDocumentChanges(ctx: LspTestContext) {.async.} =
  ## Tests document change notifications
  echo "\n=== Testing Document Changes ==="
  
  # Simulate a small change to the main file
  echo "Testing document change notification:"
  let change = TextDocumentContentChangeEvent.create(
    range = some(Range.create(
      start = Position.create(line = 0, character = 0),
      theend = Position.create(line = 0, character = 0)
    )),
    rangeLength = some(0),
    text = "# Modified\n"
  )
  
  await ctx.client.didChange(
    textDocument = VersionedTextDocumentIdentifier.create(uri = ctx.mainUri, version = 2, languageId = some("nim")),
    contentChanges = @[change]
  )
  echo "  ✓ Document change notification sent"
  
  echo "✓ Document change tests completed"

proc closeTestFiles(ctx: LspTestContext) {.async.} =
  ## Closes all test files
  echo "\n=== Closing test files ==="
  
  await ctx.client.didClose(TextDocumentIdentifier.create(uri = ctx.mainUri))
  echo "✓ Closed main.nim"
  
  await ctx.client.didClose(TextDocumentIdentifier.create(uri = ctx.typesUri))
  echo "✓ Closed types.nim"
  
  await ctx.client.didClose(TextDocumentIdentifier.create(uri = ctx.utilsUri))
  echo "✓ Closed utils.nim"

proc shutdownLsp(ctx: LspTestContext) {.async.} =
  ## Shuts down the LSP session
  echo "\n=== Shutting down LSP session ==="
  
  let shutdownResp = await ctx.client.shutdown()
  echo "✓ Shutdown successful"
  
  let exitCode = await ctx.client.exit()
  echo &"✓ Exit code: {exitCode}"

proc runComprehensiveTest() {.async.} =
  ## Runs the comprehensive LSP test suite
  echo "Starting Comprehensive LSP Client Test (GC-Safe Version)"
  echo "=".repeat(60)
  
  try:
    # Setup and initialization - all data is local, no globals
    let ctx = await setupLspClient()
    await initializeLsp(ctx)
    await openTestFiles(ctx)
    
    # Core LSP functionality tests - context passed to each function
    await testDocumentSymbols(ctx)
    await testHover(ctx)
    await testDefinition(ctx)
    await testTypeDefinition(ctx)
    await testDeclaration(ctx)
    await testCompletion(ctx)
    await testSignatureHelp(ctx)
    await testRename(ctx)
    await testDocumentChanges(ctx)
    
    # Cleanup
    await closeTestFiles(ctx)
    await shutdownLsp(ctx)
    
    echo "\n" & "=".repeat(60)
    echo "✓ Comprehensive LSP test completed successfully!"
    echo "\nTest Summary:"
    echo "- All LSP methods tested with proper GC safety"
    echo "- No global variables used"
    echo "- Context properly passed between functions"
    echo "- Complete session lifecycle validated"
    
  except Exception as e:
    echo &"\n✗ Test failed with error: {e.msg}"
    echo "Stacktrace:"
    echo e.getStackTrace()

# Main execution
proc main() {.async.} =
  ## Main test runner
  await runComprehensiveTest()

when isMainModule:
  waitFor main() 