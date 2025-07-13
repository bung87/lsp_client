import src/lsp_client/messageenums
import src/lsp_client/jsonschema

jsonSchema:
  TestSymbolKind:
    valueSet: SymbolKind{int}

when isMainModule:
  echo "Testing SymbolKind{int}..."
  var test = create(TestSymbolKind, @[SymbolKind.File, SymbolKind.Module])
  echo "Created: ", test.JsonNode
  echo "Is valid: ", test.JsonNode.isValid(TestSymbolKind) 