// Basic tests
test "simple text only" {
  let result = peeler("hello")
  inspect(result.length(), content="1")
  match result[0] {
    Text(t) => {
      inspect(t.content, content="hello")
      inspect(t.pos.start, content="0")
      inspect(t.pos.end, content="5")
      inspect(t.pos.depth, content="0")
    }
    Bracket(_) => fail("Expected Text node")
  }
}

test "simple bracket" {
  let result = peeler("(hit)")
  inspect(result.length(), content="1")
  match result[0] {
    Bracket(b) => {
      inspect(b.open, content="(")
      inspect(b.close, content=")")
      inspect(b.inner_content, content="hit")
      inspect(b.nodes.length(), content="1")
    }
    Text(_) => fail("Expected Bracket node")
  }
}

test "text before and after bracket" {
  let result = peeler("before(hit)after")
  inspect(result.length(), content="3")
  match result[0] {
    Text(t) => inspect(t.content, content="before")
    Bracket(_) => fail("Expected Text node")
  }
  match result[1] {
    Bracket(b) => {
      inspect(b.open, content="(")
      inspect(b.close, content=")")
      inspect(b.content, content="(hit)")
      inspect(b.inner_content, content="hit")
    }
    Text(_) => fail("Expected Bracket node")
  }
  match result[2] {
    Text(t) => inspect(t.content, content="after")
    Bracket(_) => fail("Expected Text node")
  }
}

// Complex tests from original
test "empty input" {
  let result = peeler("")
  inspect(result.length(), content="0")
}

test "sub empty - empty bracket" {
  let result = peeler("()")
  inspect(result.length(), content="1")
  match result[0] {
    Bracket(b) => {
      inspect(b.content, content="()")
      inspect(b.inner_content, content="")
      inspect(b.nodes.length(), content="0")
    }
    Text(_) => fail("Expected Bracket node")
  }
}

test "sub sub empty - nested empty brackets" {
  let result = peeler("(())")
  inspect(result.length(), content="1")
  match result[0] {
    Bracket(outer) => {
      inspect(outer.content, content="(())")
      inspect(outer.inner_content, content="()")
      inspect(outer.nodes.length(), content="1")
      match outer.nodes[0] {
        Bracket(inner) => {
          inspect(inner.content, content="()")
          inspect(inner.inner_content, content="")
          inspect(inner.nodes.length(), content="0")
        }
        Text(_) => fail("Expected Bracket node")
      }
    }
    Text(_) => fail("Expected Bracket node")
  }
}

test "nest side - brackets with text between" {
  let result = peeler("({}fuga{})")
  inspect(result.length(), content="1")
  match result[0] {
    Bracket(b) => {
      inspect(b.inner_content, content="{}fuga{}")
      inspect(b.nodes.length(), content="3")
      // First {}
      match b.nodes[0] {
        Bracket(inner) => inspect(inner.inner_content, content="")
        Text(_) => fail("Expected Bracket node")
      }
      // Text "fuga"
      match b.nodes[1] {
        Text(t) => inspect(t.content, content="fuga")
        Bracket(_) => fail("Expected Text node")
      }
      // Second {}
      match b.nodes[2] {
        Bracket(inner) => inspect(inner.inner_content, content="")
        Text(_) => fail("Expected Bracket node")
      }
    }
    Text(_) => fail("Expected Bracket node")
  }
}

test "any bracket - mixed bracket types" {
  let result = peeler("[({})]")
  inspect(result.length(), content="1")
  match result[0] {
    Bracket(b1) => {
      inspect(b1.open, content="[")
      inspect(b1.close, content="]")
      match b1.nodes[0] {
        Bracket(b2) => {
          inspect(b2.open, content="(")
          inspect(b2.close, content=")")
          match b2.nodes[0] {
            Bracket(b3) => {
              inspect(b3.open, content="{")
              inspect(b3.close, content="}")
              inspect(b3.nodes.length(), content="0")
            }
            Text(_) => fail("Expected Bracket node")
          }
        }
        Text(_) => fail("Expected Bracket node")
      }
    }
    Text(_) => fail("Expected Bracket node")
  }
}

test "with newline" {
  let result = peeler("hel(lo\ngo)od by")
  inspect(result.length(), content="3")
  match result[0] {
    Text(t) => inspect(t.content, content="hel")
    Bracket(_) => fail("Expected Text node")
  }
  match result[1] {
    Bracket(b) => inspect(b.inner_content, content="lo\ngo")
    Text(_) => fail("Expected Bracket node")
  }
  match result[2] {
    Text(t) => inspect(t.content, content="od by")
    Bracket(_) => fail("Expected Text node")
  }
}

test "three nest" {
  let result = peeler("aa(bb(cc(dd)cc)bb)aa")
  inspect(result.length(), content="3")
  match result[0] {
    Text(t) => inspect(t.content, content="aa")
    Bracket(_) => fail("Expected Text node")
  }
  match result[1] {
    Bracket(level1) => {
      inspect(level1.nodes.length(), content="3")
      match level1.nodes[0] {
        Text(t) => inspect(t.content, content="bb")
        Bracket(_) => fail("Expected Text node")
      }
      match level1.nodes[1] {
        Bracket(level2) => {
          inspect(level2.nodes.length(), content="3")
          match level2.nodes[1] {
            Bracket(level3) => inspect(level3.inner_content, content="dd")
            Text(_) => fail("Expected Bracket node")
          }
        }
        Text(_) => fail("Expected Bracket node")
      }
    }
    Text(_) => fail("Expected Bracket node")
  }
}

// Escape tests
test "escape char only" {
  let result = peeler("\\")
  inspect(result.length(), content="1")
  match result[0] {
    Text(t) => inspect(t.content, content="\\")
    Bracket(_) => fail("Expected Text node")
  }
}

test "escape bracket" {
  let result = peeler("a\\(b")
  inspect(result.length(), content="1")
  match result[0] {
    Text(t) => inspect(t.content, content="a(b")
    Bracket(_) => fail("Expected Text node")
  }
}

test "escape bracket chars inside bracket" {
  let result = peeler("(\\(OK\\)\\[GOOD\\])")
  inspect(result.length(), content="1")
  match result[0] {
    Bracket(b) => {
      inspect(b.nodes.length(), content="1")
      match b.nodes[0] {
        Text(t) => inspect(t.content, content="(OK)[GOOD]")
        Bracket(_) => fail("Expected Text node")
      }
    }
    Text(_) => fail("Expected Bracket node")
  }
}

// Bracket options tests
test "custom pairs - () only" {
  let opt = Options::with_pairs(["()"])
  let result = peeler_with_options("aaa(bbb{})ccc[ddd]", opt)
  inspect(result.length(), content="3")
  match result[0] {
    Text(t) => inspect(t.content, content="aaa")
    Bracket(_) => fail("Expected Text node")
  }
  match result[1] {
    Bracket(b) => {
      inspect(b.open, content="(")
      inspect(b.inner_content, content="bbb{}")
    }
    Text(_) => fail("Expected Bracket node")
  }
  match result[2] {
    Text(t) => inspect(t.content, content="ccc[ddd]")
    Bracket(_) => fail("Expected Text node")
  }
}

test "custom pairs - rare option Oo" {
  let opt = Options::with_pairs(["Oo"])
  let result = peeler_with_options("tOshinO kyoko", opt)
  inspect(result.length(), content="2")
  match result[0] {
    Text(t) => inspect(t.content, content="t")
    Bracket(_) => fail("Expected Text node")
  }
  match result[1] {
    Bracket(b) => {
      inspect(b.open, content="O")
      inspect(b.close, content="o")
      inspect(b.inner_content, content="shinO kyok")
    }
    Text(_) => fail("Expected Bracket node")
  }
}

// nestMax option tests
test "nestMax error - limit 2" {
  let opt = Options::with_nest_max(2)
  let result : Result[Array[PNode], Error] = try {
    Ok(peeler_with_options("((()))", opt))
  } catch {
    e => Err(e)
  }
  match result {
    Err(_) => ()
    Ok(_) => fail("Expected NestError")
  }
}

test "nestMax error - limit 1" {
  let opt = Options::with_nest_max(1)
  let result : Result[Array[PNode], Error] = try {
    Ok(peeler_with_options("((()))", opt))
  } catch {
    e => Err(e)
  }
  match result {
    Err(_) => ()
    Ok(_) => fail("Expected NestError")
  }
}

// Quote tests
test "quote - inside quote escape" {
  let opt = Options::with_quotes(["\""])
  let result = peeler_with_options("( \" ignored (() \" )", opt)
  inspect(result.length(), content="1")
  match result[0] {
    Bracket(b) => {
      inspect(b.inner_content, content=" \" ignored (() \" ")
      inspect(b.nodes.length(), content="1")
    }
    Text(_) => fail("Expected Bracket node")
  }
}

test "quote - another quote is not close quote" {
  let opt = Options::with_quotes(["\"", "'"])
  let result = peeler_with_options("( \" '( \" )", opt)
  inspect(result.length(), content="1")
  match result[0] {
    Bracket(b) => {
      inspect(b.inner_content, content=" \" '( \" ")
    }
    Text(_) => fail("Expected Bracket node")
  }
}

test "quote pair - <>" {
  let opt = Options::with_quotes(["\"", "'", "<>"])
  let result = peeler_with_options("( < escape [[( > \" ' \\\" \" )", opt)
  inspect(result.length(), content="1")
  match result[0] {
    Bracket(b) => {
      inspect(b.inner_content, content=" < escape [[( > \" ' \\\" \" ")
    }
    Text(_) => fail("Expected Bracket node")
  }
}

test "quote parse error - unclosed quote" {
  let opt = Options::with_quotes(["\""])
  let result : Result[Array[PNode], Error] = try {
    Ok(peeler_with_options("( \"(\" ) \")", opt))
  } catch {
    e => Err(e)
  }
  match result {
    Err(_) => ()
    Ok(_) => fail("Expected ParseError for unclosed quote")
  }
}

// Bracket parse error tests
test "bracket error - mismatched brackets" {
  let result : Result[Array[PNode], Error] = try {
    Ok(peeler("hog{e(b}c)d"))
  } catch {
    e => Err(e)
  }
  match result {
    Err(_) => ()
    Ok(_) => fail("Expected ParseError for mismatched brackets")
  }
}

test "bracket error - unclosed bracket" {
  let result : Result[Array[PNode], Error] = try {
    Ok(peeler("("))
  } catch {
    e => Err(e)
  }
  match result {
    Err(_) => ()
    Ok(_) => fail("Expected ParseError for unclosed bracket")
  }
}

test "bracket error - unmatched close bracket" {
  let result : Result[Array[PNode], Error] = try {
    Ok(peeler("text)"))
  } catch {
    e => Err(e)
  }
  match result {
    Err(_) => ()
    Ok(_) => fail("Expected ParseError for unmatched close bracket")
  }
}

// Depth tests
test "depth values" {
  let result = peeler("a(b(c))")
  match result[0] {
    Text(t) => inspect(t.pos.depth, content="0")
    Bracket(_) => fail("Expected Text node")
  }
  match result[1] {
    Bracket(b) => {
      inspect(b.pos.depth, content="0")
      match b.nodes[0] {
        Text(t) => inspect(t.pos.depth, content="1")
        Bracket(_) => fail("Expected Text node")
      }
      match b.nodes[1] {
        Bracket(inner) => {
          inspect(inner.pos.depth, content="1")
          match inner.nodes[0] {
            Text(t) => inspect(t.pos.depth, content="2")
            Bracket(_) => fail("Expected Text node")
          }
        }
        Text(_) => fail("Expected Bracket node")
      }
    }
    Text(_) => fail("Expected Bracket node")
  }
}

// Complex case from original
test "gata gata - complex nested" {
  let result = peeler("aa({cc}bb{c2(dd)c2}b)aa(b2)aa")
  inspect(result.length(), content="5")
  match result[0] {
    Text(t) => inspect(t.content, content="aa")
    Bracket(_) => fail("Expected Text node")
  }
  match result[1] {
    Bracket(b) => inspect(b.inner_content, content="{cc}bb{c2(dd)c2}b")
    Text(_) => fail("Expected Bracket node")
  }
  match result[2] {
    Text(t) => inspect(t.content, content="aa")
    Bracket(_) => fail("Expected Text node")
  }
  match result[3] {
    Bracket(b) => inspect(b.inner_content, content="b2")
    Text(_) => fail("Expected Bracket node")
  }
  match result[4] {
    Text(t) => inspect(t.content, content="aa")
    Bracket(_) => fail("Expected Text node")
  }
}
