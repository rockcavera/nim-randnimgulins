template testRng*(init: untyped) =
  var
    rng = init
    toFill: typeof(expected)

  for i in mitems(toFill):
    i = next(rng)

  check expected == toFill
