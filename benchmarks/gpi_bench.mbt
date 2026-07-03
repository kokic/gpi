///|
const BENCH_SIZE = 4096

///|
const BENCH_QUERY_COUNT = 256

///|
const BENCH_REMOVE_COUNT = 256

///|
fn bench_left_symbol(i : Int) -> Int {
  100 + i % 64
}

///|
fn bench_right_symbol(i : Int) -> Int {
  200 + i / 64 % 64
}

///|
fn bench_arrow(
  left : @gpi.Pattern[Int, Int],
  right : @gpi.Pattern[Int, Int],
) -> @gpi.Pattern[Int, Int] {
  @gpi.pattern_node(0, [left, right])
}

///|
fn bench_pattern(i : Int) -> @gpi.Pattern[Int, Int] {
  bench_arrow(
    @gpi.pattern_leaf(bench_left_symbol(i)),
    @gpi.pattern_leaf(bench_right_symbol(i)),
  )
}

///|
fn bench_wildcard_left_pattern(i : Int) -> @gpi.Pattern[Int, Int] {
  bench_arrow(@gpi.pattern_var(0), @gpi.pattern_leaf(bench_right_symbol(i)))
}

///|
fn bench_exact_keys(i : Int) -> Array[@gpi.Key[Int]] {
  [
    @gpi.symbol_key(0),
    @gpi.symbol_key(bench_left_symbol(i)),
    @gpi.symbol_key(bench_right_symbol(i)),
  ]
}

///|
fn bench_wildcard_left_keys(i : Int) -> Array[@gpi.Key[Int]] {
  [@gpi.symbol_key(0), @gpi.star_key(), @gpi.symbol_key(bench_right_symbol(i))]
}

///|
fn bench_patterns(n : Int) -> Array[@gpi.Pattern[Int, Int]] {
  Array::makei(n, bench_pattern)
}

///|
fn bench_exact_key_set(n : Int) -> Array[Array[@gpi.Key[Int]]] {
  Array::makei(n, bench_exact_keys)
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
    matches: (_, candidate) => candidate % 2 == 0,
    rank: (_, candidates) => {
      candidates.sort()
      candidates
    },
  }
}

///|
fn bench_standard_tree(n : Int) -> @gpi.StandardDiscrTree[Int, Int] {
  let tree = @gpi.StandardDiscrTree::new()
  for i in 0..<n {
    tree.insert(bench_exact_keys(i), i)
  }
  tree
}

///|
fn bench_standard_index(
  n : Int,
  profile : @gpi.RetrievalProfile[@gpi.Pattern[Int, Int], @gpi.Key[Int], Int],
) -> @gpi.RetrievalIndex[
  @gpi.StandardDiscrTree[Int, Int],
  @gpi.Pattern[Int, Int],
  @gpi.Key[Int],
  Int,
] {
  let index = @gpi.standard_index(profile)
  for i in 0..<n {
    index.insert(bench_pattern(i), i)
  }
  index
}

///|
fn bench_lazy_index(
  n : Int,
) -> @gpi.RetrievalIndex[
  @gpi.LazyDiscrTree[Int, Int],
  @gpi.Pattern[Int, Int],
  @gpi.Key[Int],
  Int,
] {
  let index = @gpi.lazy_index(bench_profile())
  for i in 0..<n {
    index.insert(bench_pattern(i), i)
  }
  index
}

///|
test "bench profile query_keys preorder n=4096" (it : @bench.T) {
  let profile = bench_profile()
  let patterns = bench_patterns(BENCH_SIZE)
  it.bench(() => {
    let mut total = 0
    for pattern in patterns {
      total += profile.query_keys(pattern).length()
    }
    it.keep(total)
  })
}

///|
test "bench StandardDiscrTree::insert build n=4096" (it : @bench.T) {
  let keys = bench_exact_key_set(BENCH_SIZE)
  it.bench(
    () => {
      let tree = @gpi.StandardDiscrTree::new()
      for i in 0..<keys.length() {
        tree.insert(keys[i], i)
      }
      it.keep(tree.all().length())
    },
    count=5,
  )
}

///|
test "bench StandardDiscrTree::retrieve exact batch q=256 n=4096" (
  it : @bench.T,
) {
  let tree = bench_standard_tree(BENCH_SIZE)
  let queries = Array::makei(BENCH_QUERY_COUNT, bench_exact_keys)
  it.bench(() => {
    let mut total = 0
    for query in queries {
      total += tree.retrieve(query).length()
    }
    it.keep(total)
  })
}

///|
test "bench StandardDiscrTree::retrieve wildcard-left batch q=256 n=4096" (
  it : @bench.T,
) {
  let tree = bench_standard_tree(BENCH_SIZE)
  let queries = Array::makei(BENCH_QUERY_COUNT, bench_wildcard_left_keys)
  it.bench(() => {
    let mut total = 0
    for query in queries {
      total += tree.retrieve(query).length()
    }
    it.keep(total)
  })
}

///|
test "bench RetrievalIndex::retrieve exact batch q=256 n=4096" (it : @bench.T) {
  let index = bench_standard_index(BENCH_SIZE, bench_profile())
  let queries = bench_patterns(BENCH_QUERY_COUNT)
  it.bench(() => {
    let mut total = 0
    for query in queries {
      total += index.retrieve(query).length()
    }
    it.keep(total)
  })
}

///|
test "bench RetrievalIndex::retrieve wildcard-left with rank q=256 n=4096" (
  it : @bench.T,
) {
  let index = bench_standard_index(BENCH_SIZE, bench_filtering_profile())
  let queries = Array::makei(BENCH_QUERY_COUNT, bench_wildcard_left_pattern)
  it.bench(() => {
    let mut total = 0
    for query in queries {
      total += index.retrieve(query).length()
    }
    it.keep(total)
  })
}

///|
test "bench LazyDiscrTree::retrieve warmed exact batch q=256 n=4096" (
  it : @bench.T,
) {
  let index = bench_lazy_index(BENCH_SIZE)
  ignore(index.retrieve(@gpi.pattern_var(0)))
  let queries = bench_patterns(BENCH_QUERY_COUNT)
  it.bench(() => {
    let mut total = 0
    for query in queries {
      total += index.retrieve(query).length()
    }
    it.keep(total)
  })
}

///|
test "bench StandardDiscrTree::build_remove n=4096 remove=256" (it : @bench.T) {
  let keys = bench_exact_key_set(BENCH_SIZE)
  it.bench(
    () => {
      let tree = @gpi.StandardDiscrTree::new()
      keys.eachi((i, x) => tree.insert(x, i))
      for i in 0..<BENCH_REMOVE_COUNT {
        tree.remove(keys[i], i)
      }
      it.keep(tree.all().length())
    },
    count=5,
  )
}
