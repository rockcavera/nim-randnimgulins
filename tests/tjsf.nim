import std/unittest

import ./randnimgulins/jsf

suite "Jenkins's Small Fast RNG (JSF)":
  test "JSF32 - Seed: 0 - Rounds: 5":
    var state = initJsf32(0'u32)
    check(next(state) == 446393351'u32)
    check(next(state) == 2589264021'u32)
    check(next(state) == 4046186614'u32)
    check(next(state) == 151173657'u32)
    check(next(state) == 552706628'u32)

  test "JSF64 - Seed: 0 - Rounds: 5":
    var state = initJsf64(0'u64)
    check(next(state) == 5420579327082221045'u64)
    check(next(state) == 12601856710328663849'u64)
    check(next(state) == 3486099297865454798'u64)
    check(next(state) == 9209813893562929851'u64)
    check(next(state) == 13082810583377980795'u64)
