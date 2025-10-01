{.push header: "WFAligner.hpp".}

type
  MemoryModel* = enum
    MemoryHigh, MemoryMed, MemoryLow, MemoryUltralow
  AlignmentScope* = enum
    Score, Alignment
  AlignmentStatus* = enum
    StatusAlgCompleted, StatusAlgPartial, StatusMaxStepsReached, StatusOOM
  WFAlignerGapAffine* {.importcpp: "wfa::WFAlignerGapAffine", byref.} = object
  WFAlignerGapAffine2Pieces* {.importcpp: "wfa::WFAlignerGapAffine2Pieces", byref.} = object
  WFAlignerGapLinear* {.importcpp: "wfa::WFAlignerGapLinear", byref.} = object
  WFAlignerEdit* {.importcpp: "wfa::WFAlignerEdit", byref.} = object
  WFAlignerIndel* {.importcpp: "wfa::WFAlignerIndel", byref.} = object

proc createIndelAligner*(alignmentScope: AlignmentScope, memoryModel: MemoryModel): WFAlignerIndel {.importcpp: "'0(@)", constructor.}
proc createEditAligner*(alignmentScope: AlignmentScope, memoryModel: MemoryModel): WFAlignerEdit {.importcpp: "'0(@)", constructor.}
proc createGapLinearAligner*(match: cint, mismatch: cint, indel: cint, alignmentScope: AlignmentScope, memoryModel: MemoryModel): WFAlignerGapLinear {.importcpp: "'0(@)", constructor.}
proc createGapAffineAligner*(match: cint, mismatch: cint, gapOpening: cint, gapExtension: cint, alignmentScope: AlignmentScope, memoryModel: MemoryModel): WFAlignerGapAffine {.importcpp: "'0(@)", constructor.}
proc createGapAffine2PieceAligner*(match: cint, mismatch: cint, gapOpening1: cint, gapExtension1: cint, gapOpening2: cint, gapExtension2: cint, alignmentScope: AlignmentScope, memoryModel: MemoryModel): WFAlignerGapAffine2Pieces {.importcpp: "'0(@)", constructor.}
proc setHeuristicNone*[T](wfa: T) {.importcpp: "#.setHeuristicNone()".}
proc setHeuristicBandedStatic*[T](wfa: T, band_min_k: cint, band_max_k: cint) {.importcpp: "#.setHeuristicBandedStatic(@)".}
proc setHeuristicBandedAdaptive*[T](wfa: T, band_min_k: cint, band_max_k: cint, steps_between_cutoffs: cint = 1) {.importcpp: "#.setHeuristicBandedAdaptive(@)".}
proc setHeuristicWfAdaptive*[T](wfa: T, min_wavefront_length: cint, max_distance_threshold: cint, steps_between_cutoffs: cint = 1) {.importcpp: "#.setHeuristicWFadaptive(@)".}
proc setHeuristicWfMash*[T](wfa: T, min_wavefront_length: cint, max_distance_threshold: cint, steps_between_cutoffs: cint = 1) {.importcpp: "#.setHeuristicWFmash(@)".}
proc setHeuristicXDrop*[T](wfa: T, xdrop: cint, steps_between_cutoffs: cint = 1) {.importcpp: "#.setHeuristicXDrop(@)".}
proc setHeuristicZDrop*[T](wfa: T, zdrop: cint, steps_between_cutoffs: cint = 1) {.importcpp: "#.setHeuristicZDrop(@)".}
proc alignEnd2End[T](wfa: T, pattern: cstring, text: cstring): AlignmentStatus {.importcpp: "#.alignEnd2End(@)".}
proc alignEndsFree[T](wfa: T, pattern: cstring, patternBeginFree: cint, patternEndFree: cint, text: cstring, textBeginFree: cint, textEndFree: cint): AlignmentStatus {.importcpp: "#.alignEndsFree(@)".}
proc setMaxNumThreads*[T](wfa: T, maxNumThreads: cint) {.importcpp: "#.setMaxNumThreads(@)".}
proc printPretty*[T](wfa: T, stream: File, pattern: cstring, patternLength: cint, text: cstring, textLength: cint) {.importcpp: "#.printPretty(@)".}
proc getAlignmentScore*[T](wfa: T): cint {.importcpp: "#.getAlignmentScore()".}
proc getCIGAR*[T](wfa: T, showMismatches: bool, cigarOperations: pointer, numCigarOperations: ptr cint) {.importcpp: "#.getCIGAR(@)".}
{.pop.}

type 
  CigarOp* {.pure.} = enum
    Match = 0
    Ins = 1
    Del = 2
    N = 3
    Hole4 = 4
    Hole5 = 5
    Hole6 = 6
    Equal = 7
    Mismatch = 8
    Unsure

type Paf* = object
  targetLen, targetLeft, targetRight: int
  queryLen, queryLeft, queryRight: int
  nMatches*, blockLen*: int
  score*: int
  cigar: seq[tuple[operation: char, length: int]]

proc printPretty*[T](wfa: T, pattern: string, text: string) =
  printPretty(wfa, stdout, pattern.cstring, pattern.len.cint, text.cstring, text.len.cint)
proc alignEndsFree*[T](wfa: T, pattern: string, propP: float, text: string, propT: float): AlignmentStatus =
  let
    base = abs(pattern.len - text.len)
    #baseP = min(base, pattern.len) - 5
    baseP = pattern.len - 24
    #baseT = min(base, text.len) - 5
    baseT = text.len - 24
  result = alignEndsFree(wfa, pattern.cstring, baseP.cint, baseP.cint, text.cstring, baseT.cint, baseT.cint)
proc alignEndsFree*[T](wfa: T, right: int, pattern: string, left: int, text: string): AlignmentStatus =
  result = alignEndsFree(wfa, pattern.cstring, right.cint, 0.cint, text.cstring, 0.cint, left.cint)
proc alignEndsFree*[T](wfa: T, free: int, pattern: string, text: string): AlignmentStatus =
  result = alignEndsFree(wfa, pattern.cstring, (pattern.len - free).cint, (pattern.len - free).cint,
                     text.cstring, (text.len - free).cint, (text.len - free).cint)

proc alignEndsFreeF*[T](wfa: T, free: int, pattern: string, text: string): AlignmentStatus =
  result = alignEndsFree(wfa, pattern.cstring, (pattern.len - free).cint, pattern.len.cint,
                              text.cstring, 0, free.cint)
proc alignEndsFreeR*[T](wfa: T, free: int, pattern: string, text: string): AlignmentStatus =
  result = alignEndsFree(wfa, pattern.cstring, 0, (pattern.len - free).cint,
                              text.cstring, (text.len - free).cint, 0)

proc alignEnd2End*[T](wfa: T, pattern: string, text: string): AlignmentStatus =
  result = wfa.alignEnd2End(pattern.cstring, text.cstring)

proc decodeCigar*(v: uint32): tuple[operation: char, length: int] =
  if (v and 0xf) <= 8:
    return((operation: "MIDN---=X"[v and 0xf], length: (v shr 4).int))
  else:
    return((operation: '?', length: (v shr 4).int))

proc decodeCigarEnum*(v: uint32): tuple[operation: CigarOp, length: int] =
  if (v and 0xf) <= 8:
    return((operation: CigarOp(v and 0xf), length: (v shr 4).int))
  else:
    return((operation: CigarOp.Unsure, length: (v shr 4).int))

proc maxCigarMatchEnum*(o: seq[tuple[operation: CigarOp, length: int]]): int =
  result = 0
  for op in o:
    if op.operation == Equal or op.operation == Match or op.operation == Mismatch:
      if op.length > result:
        result = op.length

proc cigarToString*(o: ptr UncheckedArray[uint32], l: cint): string =
  var
    op: tuple[operation: char, length: int]
  for i in 0 ..< l:
    op = decodeCigar(o[i])
    result &= $(op.length) & op.operation

proc cigarToString*(c: seq[tuple[operation: char, length: int]]): string =
  for i in c:
    result &= $(i.length) & i.operation

proc cigarToTupleSeq*(o: ptr UncheckedArray[uint32], l: cint): seq[tuple[operation: char, length: int]] =
  for i in 0 ..< l:
    result.add(decodeCigar(o[i]))

proc cigarToTupleSeqEnum*(o: ptr UncheckedArray[uint32], l: cint): seq[tuple[operation: CigarOp, length: int]] =
  for i in 0 ..< l:
    result.add(decodeCigarEnum(o[i]))

proc alToCigarTupleSeq*[T](a: T): seq[tuple[operation: char, length: int]] =
  var
    nops: cint
    ops = allocShared(sizeof(uint32) * 100)
  a.getCIGAR(true, ops.addr, nops.addr)
  return cigarToTupleSeq(cast[ptr UncheckedArray[uint32]](ops), nops)

proc alToCigarTupleSeqEnum*[T](a: T): seq[tuple[operation: CigarOp, length: int]] =
  var
    nops: cint
    ops = cast[ptr UncheckedArray[uint32]](allocShared(sizeof(uint32) * 100))
  a.getCIGAR(true, ops.addr, nops.addr)
  return cigarToTupleSeqEnum(ops, nops)

proc alToCigarTupleSeqEnum*[T](a: T, ops: ptr UncheckedArray[uint32], nops: cint): seq[tuple[operation: CigarOp, length: int]] =
  a.getCIGAR(true, ops.addr, nops.addr)
  return cigarToTupleSeqEnum(ops, nops)

proc alToCleanedCigarTupleSeq*[T](a: T, minMatchLength: int = 5): seq[tuple[operation: char, length: int]] =
  var
    cigarSeq = alToCigarTupleSeq(a)
  if cigarSeq.len >= 3:
    if cigarSeq[0].operation == 'D' or cigarSeq[0].operation == 'I':
      if cigarSeq[1].length < minMatchLength and cigarSeq[1].operation == '=':
        cigarSeq[0].length += cigarSeq[1].length
        cigarSeq[2].length += cigarSeq[1].length
        cigarSeq.delete(1)
    if cigarSeq[^1].operation == 'D' or cigarSeq[^1].operation == 'I':
      if cigarSeq[^2].length < minMatchLength and cigarSeq[^2].operation == '=':
        cigarSeq[^1].length += cigarSeq[^2].length
        cigarSeq[^3].length += cigarSeq[^2].length
        cigarSeq.delete(cigarSeq.high - 1)
  return cigarSeq

proc alignmentChar*[T](wfa: T): tuple[sumMatch: int, sumMismatch: int, sumInsertion: int, sumDeletion: int, longestMatchSegment: int, firstCIGAR: int, lastCIGAR: int] =
  let
    cigarTuple = alToCigarTupleSeq(wfa)
  for i in 0 ..< cigarTuple.len:

    case cigarTuple[i].operation:
      of '=':
        result.sumMatch += cigarTuple[i].length
        if cigarTuple[i].length > result.longestMatchSegment:
          result.longestMatchSegment = cigarTuple[i].length
        if i == 0:
          result.firstCIGAR = cigarTuple[i].length
        if i == (cigarTuple.len - 1):
          result.lastCIGAR = cigarTuple[i].length
      of 'X':
        result.sumMismatch += cigarTuple[i].length
      of 'I':
        if i > 0 and i < (cigarTuple.len - 1):
          result.sumInsertion += cigarTuple[i].length
      of 'D':
        if i > 0 and i < (cigarTuple.len - 1):
          result.sumDeletion += cigarTuple[i].length
      else:
        discard

proc consumesText*(op: tuple[operation: char, length: int]): bool =
  result = op.operation in ['D', 'M', 'X', '=']
proc consumePattern*(op: tuple[operation: char, length: int]): bool =
  result = op.operation in ['I', 'M', 'X', '=']

proc createPaf*[T](al: T, targetLen: int, queryLen: int): Paf =
  let
    aScore = al.getAlignmentScore()
    aCigarTuple = al.alToCigarTupleSeq()
  var
    lroff = if aCigarTuple[0].operation == 'D': aCigarTuple[0].length else: 0
    rroff = if aCigarTuple[^1].operation == 'D': aCigarTuple[^1].length else: 0
    lqoff = if aCigarTuple[0].operation == 'I': aCigarTuple[0].length else: 0
    rqoff = if aCigarTuple[^1].operation == 'I': aCigarTuple[^1].length else: 0
    nMatches: int
    blockLength: int
  for i in 0 ..< aCigarTuple.len:
    if aCigarTuple[i].operation == '=':
      nMatches += aCigarTuple[i].length
      blockLength += aCigarTuple[i].length
    else:
      if i > 0 and i < (aCigarTuple.len - 1):
        blockLength += aCigarTuple[i].length
  result = Paf(targetLen: targetLen,
               targetLeft: lroff,
               targetRight: targetLen - rroff,
               queryLen: queryLen,
               queryLeft: lqoff,
               queryRight: queryLen - rqoff,
               score: aScore,
               cigar: aCigarTuple)
  #stdout.writeLine "{s2n}\t{s2l}\t{lqoff}\t{s2l - rqoff}\t+\t{s1n}\t{s1l}\t{lroff}\t{s1l - rroff}\t{nMatches}\t{blockLength}\t\t{aScore * -1}\tcg:Z:{aCigarTuple[1 .. ^2].cigarToString}".fmt



when isMainModule:
  import cligen
  proc test() =
    let
      refS =   "GGGGAAGCCTCACAATCATGGTGGAAGGCAAGGAGGAGCAAGTCACGTCGTACACGGATGGCAGCAGGCAAAGAGAGAGCTTGTGCAGGGAAACTCCCCTG".cstring
      queryS =   "GGAAGCCTCACAATCATGGTGGAAGGCAAGGAGGAGCAAGTCACGTCGTACACGGATGGCAGCAGGCAAAGAGAGAGCTTGTGCAGGGAAACTCCC".cstring
      al = createGapAffine2PieceAligner(0, 4, 6, 3, 12, 1, Alignment, MemoryHigh)
    al.setHeuristicWfAdaptive(50, 10)
    al.setMaxNumThreads(4)
    echo al.alignEndsFree(refS, 20, 20, queryS, 20, 20)
    al.printPretty(stdout, refS, refS.len.cint, queryS, queryS.len.cint)
    al.printPretty($refS, $queryS)
    var
      nOps: cint
      ops = allocShared(sizeof(uint32) * refS.len)
    al.getCigar(true, ops.addr, nOps.addr)
    #let
    #  opsArray = cast[ptr UncheckedArray[uint32]](ops)
    echo al.createPaf(refS.len, queryS.len)
  proc ma(text: string, pattern: string, mismatch: cint = 4, go1: cint = 6, ge1: cint = 3, go2: cint = 12, ge2: cint = 1, s1: cint = 20, e1: cint = 20, s2: cint = 20, e2: cint = 20) =
    let
      al = createGapAffine2PieceAligner(0, mismatch, go1, ge1, go2, ge2, Alignment, MemoryHigh)
      alE = createIndelAligner(Alignment, MemoryHigh)
    al.setHeuristicNone()
    al.setMaxNumThreads(4)
    discard al.alignEnd2End(text, pattern)
    echo al.alignmentChar()
    al.printPretty(text, pattern)
    discard alE.alignEnd2End(text, pattern)
    echo alE.alignmentChar()
    alE.printPretty(text, pattern)
    discard al.alignEndsFree(text, s1, e1, pattern, s2, e2)
    al.printPretty(text, pattern)
    echo al.alignmentChar()
    discard al.alignEndsFree(text, 0.2, pattern, 0.2)
    al.printPretty(text, pattern)
  dispatchMulti([test], [ma])
