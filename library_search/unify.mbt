///|
fn occurs(name : String, t : MbType) -> Bool {
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
  subst : Map[String, MbType],
  name : String,
  target : MbType,
) -> Bool {
  match subst.get(name) {
    Some(existing) => existing == target
    None =>
      if occurs(name, target) {
        false
      } else {
        subst.set(name, target)
        true
      }
  }
}

///|
fn unify_candidate(
  candidate : MbType,
  query : MbType,
  subst : Map[String, MbType],
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
  left : Array[MbType],
  right : Array[MbType],
  subst : Map[String, MbType],
) -> Bool {
  if left.length() != right.length() {
    false
  } else {
    for i in 0..<left.length() {
      if !unify_candidate(left[i], right[i], subst) {
        return false
      }
    }
    true
  }
}

///|
pub fn matches_type(candidate : MbType, query : MbType) -> Bool {
  unify_candidate(candidate, query, Map::default())
}
