{.passl: "-lopenblas".}
{.push header: "armadillo".}
type
  Mat[T] {.importcpp: "arma::Mat<'0>".} = object
  GMM {.importcpp: "arma::gmm_full".} = object
  DistMode {.importcpp: "arma::gmm_dist_mode".} = enum
    eucl_dist,
    maha_dist
  SeedMode {.importcpp: "arma::gmm_seed_mode".} = enum
    keep_existing,
    static_subset,
    random_subset,
    static_spread,
    random_spread
#
proc mat[T](n_rows, n_cols: int): Mat[T] {.importcpp: "arma::Mat<'*0>(@)".}
proc `[]`[T](m: Mat[T]; r, c: int): T {.importcpp: "#(#,#)".}
proc `[]=`[T](m: Mat[T]; r, c: int; e: T) {.importcpp: "#(#,#)=#".}
proc t[T](m: Mat[T]): Mat[T] {.importcpp: "#.t()".}
proc print[T](m: Mat[T]) {.importcpp: "#.print()".}
#proc createGmm[T](): GMM[T] {.importcpp: "arma::gmm_full<'0>", constructor.}
proc gmmLearn[T](g: GMM; m: Mat[T]; n_gaus: uint32; dist_mode: DistMode = DistMode.eucl_dist; seed_mode: SeedMode = SeedMode.random_spread; km_iter, em_iter: uint32; var_floor: T; print_mode: bool = true) {.importcpp: "#.learn(@)".}
#
{.pop.}

when isMainModule:
  import cligen, strformat
  proc test() =
    var 
      m = mat[float](5, 5)
      g: GMM
    m[1,1] = 4
    m[1,2] = 3
    m[2,1] = 2
    stdout.writeLine "m element at 0,0: {m[0,0]}".fmt
    stdout.writeLine "m element at 1,1: {m[1,1]}".fmt
    stdout.writeLine "m element at 1,2: {m[1,2]}".fmt
    stdout.writeLine "m element at 2,1: {m[2,1]}".fmt
    m.print
    var tm = m.t
    stdout.writeLine "tm element at 1,2: {tm[1,2]}".fmt
    stdout.writeLine "tm element at 2,1: {tm[2,1]}".fmt
    tm.print
    g.gmmLearn(m, 2, eucl_dist, random_spread, 5, 5, 0.5)
  dispatch test
    
