{.push header: "armadillo".}
import sequtils
type
  Mat*[T] {.importcpp: "arma::Mat", byref.} = object
  Cube*[T] {.importcpp: "arma::Cube", byref.} = object
  Row*[T] {.importcpp: "arma::Row", byref.} = object
  Col*[T] {.importcpp: "arma::Col", byref.} = object
  ColIter*[T] {.importcpp: "arma::Mat<'0>::col_iterator".} = object
  RowIter*[T] {.importcpp: "arma::Mat<'0>::row_iterator".} = object
  RowVecIter*[T] {.importcpp: "arma::Row<'*0>::iterator".} = object
  SliceIter*[T] {.importcpp: "arma::Cube<'0>::slice_iterator".} = object
  GmmDistEucl* {.importcpp: "arma::gmm_dist_eucl".} = object
  GmmDistMaha* {.importcpp: "arma::gmm_dist_maha".} = object
  GmmDistProb* {.importcpp: "arma::gmm_dist_prob".} = object
  GmmSeedRandomSpread* {.importcpp: "arma::gmm_seed_random_spread".} = object
  GmmSeedRandomSample* {.importcpp: "arma::gmm_seed_random_sample".} = object
  GmmSeedKeepExisting* {.importcpp: "arma::gmm_seed_keep_existing".} = object
  fGMM*[T] {.importcpp: "arma::gmm_priv::gmm_full".} = object
  dGMM*[T] {.importcpp: "arma::gmm_priv::gmm_diag".} = object
#
proc createMat*[T](nr, nc: uint64): Mat[T] {.importcpp: "arma::Mat<'*0>(@)", constructor.}
proc createRow*[T](nr: uint64): Row[T] {.importcpp: "arma::Row<'*0>(@)", constructor.}
proc createVec*[T](ne: uint64): Col[T] {.importcpp: "arma::Col<'*0>(@)", constructor.}
proc printMat*[T](m: T) {.importcpp: "#.print()".}
proc `[]`*[T](m: Row[T]|Col[T]; i: uint64): T {.importcpp: "#(#)".}
proc `[]`*[T](m: Cube[T]; i: uint64): Mat[T] {.importcpp: "#.slice(#)".}
proc `[]`*[T](m: Mat[T]; r, c: uint64): T {.importcpp: "#(#,#)".}
proc `[]=`*[T](m: var Mat[T]; r, c: uint64; e: T) {.importcpp: "#(#,#)=#".}
proc `[]=`*[T](m: var Col[T]; i: uint64; e: T) {.importcpp: "#(#)=#".}
proc `[]=`*[T](m: var Row[T]; i: uint64; e: T) {.importcpp: "#(#)=#".}
proc diag*[T](m: Mat[T]; i: int64 = 0): Col[T] {.importcpp: "#.diag(#)".}
proc transpose*[T](m: Mat[T]): Mat[T] {.importcpp: "#.t()".}
proc gmmLearn*[T](g: fGMM[T]|dGMM[T]; m: Mat[T]; nGaussians: uint64 = 3; distMode: GmmDistMaha|GmmDistEucl; seedMode: GmmSeedRandomSample|GmmSeedRandomSpread|GmmSeedKeepExisting; kmIter: uint64 = 15; emIter: uint64 = 100; varFloor: T = 0.001; printMode: bool = true): bool {.importcpp: "#.learn(@)".}
proc gmmNGaussians*(g: fGMM|dGMM): uint {.importcpp: "#.n_gaus()".}
proc gmmMeans*[T](g: fGMM[T]|dGMM[T]): Mat[T] {.importcpp: "#.means".}
proc gmmHefts*[T](g: fGMM[T]|dGMM[T]): Mat[T] {.importcpp: "#.hefts".}
proc gmmCovs*[T](g: dGMM[T]): Mat[T] {.importcpp: "#.dcovs".}
proc gmmCovs*[T](g: fGMM[T]): Cube[T] {.importcpp: "#.fcovs".}
proc gmmAssign*[T](g: fGMM[T]; x: Col[T]; dist: GmmDistEucl|GmmDistProb): uint64 {.importcpp: "#.assign(#,#)".}
proc gmmLogP*[T](g: fGMM[T]; x: Mat[T]; idx: uint64): Row[T] {.importcpp: "#.log_p(#,#)".}
proc gmmLogP*[T](g: fGMM[T]; x: Mat[T]): Row[T] {.importcpp: "#.log_p(#)".}
proc gmmSave*(g: fGMM|dGMM; f: cstring) {.importcpp: "#.save(#)".}
proc gmmLoad*(g: fGMM|dGMM; f: cstring) {.importcpp: "#.load(#)".}
proc colBegin*[T](m: Mat[T]; idx: uint64): ColIter[T] {.importcpp: "#.begin_col(#)".}
proc colBegin*[T](m: Col[T]): ColIter[T] {.importcpp: "#.begin()".}
proc rowBegin*[T](m: Row[T]): RowVecIter[T] {.importcpp: "#.begin()".}
proc colEnd*[T](m: Mat[T]; idx: uint64): ColIter[T] {.importcpp: "#.end_col(#)".}
proc colEnd*[T](m: Col[T]): ColIter[T] {.importcpp: "#.end()".}
proc rowEnd*[T](m: Row[T]): RowVecIter[T] {.importcpp: "#.end()".}
proc rowBegin*[T](m: Mat[T]; idx: uint64): RowIter[T] {.importcpp: "#.begin_row(#)".}
proc rowEnd*[T](m: Mat[T]; idx: uint64): RowIter[T] {.importcpp: "#.end_row(#)".}
proc `[]`*[T](it: ColIter[T]|RowVecIter[T]|RowIter[T]): T {.importcpp: "(*#)".}
proc `inc`*(it: var ColIter|RowVecIter|RowIter) {.importcpp: "++#".}
proc `!=`*(it1, it2: ColIter|RowVecIter|RowIter): bool {.importcpp: "# != #".}
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

iterator item*[T](m: Row[T]): T =
  var itB = m.rowBegin()
  let itE = m.rowEnd()
  while itB != itE:
    yield itB[]
    itB.inc()

proc rowToSeq*[T](m: Mat[T]; idx: uint64): seq[T] =
  result = toSeq(m.row(idx))
proc colToSeq*[T](m: Mat[T]; idx: uint64): seq[T] =
  result = toSeq(m.col(idx))

when isMainModule:
  import cligen, random, strformat, strutils
  proc test(n1: uint64 = 5000;
            n2: uint64 = 5000;
            m1x: float = 1.5;
            m1y: float = 3.1;
            m2x: float = 2.5;
            m2y: float = 3.5;
            m1xsd: float = 0.1;
            m1ysd: float = 0.2;
            m2xsd: float = 0.15;
            m2ysd: float = 0.3) =
    var
      g: fGMM[float]
      m = createMat[float](n1 + n2, 2)
      d: GmmDistEucl
      s: GmmSeedRandomSpread
    for i in 0..<n1:
      m[i,0] = gauss(m1x, m1xsd)
      m[i,1] = gauss(m1y, m1ysd)
    for i in n1..<n1+n2:
      m[i,0] = gauss(m2x, m2xsd)
      m[i,1] = gauss(m2y, m2ysd)
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
      stdout.write "{d}\t".fmt
    stdout.write "\n"

    stdout.writeLine "cov[0] +1 diag:"
    for d in outCovs[0].diag(1).col:
      stdout.write "{d}\t".fmt
    stdout.write "\n"

    stdout.writeLine "cov[0] -1 diag:"
    for d in outCovs[1].diag(-1).col:
      stdout.write "{d}\t".fmt
    stdout.write "\n"
    
    stdout.writeLine "testAssign:"
    var
      r = createVec[float](2)
      om = createMat[float](2, 2)
    stdout.writeLine "vec created"
    r[0] = 1.1
    r[1] = 2.5
    stdout.writeLine "vec assigned"
    stdout.writeLine "G: {g.gmmAssign(r, d)}".fmt
    r[0] = 2.2
    r[1] = 4
    stdout.writeLine "G: {g.gmmAssign(r, d)}".fmt
    om[0,0] = 2.5
    om[1,0] = 3.5
    om[0,1] = 1.5
    om[1,1] = 3.1
    om.printMat
    let
      o1 = g.gmmLogP(om, 0)
      o2 = g.gmmLogP(om, 1)
      oa = g.gmmLogP(om)
    stdout.writeLine "G prob:"
    for d in 0..<2.uint64:
      stdout.writeLine "{o1[d]}\t{o2[d]}\t{oa[d]}".fmt
  dispatch test
