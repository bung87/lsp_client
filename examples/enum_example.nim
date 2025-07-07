## Example demonstrating enum support in jsonschema
##
## This example shows how to use enum types with base type annotations
## in JSON schema validation.

import json
import options
import ../src/lsp_client/jsonschema

# Define enum types
type 
  MarkupKind {.pure.} = enum
    plaintext = 0
    markdown = 1

  CompletionItemKindEnum* {.pure.} = enum
    Text = 1,
    Method = 2,
    Function = 3,
    Constructor = 4,
    Field = 5

# Define JSON schemas using enum types
jsonSchema:
  CompletionItemsRequest:
    # Array of enum values - serialized as integers
    kinds: CompletionItemKindEnum{int}
    # Optional single enum value - serialized as integer
    markupKind ?: MarkupKind{.int.}
    # Regular fields
    textDocument: string
    position: int

  SingleEnumExample:
    # Single enum value with base type annotation
    kind: MarkupKind{.int.}
    value: string

when isMainModule:
  # Test enum array
  echo "=== Testing enum array ==="
  var request = create(CompletionItemsRequest,
    @[CompletionItemKindEnum.Text, CompletionItemKindEnum.Method, CompletionItemKindEnum.Function],
    some(MarkupKind.markdown),
    "file.nim",
    42
  )
  
  echo "Created request: ", request.JsonNode.pretty
  echo "Validation result: ", request.JsonNode.isValid(CompletionItemsRequest)
  
  # Test single enum value
  echo "\n=== Testing single enum value ==="
  var singleEnum = create(SingleEnumExample,
    MarkupKind.plaintext,
    "Hello, World!"
  )
  
  echo "Created single enum: ", singleEnum.JsonNode.pretty
  echo "Validation result: ", singleEnum.JsonNode.isValid(SingleEnumExample)
  
  # Test validation with wrong data
  echo "\n=== Testing validation with wrong data ==="
  let wrongData = %*{
    "kinds": ["text", "method"],  # Wrong: should be integers
    "textDocument": "file.nim",
    "position": 42
  }
  
  echo "Wrong data: ", wrongData.pretty
  echo "Validation result: ", wrongData.isValid(CompletionItemsRequest) 