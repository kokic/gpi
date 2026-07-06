///|
pub(all) enum MbType {
  Con(String)
  Var(String)
  App(String, Array[MbType])
  Fun(Array[MbType], MbType)
  Tuple(Array[MbType])
} derive(Eq, Hash, Debug)

///|
pub(all) struct MbCandidate {
  name : String
  signature : MbType
  source : String
}

///|
pub(all) struct MbSearchResult {
  candidate : MbCandidate
  score : Int
}

///|
pub(all) suberror MbSearchError {
  InvalidType(input~ : String, offset~ : Int, message~ : String)
  InvalidSignature(line~ : String, message~ : String)
} derive(Eq, Debug)

///|
pub fn con(name : String) -> MbType {
  Con(name)
}

///|
pub fn type_var(name : String) -> MbType {
  Var(name)
}

///|
pub fn app(name : String, args : Array[MbType]) -> MbType {
  App(name, args)
}

///|
pub fn option(t : MbType) -> MbType {
  App("Option", [t])
}

///|
pub fn function_type(args : Array[MbType], return_type : MbType) -> MbType {
  Fun(args, return_type)
}

///|
pub fn tuple_type(items : Array[MbType]) -> MbType {
  Tuple(items)
}

///|
pub fn MbType::to_pattern(self : MbType) -> @gpi.Pattern[String, String] {
  match self {
    Con(name) => @gpi.Pattern::leaf("type:" + name)
    Var(name) => @gpi.Pattern::variable(name)
    App(name, args) =>
      @gpi.Pattern::node("type:" + name, args.map(arg => arg.to_pattern()))
    Fun(args, return_type) => {
      let children = args.map(arg => arg.to_pattern())
      children.push(return_type.to_pattern())
      @gpi.Pattern::node("fn", children)
    }
    Tuple(items) =>
      @gpi.Pattern::node(
        "tuple/" + items.length().to_string(),
        items.map(item => item.to_pattern()),
      )
  }
}

///|
fn MbType::generic_count(self : MbType) -> Int {
  match self {
    Var(_) => 1
    Con(_) => 0
    App(_, args) => args.fold(init=0, (acc, arg) => acc + arg.generic_count())
    Fun(args, return_type) =>
      args.fold(init=return_type.generic_count(), (acc, arg) => {
        acc + arg.generic_count()
      })
    Tuple(items) =>
      items.fold(init=0, (acc, item) => acc + item.generic_count())
  }
}

///|
fn MbType::node_count(self : MbType) -> Int {
  match self {
    Var(_) | Con(_) => 1
    App(_, args) => 1 + args.fold(init=0, (acc, arg) => acc + arg.node_count())
    Fun(args, return_type) =>
      1 +
      return_type.node_count() +
      args.fold(init=0, (acc, arg) => acc + arg.node_count())
    Tuple(items) =>
      1 + items.fold(init=0, (acc, item) => acc + item.node_count())
  }
}

///|
fn candidate_score(query : MbType, candidate : MbType) -> Int {
  if query == candidate {
    0
  } else {
    candidate.generic_count() * 10 + candidate.node_count()
  }
}
