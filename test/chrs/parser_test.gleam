import gleam/result
import gleam/string
import gleeunit

import chrs/parser
import chrs/sheet.{
  Checkbox, Counter, Group, Integer, LongText, Modifier, Numeric, Reference,
  Resource, Sheet, ShortText, Value,
}

pub fn main() {
  gleeunit.main()
}

pub fn parser_test() {
  let name = "Name"
  testcase([], "")

  testcase(
    [Value(name, ShortText("a short text"))],
    name <> ": \"a short text\"",
  )

  let long_text_content =
    "a long text\nwith\tnewlines in it
  and also a quote\" and a backslash\\"
  testcase(
    [Value(name, LongText(long_text_content))],
    name <> ": {" <> long_text_content <> "}",
  )

  testcase(
    [Value(name, Reference("telex", "https://telex.hu"))],
    name <> ": [telex](https://telex.hu)",
  )

  testcase([Value(name, Reference("telex", ""))], name <> ": [telex]()")

  testcase([Value(name, Reference("telex", ""))], name <> ": [telex]")

  testcase([Value(name, Integer(1))], name <> ": 1")

  let rule = sheet.RecoveryRule([], sheet.ByAmount(2))
  testcase(
    [Value(name, Resource(9, 10, rule, Numeric))],
    name <> ": resource {9/10 [] +2}",
  )

  let rule = sheet.RecoveryRule([], sheet.ByAmount(-2))
  testcase(
    [Value(name, Resource(9, 10, rule, Counter))],
    name <> ": counter {9/10 [] -2}",
  )

  testcase([Group(name, [])], "group Name {}")

  testcase([Group(name, [Group(name, [])])], "group Name {group Name{}}")

  testcase([Value("Wizard's Stuff", Integer(1))], "Wizard's Stuff: 1")
  testcase([Group("Wizard's Stuff", [])], "group Wizard's Stuff {}")

  testcase([Value(name, Integer(1))], "   " <> name <> "   : 1")
  testcase([Group(name, [])], "group   " <> name <> "   {}")

  testcase([Value(name, Checkbox(sheet.On))], name <> ": On")
  testcase([Value(name, Checkbox(sheet.Off))], name <> ": Off")
  testcase([Value(name, Checkbox(sheet.Special))], name <> ": Special")

  testcase([Value(name, Modifier(3))], name <> ": +3")
  testcase([Value(name, Modifier(-1))], name <> ": -1")

  testcase(
    [
      Value(
        name,
        Resource(9, 10, sheet.RecoveryRule([], sheet.ToFull), Numeric),
      ),
    ],
    name <> ": resource {9/10 [] to_full}",
  )
  testcase(
    [
      Value(
        name,
        Resource(9, 10, sheet.RecoveryRule([], sheet.ToHalfMax), Numeric),
      ),
    ],
    name <> ": resource {9/10 [] to_half}",
  )
  testcase(
    [
      Value(
        name,
        Resource(9, 10, sheet.RecoveryRule([], sheet.ToZero), Numeric),
      ),
    ],
    name <> ": resource {9/10 [] to_zero}",
  )
  testcase(
    [
      Value(
        name,
        Resource(9, 10, sheet.RecoveryRule([], sheet.NoChange), Numeric),
      ),
    ],
    name <> ": resource {9/10 [] no_change}",
  )

  testcase(
    [
      Value(
        name,
        Resource(
          9,
          10,
          sheet.RecoveryRule(["on damage"], sheet.ToFull),
          Numeric,
        ),
      ),
    ],
    name <> ": resource {9/10 [on damage] to_full}",
  )

  testcase(
    [
      Value(
        name,
        Resource(
          9,
          10,
          sheet.RecoveryRule(["a b", "c d"], sheet.ToFull),
          Numeric,
        ),
      ),
    ],
    name <> ": resource {9/10 [a b, c d] to_full}",
  )

  testcase(
    [
      Value(
        name,
        Resource(
          9,
          10,
          sheet.RecoveryRule(["long trigger phrase with words"], sheet.ToZero),
          Counter,
        ),
      ),
    ],
    name <> ": counter {9/10 [long trigger phrase with words] to_zero}",
  )

  testcase(
    [
      Value(
        name,
        Resource(9, 10, sheet.RecoveryRule([], sheet.ToFull), Numeric),
      ),
    ],
    name <> ": resource {9/10 [ ] to_full}",
  )

  testcase([Value(name, Reference("", ""))], name <> ": []")
  testcase([Value(name, Reference("", ""))], name <> ": []()")
  testcase([Value(name, Reference("", "https://x"))], name <> ": [](https://x)")

  testcase(
    [
      Value(name, Reference("telex", "https://telex.hu")),
      Value("Next", Integer(1)),
    ],
    name <> ": [telex](https://telex.hu)\nNext: 1",
  )

  testcase(
    [Value(name, Reference("telex", "https://telex.hu"))],
    name <> ": [telex] (https://telex.hu)",
  )

  testcase(
    [Value("HP", Integer(10)), Group("Nested", [Value("X", Integer(1))])],
    "HP: 10\ngroup Nested {\n  X: 1\n}",
  )

  testcase([Value("A", Integer(1)), Value("B", Integer(2))], "A: 1\nB: 2")

  testcase([Value(name, Integer(1))], "\n\n  " <> name <> ":    1  \n\n")
}

fn testcase(expected, input) {
  assert Ok(Sheet("sheet", expected)) == parser.run(input)
}

pub fn explain_test() {
  // Unclosed group: runs out of input while still wanting "}".
  let input = "group Name {"
  let assert Error(msg) =
    input |> parser.run |> result.map_error(parser.explain(_, input))
  assert string.contains(msg, "Parse error:")
  assert string.contains(msg, "EOF")
  assert !string.contains(msg, "ParseError(")

  // Missing colon: "Name 1" is swallowed whole as the key (spaces are
  // legal inside Key), then ":" is expected and never found.
  let input = "Name 1"
  let assert Error(msg) =
    input |> parser.run |> result.map_error(parser.explain(_, input))
  assert string.contains(msg, "Parse error:")
  assert string.contains(msg, "EOF")

  // Unrecognized field value: nothing in FieldValue starts with "@",
  // exercising the "Expected ..." / "Expected one of ..." branch.
  let input = "Name: @@@"
  let assert Error(msg) =
    input |> parser.run |> result.map_error(parser.explain(_, input)) |> echo
  assert string.contains(msg, "Parse error:")
  assert string.contains(msg, "Expected")

  // The message always carries a rendered source snippet after the
  // headline, not just the headline alone.
  assert string.contains(msg, "\n\n")
}
