import ./randnimgulins/wyrand

import ./testsutils

initTests([42])

suite "wyrand":
  when defined(wyRand32Bit):
    when defined(wyRandCondom):
      test "defined `wyrand32Bit` and `wyrandCondom`":
        const expected = [8968573670647833296'u64, 17685900389795434097'u64, 14892009209142482017'u64, 14560301896798849829'u64, 7333637800628584940'u64]

        testRng(initWyrand(tseed[0].uint64))
    else:
      test "defined `wyrand32Bit` and not defined `wyrandCondom`":
        const expected = [11202062979494742539'u64, 1329562870757140138'u64, 3001778519655890106'u64, 3248198965284332542'u64, 9422988823067633975'u64]

        testRng(initWyrand(tseed[0].uint64))
  else:
    when defined(wyRandCondom):
      test "not defined `wyrand32Bit` and defined `wyrandCondom`":
        const expected = [5280754711637368047'u64, 1067202489826996489'u64, 3194222568268065761'u64, 876737861347062442'u64, 13634833249873673755'u64]

        testRng(initWyrand(tseed[0].uint64))
    else:
      test "not defined `wyrand32Bit` and not defined `wyrandCondom`":
        const expected = [12558987674375533620'u64, 16846851108956068306'u64, 14652274819296609082'u64, 16945271478357465713'u64, 6502026092014180032'u64]

        testRng(initWyrand(tseed[0].uint64))
