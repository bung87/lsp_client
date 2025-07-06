import lsp_client/lsp_types
include lsp_client/messages
import options
import json
import chronos

# type TraceValue = enum
#   off="off",messages="messages",verbose="verbose"
type TraceValue* = string
type
  LspClientObj[E] = object of RootObj
    lspEndpoint: E
  LspClient*[E] = ref LspClientObj[E]

proc newLspClient*[E](lspEndpoint: E): LspClient[E] =
  #[
  Constructs a new LspClient instance.
  :param lspEndpoint:LspEndpoint
  ]#
  result = LspClient[E]()
  result.lspEndpoint = lspEndpoint


proc initialize*[E, T, P](self: LspClient[E], processId: P, rootPath: Option[string], rootUri: DocumentUri,
    initializationOptions: Option[T], capabilities: ClientCapabilities, trace: Option[TraceValue],
    workspaceFolders: Option[seq[WorkspaceFolder]]): Future[InitializeResponse]{.async.} =
  #[
    The initialize request is sent as the first request from the client to the server. If the server receives a request or notification
    before the initialize request it should act as follows:
    1. For a request the response should be an error with code: -32002. The message can be picked by the server.
    2. Notifications should be dropped, except for the exit notification. This will allow the exit of a server without an initialize request.

    Until the server has responded to the initialize request with an InitializeResult, the client must not send any additional requests or
    notifications to the server. In addition the server is not allowed to send any requests or notifications to the client until it has responded
    with an InitializeResult, with the exception that during the initialize request the server is allowed to send the notifications window/showMessage,
    window/logMessage and telemetry/event as well as the window/showMessageRequest request to the client.
    The initialize request may only be sent once.
    :param int processId: The process Id of the parent process that started the server. Is null if the process has not been started by another process.
                            If the parent process is not alive then the server should exit (see exit notification) its process.
    :param str rootPath: The rootPath of the workspace. Is null if no folder is open. Deprecated in favour of rootUri.
    :param DocumentUri rootUri: The rootUri of the workspace. Is null if no folder is open. If both `rootPath` and `rootUri` are set
                                `rootUri` wins.
    :param any initializationOptions: User provided initialization options.
    :param ClientCapabilities capabilities: The capabilities provided by the client (editor or tool).
    :param Trace trace: The initial trace setting. If omitted trace is disabled ('off').
    :param list workspaceFolders: The workspace folders configured in the client when the server starts. This property is only available if the client supports workspace folders.
                                    It can be `null` if the client supports workspace folders but none are configured.
    ]#
  await self.lspEndpoint.startProcess()

  let resp = await self.lspEndpoint.callMethod("initialize", InitializeParams.create(processId = processId,
      rootPath = rootPath, rootUri = rootUri, initializationOptions = cast[Option[json.JsonNode]](
          initializationOptions), capabilities = capabilities, trace = trace,
      workspaceFolders = workspaceFolders))
  result = InitializeResponse(parseJson(resp))


proc initialized*[E](self: LspClient[E]): Future[void] {.async.} =
  #[
    The initialized notification is sent from the client to the server after the client received the result of the initialize request
    but before the client is sending any other request or notification to the server. The server can use the initialized notification
    for example to dynamically register capabilities. The initialized notification may only be sent once.
    ]#
  await self.lspEndpoint.sendNotification("initialized", InitializedParams(newJObject()))


proc shutdown*[E](self: LspClient[E]): Future[ResponseMessage] {.async.} =
  #[
   It asks the server to shut down, but to not exit
   (otherwise the response might not be delivered correctly to the client)
  ]#
  self.lspEndpoint.stopProcess()
  let resp = await self.lspEndpoint.callMethod("shutdown")
  return ResponseMessage(resp.parseJson)


proc exit*[E](self: LspClient[E]): Future[int] {.async.} =
  #[
  A notification to ask the server to exit its process.
  The server should exit with success code 0 if the shutdown request has been received before;
  otherwise with error code 1.
  ]#
  # send shutdown notification then server exit with 0
  await self.lspEndpoint.sendNotification("exit")
  while self.lspEndpoint.exitCode != 259:
    result = self.lspEndpoint.exitCode
    break


proc didOpen*[E](self: LspClient[E], textDocument: TextDocumentItem): Future[void]{.async.} =
  #[
  The document open notification is sent from the client to the server to signal newly opened text documents. The document's truth is
  now managed by the client and the server must not try to read the document's truth using the document's uri. Open in this sense
  means it is managed by the client. It doesn't necessarily mean that its content is presented in an editor. An open notification must
  not be sent more than once without a corresponding close notification send before. This means open and close notification must be
  balanced and the max open count for a particular textDocument is one. Note that a server's ability to fulfill requests is independent
  of whether a text document is open or closed.
  The DidOpenTextDocumentParams contain the language id the document is associated with. If the language Id of a document changes, the
  client needs to send a textDocument/didClose to the server followed by a textDocument/didOpen with the new language id if the server
  handles the new language id as well.
  :param TextDocumentItem textDocument: The document that was opened.
  ]#
  await self.lspEndpoint.sendNotification("textDocument/didOpen", DidOpenTextDocumentParams.create(
      textDocument = textDocument))

proc didClose*[E](self: LspClient[E], textDocument: TextDocumentIdentifier): Future[void]{.async.} =
  await self.lspEndpoint.sendNotification("textDocument/didClose", DidCloseTextDocumentParams.create(
      textDocument = textDocument))

proc didSave*[E](self: LspClient[E], textDocument: VersionedTextDocumentIdentifier): Future[void]{.async.} =
  await self.lspEndpoint.sendNotification("textDocument/didSave", DidCloseTextDocumentParams.create(
      textDocument = textDocument))

proc didChange*[E](self: LspClient[E], textDocument: VersionedTextDocumentIdentifier, contentChanges: seq[
    TextDocumentContentChangeEvent]): Future[void]{.async.} =
  # https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#didChangeTextDocumentParams
  #[
  The document change notification is sent from the client to the server to signal changes to a text document.
  In 2.0 the shape of the params has changed to include proper version numbers and language ids.
  :param VersionedTextDocumentIdentifier textDocument: The initial trace setting. If omitted trace is disabled ('off').
  :param TextDocumentContentChangeEvent[] contentChanges: The actual content changes. The content changes describe single state changes
    to the document. So if there are two content changes c1 and c2 for a document in state S then c1 move the document
    to S' and c2 to S''.
  ]#
  await self.lspEndpoint.sendNotification("textDocument/didChange", DidChangeTextDocumentParams.create(
      textDocument = textDocument, contentChanges = contentChanges))


proc documentSymbol*[E](self: LspClient[E], textDocument: TextDocumentIdentifier, workDoneToken = none(string),
    partialResultToken = none(string)): Future[DocumentSymbolResponse]{.async.} =
  # https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#documentSymbolParams
  #[
  The document symbol request is sent from the client to the server to return a flat list of all symbols found in a given text document.
  Neither the symbol's location range nor the symbol's container name should be used to infer a hierarchy.
  :param TextDocumentItem textDocument: The text document.
  :result DocumentSymbol[] | SymbolInformation[] | null
  ]#

  let resp = await self.lspEndpoint.callMethod("textDocument/documentSymbol", DocumentSymbolParams.create(
      textDocument = textDocument, workDoneToken = workDoneToken, partialResultToken = partialResultToken))
  return DocumentSymbolResponse(resp.parseJson)


proc definition*[E](self: LspClient[E], textDocument: TextDocumentIdentifier, position: Position, workDoneToken = none(
    string), partialResultToken = none(string)): Future[DefinitionResponse]{.async.} =
  # https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_definition
  #[
  The goto definition request is sent from the client to the server to resolve the definition location of a symbol at a given text document position.
  :param TextDocumentIdentifier textDocument: The text document.
  :param Position position: The position inside the text document.
  result: Location | Location[] | LocationLink[] | null
    partial result: Location[] | LocationLink[]
    error: code and message set in case an exception happens during the definition request
  ]#
  # TextDocumentPositionParams,WorkDoneProgressParams,PartialResultParams
  let resp = await self.lspEndpoint.callMethod("textDocument/definition", DefinitionParams.create(
      textDocument = textDocument, position = position, workDoneToken = workDoneToken,
      partialResultToken = partialResultToken))
  return DefinitionResponse(resp.parseJson)


proc typeDefinition*[E](self: LspClient[E], textDocument: TextDocumentIdentifier, position: Position,
    workDoneToken = none(string), partialResultToken = none(string)): Future[
    TypeDefinitionResponse]{.async.} =
  # https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_typeDefinition
  #[
  The goto type definition request is sent from the client to the server to resolve the type definition location of a symbol at a given text document position.
  :param TextDocumentIdentifier textDocument: The text document.
  :param Position position: The position inside the text document.
  ]#
  let resp = await self.lspEndpoint.callMethod("textDocument/typeDefinition", TypeDefinitionParams.create(
      textDocument = textDocument, position = position, workDoneToken = workDoneToken,
      partialResultToken = partialResultToken))
  return TypeDefinitionResponse(resp.parseJson)


proc signatureHelp*[E](self: LspClient[E], textDocument: TextDocumentIdentifier, position: Position,
    workDoneToken = none(string), context = none(SignatureHelpContext)): Future[SignatureHelpResponse]{.async.} =
  # https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_signatureHelp
  #[
  The signature help request is sent from the client to the server to request signature information at a given cursor position.
  :param TextDocumentIdentifier textDocument: The text document.
  :param Position position: The position inside the text document.
  ]#
  let resp = await self.lspEndpoint.callMethod("textDocument/signatureHelp", SignatureHelpParams.create(
      textDocument = textDocument, position = position, workDoneToken = workDoneToken, context = context))
  return SignatureHelpResponse(resp.parseJson)


proc completion*[E](self: LspClient[E], textDocument: TextDocumentIdentifier, position: Position, workDoneToken = none(
    string), context = none(CompletionContext)): Future[CompletionResponse]{.async.} =
  # https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#completionParams
  #[
  The Completion request is sent from the client to the server to compute completion items at a given cursor position.
  :param TextDocumentIdentifier textDocument: The text document.
  :param Position position: The position inside the text document.
  :param CompletionContext context: The completion context. This is only available if the client specifies
    to send this using `ClientCapabilities.textDocument.completion.contextSupport === true`
  :result CompletionItem[] | CompletionList | null
  ]#
  let resp = await self.lspEndpoint.callMethod("textDocument/completion", CompletionParams.create(
      textDocument = textDocument, position = position, workDoneToken = workDoneToken, context = context))
  return CompletionResponse(resp.parseJson())


proc declaration*[E](self: LspClient[E], textDocument: TextDocumentIdentifier, position: Position, workDoneToken = none(
    string), partialResultToken = none(string)): Future[DeclarationResponse]{.async.} =
  # https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#declarationParams
  #[
  The go to declaration request is sent from the client to the server to resolve the declaration location of a
  symbol at a given text document position.
  The result type LocationLink[] got introduce with version 3.14.0 and depends in the corresponding client
  capability `clientCapabilities.textDocument.declaration.linkSupport`.
  :param TextDocumentItem textDocument: The text document.
  :param Position position: The position inside the text document.
  ]#
  let resp = await self.lspEndpoint.callMethod("textDocument/declaration", DeclarationParams.create(
      textDocument = textDocument, position = position, workDoneToken = workDoneToken,
      partialResultToken = partialResultToken))
  return DeclarationResponse(resp.parseJson())

proc rename*[E](self: LspClient[E], textDocument: TextDocumentIdentifier, position: Position, newName: string,
    workDoneToken = none(string)): Future[RenameResponse]{.async.} =
  let resp = self.lspEndpoint.callMethod("textDocument/rename", RenameParams.create(textDocument = textDocument,
      position = position, newName = newName, workDoneToken = workDoneToken))
  return RenameResponse(resp.parseJson())

proc hover*[E](self: LspClient[E], textDocument: TextDocumentIdentifier, position: Position,
    workDoneToken = none(string)): Future[HoverResponse]{.async.} =
  let resp = self.lspEndpoint.callMethod("textDocument/hover", HoverParams.create(textDocument = textDocument,
      position = position, workDoneToken = workDoneToken))
  return HoverResponse(resp.parseJson())
