# GPI Benchmarks

Run from the repository root:

```sh
moon bench --target native --release --package kokic/gpi/benchmarks
```

The benchmark corpus is based on signatures queried from MoonBit core with
`moon ide doc`, including:

- `Array::*`
- `String::*`
- `Option::*`
- `Result::*`
- `Map::*`
- `Iter::*`

The benchmark does not parse these signatures at runtime. It encodes their type
shapes as GPI patterns so the measured work stays focused on indexing and
retrieval. The fixture includes function types, generic variables, callbacks,
arrays, views, options, results, iterators, tuples, maps, strings, and primitive
types.

Covered operations:

- `query_keys`: normalize, traversal, and key generation.
- `StandardDiscrTree::insert`: building from realistic signature paths.
- `StandardDiscrTree::retrieve concrete`: backend lookup for Hoogle-like
  concrete type queries.
- `StandardDiscrTree::retrieve wildcard-return`: backend lookup where the query
  leaves the return type open.
- `RetrievalIndex::retrieve concrete`: full pipeline overhead over the backend.
- `RetrievalIndex::retrieve wildcard-return with rank`: retrieval plus matcher
  filtering and ranking.
- `LazyDiscrTree::retrieve warmed concrete`: lazy backend after materializing
  root buckets.
- `StandardDiscrTree::build_remove`: build plus removal workload.

Use timings comparatively. Re-run baseline and changed versions back-to-back on
the same machine before drawing conclusions.
