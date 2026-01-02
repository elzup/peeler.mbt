/// Position information for a node
pub struct Pos {
  start : Int
  end : Int
  depth : Int
} derive(Show, Eq)

/// Parser options
pub struct Options {
  pairs : Array[String]
  nest_max : Int
  escape : Char
  include_empty : Bool
  quotes : Array[String]
} derive(Show, Eq)

/// Text node - plain text between brackets
pub struct PNodeText {
  pos : Pos
  content : String
} derive(Show, Eq)

/// Bracket node - contains open/close brackets and nested nodes
pub struct PNodeBracket {
  pos : Pos
  open : Char
  close : Char
  nodes : Array[PNode]
  content : String
  inner_content : String
} derive(Show, Eq)

/// PNode - either a text or bracket node
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

/// Default options for parsing
pub fn default_options() -> Options {
  {
    pairs: ["()", "{}", "[]"],
    nest_max: 100,
    escape: '\\',
    include_empty: false,
    quotes: [],
  }
}

/// Create options with custom pairs
pub fn Options::with_pairs(pairs : Array[String]) -> Options {
  { ..default_options(), pairs }
}

/// Create options with custom quotes
pub fn Options::with_quotes(quotes : Array[String]) -> Options {
  { ..default_options(), quotes }
}

/// Create options with custom nest_max
pub fn Options::with_nest_max(nest_max : Int) -> Options {
  { ..default_options(), nest_max }
}

/// Create custom options
pub fn Options::new(
  pairs : Array[String],
  nest_max : Int,
  escape : Char,
  include_empty : Bool,
  quotes : Array[String]
) -> Options {
  { pairs, nest_max, escape, include_empty, quotes }
}
