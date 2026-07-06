///|
/// A language-independent pattern tree.
///
/// `Symbol` is the node label type supplied by the client language.
/// `Variable` preserves variable identity for the final matcher; the index
/// layer treats variable semantics as a key-generation choice.
pub(all) enum Pattern[Symbol, Variable] {
  Node(Symbol, Array[Pattern[Symbol, Variable]])
  Var(Variable)
} derive(Eq, Hash, Debug)

///|
pub fn[Symbol, Variable] Pattern::node(
  symbol : Symbol,
  children : Array[Pattern[Symbol, Variable]],
) -> Pattern[Symbol, Variable] {
  Node(symbol, children)
}

///|
pub fn[Symbol, Variable] Pattern::leaf(
  symbol : Symbol,
) -> Pattern[Symbol, Variable] {
  Node(symbol, [])
}

///|
pub fn[Symbol, Variable] Pattern::variable(
  variable : Variable,
) -> Pattern[Symbol, Variable] {
  Var(variable)
}

///|
pub fn[Symbol, Variable] Pattern::is_variable(
  self : Pattern[Symbol, Variable],
) -> Bool {
  match self {
    Var(_) => true
    Node(_, _) => false
  }
}

///|
pub fn[Symbol, Variable] Pattern::children(
  self : Pattern[Symbol, Variable],
) -> Array[Pattern[Symbol, Variable]] {
  guard self is Node(_, children) else { [] }
  children
}

///|
pub fn[Symbol, Variable] Pattern::root_symbol(
  self : Pattern[Symbol, Variable],
) -> Symbol? {
  guard self is Node(symbol, _) else { None }
  Some(symbol)
}

///|
/// Preorder traversal used by traditional discrimination trees.
pub fn[Symbol, Variable] Pattern::preorder(
  self : Pattern[Symbol, Variable],
) -> Array[Pattern[Symbol, Variable]] {
  let out : Array[Pattern[Symbol, Variable]] = []
  self.preorder_into(out)
  out
}

///|
fn[Symbol, Variable] Pattern::preorder_into(
  self : Pattern[Symbol, Variable],
  out : Array[Pattern[Symbol, Variable]],
) -> Unit {
  out.push(self)
  if self is Node(_, children) {
    children.each(child => child.preorder_into(out))
  }
}
