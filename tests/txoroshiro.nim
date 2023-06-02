import ./randnimgulins/xoroshiro

import ./testsutils

initTests([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16])

suite "xoroshiro":
  test "Xoroshiro64star":
    const expected = [2654435771'u32, 327208753'u32, 4063491769'u32, 4259754937'u32, 261922412'u32]

    testRng(initXoroshiro64star(tseed[0].uint32, tseed[1].uint32))
  test "Xoroshiro64starstar":
    const expected = [3802928447'u32, 813792938'u32, 1618621494'u32, 2955957307'u32, 3252880261'u32]

    testRng(initXoroshiro64starstar(tseed[0].uint32, tseed[1].uint32))
  test "Xoroshiro128plus":
    const expected = [3'u64, 412333834243'u64, 2360170716294286339'u64, 9295852285959843169'u64, 2797080929874688578'u64]

    testRng(initXoroshiro128plus(tseed[0].uint64, tseed[1].uint64))
  test "Xoroshiro128plusplus":
    const expected = [393217'u64, 669327710093319'u64, 1732421326133921491'u64, 11394790081659126983'u64, 9555452776773192676'u64]

    testRng(initXoroshiro128plusplus(tseed[0].uint64, tseed[1].uint64))
  test "Xoroshiro128star":
    const expected = [11400714819323198483'u64, 95197400445514809'u64, 2278297484023264313'u64, 7389896066207290131'u64, 4589514994495871539'u64]

    testRng(initXoroshiro128star(tseed[0].uint64, tseed[1].uint64))
  test "Xoroshiro128starstar":
    const expected = [5760'u64, 97769243520'u64, 9706862127477703552'u64, 9223447511460779954'u64, 8358291023205304566'u64]

    testRng(initXoroshiro128starstar(tseed[0].uint64, tseed[1].uint64))
  test "Xoroshiro1024plus":
    const expected = [3'u64, 206158430211'u64, 206158430980'u64, 53051436040965'u64, 53120155714566'u64]

    testRng(initXoroshiro1024plus(tseed[0].uint64, tseed[1].uint64, tseed[2].uint64, tseed[3].uint64, tseed[4].uint64, tseed[5].uint64, tseed[6].uint64, tseed[7].uint64, tseed[8].uint64, tseed[9].uint64, tseed[10].uint64, tseed[11].uint64, tseed[12].uint64, tseed[13].uint64, tseed[14].uint64, tseed[15].uint64))
  test "Xoroshiro1024plusplus":
    const expected = [25165825'u64, 1729382463093866496'u64, 1729382469544706816'u64, 2305896067134128920'u64, 2882358539580539928'u64]

    testRng(initXoroshiro1024plusplus(tseed[0].uint64, tseed[1].uint64, tseed[2].uint64, tseed[3].uint64, tseed[4].uint64, tseed[5].uint64, tseed[6].uint64, tseed[7].uint64, tseed[8].uint64, tseed[9].uint64, tseed[10].uint64, tseed[11].uint64, tseed[12].uint64, tseed[13].uint64, tseed[14].uint64, tseed[15].uint64))
  test "Xoroshiro1024star":
    const expected = [4354685564936845350'u64, 15755400384260043833'u64, 8709371129873690700'u64, 1663341875487337567'u64, 13064056694810536050'u64]

    testRng(initXoroshiro1024star(tseed[0].uint64, tseed[1].uint64, tseed[2].uint64, tseed[3].uint64, tseed[4].uint64, tseed[5].uint64, tseed[6].uint64, tseed[7].uint64, tseed[8].uint64, tseed[9].uint64, tseed[10].uint64, tseed[11].uint64, tseed[12].uint64, tseed[13].uint64, tseed[14].uint64, tseed[15].uint64))
  test "Xoroshiro1024starstar":
    const expected = [11520'u64, 17280'u64, 23040'u64, 28800'u64, 34560'u64]

    testRng(initXoroshiro1024starstar(tseed[0].uint64, tseed[1].uint64, tseed[2].uint64, tseed[3].uint64, tseed[4].uint64, tseed[5].uint64, tseed[6].uint64, tseed[7].uint64, tseed[8].uint64, tseed[9].uint64, tseed[10].uint64, tseed[11].uint64, tseed[12].uint64, tseed[13].uint64, tseed[14].uint64, tseed[15].uint64))
