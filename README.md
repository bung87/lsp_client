# lsp_client  ![Build Status](https://github.com/bung87/lsp_client/workflows/Test/badge.svg) 

Language server protocol client implementated in Nim language.  

Builtin support integrate with `nimlsp`, `nimlsp` should use my fork version [https://github.com/bung87/nimlsp](https://github.com/bung87/nimlsp)

## Features

### JSON Schema with Enum Support

The `jsonschema` module now supports enum types with base type annotations:

```nim
import json
import options
import lsp_client/jsonschema

type 
  MarkupKind {.pure.} = enum
    plaintext = 0
    markdown = 1

  CompletionItemKindEnum = enum
    Text = 1,
    Method = 2,
    Function = 3

jsonSchema:
  MySchema:
    # Array of enum values - serialized as integers
    kinds: CompletionItemKindEnum{int}
    # Single enum value - serialized as integer  
    markupKind: MarkupKind{.int.}
    # Optional enum field
    optionalKind ?: MarkupKind{.int.}

# Usage
var schema = create(MySchema, 
  @[CompletionItemKindEnum.Text, CompletionItemKindEnum.Method],
  MarkupKind.markdown,
  some(MarkupKind.plaintext)
)

echo schema.JsonNode.pretty
# Output:
# {
#   "kinds": [1, 2],
#   "markupKind": 1,
#   "optionalKind": 0
# }
```

**Enum Syntax:**
- `EnumType{int}` - Array of enum values serialized as integers
- `EnumType{.int.}` - Single enum value serialized as integer
- Works with optional fields using `?:` syntax

## Development  

**Note**: `nimlsp` **should** use `release` build, as debug build write debug message to `stderror` , I may change `nimlsp` debug log to other destination in the future.   