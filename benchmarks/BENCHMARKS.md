# GPI Benchmarks

Run the benchmark suite with:

```sh
moon bench --target native --release
```

The benchmark module is `gpi_bench_test.mbt`. It uses a fixed synthetic type-like
pattern shape:

```text
Arrow(left, right)
```

with integer symbols and integer candidates, so the results primarily measure
the retrieval framework rather than string hashing or language-specific
matching.

## Covered Operations

- `profile query_keys preorder`: normalize + traversal + key generation.
- `StandardDiscrTree::insert build`: building a trie from key sequences.
- `StandardDiscrTree::retrieve exact`: direct backend lookup for exact keys.
- `StandardDiscrTree::retrieve wildcard-left`: backend lookup where query
  wildcard expands over many child branches.
- `RetrievalIndex::retrieve exact`: full pipeline retrieval overhead above the
  backend.
- `RetrievalIndex::retrieve wildcard-left with rank`: full pipeline retrieval
  including matcher filtering and ranking.
- `LazyDiscrTree::retrieve warmed exact`: lazy backend after all root buckets
  have already been materialized.
- `StandardDiscrTree::build_remove`: build cost plus removal workload.

Use these numbers comparatively, not as absolute truth. For optimization work,
run baseline and changed versions back-to-back on the same machine.
