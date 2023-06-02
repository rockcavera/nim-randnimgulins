# http://burtleburtle.net/bob/rand/smallprng.html

## Jenkins's Small Fast RNG (JSF) - so named by the creator of PractRand - is an
## RNG created by Bob Jenkins, described as a small and fast pseudo-random
## number generator.
##
## **It is not cryptographically secure.**
##
## =======  ===================  ===============  =========
##  PRNG     State size (bits)    Output (bits)    Period
## =======  ===================  ===============  =========
##  Jsf32    128                  32               ~ 2^127
##  Jsf64    256                  64               ~ 2^255
## =======  ===================  ===============  =========
##
## The period may vary according to the seed used, as these generators do not
## have a guaranteed size in their period.
##
## More information: http://burtleburtle.net/bob/rand/smallprng.html
##                   https://www.pcg-random.org/posts/bob-jenkins-small-prng-passes-practrand.html

import ./private/[exporter, utils]

type
  Jsf32* = object ## State of a random number generator.
    state: array[4, uint32]

  Jsf64* = object ## State of a random number generator.
    state: array[4, uint64]

template nextImpl(r1, r2, r3) =
  let e = rng.state[0] - rotl(rng.state[1], r1)

  rng.state[0] = rng.state[1] xor rotl(rng.state[2], r2)
  rng.state[1] = when r3 > 0: rng.state[2] + rotl(rng.state[3], r3)
                 else: rng.state[2] + rng.state[3]
  rng.state[2] = rng.state[3] + e
  rng.state[3] = e + rng.state[0]

  return rng.state[3]

template initJsfImpl() =
  result.state[0] = type(result.state[0])(0xf1ea5eed)
  result.state[1] = seed
  result.state[2] = seed
  result.state[3] = seed

  for i in 1 .. 20:
    discard next(result)

{.push overflowChecks: off, raises: [].}

# Jsf32
func next*(rng: var Jsf32): uint32 {.inline.} =
  ## Returns the next random `uint32` using the `Jsf32` state.
  nextImpl(27'i32, 17'i32, 0'i32)

func initJsf32*(seed: uint32): Jsf32 =
  ## Initializes a new `Jfc32` state using the provided `seed`.
  initJsfImpl()

# Jsf64
func next*(rng: var Jsf64): uint64 {.inline.} =
  ## Returns the next random `uint64` using the `Jsf64` state.
  nextImpl(7'i32, 13'i32, 37'i32)

func initJsf64*(seed: uint64): Jsf64 =
  ## Initializes a new `Jfc64` state using the provided `seed`.
  initJsfImpl()

{.pop.}

addRng(Jsf32)
addRng(Jsf64)
