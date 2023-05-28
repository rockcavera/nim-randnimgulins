# Permuted Congruential Generator (PCG)
# https://github.com/imneme/pcg-cpp
# https://www.pcg-random.org/

## Permuted Congruential Generator (PCG) is a family of pseudorandom number
## generators designed by Melissa E. O'Neill, described as being simple, fast,
## statically good, and with a small state size.
##
## **It is not cryptographically secure.**
##
## More information: https://www.pcg-random.org/
##
## ## Notes
## =====
## - This module uses the `mul64by64To128` function, from the
##   [nint128](https://github.com/rockcavera/nim-nint128) package. Consider
##   compiling with `-d:useCInt128=cumul64by64To128` for optimization. See more
##   [here](https://rockcavera.github.io/nim-nint128/nint128/nint128_cint128.html).

import pkg/nint128

import ./private/utils

{.push overflowChecks: off, warnings: off, raises: [].}

type
  PcgUInts = SomeUnsignedInt|UInt128

  PcgVariants* = enum
    PcgSingleStream, # OneSeq - all instances use the same fixed constant, thus the RNG always somewhere in same sequence
    PcgMcg, # Fast - adds zero, resulting in a single stream and reduced period
    PcgSpecificStream, # SetSeq - the constant can be changed at any time, selecting a different random sequence
    PcgUniqueStream # Unique - the constant is based on the memory address of the object, thus every RNG has its own unique sequence

  PcgOutputMixin* = enum
    PcgXSH_RS,
    PcgXSH_RR,
    PcgRXS,
    PcgRXS_M_XS,
    PcgRXS_M,
    PcgDXSM,
    PcgXSL_RR,
    PcgXSL_RR_RR,
    PcgXSH,
    PcgXSL

  PcgMultipliers* = enum
    PcgDefaultMultiplier,
    PcgCheapMultiplier

  PcgOutputPrevious* = enum
    PcgOPDefault
    PcgOPFalse
    PcgOPTrue

#
# Helper templates
#

template zero[T: SomeUnsignedInt](x: typedesc[T]): T =
  T(0)

template one[T: SomeUnsignedInt](x: typedesc[T]): T =
  T(1)

template three[T: RngSomeInteger](x: typedesc[T]): T =
  when x is SomeUnsignedInt:
    T(3)
  elif x is UInt128:
    UInt128(hi: 0'u64, lo: 3'u64)

template four[T: RngSomeInteger](x: typedesc[T]): T =
  when x is SomeUnsignedInt:
    T(4)
  elif x is UInt128:
    UInt128(hi: 0'u64, lo: 4'u64)

template toInt[T: RngSomeInteger](x: T): int =
  toSomeIntegerUnsafe[int](x)

template toOutput[T: PcgUInts](x: PcgUInts): T =
  toSomeIntegerUnsafe[T](x)

template addressToSomeUint[T: PcgUInts](x: pointer): T =
  when T is SomeUnsignedInt:
    cast[T](x)
  elif T is UInt128:
    UInt128(hi: 0'u64, lo: cast[uint64](x))

#
# END Helper templates
#

template mcgMultiplier[T: PcgUInts](typ: typedesc[T]): T =
  when typ is uint8:
    217'u8
  elif typ is uint16:
    62169'u16
  elif typ is uint32:
    277803737'u32
  elif typ is uint64:
    12605985483714917081'u64
  elif typ is UInt128:
    UInt128(hi: 17766728186571221404'u64, lo: 12605985483714917081'u64)

template mcgUnmultiplier[T: PcgUInts](typ: typedesc[T]): T =
  when typ is uint8:
    105'u8
  elif typ is uint16:
    28009'u16
  elif typ is uint32:
    2897767785'u32
  elif typ is uint64:
    15009553638781119849'u64
  elif typ is UInt128:
    UInt128(hi: 14422606686972528997'u64, lo: 15009553638781119849'u64)

template defaultMultiplier[T: PcgUInts](typ: typedesc[T]): T =
  when typ is uint8:
    141'u8
  elif typ is uint16:
    12829'u16
  elif typ is uint32:
    747796405'u32
  elif typ is uint64:
    6364136223846793005'u64
  elif typ is UInt128:
    UInt128(hi: 2549297995355413924'u64, lo: 4865540595714422341'u64)

template defaultSeed[T: PcgUInts](typ: typedesc[T]): T =
  when typ is uint8:
    0xe5'u8
  elif typ is uint16:
    0xa5e5'u16
  elif typ is uint32:
    0xd15ea5e5'u32
  elif typ is uint64:
    0xcafef00dd15ea5e5'u64
  elif typ is UInt128:
    UInt128(hi: 0'u64, lo: 0xcafef00dd15ea5e5'u64)

template cheapMultiplier[T: PcgUInts](typ: typedesc[T]): T =
  when typ is UInt128:
    0xda942042e4dd58b5'u64
  else:
    defaultMultiplier(typ)

template defaultIncrement[T: PcgUInts](typ: typedesc[T]): T =
  when typ is uint8:
    77'u8
  elif typ is uint16:
    47989'u16
  elif typ is uint32:
    2891336453'u32
  elif typ is uint64:
    1442695040888963407'u64
  elif typ is UInt128:
    UInt128(hi: 6364136223846793005'u64, lo: 1442695040888963407'u64)

func unxorshift[T](x: T, bits: int, shift: int): T =
  if (2 * shift) >= bits:
    result = x xor (x shr shift)
  else:
    let
      lowmask1 = (one(T) shl (bits - shift * 2)) - 1
      lowmask2 = (one(T) shl (bits - shift)) - 1
      highmask1 = not(lowmask1)
      bottom1 = x and lowmask1

    var top1 = x

    top1 = (top1 shr shift) xor top1
    top1 = top1 and highmask1

    let x = top1 or bottom1

    var bottom2 = x and lowmask2

    bottom2 = unxorshift(bottom2, bits - shift, shift)
    bottom2 = bottom2 and lowmask1
    result = top1 or bottom2

func advanceImpl[T: PcgUInts](state: T, delta: T, curMult: T, curPlus: T): T =
    var
      accMult = one(T)
      accPlus = zero(T)
      delta = delta
      curMult = curMult
      curPlus = curPlus

    while delta > zero(T):
      if (delta and one(T)) > zero(T):
        accMult = accMult * curMult
        accPlus = accPlus * curMult + curPlus

      curPlus = (curMult + one(T)) * curPlus
      curMult = curMult * curMult

      delta = delta shr 1

    result = accMult * state + accPlus

func distanceImpl[T: PcgUInts](curState: T, newState: T, curMult: T, curPlus: T, mask: T): T =
  var
    curState = curState
    curMult = curMult
    curPlus = curPlus
    theBit = one(T)

  let isMcg = curPlus == zero(T)

  if isMcg:
    theBit = four(T)

  while (curState and mask) != (newState and mask):
    if (curState and theBit) != (newState and theBit):
      curState = curState * curMult + curPlus
      result = result or theBit

    assert((curState and theBit) == (newState and theBit))

    theBit = theBit shl 1
    curPlus = (curMult + one(T)) * curPlus
    curMult = curMult * curMult

  if isMcg:
    result = result shr 2

#
# OUTPUT FUNCTIONS.
#

func output_xsh_rs[I, O](internal: I): O =
  ## XSH RS -- high xorshift, followed by a random shift
  ##
  ## Fast. A good performer.
  const
    ibits = bitsByType(I)
    obits = bitsByType(O)
    sparebits = ibits - obits
    opbits = when (sparebits - 5) >= 64: 5
             elif (sparebits - 4) >= 32: 4
             elif (sparebits - 3) >= 16: 3
             elif (sparebits - 2) >= 4: 2
             elif (sparebits - 1) >= 1: 1
             else: 0
    mask = (1 shl opbits) - 1
    maxrandshift = mask
    topspare = opbits
    bottomspare = sparebits - topspare
    xshift = topspare + (obits + maxrandshift) div 2

  let
    rshift = when opbits > 0: toInt(internal shr (ibits - opbits)) and mask
             else: 0
    internal = (internal shr xshift) xor internal

  result = toOutput[O](internal shr (bottomspare - maxrandshift + rshift))

func output_xsh_rr[I, O](internal: I): O =
  ## XSH RR -- high xorshift, followed by a random rotate
  ##
  ## Fast. A good performer. Slightly better statistically than XSH RS.
  const
    ibits = bitsByType(I)
    obits = bitsByType(O)
    sparebits = ibits - obits
    wantedopbits = when obits >= 128: 7
                   elif obits >= 64: 6
                   elif obits >= 32: 5
                   elif obits >= 16: 4
                   else: 3
    opbits = when sparebits >= wantedopbits: wantedopbits
             else: sparebits
    amplifier = wantedopbits - opbits
    mask = (1 shl opbits) - 1
    topspare = opbits
    bottomspare = sparebits - topspare
    xshift = (topspare + obits) div 2

  let
    rot = when opbits > 0: toInt(internal shr (ibits - opbits)) and mask
          else: 0
    amprot = (rot shl amplifier) and mask
    internal = (internal shr xshift) xor internal

  result = toOutput[O](internal shr bottomspare)
  result = rotr(result, amprot)

func output_rxs[I, O](internal: I): O =
  ## RXS -- random xorshift
  const
    ibits = bitsByType(I)
    obits = bitsByType(O)
    shift = ibits - obits
    extrashift = (obits - shift) div 2

  let
    rshift = when shift > (64 + 8): toInt(internal shr (ibits - 6)) and 63
             elif shift > (32 + 4): toInt(internal shr (ibits - 5)) and 31
             elif shift > (16 + 2): toInt(internal shr (ibits - 4)) and 15
             elif shift > (8 + 1): toInt(internal shr (ibits - 3)) and 7
             elif shift > (4 + 1): toInt(internal shr (ibits - 2)) and 3
             elif shift > (2 + 1): toInt(internal shr (ibits - 1)) and 1
             else: 0
    internal = (internal shr (shift + extrashift - rshift)) xor internal

  result = toOutput[O](internal shr rshift)

func output_rxs_m_xs[I, O](internal: I): O =
  ## RXS M XS -- random xorshift, mcg multiply, fixed xorshift
  ##
  ## The most statistically powerful generator, but all those steps make it
  ## slower than some of the others.  We give it the rottenest jobs.
  ##
  ## Because it's usually used in contexts where the state type and the result
  ## type are the same, it is a permutation and is thus invertable. We thus
  ## provide a function to invert it. This function is used to for the "inside
  ## out" generator used by the extended generator.
  const
    ibits = bitsByType(I)
    obits = bitsByType(O)
    opbits = when obits >= 128: 6
             elif obits >= 64: 5
             elif obits >= 32: 4
             elif obits >= 16: 3
             else: 2
    shift = ibits - obits
    mask = (1 shl opbits) - 1

  let
    rshift = when opbits > 0: toInt(internal shr (ibits - opbits)) and mask
             else: 0
    internal = ((internal shr (opbits + rshift)) xor internal) * mcgMultiplier(typeof(internal))

  result = toOutput[O](internal shr shift)
  result = (result shr ((2 * obits + 2) div 3)) xor result

func unoutput_rxs_m_xs[I, O](internal: I): I =
  const
    ibits = bitsByType(I)
    opbits = when ibits >= 128: 6
             elif ibits >= 64: 5
             elif ibits >= 32: 4
             elif ibits >= 16: 3
             else: 2
    mask = (1 shl opbits) - 1

  result = unxorshift(internal, ibits, (2 * ibits + 2) div 3)
  result = result * mcgUnmultiplier(typeof(result))

  let rshift = when opbits > 0: toInt(result shr (ibits - opbits)) and mask
               else: 0

  result = unxorshift(result, ibits, opbits + rshift)

func output_rxs_m[I, O](internal: I): O =
  ## RXS M -- random xorshift, mcg multiply
  const
    ibits = bitsByType(I)
    obits = bitsByType(O)
    opbits = when obits >= 128: 6
             elif obits >= 64: 5
             elif obits >= 32: 4
             elif obits >= 16: 3
             else: 2
    shift = ibits - obits
    mask = (1 shl opbits) - 1

  let
    rshift = when opbits > 0: toInt(internal shr (ibits - opbits)) and mask
             else: 0
    internal = ((internal shr (opbits + rshift)) xor internal) * mcgMultiplier(typeof(internal))

  result = toOutput[O](internal shr shift)

func output_dxsm[I, O](internal: I): O =
  ## DXSM -- double xorshift multiply
  ##
  ## This is a new, more powerful output permutation (added in 2019). It's a
  ## more comprehensive scrambling than RXS M, but runs faster on 128-bit types.
  ## Although primarily intended for use at large sizes, also works at smaller
  ## sizes as well.
  ##
  ## This permutation is similar to xorshift multiply hash functions, except
  ## that one of the multipliers is the LCG multiplier (to avoid needing to have
  ## a second constant) and the other is based on the low-order bits. This
  ## latter aspect means that the scrambling applied to the high bits depends on
  ## the low bits, and makes it (to my eye) impractical to back out the
  ## permutation without having the low-order bits.
  const
    ibits = bitsByType(I)
    obits = bitsByType(O)

  static:
    doAssert(obits <= (ibits div 2),
             "Output type must be half the size of the state type.")

  result = toOutput[O](internal shr (ibits - obits))

  var lo = toOutput[O](internal)

  lo = lo or one(O)
  # result = (result shr (obits div 2)) xor result
  result = (result shr (obits shr 1)) xor result # N div 2 = N shr 1
  result = result * toOutput[O](cheapMultiplier(internal))
  # result = (result shr (3 * (obits div 4))) xor result
  result = (result shr (3 * (obits shr 2))) xor result # N div 4 = N shr 2
  result = result * lo

func output_xsl_rr[I, O](internal: I): O =
  ## XSL RR -- fixed xorshift (to low bits), random rotate
  ##
  ## Useful for 128-bit types that are split across two CPU registers.
  const
    ibits = bitsByType(I)
    obits = bitsByType(O)
    sparebits = ibits - obits
    wantedopbits = when obits >= 128: 7
                   elif obits >= 64: 6
                   elif obits >= 32: 5
                   elif obits >= 16: 4
                   else: 3
    opbits = when sparebits >= wantedopbits: wantedopbits
             else: sparebits
    amplifier = wantedopbits - opbits
    mask = (1 shl opbits) - 1
    topspare = sparebits
    bottomspare = sparebits - topspare
    xshift = (topspare + obits) div 2

  let
    rot = when opbits > 0: toInt(internal shr (ibits - opbits)) and mask
          else: 0
    amprot = (rot shl amplifier) and mask
    internal = (internal shr xshift) xor internal

  result = toOutput[O](internal shr bottomspare)
  result = rotr(result, amprot)

func output_xsl_rr_rr[I, O](internal: I): I =
  ## XSL RR RR -- fixed xorshift (to low bits), random rotate (both parts)
  ##
  ## Useful for 128-bit types that are split across two CPU registers.
  ## If you really want an invertable 128-bit RNG, I guess this is the one.
  when I is UInt128:
    type Htype = uint64
  elif I is uint64:
    type Htype = uint32
  elif I is uint32:
    type Htype = uint16
  elif I is uint16:
    type Htype = uint8

  const
    ibits = bitsByType(I)
    htypebits = bitsByType(Htype)
    sparebits = ibits - htypebits
    wantedopbits = when htypebits >= 128: 7
                   elif htypebits >= 64: 6
                   elif htypebits >= 32: 5
                   elif htypebits >= 16: 4
                   else: 3
    opbits = when sparebits >= wantedopbits: wantedopbits
             else: sparebits
    amplifier = wantedopbits - opbits
    mask = (1 shl opbits) - 1
    topspare = sparebits
    xshift = (topspare + htypebits) div 2

  let
    rot = when opbits > 0: toInt(internal shr (ibits - opbits)) and mask
          else: 0
    amprot = (rot shl amplifier) and mask
    internal = (internal shr xshift) xor internal

  var lowbits = toOutput[Htype](internal)

  lowbits = rotr(lowbits, amprot)

  var highbits = toOutput[Htype](internal shr topspare)

  let
    rot2 = lowbits and mask
    amprot2 = (rot2 shl amplifier) and mask

  highbits = rotr(highbits, amprot2.int)
  result = (toOutput[I](highbits) shl topspare) xor toOutput[I](lowbits)

func output_xsh[I, O](internal: I): O =
  ## XSH -- fixed xorshift (to high bits)
  ##
  ## You shouldn't use this at 64-bits or less.
  const
    ibits = bitsByType(I)
    obits = bitsByType(O)
    sparebits = ibits - obits
    topspare = 0
    bottomspare = sparebits - topspare
    xshift = (topspare + obits) div 2

  let internal = (internal shr xshift) xor internal

  result = toOutput[O](internal shr bottomspare)

func output_xsl[I, O](internal: I): O =
  ## XSL -- fixed xorshift (to low bits)
  ##
  ## You shouldn't use this at 64-bits or less.
  const
    ibits = bitsByType(I)
    obits = bitsByType(O)
    sparebits = ibits - obits
    topspare = sparebits
    bottomspare = sparebits - topspare
    xshift = (topspare + obits) div 2

  let internal = (internal shr xshift) xor internal

  result = toOutput[O](internal shr bottomspare)

#
# End Output Functions
#

template outputFunc[I, O](state: I, outputMixin: PcgOutputMixin): O =
  when outputMixin == PcgXSH_RS:
    output_xsh_rs[I, O](state)
  elif outputMixin == PcgXSH_RR:
    output_xsh_rr[I, O](state)
  elif outputMixin == PcgRXS:
    output_rxs[I, O](state)
  elif outputMixin == PcgRXS_M_XS:
    output_rxs_m_xs[I, O](state)
  elif outputMixin == PcgRXS_M:
    output_rxs_m[I, O](state)
  elif outputMixin == PcgDXSM:
    output_dxsm[I, O](state)
  elif outputMixin == PcgXSL_RR:
    output_xsl_rr[I, O](state)
  elif outputMixin == PcgXSL_RR_RR:
    output_xsl_rr_rr[I, O](state)
  elif outputMixin == PcgXSH:
    output_xsh[I, O](state)
  elif outputMixin == PcgXSL:
    output_xsl[I, O](state)

template pcgMultiplier[T: PcgUInts](typ: typedesc[T], multiplierType: PcgMultipliers): T =
  when multiplierType == PcgDefaultMultiplier:
    defaultMultiplier(typ)
  elif multiplierType == PcgCheapMultiplier:
    cheapMultiplier(typ)

template pcgIncrement[T: PcgUInts](rng: var typed, typ: typedesc[T], variant: PcgVariants): T =
  when variant == PcgSingleStream:
    defaultIncrement(typ)
  elif variant == PcgMcg:
    zero(typ)
  elif variant == PcgSpecificStream:
    rng.inc
  elif variant == PcgUniqueStream:
    addressToSomeUint[typ](addr rng) or one(typ)

template pcgStepImpl[I: PcgUInts](rng: var typed, iType: typedesc[I], variant: PcgVariants,
                                  multiplierType: PcgMultipliers) =
  rng.state *= pcgMultiplier(iType, multiplierType)

  when variant != PcgMcg:
    rng.state += pcgIncrement(rng, iType, variant)

template pcgInitImpl[I: PcgUInts](rng: var typed, iType: typedesc[I], variant: PcgVariants,
                                  multiplierType: PcgMultipliers, seed: PcgUints,
                                  hasStreamSeed: bool = false) =
  when variant == PcgMcg:
    rng.state = seed or three(iType) # For PcgMCG the lowest 2 bits (least significant) never change.
  else:
    when variant == PcgSpecificStream:
      when hasStreamSeed:
        rng.inc = (stream shl 1) or one(iType)
      else:
        rng.inc = defaultIncrement(iType)

    rng.state = seed + pcgIncrement(rng, iType, variant)

    pcgStepImpl(rng, iType, variant, multiplierType)

func getOutputPrevious[I: PcgUInts](outputPrevious: PcgOutputPrevious,
                                    iType: typedesc[I]): bool {.compileTime.} =
  case outputPrevious
  of PcgOPDefault:
    result = sizeof(iType) <= 8
  of PcgOPFalse:
    result = false
  of PcgOPTrue:
    result = true

template pcgConstructor*[I, O: PcgUInts](name: untyped, variant: PcgVariants,
                                         outputMixin: PcgOutputMixin, iType: typedesc[I],
                                         oType: typedesc[O],
                                         multiplierType: PcgMultipliers = PcgDefaultMultiplier,
                                         outputPrevious: PcgOutputPrevious = PcgOPDefault,
                                         inlineNext: bool = true) {.dirty.} =
  when iType isnot PcgUInts or oType isnot PcgUInts:
    {.fatal: "iType or oType not is `PcgUInts`".}

  when variant == PcgSpecificStream:
    type name* = object
      state: iType
      inc: iType
  else:
    type name* = object
      state: iType

  func multiplier(rng: name): iType {.inline.} =
    result = pcgMultiplier(iType, multiplierType)

  func increment(rng: var name): iType {.inline.} =
    result = pcgIncrement(rng, iType, variant)

  when variant == PcgSpecificStream:
    func setStream*(rng: var name, stream: iType) =
      rng.inc = (stream shl 1) or one(iType)

    func `init name`*(seed: iType, stream: iType): name =
      pcgInitImpl(result, iType, variant, multiplierType, seed, true)

  func `init name`*(seed: iType): name =
    pcgInitImpl(result, iType, variant, multiplierType, seed)

  func `init name`*(): name =
    pcgInitImpl(result, iType, variant, multiplierType, defaultSeed(iType))

  func `init name`*(rng: name): name =
    result = rng

  when inlineNext:
    func next*(rng: var name): oType {.inline.}
  else:
    func next*(rng: var name): oType

  func next*(rng: var name): oType =
    when getOutputPrevious(outputPrevious, iType):
      let state = rng.state

      pcgStepImpl(rng, iType, variant, multiplierType)

      result = outputFunc[iType, oType](state, outputMixin)
    else:
      pcgStepImpl(rng, iType, variant, multiplierType)

      result = outputFunc[iType, oType](rng.state, outputMixin)

  func resultType*(rng: name): oType = discard
  func stateType*(rng: name): iType = discard

  func min*(rng: name): oType = zero(oType)
  func max*(rng: name): oType = high(oType)

  func seed*(rng: var name, newSeed: iType) =
    rng = `init name`(newSeed)

  func periodPow2*(rng: name): int =
    const
      ibits = sizeof(iType) * 8
      period = when variant == PcgMcg: ibits - 2
               else: ibits

    result = period

  func streamsPow2*(rng: name): int =
    when variant == PcgSpecificStream:
      const steams = sizeof(iType) * 8 - 1

      result = steams
    elif variant == PcgUniqueStream:
      const steams = when sizeof(iType) < sizeof(int): sizeof(iType)
                     else: sizeof(int) * 8 - 1

      result = steams
    else:
      result = 0

  func advance*(rng: var name, delta: iType) =
    rng.state = advanceImpl(rng.state, delta, pcgMultiplier(iType, multiplierType),
                            pcgIncrement(rng, iType, variant))

  func backstep*(rng: var name, delta: iType) =
    advance(rng, -delta)

  func throwOut*(rng: var name, n: iType) =
    advance(rng, n)

  func wrapped*(rng: var name): bool =
    when variant == PcgMcg:
      result = rng.state == three(iType)
    else:
      result = rng.state == zero(iType)

  func `==`*(rng1, rng2: var name): bool =
    result = rng1.state == rng2.state

    when variant in {PcgSpecificStream, PcgUniqueStream}:
      result = result and (pcgIncrement(rng1, iType, variant) == pcgIncrement(rng2, iType, variant))

  func `-`*(rng1, rng2: var name): iType =
    const mask = not(zero(iType))

    if pcgIncrement(rng1, iType, variant) == pcgIncrement(rng2, iType, variant):
      result = distanceImpl(rng2.state, rng1.state, pcgMultiplier(iType, multiplierType),
                            pcgIncrement(rng2, iType, variant), mask)
    else:
      let rng1Diff = pcgIncrement(rng1, iType, variant) + (pcgMultiplier(iType, multiplierType) - one(iType)) * rng1.state

      var rng2Diff = pcgIncrement(rng2, iType, variant) + (pcgMultiplier(iType, multiplierType) - one(iType)) * rng2.state

      if (rng1Diff and three(iType)) != (rng2Diff and three(iType)):
        rng2Diff = -rng2Diff

      result = distanceImpl(rng2Diff, rng1Diff, pcgMultiplier(iType, multiplierType), zero(iType), mask)

  func boundedRand*(rng: var name, upperBound: oType): oType =
    let threshold = (max(rng) - min(rng) + one(oType) - upperBound) mod upperBound

    while true:
      let r = next(rng) - min(rng)

      if r >= threshold:
        return r mod upperBound

pcgConstructor(Pcg32, PcgSpecificStream, PcgXSH_RR, uint64, uint32)
pcgConstructor(Pcg32OneSeq, PcgSingleStream, PcgXSH_RR, uint64, uint32)
pcgConstructor(Pcg32Unique, PcgUniqueStream, PcgXSH_RR, uint64, uint32)
pcgConstructor(Pcg32Fast, PcgMcg, PcgXSH_RS, uint64, uint32)

pcgConstructor(Pcg64, PcgSpecificStream, PcgXSL_RR, UInt128, uint64)
pcgConstructor(Pcg64OneSeq, PcgSingleStream, PcgXSL_RR, UInt128, uint64)
pcgConstructor(Pcg64Unique, PcgUniqueStream, PcgXSL_RR, UInt128, uint64)
pcgConstructor(Pcg64Fast, PcgMcg, PcgXSL_RR, UInt128, uint64)

pcgConstructor(Pcg8OnceInsecure, PcgSpecificStream, PcgRXS_M_XS, uint8, uint8)
pcgConstructor(Pcg16OnceInsecure, PcgSpecificStream, PcgRXS_M_XS, uint16, uint16)
pcgConstructor(Pcg32OnceInsecure, PcgSpecificStream, PcgRXS_M_XS, uint32, uint32)
pcgConstructor(Pcg64OnceInsecure, PcgSpecificStream, PcgRXS_M_XS, uint64, uint64)
pcgConstructor(Pcg128OnceInsecure, PcgSpecificStream, PcgXSL_RR_RR, UInt128, UInt128)

pcgConstructor(Pcg8OneSeqOnceInsecure, PcgSingleStream, PcgRXS_M_XS, uint8, uint8)
pcgConstructor(Pcg16OneSeqOnceInsecure, PcgSingleStream, PcgRXS_M_XS, uint16, uint16)
pcgConstructor(Pcg32OneSeqOnceInsecure, PcgSingleStream, PcgRXS_M_XS, uint32, uint32)
pcgConstructor(Pcg64OneSeqOnceInsecure, PcgSingleStream, PcgRXS_M_XS, uint64, uint64)
pcgConstructor(Pcg128OneSeqOnceInsecure, PcgSingleStream, PcgXSL_RR_RR, UInt128, UInt128)

# TODO extended generators

{.pop.}
