import math, hashes, cppstl, algorithm, tables, sequtils, strutils
proc comp*(s: string): string =
  result = s.multiReplace([("A", "T"), ("T", "A"), ("C", "G"), ("G", "C")])

proc rev*(s: string): string =
  let
    n = s.len
  result = newStringOfCap(n)
  for i in countdown(n-1, 0):
    result.add(s[i])

proc gcContent*(s: string): float =
  var
    gcCount, totalLen: int
  for c in s:
    if c == 'C' or c == 'G':
      gcCount.inc
    elif c == 'A' or c == 'T':
      totalLen.inc
  return gcCount/(totalLen + gcCount)

proc entropy*(s: string): float =
  var
    sc = s.filterIt(it != 'N')
    c = sc.toCountTable
  for h in c.values:
    result += (((h)/sc.len) * log2((h)/sc.len))
  result *= -1

proc windowEntropy*(s: string, window: int = 24): float =
  result = 2.0
  var 
    thisH: float
  assert s.len >= window
  for w in 0 .. (s.len - window):
    thisH = entropy(s[w ..< (w + window)])
    if thisH < result:
      result = thisH

proc hpc*(s: string): string =
  result = newStringOfCap(s.len)
  result.add(s[0])
  for c in s[1..<s.len]:
    if c != result[^1]:
      result.add(c)

type BitArray* = ref object
  bits*: seq[uint64]
  len*: int

type CppBitArray* = ref object
  bits*: CppVector[uint64]
  len*: int

proc divUp(a, b: int): int =
  let ex = if a mod b > 0: 1 else: 0
  return a div b + ex

proc newBitArray*(len: int = 0): BitArray =
  result = BitArray()
  result.len = len
  result.bits = newSeq[uint64](len.divUp(64))

proc newNtBitArray*(len: int = 0): BitArray =
  result = BitArray()
  result.len = (len * 3)
  result.bits = newSeq[uint64]((len * 3).divUp(64))

proc splitNts*(s: string, l: int = 20): seq[string] =
  var
    tmpNts: string
  for c in s:
    tmpNts &= c
    if tmpNts.len mod l == 0:
      result.add(tmpNts)
      tmpNts.setLen(0)
  result.add(tmpNts)

proc splitNtToBin*(s: string, i: int): uint64 =
  result = 0.uint
  var
    count: int
  for c in s:
    let
      conv: uint64 = case c:
             of 'A': 0b001
             of 'C': 0b010
             of 'G': 0b011
             of 'T': 0b100
             else: 0b101
      mask = conv shl (count * 3 + 4)
    result = result or mask
    count.inc
  result = result or i.uint8

proc splitBinToNt*(b: uint64): tuple[s: string, i: uint64] =
  #result.s = stringOfCap(20)
  for i in 0..<20:
    let
      mask = 7.uint64 shl (i * 3 + 4)
      c: char = case (b and mask) shr (i * 3 + 4):
        of 0b001: 'A'
        of 0b010: 'C'
        of 0b011: 'G'
        of 0b100: 'T'
        of 0b101: 'N'
        else: 'X'
    if not (c == 'X'):
      result.s.add(c)
  result.i = b and 7.uint64

proc sortSplitNts(a, b: tuple[s: string, i: uint64]): int =
  cmp(a.i, b.i)

proc unsplitSplitNts*(s: seq[tuple[s: string, i: uint64]]): string =
  var
    sv = s
  sv.sort(sortSplitNts, Ascending)
  for p in sv:
    result &= p.s

when defined(release):
  {.push checks: off.}

proc unsafeGet*(b: BitArray, i: int): bool =
  let
    bigAt = i div 64
    littleAt = i mod 64
    mask = 1.uint64 shl littleAt
  return (b.bits[bigAt] and mask) != 0

proc unsafeGetNt*(b: BitArray, i: int): char =
  let
    bigAt = (i * 3) div 64
    littleAt = (i * 3) mod 64
    mask = 7.uint64 shl littleAt
  result = case (b.bits[bigAt] and mask) shr littleAt:
             of 0b000 : 'A'
             of 0b001 : 'C'
             of 0b010 : 'G'
             of 0b011 : 'T'
             else: 'N'


proc unsafeSetFalse*(b: BitArray, i: int) =
  let
    bigAt = i div 64
    littleAt = i mod 64
    mask = 1.uint64 shl littleAt
  b.bits[bigAt] = b.bits[bigAt] and (not mask)

proc unsafeSetTrue*(b: BitArray, i: int) =
  let
    bigAt = i div 64
    littleAt = i mod 64
    mask = 1.uint64 shl littleAt
  b.bits[bigAt] = b.bits[bigAt] or mask

proc unsafeSetNt*(b: BitArray, i: int, nt: char) =
  let
    bigAt = (i * 3) div 64
    littleAt = (i * 3) mod 64
    conv: uint64 = case nt:
             of 'A': 0b000
             of 'C': 0b001
             of 'G': 0b010
             of 'T': 0b011
             else: 0b100
    mask = conv shl littleAt
  b.bits[bigAt] = b.bits[bigAt] or mask

when defined(release):
  {.pop.}

proc ntToBits*(s: string): BitArray =
  result = newNtBitArray(s.len)
  for n in 0 ..< s.len:
    result.unsafeSetNt(n, s[n])

proc bitsToNt*(b: BitArray): string =
  result = newStringOfCap(b.len div 3)
  for i in 0 ..< b.len div 3:
    result.add(b.unsafeGetNt(i))


proc `[]`*(b: BitArray, i: int): bool =
  if i < 0 or i >= b.len:
    raise newException(IndexDefect, "OOB")
  b.unsafeGet(i)

proc `[]=`*(b: BitArray, i: int, v: bool) =
  if i < 0 or i >= b.len:
    raise newException(IndexDefect, "OOB")
  if v:
    b.unsafeSetTrue(i)
  else:
    b.unsafeSetFalse(i)

proc `$`*(b: BitArray): string =
  result = newStringOfCap(b.len)
  for i in 0 ..< b.len:
    if b.unsafeGet(i):
      result.add("1")
    else:
      result.add("0")

when isMainModule:
  import cligen, strformat, klib
  proc test() =
    var
      sequence = "ATCGTAGTGAC"
      ba = newBitArray(10)
    echo "Sequence: ", sequence, " entropy: ", sequence.entropy
    echo "Sequecne: AATTAATT entropy: ", "AATTAATT".entropy
    echo "Sequence: ", sequence, " window: 3, entropy: ", sequence.windowEntropy(3)
    echo "Sequence: ", sequence, " window: 11, entropy: ", sequence.windowEntropy(11)
    doAssert almostEqual(sequence.entropy,  1.9808259362290785)
    doAssert almostEqual(sequence.windowEntropy(sequence.len), 1.9808259362290785)

    assert sequence.hpc == sequence
    assert "AAACCCGTT".hpc == "ACGT"
    echo "Sequence: ", sequence, " hpc: ", sequence.hpc
    echo "Sequence: ", "AAACCCGTT", " hpc: ", "AAACCCGTT".hpc

    let
      ls = "TAAGTTCTAGATAAGGCCACCCCTCTCCAGTCTTATTTCCTCAAGGCAGGAGTCATTAAAAACAAACAAAACAAAACAAAACAAAAAAAAACCCCTCAGAA"
      b = ntToBits(ls)
    echo "Sequence: ", ls
    echo "Bit representation: ", b
    echo "Bit to seq: ", b.bitsToNt()
    let
      splitNt = ls.splitNts
    echo "Split read: ", splitNt
    var
      counter: int
      mergeNt: seq[tuple[s: string, i: uint64]]
    for k in splitNt:
      echo k.splitNtToBin(counter)
      counter.inc
      echo k.splitNtToBin(counter).splitBinToNt
      mergeNt.add(k.splitNtToBin(counter).splitBinToNt)
    echo  unsplitSplitNts(mergeNt)
    echo unsplitSplitNts(mergeNt).entropy

  proc revComp(args: seq[string]) =
    if args.len == 1:
      stdout.writeLine args[0].rev.comp
  
  proc H(args: seq[string]) =
    for s in args:
      stdout.writeLine s, ": ", s.entropy
  
  proc windowH(window: int = 24, args: seq[string]) =
    var 
      f = xopen[GzFile](args[0])
      r: FastxRecord
    while f.readFastx(r):
      stdout.writeLine  "{r.seq.windowEntropy(window).abs:0.4f}".fmt

  proc windowHFilter(window: int = 24, minEntropy: float = 1.85, args: seq[string]) =
    var 
      f = xopen[GzFile](args[0])
      r: FastxRecord
    while f.readFastx(r):
      if r.seq.windowEntropy(window) >= minEntropy:
        stdout.writeLine  ">{r.name}\n{r.seq}".fmt

  dispatchMulti([revComp], [test], [H], [windowH], [windowHFilter])
