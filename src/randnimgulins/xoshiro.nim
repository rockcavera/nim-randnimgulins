## Xoshiro (xor/shift/rotate) is a family of pseudorandom number generators
## designed by David Blackman and Sebastiano Vigna.
##
## **It is not cryptographically secure.**
##
## =================  ===================  ===============  ===========
##  PRNG*              State size (bits)    Output (bits)    Period
## =================  ===================  ===============  ===========
##  `xoshiro128+`_     128                  32               2^128 - 1
##  `xoshiro256+`_     256                  64               2^256 - 1
##  `xoshiro512+`_     512                  64               2^512 - 1
##  `xoshiro128++`_    128                  32               2^128 - 1
##  `xoshiro256++`_    256                  64               2^256 - 1
##  `xoshiro512++`_    512                  64               2^512 - 1
##  `xoshiro128**`_    128                  32               2^128 - 1
##  `xoshiro256**`_    256                  64               2^256 - 1
##  `xoshiro512**`_    512                  64               2^512 - 1
## =================  ===================  ===============  ===========
##
## .. _xoshiro128+: https://prng.di.unimi.it/xoshiro128plus.c
## .. _xoshiro256+: https://prng.di.unimi.it/xoshiro256plus.c
## .. _xoshiro512+: https://prng.di.unimi.it/xoshiro512plus.c
## .. _xoshiro128++: https://prng.di.unimi.it/xoshiro128plusplus.c
## .. _xoshiro256++: https://prng.di.unimi.it/xoshiro256plusplus.c
## .. _xoshiro512++: https://prng.di.unimi.it/xoshiro512plusplus.c
## .. _xoshiro128**: https://prng.di.unimi.it/xoshiro128starstar.c
## .. _xoshiro256**: https://prng.di.unimi.it/xoshiro256starstar.c
## .. _xoshiro512**: https://prng.di.unimi.it/xoshiro512starstar.c
##
## \* C implementation adapted for Nim on the link.
##
## More information: https://prng.di.unimi.it/ or http://vigna.di.unimi.it/ftp/papers/ScrambledLinear.pdf

import ./private/utils

template shiftXorsRotlImpl(shift1, rotl1) =
  let t = rng.state[1] shl shift1

  rng.state[2] = rng.state[2] xor rng.state[0]
  when len(rng.state) == 4:
    rng.state[3] = rng.state[3] xor rng.state[1]
    rng.state[1] = rng.state[1] xor rng.state[2]
    rng.state[0] = rng.state[0] xor rng.state[3]
    rng.state[2] = rng.state[2] xor t
    rng.state[3] = rotl(rng.state[3], rotl1)
  elif len(rng.state) == 8:
    rng.state[5] = rng.state[5] xor rng.state[1]
    rng.state[1] = rng.state[1] xor rng.state[2]
    rng.state[7] = rng.state[7] xor rng.state[3]
    rng.state[3] = rng.state[3] xor rng.state[4]
    rng.state[4] = rng.state[4] xor rng.state[5]
    rng.state[0] = rng.state[0] xor rng.state[6]
    rng.state[6] = rng.state[6] xor rng.state[7]
    rng.state[6] = rng.state[6] xor t
    rng.state[7] = rotl(rng.state[7], rotl1)

# xoshiro128+ 1.0 https://prng.di.unimi.it/xoshiro128plus.c
# xoshiro256+ 1.0 https://prng.di.unimi.it/xoshiro256plus.c
# xoshiro512+ 1.0 https://prng.di.unimi.it/xoshiro512plus.c

type
  Xoshiro128plus* = object
    state: array[4, uint32]

  Xoshiro256plus* = object
    state: array[4, uint64]

  Xoshiro512plus* = object
    state: array[8, uint64]

template xoshiroplusImpl(index1, shift1, rotl1) =
  result = rng.state[0] + rng.state[index1]

  shiftXorsRotlImpl(shift1, rotl1)

{.push overflowChecks: off, raises: [].}

func next*(rng: var Xoshiro128plus): uint32 {.inline.} =
  xoshiroplusImpl(3, 9, 11)

func next*(rng: var Xoshiro256plus): uint64 {.inline.} =
  xoshiroplusImpl(3, 17, 45)

func next*(rng: var Xoshiro512plus): uint64 {.inline.} =
  xoshiroplusImpl(2, 11, 21)

{.pop.}

func initXoshiro128plus*(seed: varargs[uint32]): Xoshiro128plus =
  initImpl(4, -1)

func initXoshiro256plus*(seed: varargs[uint64]): Xoshiro256plus =
  initImpl(4, -1)

func initXoshiro512plus*(seed: varargs[uint64]): Xoshiro512plus =
  initImpl(8, -1)

# xoshiro128++ 1.0 https://prng.di.unimi.it/xoshiro128plusplus.c
# xoshiro256++ 1.0 https://prng.di.unimi.it/xoshiro256plusplus.c
# xoshiro512++ 1.0 https://prng.di.unimi.it/xoshiro512plusplus.c

type
  Xoshiro128plusplus* = object
    state: array[4, uint32]

  Xoshiro256plusplus* = object
    state: array[4, uint64]

  Xoshiro512plusplus* = object
    state: array[8, uint64]

template xoshiroplusplusImpl(index1, index2, rotl1, shift1, rotl2) =
  result = rotl(rng.state[index1] + rng.state[index2], rotl1) + rng.state[index1]

  shiftXorsRotlImpl(shift1, rotl2)

{.push overflowChecks: off, raises: [].}

func next*(rng: var Xoshiro128plusplus): uint32 {.inline.} =
  xoshiroplusplusImpl(0, 3, 7, 9, 11)

func next*(rng: var Xoshiro256plusplus): uint64 {.inline.} =
  xoshiroplusplusImpl(0, 3, 23, 17, 45)

func next*(rng: var Xoshiro512plusplus): uint64 {.inline.} =
  xoshiroplusplusImpl(2, 0, 17, 11, 21)

{.pop.}

func initXoshiro128plusplus*(seed: varargs[uint32]): Xoshiro128plusplus =
  initImpl(4, -1)

func initXoshiro256plusplus*(seed: varargs[uint64]): Xoshiro256plusplus =
  initImpl(4, -1)

func initXoshiro512plusplus*(seed: varargs[uint64]): Xoshiro512plusplus =
  initImpl(8, -1)

# xoshiro128** 1.1 https://prng.di.unimi.it/xoshiro128starstar.c
# xoshiro256** 1.0 https://prng.di.unimi.it/xoshiro256starstar.c
# xoshiro512** 1.0 https://prng.di.unimi.it/xoshiro512starstar.c

type
  Xoshiro128starstar* = object
    state: array[4, uint32]

  Xoshiro256starstar* = object
    state: array[4, uint64]

  Xoshiro512starstar* = object
    state: array[8, uint64]

template xoshirostarstarImpl(shift1, rotl1) =
  result = rotl(rng.state[1] * 5, 7) * 9

  shiftXorsRotlImpl(shift1, rotl1)

{.push overflowChecks: off, raises: [].}

func next*(rng: var Xoshiro128starstar): uint32 {.inline.} =
  xoshirostarstarImpl(9, 11)

func next*(rng: var Xoshiro256starstar): uint64 {.inline.} =
  xoshirostarstarImpl(17, 45)

func next*(rng: var Xoshiro512starstar): uint64 {.inline.} =
  xoshirostarstarImpl(11, 21)

{.pop.}

func initXoshiro128starstar*(seed: varargs[uint32]): Xoshiro128starstar =
  initImpl(4, -1)

func initXoshiro256starstar*(seed: varargs[uint64]): Xoshiro256starstar =
  initImpl(4, -1)

func initXoshiro512starstar*(seed: varargs[uint64]): Xoshiro512starstar =
  initImpl(8, -1)
