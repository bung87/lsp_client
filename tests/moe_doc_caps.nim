# include lsp_client
import sequtils
const TagSupportValueSet = {low(CompletionItemTag) .. high(
    CompletionItemTag)}.toSeq
const DocumentationFormat = {low(MarkupKind) .. high(MarkupKind)}.toSeq
let docCaps = create(TextDocumentClientCapabilities,
  synchronization = some(create(TextDocumentSyncClientCapabilities,
    dynamicRegistration = some(true),
    willSave = none(bool),
    willSaveWaitUntil = none(bool),
    didSave = none(bool),
  )),
  hover = some(HoverClientCapabilities.create(
    dynamicRegistration = some(true),
    contentFormat = some(DocumentationFormat),
    documentationFormat = some(DocumentationFormat)
  )),
  completion = some(create(CompletionClientCapabilities,
    dynamicRegistration = some(true),
    completionItem = some(CompletionItemCompletionClientCapabilities.create(
      snippetSupport = none(bool),
      commitCharactersSupport = none(bool),
    documentationFormat = some(DocumentationFormat),
    deprecatedSupport = some(true),
    preselectSupport = none(bool),
    tagSupport = some(TagSupportCompletionItemCompletionClientCapabilities.create(
      valueSet = TagSupportValueSet
    ))

  )),
    completionItemKind = some(CompletionItemKind.create(
      valueSet = some({low(CompletionItemKindEnum) .. high(CompletionItemKindEnum)}.toSeq)
    )),
    contextSupport = none(bool),
    insertTextMode = none(InsertTextMode),
  )),
  foldingRange = none(FoldingRangeClientCapabilities),
  selectionRange = none(SelectionRangeClientCapabilities),
  publishDiagnostics = none(PublishDiagnosticsClientCapabilities),
  declaration = none(DeclarationClientCapabilities),
  signatureHelp = none(SignatureHelpClientCapabilities),
  definition = some(DefinitionClientCapabilities.create(dynamicRegistration = some(true), linkSupport = none(bool))), #?: bool
  typeDefinition = some(TypeDefinitionClientCapabilities.create(dynamicRegistration = some(true), linkSupport = none(
      bool))),  #?: bool or TextDocumentAndStaticRegistrationOptions
  implementation = some(ImplementationClientCapabilities.create(dynamicRegistration = some(true), linkSupport = none(
      bool))),  #?: bool or TextDocumentAndStaticRegistrationOptions
  references = some(ReferenceClientCapabilities.create(dynamicRegistration = some(true))),             #?: bool
  documentHighlight = some(DocumentHighlightClientCapabilities.create(dynamicRegistration = some(true))), #?: bool
  documentSymbol = some(DocumentSymbolClientCapabilities.create(dynamicRegistration = some(true),
      hierarchicalDocumentSymbolSupport = none(bool))),                                                #?: bool
  codeAction = none(CodeActionClientCapabilities),                                                     #?: bool
  codeLens = none(CodeLensClientCapabilities),                                                         #?: CodeLensOptions
  formatting = none(DocumentFormattingClientCapabilities),                                             #?: bool
  rangeFormatting = none(DocumentRangeFormattingClientCapabilities),                                   #?: bool
  onTypeFormatting = none(DocumentOnTypeFormattingClientCapabilities),  #?: DocumentOnTypeFormattingOptions
  rename = some(RenameClientCapabilities.create(dynamicRegistration = some(true), prepareSupport = none(bool))), #?: bool
  documentLink = none(DocumentLinkClientCapabilities),                                                 #?: DocumentLinkOptions
  colorProvider = none(DocumentColorClientCapabilities),  #?: bool or ColorProviderOptions or TextDocumentAndStaticRegistrationOptions
)
