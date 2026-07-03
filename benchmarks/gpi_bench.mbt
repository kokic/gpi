///|
const BENCH_SIZE = 4096

///|
const BENCH_QUERY_COUNT = 256

///|
const BENCH_REMOVE_COUNT = 256

///|
const SYM_FN = 0

///|
const SYM_ARRAY = 1

///|
const SYM_ARRAY_VIEW = 2

///|
const SYM_OPTION = 3

///|
const SYM_RESULT = 4

///|
const SYM_ITER = 5

///|
const SYM_ITER2 = 6

///|
const SYM_TUPLE2 = 7

///|
const SYM_MAP = 8

///|
const SYM_STRING = 20

///|
const SYM_STRING_VIEW = 21

///|
const SYM_INT = 22

///|
const SYM_BOOL = 23

///|
const SYM_UNIT = 24

///|
const SYM_CHAR = 25

///|
const SYM_UINT16 = 26

///|
const SYM_JSON = 27

///|
fn tv(id : Int) -> @gpi.Pattern[Int, Int] {
  @gpi.pattern_var(id)
}

///|
fn tc(symbol : Int) -> @gpi.Pattern[Int, Int] {
  @gpi.pattern_leaf(symbol)
}

///|
fn app(
  symbol : Int,
  args : Array[@gpi.Pattern[Int, Int]],
) -> @gpi.Pattern[Int, Int] {
  @gpi.pattern_node(symbol, args)
}

///|
fn arr(t : @gpi.Pattern[Int, Int]) -> @gpi.Pattern[Int, Int] {
  app(SYM_ARRAY, [t])
}

///|
fn arr_view(t : @gpi.Pattern[Int, Int]) -> @gpi.Pattern[Int, Int] {
  app(SYM_ARRAY_VIEW, [t])
}

///|
fn opt(t : @gpi.Pattern[Int, Int]) -> @gpi.Pattern[Int, Int] {
  app(SYM_OPTION, [t])
}

///|
fn res(
  ok : @gpi.Pattern[Int, Int],
  err : @gpi.Pattern[Int, Int],
) -> @gpi.Pattern[Int, Int] {
  app(SYM_RESULT, [ok, err])
}

///|
fn iter(t : @gpi.Pattern[Int, Int]) -> @gpi.Pattern[Int, Int] {
  app(SYM_ITER, [t])
}

///|
fn iter2(
  a : @gpi.Pattern[Int, Int],
  b : @gpi.Pattern[Int, Int],
) -> @gpi.Pattern[Int, Int] {
  app(SYM_ITER2, [a, b])
}

///|
fn tuple2(
  a : @gpi.Pattern[Int, Int],
  b : @gpi.Pattern[Int, Int],
) -> @gpi.Pattern[Int, Int] {
  app(SYM_TUPLE2, [a, b])
}

///|
fn map_t(
  k : @gpi.Pattern[Int, Int],
  v : @gpi.Pattern[Int, Int],
) -> @gpi.Pattern[Int, Int] {
  app(SYM_MAP, [k, v])
}

///|
fn fn_type(
  args : Array[@gpi.Pattern[Int, Int]],
  ret : @gpi.Pattern[Int, Int],
) -> @gpi.Pattern[Int, Int] {
  let all = args.copy()
  all.push(ret)
  app(SYM_FN, all)
}

///|
fn pred(t : @gpi.Pattern[Int, Int]) -> @gpi.Pattern[Int, Int] {
  fn_type([t], tc(SYM_BOOL))
}

///|
fn callback1(
  arg : @gpi.Pattern[Int, Int],
  ret : @gpi.Pattern[Int, Int],
) -> @gpi.Pattern[Int, Int] {
  fn_type([arg], ret)
}

///|
fn callback2(
  a : @gpi.Pattern[Int, Int],
  b : @gpi.Pattern[Int, Int],
  ret : @gpi.Pattern[Int, Int],
) -> @gpi.Pattern[Int, Int] {
  fn_type([a, b], ret)
}

///|
fn callback3(
  a : @gpi.Pattern[Int, Int],
  b : @gpi.Pattern[Int, Int],
  c : @gpi.Pattern[Int, Int],
  ret : @gpi.Pattern[Int, Int],
) -> @gpi.Pattern[Int, Int] {
  fn_type([a, b, c], ret)
}

///|
fn core_signature(seed : Int) -> @gpi.Pattern[Int, Int] {
  let a = tv(0)
  let b = tv(1)
  let c = tv(2)
  match seed % 72 {
    0 => fn_type([arr(a), arr(a)], arr(a)) // Array::add
    1 => fn_type([arr(a), pred(a)], tc(SYM_BOOL)) // Array::all
    2 => fn_type([arr(a), arr_view(a)], tc(SYM_UNIT)) // Array::append
    3 => fn_type([arr(a), tc(SYM_INT)], a) // Array::at
    4 => fn_type([arr(a), a], res(tc(SYM_INT), tc(SYM_INT))) // binary_search
    5 =>
      fn_type(
        [arr(a), callback1(a, tc(SYM_INT))],
        res(tc(SYM_INT), tc(SYM_INT)),
      )
    6 => fn_type([arr(a), callback2(a, a, tc(SYM_BOOL))], arr(arr_view(a)))
    7 => fn_type([arr(a), tc(SYM_INT)], arr(arr_view(a))) // chunks
    8 => fn_type([arr(a)], tc(SYM_UNIT)) // clear
    9 => fn_type([arr(a), arr(a)], tc(SYM_INT)) // compare
    10 => fn_type([arr(a), a], tc(SYM_BOOL)) // contains
    11 => fn_type([arr(a)], arr(a)) // copy
    12 => fn_type([arr(a), a], tc(SYM_INT)) // count
    13 => fn_type([arr(a), pred(a)], tc(SYM_INT)) // count_if
    14 => fn_type([arr(a), tc(SYM_INT), tc(SYM_INT)], arr(a)) // drain
    15 => fn_type([arr(a), callback1(a, tc(SYM_UNIT))], tc(SYM_UNIT)) // each
    16 =>
      fn_type([arr(a), callback2(tc(SYM_INT), a, tc(SYM_UNIT))], tc(SYM_UNIT))
    17 => fn_type([arr(a), pred(a)], arr(a)) // filter
    18 => fn_type([arr(a), callback1(a, opt(b))], arr(b)) // filter_map
    19 => fn_type([arr(arr(a))], arr(a)) // flatten
    20 => fn_type([arr(a), b, callback2(b, a, b)], b) // fold
    21 => fn_type([arr(a), b, callback3(tc(SYM_INT), b, a, b)], b) // foldi
    22 => fn_type([iter(a)], arr(a)) // from_iter
    23 => fn_type([arr(a), tc(SYM_INT)], opt(a)) // get
    24 => fn_type([arr(a), tc(SYM_INT), tc(SYM_INT)], opt(arr_view(a))) // get_view
    25 => fn_type([arr(a)], iter(a)) // iter
    26 => fn_type([arr(a)], iter2(tc(SYM_INT), a)) // iter2
    27 => fn_type([arr(a), tc(SYM_STRING_VIEW)], tc(SYM_STRING)) // join
    28 => fn_type([arr(a)], opt(a)) // last/pop
    29 => fn_type([tc(SYM_INT), a], arr(a)) // make
    30 => fn_type([tc(SYM_INT), callback1(tc(SYM_INT), a)], arr(a)) // makei
    31 => fn_type([arr(a), callback1(a, b)], arr(b)) // map
    32 => fn_type([arr(a), callback2(tc(SYM_INT), a, b)], arr(b)) // mapi
    33 => fn_type([arr(a), tc(SYM_INT), a], tc(SYM_UNIT)) // insert/set
    34 => fn_type([arr(a), tc(SYM_INT)], a) // remove
    35 => fn_type([arr(a), tc(SYM_INT)], arr(a)) // repeat
    36 => fn_type([arr(a), callback2(a, a, tc(SYM_INT))], tc(SYM_UNIT)) // sort_by
    37 => fn_type([arr(a), callback1(a, b)], tc(SYM_UNIT)) // sort_by_key
    38 => fn_type([arr(tuple2(a, b))], tuple2(arr(a), arr(b))) // unzip
    39 => fn_type([arr(a), arr(b)], arr(tuple2(a, b))) // zip
    40 => fn_type([tc(SYM_STRING), tc(SYM_STRING)], tc(SYM_STRING)) // String::add
    41 =>
      fn_type([tc(SYM_STRING), tc(SYM_STRING_VIEW)], opt(tc(SYM_STRING_VIEW)))
    42 =>
      fn_type(
        [tc(SYM_STRING), callback1(tc(SYM_CHAR), tc(SYM_BOOL))],
        tc(SYM_BOOL),
      )
    43 => fn_type([tc(SYM_STRING), tc(SYM_INT)], tc(SYM_UINT16)) // at
    44 => fn_type([tc(SYM_STRING)], arr_view(tc(SYM_UINT16))) // code_units
    45 => fn_type([tc(SYM_STRING), tc(SYM_STRING)], tc(SYM_INT)) // compare
    46 => fn_type([tc(SYM_STRING), tc(SYM_STRING_VIEW)], tc(SYM_BOOL)) // contains
    47 => fn_type([tc(SYM_STRING), tc(SYM_CHAR)], tc(SYM_BOOL)) // contains_char
    48 => fn_type([tc(SYM_STRING), tc(SYM_UINT16)], tc(SYM_BOOL))
    49 => fn_type([tc(SYM_STRING), tc(SYM_STRING_VIEW)], opt(tc(SYM_INT))) // find
    50 =>
      fn_type(
        [tc(SYM_STRING), callback1(tc(SYM_CHAR), tc(SYM_BOOL))],
        opt(tc(SYM_INT)),
      )
    51 => fn_type([tc(SYM_STRING), a, callback2(a, tc(SYM_CHAR), a)], a) // fold
    52 => fn_type([arr_view(tc(SYM_CHAR))], tc(SYM_STRING)) // from_array
    53 => fn_type([iter(tc(SYM_CHAR))], tc(SYM_STRING)) // from_iter
    54 => fn_type([tc(SYM_STRING), tc(SYM_INT)], opt(tc(SYM_CHAR))) // get_char
    55 =>
      fn_type(
        [tc(SYM_STRING), tc(SYM_INT), tc(SYM_INT)],
        opt(tc(SYM_STRING_VIEW)),
      )
    56 => fn_type([tc(SYM_STRING)], iter(tc(SYM_CHAR))) // iter
    57 => fn_type([tc(SYM_STRING)], iter2(tc(SYM_INT), tc(SYM_CHAR))) // iter2
    58 => fn_type([tc(SYM_INT), tc(SYM_CHAR)], tc(SYM_STRING)) // make
    59 => fn_type([tc(SYM_STRING), tc(SYM_INT), tc(SYM_CHAR)], tc(SYM_STRING)) // pad
    60 =>
      fn_type(
        [tc(SYM_STRING), tc(SYM_STRING_VIEW), tc(SYM_STRING_VIEW)],
        tc(SYM_STRING),
      )
    61 =>
      fn_type([tc(SYM_STRING), tc(SYM_STRING_VIEW)], iter(tc(SYM_STRING_VIEW))) // split
    62 => fn_type([tc(SYM_STRING)], arr(tc(SYM_CHAR))) // to_array
    63 => fn_type([tc(SYM_STRING)], tc(SYM_JSON)) // to_json
    64 => fn_type([opt(a), callback1(a, opt(b))], opt(b)) // Option::bind
    65 => fn_type([opt(a), pred(a)], opt(a)) // Option::filter
    66 => fn_type([opt(a), callback1(a, b)], opt(b)) // Option::map
    67 => fn_type([opt(a), b, callback1(a, b)], b) // Option::map_or
    68 => fn_type([res(a, b), callback1(a, c)], res(c, b)) // Result::map
    69 => fn_type([res(a, b), callback1(b, c)], res(a, c)) // Result::map_err
    70 => fn_type([map_t(a, b), a], b) // Map::at
    _ => fn_type([iter(a), callback1(a, b)], iter(b)) // Iter::map
  }
}

///|
fn concrete_type(seed : Int) -> @gpi.Pattern[Int, Int] {
  match seed % 12 {
    0 => tc(SYM_INT)
    1 => tc(SYM_STRING)
    2 => tc(SYM_BOOL)
    3 => tc(SYM_CHAR)
    4 => opt(tc(SYM_INT))
    5 => arr(tc(SYM_STRING))
    6 => iter(tc(SYM_CHAR))
    7 => res(tc(SYM_INT), tc(SYM_STRING))
    8 => arr_view(tc(SYM_UINT16))
    9 => tuple2(tc(SYM_INT), tc(SYM_STRING))
    10 => map_t(tc(SYM_STRING), tc(SYM_INT))
    _ => tc(SYM_JSON)
  }
}

///|
fn query_signature(seed : Int) -> @gpi.Pattern[Int, Int] {
  let x = concrete_type(seed)
  let y = concrete_type(seed + 3)
  match seed % 24 {
    0 => fn_type([arr(x), callback1(x, y)], arr(y))
    1 => fn_type([arr(x), pred(x)], arr(x))
    2 => fn_type([arr(x), x], tc(SYM_BOOL))
    3 => fn_type([arr(x), tc(SYM_INT)], opt(x))
    4 => fn_type([arr(x)], iter(x))
    5 => fn_type([iter(x), callback1(x, y)], iter(y))
    6 => fn_type([opt(x), callback1(x, y)], opt(y))
    7 => fn_type([res(x, y), callback1(x, tc(SYM_BOOL))], res(tc(SYM_BOOL), y))
    8 => fn_type([tc(SYM_STRING), tc(SYM_STRING_VIEW)], tc(SYM_BOOL))
    9 =>
      fn_type(
        [tc(SYM_STRING), callback1(tc(SYM_CHAR), tc(SYM_BOOL))],
        opt(tc(SYM_INT)),
      )
    10 => fn_type([tc(SYM_STRING)], iter(tc(SYM_CHAR)))
    11 => fn_type([tc(SYM_STRING), tc(SYM_INT)], opt(tc(SYM_CHAR)))
    12 => fn_type([map_t(tc(SYM_STRING), x), tc(SYM_STRING)], x)
    13 => fn_type([arr_view(x)], arr(x))
    14 => fn_type([tc(SYM_INT), x], arr(x))
    15 => fn_type([arr(x), callback2(x, x, tc(SYM_INT))], tc(SYM_UNIT))
    16 => fn_type([arr(x), y, callback2(y, x, y)], y)
    17 => fn_type([iter(x)], arr(x))
    18 =>
      fn_type([tc(SYM_STRING), tc(SYM_STRING_VIEW)], opt(tc(SYM_STRING_VIEW)))
    19 => fn_type([opt(x), y, callback1(x, y)], y)
    20 => fn_type([arr(x), arr(y)], arr(tuple2(x, y)))
    21 =>
      fn_type([tc(SYM_STRING), tc(SYM_STRING_VIEW)], iter(tc(SYM_STRING_VIEW)))
    22 => fn_type([res(x, y)], opt(x))
    _ => fn_type([arr(x)], opt(x))
  }
}

///|
fn wildcard_return_query(seed : Int) -> @gpi.Pattern[Int, Int] {
  match query_signature(seed) {
    @gpi.Node(symbol, children) =>
      if symbol == SYM_FN && children.length() > 0 {
        let next = children.copy()
        next.set(children.length() - 1, tv(99))
        @gpi.Node(symbol, next)
      } else {
        tv(99)
      }
    @gpi.Var(_) => tv(99)
  }
}

///|
fn core_signatures(n : Int) -> Array[@gpi.Pattern[Int, Int]] {
  Array::makei(n, core_signature)
}

///|
fn core_queries(n : Int) -> Array[@gpi.Pattern[Int, Int]] {
  Array::makei(n, query_signature)
}

///|
fn wildcard_return_queries(n : Int) -> Array[@gpi.Pattern[Int, Int]] {
  Array::makei(n, wildcard_return_query)
}

///|
fn bench_profile() -> @gpi.RetrievalProfile[
  @gpi.Pattern[Int, Int],
  @gpi.Key[Int],
  Int,
] {
  {
    normalize_query: @gpi.identity_normalize,
    normalize_candidate: @gpi.identity_normalize,
    traverse: @gpi.preorder,
    key: @gpi.default_key,
    matches: (_, _) => true,
    rank: (_, candidates) => candidates,
  }
}

///|
fn bench_filtering_profile() -> @gpi.RetrievalProfile[
  @gpi.Pattern[Int, Int],
  @gpi.Key[Int],
  Int,
] {
  {
    normalize_query: @gpi.identity_normalize,
    normalize_candidate: @gpi.identity_normalize,
    traverse: @gpi.preorder,
    key: @gpi.default_key,
    matches: (_, candidate) => candidate % 3 != 0,
    rank: (_, candidates) => {
      candidates.sort()
      candidates
    },
  }
}

///|
fn bench_standard_tree(
  signatures : Array[@gpi.Pattern[Int, Int]],
) -> @gpi.StandardDiscrTree[Int, Int] {
  let profile = bench_profile()
  let tree = @gpi.StandardDiscrTree::new()
  for i in 0..<signatures.length() {
    tree.insert(profile.candidate_keys(signatures[i]), i)
  }
  tree
}

///|
fn bench_standard_index(
  signatures : Array[@gpi.Pattern[Int, Int]],
  profile : @gpi.RetrievalProfile[@gpi.Pattern[Int, Int], @gpi.Key[Int], Int],
) -> @gpi.RetrievalIndex[
  @gpi.StandardDiscrTree[Int, Int],
  @gpi.Pattern[Int, Int],
  @gpi.Key[Int],
  Int,
] {
  let index = @gpi.standard_index(profile)
  for i in 0..<signatures.length() {
    index.insert(signatures[i], i)
  }
  index
}

///|
fn bench_lazy_index(
  signatures : Array[@gpi.Pattern[Int, Int]],
) -> @gpi.RetrievalIndex[
  @gpi.LazyDiscrTree[Int, Int],
  @gpi.Pattern[Int, Int],
  @gpi.Key[Int],
  Int,
] {
  let index = @gpi.lazy_index(bench_profile())
  for i in 0..<signatures.length() {
    index.insert(signatures[i], i)
  }
  index
}

///|
test "bench core signatures query_keys preorder n=4096" (it : @bench.T) {
  let profile = bench_profile()
  let signatures = core_signatures(BENCH_SIZE)
  it.bench(() => {
    let mut total = 0
    for signature in signatures {
      total += profile.query_keys(signature).length()
    }
    it.keep(total)
  })
}

///|
test "bench core signatures StandardDiscrTree::insert build n=4096" (
  it : @bench.T,
) {
  let profile = bench_profile()
  let signatures = core_signatures(BENCH_SIZE)
  it.bench(
    () => {
      let tree = @gpi.StandardDiscrTree::new()
      for i in 0..<signatures.length() {
        tree.insert(profile.candidate_keys(signatures[i]), i)
      }
      it.keep(tree.all().length())
    },
    count=5,
  )
}

///|
test "bench core signatures StandardDiscrTree::retrieve concrete q=256 n=4096" (
  it : @bench.T,
) {
  let profile = bench_profile()
  let tree = bench_standard_tree(core_signatures(BENCH_SIZE))
  let queries = core_queries(BENCH_QUERY_COUNT).map(query => {
    profile.query_keys(query)
  })
  it.bench(() => {
    let mut total = 0
    for query in queries {
      total += tree.retrieve(query).length()
    }
    it.keep(total)
  })
}

///|
test "bench core signatures StandardDiscrTree::retrieve wildcard-return q=256 n=4096" (
  it : @bench.T,
) {
  let profile = bench_profile()
  let tree = bench_standard_tree(core_signatures(BENCH_SIZE))
  let queries = wildcard_return_queries(BENCH_QUERY_COUNT).map(query => {
    profile.query_keys(query)
  })
  it.bench(() => {
    let mut total = 0
    for query in queries {
      total += tree.retrieve(query).length()
    }
    it.keep(total)
  })
}

///|
test "bench core signatures RetrievalIndex::retrieve concrete q=256 n=4096" (
  it : @bench.T,
) {
  let index = bench_standard_index(core_signatures(BENCH_SIZE), bench_profile())
  let queries = core_queries(BENCH_QUERY_COUNT)
  it.bench(() => {
    let mut total = 0
    for query in queries {
      total += index.retrieve(query).length()
    }
    it.keep(total)
  })
}

///|
test "bench core signatures RetrievalIndex::retrieve wildcard-return with rank q=256 n=4096" (
  it : @bench.T,
) {
  let index = bench_standard_index(
    core_signatures(BENCH_SIZE),
    bench_filtering_profile(),
  )
  let queries = wildcard_return_queries(BENCH_QUERY_COUNT)
  it.bench(() => {
    let mut total = 0
    for query in queries {
      total += index.retrieve(query).length()
    }
    it.keep(total)
  })
}

///|
test "bench core signatures LazyDiscrTree::retrieve warmed concrete q=256 n=4096" (
  it : @bench.T,
) {
  let index = bench_lazy_index(core_signatures(BENCH_SIZE))
  ignore(index.retrieve(tv(99)))
  let queries = core_queries(BENCH_QUERY_COUNT)
  it.bench(() => {
    let mut total = 0
    for query in queries {
      total += index.retrieve(query).length()
    }
    it.keep(total)
  })
}

///|
test "bench core signatures StandardDiscrTree::build_remove n=4096 remove=256" (
  it : @bench.T,
) {
  let profile = bench_profile()
  let signatures = core_signatures(BENCH_SIZE)
  let keys = signatures.map(signature => profile.candidate_keys(signature))
  it.bench(
    () => {
      let tree = @gpi.StandardDiscrTree::new()
      for i in 0..<keys.length() {
        tree.insert(keys[i], i)
      }
      for i in 0..<BENCH_REMOVE_COUNT {
        tree.remove(keys[i], i)
      }
      it.keep(tree.all().length())
    },
    count=5,
  )
}
