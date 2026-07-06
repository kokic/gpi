///|
pub struct MbSearchIndex {
  candidates : Array[MbtCandidate]
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
    traverse: pattern => pattern.preorder(),
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
  candidate : MbtCandidate,
) -> Unit {
  let id = self.candidates.length()
  self.candidates.push(candidate)
  self.index.insert(candidate.signature.to_pattern(), id)
}

///|
pub fn MbSearchIndex::add_doc_signature(
  self : MbSearchIndex,
  line : String,
) -> Unit raise MbtSearchError {
  self.add_candidate(parse_doc_signature(line))
}

///|
pub fn MbSearchIndex::add_doc_signatures(
  self : MbSearchIndex,
  lines : Array[String],
) -> Unit raise MbtSearchError {
  for line in lines {
    let trimmed = line.trim().to_owned()
    if trimmed.has_prefix("pub fn") {
      self.add_doc_signature(trimmed)
    }
  }
}

///|
fn result_compare(left : MbtSearchResult, right : MbtSearchResult) -> Int {
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
) -> Array[MbtSearchResult] raise MbtSearchError {
  let query_type = parse_type(query)
  self.search(query_type, limit~)
}

///|
pub fn MbSearchIndex::search(
  self : MbSearchIndex,
  query_type : MbtType,
  limit? : Int = 20,
) -> Array[MbtSearchResult] {
  let ids = self.index.retrieve(query_type.to_pattern())
  let results : Array[MbtSearchResult] = []
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
) -> Array[MbtSearchResult] raise MbtSearchError {
  let index = MbSearchIndex::new()
  index..add_doc_signatures(lines).search_type(query, limit~)
}
