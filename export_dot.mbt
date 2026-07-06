///|
pub fn[Symbol, Candidate] StandardDiscrTree::export_to_dot(
  self : StandardDiscrTree[Symbol, Candidate],
  show_key~ : (Key[Symbol]) -> String,
  show_candidate~ : (Candidate) -> String,
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("digraph StandardDiscrTree {\n")
  builder.write_string("  rankdir=LR;\n")
  ignore(self.root.write_dot(builder, 0, show_key, show_candidate))
  builder.write_string("}\n")
  builder.to_string()
}

///|
fn dot_escape(input : String) -> String {
  let builder = StringBuilder::new(size_hint=input.length())
  for char in input {
    match char {
      '\\' => builder <+ "\\\\"
      '"' => builder <+ "\\\""
      '\n' => builder <+ "\\n"
      '\r' => builder <+ "\\r"
      _ => builder.write_char(char)
    }
  }
  builder.to_string()
}

///|
fn dot_quote(input : String) -> String {
  "\"" + dot_escape(input) + "\""
}

///|
fn[Symbol, Candidate] Trie::write_dot(
  self : Trie[Symbol, Candidate],
  builder : StringBuilder,
  next_id : Int,
  show_key : (Key[Symbol]) -> String,
  show_candidate : (Candidate) -> String,
) -> Int {
  let node_id = next_id
  let mut next = next_id + 1
  let candidates = self.values.map(show_candidate)
  let label = if node_id == 0 {
    guard !candidates.is_empty() else { "root" }
    "root\\nvalues: " + candidates.join(", ")
  } else if candidates.is_empty() {
    "node " + node_id.to_string()
  } else {
    "values: " + candidates.join(", ")
  }
  builder
  ..write_string("  n")
  ..write_string(node_id.to_string())
  ..write_string(" [label=")
  ..write_string(dot_quote(label))
  .write_string("];\n")
  self.children.each((key, child) => {
    let child_id = next
    next = child.write_dot(builder, next, show_key, show_candidate)
    builder
    ..write_string("  n")
    ..write_string(node_id.to_string())
    ..write_string(" -> n")
    ..write_string(child_id.to_string())
    ..write_string(" [label=")
    ..write_string(dot_quote(show_key(key)))
    .write_string("];\n")
  })
  next
}
