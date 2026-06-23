// Benchmark runner, modeled after braces' `benchmark/index.js`: sweep each
// fixture through `@lib.parse` and let MoonBit's native bench harness
// (`moon bench`) collect timing statistics. Backend-independent, so unlike the
// old `extern "js"` harness this runs on wasm-gc, js, and native alike.

///|
test "bench parse flat_brackets x1000" (it : @bench.T) {
  let opt = @lib.default_options()
  let text = fixture_flat()
  it.bench(() => (try? @lib.parse(text, opt)) |> ignore)
}

///|
test "bench parse escape_heavy x2000" (it : @bench.T) {
  let opt = @lib.default_options()
  let text = fixture_escape()
  it.bench(() => (try? @lib.parse(text, opt)) |> ignore)
}

///|
test "bench parse plain_text x2000" (it : @bench.T) {
  let opt = @lib.default_options()
  let text = fixture_plain()
  it.bench(() => (try? @lib.parse(text, opt)) |> ignore)
}

///|
test "bench parse deep_nest x90" (it : @bench.T) {
  let opt = @lib.default_options()
  let text = fixture_deep()
  it.bench(() => (try? @lib.parse(text, opt)) |> ignore)
}
