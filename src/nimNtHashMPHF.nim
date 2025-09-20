{.passl: "-L../lib -lz -lnthashmphf -lnthash".}
{.passc: "-std=c++17 -I../include".}
{.push header: "NtHashMPHF.hpp".}
import klib
type
  GHash* {.importcpp: "NtHashMPHF::GHash", byref.} = object
proc createGHash*(k: uint64): GHash {.importcpp: "NtHashMPHF::GHash(@)", constructor.}
proc insert*(h: GHash, s: pointer, l: int) {.importcpp: "#.insert(@)".}
proc build*(h: GHash) {.importcpp: "#.build()".}
proc inc*(h: GHash, s: pointer, l: int) {.importcpp: "#.inc(@)".}
{.pop.}
proc insert*(h: GHash, k: string) =
  h.insert(k[0].addr, k.len)
proc inc*(h: GHash, k: string) =
  h.inc(k[0].addr, k.len)

when isMainModule:
  import cligen
  proc test(r: string) =
    var
      rz: Bufio[GzFile]
      rec: FastxRecord
    var g: GHash = createGHash(12)
    rz.open(r)
    while rz.readFastx(rec):
      g.insert(rec.seq)
    g.build()
  dispatch test
