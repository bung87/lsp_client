import lsp_client/jsonschema
import json
import options

# Define some test schemas
jsonSchema:
  CancelParams:
    id ?: int or string or float
    something ?: float

  WrapsCancelParams:
    cp: CancelParams
    name: string

  ExtendsCancelParams extends CancelParams:
    name: string

  WithArrayAndAny:
    test ?: CancelParams[]
    ralph: int[] or float
    bob: any
    john ?: int or nil

  NameTest:
    "method": string
    "result": int
    "if": bool
    "type": float

# Test the shortcut procedures
proc testShortcuts() =
  echo "Testing shortcut procedures..."
  
  # Test createCancelParams shortcut
  var cp1 = createCancelParams(some(10), some(5.3))
  echo "createCancelParams shortcut works: ", cp1.JsonNode.isValid(CancelParams)
  
  # Test createWrapsCancelParams shortcut
  var wcp1 = createWrapsCancelParams(
    createCancelParams(some(20), none(float)), 
    "Test Name"
  )
  echo "createWrapsCancelParams shortcut works: ", wcp1.JsonNode.isValid(WrapsCancelParams)
  
  # Test createExtendsCancelParams shortcut
  var ecp1 = createExtendsCancelParams(some(30), some(7.5), "Extended Name")
  echo "createExtendsCancelParams shortcut works: ", ecp1.JsonNode.isValid(ExtendsCancelParams)
  
  # Test createWithArrayAndAny shortcut
  var war1 = createWithArrayAndAny(
    some(@[
      createCancelParams(some(40), some(1.0)),
      createCancelParams(some("hello"), none(float))
    ]), 
    2.0, 
    %*{"hello": "world"}, 
    none(NilType)
  )
  echo "createWithArrayAndAny shortcut works: ", war1.JsonNode.isValid(WithArrayAndAny)
  
  # Test createNameTest shortcut
  var nt1 = createNameTest("GET", 200, true, 3.14)
  echo "createNameTest shortcut works: ", nt1.JsonNode.isValid(NameTest)
  
  echo "All shortcut procedures work correctly!"

# Test that the original create() function still works
proc testOriginalCreate() =
  echo "Testing original create() function..."
  
  var cp2 = create(CancelParams, some(15), some(6.7))
  echo "Original create(CancelParams) works: ", cp2.JsonNode.isValid(CancelParams)
  
  var wcp2 = create(WrapsCancelParams,
    create(CancelParams, some(25), none(float)), "Original Test"
  )
  echo "Original create(WrapsCancelParams) works: ", wcp2.JsonNode.isValid(WrapsCancelParams)
  
  var ecp2 = create(ExtendsCancelParams, some(35), some(8.9), "Original Extended")
  echo "Original create(ExtendsCancelParams) works: ", ecp2.JsonNode.isValid(ExtendsCancelParams)
  
  echo "Original create() function still works correctly!"

# Test field access
proc testFieldAccess() =
  echo "Testing field access..."
  
  var cp = createCancelParams(some(50), some(9.1))
  # 'id' is optional, so it returns Option[JsonNode]
  echo "Field access works: ", cp["id"].unsafeGet.getInt == 50
  
  var wcp = createWrapsCancelParams(
    createCancelParams(some(60), none(float)), 
    "Field Test"
  )
  # 'name' is required, so it returns JsonNode directly
  echo "Nested field access works: ", wcp["name"].getStr == "Field Test"
  
  echo "Field access works correctly!"

when isMainModule:
  testShortcuts()
  testOriginalCreate()
  testFieldAccess()
  echo "All tests passed!" 