import logging, stats, streams, sequtils, zip/gzipfiles, klib, nimPtHash, nimWfa, nimGmm, tables, nimNt, cligen, strformat
type
  HashedConsensusSequence = object
    hashes: seq[uint64]

proc main(r1: string; r2: string;
          maxReadLength: int = 101;
          minOverlapLength: int = 14;
          nG: uint64 = 7;
          nD: uint64 = 2;
          quiet: bool = false;
          nKiter: uint64 = 25;
          nEMiter: uint64 = 500;
          k: uint64 = 12;
          minLogProb: float = 1;
          threads: uint64 = 8;
          writeModel: string = "";
          loadModel: string = "";
          assignedKCounts: string = "";
          summaryStats: string = "";
          readMetrics: string = "") =
  let
    phf = newGHash(k, threads, avg_partition_size = 100000)
  var
    files: tuple[r1: Bufio[GzFile], r2: Bufio[GzFile]]
    output: tuple[ro: GzFileStream, so: FileStream, ko: GzFileStream]
    reads: tuple[r1: FastxRecord, r2: FastxRecord]
    pairCount: tuple[valid: uint64, total: uint64]
    cigarOps = cast[ptr UncheckedArray[uint32]](allocShared(sizeof(uint32) * 100))
    cigarLen: cint
    gcStat, lengthStat: RunningStat
    consSeqs: seq[HashedConsensusSequence]
    m: tuple[mat: Mat[float], nCols: uint64, lengthStats: RunningStat, gcStats: RunningStat] = (createMat[float](2, 1e6.uint64), 1e6.uint64, lengthStat, gcStat)
    logger = newConsoleLogger(fmtStr = "[$time] - [$appname]: ", useStderr = true)
  addHandler(logger)
  if summaryStats != "":
    output.so = newFileStream(summaryStats, fmWrite)
  if readMetrics != "":
    output.ro = newGzFileStream(readMetrics, fmWrite)
  if assignedKCounts != "":
    output.ko = newGzFileStream(assignedKCounts, fmWrite)
  let
    gla = createGapAffine2PieceAligner(-1, 3, 4, 2, 10, 1, Alignment, MemoryHigh)
  gla.setHeuristicNone()
  gla.setMaxNumThreads(4)
  files.r1.open(r1)
  files.r2.open(r2)
  if not quiet: info("loaded FASTQs R1: {r1}, R2: {r2}".fmt)
  while files.r1.readFastx(reads.r1):
    doAssert(files.r2.readFastx(reads.r2))
    pairCount.total.inc
    if not quiet:
      if pairCount.total mod 1e6.uint64 == 0:
        info("{pairCount.total} reads processed; {pairCount.valid} valid pairs".fmt)
    doAssert(reads.r1.name == reads.r2.name)
    doAssert(StatusAlgCompleted == gla.alignEndsFree(maxReadLength, reads.r1.seq, maxReadLength, reads.r2.seq.rev.comp))
    let 
      thisCigar = gla.alToCigarTupleSeqEnum(cigarOps, cigarLen)
    if thisCigar.maxCigarMatchEnum > minOverlapLength:
      pairCount.valid.inc
      if pairCount.valid mod 1e6.uint64 == 0:
        m.mat.insertCols(pairCount.valid, 1e6.uint64)
        m.nCols.inc(1e6.uint64)
      var
        calculatedLength: uint64 = 0
        offsets: tuple[r1: int, r2: int]
        consensusSeq: string
      for c in thisCigar:
        case c.operation:
          of Del:
            consensusSeq.add(reads.r1.seq[offsets.r1..<(offsets.r1 + c.length)])
            offsets.r1.inc(c.length)
          of Equal, Match:
            consensusSeq.add(reads.r1.seq[offsets.r1..<(offsets.r1 + c.length)])
            offsets.r1.inc(c.length)
            offsets.r2.inc(c.length)
          of Ins:
            consensusSeq.add(reads.r2.seq.rev.comp[offsets.r2..<(offsets.r2 + c.length)])
            offsets.r2.inc(c.length)
          of Mismatch:
            consensusSeq.add('N')
            offsets.r1.inc(c.length)
            offsets.r2.inc(c.length)
          else:
            info("ERR: unknown CIGAR operation")
        calculatedLength.inc(c.length)
      phf.insert(consensusSeq)
      consSeqs.add(HashedConsensusSequence(hashes: phf.hash(consensusSeq)))
      m.mat[0, pairCount.valid - 1] = calculatedLength.float
      m.mat[1, pairCount.valid - 1] = consensusSeq.gcContent
      m.gcStats.push(m.mat[1, pairCount.valid - 1])
      m.lengthStats.push(m.mat[0, pairCount.valid - 1])
      if readMetrics != "":
        output.ro.writeLine "{m.mat[0, pairCount.valid - 1]:g}\t{m.mat[1, pairCount.valid - 1]:0.3f}".fmt
  deallocShared(cigarOps)
  phf.build()
  if readMetrics != "":
    output.ro.close()
  if not quiet:
    info("final counts: {pairCount}".fmt)
    info("mean length: {m.lengthStats.mean:0.2f}; mean GC: {m.gcStats.mean:0.2f}".fmt)
  m.mat.shedCols(pairCount.valid, m.nCols - 1)
  for i in 0..<pairCount.valid:
    let tmp = m.mat[0,i]
    m.mat[0,i] = tmp - m.lengthStats.mean
  var
    g: fGMM[float]
    d: GmmDistMaha
    dp: GmmDistProb
    v: seq[seq[uint64]] = newSeqWith(nG.int, newSeq[uint64](phf.size()))
  if loadModel != "":
    g.gmmLoad(loadModel.cstring)
    var
      s: GmmSeedKeepExisting
    doAssert g.gmmLearn(m.mat, nG, d, s, nKiter, nEMiter)
  else:
    var
      s: GmmSeedRandomSpread
    doAssert g.gmmLearn(m.mat, nG, d, s, nKiter, nEMiter)
  let hefts = g.gmmHefts.rowToSeq(0)
  g.gmmMeans.printMat
  g.gmmCovs.printMat
  let
    assignments = g.gmmAssign(m.mat, dp)
  for i in 0..<consSeqs.len:
    let
      assignedG = assignments[i.csize_t]
      assignedGprob = g.gmmLogP(m.mat.col(i.csize_t), assignedG)
    if assignedGprob >= minLogProb:
      for k in consSeqs[i].hashes:
        v[assignedG][phf.index(k)]+=1
  if assignedKCounts != "":
    for i in 0..<nG:
      for k in 0..<phf.size():
        output.ko.writeLine "{i}\t{k}\t{v[i][k]}".fmt
    output.ko.close()
  if summaryStats != "":
    output.so.write "meanFragmentSize"
    for k in ["mean"]:
      for n in 0..<nG:
        for d in 0..<nD:
          output.so.write "\tg{n}_d{d}_{k}".fmt
        output.so.write "\tg{n}_heft".fmt
    output.so.write "\n{m.lengthStats.mean:0.6f}".fmt
    for n in 0..<nG:
      for r in g.gmmMeans.col(n):
        output.so.write "\t{r:0.6f}".fmt
      output.so.write "\t{hefts[n]:0.6f}".fmt
    output.so.write "\n"
    output.so.close()
  if writeModel != "":
    g.gmmSave(writeModel.cstring)
dispatch main

