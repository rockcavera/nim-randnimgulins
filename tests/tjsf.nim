import ./randnimgulins/jsf

import ./testsutils

initTests([0])

suite "Jenkins's Small Fast RNG (JSF)":
  test "JSF32":
    const expected = [446393351'u32, 2589264021'u32, 4046186614'u32, 151173657'u32, 552706628'u32]

    testRng(initJsf32(tseed[0].uint32))
  test "JSF64":
    const expected = [5420579327082221045'u64, 12601856710328663849'u64, 3486099297865454798'u64, 9209813893562929851'u64, 13082810583377980795'u64]

    testRng(initJsf64(tseed[0].uint64))
