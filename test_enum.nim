import src/lsp_client/jsonschema

type
  TestEnum = enum
    Value1 = 1
    Value2 = 2
    Value3 = 3

jsonSchema:
  TestWithEnum:
    single: TestEnum{int}
    array: TestEnum{int}[]

when isMainModule:
  echo "Testing enum support..."
  
  # Test single enum value
  var singleTest = create(TestWithEnum, Value1, @[Value2, Value3])
  echo "Single test created: ", singleTest.JsonNode
  
  # Test validation
  echo "Is valid: ", singleTest.JsonNode.isValid(TestWithEnum)
  
  # Test with invalid enum value
  var invalidJson = %*{"single": 99, "array": [1, 2]}
  echo "Invalid JSON is valid: ", invalidJson.isValid(TestWithEnum) 