///|
struct SourceSearchResult {
  definition : @database.FunctionDefinition
  score : Int
} derive(Debug)

///|
fn search_source_definitions(
  source : String,
  query : String,
  name? : String = "",
  limit? : Int = 20,
) -> Array[SourceSearchResult] raise {
  let definitions = @database.function_definitions(source, name~)
  let definitions_by_signature : Map[String, @database.FunctionDefinition] = Map([],
  )
  let index = MbSearchIndex::new()
  for definition in definitions {
    guard definition.visibility == Public &&
      definition.signature.has_prefix("pub fn") else {
      continue
    }
    let signature = definition.signature.trim().to_owned()
    definitions_by_signature[signature] = definition
    index.add_doc_signature(signature)
  }
  index
  .search_type(query, limit~)
  .filter_map(result => {
    match definitions_by_signature.get(result.candidate.source) {
      Some(definition) => Some({ definition, score: result.score })
      None => None
    }
  })
}

///|
test "query MoonBit source for complete function definitions" {
  let source =
    #|fn local_helper() -> Unit { () }
    #|
    #|pub fn[T] Box::get(
    #|  self : Box[T],
    #|) -> T {
    #|  ...
    #|}
    #|
    #|pub fn String::size(self : String) -> Int { self.length() }
  let results = search_source_definitions(
    source,
    "Box[Int] -> Int",
    name="box.mbt",
  )
  debug_inspect(
    results.map(result => {
      let definition = result.definition
      (
        definition.name,
        definition.visibility,
        definition.signature,
        definition.source,
        definition.start,
        definition.end,
        result.score,
      )
    }),
    content=(
      #|[
      #|  (
      #|    "Box::get",
      #|    Public,
      #|    "pub fn[T] Box::get(\n  self : Box[T],\n) -> T",
      #|    "pub fn[T] Box::get(\n  self : Box[T],\n) -> T {\n  ...\n}",
      #|    { line: 3, column: 1, offset: 34 },
      #|    { line: 7, column: 2, offset: 87 },
      #|    24,
      #|  ),
      #|]
    ),
  )
}

///|
test "source search excludes non-public and unsupported function forms" {
  let source =
    #|fn default_value(value : Int) -> Int { value }
    #|priv fn hidden_value(value : Int) -> Int { value }
    #|pub async fn async_value(value : Int) -> Int { value }
    #|pub fn visible_value(value : Int) -> Int { value }
  let results = search_source_definitions(source, "Int -> Int")
  debug_inspect(
    results.map(result => result.definition.name),
    content=(
      #|["visible_value"]
    ),
  )
}

///|
test "source search respects repeated generic variables" {
  let source =
    #|pub fn[T] same(left : T, right : T) -> T { left }
    #|pub fn[A, B] first(left : A, right : B) -> A { left }
  let results = search_source_definitions(source, "Int -> String -> Int")
  debug_inspect(
    results.map(result => result.definition.name),
    content=(
      #|["first"]
    ),
  )
}

///|
test "source search ranks exact signatures before generic signatures and limits results" {
  let source =
    #|pub fn exact(value : String) -> Int { value.length() }
    #|pub fn[A, B] convert(value : A) -> B { ... }
  let results = search_source_definitions(source, "String -> Int", limit=1)
  debug_inspect(
    results.map(result => (result.definition.name, result.score)),
    content=(
      #|[("exact", 0)]
    ),
  )
}

///|
test "source search preserves database parse diagnostics" {
  let error = try
    search_source_definitions(
      "pub fn broken(",
      "Unit -> Unit",
      name="broken.mbt",
    )
  catch {
    error => error
  } noraise {
    _ => fail("expected source parse error")
  }
  guard error is @database.ParseFailed(diagnostics) else {
    fail("unexpected error")
  }
  debug_inspect(
    diagnostics.map(diagnostic => {
      (diagnostic.message, diagnostic.start, diagnostic.end)
    }),
    content=(
      #|[
      #|  (
      #|    "Unexpected end of file, missing parameter name or label here.",
      #|    { line: 1, column: 15, offset: 14 },
      #|    { line: 1, column: 15, offset: 14 },
      #|  ),
      #|]
    ),
  )
}
