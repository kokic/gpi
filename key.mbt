///|
/// Backend key used by the built-in discrimination tree backends.
///
/// `Star` is a wildcard edge. By default, pattern variables become `Star`,
/// so retrieval returns potential candidates while semantic checking remains
/// in the caller-provided matcher.
pub(all) enum Key[Symbol] {
  Symbol(Symbol)
  Star
} derive(Eq, Hash, Debug)

///|
pub fn[Symbol] symbol_key(symbol : Symbol) -> Key[Symbol] {
  Symbol(symbol)
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
    Node(symbol, _) => Some(Symbol(symbol))
    Var(_) => Some(Star)
  }
}

///|
pub fn[Symbol, Variable] constructor_only_key(
  node : Pattern[Symbol, Variable],
) -> Key[Symbol]? {
  match node {
    Node(symbol, _) => Some(Symbol(symbol))
    Var(_) => None
  }
}
