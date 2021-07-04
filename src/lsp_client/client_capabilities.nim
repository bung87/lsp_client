import jsonschema
type InsertTextMode {.pure.} = enum
  asIs = 1, adjustIndentation

type MarkupKind {.pure.} = enum
  plaintext = 0
  markdown = 1

type ResourceOperationKind {.pure.} = enum
  create = 0
  rename = 1
  delete = 2

type FailureHandlingKind {.pure.} = enum
  abort = 0
  transactional = 1
  undo = 2
  textOnlyTransactional = 3

type CompletionItemTag {.pure.} = enum
  # Render a completion as obsolete, usually using a strike-out.
  Deprecated = 1

jsonSchema:
  WorkspaceEditClientCapabilities:
    # The client supports versioned document changes in `WorkspaceEdit`s
    documentChanges ?: bool

    # The resource operations the client supports. Clients should at least
    # support 'create', 'rename' and 'delete' files and folders.
    #
    # @since 3.13.0
    resourceOperations ?: ResourceOperationKind[]

    # The failure handling strategy of a client if applying the workspace edit
    # fails.
    #
    # @since 3.13.0
    failureHandling ?: FailureHandlingKind

  DidChangeConfigurationClientCapabilities:
    # Did change configuration notification supports dynamic registration.
    dynamicRegistration: bool

  DidChangeWatchedFilesClientCapabilities:
    # Did change watched files notification supports dynamic registration. Please note
    # that the current protocol doesn't support static configuration for file changes
    # from the server side.
    dynamicRegistration ?: bool

  symbolKindWorkspaceSymbolClientCapabilities:
    # The symbol kind values the client supports. When this
    # property exists the client also guarantees that it will
    # handle values outside its set gracefully and falls back
    # to a default value when unknown.
    #
    # If this property is not present the client only supports
    # the symbol kinds from `File` to `Array` as defined in
    # the initial version of the protocol.
    valueSet ?: SymbolKind[]

  WorkspaceSymbolClientCapabilities:
    # Symbol request supports dynamic registration.
    dynamicRegistration ?: bool

    # Specific capabilities for the `SymbolKind` in the `workspace/symbol` request.
    symbolKind ?: symbolKindWorkspaceSymbolClientCapabilities

  ExecuteCommandClientCapabilities:
    # Execute command supports dynamic registration.
    dynamicRegistration ?: bool

  WorkspaceClientCapabilities:
    # The client supports applying batch edits
    # to the workspace by supporting the request
    # 'workspace/applyEdit'
    applyEdit ?: bool

    # Capabilities specific to `WorkspaceEdit`s
    workspaceEdit ?: WorkspaceEditClientCapabilities

    # Capabilities specific to the `workspace/didChangeConfiguration` notification.
    didChangeConfiguration ?: DidChangeConfigurationClientCapabilities

    # Capabilities specific to the `workspace/didChangeWatchedFiles` notification.
    didChangeWatchedFiles ?: DidChangeWatchedFilesClientCapabilities

    # Capabilities specific to the `workspace/symbol` request.
    symbol ?: WorkspaceSymbolClientCapabilities

    # Capabilities specific to the `workspace/executeCommand` request.
    executeCommand ?: ExecuteCommandClientCapabilities

    # The client has support for workspace folders.
    # Since 3.6.0
    workspaceFolders ?: bool

    # The client supports `workspace/configuration` requests.
    # Since 3.6.0
    configuration ?: bool

  WindowClientCapabilities:
    # Whether client supports handling progress notifications. If set servers are allowed to
    # report in `workDoneProgress` property in the request specific server capabilities.
    # Since 3.15.0
    workDoneProgress ?: bool

  TextDocumentSyncClientCapabilities:
    # Whether text document synchronization supports dynamic registration.
    dynamicRegistration ?: bool

    # The client supports sending will save notifications.
    willSave ?: bool

    # The client supports sending a will save request and
    # waits for a response providing text edits which will
    # be applied to the document before it is saved.
    willSaveWaitUntil ?: bool

    # The client supports did save notifications.
    didSave ?: bool

  TagSupportCompletionItemCompletionClientCapabilities:
    # The tags supported by the client.
    valueSet: CompletionItemTag{int}
    # valueSet: int[]

  CompletionItemKind:
    # The completion item kind values the client supports. When this
    # property exists the client also guarantees that it will
    # handle values outside its set gracefully and falls back
    # to a default value when unknown.
    #
    # If this property is not present the client only supports
    # the completion items kinds from `Text` to `Reference` as defined in
    # the initial version of the protocol.
    valueSet ?: CompletionItemKindEnum{int}

  CompletionItemCompletionClientCapabilities:
    # Client supports snippets as insert text.
    #
    # A snippet can define tab stops and placeholders with `$1`, `$2`
    # and `${3:foo}`. `$0` defines the final tab stop, it defaults to
    # the end of the snippet. Placeholders with equal identifiers are linked,
    # that is typing in one will update others too.
    snippetSupport ?: bool

    # Client supports commit characters on a completion item.
    commitCharactersSupport ?: bool

    # Client supports the follow content formats for the documentation
    # property. The order describes the preferred format of the client.
    documentationFormat ?: MarkupKind{int}

      # Client supports the deprecated property on a completion item.
    deprecatedSupport ?: bool

    # Client supports the preselect property on a completion item.
    preselectSupport ?: bool

    # Client supports the tag property on a completion item. Clients supporting
    # tags have to handle unknown tags gracefully. Clients especially need to
    # preserve unknown tags when sending a completion item back to the server in
    # a resolve call.
    #
    # @since 3.15.0
    tagSupport ?: TagSupportCompletionItemCompletionClientCapabilities



  CompletionClientCapabilities:
    # Whether completion supports dynamic registration.
    dynamicRegistration ?: bool

    # The client supports the following `CompletionItem` specific
    # capabilities.
    completionItem ?: CompletionItemCompletionClientCapabilities
    completionItemKind ?: CompletionItemKind
    # The client supports to send additional context information for a
    # `textDocument/completion` request.
    contextSupport ?: bool
    insertTextMode ?: InsertTextMode{.int.} #InsertTextMode # since 3.17.0

  HoverClientCapabilities:
    # Whether hover supports dynamic registration.
    dynamicRegistration ?: bool

    # Client supports the follow content formats for the content
    # property. The order describes the preferred format of the client.
    contentFormat ?: MarkupKind{int}

  #SignatureInformation:
    # Client supports the follow content formats for the documentation
    # property. The order describes the preferred format of the client.
    documentationFormat ?: MarkupKind{int}

  ParameterInformation:
    # The client supports processing label offsets instead of a
    # simple label string.
    #
    # @since 3.14.0
    labelOffsetSupport ?: bool

  SignatureHelpClientCapabilities:
    # Whether signature help supports dynamic registration.
    dynamicRegistration ?: bool

    # The client supports the following `SignatureInformation`
    # specific properties.
    #signatureInformation?: SignatureInformation

    # Client capabilities specific to parameter information.
    parameterInformation ?: ParameterInformation

    # The client supports to send additional context information for a
    # `textDocument/signatureHelp` request. A client that opts into
    # contextSupport will also support the `retriggerCharacters` on
    # `SignatureHelpOptions`.
    #
    # @since 3.15.0
    contextSupport ?: bool

  DeclarationClientCapabilities:
    # Whether declaration supports dynamic registration. If this is set to `true`
    # the client supports the new `DeclarationRegistrationOptions` return value
    # for the corresponding server capability as well.
    dynamicRegistration ?: bool

    # The client supports additional metadata in the form of declaration links.
    linkSupport ?: bool

  DefinitionClientCapabilities:
    # Whether definition supports dynamic registration.
    dynamicRegistration ?: bool

    # The client supports additional metadata in the form of definition links.
    #
    # @since 3.14.0
    linkSupport ?: bool

  TypeDefinitionClientCapabilities:
    # Whether implementation supports dynamic registration. If this is set to `true`
    # the client supports the new `TypeDefinitionRegistrationOptions` return value
    # for the corresponding server capability as well.
    dynamicRegistration ?: bool

    # The client supports additional metadata in the form of definition links.
    #
    # @since 3.14.0
    linkSupport ?: bool

  ImplementationClientCapabilities:
    # Whether implementation supports dynamic registration. If this is set to `true`
    # the client supports the new `ImplementationRegistrationOptions` return value
    # for the corresponding server capability as well.
    dynamicRegistration ?: bool

    # The client supports additional metadata in the form of definition links.
    #
    # @since 3.14.0
    linkSupport ?: bool

  ReferenceClientCapabilities:
    # Whether references supports dynamic registration.
    dynamicRegistration ?: bool

  DocumentHighlightClientCapabilities:
    # Whether document highlight supports dynamic registration.
    dynamicRegistration ?: bool

  SymbolKindDocumentSymbolClientCapabilities:
    # The symbol kind values the client supports. When this
    # property exists the client also guarantees that it will
    # handle values outside its set gracefully and falls back
    # to a default value when unknown.
    #
    # If this property is not present the client only supports
    # the symbol kinds from `File` to `Array` as defined in
    # the initial version of the protocol.
    valueSet ?: SymbolKind[];

  DocumentSymbolClientCapabilities:
    # Whether document symbol supports dynamic registration.
    dynamicRegistration ?: bool

    # Specific capabilities for the `SymbolKind` in the `textDocument/documentSymbol` request.
    #symbolKind?: SymbolKindInDocumentSymbolClientCapabilities

    # The client supports hierarchical document symbols.
    hierarchicalDocumentSymbolSupport ?: bool

  CodeActionKind:
    # The code action kind values the client supports. When this
    # property exists the client also guarantees that it will
    # handle values outside its set gracefully and falls back
    # to a default value when unknown.
    valueSet: CodeActionKind[]

  #CodeActionLiteralSupport:
    # The code action kind is supported with the following value
    # set.
    #codeActionKind: CodeActionKind

  CodeActionClientCapabilities:
    # Whether code action supports dynamic registration.
    dynamicRegistration ?: bool

    # The client supports code action literals as a valid
    # response of the `textDocument/codeAction` request.
    #
    # @since 3.8.0
    #codeActionLiteralSupport?: CodeActionLiteralSupport

    # Whether code action supports the `isPreferred` property.
    # @since 3.15.0
    isPreferredSupport ?: bool

  CodeLensClientCapabilities:
    # Whether code lens supports dynamic registration.
    dynamicRegistration ?: bool

  DocumentLinkClientCapabilities:
    # Whether document link supports dynamic registration.
    dynamicRegistration ?: bool

    # Whether the client supports the `tooltip` property on `DocumentLink`.
    # @since 3.15.0
    tooltipSupport ?: bool

  DocumentColorClientCapabilities:
    # Whether document color supports dynamic registration.
    dynamicRegistration ?: bool

  DocumentFormattingClientCapabilities:
    # Whether formatting supports dynamic registration.
    dynamicRegistration ?: bool

  DocumentRangeFormattingClientCapabilities:
    # Whether formatting supports dynamic registration.
    dynamicRegistration ?: bool

  DocumentOnTypeFormattingClientCapabilities:
    # Whether on type formatting supports dynamic registration.
    dynamicRegistration ?: bool

  RenameClientCapabilities:
    # Whether rename supports dynamic registration.
    dynamicRegistration ?: bool

    # Client supports testing for validity of rename operations
    # before execution.
    #
    # @since version 3.12.0
    prepareSupport ?: bool

  TagSupportPublishDiagnosticsClientCapabilities:
    # The tags supported by the client.
    # DiagnosticTag 1 or 2
    valueSet: int[]

  PublishDiagnosticsClientCapabilities:
    # Whether the clients accepts diagnostics with related information.
    relatedInformation ?: bool

    # Client supports the tag property to provide meta data about a diagnostic.
    # Clients supporting tags have to handle unknown tags gracefully.
    #
    # @since 3.15.0
    tagSupport ?: TagSupportPublishDiagnosticsClientCapabilities

    # Whether the client interprets the version property of the
    # `textDocument/publishDiagnostics` notification's parameter.
    #
    # @since 3.15.0
    versionSupport ?: bool

  FoldingRangeClientCapabilities:
    # Whether implementation supports dynamic registration for folding range providers. If this is set to `true`
    # the client supports the new `FoldingRangeRegistrationOptions` return value for the corresponding server
    # capability as well.
    dynamicRegistration ?: bool
    # The maximum number of folding ranges that the client prefers to receive per document. The value serves as a
    # hint, servers are free to follow the limit.
    rangeLimit ?: int or float
    # If set, the client signals that it only supports folding complete lines. If set, client will
    # ignore specified `startCharacter` and `endCharacter` properties in a FoldingRange.
    lineFoldingOnly ?: bool

  SelectionRangeClientCapabilities:
    # Whether implementation supports dynamic registration for selection range providers. If this is set to `true`
    # the client supports the new `SelectionRangeRegistrationOptions` return value for the corresponding server
    # capability as well.
    dynamicRegistration ?: bool

  TextDocumentClientCapabilities:
    synchronization ?: TextDocumentSyncClientCapabilities

    # Capabilities specific to the `textDocument/completion` request.
    completion ?: CompletionClientCapabilities

    # Capabilities specific to the `textDocument/hover` request.
    hover ?: HoverClientCapabilities

    # Capabilities specific to the `textDocument/signatureHelp` request.
    signatureHelp ?: SignatureHelpClientCapabilities

    # Capabilities specific to the `textDocument/declaration` request.
    # @since 3.14.0
    declaration ?: DeclarationClientCapabilities

    # Capabilities specific to the `textDocument/definition` request.
    definition ?: DefinitionClientCapabilities

    # Capabilities specific to the `textDocument/typeDefinition` request.
    # @since 3.6.0
    typeDefinition ?: TypeDefinitionClientCapabilities

    # Capabilities specific to the `textDocument/implementation` request.
    # @since 3.6.0
    implementation ?: ImplementationClientCapabilities

    # Capabilities specific to the `textDocument/references` request.
    references ?: ReferenceClientCapabilities

    # Capabilities specific to the `textDocument/documentHighlight` request.
    documentHighlight ?: DocumentHighlightClientCapabilities

    # Capabilities specific to the `textDocument/documentSymbol` request.
    documentSymbol ?: DocumentSymbolClientCapabilities

    # Capabilities specific to the `textDocument/codeAction` request.
    codeAction ?: CodeActionClientCapabilities

    # Capabilities specific to the `textDocument/codeLens` request.
    codeLens ?: CodeLensClientCapabilities

    # Capabilities specific to the `textDocument/documentLink` request.
    documentLink ?: DocumentLinkClientCapabilities

    # Capabilities specific to the `textDocument/documentColor` and the
    # `textDocument/colorPresentation` request.
    # @since 3.6.0
    colorProvider ?: DocumentColorClientCapabilities

    # Capabilities specific to the `textDocument/formatting` request.
    formatting ?: DocumentFormattingClientCapabilities

    # Capabilities specific to the `textDocument/rangeFormatting` request.
    rangeFormatting ?: DocumentRangeFormattingClientCapabilities

    # Capabilities specific to the `textDocument/onTypeFormatting` request.
    onTypeFormatting ?: DocumentOnTypeFormattingClientCapabilities

    # Capabilities specific to the `textDocument/rename` request.
    rename ?: RenameClientCapabilities

    # Capabilities specific to the `textDocument/publishDiagnostics` notification.
    publishDiagnostics ?: PublishDiagnosticsClientCapabilities

      # Capabilities specific to the `textDocument/foldingRange` request.
      # @since 3.10.0
    foldingRange ?: FoldingRangeClientCapabilities

      # Capabilities specific to the `textDocument/selectionRange` request.
      # @since 3.15.0
    selectionRange ?: SelectionRangeClientCapabilities

  ClientCapabilities:
    # Workspace specific client capabilities.
    workspace ?: WorkspaceClientCapabilities

    # Text document specific client capabilities.
    textDocument ?: TextDocumentClientCapabilities

    # Window specific client capabilities.
    window ?: WindowClientCapabilities

    # Experimental client capabilities.
    experimental ?: any
