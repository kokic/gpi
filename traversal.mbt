///|
/// Preorder traversal used by traditional discrimination trees.
pub fn[Symbol, Variable] preorder(
  pattern : Pattern[Symbol, Variable],
) -> Array[Pattern[Symbol, Variable]] {
  let out : Array[Pattern[Symbol, Variable]] = []
  preorder_into(pattern, out)
  out
}

///|
fn[Symbol, Variable] preorder_into(
  pattern : Pattern[Symbol, Variable],
  out : Array[Pattern[Symbol, Variable]],
) -> Unit {
  out.push(pattern)
  match pattern {
    Node(_, children) => children.each(child => preorder_into(child, out))
    Var(_) => ()
  }
}

///|
pub fn[Symbol, Variable] identity_normalize(
  pattern : Pattern[Symbol, Variable],
) -> Pattern[Symbol, Variable] {
  pattern
}
