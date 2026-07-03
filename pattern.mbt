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
pub fn[Symbol, Variable] pattern_node(
  symbol : Symbol,
  children : Array[Pattern[Symbol, Variable]],
) -> Pattern[Symbol, Variable] {
  Node(symbol, children)
}

///|
pub fn[Symbol, Variable] pattern_leaf(
  symbol : Symbol,
) -> Pattern[Symbol, Variable] {
  Node(symbol, [])
}

///|
pub fn[Symbol, Variable] pattern_var(
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
  match self {
    Node(_, children) => children
    Var(_) => []
  }
}

///|
pub fn[Symbol, Variable] Pattern::root_symbol(
  self : Pattern[Symbol, Variable],
) -> Symbol? {
  match self {
    Node(symbol, _) => Some(symbol)
    Var(_) => None
  }
}
