///|
priv struct Parser {
  input : String
  mut pos : Int
  self_type : String
  generic_vars : Array[String]
  allow_implicit_vars : Bool
}

///|
fn Parser::new(
  input : String,
  self_type? : String = "",
  generic_vars? : Array[String] = [],
  allow_implicit_vars? : Bool = true,
) -> Parser {
  { input, pos: 0, self_type, generic_vars, allow_implicit_vars }
}

///|
fn is_space(code : UInt16) -> Bool {
  code == ' ' || code == '\t' || code == '\n' || code == '\r'
}

///|
fn is_plain_ident_start(code : UInt16) -> Bool {
  code is ('A'..='Z') || code is ('a'..='z') || code == '_'
}

///|
fn is_plain_ident_continue(code : UInt16) -> Bool {
  is_plain_ident_start(code) || code is ('0'..='9')
}

///|
fn is_ident_start(code : UInt16) -> Bool {
  is_plain_ident_start(code) || code == '@'
}

///|
fn is_ident_continue(code : UInt16) -> Bool {
  is_ident_start(code) || code is ('0'..='9') || code == '.' || code == '/'
}

///|
fn Parser::at_end(self : Parser) -> Bool {
  self.pos >= self.input.length()
}

///|
fn Parser::peek(self : Parser) -> UInt16? {
  guard !self.at_end() else { None }
  Some(self.input[self.pos])
}

///|
fn Parser::skip_ws(self : Parser) -> Unit {
  while self.peek() is Some(code) {
    guard is_space(code) else { break }
    self.pos += 1
  }
}

///|
fn Parser::starts_with(self : Parser, text : String) -> Bool {
  let end = self.pos + text.length()
  end <= self.input.length() &&
  self.input.unsafe_substring(start=self.pos, end~) == text
}

///|
fn Parser::consume(self : Parser, text : String) -> Bool {
  guard self.starts_with(text) else { false }
  self.pos += text.length()
  true
}

///|
fn Parser::expect(self : Parser, text : String) -> Unit raise MbtSearchError {
  guard self.consume(text) else {
    raise MbtSearchError::InvalidType(
      input=self.input,
      offset=self.pos,
      message="expected `" + text + "`",
    )
  }
}

///|
fn Parser::parse_ident(self : Parser) -> String raise MbtSearchError {
  self.skip_ws()
  let start = self.pos
  match self.peek() {
    Some(code) if is_ident_start(code) => self.pos += 1
    _ =>
      raise MbtSearchError::InvalidType(
        input=self.input,
        offset=self.pos,
        message="expected identifier",
      )
  }
  while self.peek() is Some(code) {
    if is_ident_continue(code) {
      self.pos += 1
    } else {
      guard code == ':' &&
        self.pos + 1 < self.input.length() &&
        self.input[self.pos + 1] == ':' else {
        break
      }
      self.pos += 2
    }
  }
  self.input.unsafe_substring(start~, end=self.pos)
}

///|
fn Parser::parse_type(self : Parser) -> MbtType raise MbtSearchError {
  self.parse_arrow()
}

///|
fn Parser::parse_arrow(self : Parser) -> MbtType raise MbtSearchError {
  let left = self.parse_postfix()
  self.skip_ws()
  guard self.consume("->") else { left }
  let right = self.parse_arrow()
  let args = match left {
    Tuple(items) => items
    _ => [left]
  }
  match right {
    Fun(right_args, right_return) => {
      let all_args = args.copy()
      all_args.append(right_args)
      Fun(all_args, right_return)
    }
    _ => Fun(args, right)
  }
}

///|
fn Parser::parse_postfix(self : Parser) -> MbtType raise MbtSearchError {
  let mut t = self.parse_primary()
  for ;; {
    self.skip_ws()
    guard self.consume("?") else { break }
    t = option(t)
  }
  t
}

///|
fn Parser::parse_primary(self : Parser) -> MbtType raise MbtSearchError {
  self.skip_ws()
  if self.consume("(") {
    self.skip_ws()
    if self.consume(")") {
      Con("Unit")
    } else {
      let items : Array[MbtType] = []
      items.push(self.parse_type())
      self.skip_ws()
      while self.consume(",") {
        items.push(self.parse_type())
        self.skip_ws()
      }
      self.expect(")")
      if items.length() == 1 {
        items[0]
      } else {
        Tuple(items)
      }
    }
  } else {
    let name = self.parse_ident()
    self.skip_ws()
    let real_name = if name == "Self" && self.self_type != "" {
      self.self_type
    } else {
      name
    }
    if self.consume("[") {
      let args : Array[MbtType] = []
      self.skip_ws()
      guard !self.consume("]") else {
        raise MbtSearchError::InvalidType(
          input=self.input,
          offset=self.pos - 1,
          message="empty type argument list",
        )
      }
      args.push(self.parse_type())
      self.skip_ws()
      while self.consume(",") {
        args.push(self.parse_type())
        self.skip_ws()
      }
      self.expect("]")
      App(real_name, args)
    } else if self.is_type_variable(real_name) {
      Var(real_name)
    } else {
      Con(real_name)
    }
  }
}

///|
fn Parser::is_type_variable(self : Parser, name : String) -> Bool {
  guard self.generic_vars.is_empty() else { self.generic_vars.contains(name) }
  self.allow_implicit_vars && name.length() == 1 && name[0] is ('A'..='Z')
}

///|
pub fn parse_type(input : String) -> MbtType raise MbtSearchError {
  parse_type_with_self(input, self_type="")
}

///|
fn parse_type_with_self(
  input : String,
  self_type~ : String,
  generic_vars? : Array[String] = [],
  allow_implicit_vars? : Bool = true,
) -> MbtType raise MbtSearchError {
  let cleaned = strip_top_level_effect_suffix(input)
  let parser = Parser::new(
    cleaned,
    self_type~,
    generic_vars~,
    allow_implicit_vars~,
  )
  let t = parser.parse_type()
  parser.skip_ws()
  guard parser.at_end() else {
    raise MbtSearchError::InvalidType(
      input=cleaned,
      offset=parser.pos,
      message="unexpected trailing input",
    )
  }
  t
}

///|
priv struct DelimiterDepth {
  mut paren : Int
  mut bracket : Int
}

///|
fn DelimiterDepth::new() -> DelimiterDepth {
  { paren: 0, bracket: 0 }
}

///|
fn DelimiterDepth::at_top(self : DelimiterDepth) -> Bool {
  self.paren == 0 && self.bracket == 0
}

///|
fn is_effect_raise_at(input : String, pos : Int) -> Bool {
  let word = "raise"
  let end = pos + word.length()
  pos > 0 &&
  is_space(input[pos - 1]) &&
  end <= input.length() &&
  input.unsafe_substring(start=pos, end~) == word &&
  (end >= input.length() || !is_ident_continue(input[end]))
}

///|
fn DelimiterDepth::consume_unchecked(
  self : DelimiterDepth,
  code : UInt16,
) -> Bool {
  if code == '(' {
    self.paren += 1
    true
  } else if code == ')' {
    if self.paren == 0 {
      false
    } else {
      self.paren -= 1
      true
    }
  } else if code == '[' {
    self.bracket += 1
    true
  } else if code == ']' {
    if self.bracket == 0 {
      false
    } else {
      self.bracket -= 1
      true
    }
  } else {
    true
  }
}

///|
fn DelimiterDepth::consume_type(
  self : DelimiterDepth,
  code : UInt16,
  input : String,
  offset : Int,
) -> Unit raise MbtSearchError {
  guard self.consume_unchecked(code) else {
    raise MbtSearchError::InvalidType(
      input~,
      offset~,
      message="unmatched delimiter",
    )
  }
}

///|
fn DelimiterDepth::consume_signature(
  self : DelimiterDepth,
  code : UInt16,
  line : String,
) -> Unit raise MbtSearchError {
  guard self.consume_unchecked(code) else {
    raise MbtSearchError::InvalidSignature(line~, message="unmatched delimiter")
  }
}

///|
fn DelimiterDepth::expect_type_closed(
  self : DelimiterDepth,
  input : String,
) -> Unit raise MbtSearchError {
  guard self.at_top() else {
    raise MbtSearchError::InvalidType(
      input~,
      offset=input.length(),
      message="unclosed delimiter",
    )
  }
}

///|
fn DelimiterDepth::expect_signature_closed(
  self : DelimiterDepth,
  line : String,
) -> Unit raise MbtSearchError {
  guard self.paren == 0 else {
    raise MbtSearchError::InvalidSignature(line~, message="unclosed `(`")
  }
  guard self.bracket == 0 else {
    raise MbtSearchError::InvalidSignature(line~, message="unclosed `[`")
  }
}

///|
fn find_matching(
  input : String,
  open_pos : Int,
  open_code : UInt16,
  close_code : UInt16,
) -> Int? {
  let mut depth = 0
  for i in open_pos..<input.length() {
    let code = input[i]
    if code == open_code {
      depth += 1
    } else if code == close_code {
      depth -= 1
      if depth == 0 {
        return Some(i)
      }
    }
  }
  None
}

///|
fn find_code_from(input : String, start : Int, code : UInt16) -> Int? {
  for i in start..<input.length() {
    if input[i] == code {
      return Some(i)
    }
  }
  None
}

///|
fn strip_top_level_effect_suffix(input : String) -> String raise MbtSearchError {
  let trimmed = input.trim().to_owned()
  let depth = DelimiterDepth::new()
  // TODO: model MoonBit effects in MbType instead of temporarily erasing them.
  for i in 0..<trimmed.length() {
    if depth.at_top() && is_effect_raise_at(trimmed, i) {
      return trimmed.unsafe_substring(start=0, end=i).trim().to_owned()
    }
    depth.consume_type(trimmed[i], trimmed, i)
  }
  depth.expect_type_closed(trimmed)
  trimmed
}

///|
fn is_annotation_colon(input : String, pos : Int) -> Bool {
  input[pos] == ':' &&
  (pos == 0 || input[pos - 1] != ':') &&
  (pos + 1 >= input.length() || input[pos + 1] != ':')
}

///|
fn find_top_level_annotation_colon(
  input : String,
  line : String,
) -> Int? raise MbtSearchError {
  let depth = DelimiterDepth::new()
  for i in 0..<input.length() {
    let code = input[i]
    if depth.at_top() && is_annotation_colon(input, i) {
      return Some(i)
    }
    depth.consume_signature(code, line)
  }
  depth.expect_signature_closed(line)
  None
}

///|
fn split_top_level_commas(
  input : String,
  line : String,
) -> Array[String] raise MbtSearchError {
  let trimmed = input.trim().to_owned()
  guard trimmed != "" else { [] }
  let parts : Array[String] = []
  let mut start = 0
  let depth = DelimiterDepth::new()
  for i in 0..<input.length() {
    let code = input[i]
    if code == ',' && depth.at_top() {
      let part = input.unsafe_substring(start~, end=i).trim().to_owned()
      guard part != "" else {
        raise MbtSearchError::InvalidSignature(
          line~,
          message="empty comma-separated item",
        )
      }
      parts.push(part)
      start = i + 1
    } else {
      depth.consume_signature(code, line)
    }
  }
  depth.expect_signature_closed(line)
  let tail = input
    .unsafe_substring(start~, end=input.length())
    .trim()
    .to_owned()
  if tail != "" {
    parts.push(tail)
  }
  parts
}

///|
fn param_type_text(
  param : String,
  line : String,
) -> String raise MbtSearchError {
  match find_top_level_annotation_colon(param, line) {
    Some(colon) =>
      param
      .unsafe_substring(start=colon + 1, end=param.length())
      .trim()
      .to_owned()
    None => param.trim().to_owned()
  }
}

///|
fn self_type_from_name(name : String) -> String {
  match name.split_once("::") {
    Some((receiver, _)) => receiver.to_owned()
    None => ""
  }
}

///|
fn generic_param_name(
  param : String,
  line : String,
) -> String raise MbtSearchError {
  let trimmed = param.trim().to_owned()
  let mut end = 0
  while end < trimmed.length() && !is_space(trimmed[end]) && trimmed[end] != ':' {
    end += 1
  }
  let name = trimmed.unsafe_substring(start=0, end~)
  guard name != "" && is_plain_ident_start(name[0]) else {
    raise MbtSearchError::InvalidSignature(
      line~,
      message="invalid generic parameter",
    )
  }
  for i in 1..<name.length() {
    guard is_plain_ident_continue(name[i]) else {
      raise MbtSearchError::InvalidSignature(
        line~,
        message="invalid generic parameter",
      )
    }
  }
  name
}

///|
fn generic_params_from_text(
  text : String,
  line : String,
) -> Array[String] raise MbtSearchError {
  let params = split_top_level_commas(text, line)
  guard !params.is_empty() else {
    raise MbtSearchError::InvalidSignature(
      line~,
      message="empty generic parameter list",
    )
  }
  let names : Array[String] = []
  for param in params {
    let name = generic_param_name(param, line)
    guard !names.contains(name) else {
      raise MbtSearchError::InvalidSignature(
        line~,
        message="duplicate generic parameter `" + name + "`",
      )
    }
    names.push(name)
  }
  names
}

///|
fn has_pub_fn_prefix(trimmed : String) -> Bool {
  let prefix = "pub fn"
  trimmed.has_prefix(prefix) &&
  (
    trimmed.length() == prefix.length() ||
    is_space(trimmed[prefix.length()]) ||
    trimmed[prefix.length()] == '['
  )
}

///|
priv struct SignatureHeader {
  name : String
  name_end : Int
  generic_vars : Array[String]
}

///|
fn signature_header_from_line(
  line : String,
) -> SignatureHeader raise MbtSearchError {
  let trimmed = line.trim().to_owned()
  guard has_pub_fn_prefix(trimmed) else {
    raise MbtSearchError::InvalidSignature(
      line=trimmed,
      message="expected `pub fn` signature line",
    )
  }
  let mut pos = "pub fn".length()
  while pos < trimmed.length() && is_space(trimmed[pos]) {
    pos += 1
  }
  let generic_vars = if pos < trimmed.length() && trimmed[pos] == '[' {
    guard find_matching(trimmed, pos, '[', ']') is Some(end) else {
      raise MbtSearchError::InvalidSignature(
        line=trimmed,
        message="unclosed generic parameter list",
      )
    }
    let text = trimmed.unsafe_substring(start=pos + 1, end~)
    pos = end + 1
    generic_params_from_text(text, trimmed)
  } else {
    []
  }
  while pos < trimmed.length() && is_space(trimmed[pos]) {
    pos += 1
  }
  let start = pos
  while pos < trimmed.length() && trimmed[pos] != '(' && !is_space(trimmed[pos]) {
    pos += 1
  }
  guard start != pos else {
    raise MbtSearchError::InvalidSignature(
      line=trimmed,
      message="missing function name",
    )
  }
  {
    name: trimmed.unsafe_substring(start~, end=pos),
    name_end: pos,
    generic_vars,
  }
}

///|
pub fn parse_doc_signature(line : String) -> MbtCandidate raise MbtSearchError {
  let trimmed = line.trim().to_owned()
  let header = signature_header_from_line(trimmed)
  let name = header.name
  guard find_code_from(trimmed, header.name_end, '(') is Some(open) else {
    raise MbtSearchError::InvalidSignature(
      line=trimmed,
      message="missing parameter list",
    )
  }
  guard find_matching(trimmed, open, '(', ')') is Some(close) else {
    raise MbtSearchError::InvalidSignature(
      line=trimmed,
      message="unclosed parameter list",
    )
  }
  let after_params = trimmed.unsafe_substring(
    start=close + 1,
    end=trimmed.length(),
  )
  let after_params = after_params.trim().to_owned()
  guard after_params.has_prefix("->") else {
    raise MbtSearchError::InvalidSignature(
      line=trimmed,
      message="missing return type",
    )
  }
  let self_type = self_type_from_name(name)
  let generic_vars = header.generic_vars
  let params_text = trimmed.unsafe_substring(start=open + 1, end=close)
  let args = split_top_level_commas(params_text, trimmed).map(param => {
    parse_type_with_self(
      param_type_text(param, trimmed),
      self_type~,
      generic_vars~,
      allow_implicit_vars=false,
    )
  })
  let return_text = after_params.unsafe_substring(
    start=2,
    end=after_params.length(),
  )
  let return_type = parse_type_with_self(
    return_text,
    self_type~,
    generic_vars~,
    allow_implicit_vars=false,
  )
  MbtCandidate::{ name, signature: Fun(args, return_type), source: trimmed }
}
