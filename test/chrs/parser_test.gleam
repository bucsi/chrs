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
}

fn testcase(expected, input) {
  assert Ok(Sheet("sheet", expected)) == parser.parse_sheet(input)
}
