///|
pub struct MbSearchIndex {
  candidates : Array[MbCandidate]
  index : @gpi.RetrievalIndex[
    @gpi.StandardDiscrTree[String, Int],
    @gpi.Pattern[String, String],
    @gpi.Key[String],
    Int,
  ]
}

///|
fn search_profile() -> @gpi.RetrievalProfile[
  @gpi.Pattern[String, String],
  @gpi.Key[String],
  Int,
] {
  {
    normalize_query: @gpi.identity_normalize,
    normalize_candidate: @gpi.identity_normalize,
    traverse: @gpi.preorder,
    key: @gpi.default_key,
    matches: (_, _) => true,
    rank: (_, candidates) => candidates,
  }
}

///|
pub fn MbSearchIndex::new() -> MbSearchIndex {
  { candidates: [], index: @gpi.standard_index(search_profile()) }
}

///|
pub fn MbSearchIndex::add_candidate(
  self : MbSearchIndex,
  candidate : MbCandidate,
) -> Unit {
  let id = self.candidates.length()
  self.candidates.push(candidate)
  self.index.insert(candidate.signature.to_pattern(), id)
}

///|
pub fn MbSearchIndex::add_doc_signature(
  self : MbSearchIndex,
  line : String,
) -> Unit raise MbSearchError {
  self.add_candidate(parse_doc_signature(line))
}

///|
pub fn MbSearchIndex::add_doc_signatures(
  self : MbSearchIndex,
  lines : Array[String],
) -> Unit raise MbSearchError {
  for line in lines {
    let trimmed = line.trim().to_owned()
    if trimmed.has_prefix("pub fn") {
      self.add_doc_signature(trimmed)
    }
  }
}

///|
fn result_compare(left : MbSearchResult, right : MbSearchResult) -> Int {
  let by_score = left.score.compare(right.score)
  if by_score != 0 {
    by_score
  } else {
    left.candidate.name.compare(right.candidate.name)
  }
}

///|
pub fn MbSearchIndex::search_type(
  self : MbSearchIndex,
  query : String,
  limit? : Int = 20,
) -> Array[MbSearchResult] raise MbSearchError {
  let query_type = parse_type(query)
  self.search(query_type, limit~)
}

///|
pub fn MbSearchIndex::search(
  self : MbSearchIndex,
  query_type : MbType,
  limit? : Int = 20,
) -> Array[MbSearchResult] {
  let ids = if query_type.has_var() {
    // TODO: replace this temporary full scan once GPI supports arity-aware
    // wildcard skip keys for variable-bearing queries.
    Array::makei(self.candidates.length(), i => i)
  } else {
    self.index.retrieve(query_type.to_pattern())
  }
  let results : Array[MbSearchResult] = []
  for id in ids {
    match self.candidates.get(id) {
      Some(candidate) =>
        if matches_type(candidate.signature, query_type) {
          results.push({
            candidate,
            score: candidate_score(query_type, candidate.signature),
          })
        }
      None => ()
    }
  }
  results.sort_by(result_compare)
  if limit >= 0 && results.length() > limit {
    results.truncate(limit)
  }
  results
}

///|
pub fn search_doc_signatures(
  lines : Array[String],
  query : String,
  limit? : Int = 20,
) -> Array[MbSearchResult] raise MbSearchError {
  let index = MbSearchIndex::new()
  index..add_doc_signatures(lines).search_type(query, limit~)
}
