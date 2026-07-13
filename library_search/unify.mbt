///|
fn occurs(name : String, t : MbtType) -> Bool {
  match t {
    Var(v) => v == name
    Con(_) => false
    App(_, args) => args.any(arg => occurs(name, arg))
    Fun(args, return_type) =>
      occurs(name, return_type) || args.any(arg => occurs(name, arg))
    Tuple(items) => items.any(item => occurs(name, item))
  }
}

///|
fn bind_var(
  subst : Map[String, MbtType],
  name : String,
  target : MbtType,
) -> Bool {
  match subst.get(name) {
    Some(existing) => existing == target
    None => {
      guard !occurs(name, target) else { false }
      subst.set(name, target)
      true
    }
  }
}

///|
fn unify_candidate(
  candidate : MbtType,
  query : MbtType,
  subst : Map[String, MbtType],
) -> Bool {
  match candidate {
    Var(name) => bind_var(subst, name, query)
    Con(name) =>
      match query {
        Con(other) => name == other
        Var(_) => true
        _ => false
      }
    App(name, args) =>
      match query {
        App(other, other_args) =>
          name == other && unify_arrays(args, other_args, subst)
        Var(_) => true
        _ => false
      }
    Fun(args, return_type) =>
      match query {
        Fun(other_args, other_return) =>
          unify_arrays(args, other_args, subst) &&
          unify_candidate(return_type, other_return, subst)
        Var(_) => true
        _ => false
      }
    Tuple(items) =>
      match query {
        Tuple(other_items) => unify_arrays(items, other_items, subst)
        Var(_) => true
        _ => false
      }
  }
}

///|
fn unify_arrays(
  left : Array[MbtType],
  right : Array[MbtType],
  subst : Map[String, MbtType],
) -> Bool {
  guard left.length() == right.length() else { false }
  for i in 0..<left.length() {
    guard unify_candidate(left[i], right[i], subst) else { return false }
  }
  true
}

///|
pub fn matches_type(candidate : MbtType, query : MbtType) -> Bool {
  unify_candidate(candidate, query, Map::default())
}
