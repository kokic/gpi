///|
struct Trie[Symbol, Candidate] {
  values : Array[Candidate]
  children : Map[Key[Symbol], Trie[Symbol, Candidate]]
}

///|
fn[Symbol, Candidate] Trie::empty() -> Trie[Symbol, Candidate] {
  { values: [], children: Map::default() }
}

///|
fn[Symbol : Eq + Hash, Candidate : Eq] Trie::insert(
  self : Trie[Symbol, Candidate],
  keys : Array[Key[Symbol]],
  index : Int,
  candidate : Candidate,
) -> Trie[Symbol, Candidate] {
  if index >= keys.length() {
    let next_values = self.values.copy()
    if !next_values.contains(candidate) {
      next_values.push(candidate)
    }
    Trie::{ values: next_values, children: self.children.copy() }
  } else {
    let key = keys[index]
    let child = self.children.get(key).unwrap_or_else(() => Trie::empty())
    let next_child = child.insert(keys, index + 1, candidate)
    let next_children = self.children.copy()
    next_children.set(key, next_child)
    Trie::{ values: self.values.copy(), children: next_children }
  }
}

///|
fn[Symbol : Eq + Hash, Candidate : Eq] Trie::remove(
  self : Trie[Symbol, Candidate],
  keys : Array[Key[Symbol]],
  index : Int,
  candidate : Candidate,
) -> Trie[Symbol, Candidate] {
  if index >= keys.length() {
    Trie::{
      values: self.values.filter(value => value != candidate),
      children: self.children.copy(),
    }
  } else {
    let key = keys[index]
    match self.children.get(key) {
      Some(child) => {
        let next_child = child.remove(keys, index + 1, candidate)
        let next_children = self.children.copy()
        next_children.set(key, next_child)
        { values: self.values.copy(), children: next_children }
      }
      None => { values: self.values.copy(), children: self.children.copy() }
    }
  }
}

///|
fn[Symbol : Eq + Hash, Candidate] Trie::retrieve_match(
  self : Trie[Symbol, Candidate],
  keys : Array[Key[Symbol]],
  index : Int,
  output : Array[Candidate],
) -> Unit {
  if index >= keys.length() {
    output.append(self.values)
  } else {
    let key = keys[index]
    if key is Star {
      self.children.each((child_key, child) => {
        child.retrieve_after_candidate_subtree(
          pending=child_key.subtree_arity(),
          keys,
          index + 1,
          output,
        )
      })
    } else {
      if self.children.get(Star) is Some(child) {
        child.retrieve_match(keys, skip_query_subtree(keys, index), output)
      }
      if self.children.get(key) is Some(child) {
        child.retrieve_match(keys, index + 1, output)
      }
    }
  }
}

///|
fn[Symbol : Eq + Hash, Candidate] Trie::retrieve_after_candidate_subtree(
  self : Trie[Symbol, Candidate],
  pending~ : Int,
  keys : Array[Key[Symbol]],
  index : Int,
  output : Array[Candidate],
) -> Unit {
  guard pending != 0 else { self.retrieve_match(keys, index, output) }
  self.children.each((key, child) => {
    child.retrieve_after_candidate_subtree(
      pending=pending - 1 + key.subtree_arity(),
      keys,
      index,
      output,
    )
  })
}

///|
fn[Symbol] skip_query_subtree(keys : Array[Key[Symbol]], index : Int) -> Int {
  let mut pending = 1
  let mut next = index
  while pending > 0 && next < keys.length() {
    pending = pending - 1 + keys[next].subtree_arity()
    next += 1
  }
  next
}

///|
fn[Symbol, Candidate] Trie::collect_all(
  self : Trie[Symbol, Candidate],
  output : Array[Candidate],
) -> Unit {
  output.append(self.values)
  self.children.each((_, child) => child.collect_all(output))
}

///|
pub struct StandardDiscrTree[Symbol, Candidate] {
  mut root : Trie[Symbol, Candidate]
}

///|
pub fn[Symbol, Candidate] StandardDiscrTree::new() -> StandardDiscrTree[
  Symbol,
  Candidate,
] {
  { root: Trie::empty() }
}

///|
pub fn[Symbol : Eq + Hash, Candidate : Eq] StandardDiscrTree::insert(
  self : StandardDiscrTree[Symbol, Candidate],
  keys : Array[Key[Symbol]],
  candidate : Candidate,
) -> Unit {
  self.root = self.root.insert(keys, 0, candidate)
}

///|
pub fn[Symbol : Eq + Hash, Candidate : Eq] StandardDiscrTree::remove(
  self : StandardDiscrTree[Symbol, Candidate],
  keys : Array[Key[Symbol]],
  candidate : Candidate,
) -> Unit {
  self.root = self.root.remove(keys, 0, candidate)
}

///|
pub fn[Symbol : Eq + Hash, Candidate] StandardDiscrTree::retrieve(
  self : StandardDiscrTree[Symbol, Candidate],
  keys : Array[Key[Symbol]],
) -> Array[Candidate] {
  let output : Array[Candidate] = []
  self.root.retrieve_match(keys, 0, output)
  output
}

///|
pub fn[Symbol, Candidate] StandardDiscrTree::all(
  self : StandardDiscrTree[Symbol, Candidate],
) -> Array[Candidate] {
  let output : Array[Candidate] = []
  self.root.collect_all(output)
  output
}

///|
pub fn[Symbol, Candidate] StandardDiscrTree::clear(
  self : StandardDiscrTree[Symbol, Candidate],
) -> Unit {
  self.root = Trie::empty()
}

///|
pub fn[Symbol : Eq + Hash, Candidate : Eq] standard_backend_ops() -> BackendOps[
  StandardDiscrTree[Symbol, Candidate],
  Key[Symbol],
  Candidate,
] {
  BackendOps::{
    insert: (backend, keys, candidate) => backend.insert(keys, candidate),
    remove: (backend, keys, candidate) => backend.remove(keys, candidate),
    retrieve: (backend, keys) => backend.retrieve(keys),
    clear: backend => backend.clear(),
  }
}

///|
pub fn[Symbol : Eq + Hash, Pattern, Candidate : Eq] standard_index(
  profile : RetrievalProfile[Pattern, Key[Symbol], Candidate],
) -> RetrievalIndex[
  StandardDiscrTree[Symbol, Candidate],
  Pattern,
  Key[Symbol],
  Candidate,
] {
  RetrievalIndex::{
    backend: StandardDiscrTree::new(),
    backend_ops: standard_backend_ops(),
    profile,
  }
}
