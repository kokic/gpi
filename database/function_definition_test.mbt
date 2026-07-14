///|
test "find top-level function definitions" {
  let source =
    #|fn[T] helper(value : T) -> T { value }
    #|
    #|#alias(from_array)
    #|pub fn[A] Deque::Deque(
    #|  values : ArrayView[A],
    #|  capacity? : Int,
    #|) -> Deque[A] {
    #|  ...
    #|}
    #|
    #|pub impl[A : Show] Show for Deque[A] with fn output(self, logger) {
    #|  ...
    #|}
  let definitions = @database.function_definitions(source)
  debug_inspect(
    definitions.map(definition => {
      (
        definition.name,
        definition.visibility,
        definition.start.line,
        definition.end.line,
      )
    }),
    content=(
      #|[("helper", Default, 1, 1), ("Deque::Deque", Public, 3, 9)]
    ),
  )
  inspect(
    definitions[1].signature,
    content=(
      #|pub fn[A] Deque::Deque(
      #|  values : ArrayView[A],
      #|  capacity? : Int,
      #|) -> Deque[A]
    ),
  )
}

///|
test "return public signatures for library search" {
  let signatures = @database.public_function_signatures(
    (
      #|fn private_helper() -> Unit { () }
      #|pub fn[A] Deque::front(self : Deque[A]) -> A? { ... }
      #|priv fn hidden() -> Unit { () }
      #|pub async fn fetch() -> String { ... }
    ),
  )
  debug_inspect(
    signatures,
    content="[\"pub fn[A] Deque::front(self : Deque[A]) -> A?\"]",
  )
}

///|
test "source slices account for non-BMP characters" {
  let definitions = @database.function_definitions(
    (
      #|let marker = "\u{1f680}"
      #|pub fn answer() -> Int { 42 }
    ),
  )
  inspect(definitions[0].source, content="pub fn answer() -> Int { 42 }")
}

///|
test "surface parser diagnostics" {
  let error = try @database.function_definitions("pub fn broken(") catch {
    error => error
  } noraise {
    _ => fail("expected parser error")
  }
  guard error is ParseFailed(diagnostics) else { fail("unexpected error") }
  assert_true(!diagnostics.is_empty())
}
