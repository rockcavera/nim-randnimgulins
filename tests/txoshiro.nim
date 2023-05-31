import ./randnimgulins/xoshiro

import ./testsutils

initTests([1, 2, 3, 4, 5, 6, 7, 8])

suite "xoshiro":
  test "Xoshiro128plus":
    const expected = [5'u32, 12295, 25178119, 27286542, 39879690]

    testRng(initXoshiro128plus(tseed[0].uint32, tseed[1].uint32, tseed[2].uint32, tseed[3].uint32))
  test "Xoshiro128plusplus":
    const expected = [641'u32, 1573767'u32, 3222811527'u32, 3517856514'u32, 836907274'u32]

    testRng(initXoshiro128plusplus(tseed[0].uint32, tseed[1].uint32, tseed[2].uint32, tseed[3].uint32))
  test "Xoshiro128starstar":
    const expected = [11520'u32, 0, 5927040, 70819200, 2031721883]

    testRng(initXoshiro128starstar(tseed[0].uint32, tseed[1].uint32, tseed[2].uint32, tseed[3].uint32))
  test "Xoshiro256plus":
    const expected = [5'u64, 211106232532999'u64, 211106635186183'u64, 9223759065350669058'u64, 9250833439874351877'u64]

    testRng(initXoshiro256plus(tseed[0].uint64, tseed[1].uint64, tseed[2].uint64, tseed[3].uint64))
  test "Xoshiro256plusplus":
    const expected = [41943041'u64, 58720359'u64, 3588806011781223'u64, 3591011842654386'u64, 9228616714210784205'u64]

    testRng(initXoshiro256plusplus(tseed[0].uint64, tseed[1].uint64, tseed[2].uint64, tseed[3].uint64))
  test "Xoshiro256starstar":
    const expected = [11520'u64, 0'u64, 1509978240'u64, 1215971899390074240'u64, 1216172134540287360'u64]

    testRng(initXoshiro256starstar(tseed[0].uint64, tseed[1].uint64, tseed[2].uint64, tseed[3].uint64))
  test "Xoshiro512plus":
    const expected = [4'u64, 8'u64, 4113'u64, 25169936'u64, 52776585412635'u64]

    testRng(initXoshiro512plus(tseed[0].uint64, tseed[1].uint64, tseed[2].uint64, tseed[3].uint64, tseed[4].uint64, tseed[5].uint64, tseed[6].uint64, tseed[7].uint64))
  test "Xoshiro512plusplus":
    const expected = [524291'u64, 1048578'u64, 539099140'u64, 3299073855497'u64, 6917532603230064654'u64]

    testRng(initXoshiro512plusplus(tseed[0].uint64, tseed[1].uint64, tseed[2].uint64, tseed[3].uint64, tseed[4].uint64, tseed[5].uint64, tseed[6].uint64, tseed[7].uint64))
  test "Xoshiro512starstar":
    const expected = [11520'u64, 0'u64, 23040'u64, 23667840'u64, 144955163520'u64,]

    testRng(initXoshiro512starstar(tseed[0].uint64, tseed[1].uint64, tseed[2].uint64, tseed[3].uint64, tseed[4].uint64, tseed[5].uint64, tseed[6].uint64, tseed[7].uint64))
