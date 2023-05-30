# Wyrand - https://github.com/wangyi-fudan/wyhash

## Wyrand is a PRNG created by Wang Yi. It is described as a fast, quality,
## portable and simple PRNG.
##
## **It is not cryptographically secure.**
##
## =========  ===================  ===============  ========
##  PRNG       State size (bits)    Output (bits)    Period
## =========  ===================  ===============  ========
##  wyrand     64                   64               2^64
## =========  ===================  ===============  ========
##
## More information: https://github.com/wangyi-fudan/wyhash
##
## Notes
## =====
## - To add extra protection against entropy loss, compile with
##   `-d:wyrandCondom`.
## - To increase speed on 32-bit systems, compile with `-d:wyrand32Bit`.
##   However, this will produce different results.
## - This module uses the `mul64by64To128` function, from the
##   [nint128](https://github.com/rockcavera/nim-nint128) package. Consider
##   compiling with `-d:useCInt128=cumul64by64To128` for optimization. See more
##   [here](https://rockcavera.github.io/nim-nint128/nint128/nint128_cint128.html).

import pkg/nint128

when defined(wyrand32Bit):
  import ./private/utils

type
  Wyrand* = object ## State of a random number generator.
    state: uint64

func next*(rng: var Wyrand): uint64 {.inline.} =
  ## Returns the next random `uint64` using the `Wyrand` state.
  rng.state += 0xa0761d6478bd642f'u64

  var
    a = rng.state
    b = a xor 0xe7037ed1a0b428db'u64

  when defined(wyrand32Bit):
    let
      hh = (a shr 32) * (b shr 32)
      hl = (a shr 32) * (b and 0xFFFFFFFF'u64)
      lh = (a and 0xFFFFFFFF'u64) * (b shr 32)
      ll = (a and 0xFFFFFFFF'u64) * (b and 0xFFFFFFFF'u64)

    when defined(wyrandCondom):
      a = a xor (rotr(hl, 32) xor hh)
      b = b xor (rotr(lh, 32) xor ll)
    else:
      a = rotr(hl, 32) xor hh
      b = rotr(lh, 32) xor ll
  else:
    let r = mul64by64To128(a, b)

    when defined(wyrandCondom):
      a = a xor r.lo
      b = b xor r.hi
    else:
      a = r.lo
      b = r.hi

  a xor b

func initWyrand*(seed: uint64): Wyrand =
  ## Initializes a new `Wyrand` state using the provided `seed`.
  result.state = seed
