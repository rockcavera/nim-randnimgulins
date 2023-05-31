template initTests*(seeds: openarray[int]) =
  import std/[os, strutils, unittest]

  # Prevents compile-time optimizations (?)
  # Allows you to pass other seeds
  var
    tseed {.inject.} = seeds
    length = paramCount()

  if length > len(tseed):
    length = len(tseed)

  for i in 1 .. length:
    tseed[i - 1] = paramStr(i).parseInt()

template testRng*(init: untyped) =
  var
    rng = init
    toFill: typeof(expected)

  for i in mitems(toFill):
    i = next(rng)

  check expected == toFill
