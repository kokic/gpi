///|
pub struct LazyDiscrTree[Symbol, Candidate] {
  eager : StandardDiscrTree[Symbol, Candidate]
  pending : Map[Key[Symbol], Array[(Array[Key[Symbol]], Candidate)]]
}

///|
pub fn[Symbol, Candidate] LazyDiscrTree::new() -> LazyDiscrTree[
  Symbol,
  Candidate,
] {
  { eager: StandardDiscrTree::new(), pending: Map::default() }
}

///|
pub fn[Symbol : Eq + Hash, Candidate : Eq] LazyDiscrTree::insert(
  self : LazyDiscrTree[Symbol, Candidate],
  keys : Array[Key[Symbol]],
  candidate : Candidate,
) -> Unit {
  match keys {
    [root, ..] => {
      let bucket = self.pending.get(root).unwrap_or([])
      bucket.push((keys, candidate))
      self.pending.set(root, bucket)
    }
    [] => self.eager.insert(keys, candidate)
  }
}

///|
pub fn[Symbol : Eq + Hash, Candidate : Eq] LazyDiscrTree::force_root(
  self : LazyDiscrTree[Symbol, Candidate],
  root : Key[Symbol],
) -> Unit {
  guard self.pending.get(root) is Some(entries) else { () }
  for entry in entries {
    let (keys, candidate) = entry
    self.eager.insert(keys, candidate)
  }
  self.pending.remove(root)
}

///|
pub fn[Symbol : Eq + Hash, Candidate : Eq] LazyDiscrTree::force_all(
  self : LazyDiscrTree[Symbol, Candidate],
) -> Unit {
  let roots = self.pending.keys().collect()
  roots.each(root => self.force_root(root))
}

///|
fn[Symbol : Eq + Hash, Candidate : Eq] LazyDiscrTree::remove_pending(
  self : LazyDiscrTree[Symbol, Candidate],
  keys : Array[Key[Symbol]],
  candidate : Candidate,
) -> Unit {
  guard keys is [root, ..] else { () }
  guard self.pending.get(root) is Some(entries) else { () }
  let kept = entries.filter(entry => entry.0 != keys || entry.1 != candidate)
  guard !kept.is_empty() else { self.pending.remove(root) }
  self.pending.set(root, kept)
}

///|
pub fn[Symbol : Eq + Hash, Candidate : Eq] LazyDiscrTree::remove(
  self : LazyDiscrTree[Symbol, Candidate],
  keys : Array[Key[Symbol]],
  candidate : Candidate,
) -> Unit {
  self.remove_pending(keys, candidate)
  self.eager.remove(keys, candidate)
}

///|
pub fn[Symbol : Eq + Hash, Candidate : Eq] LazyDiscrTree::retrieve(
  self : LazyDiscrTree[Symbol, Candidate],
  keys : Array[Key[Symbol]],
) -> Array[Candidate] {
  guard keys is [root, ..] else { self.eager.retrieve(keys) }
  match root {
    Star => self.force_all()
    Symbol(_, _) => self..force_root(Star).force_root(root)
  }
  self.eager.retrieve(keys)
}

///|
pub fn[Symbol, Candidate] LazyDiscrTree::clear(
  self : LazyDiscrTree[Symbol, Candidate],
) -> Unit {
  self.eager.clear()
  self.pending.clear()
}

///|
pub fn[Symbol : Eq + Hash, Candidate : Eq] lazy_backend_ops() -> BackendOps[
  LazyDiscrTree[Symbol, Candidate],
  Key[Symbol],
  Candidate,
] {
  {
    insert: (backend, keys, candidate) => backend.insert(keys, candidate),
    remove: (backend, keys, candidate) => backend.remove(keys, candidate),
    retrieve: (backend, keys) => backend.retrieve(keys),
    clear: backend => backend.clear(),
  }
}

///|
pub fn[Symbol : Eq + Hash, Pattern, Candidate : Eq] lazy_index(
  profile : RetrievalProfile[Pattern, Key[Symbol], Candidate],
) -> RetrievalIndex[
  LazyDiscrTree[Symbol, Candidate],
  Pattern,
  Key[Symbol],
  Candidate,
] {
  { backend: LazyDiscrTree::new(), backend_ops: lazy_backend_ops(), profile }
}
