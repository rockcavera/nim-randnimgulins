## Xoroshiro (xor/rotate/shift/rotate) is a family of pseudorandom number
## generators designed by David Blackman and Sebastiano Vigna.
##
## **It is not cryptographically secure.**
##
## ====================  ===================  ===============  ============
##  PRNG*                 State size (bits)    Output (bits)    Period
## ====================  ===================  ===============  ============
##  `xoroshiro64*`_       64                   32               2^64 - 1
##  `xoroshiro64**`_      64                   32               2^64 - 1
##  `xoroshiro128+`_      128                  64               2^128 - 1
##  `xoroshiro128++`_     128                  64               2^128 - 1
##  `xoroshiro128*`_      128                  64               2^128 - 1
##  `xoroshiro128**`_     128                  64               2^128 - 1
##  `xoroshiro1024+`_     1068                 64               2^1024 - 1
##  `xoroshiro1024++`_    1068                 64               2^1024 - 1
##  `xoroshiro1024*`_     1068                 64               2^1024 - 1
##  `xoroshiro1024**`_    1068                 64               2^1024 - 1
## ====================  ===================  ===============  ============
##
## .. _xoroshiro64*: https://prng.di.unimi.it/xoroshiro64star.c
## .. _xoroshiro64**: http://prng.di.unimi.it/xoroshiro64starstar.c
## .. _xoroshiro128+: https://prng.di.unimi.it/xoroshiro128plus.c
## .. _xoroshiro128++: https://prng.di.unimi.it/xoroshiro128plusplus.c
## .. _xoroshiro128*: http://vigna.di.unimi.it/ftp/papers/ScrambledLinear.pdf
## .. _xoroshiro128**: https://prng.di.unimi.it/xoroshiro128starstar.c
## .. _xoroshiro1024+: http://vigna.di.unimi.it/ftp/papers/ScrambledLinear.pdf
## .. _xoroshiro1024++: https://prng.di.unimi.it/xoroshiro1024plusplus.c
## .. _xoroshiro1024*: https://prng.di.unimi.it/xoroshiro1024star.c
## .. _xoroshiro1024**: https://prng.di.unimi.it/xoroshiro1024starstar.c
##
## \* C implementation adapted for Nim on the link.
##
## More information: https://prng.di.unimi.it/ or http://vigna.di.unimi.it/ftp/papers/ScrambledLinear.pdf

import ./private/[exporter, utils]

# xoroshiro64* 1.0 https://prng.di.unimi.it/xoroshiro64star.c
# xoroshiro64** 1.0 http://prng.di.unimi.it/xoroshiro64starstar.c
# xoroshiro128+ 1.0 https://prng.di.unimi.it/xoroshiro128plus.c
# xoroshiro128++ 1.0 https://prng.di.unimi.it/xoroshiro128plusplus.c
# xoroshiro128* 1.0 http://vigna.di.unimi.it/ftp/papers/ScrambledLinear.pdf
# xoroshiro128** 1.0 https://prng.di.unimi.it/xoroshiro128starstar.c

type
  Xoroshiro64star* = object
    state: array[2, uint32]

  Xoroshiro64starstar* = object
    state: array[2, uint32]

  Xoroshiro128plus* = object
    state: array[2, uint64]

  Xoroshiro128plusplus* = object
    state: array[2, uint64]

  Xoroshiro128star* = object
    state: array[2, uint64]

  Xoroshiro128starstar* = object
    state: array[2, uint64]

template xoroshiro(aRotl, bShiftl, cRotl: int, scrambler: untyped) =
  let s0 {.inject.} = rng.state[0]

  var s1 {.inject.} = rng.state[1]

  scrambler

  s1 = s1 xor s0
  rng.state[0] = rotl(s0, aRotl) xor s1 xor (s1 shl bShiftl)
  rng.state[1] = rotl(s1, cRotl)

proc next*(rng: var Xoroshiro64star): uint32 {.inline.} =
  xoroshiro(26, 9, 13):
    result = s0 * 0x9E3779BB'u32

proc next*(rng: var Xoroshiro64starstar): uint32 {.inline.} =
  xoroshiro(26, 9, 13):
    result = rotl(s0 * 0x9E3779BB'u32, 5) * 5'u32

proc next*(rng: var Xoroshiro128plus): uint64 {.inline.} =
  xoroshiro(24, 16, 37):
    result = s0 + s1

proc next*(rng: var Xoroshiro128plusplus): uint64 {.inline.} =
  xoroshiro(49, 21, 28):
    result = rotl(s0 + s1, 17) + s0

proc next*(rng: var Xoroshiro128star): uint64 {.inline.} =
  xoroshiro(24, 16, 37):
    result = s0 * 0x9e3779b97f4a7c13'u64

proc next*(rng: var Xoroshiro128starstar): uint64 {.inline.} =
  xoroshiro(24, 16, 37):
    result = rotl(s0 * 5'u64, 7) * 9'u64

proc initXoroshiro64star*(seed: varargs[uint32]): Xoroshiro64star =
  initImpl(2, -1)

proc initXoroshiro64starstar*(seed: varargs[uint32]): Xoroshiro64starstar =
  initImpl(2, -1)

proc initXoroshiro128plus*(seed: varargs[uint64]): Xoroshiro128plus =
  initImpl(2, -1)

proc initXoroshiro128plusplus*(seed: varargs[uint64]): Xoroshiro128plusplus =
  initImpl(2, -1)

proc initXoroshiro128star*(seed: varargs[uint64]): Xoroshiro128star =
  initImpl(2, -1)

proc initXoroshiro128starstar*(seed: varargs[uint64]): Xoroshiro128starstar =
  initImpl(2, -1)

# xoroshiro1024+ 1.0 http://vigna.di.unimi.it/ftp/papers/ScrambledLinear.pdf
# xoroshiro1024++ 1.0 https://prng.di.unimi.it/xoroshiro1024plusplus.c
# xoroshiro1024* 1.0 https://prng.di.unimi.it/xoroshiro1024star.c
# xoroshiro1024** 1.0 https://prng.di.unimi.it/xoroshiro1024starstar.c

type
  Xoroshiro1024plus* = object
    state: array[16, uint64]
    p: int32

  Xoroshiro1024plusplus* = object
    state: array[16, uint64]
    p: int32

  Xoroshiro1024star* = object
    state: array[16, uint64]
    p: int32

  Xoroshiro1024starstar* = object
    state: array[16, uint64]
    p: int32

template xoroshiro1024Impl(scrambler: untyped) =
  let q = rng.p

  rng.p = (rng.p + 1) and 15

  let s0 {.inject.} = rng.state[rng.p]

  var s15 {.inject.} = rng.state[q]

  scrambler

  s15 = s15 xor s0
  rng.state[q] = rotl(s0, 25) xor s15 xor (s15 shl 27)
  rng.state[rng.p] = rotl(s15, 36)

proc next*(rng: var Xoroshiro1024plus): uint64 {.inline.} =
  xoroshiro1024Impl:
    result = s0 + s15

proc next*(rng: var Xoroshiro1024plusplus): uint64 {.inline.} =
  xoroshiro1024Impl:
    result = rotl(s0 + s15, 23) + s15

proc next*(rng: var Xoroshiro1024star): uint64 {.inline.} =
  xoroshiro1024Impl:
    result = s0 * 0x9e3779b97f4a7c13'u64

proc next*(rng: var Xoroshiro1024starstar): uint64 {.inline.} =
  xoroshiro1024Impl:
    result = rotl(s0 * 5, 7) * 9

proc initXoroshiro1024plus*(seed: varargs[uint64]): Xoroshiro1024plus =
  initImpl(16, 0'i32)

proc initXoroshiro1024plusplus*(seed: varargs[uint64]): Xoroshiro1024plusplus =
  initImpl(16, 0'i32)

proc initXoroshiro1024star*(seed: varargs[uint64]): Xoroshiro1024star =
  initImpl(16, 0'i32)

proc initXoroshiro1024starstar*(seed: varargs[uint64]): Xoroshiro1024starstar =
  initImpl(16, 0'i32)

addRng(Xoroshiro64star)
addRng(Xoroshiro64starstar)
addRng(Xoroshiro128plus)
addRng(Xoroshiro128plusplus)
addRng(Xoroshiro128star)
addRng(Xoroshiro128starstar)
addRng(Xoroshiro1024plus)
addRng(Xoroshiro1024plusplus)
addRng(Xoroshiro1024star)
addRng(Xoroshiro1024starstar)
