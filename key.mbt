///|
/// Backend key used by the built-in discrimination tree backends.
///
/// `Symbol(symbol, arity)` stores the constructor and child count, allowing
/// retrieval to skip complete subtrees for wildcard matches. `Star` matches
/// one complete subtree. Semantic constraints still live in the caller-provided
/// matcher.
pub(all) enum Key[Symbol] {
  Symbol(Symbol, Int)
  Star
} derive(Eq, Hash, Debug)

///|
pub fn[Symbol] symbol_key(symbol : Symbol, arity : Int) -> Key[Symbol] {
  Symbol(symbol, arity)
}

///|
pub fn[Symbol] leaf_key(symbol : Symbol) -> Key[Symbol] {
  Symbol(symbol, 0)
}

///|
pub fn[Symbol] star_key() -> Key[Symbol] {
  Star
}

///|
pub fn[Symbol, Variable] default_key(
  node : Pattern[Symbol, Variable],
) -> Key[Symbol]? {
  match node {
    Node(symbol, children) => Some(Symbol(symbol, children.length()))
    Var(_) => Some(Star)
  }
}

///|
pub fn[Symbol, Variable] constructor_only_key(
  node : Pattern[Symbol, Variable],
) -> Key[Symbol]? {
  match node {
    Node(symbol, children) => Some(Symbol(symbol, children.length()))
    Var(_) => None
  }
}

///|
fn[Symbol] Key::subtree_arity(self : Key[Symbol]) -> Int {
  match self {
    Symbol(_, arity) => arity
    Star => 0
  }
}
