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
  let dot = tree.to_dot(
    DotOptions::new(key_label=string_key_label, candidate_label=identity_label),
  )
  assert_true(dot.contains("digraph \"StandardDiscrTree\""))
  assert_true(dot.contains("rankdir=LR"))
  assert_true(dot.contains("root"))
  assert_true(dot.contains("Root/1"))
  assert_true(dot.contains("*"))
  assert_true(dot.contains("Quote\\\"Slash\\\\New\\nLine/0"))
  assert_true(dot.contains("candidate\\\"one\\\\two\\nthree"))
  assert_true(dot.contains("wildcard"))
}

///|
test "dot export options control graph header" {
  let tree = StandardDiscrTree::new()
  tree.insert([symbol_key("Root", 0)], "candidate")
  let dot = tree.to_dot(
    DotOptions::new(
      key_label=string_key_label,
      candidate_label=identity_label,
      graph_name="quoted\"graph",
      rankdir=DotRankDir::BottomTop,
    ),
  )
  assert_true(dot.contains("digraph \"quoted\\\"graph\""))
  assert_true(dot.contains("rankdir=BT"))
}
