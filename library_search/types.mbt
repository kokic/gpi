///|
pub(all) enum MbtType {
  Con(String)
  Var(String)
  App(String, Array[MbtType])
  Fun(Array[MbtType], MbtType)
  Tuple(Array[MbtType])
} derive(Eq, Hash, Debug)

///|
pub(all) struct MbtCandidate {
  name : String
  signature : MbtType
  source : String
}

///|
pub(all) struct MbtSearchResult {
  candidate : MbtCandidate
  score : Int
}

///|
pub(all) suberror MbtSearchError {
  InvalidType(input~ : String, offset~ : Int, message~ : String)
  InvalidSignature(line~ : String, message~ : String)
} derive(Eq, Debug)

///|
pub fn con(name : String) -> MbtType {
  Con(name)
}

///|
pub fn type_var(name : String) -> MbtType {
  Var(name)
}

///|
pub fn app(name : String, args : Array[MbtType]) -> MbtType {
  App(name, args)
}

///|
pub fn option(t : MbtType) -> MbtType {
  App("Option", [t])
}

///|
pub fn function_type(args : Array[MbtType], return_type : MbtType) -> MbtType {
  Fun(args, return_type)
}

///|
pub fn tuple_type(items : Array[MbtType]) -> MbtType {
  Tuple(items)
}

///|
pub fn MbtType::to_pattern(self : MbtType) -> @gpi.Pattern[String, String] {
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
fn MbtType::generic_count(self : MbtType) -> Int {
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
fn MbtType::node_count(self : MbtType) -> Int {
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
fn candidate_score(query : MbtType, candidate : MbtType) -> Int {
  guard query != candidate else { 0 }
  candidate.generic_count() * 10 + candidate.node_count()
}
