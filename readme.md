# peeler.mbt

> Bracket parser for MoonBit

MoonBit implementation of [peeler](https://github.com/elzup/peeler).

## Examples

```moonbit
// Simple
peeler("(hello)")
// -> [Bracket{open:'(', nodes:[Text{content:"hello"}]}]

// Nested brackets
peeler("aa(bb{cc}bb)aa")
// -> [Text("aa"), Bracket(...), Text("aa")]
//                    └─ [Text("bb"), Bracket({cc}), Text("bb")]

// Escape brackets
peeler("a\\(b")
// -> [Text{content:"a(b"}]

// Mixed bracket types
peeler("[({})]")
// -> [Bracket [
//       └─ Bracket (
//            └─ Bracket {} ]]
```

## Dump Result

```moonbit
fn dump(nodes : Array[PNode], d~ : Int = 0) -> Array[String] {
  let pad = "  ".repeat(d)
  nodes.flat_map(fn(n) {
    match n {
      Text(t) => ["\{pad}\{t.content}"]
      Bracket(b) => [["\{pad}\{b.open}"], dump(b.nodes, d=d + 1), ["\{pad}\{b.close}"]].flatten()
    }
  })
}

dump(peeler("aa(bb{cc}dd)ee")).join("\n")
// aa
// (
//   bb
//   {
//     cc
//   }
//   dd
// )
// ee
```

## Install

```
moon add elzup/peeler
```

## Usage

```moonbit
let result = @peeler.peeler("before(hit)after")
// Returns: [Text("before"), Bracket("(", ")", [Text("hit")]), Text("after")]

// With custom options
let opt = @peeler.Options::with_pairs(["[]", "<>"])
let result = @peeler.peeler_with_options("[content]", opt)
```

## API

### peeler(text: String) -> Array[PNode]

Parse text with default options (pairs: `()`, `{}`, `[]`).

### peeler_with_options(text: String, opt: Options) -> Array[PNode]

Parse text with custom options.

## Types

```moonbit
enum PNode {
  Text(PNodeText)
  Bracket(PNodeBracket)
}

struct PNodeText {
  pos: Pos
  content: String
}

struct PNodeBracket {
  pos: Pos
  open: Char
  close: Char
  nodes: Array[PNode]
  content: String
  inner_content: String
}

struct Pos {
  start: Int
  end: Int
  depth: Int
}

struct Options {
  pairs: Array[String]      // default: ["()", "{}", "[]"]
  nest_max: Int             // default: 100
  escape: Char              // default: '\\'
  include_empty: Bool       // default: false
  quotes: Array[String]     // default: []
}
```

## License

MIT
