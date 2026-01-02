/// Position information for a parsed node.
///
/// Tracks where the node appears in the original text and its nesting depth.
///
/// # Fields
///
/// - `start` - Starting index in the original text (inclusive)
/// - `end` - Ending index in the original text (exclusive)
/// - `depth` - Nesting depth (0 for top-level nodes)
pub struct Pos {
  start : Int
  end : Int
  depth : Int
} derive(Show, Eq)

/// Configuration options for the bracket parser.
///
/// # Fields
///
/// - `pairs` - Bracket pairs to recognize (e.g., `["()", "{}", "[]"]`)
/// - `nest_max` - Maximum nesting depth allowed (default: 100)
/// - `escape` - Escape character for literal brackets (default: `\\`)
/// - `include_empty` - Whether to include empty text nodes (default: false)
/// - `quotes` - Quote pairs that prevent bracket parsing inside (e.g., `["\"\"", "''"]`)
///
/// # Example
///
/// ```moonbit
/// let opt = Options::with_pairs(["<>", "[]"])
/// let result = peeler_with_options("<hello>", opt)
/// ```
pub struct Options {
  pairs : Array[String]
  nest_max : Int
  escape : Char
  include_empty : Bool
  quotes : Array[String]
} derive(Show, Eq)

/// A text node representing plain text content.
///
/// Text nodes contain the actual text content found between brackets
/// or at the top level of the input string. Escape sequences are
/// already processed (e.g., `\\(` becomes `(`).
///
/// # Fields
///
/// - `pos` - Position information in the original text
/// - `content` - The actual text content (with escapes removed)
pub struct PNodeText {
  pos : Pos
  content : String
} derive(Show, Eq)

/// A bracket node representing a matched bracket pair and its contents.
///
/// Bracket nodes contain nested `PNode` elements, allowing for
/// recursive tree structures when brackets are nested.
///
/// # Fields
///
/// - `pos` - Position information in the original text
/// - `open` - The opening bracket character (e.g., `(`, `{`, `[`)
/// - `close` - The closing bracket character (e.g., `)`, `}`, `]`)
/// - `nodes` - Nested child nodes inside this bracket
/// - `content` - Full content including brackets (e.g., `"(hello)"`)
/// - `inner_content` - Content without brackets (e.g., `"hello"`)
pub struct PNodeBracket {
  pos : Pos
  open : Char
  close : Char
  nodes : Array[PNode]
  content : String
  inner_content : String
} derive(Show, Eq)

/// A parsed node in the bracket tree.
///
/// The result of parsing is an array of `PNode` values, where each node
/// is either plain text (`Text`) or a bracket with nested content (`Bracket`).
///
/// # Variants
///
/// - `Text(PNodeText)` - Plain text content
/// - `Bracket(PNodeBracket)` - A matched bracket pair with nested nodes
///
/// # Example
///
/// ```moonbit
/// let nodes = peeler("a(b)c")
/// // nodes = [Text("a"), Bracket("(", [Text("b")]), Text("c")]
/// ```
pub enum PNode {
  Text(PNodeText)
  Bracket(PNodeBracket)
} derive(Show, Eq)

/// Internal type for open brackets during parsing
priv struct PNodeBracketOpen {
  pos_start : Int
  depth : Int
  open : Char
  close : Char
  nodes : Array[PNode]
}

/// Internal type for building the parse tree
priv enum PNodeBuild {
  Root(Array[PNode], Int)
  BracketOpen(PNodeBracketOpen)
}

/// Returns the default parsing options.
///
/// Default configuration:
/// - `pairs`: `["()", "{}", "[]"]`
/// - `nest_max`: `100`
/// - `escape`: `\\`
/// - `include_empty`: `false`
/// - `quotes`: `[]`
///
/// # Returns
///
/// An `Options` struct with default values.
pub fn default_options() -> Options {
  {
    pairs: ["()", "{}", "[]"],
    nest_max: 100,
    escape: '\\',
    include_empty: false,
    quotes: [],
  }
}

/// Creates options with custom bracket pairs.
///
/// # Parameters
///
/// - `pairs` - Array of bracket pair strings (e.g., `["<>", "[]"]`)
///
/// # Returns
///
/// An `Options` struct with custom pairs and other default values.
///
/// # Example
///
/// ```moonbit
/// let opt = Options::with_pairs(["<>"])
/// let result = peeler_with_options("<html>", opt)
/// ```
pub fn Options::with_pairs(pairs : Array[String]) -> Options {
  { ..default_options(), pairs }
}

/// Creates options with custom quote characters.
///
/// Quotes prevent bracket parsing inside quoted strings.
/// Each quote string should be 1-2 characters: start and end quote.
/// Single character means start and end are the same.
///
/// # Parameters
///
/// - `quotes` - Array of quote pair strings (e.g., `["\"\"", "''"]`)
///
/// # Returns
///
/// An `Options` struct with custom quotes and other default values.
///
/// # Example
///
/// ```moonbit
/// let opt = Options::with_quotes(["\"\""])
/// let result = peeler_with_options("a\"(not bracket)\"b", opt)
/// // The "(not bracket)" is treated as text, not a bracket
/// ```
pub fn Options::with_quotes(quotes : Array[String]) -> Options {
  { ..default_options(), quotes }
}

/// Creates options with a custom maximum nesting depth.
///
/// # Parameters
///
/// - `nest_max` - Maximum nesting depth allowed (raises `ParseError` if exceeded)
///
/// # Returns
///
/// An `Options` struct with custom nest_max and other default values.
pub fn Options::with_nest_max(nest_max : Int) -> Options {
  { ..default_options(), nest_max }
}

/// Creates a fully customized `Options` struct.
///
/// # Parameters
///
/// - `pairs` - Bracket pairs to recognize
/// - `nest_max` - Maximum nesting depth
/// - `escape` - Escape character for literal brackets
/// - `include_empty` - Whether to include empty text nodes
/// - `quotes` - Quote pairs that prevent bracket parsing inside
///
/// # Returns
///
/// An `Options` struct with all custom values.
///
/// # Example
///
/// ```moonbit
/// let opt = Options::new(
///   pairs=["<>", "[]"],
///   nest_max=50,
///   escape='\\',
///   include_empty=true,
///   quotes=["\"\""],
/// )
/// ```
pub fn Options::new(
  pairs : Array[String],
  nest_max : Int,
  escape : Char,
  include_empty : Bool,
  quotes : Array[String]
) -> Options {
  { pairs, nest_max, escape, include_empty, quotes }
}
