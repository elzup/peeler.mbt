fn dump(nodes : Array[@lib.PNode], d~ : Int = 0) -> Array[String] {
  let pad = "  ".repeat(d)
  let result : Array[String] = []
  for n in nodes {
    match n {
      @lib.Text(t) => result.push("\{pad}\{t.content}")
      @lib.Bracket(b) => {
        result.push("\{pad}\{b.open}")
        result.append(dump(b.nodes, d=d + 1))
        result.push("\{pad}\{b.close}")
      }
    }
  }
  result
}

///|
test "peel tree" {
  inspect(
    dump(@lib.peeler("(hello((w)world(-\\('ω'\\)-){[A](B)}))")).join("\n"),
  content=(
    #|(
  #|  hello
  #|  (
  #|    (
  #|      w
  #|    )
  #|    world
  #|    (
  #|      -('ω')-
  #|    )
  #|    {
  #|      [
  #|        A
  #|      ]
  #|      (
  #|        B
  #|      )
  #|    }
  #|  )
  #|)
  ))
}
