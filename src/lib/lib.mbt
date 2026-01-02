/// Build a map from open bracket to close bracket
fn build_closes(pairs : Array[String]) -> Map[Char, Char] {
  let closes : Map[Char, Char] = {}
  for pair in pairs {
    if pair.length() >= 2 {
      let chars = pair.to_array()
      closes[chars[0]] = chars[1]
    }
  }
  closes
}

/// Build a map from close bracket to open bracket
fn build_opens(pairs : Array[String]) -> Map[Char, Char] {
  let opens : Map[Char, Char] = {}
  for pair in pairs {
    if pair.length() >= 2 {
      let chars = pair.to_array()
      opens[chars[1]] = chars[0]
    }
  }
  opens
}

/// Build a map from quote start to quote end
fn build_quotes(quote_opts : Array[String]) -> Map[Char, Char] {
  let quotes : Map[Char, Char] = {}
  for q in quote_opts {
    let chars = q.to_array()
    if chars.length() >= 2 {
      quotes[chars[0]] = chars[1]
    } else if chars.length() == 1 {
      quotes[chars[0]] = chars[0]
    }
  }
  quotes
}

/// Get all bracket characters for escape processing
fn get_bracket_chars(pairs : Array[String]) -> Array[Char] {
  let chars : Array[Char] = []
  for pair in pairs {
    for c in pair {
      chars.push(c)
    }
  }
  chars
}

/// Remove escape characters from text
fn remove_escapes(text : String, escape : Char, bracket_chars : Array[Char]) -> String {
  let result = StringBuilder::new()
  let chars = text.to_array()
  let mut i = 0
  while i < chars.length() {
    if chars[i] == escape && i + 1 < chars.length() {
      let next = chars[i + 1]
      if bracket_chars.contains(next) {
        result.write_char(next)
        i = i + 2
        continue
      }
    }
    result.write_char(chars[i])
    i = i + 1
  }
  result.to_string()
}

/// Substring helper
fn substring(text : String, start : Int, end : Int) -> String {
  let chars = text.to_array()
  let result = StringBuilder::new()
  for i = start; i < end && i < chars.length(); i = i + 1 {
    result.write_char(chars[i])
  }
  result.to_string()
}

/// Error type raised when parsing fails.
///
/// Contains a descriptive error message indicating:
/// - Missing closing bracket and its position
/// - Missing opening bracket and its position
/// - Unclosed quote and its position
/// - Nesting depth exceeded
pub suberror ParseError String

/// Parses text into a tree of bracket nodes.
///
/// This is the core parsing function that converts a string into an array
/// of `PNode` values representing the bracket structure.
///
/// # Parameters
///
/// - `text` - The input string to parse
/// - `opt` - Parsing options (bracket pairs, quotes, etc.)
///
/// # Returns
///
/// An array of `PNode` values representing the parsed structure.
///
/// # Raises
///
/// - `ParseError` - If brackets are unmatched or nesting exceeds `nest_max`
///
/// # Example
///
/// ```moonbit
/// let opt = default_options()
/// let nodes = parse!("hello (world)", opt)
/// ```
pub fn parse(text : String, opt : Options) -> Array[PNode] raise ParseError {
  let closes = build_closes(opt.pairs)
  let opens = build_opens(opt.pairs)
  let quotes = build_quotes(opt.quotes)
  let bracket_chars = get_bracket_chars(opt.pairs)
  let chars = text.to_array()

  // Stack of nodes being built
  let stack : Array[PNodeBuild] = [Root([], -1)]
  let mut p = 0
  let mut inside_quote : Char? = None
  let mut quote_start = 0

  for i, c in chars {
    let at_escape = i > 0 && chars[i - 1] == opt.escape
    if at_escape {
      continue
    }
    match inside_quote {
      Some(q) => {
        if q == c {
          inside_quote = None
        }
        continue
      }
      None => ()
    }
    match quotes.get(c) {
      Some(end_quote) => {
        inside_quote = Some(end_quote)
        quote_start = i
        continue
      }
      None => ()
    }

    // Check for open bracket
    match closes.get(c) {
      Some(close_bracket) => {
        if stack.length() >= opt.nest_max {
          raise ParseError(
            "NestError: over nest max limit. options: { nest_max: '\{opt.nest_max}' }",
          )
        }

        // Add text before this bracket
        let current_depth = match stack[stack.length() - 1] {
          Root(_, d) => d
          BracketOpen(bo) => bo.depth
        }
        if p < i || opt.include_empty {
          let content = remove_escapes(
            substring(text, p, i),
            opt.escape,
            bracket_chars,
          )
          if content.length() > 0 || opt.include_empty {
            let text_node = Text(
              { pos: { start: p, end: i, depth: current_depth + 1 }, content },
            )
            match stack[stack.length() - 1] {
              Root(nodes, _) => nodes.push(text_node)
              BracketOpen(bo) => bo.nodes.push(text_node)
            }
          }
        }

        // Push new bracket
        stack.push(
          BracketOpen(
            {
              pos_start: i,
              depth: current_depth + 1,
              open: c,
              close: close_bracket,
              nodes: [],
            },
          ),
        )
        p = i + 1
        continue
      }
      None => ()
    }

    // Check for close bracket
    match opens.get(c) {
      Some(expected_open) =>
        match stack[stack.length() - 1] {
          Root(_nodes, _) =>
            raise ParseError("ParseError: 404 pair '\{expected_open}' :\{i}")
          BracketOpen(bo) => {
            if bo.close != c {
              raise ParseError(
                "ParseError: 404 pair '\{bo.open}' :\{bo.pos_start}",
              )
            }

            // Add final text in bracket
            if p < i || opt.include_empty {
              let content = remove_escapes(
                substring(text, p, i),
                opt.escape,
                bracket_chars,
              )
              if content.length() > 0 || opt.include_empty {
                let text_node = Text(
                  { pos: { start: p, end: i, depth: bo.depth + 1 }, content },
                )
                bo.nodes.push(text_node)
              }
            }

            // Close the bracket
            let closed_node = Bracket(
              {
                pos: { start: bo.pos_start, end: i, depth: bo.depth },
                open: bo.open,
                close: c,
                nodes: bo.nodes,
                content: substring(text, bo.pos_start, i + 1),
                inner_content: substring(text, bo.pos_start + 1, i),
              },
            )

            // Pop the bracket and add to parent
            let _ = stack.pop()
            match stack[stack.length() - 1] {
              Root(nodes, _) => nodes.push(closed_node)
              BracketOpen(parent_bo) => parent_bo.nodes.push(closed_node)
            }
            p = i + 1
          }
        }
      None => ()
    }
  }

  // Check for unclosed quote
  match inside_quote {
    Some(q) =>
      raise ParseError("ParseError: 404 quote close \{q} :\{quote_start}")
    None => ()
  }

  // Check for unclosed brackets
  match stack[stack.length() - 1] {
    BracketOpen(bo) =>
      raise ParseError("ParseError: 404 pair '\{bo.open}' :\{bo.pos_start}")
    Root(nodes, depth) => {
      // Add remaining text
      if p < chars.length() || opt.include_empty {
        let content = remove_escapes(
          substring(text, p, chars.length()),
          opt.escape,
          bracket_chars,
        )
        if content.length() > 0 || opt.include_empty {
          let text_node = Text(
            {
              pos: { start: p, end: chars.length(), depth: depth + 1 },
              content,
            },
          )
          nodes.push(text_node)
        }
      }
      nodes
    }
  }
}

/// Parses text with default options.
///
/// This is the main entry point for parsing bracket structures.
/// Uses default bracket pairs: `()`, `{}`, `[]`.
///
/// # Parameters
///
/// - `text` - The input string to parse
///
/// # Returns
///
/// An array of `PNode` values representing the parsed structure.
///
/// # Raises
///
/// - `ParseError` - If brackets are unmatched or nesting exceeds limit
///
/// # Example
///
/// ```moonbit
/// let nodes = peeler!("hello (world)")
/// // nodes = [Text("hello "), Bracket("(", [Text("world")])]
///
/// // Nested brackets
/// let nodes = peeler!("a(b{c}d)e")
/// // nodes = [Text("a"), Bracket("(", [Text("b"), Bracket("{", ...), Text("d")]), Text("e")]
///
/// // Escape brackets with backslash
/// let nodes = peeler!("a\\(b")
/// // nodes = [Text("a(b")]
/// ```
pub fn peeler(text : String) -> Array[PNode] raise ParseError {
  parse(text, default_options())
}

/// Parses text with custom options.
///
/// Use this function when you need to customize bracket pairs,
/// quotes, or other parsing behavior.
///
/// # Parameters
///
/// - `text` - The input string to parse
/// - `opt` - Custom parsing options
///
/// # Returns
///
/// An array of `PNode` values representing the parsed structure.
///
/// # Raises
///
/// - `ParseError` - If brackets are unmatched or nesting exceeds limit
///
/// # Example
///
/// ```moonbit
/// // Parse HTML-style angle brackets
/// let opt = Options::with_pairs(["<>"])
/// let nodes = peeler_with_options!("<div>content</div>", opt)
///
/// // Ignore brackets inside quotes
/// let opt = Options::with_quotes(["\"\""])
/// let nodes = peeler_with_options!("say \"(hello)\" now", opt)
/// // "(hello)" is treated as text, not a bracket
/// ```
pub fn peeler_with_options(
  text : String,
  opt : Options
) -> Array[PNode] raise ParseError {
  parse(text, opt)
}
