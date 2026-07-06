///|
priv struct Parser {
  input : String
  mut pos : Int
  self_type : String
}

///|
fn Parser::new(input : String, self_type? : String = "") -> Parser {
  { input, pos: 0, self_type }
}

///|
fn is_space(code : UInt16) -> Bool {
  code == ' ' || code == '\t' || code == '\n' || code == '\r'
}

///|
fn is_ident_start(code : UInt16) -> Bool {
  code is ('A'..='Z') || code is ('a'..='z') || code == '_' || code == '@'
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
  if self.at_end() {
    None
  } else {
    Some(self.input[self.pos])
  }
}

///|
fn Parser::skip_ws(self : Parser) -> Unit {
  while self.peek() is Some(code) {
    if is_space(code) {
      self.pos += 1
    } else {
      break
    }
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
  if self.starts_with(text) {
    self.pos += text.length()
    true
  } else {
    false
  }
}

///|
fn Parser::expect(self : Parser, text : String) -> Unit raise MbSearchError {
  if !self.consume(text) {
    raise MbSearchError::InvalidType(
      input=self.input,
      offset=self.pos,
      message="expected `" + text + "`",
    )
  }
}

///|
fn Parser::parse_ident(self : Parser) -> String raise MbSearchError {
  self.skip_ws()
  let start = self.pos
  match self.peek() {
    Some(code) if is_ident_start(code) => self.pos += 1
    _ =>
      raise MbSearchError::InvalidType(
        input=self.input,
        offset=self.pos,
        message="expected identifier",
      )
  }
  while self.peek() is Some(code) {
    if is_ident_continue(code) {
      self.pos += 1
    } else {
      break
    }
  }
  self.input.unsafe_substring(start~, end=self.pos)
}

///|
fn Parser::parse_type(self : Parser) -> MbType raise MbSearchError {
  self.parse_arrow()
}

///|
fn Parser::parse_arrow(self : Parser) -> MbType raise MbSearchError {
  let left = self.parse_postfix()
  self.skip_ws()
  if self.consume("->") {
    let right = self.parse_arrow()
    let left_args = match left {
      Tuple(items) => Fun(items, right)
      _ => Fun([left], right)
    }
    match left_args {
      Fun(args, _) =>
        match right {
          Fun(right_args, right_return) => {
            let all_args = args.copy()
            all_args.append(right_args)
            Fun(all_args, right_return)
          }
          _ => left_args
        }
      _ => left_args
    }
  } else {
    left
  }
}

///|
fn Parser::parse_postfix(self : Parser) -> MbType raise MbSearchError {
  let mut t = self.parse_primary()
  for ;; {
    self.skip_ws()
    if self.consume("?") {
      t = option(t)
    } else {
      break
    }
  }
  t
}

///|
fn Parser::parse_primary(self : Parser) -> MbType raise MbSearchError {
  self.skip_ws()
  if self.consume("(") {
    self.skip_ws()
    if self.consume(")") {
      Con("Unit")
    } else {
      let items : Array[MbType] = []
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
      let args : Array[MbType] = []
      self.skip_ws()
      if !self.consume("]") {
        args.push(self.parse_type())
        self.skip_ws()
        while self.consume(",") {
          args.push(self.parse_type())
          self.skip_ws()
        }
        self.expect("]")
      }
      App(real_name, args)
    } else if is_type_variable(real_name) {
      Var(real_name)
    } else {
      Con(real_name)
    }
  }
}

///|
fn is_type_variable(name : String) -> Bool {
  name.length() == 1 && name[0] is ('A'..='Z')
}

///|
fn strip_effect_suffix(input : String) -> String {
  let mut s = input.trim().to_owned()
  // TODO: model MoonBit effects in MbType instead of temporarily erasing them.
  if s.has_suffix(" raise?") {
    s = s.unsafe_substring(start=0, end=s.length() - " raise?".length())
  } else if s.has_suffix(" raise") {
    s = s.unsafe_substring(start=0, end=s.length() - " raise".length())
  }
  s
}

///|
pub fn parse_type(input : String) -> MbType raise MbSearchError {
  parse_type_with_self(input, self_type="")
}

///|
fn parse_type_with_self(
  input : String,
  self_type~ : String,
) -> MbType raise MbSearchError {
  let cleaned = strip_effect_suffix(input)
  let parser = Parser::new(cleaned, self_type~)
  let t = parser.parse_type()
  parser.skip_ws()
  if !parser.at_end() {
    raise MbSearchError::InvalidType(
      input=cleaned,
      offset=parser.pos,
      message="unexpected trailing input",
    )
  }
  t
}

///|
fn find_matching(
  input : String,
  open_pos : Int,
  open_code : UInt16,
  close_code : UInt16,
) -> Int {
  let mut depth = 0
  for i in open_pos..<input.length() {
    let code = input[i]
    if code == open_code {
      depth += 1
    } else if code == close_code {
      depth -= 1
      if depth == 0 {
        return i
      }
    }
  }
  -1
}

///|
fn skip_generic_params(line : String, pos : Int) -> Int {
  let mut p = pos
  while p < line.length() && is_space(line[p]) {
    p += 1
  }
  if p < line.length() && line[p] == '[' {
    let end = find_matching(line, p, '[', ']')
    if end >= 0 {
      end + 1
    } else {
      p
    }
  } else {
    p
  }
}

///|
fn find_top_level_colon(input : String) -> Int {
  let mut paren = 0
  let mut bracket = 0
  for i in 0..<input.length() {
    let code = input[i]
    if code == '(' {
      paren += 1
    } else if code == ')' {
      paren -= 1
    } else if code == '[' {
      bracket += 1
    } else if code == ']' {
      bracket -= 1
    } else if code == ':' && paren == 0 && bracket == 0 {
      if i + 1 < input.length() && input[i + 1] == ':' {
        continue
      }
      return i
    }
  }
  -1
}

///|
fn split_top_level_commas(input : String) -> Array[String] {
  let parts : Array[String] = []
  let mut start = 0
  let mut paren = 0
  let mut bracket = 0
  for i in 0..<input.length() {
    let code = input[i]
    if code == '(' {
      paren += 1
    } else if code == ')' {
      paren -= 1
    } else if code == '[' {
      bracket += 1
    } else if code == ']' {
      bracket -= 1
    } else if code == ',' && paren == 0 && bracket == 0 {
      parts.push(input.unsafe_substring(start~, end=i).trim().to_owned())
      start = i + 1
    }
  }
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
fn param_type_text(param : String) -> String {
  let colon = find_top_level_colon(param)
  if colon >= 0 {
    param
    .unsafe_substring(start=colon + 1, end=param.length())
    .trim()
    .to_owned()
  } else {
    param.trim().to_owned()
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
fn candidate_name_from_line(line : String) -> (String, Int) raise MbSearchError {
  let trimmed = line.trim().to_owned()
  if !trimmed.has_prefix("pub fn") {
    raise MbSearchError::InvalidSignature(
      line=trimmed,
      message="expected `pub fn` signature line",
    )
  }
  let mut pos = "pub fn".length()
  pos = skip_generic_params(trimmed, pos)
  while pos < trimmed.length() && is_space(trimmed[pos]) {
    pos += 1
  }
  let start = pos
  while pos < trimmed.length() && trimmed[pos] != '(' && !is_space(trimmed[pos]) {
    pos += 1
  }
  if start == pos {
    raise MbSearchError::InvalidSignature(
      line=trimmed,
      message="missing function name",
    )
  }
  (trimmed.unsafe_substring(start~, end=pos), pos)
}

///|
pub fn parse_doc_signature(line : String) -> MbCandidate raise MbSearchError {
  let trimmed = line.trim().to_owned()
  let (name, name_end) = candidate_name_from_line(trimmed)
  let open = for i = name_end; i < trimmed.length(); i = i + 1 {
    if trimmed[i] == '(' {
      break i
    }
  } nobreak {
    -1
  }
  if open < 0 {
    raise MbSearchError::InvalidSignature(
      line=trimmed,
      message="missing parameter list",
    )
  }
  let close = find_matching(trimmed, open, '(', ')')
  if close < 0 {
    raise MbSearchError::InvalidSignature(
      line=trimmed,
      message="unclosed parameter list",
    )
  }
  let after_params = trimmed.unsafe_substring(
    start=close + 1,
    end=trimmed.length(),
  )
  let arrow = after_params.find("->")
  match arrow {
    None =>
      raise MbSearchError::InvalidSignature(
        line=trimmed,
        message="missing return type",
      )
    Some(arrow_pos) => {
      let self_type = self_type_from_name(name)
      let params_text = trimmed.unsafe_substring(start=open + 1, end=close)
      let args = split_top_level_commas(params_text).map(param => {
        parse_type_with_self(param_type_text(param), self_type~)
      })
      let return_text = after_params.unsafe_substring(
        start=arrow_pos + 2,
        end=after_params.length(),
      )
      let return_type = parse_type_with_self(return_text, self_type~)
      { name, signature: Fun(args, return_type), source: trimmed }
    }
  }
}
