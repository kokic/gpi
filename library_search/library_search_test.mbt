///|
fn sample_index() -> MbSearchIndex raise MbtSearchError {
  let index = MbSearchIndex::new()
  index.add_doc_signatures([
    "pub fn[T, U] Array::map(Self[T], (T) -> U raise?) -> Self[U] raise?", //
     "pub fn[T] Array::filter(Self[T], (T) -> Bool raise?) -> Self[T] raise?", //
     "pub fn[T] Array::get(Self[T], Int) -> T?", //
     "pub fn[A, B] Array::fold(Self[A], init~ : B, (B, A) -> B raise?) -> B raise?", //
     "pub fn[T] Array::iter(Self[T]) -> Iter[T]", //
     "pub fn[A, B] Array::zip(Self[A], Self[B]) -> Self[(A, B)]", //
     "pub fn String::split(String, StringView) -> Iter[StringView]", //
     "pub fn String::find(String, StringView) -> Int?", //
     "pub fn String::contains(String, StringView) -> Bool", //
     "pub fn String::replace(String, old~ : StringView, new~ : StringView) -> String", //
     "pub fn String::to_array(String) -> Array[Char]", //
     "pub fn String::get_char(String, Int) -> Char?", //
     "pub fn[T, U] Option::bind(T?, (T) -> U? raise?) -> U? raise?", //
     "pub fn[T, U] Option::map(T?, (T) -> U raise?) -> U? raise?", //
     "pub fn[T] Option::unwrap_or(T?, T) -> T", //
     "pub fn[T, E, U] Result::map(Self[T, E], (T) -> U) -> Self[U, E]", //
     "pub fn[T, E, F] Result::map_err(Self[T, E], (E) -> F) -> Self[T, F]", //
     "pub fn[T, E] Result::unwrap_or(Self[T, E], T) -> T", //
     "pub fn[X, Y] Iter::map(Self[X], (X) -> Y) -> Self[Y]", //
     "pub fn[X] Iter::filter(Self[X], (X) -> Bool) -> Self[X]", //
     "pub fn[X] Iter::to_array(Self[X]) -> Array[X]", //
     "pub fn[K : Hash + Eq, V] Map::get(Self[K, V], K) -> V?", //
     "pub fn[K : Hash + Eq, V] Map::set(Self[K, V], K, V) -> Unit", //
  ])
  index
}

///|
test "parse moon ide doc function signature with Self and option" {
  let c = parse_doc_signature("pub fn[T] Array::get(Self[T], Int) -> T?")
  debug_inspect(
    c.signature,
    content="Fun([App(\"Array\", [Var(\"T\")]), Con(\"Int\")], App(\"Option\", [Var(\"T\")]))",
  )
}

///|
test "parse doc signature uses declared multi-character generic names" {
  let c = parse_doc_signature(
    "pub fn[Ok, Err] Result::unwrap_or(Self[Ok, Err], Ok) -> Ok",
  )
  debug_inspect(
    c.signature,
    content="Fun([App(\"Result\", [Var(\"Ok\"), Var(\"Err\")]), Var(\"Ok\")], Var(\"Ok\"))",
  )
}

///|
test "parse doc signature does not invent undeclared generic variables" {
  let c = parse_doc_signature("pub fn Constants::default() -> T")
  debug_inspect(c.signature, content="Fun([], Con(\"T\"))")
  debug_inspect(parse_type("T"), content="Var(\"T\")")
}

///|
test "parse doc signature strips typed effect suffix from return type" {
  let c = parse_doc_signature(
    "pub fn[T, E : Error] Result::unwrap_or_error(Self[T, E]) -> T raise E",
  )
  debug_inspect(
    c.signature,
    content="Fun([App(\"Result\", [Var(\"T\"), Var(\"E\")])], Var(\"T\"))",
  )
}

///|
test "parse type does not strip raise inside constructor name" {
  debug_inspect(parse_type("Raise"), content="Con(\"Raise\")")
}

///|
test "parse type flattens right-associated arrow arguments" {
  debug_inspect(
    parse_type("(Int, String) -> Bool -> Unit"),
    content="Fun([Con(\"Int\"), Con(\"String\"), Con(\"Bool\")], Con(\"Unit\"))",
  )
}

///|
test "parse doc signature keeps path-like type before labeled annotation colon" {
  let c = parse_doc_signature(
    "pub fn Example::use_path(value : pkg::Type) -> pkg::Type",
  )
  debug_inspect(
    c.signature,
    content="Fun([Con(\"pkg::Type\")], Con(\"pkg::Type\"))",
  )
}

///|
test "parse doc signature rejects malformed generic and parameter lists" {
  ignore(
    @test.expect_error(() => parse_doc_signature("pub fn[] bad() -> Unit")),
  )
  ignore(
    @test.expect_error(() => {
      parse_doc_signature("pub fn[T Array::get(Self[T]) -> T")
    }),
  )
  ignore(
    @test.expect_error(() => {
      parse_doc_signature("pub fn f(Int,, String) -> Unit")
    }),
  )
  ignore(
    @test.expect_error(() => {
      parse_doc_signature("pub fn f((Int, String) -> Unit")
    }),
  )
}

///|
test "parse doc signature rejects extra syntax between params and return arrow" {
  ignore(
    @test.expect_error(() => parse_doc_signature("pub fn f(Int) raise -> Unit")),
  )
}

///|
test "parse type rejects malformed delimiters" {
  ignore(@test.expect_error(() => parse_type("Array[Int")))
  ignore(@test.expect_error(() => parse_type("Array[Int]]")))
}

///|
test "search exact concrete array get" {
  let index = sample_index()
  let results = index.search_type("Array[String] -> Int -> Option[String]")
  debug_inspect(results.map(r => r.candidate.name), content="[\"Array::get\"]")
}

///|
test "search higher order array map" {
  let index = sample_index()
  let results = index.search_type(
    "Array[Int] -> (Int -> String) -> Array[String]",
  )
  debug_inspect(results.map(r => r.candidate.name), content="[\"Array::map\"]")
}

///|
test "search nested generic candidate variable through index" {
  let index = sample_index()
  let results = index.search_type(
    "Array[Array[String]] -> Int -> Option[Array[String]]",
  )
  debug_inspect(results.map(r => r.candidate.name), content="[\"Array::get\"]")
}

///|
test "search query variable return" {
  let index = sample_index()
  let results = index.search_type("String -> StringView -> R")
  debug_inspect(
    results.map(r => r.candidate.name),
    content="[\"String::contains\", \"String::find\", \"String::split\"]",
  )
}

///|
test "search_doc_signatures skips non function lines" {
  let results = search_doc_signatures(
    [
      "package \"moonbitlang/core/array\"", "#alias(iterator, deprecated)", "pub fn[T] Array::iter(Self[T]) -> Iter[T]",
    ],
    "Array[Int] -> Iter[Int]",
  )
  debug_inspect(results.map(r => r.candidate.name), content="[\"Array::iter\"]")
}
