import std/[macros, tables]

var allRngs {.compileTime.} = initTable[int, seq[string]]()

macro stringify(n: untyped): string =
  ## Turns an identifier name into a string. Taken from https://forum.nim-lang.org/t/1588#9907
  result = newNimNode(nnkStmtList, n)
  result.add(toStrLit(n))

proc addRng*(rngName: string, rngOutputSize: int) =
  if not hasKey(allRngs, rngOutputSize):
    allRngs[rngOutputSize] = @[]

  add(allRngs[rngOutputSize], rngName)

template addRng*(rngName: untyped) =
  static:
    var rng: rngName

    addRng(stringify(rngName), sizeof(next(rng)))

macro defineAliasesToAllRngs*(): untyped =
  result = newTree(nnkTypeSection)

  for k,v in pairs(allRngs):
    let typeName = "Rng" & $(k * 8)
    var n: NimNode

    if len(v) > 1:
      n = newTree(nnkInfix, newIdentNode("|"), newIdentNode(v[0]), newIdentNode(v[1]))

      for i in 2 ..< len(v):
        n = newTree(nnkInfix, newIdentNode("|"), n, newIdentNode(v[i]))
    else:
      n = newIdentNode(v[0])

    n = newTree(nnkTypeDef, newTree(nnkPostfix, newIdentNode("*"), newIdentNode(typeName)), newEmptyNode(), n)

    add(result, n)

  result = newStmtList(result)
