///|
pub(all) enum DotRankDir {
  TopBottom
  LeftRight
  BottomTop
  RightLeft
} derive(Eq, Debug)

///|
pub(all) struct DotOptions[Symbol, Candidate] {
  graph_name : String
  rankdir : DotRankDir
  key_label : (Key[Symbol]) -> String
  candidate_label : (Candidate) -> String
}

///|
pub fn[Symbol, Candidate] DotOptions::new(
  key_label~ : (Key[Symbol]) -> String,
  candidate_label~ : (Candidate) -> String,
  graph_name? : String = "StandardDiscrTree",
  rankdir? : DotRankDir = DotRankDir::LeftRight,
) -> DotOptions[Symbol, Candidate] {
  { graph_name, rankdir, key_label, candidate_label }
}

///|
pub fn[Symbol, Candidate] StandardDiscrTree::to_dot(
  self : StandardDiscrTree[Symbol, Candidate],
  options : DotOptions[Symbol, Candidate],
) -> String {
  let writer = DotWriter::new(options)
  writer.begin_graph()
  ignore(self.root.write_dot(writer))
  writer.end_graph()
  writer.finish()
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
fn DotRankDir::to_dot(self : DotRankDir) -> String {
  match self {
    TopBottom => "TB"
    LeftRight => "LR"
    BottomTop => "BT"
    RightLeft => "RL"
  }
}

///|
priv struct DotWriter[Symbol, Candidate] {
  builder : StringBuilder
  mut next_id : Int
  options : DotOptions[Symbol, Candidate]
}

///|
fn[Symbol, Candidate] DotWriter::new(
  options : DotOptions[Symbol, Candidate],
) -> DotWriter[Symbol, Candidate] {
  { builder: StringBuilder::new(), next_id: 0, options }
}

///|
fn[Symbol, Candidate] DotWriter::begin_graph(
  self : DotWriter[Symbol, Candidate],
) -> Unit {
  self.builder
  ..write_string("digraph ")
  ..write_string(dot_quote(self.options.graph_name))
  .write_string(" {\n")
  self.builder
  ..write_string("  rankdir=")
  ..write_string(self.options.rankdir.to_dot())
  .write_string(";\n")
}

///|
fn[Symbol, Candidate] DotWriter::end_graph(
  self : DotWriter[Symbol, Candidate],
) -> Unit {
  self.builder.write_string("}\n")
}

///|
fn[Symbol, Candidate] DotWriter::finish(
  self : DotWriter[Symbol, Candidate],
) -> String {
  self.builder.to_string()
}

///|
fn[Symbol, Candidate] DotWriter::node_id(
  self : DotWriter[Symbol, Candidate],
) -> Int {
  let id = self.next_id
  self.next_id += 1
  id
}

///|
fn[Symbol, Candidate] DotWriter::write_node(
  self : DotWriter[Symbol, Candidate],
  node_id : Int,
  label : String,
) -> Unit {
  self.builder
  ..write_string("  n")
  ..write_string(node_id.to_string())
  ..write_string(" [label=")
  ..write_string(dot_quote(label))
  .write_string("];\n")
}

///|
fn[Symbol, Candidate] DotWriter::write_edge(
  self : DotWriter[Symbol, Candidate],
  parent_id : Int,
  child_id : Int,
  key : Key[Symbol],
) -> Unit {
  self.builder
  ..write_string("  n")
  ..write_string(parent_id.to_string())
  ..write_string(" -> n")
  ..write_string(child_id.to_string())
  ..write_string(" [label=")
  ..write_string(dot_quote((self.options.key_label)(key)))
  .write_string("];\n")
}

///|
fn[Symbol, Candidate] Trie::write_dot(
  self : Trie[Symbol, Candidate],
  writer : DotWriter[Symbol, Candidate],
) -> Int {
  let node_id = writer.node_id()
  let candidates = self.values.map(writer.options.candidate_label)
  let label = if node_id == 0 {
    guard !candidates.is_empty() else { "root" }
    "root\\nvalues: " + candidates.join(", ")
  } else if candidates.is_empty() {
    "node " + node_id.to_string()
  } else {
    "values: " + candidates.join(", ")
  }
  writer.write_node(node_id, label)
  self.children.each((key, child) => {
    let child_id = child.write_dot(writer)
    writer.write_edge(node_id, child_id, key)
  })
  node_id
}
