///|
fn type_profile() -> RetrievalProfile[
  Pattern[String, String],
  Key[String],
  String,
] {
  {
    normalize_query: identity_normalize,
    normalize_candidate: identity_normalize,
    traverse: pattern => pattern.preorder(),
    key: default_key,
    matches: (_, _) => true,
    rank: (_, candidates) => candidates,
  }
}

///|
fn arrow(
  left : Pattern[String, String],
  right : Pattern[String, String],
) -> Pattern[String, String] {
  Pattern::node("Arrow", [left, right])
}

///|
test "standard discrimination tree retrieves exact and wildcard candidates" {
  let index = standard_index(type_profile())
  index
  ..insert(arrow(Pattern::variable("a"), Pattern::variable("a")), "id")
  .insert(arrow(Pattern::leaf("Int"), Pattern::leaf("Bool")), "int_bool")
  let result = index.retrieve(arrow(Pattern::leaf("Int"), Pattern::leaf("Int")))
  debug_inspect(result, content="[\"id\"]")
}

///|
test "standard discrimination tree removes exact candidate path" {
  let index = standard_index(type_profile())
  let id_type = arrow(Pattern::variable("a"), Pattern::variable("a"))
  index..insert(id_type, "id").remove(id_type, "id")
  let result = index.retrieve(arrow(Pattern::leaf("Int"), Pattern::leaf("Int")))
  debug_inspect(result, content="[]")
}

///|
test "lazy discrimination tree materializes demanded root" {
  let index = lazy_index(type_profile())
  index
  ..insert(arrow(Pattern::variable("a"), Pattern::variable("a")), "id")
  .insert(Pattern::leaf("String"), "string")
  let result = index.retrieve(arrow(Pattern::leaf("Int"), Pattern::leaf("Int")))
  debug_inspect(result, content="[\"id\"]")
}

///|
test "query wildcard retrieves concrete candidates" {
  let index = standard_index(type_profile())
  index.insert(arrow(Pattern::leaf("Int"), Pattern::leaf("Bool")), "int_bool")
  let result = index.retrieve(
    arrow(Pattern::variable("a"), Pattern::leaf("Bool")),
  )
  debug_inspect(result, content="[\"int_bool\"]")
}

///|
test "lazy wildcard root materializes all roots" {
  let index = lazy_index(type_profile())
  index
  ..insert(Pattern::leaf("String"), "string")
  .insert(Pattern::leaf("Int"), "int")
  let result = index.retrieve(Pattern::variable("a"))
  result.sort()
  debug_inspect(result, content="[\"int\", \"string\"]")
}

///|
test "lazy discrimination tree removes pending candidates" {
  let index = lazy_index(type_profile())
  let pattern = Pattern::leaf("String")
  index..insert(pattern, "string").remove(pattern, "string")
  debug_inspect(index.retrieve(pattern), content="[]")
}

///|
test "lazy discrimination tree handles empty key paths eagerly" {
  let tree : LazyDiscrTree[String, String] = LazyDiscrTree::new()
  tree.insert([], "empty")
  debug_inspect(tree.retrieve([]), content="[\"empty\"]")
}

///|
test "profile matcher filters potential candidates" {
  let profile : RetrievalProfile[Pattern[String, String], Key[String], String] = {
    normalize_query: identity_normalize,
    normalize_candidate: identity_normalize,
    traverse: pattern => pattern.preorder(),
    key: default_key,
    matches: (_, candidate) => candidate == "id",
    rank: (_, candidates) => candidates,
  }
  let index = standard_index(profile)
  index
  ..insert(arrow(Pattern::variable("a"), Pattern::variable("a")), "id")
  .insert(arrow(Pattern::variable("a"), Pattern::leaf("Bool")), "to_bool")
  let result = index.retrieve(arrow(Pattern::leaf("Int"), Pattern::leaf("Int")))
  debug_inspect(result, content="[\"id\"]")
}
