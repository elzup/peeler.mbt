// Benchmark corpora, modeled after braces' `benchmark/fixtures/*`:
// one input *shape* per entry so the runner can sweep them side by side.
// These shapes mirror the cases that surfaced the O(n^2) `substring` bug.

fn repeat_str(s : String, n : Int) -> String {
  let buf = StringBuilder::new()
  for _ in 0..<n {
    buf.write_string(s)
  }
  buf.to_string()
}

/// Many shallow brackets (16k chars, many nodes). Stresses per-node slicing.
fn fixture_flat() -> String {
  repeat_str("before(hit)after ", 1000)
}

/// Escape-heavy (24k chars, collapses to one text node). Stresses remove_escapes.
fn fixture_escape() -> String {
  repeat_str("a\\(b\\)c\\{d\\}", 2000)
}

/// Plain text (44k chars, one text node). Stresses the final substring only.
fn fixture_plain() -> String {
  repeat_str("abcdefghij klmnopqrst ", 2000)
}

/// Deeply nested (depth 90). Stresses the stack and inner_content slicing.
fn fixture_deep() -> String {
  repeat_str("(", 90) + "x" + repeat_str(")", 90)
}
