import std/bitops

import pkg/nint128

type
  RngSignedInt* = SomeSignedInt|Int128
  RngUnsignedInt* = SomeUnsignedInt|UInt128
  RngSomeInteger* = RngSignedInt|RngUnsignedInt

func `-`*[T: SomeUnsignedInt](a: T): T {.inline.} =
  ## Operator unary minus
  not(a) + 1

template rotl*[T: SomeUnsignedInt](value: T, rot: int): T =
  ## Left-rotate bits in a `value`.
  rotateLeftBits(value, rot)

template rotr*[T: SomeUnsignedInt](value: T, rot: int): T =
  ## Right-rotate bits in a `value`.
  rotateRightBits(value, rot)

# https://arxiv.org/pdf/2001.05304.pdf
func mcg*(n: uint32): uint32 {.inline.} =
  n * 0xf0d21d'u32

# https://arxiv.org/pdf/2001.05304.pdf
func mcg*(n: uint64): uint64 {.inline.} =
  n * 0x8efd5483c3fd'u64

func mul64by64ToTwo64*(a, b: uint64, hi: var uint64): uint64 {.inline.} =
  let tmp = mul64by64To128(a, b)
  hi = tmp.hi
  result = tmp.lo

func mul128by128ToTwo128*(a, b: UInt128, hi: var UInt128): UInt128 {.inline.} =
  var tmp = mul64by64To128(a.lo, b.lo)
  result.lo = tmp.lo
  tmp.lo = tmp.hi
  tmp.hi = 0'u64
  tmp += mul64by64To128(a.hi, b.lo)
  #result.hi = tmp.lo
  hi.lo = tmp.hi
  #tmp.lo = result.hi
  tmp.hi = 0'u64
  # result.hi = 0'u64
  tmp += mul64by64To128(b.hi, a.lo)
  result.hi = tmp.lo
  hi += tmp.hi
  hi += mul64by64To128(a.hi, b.hi)

template initImpl*(length: int, index: untyped) =
  if len(seed) < length:
    raise

  for i in 0 ..< length:
    result.state[i] = seed[i]

  when -1 != index:
    result.p = index

func toSomeIntegerUnsafeImpl[T: RngSomeInteger](x: SomeInt128): T {.compileTime.} =
  when T is SomeSignedInt or T is SomeUnsignedInt: # `SomeInteger` does not work with all versions of Nim
    result = cast[T](x.lo)
  elif T is Int128 and typeof(x) is UInt128:
    result = Int128(hi: cast[int64](x.hi), lo: x.lo)
  elif T is UInt128 and typeof(x) is Int128:
    result = UInt128(hi: cast[uint64](x.hi), lo: x.lo)
  else:
    {.fatal: "`toSomeIntegerUnsafe` does not implement `" & $typeof(x) & "` to `" & $T & "`."}

func toSomeIntegerUnsafeImpl[T: RngSomeInteger](x: SomeSignedInt|SomeUnsignedInt): T {.compileTime.} =
  when T is SomeSignedInt or T is SomeUnsignedInt:
    result = cast[T](x)
  elif T is SomeInt128:
    result = T(hi: 0'u64, lo: cast[uint64](x))
  else:
    {.fatal: "`toSomeIntegerUnsafe` does not implement `" & $typeof(x) & "` to `" & $T & "`."}

template toSomeIntegerUnsafe*[T: RngSomeInteger](x: RngSomeInteger): T =
  when typeof(x) is T:
    x
  else:
    when nimvm:
      toSomeIntegerUnsafeImpl[T](x)
    else:
      cast[T](x)

func bitsByType*(typ: typedesc): int =
  result = sizeof(typ) * 8
