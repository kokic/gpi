///|
/// A function-table backend interface.
///
/// MoonBit traits are not parameterized, so backend independence is represented
/// explicitly as operations over a concrete backend value.
pub(all) struct BackendOps[Backend, Key, Candidate] {
  insert : (Backend, Array[Key], Candidate) -> Unit
  remove : (Backend, Array[Key], Candidate) -> Unit
  retrieve : (Backend, Array[Key]) -> Array[Candidate]
  clear : (Backend) -> Unit
}

///|
pub(all) struct RetrievalProfile[Pattern, Key, Candidate] {
  normalize_query : (Pattern) -> Pattern
  normalize_candidate : (Pattern) -> Pattern
  traverse : (Pattern) -> Array[Pattern]
  key : (Pattern) -> Key?
  matches : (Pattern, Candidate) -> Bool
  rank : (Pattern, Array[Candidate]) -> Array[Candidate]
}

///|
pub(all) struct RetrievalIndex[Backend, Pattern, Key, Candidate] {
  backend : Backend
  backend_ops : BackendOps[Backend, Key, Candidate]
  profile : RetrievalProfile[Pattern, Key, Candidate]
}

///|
pub fn[Pattern] identity_normalize(pattern : Pattern) -> Pattern {
  pattern
}

///|
pub fn[Pattern, Key, Candidate] RetrievalProfile::query_keys(
  self : RetrievalProfile[Pattern, Key, Candidate],
  pattern : Pattern,
) -> Array[Key] {
  let normalized = (self.normalize_query)(pattern)
  profile_keys(self, normalized)
}

///|
pub fn[Pattern, Key, Candidate] RetrievalProfile::candidate_keys(
  self : RetrievalProfile[Pattern, Key, Candidate],
  pattern : Pattern,
) -> Array[Key] {
  let normalized = (self.normalize_candidate)(pattern)
  profile_keys(self, normalized)
}

///|
fn[Pattern, Key, Candidate] profile_keys(
  profile : RetrievalProfile[Pattern, Key, Candidate],
  pattern : Pattern,
) -> Array[Key] {
  let keys : Array[Key] = []
  for node in (profile.traverse)(pattern) {
    guard (profile.key)(node) is Some(key) else { continue }
    keys.push(key)
  }
  keys
}

///|
pub fn[Backend, Pattern, Key, Candidate] RetrievalIndex::insert(
  self : RetrievalIndex[Backend, Pattern, Key, Candidate],
  pattern : Pattern,
  candidate : Candidate,
) -> Unit {
  let keys = self.profile.candidate_keys(pattern)
  (self.backend_ops.insert)(self.backend, keys, candidate)
}

///|
pub fn[Backend, Pattern, Key, Candidate] RetrievalIndex::remove(
  self : RetrievalIndex[Backend, Pattern, Key, Candidate],
  pattern : Pattern,
  candidate : Candidate,
) -> Unit {
  let keys = self.profile.candidate_keys(pattern)
  (self.backend_ops.remove)(self.backend, keys, candidate)
}

///|
pub fn[Backend, Pattern, Key, Candidate] RetrievalIndex::retrieve(
  self : RetrievalIndex[Backend, Pattern, Key, Candidate],
  query : Pattern,
) -> Array[Candidate] {
  let normalized = (self.profile.normalize_query)(query)
  let keys = profile_keys(self.profile, normalized)
  let candidates = (self.backend_ops.retrieve)(self.backend, keys)
  let matched = candidates.filter(candidate => {
    (self.profile.matches)(normalized, candidate)
  })
  (self.profile.rank)(normalized, matched)
}

///|
pub fn[Backend, Pattern, Key, Candidate] RetrievalIndex::clear(
  self : RetrievalIndex[Backend, Pattern, Key, Candidate],
) -> Unit {
  (self.backend_ops.clear)(self.backend)
}
