import std/[os, strutils, unittest]

import pkg/nint128

import ./randnimgulins/pcg

import ./testsutils

# Prevents compile-time optimizations (?)
# Allows you to pass other seeds
var
  tseed = 42
  tstream = 54

if paramCount() > 0:
  tseed = paramStr(1).parseInt()
if paramCount() > 1:
  tstream = paramStr(2).parseInt()

suite "PCG":
  test "Pcg8OnceInsecure":
    const expected = [0xea'u8, 0x4d, 0x8a, 0x45, 0x6b, 0x23, 0xcb, 0xaa, 0xf7, 0x63, 0xec, 0x30, 0x39, 0xbc]

    testRng(initPcg8OnceInsecure(tseed.uint8, tstream.uint8))

  test "Pcg8OneSeqOnceInsecure":
    const expected = [0x2e'u8, 0x44, 0x2f, 0x91, 0x50, 0x84, 0xcb, 0x60, 0x4b, 0xe5, 0x5f, 0x97, 0x0f, 0x58]

    testRng(initPcg8OneSeqOnceInsecure(tseed.uint8))

  test "Pcg16OnceInsecure":
    const expected = [0x9bec'u16, 0x5957, 0x960e, 0xd08d, 0x4e05, 0xde00, 0x03f7, 0x1fa6, 0xee22, 0xf6fa]

    testRng(initPcg16OnceInsecure(tseed.uint16, tstream.uint16))

  test "Pcg16OneSeqOnceInsecure":
    const expected = [0x7f90'u16, 0x7f82, 0x54f7, 0xe8c8, 0x9444, 0xba1a, 0xb7fb, 0x2167, 0x39dd, 0xb0f2]

    testRng(initPcg16OneSeqOnceInsecure(tseed.uint16))

  test "Pcg32":
    const expected = [0xa15c02b7'u32, 0x7b47f409'u32, 0xba1d3330'u32, 0x83d2f293'u32, 0xbfa4784b'u32, 0xcbed606e'u32]

    testRng(initPcg32(tseed.uint64, tstream.uint64))

  test "Pcg32OneSeq":
    const expected = [0xc2f57bd6'u32, 0x6b07c4a9'u32, 0x72b7b29b'u32, 0x44215383'u32, 0xf5af5ead'u32, 0x68beb632'u32]

    testRng(initPcg32OneSeq(tseed.uint64))

  test "Pcg32OneSeq":
    const expected = [0x00000000'u32, 0x5c400ccc'u32, 0x03a8459e'u32, 0x9bdb59c5'u32, 0xf1c9dcf5'u32, 0xaac0af3b'u32]

    testRng(initPcg32Fast(tseed.uint64))

  test "Pcg32OnceInsecure":
    const expected = [0xf84b622d'u32, 0xdc1e5bb4'u32, 0x74fb8ac1'u32, 0xb3bbf8de'u32, 0x9cf62074'u32, 0x2d2f5e33'u32]

    testRng(initPcg32OnceInsecure(tseed.uint32, tstream.uint32))

  test "Pcg32OneSeqOnceInsecure":
    const expected = [0x256b5357'u32, 0xa5efad32'u32, 0x170b7830'u32, 0x334a5b22'u32, 0x3de5c680'u32, 0x9b47b7b3'u32]

    testRng(initPcg32OneSeqOnceInsecure(tseed.uint32))

  test "Pcg64":
    const expected = [0x86b1da1d72062b68'u64, 0x1304aa46c9853d39'u64, 0xa3670e9e0dd50358'u64, 0xf9090e529a7dae00'u64, 0xc85b9fd837996f2c'u64, 0x606121f8e3919196'u64]

    testRng(initPcg64(u128(tseed), u128(tstream)))

  test "Pcg64OneSeq":
    const expected = [0x287472e87ff5705a'u64, 0xbbd190b04ed0b545'u64, 0xb6cee3580db14880'u64, 0xbf5f7d7e4c3d1864'u64, 0x734eedbe7e50bbc5'u64, 0xa5b6b5f867691c77'u64]

    testRng(initPcg64OneSeq(u128(tseed)))

  test "Pcg64Fast":
    const expected = [0x63b4a3a813ce700a'u64, 0x382954200617ab24'u64, 0xa7fd85ae3fe950ce'u64, 0xd715286aa2887737'u64, 0x60c92fee2e59f32c'u64, 0x84c4e96beff30017'u64]

    testRng(initPcg64Fast(u128(tseed)))

  test "Pcg64OnceInsecure":
    const expected = [0xe1cbc180b69606bb'u64, 0x6573bce7abaee684'u64, 0xc744f07442006076'u64, 0x9e9f98ccbd60b8fc'u64, 0xde693821ee9629ae'u64, 0x263cc2cdc66ebc25'u64]

    testRng(initPcg64OnceInsecure(tseed.uint64, tstream.uint64))

  test "Pcg64OneSeqOnceInsecure":
    const expected = [0x27a53829edf003a9'u64, 0xdf28458e5c04c31c'u64, 0x2756dc550bc36037'u64, 0xa10325553eb09ee9'u64, 0x40a0fccb8d9df09f'u64, 0x5c2047cfefb5e9ca'u64]

    testRng(initPcg64OneSeqOnceInsecure(tseed.uint64))

  when defined(release):
    # Some code optimization problem makes the output not as expected.
    # Still I don't know if it's in nint128 or in the pcg code.
    test "Pcg128OnceInsecure":
      const expected = [UInt128(hi: 0x5f4ea96e8510af06'u64, lo: 0x86b1da1d72062b68'u64), UInt128(hi: 0x341b1cb1e675ec46'u64, lo: 0x1304aa46c9853d39'u64), UInt128(hi: 0xcfdc46c17f1c9974'u64, lo: 0xa3670e9e0dd50358'u64), UInt128(hi: 0x02d273b87fe9110c'u64, lo: 0xf9090e529a7dae00'u64), UInt128(hi: 0x9b4e47fda576f0dd'u64, lo: 0xc85b9fd837996f2c'u64), UInt128(hi: 0x17cee59c8cb9c0a1'u64, lo: 0x606121f8e3919196'u64)]

      testRng(initPcg128OnceInsecure(u128(tseed), u128(tstream)))

    test "Pcg128OneSeqOnceInsecure":
      const expected = [UInt128(hi: 0xf7d42ec98a2a818c'u64, lo: 0x287472e87ff5705a'u64), UInt128(hi: 0x1e69ebc79672e381'u64, lo: 0xbbd190b04ed0b545'u64), UInt128(hi: 0xefb0314dea875a49'u64, lo: 0xb6cee3580db14880'u64), UInt128(hi: 0xff56268e0e45f685'u64, lo: 0xbf5f7d7e4c3d1864'u64), UInt128(hi: 0x03f0bf312cd0282c'u64, lo: 0x734eedbe7e50bbc5'u64), UInt128(hi: 0xfcfdd5e15426494f'u64, lo: 0xa5b6b5f867691c77'u64)]

      testRng(initPcg128OneSeqOnceInsecure(u128(tseed)))
