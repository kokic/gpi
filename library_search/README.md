# MoonBit Library Search

`kokic/gpi/library_search` is a small Hoogle-style type search layer for
MoonBit APIs.

It indexes MoonBit function signatures, retrieves candidates through GPI, then
filters them with type unification.

## Input Format

The parser accepts `moon ide doc` style function lines:

```text
pub fn[T, U] Array::map(Self[T], (T) -> U raise?) -> Self[U] raise?
pub fn[T] Array::get(Self[T], Int) -> T?
pub fn String::split(String, StringView) -> Iter[StringView]
```

It is intentionally not a full MoonBit source parser. Feed it API signature
lines from generated docs, `moon ide doc`, or another extraction step.

## Example

```mbt
let index = MbSearchIndex::new()
index.add_doc_signature(
  "pub fn[T] Array::get(Self[T], Int) -> T?"
)
let results = index.search_type("Array[String] -> Int -> Option[String]")
```

Supported type syntax includes:

- type constructors: `Array[T]`, `Result[T, E]`
- postfix option syntax: `T?`
- function types: `A -> B`, `(A, B) -> C`, `A -> (B -> C)`
- tuples: `(A, B)`
- generic variables: `T`, `U`, `R`
- `Self[T]` inside method signatures, resolved from `Array::method`
- trailing `raise` / `raise?`, ignored for now

## Current Limits

Queries containing type variables fall back to scanning all indexed candidates
after parsing. This preserves correctness while GPI lacks arity-aware wildcard
skip keys. Concrete queries still use the discrimination tree first.
