///|
fn type_profile() -> RetrievalProfile[
  Pattern[String, String],
  Key[String],
  String,
] {
  {
    normalize_query: identity_normalize,
    normalize_candidate: identity_normalize,
    traverse: preorder,
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
  pattern_node("Arrow", [left, right])
}

///|
test "standard discrimination tree retrieves exact and wildcard candidates" {
  let index = standard_index(type_profile())
  index
  ..insert(arrow(pattern_var("a"), pattern_var("a")), "id")
  .insert(arrow(pattern_leaf("Int"), pattern_leaf("Bool")), "int_bool")
  let result = index.retrieve(arrow(pattern_leaf("Int"), pattern_leaf("Int")))
  debug_inspect(result, content="[\"id\"]")
}

///|
test "standard discrimination tree removes exact candidate path" {
  let index = standard_index(type_profile())
  let id_type = arrow(pattern_var("a"), pattern_var("a"))
  index..insert(id_type, "id").remove(id_type, "id")
  let result = index.retrieve(arrow(pattern_leaf("Int"), pattern_leaf("Int")))
  debug_inspect(result, content="[]")
}

///|
test "lazy discrimination tree materializes demanded root" {
  let index = lazy_index(type_profile())
  index
  ..insert(arrow(pattern_var("a"), pattern_var("a")), "id")
  .insert(pattern_leaf("String"), "string")
  let result = index.retrieve(arrow(pattern_leaf("Int"), pattern_leaf("Int")))
  debug_inspect(result, content="[\"id\"]")
}

///|
test "query wildcard retrieves concrete candidates" {
  let index = standard_index(type_profile())
  index.insert(arrow(pattern_leaf("Int"), pattern_leaf("Bool")), "int_bool")
  let result = index.retrieve(arrow(pattern_var("a"), pattern_leaf("Bool")))
  debug_inspect(result, content="[\"int_bool\"]")
}

///|
test "lazy wildcard root materializes all roots" {
  let index = lazy_index(type_profile())
  index
  ..insert(pattern_leaf("String"), "string")
  .insert(pattern_leaf("Int"), "int")
  let result = index.retrieve(pattern_var("a"))
  result.sort()
  debug_inspect(result, content="[\"int\", \"string\"]")
}

///|
test "profile matcher filters potential candidates" {
  let profile : RetrievalProfile[Pattern[String, String], Key[String], String] = {
    normalize_query: identity_normalize,
    normalize_candidate: identity_normalize,
    traverse: preorder,
    key: default_key,
    matches: (_, candidate) => candidate == "id",
    rank: (_, candidates) => candidates,
  }
  let index = standard_index(profile)
  index
  ..insert(arrow(pattern_var("a"), pattern_var("a")), "id")
  .insert(arrow(pattern_var("a"), pattern_leaf("Bool")), "to_bool")
  let result = index.retrieve(arrow(pattern_leaf("Int"), pattern_leaf("Int")))
  debug_inspect(result, content="[\"id\"]")
}
