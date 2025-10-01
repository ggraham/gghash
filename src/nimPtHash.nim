{.push header: "nimpthash.hpp".}
type
  CppVector*[T] {.importcpp: "std::vector<'0>", header: "<vector>".} = object
  GHash* {.importcpp: "NtPtHash::GHash", byref.} = object
#####
proc newGHash*(k, num_threads: uint64; seed: uint64 = 7, avg_partition_size: uint64 = 100; alpha: cdouble = 0.97, lambda: cdouble = 5; verbose: bool = true; dense_partitioning: bool = true): GHash {.importcpp: "NtPtHash::GHash(@)", constructor.}
proc insert(h: GHash; s: pointer; l: csize_t) {.importcpp: "#.ins(@)".}
proc build*(h: GHash) {.importcpp: "#.build()".}
proc index(h: GHash; s: pointer; l: csize_t): CppVector[uint64] {.importcpp: "#.idx(@)".}
proc index*(h: GHash; i: uint64): uint64 {.importcpp: "#.idx(@)".}
proc hash(h: GHash; s: pointer; l: csize_t): CppVector[uint64] {.importcpp: "#.hx(@)".}
proc data[T](v: CppVector[T]): ptr T {.importcpp: "#.data()".}
proc size*(h: GHash): uint64 {.importcpp: "#.getSize()".}
proc size[T](v: CppVector[T]): int {.importcpp: "#.size()".}
{.pop.}
proc index*(h: GHash, s: string): seq[uint64] =
  let
    ac = h.index(s[0].addr, s.len.csize_t)
    length = ac.size()
  if length == 0:
    return @[]
  result = newSeq[uint64](length)
  copyMem(result[0].addr, ac.data(), length * sizeof(uint64))

proc hash*(h: GHash, s: string): seq[uint64] =
  let
    ac = h.hash(s[0].addr, s.len.csize_t)
    length = ac.size()
  if length == 0:
    return @[]
  result = newSeq[uint64](length)
  copyMem(result[0].addr, ac.data(), length * sizeof(uint64))

proc insert*(h: GHash; s: string) =
  h.insert(s[0].addr, s.len.csize_t)

when isMainModule:
  import cligen, tables, strutils, strformat, klib
  proc testStuff(f: string; k: uint64 = 12; threads: uint64 = 8) =
    let  
      phf = newGHash(k, threads, avg_partition_size = 10000)
      s: string = "TGATATTATCGGTA"
    phf.insert(s)
    var
      fz = xopen[GzFile](f)
      rec: FastxRecord
    while fz.readFastx(rec):
      phf.insert(rec.seq)
    phf.build()
    
    for h in phf.index(s):
      stdout.writeLine "hash: {h}".fmt
    close(fz)
    
    var
      fo = xopen[GzFile](f)
      reco: FastxRecord
      v: seq[uint64] = newSeq[uint64](phf.size())
    while fo.readFastx(reco):
      for i in phf.index(reco.seq):
        v[i]+=1
    for n in v[0..<50]:
      stdout.writeLine "this count: {n}".fmt


  dispatch testStuff
