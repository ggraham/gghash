{.passl: "-lgomp -llapack -lopenblas".}
{.passc: "-fopenmp -I../external/armadillo/include".}
{.push header: "<armadillo>".}
import sequtils
type
  Mat*[T] {.importcpp: "arma::Mat", byref.} = object
  Cube*[T] {.importcpp: "arma::Cube", byref.} = object
  Row*[T] {.importcpp: "arma::Row", byref.} = object
  Col*[T] {.importcpp: "arma::Col", byref.} = object
  ColIter*[T] {.importcpp: "arma::Mat<'0>::col_iterator".} = object
  RowIter*[T] {.importcpp: "arma::Mat<'0>::row_iterator".} = object
  SliceIter*[T] {.importcpp: "arma::Cube<'0>::slice_iterator".} = object
  GmmDistEucl* {.importcpp: "arma::gmm_dist_eucl".} = object
  GmmDistMaha* {.importcpp: "arma::gmm_dist_maha".} = object
  GmmSeedRandomSpread* {.importcpp: "arma::gmm_seed_random_spread".} = object
  GmmSeedRandomSample* {.importcpp: "arma::gmm_seed_random_sample".} = object
  GmmSeedKeepExisting* {.importcpp: "arma::gmm_seed_keep_existing".} = object
  fGMM*[T] {.importcpp: "arma::gmm_priv::gmm_full".} = object
  dGMM*[T] {.importcpp: "arma::gmm_priv::gmm_diag".} = object
#
proc createMat*[T](nr, nc: uint64): Mat[T] {.importcpp: "arma::Mat<'*0>(@)", constructor.}
proc printMat*[T](m: T) {.importcpp: "#.print()".}
proc `[]`*[T](m: Row[T]|Col[T]; i: uint64): T {.importcpp: "#(#)".}
proc `[]`*[T](m: Cube[T]; i: uint64): Mat[T] {.importcpp: "#.slice(#)".}
proc `[]`*[T](m: Mat[T]; r, c: uint64): T {.importcpp: "#(#,#)".}
proc `[]=`*[T](m: var Mat[T]; r, c: uint64; e: T) {.importcpp: "#(#,#)=#".}
proc diag*[T](m: Mat[T]; i: int64 = 0): Col[T] {.importcpp: "#.diag(#)".}
proc transpose*[T](m: Mat[T]): Mat[T] {.importcpp: "#.t()".}
proc gmmLearn*[T](g: fGMM[T]|dGMM[T]; m: Mat[T]; nGaussians: uint64 = 3; distMode: GmmDistMaha|GmmDistEucl; seedMode: GmmSeedRandomSample|GmmSeedRandomSpread|GmmSeedKeepExisting; kmIter: uint64 = 15; emIter: uint64 = 100; varFloor: T = 0.001; printMode: bool = true): bool {.importcpp: "#.learn(@)".}
proc gmmNGaussians*(g: fGMM|dGMM): uint {.importcpp: "#.n_gaus()".}
proc gmmMeans*[T](g: fGMM[T]|dGMM[T]): Mat[T] {.importcpp: "#.means".}
proc gmmHefts*[T](g: fGMM[T]|dGMM[T]): Mat[T] {.importcpp: "#.hefts".}
proc gmmCovs*[T](g: dGMM[T]): Mat[T] {.importcpp: "#.dcovs".}
proc gmmCovs*[T](g: fGMM[T]): Cube[T] {.importcpp: "#.fcovs".}
proc gmmSave*(g: fGMM|dGMM, f: cstring) {.importcpp: "#.save(#)".}
proc gmmLoad*(g: fGMM|dGMM, f: cstring) {.importcpp: "#.load(#)".}
proc colBegin*[T](m: Mat[T]; idx: uint64): ColIter[T] {.importcpp: "#.begin_col(#)".}
proc colBegin*[T](m: Col[T]): ColIter[T] {.importcpp: "#.begin()".}
proc colEnd*[T](m: Mat[T]; idx: uint64): ColIter[T] {.importcpp: "#.end_col(#)".}
proc colEnd*[T](m: Col[T]): ColIter[T] {.importcpp: "#.end()".}
proc rowBegin*[T](m: Mat[T]; idx: uint64): RowIter[T] {.importcpp: "#.begin_row(#)".}
proc rowEnd*[T](m: Mat[T]; idx: uint64): RowIter[T] {.importcpp: "#.end_row(#)".}
proc `[]`*[T](it: ColIter[T]|RowIter[T]): T {.importcpp: "(*#)".}
proc `inc`*(it: var ColIter|RowIter) {.importcpp: "++#".}
proc `!=`*(it1, it2: ColIter|RowIter): bool {.importcpp: "# != #".}
proc insertRows*[T](m: Mat[T]; idx, nRows: uint64) {.importcpp: "#.insert_rows(@)".}
proc shedRows*[T](m: Mat[T]; idxFrom, idxTo: uint64) {.importcpp: "#.shed_rows(@)".}
{.pop.}
iterator col*[T](m: Col[T]): T =
  var itB = m.colBegin()
  let itE = m.colEnd()
  while itB != itE:
    yield itB[]
    itB.inc()

iterator col*[T](m: Mat[T]; idx: uint64): T =
  var itB = m.colBegin(idx)
  let itE = m.colEnd(idx)
  while itB != itE:
    yield itB[]
    itB.inc()

iterator row*[T](m: Mat[T]; idx: uint64): T =
  var itB = m.rowBegin(idx)
  let itE = m.rowEnd(idx)
  while itB != itE:
    yield itB[]
    itB.inc()

proc rowToSeq*[T](m: Mat[T]; idx: uint64): seq[T] =
  result = toSeq(m.row(idx))
proc colToSeq*[T](m: Mat[T]; idx: uint64): seq[T] =
  result = toSeq(m.col(idx))

when isMainModule:
  import cligen, random, strformat, parsecsv, streams, strutils, ggplotnim
  proc test(f: string = "fGMM.gmm";
            n1: uint64 = 5000;
            n2: uint64 = 5000;
            m1x: float = 1.5;
            m1y: float = 3.1;
            m2x: float = 2.5;
            m2y: float = 3.5;
            m1xsd: float = 2.5;
            m1ysd: float = 1.0;
            m2xsd: float = 3.5;
            m2ysd: float = 2.2;
            plot: bool = true) =
    var
      g: fGMM[float]
    #  fs = newFileStream(s, fmRead)
    #  parser: CsvParser
    #  m = createMat[float](272, 2)
    #  idx: uint
    #parser.open(fs, s)
    #while parser.readRow:
    #  m[idx, 0]=parser.row[1].parseFloat
    #  m[idx, 1]=parser.row[2].parseFloat
    #  idx.inc
    var
      m = createMat[float](n1 + n2, 2)
    for i in 0..<n1:
      m[i,0] = gauss(m1x, m1xsd)
      m[i,1] = gauss(m1y, m1ysd)
    for i in n1..<n1+n2:
      m[i,0] = gauss(m2x, m2xsd)
      m[i,1] = gauss(m2y, m2ysd)
    var 
      d: GmmDistEucl
      s: GmmSeedRandomSpread
    discard g.gmmLearn(m.transpose, 2, d, s)
    let
      outMeans = g.gmmMeans()
      outHefts = g.gmmHefts()
      outCovs  = g.gmmCovs()
    stdout.writeLine "2 x {n1+n2} input".fmt
    stdout.writeLine "means:"
    outMeans.printMat
    stdout.writeLine "hefts:"
    outHefts.printMat
    stdout.writeLine "covs:"
    outCovs.printMat
    stdout.writeLine "cov[0] diag:"
    for d in outCovs[0].diag.col:
      stdout.writeLine "{d}\t".fmt
    stdout.writeLine "cov[0] +1 diag:"
    for d in outCovs[0].diag(1).col:
      stdout.writeLine "{d}\t".fmt
    for d in outCovs[1].diag(-1).col:
      stdout.writeLine "{d}\t".fmt
    if plot:
      let 
        x = m.colToSeq(0)
        y = m.colToSeq(1)
        df = toDf(x, y)
        xMeans = outMeans.rowToSeq(0)
        yMeans = outMeans.rowToSeq(1)
        meanSize = outHefts.rowToSeq(0)
        dfMeans = toDf(xMeans, yMeans, meanSize)
      ggplot(df, aes("x", "y")) +
        geom_point()+
        geom_point(aes = aes(x = "xMeans", y = "yMeans"), data = dfMeans, color = "red")+
        ggsave("./plot.png", width = 720, height = 480)
  dispatch test
