import pkg/nint128

import ./randnimgulins/[jsf, pcg, wyrand, xoshiro]

import ./randnimgulins/private/[exporter, utils]

defineAliasesToAllRngs()

func moduloRange*(rng: var Rng8, bound: uint8): uint8 =
  next(rng) mod bound

func moduloRange*(rng: var Rng16, bound: uint16): uint16 =
  next(rng) mod bound

func moduloRange*(rng: var Rng32, bound: uint32): uint32 =
  next(rng) mod bound

func moduloRange*(rng: var Rng64, bound: uint64): uint64 =
  next(rng) mod bound

func moduloRange*(rng: var Rng128, bound: UInt128): UInt128 =
  next(rng) mod bound

func fastRange*(rng: var Rng8, bound: uint8): uint8 =
  ## https://github.com/lemire/fastrange
  uint8((uint16(next(rng)) * uint16(bound)) shr 8)

func fastRange*(rng: var Rng16, bound: uint16): uint16 =
  uint16((uint32(next(rng)) * uint32(bound)) shr 16)

func fastRange*(rng: var Rng32, bound: uint32): uint32 =
  uint32((uint64(next(rng)) * uint64(bound)) shr 32)

func fastRange*(rng: var Rng64, bound: uint64): uint64 =
  discard mul64by64ToTwo64(next(rng), bound, result)

func fastRange*(rng: var Rng128, bound: UInt128): UInt128 =
  discard mul128by128ToTwo128(next(rng), bound, result)

func pcgBounded*(rng: var Rng8, bound: uint8): uint8 {.inline.} =
  ## Returns an uniformly distributed number, where 0 <= r < bound.
  let threshold = -bound mod bound

  while true:
    let r = next(rng)

    if r >= threshold:
      return r mod bound

func pcgBounded*(rng: var Rng16, bound: uint16): uint16 {.inline.} =
  let threshold = -bound mod bound

  while true:
    let r = next(rng)

    if r >= threshold:
      return r mod bound

func pcgBounded*(rng: var Rng32, bound: uint32): uint32 {.inline.} =
  let threshold = -bound mod bound

  while true:
    let r = next(rng)

    if r >= threshold:
      return r mod bound

func pcgBounded*(rng: var Rng64, bound: uint64): uint64 {.inline.} =
  let threshold = -bound mod bound

  while true:
    let r = next(rng)

    if r >= threshold:
      return r mod bound

func pcgBounded*(rng: var Rng128, bound: UInt128): UInt128 {.inline.} =
  let threshold = -bound mod bound

  while true:
    let r = next(rng)

    if r >= threshold:
      return r mod bound

func pcgBoundedDivisionless*(rng: var Rng8, bound: uint8): uint8 {.inline.} =
  ## https://lemire.me/blog/2016/06/30/fast-random-shuffling/
  ## https://arxiv.org/abs/1805.10941
  var
    multiresult = uint16(next(rng)) * uint16(bound)
    leftover = cast[uint8](multiresult)

  if leftover < bound:
    let threshold = -bound mod bound

    while leftover < threshold:
      multiresult = uint16(next(rng)) * uint16(bound)
      leftover = cast[uint8](multiresult)

  uint8(multiresult shr 8)

func pcgBoundedDivisionless*(rng: var Rng16, bound: uint16): uint16 {.inline.} =
  var
    multiresult = uint32(next(rng)) * uint32(bound)
    leftover = cast[uint16](multiresult)

  if leftover < bound:
    let threshold = -bound mod bound

    while leftover < threshold:
      multiresult = uint32(next(rng)) * uint32(bound)
      leftover = cast[uint16](multiresult)

  uint16(multiresult shr 16)

func pcgBoundedDivisionless*(rng: var Rng32, bound: uint32): uint32 {.inline.} =
  var
    multiresult = uint64(next(rng)) * uint64(bound)
    leftover = cast[uint32](multiresult)

  if leftover < bound:
    let threshold = -bound mod bound

    while leftover < threshold:
      multiresult = uint64(next(rng)) * uint64(bound)
      leftover = cast[uint32](multiresult)

  uint32(multiresult shr 32)

func pcgBoundedDivisionless*(rng: var Rng64, bound: uint64): uint64 {.inline.} =
  var leftover = mul64by64ToTwo64(next(rng), bound, result)

  if leftover < bound:
    let threshold = -bound mod bound

    while leftover < threshold:
      leftover = mul64by64ToTwo64(next(rng), bound, result)

func pcgBoundedDivisionless*(rng: var Rng128, bound: UInt128): UInt128 {.inline.} =
  var leftover = mul128by128ToTwo128(next(rng), bound, result)

  if leftover < bound:
    let threshold = -bound mod bound

    while leftover < threshold:
      leftover = mul128by128ToTwo128(next(rng), bound, result)

func uniformFloat64*(rng: var Rng64): float64 {.inline.} =
  ## https://prng.di.unimi.it/#remarks
  # uniforme - 9_007_199_254_740_992 float64 diferentes de 0.0 até 0.9999999999999999, cada um aparecendo 2_048 vezes
  # É 1,33x mais lenta que a uniformFloat64MulFree()
  let n = next(rng)

  float64(n shr 11) * 1.11022302462515657e-016'f64

func uniformFloat64MulFree*(rng: var Rng64): float64 {.inline.} =
  ## https://prng.di.unimi.it/#remarks
  # uniforme - 4_503_599_627_370_496 float64 diferentes de 0.0 até 0.9999999999999998, cada um aparecendo 4_096 vezes
  # o bit menos significante sempre será 0
  let n = next(rng)

  cast[float64](0x3FF0000000000000'u64 or (n shr 12)) - 1.0'f64

func uniformFloat32*(rng: var Rng32): float32 {.inline.} =
  # 5.96046457e-8'f32 - uniforme - 16_777_216 flot32 diferentes de 0.0 até 0.9999999559077255, cada um aparecendo 256 vezes
  # É 1,33x mais lenta que a uniformFloat32MulFree()
  let n = next(rng)

  float32(n shr 8) * 5.96046457e-8'f32

func uniformFloat32MulFree*(rng: var Rng32): float32 {.inline.} =
  # uniforme - 8_388_608 float32 diferentes de 0.0 até 0.9999998807907105, cada um aparecendo 512 vezes
  # o bit menos significante sempre será 0
  let n = next(rng)

  cast[float32](0x3F800000'u32 or (n shr 9)) - 1.0'f32

when isMainModule:
  var a = initPcg64(u128(1), u128(2))

  echo pcgBounded(a, 100)
