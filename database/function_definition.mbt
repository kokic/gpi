///|
pub(all) enum FunctionVisibility {
  Default
  Public
  Private
} derive(Eq, Debug)

///|
pub(all) struct SourcePosition {
  line : Int
  column : Int
  offset : Int
} derive(Eq, Debug)

///|
pub(all) struct FunctionDefinition {
  name : String
  visibility : FunctionVisibility
  signature : String
  source : String
  start : SourcePosition
  end : SourcePosition
} derive(Eq, Debug)

///|
pub(all) struct ParseDiagnostic {
  message : String
  start : SourcePosition
  end : SourcePosition
} derive(Eq, Debug)

///|
pub(all) suberror DatabaseError {
  ParseFailed(Array[ParseDiagnostic])
} derive(Eq, Debug)

///|
fn source_position(line : Int, column : Int, offset : Int) -> SourcePosition {
  { line, column, offset }
}

///|
fn codepoint_to_utf16_offset(source : String, offset : Int) -> Int {
  guard offset > 0 else { return 0 }
  for char in source; codepoints = 0, utf16 = 0 {
    guard codepoints < offset else { break utf16 }
    let width = if char.to_int() > 0xffff { 2 } else { 1 }
    continue codepoints + 1, utf16 + width
  } nobreak {
    source.length()
  }
}

///|
fn source_slice(source : String, start : Int, end : Int) -> String {
  let utf16_start = codepoint_to_utf16_offset(source, start)
  let utf16_end = codepoint_to_utf16_offset(source, end)
  source.unsafe_substring(start=utf16_start, end=utf16_end)
}

///|
fn type_name_text(type_name : @syntax.TypeName) -> String {
  match type_name.name {
    Ident(name~) => name
    Dot(pkg~, id~) => "@" + pkg + "." + id
  }
}

///|
fn function_name(fun_decl : @syntax.FunDecl) -> String {
  match fun_decl.type_name {
    Some(type_name) => type_name_text(type_name) + "::" + fun_decl.name.name
    None => fun_decl.name.name
  }
}

///|
fn function_visibility(vis : @syntax.Visibility) -> FunctionVisibility {
  match vis {
    Default => Default
    Pub(..) => Public
    Priv(..) => Private
  }
}

///|
fn signature_start(fun_decl : @syntax.FunDecl) -> Int {
  match fun_decl.vis {
    Pub(loc~, ..) | Priv(loc~) => loc.start.cnum
    Default => fun_decl.loc.start.cnum
  }
}

///|
fn function_definition(
  source : String,
  fun_decl : @syntax.FunDecl,
  start : SourcePosition,
  end : SourcePosition,
) -> FunctionDefinition {
  {
    name: function_name(fun_decl),
    visibility: function_visibility(fun_decl.vis),
    signature: source_slice(
      source,
      signature_start(fun_decl),
      fun_decl.loc.end.cnum,
    ),
    source: source_slice(source, start.offset, end.offset),
    start,
    end,
  }
}

///|
/// Parse one MoonBit source file and return its top-level `fn` definitions.
///
/// Trait implementation methods are represented by `impl` declarations in the
/// syntax tree and are intentionally not included.
pub fn function_definitions(
  source : String,
  name? : String = "",
) -> Array[FunctionDefinition] raise DatabaseError {
  let (impls, reports) = @parser.parse_string(source, name~)
  guard reports.is_empty() else {
    raise ParseFailed(
      reports.map(report => {
        message: report.msg,
        start: source_position(
          report.loc.start.lnum,
          report.loc.start.column(),
          report.loc.start.cnum,
        ),
        end: source_position(
          report.loc.end.lnum,
          report.loc.end.column(),
          report.loc.end.cnum,
        ),
      }),
    )
  }
  let definitions : Array[FunctionDefinition] = []
  for impl_ in impls {
    match impl_ {
      TopFuncDef(fun_decl~, loc~, ..) =>
        definitions.push(
          function_definition(
            source,
            fun_decl,
            source_position(loc.start.lnum, loc.start.column(), loc.start.cnum),
            source_position(loc.end.lnum, loc.end.column(), loc.end.cnum),
          ),
        )
      _ => ()
    }
  }
  definitions
}

///|
/// Return source signatures suitable for `library_search.add_doc_signatures`.
pub fn public_function_signatures(
  source : String,
  name? : String = "",
) -> Array[String] raise DatabaseError {
  function_definitions(source, name~).filter_map(definition => {
    let is_public_function = definition.visibility == Public &&
      definition.signature.has_prefix("pub fn")
    guard is_public_function else { None }
    Some(definition.signature)
  })
}
