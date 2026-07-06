///|
fn string_key_label(key : Key[String]) -> String {
  match key {
    Symbol(symbol, arity) => symbol + "/" + arity.to_string()
    Star => "*"
  }
}

///|
fn identity_label(value : String) -> String {
  value
}

///|
test "standard discrimination tree exports graphviz dot" {
  let tree = StandardDiscrTree::new()
  tree.insert(
    [symbol_key("Root", 1), symbol_key("Quote\"Slash\\New\nLine", 0)],
    "candidate\"one\\two\nthree",
  )
  tree.insert([star_key()], "wildcard")
  let dot = tree.export_to_dot(
    show_key=string_key_label,
    show_candidate=identity_label,
  )
  assert_true(dot.contains("digraph StandardDiscrTree"))
  assert_true(dot.contains("rankdir=LR"))
  assert_true(dot.contains("root"))
  assert_true(dot.contains("Root/1"))
  assert_true(dot.contains("*"))
  assert_true(dot.contains("Quote\\\"Slash\\\\New\\nLine/0"))
  assert_true(dot.contains("candidate\\\"one\\\\two\\nthree"))
  assert_true(dot.contains("wildcard"))
}
