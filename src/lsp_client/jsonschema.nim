import macros
import ast_pattern_matching
import json
import sequtils
import options
import strutils
import tables

const ManglePrefix {.strdefine.}: string = "the"

type NilType* = enum Nil

proc extractKinds(node: NimNode): seq[tuple[name: string, isArray: bool, isBase: bool, baseType: string]] =
  if node.kind == nnkIdent:
    return @[(name: $node, isArray: false, isBase: false, baseType: "")]
  elif node.kind == nnkInfix and node[0].kind == nnkIdent and $node[0] == "or":
    result = node[2].extractKinds
    result.insert(node[1].extractKinds)
  elif node.kind == nnkBracketExpr and node[0].kind == nnkIdent:
    return @[(name: $node[0], isArray: true, isBase: false, baseType: "")]
  elif node.kind == nnkNilLit:
    return @[(name: "nil", isArray: false, isBase: false, baseType: "")]
  elif node.kind == nnkBracketExpr and node[0].kind == nnkNilLit:
    raise newException(AssertionError, "Array of nils not allowed")
  elif node.kind == nnkCurlyExpr:
    # Handle EnumType{int} syntax for sets (arrays)
    if node.len == 2 and node[0].kind == nnkIdent and node[1].kind == nnkIdent:
      return @[(name: $node[0], isArray: true, isBase: true, baseType: $node[1])]
    else:
      raise newException(AssertionError, "Invalid curly expression syntax")
  elif node.kind == nnkPragmaExpr:
    # Handle EnumType{.int.} syntax for single values
    if node.len == 2 and node[0].kind == nnkIdent and node[1].kind == nnkPragma:
      let pragma = node[1]
      if pragma.len == 1 and pragma[0].kind == nnkIdent:
        return @[(name: $node[0], isArray: false, isBase: true, baseType: $pragma[0])]
      else:
        raise newException(AssertionError, "Invalid pragma expression syntax")
    else:
      raise newException(AssertionError, "Invalid pragma expression syntax")
  else:
    raise newException(AssertionError, "Unknown node kind: " & $node.kind)

proc matchDefinition(pattern: NimNode):
  tuple[
    name: string,
    kinds: seq[tuple[name: string, isArray: bool, isBase: bool, baseType: string]],
    optional: bool,
    mangle: bool
  ] {.compileTime.} =
  matchAst(pattern):
  of nnkCall(
    `name` @ nnkIdent,
    nnkStmtList(
      `kind`
    )
  ):
    return (
      name: $name,
      kinds: kind.extractKinds,
      optional: false,
      mangle: false
    )
  of nnkInfix(
    ident"?:",
    `name` @ nnkIdent,
    `kind`
  ):
    return (
      name: $name,
      kinds: kind.extractKinds,
      optional: true,
      mangle: false
    )
  of nnkCall(
    `name` @ nnkStrLit,
    nnkStmtList(
      `kind`
    )
  ):
    return (
      name: $name,
      kinds: kind.extractKinds,
      optional: false,
      mangle: true
    )
  of nnkInfix(
    ident"?:",
    `name` @ nnkStrLit,
    `kind`
  ):
    return (
      name: $name,
      kinds: kind.extractKinds,
      optional: true,
      mangle: true
    )

proc matchDefinitions(definitions: NimNode):
  seq[
    tuple[
      name: string,
      kinds: seq[
        tuple[
          name: string,
          isArray: bool,
          isBase: bool,
          baseType: string
        ]
      ],
      optional: bool,
      mangle: bool
    ]
  ] {.compileTime.} =
  result = @[]
  for definition in definitions:
    result.add matchDefinition(definition)

macro jsonSchema*(pattern: untyped): untyped =
  var types: seq[
    tuple[
      name: string,
      extends: string,
      exported: bool,
      definitions:seq[
        tuple[
          name: string,
          kinds: seq[
            tuple[
              name: string,
              isArray: bool,
              isBase: bool,
              baseType: string
            ]
          ],
          optional: bool,
          mangle: bool
        ]
      ]
    ]
  ] = @[]
  for part in pattern:
    matchAst(part):
    of nnkCall(
      `objectName` @ nnkIdent,
      `definitions` @ nnkStmtList
    ):
      let defs = definitions.matchDefinitions
      types.add (name: $objectName, extends: "", exported: false, definitions: defs)
    of nnkCall(
      `objectName` @ nnkStrLit,
      `definitions` @ nnkStmtList
    ):
      let nameStr = $objectName
      let (actualName, isExported) = if nameStr.endsWith("*"):
          (nameStr[0..^2], true)
        else:
          (nameStr, false)
      let defs = definitions.matchDefinitions
      types.add (name: actualName, extends: "", exported: isExported, definitions: defs)
    of nnkCall(
      nnkPostfix(
        ident"*",
        `objectName` @ nnkIdent
      ),
      `definitions` @ nnkStmtList
    ):
      let defs = definitions.matchDefinitions
      types.add (name: $objectName, extends: "", exported: true, definitions: defs)
    of nnkCommand(
      `objectName` @ nnkIdent,
      nnkCommand(
        ident"extends",
        `extends` @ nnkIdent
      ),
      `definitions` @ nnkStmtList
    ):
      let defs = definitions.matchDefinitions
      types.add (name: $objectName, extends: $extends, exported: false, definitions: defs)
    of nnkCommand(
      `objectName` @ nnkStrLit,
      nnkCommand(
        ident"extends",
        `extends` @ nnkIdent
      ),
      `definitions` @ nnkStmtList
    ):
      let nameStr = $objectName
      let (actualName, isExported) = if nameStr.endsWith("*"):
          (nameStr[0..^2], true)
        else:
          (nameStr, false)
      let defs = definitions.matchDefinitions
      types.add (name: actualName, extends: $extends, exported: isExported, definitions: defs)
    of nnkCommand(
      nnkPostfix(
        ident"*",
        `objectName` @ nnkIdent
      ),
      nnkCommand(
        ident"extends",
        `extends` @ nnkIdent
      ),
      `definitions` @ nnkStmtList
    ):
      let defs = definitions.matchDefinitions
      types.add (name: $objectName, extends: $extends, exported: true, definitions: defs)

  var
    typeDefinitions = newStmtList()
    validationBodies = initOrderedTable[string, NimNode]()
    validFields = initOrderedTable[string, NimNode]()
    optionalFields = initOrderedTable[string, NimNode]()
    creatorBodies = initOrderedTable[string, NimNode]()
    createArgs  = initOrderedTable[string, NimNode]()
  let
    data = newIdentNode("data")
    fields = newIdentNode("fields")
    traverse = newIdentNode("traverse")
    allowExtra = newIdentNode("allowExtra")
    ret = newIdentNode("ret")
  for t in types:
    let
      name = newIdentNode(t.name)
      objname = newIdentNode(t.name & "Obj")
      finalName = if t.exported: nnkPostfix.newTree(newIdentNode("*"), name) else: name
      finalObjname = if t.exported: nnkPostfix.newTree(newIdentNode("*"), objname) else: objname
      converterName = newIdentNode("toJsonNode")
      finalConverterName = if t.exported: nnkPostfix.newTree(newIdentNode("*"), converterName) else: converterName
    creatorBodies[t.name] = newStmtList()
    typeDefinitions.add quote do:
      type
        `finalObjname` = distinct JsonNodeObj
        `finalName` = ref `objname`
      converter `finalConverterName`(input: `name`): JsonNode {.used.} = input.JsonNode

    var
      requiredFields = 0
      validations = newStmtList()
    validFields[t.name] = nnkBracket.newTree()
    optionalFields[t.name] = nnkBracket.newTree()
    createArgs[t.name] = nnkFormalParams.newTree(name)
    for field in t.definitions:
      let
        fname = field.name
        aname = if field.mangle: newIdentNode(ManglePrefix & field.name) else: newIdentNode(field.name)
        cname = quote do:
          `data`[`fname`]
      if field.optional:
        optionalFields[t.name].add newLit(field.name)
      else:
        validFields[t.name].add newLit(field.name)
      var
        checks: seq[NimNode] = @[]
        argumentChoices: seq[NimNode] = @[]
      for kind in field.kinds:
        let
          tKind = if kind.name == "any":
              if kind.isArray:
                nnkBracketExpr.newTree(
                  newIdentNode("seq"),
                  newIdentNode("JsonNode")
                )
              else:
                newIdentNode("JsonNode")
            elif kind.isArray:
              nnkBracketExpr.newTree(
                newIdentNode("seq"),
                newIdentNode(kind.name)
              )
            else:
              newIdentNode(kind.name)
          isBaseType = kind.isBase or kind.name.toLowerASCII in
            ["int", "string", "float", "bool"]
        if kind.name != "nil":
          if kind.isArray:
            argumentChoices.add tkind
          else:
            argumentChoices.add tkind
        else:
          argumentChoices.add newIdentNode("NilType")
        if isBaseType:
          let
            jkind = newIdentNode("J" & (if kind.isBase: kind.baseType else: kind.name).capitalizeASCII)
          if kind.isArray:
            checks.add quote do:
              `cname`.kind != JArray or `cname`.anyIt(it.kind != `jkind`)
          else:
            checks.add quote do:
              `cname`.kind != `jkind`
        elif kind.name == "any":
          if kind.isArray:
            checks.add quote do:
              `cname`.kind != JArray
          else:
            checks.add newLit(false)
        elif kind.name == "nil":
          checks.add quote do:
            `cname`.kind != JNull
        else:
          let kindNode = newIdentNode(kind.name)
          if kind.isArray:
            checks.add quote do:
              `cname`.kind != JArray or
                (`traverse` and not `cname`.allIt(it.isValid(`kindNode`, allowExtra = `allowExtra`)))
          else:
            checks.add quote do:
              (`traverse` and not `cname`.isValid(`kindNode`, allowExtra = `allowExtra`))
        if kind.name == "nil":
          if field.optional:
            creatorBodies[t.name].add quote do:
              when `aname` is Option[NilType]:
                if `aname`.isSome:
                  `ret`[`fname`] = newJNull()
          else:
            creatorBodies[t.name].add quote do:
              when `aname` is NilType:
                `ret`[`fname`] = newJNull()
        elif kind.isArray:
          let
            i = newIdentNode("i")
            accs = if isBaseType:
                if kind.isBase:
                  quote do:
                    %(`i`.ord)
                else:
                  quote do:
                    %`i`
              else:
                quote do:
                  `i`.JsonNode
          if field.optional:
            creatorBodies[t.name].add quote do:
              when `aname` is Option[`tkind`]:
                if `aname`.isSome:
                  `ret`[`fname`] = newJArray()
                  for `i` in `aname`.unsafeGet:
                    `ret`[`fname`].add `accs`
          else:
            creatorBodies[t.name].add quote do:
              when `aname` is `tkind`:
                `ret`[`fname`] = newJArray()
                for `i` in `aname`:
                  `ret`[`fname`].add `accs`
        else:
          if field.optional:
            let accs = if isBaseType:
                if kind.isBase:
                  quote do:
                    %(`aname`.unsafeGet.ord)
                else:
                  quote do:
                    %`aname`.unsafeGet
              else:
                quote do:
                  `aname`.unsafeGet.JsonNode
            creatorBodies[t.name].add quote do:
              when `aname` is Option[`tkind`]:
                if `aname`.isSome:
                  `ret`[`fname`] = `accs`
          else:
            let accs = if isBaseType:
                if kind.isBase:
                  quote do:
                    %(`aname`.ord)
                else:
                  quote do:
                    %`aname`
              else:
                quote do:
                  `aname`.JsonNode
            creatorBodies[t.name].add quote do:
              when `aname` is `tkind`:
                `ret`[`fname`] = `accs`
      while checks.len != 1:
        let newFirst = nnkInfix.newTree(
          newIdentNode("and"),
          checks[0],
          checks[1]
        )
        checks = checks[2..^1]
        checks.insert(newFirst)
      if field.optional:
        argumentChoices[0] = nnkBracketExpr.newTree(
            newIdentNode("Option"),
            argumentChoices[0]
          )
      while argumentChoices.len != 1:
        let newFirst = nnkInfix.newTree(
          newIdentNode("or"),
          argumentChoices[0],
          if not field.optional: argumentChoices[1]
          else: nnkBracketExpr.newTree(
            newIdentNode("Option"),
            argumentChoices[1]
          )
        )
        argumentChoices = argumentChoices[2..^1]
        argumentChoices.insert(newFirst)
      createArgs[t.name].add nnkIdentDefs.newTree(
        aname,
        argumentChoices[0],
        newEmptyNode()
      )
      let check = checks[0]
      if field.optional:
        validations.add quote do:
          if `data`.hasKey(`fname`):
            `fields` += 1
            if `check`: return false
      else:
        requiredFields += 1
        validations.add quote do:
          if not `data`.hasKey(`fname`): return false
          if `check`: return false

    if t.extends.len == 0:
      validationBodies[t.name] = quote do:
        var `fields` = `requiredFields`
        `validations`
    else:
      let extends = validationBodies[t.extends]
      validationBodies[t.name] = quote do:
        `extends`
        `fields` += `requiredFields`
        `validations`
      for i in countdown(createArgs[t.extends].len - 1, 1):
        createArgs[t.name].insert(1, createArgs[t.extends][i])
      creatorBodies[t.name].insert(0, creatorBodies[t.extends])
      for field in validFields[t.extends]:
        validFields[t.name].add field
      for field in optionalFields[t.extends]:
        optionalFields[t.name].add field

  var forwardDecls = newStmtList()
  var validators = newStmtList()
  let schemaType = newIdentNode("schemaType")
  for kind, body in validationBodies.pairs:
    let kindIdent = newIdentNode(kind)
    # Find the corresponding type to check if it's exported
    var isExported = false
    for t in types:
      if t.name == kind:
        isExported = t.exported
        break
    let finalIsValid = if isExported: nnkPostfix.newTree(newIdentNode("*"), newIdentNode("isValid")) else: newIdentNode("isValid")
    validators.add quote do:
      proc `finalIsValid`(`data`: JsonNode, `schemaType`: typedesc[`kindIdent`],
        `traverse` = true, `allowExtra` = false): bool {.used.} =
        if `data`.kind != JObject: return false
        `body`
        if not `allowExtra` and `fields` != `data`.len: return false
        return true
    forwardDecls.add quote do:
      proc `finalIsValid`(`data`: JsonNode, `schemaType`: typedesc[`kindIdent`],
        `traverse` = true, `allowExtra` = false): bool {.used.}
  var accessors = newStmtList()
  var creators = newStmtList()
  var shortcuts = newStmtList()
  for t in types:
    let
      creatorBody = creatorBodies[t.name]
      kindIdent = newIdentNode(t.name)
      kindName = t.name
      finalCreate = if t.exported: nnkPostfix.newTree(newIdentNode("*"), newIdentNode("create")) else: newIdentNode("create")
      shortcutName = newIdentNode("create" & t.name)
      finalShortcutName = if t.exported: nnkPostfix.newTree(newIdentNode("*"), shortcutName) else: shortcutName
    var creatorArgs = createArgs[t.name]
    creatorArgs.insert(1, nnkIdentDefs.newTree(
      schemaType,
      nnkBracketExpr.newTree(
        newIdentNode("typedesc"),
        kindIdent
      ),
      newEmptyNode()
    ))
    var createProc = quote do:
      proc `finalCreate`() {.used.} =
        var `ret` = newJObject()
        `creatorBody`
        return `ret`.`kindIdent`
    createProc[3] = creatorArgs
    creators.add createProc
    var forwardCreateProc = quote do:
      proc `finalCreate`() {.used.}
    forwardCreateProc[3] = creatorArgs
    forwardDecls.add forwardCreateProc
    
    # Create shortcut procedure
    var shortcutArgs = newNimNode(nnkFormalParams)
    shortcutArgs.add(createArgs[t.name][0]) # Add return type
    # Skip the schemaType parameter (index 1) and add the rest
    for i in 2..<createArgs[t.name].len:
      shortcutArgs.add(createArgs[t.name][i])
    
    # Build the argument list for the create call
    var createCallArgs = newNimNode(nnkCall)
    createCallArgs.add(newIdentNode("create"))
    createCallArgs.add(kindIdent)
    # Add the parameter names as arguments
    for i in 2..<createArgs[t.name].len:
      let paramDef = createArgs[t.name][i]
      if paramDef.kind == nnkIdentDefs and paramDef.len >= 1:
        let paramName = paramDef[0]
        createCallArgs.add(paramName)
    
    var shortcutProc = quote do:
      proc `finalShortcutName`() {.used.} =
        `createCallArgs`
    shortcutProc[3] = shortcutArgs
    shortcuts.add shortcutProc
    var forwardShortcutProc = quote do:
      proc `finalShortcutName`() {.used.}
    forwardShortcutProc[3] = shortcutArgs
    forwardDecls.add forwardShortcutProc

    let macroName = nnkAccQuoted.newTree(
      newIdentNode("[]")
    )
    let finalMacroName = if t.exported: nnkPostfix.newTree(newIdentNode("*"), macroName) else: macroName
    let finalUnsafeAccess = if t.exported: nnkPostfix.newTree(newIdentNode("*"), newIdentNode("unsafeAccess")) else: newIdentNode("unsafeAccess")
    let finalUnsafeOptAccess = if t.exported: nnkPostfix.newTree(newIdentNode("*"), newIdentNode("unsafeOptAccess")) else: newIdentNode("unsafeOptAccess")
    let
      validFieldsList = validFields[t.name]
      optionalFieldsList = optionalFields[t.name]
      data = newIdentNode("data")
      field = newIdentNode("field")
    var accessorbody = nnkIfExpr.newTree()
    if validFields[t.name].len != 0:
      accessorbody.add nnkElifBranch.newTree(nnkInfix.newTree(newIdentNode("in"), field, validFieldsList), quote do:
        return nnkStmtList.newTree(
          nnkCall.newTree(
            newIdentNode("unsafeAccess"),
            `data`,
            newLit(`field`)
          )
        )
      )
    if optionalFields[t.name].len != 0:
      accessorbody.add nnkElifBranch.newTree(nnkInfix.newTree(newIdentNode("in"), field, optionalFieldsList), quote do:
        return nnkStmtList.newTree(
          nnkCall.newTree(
            newIdentNode("unsafeOptAccess"),
            `data`,
            newLit(`field`)
          )
        )
      )
    accessorbody.add nnkElse.newTree(quote do:
      raise newException(KeyError, "unable to access field \"" & `field` & "\" in data with schema " & `kindName`)
    )
    accessors.add quote do:
      proc `finalUnsafeAccess`(data: `kindIdent`, field: static[string]): JsonNode {.used.} =
        JsonNode(data)[field]
      proc `finalUnsafeOptAccess`(data: `kindIdent`, field: static[string]): Option[JsonNode] {.used.} =
        if JsonNode(data).hasKey(field):
          some(JsonNode(data)[field])
        else:
          none(JsonNode)

      macro `finalMacroName`(`data`: `kindIdent`, `field`: static[string]): untyped {.used.} =
        `accessorbody`

  result = quote do:
    import macros
    import json
    import sequtils
    import options
    `typeDefinitions`
    `forwardDecls`
    `validators`
    `creators`
    `shortcuts`
    `accessors`

  when defined(jsonSchemaDebug):
    echo result.repr

when isMainModule:
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

  echo "before wcp"
  var wcp = create(WrapsCancelParams,
    create(CancelParams, some(10), none(float)), "Hello"
  )
  echo "after wcp: ", wcp.JsonNode.isValid(WrapsCancelParams)
  echo "before mutation"
  var wcpNode = wcp.JsonNode
  wcpNode["cp"] = %*{"notcancelparams": true}
  echo "after mutation: ", wcpNode.isValid(WrapsCancelParams)
  echo "before allowExtra"
  echo wcpNode.isValid(WrapsCancelParams, false) == true
  echo "before ecp"
  var ecp = create(ExtendsCancelParams, some(10), some(5.3), "Hello")
  echo "after ecp: ", ecp.JsonNode.isValid(ExtendsCancelParams)
  echo "before war"
  var war = create(WithArrayAndAny, some(@[
    create(CancelParams, some(10), some(1.0)),
    create(CancelParams, some("hello"), none(float))
  ]), 2.0, %*{"hello": "world"}, none(NilType))
  echo "after war: ", war.JsonNode.isValid(WithArrayAndAny)
