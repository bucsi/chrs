import gleam/int
import gleam/list
import gleam/result
import gleam/string

import atto
import atto/error
import atto/ops
import atto/text
import atto/text_util

// Import your custom types package/module here
import chrs/sheet.{
  type CheckboxValue, type Element, type FieldValue, type RecoveryKind,
  type RecoveryRule, type ResourceKind, type Sheet, ByAmount, Checkbox, Counter,
  Group, Integer, Link, LongText, Modifier, Numeric, Off, On, RecoveryRule,
  Resource, Sheet, ShortText, Special, ToFull, ToHalfMax, ToZero, Value,
}

// Helper combinator to handle trailing whitespace around tokens and literals
fn lexeme(
  p: atto.Parser(a, String, String, b, c),
) -> atto.Parser(a, String, String, b, c) {
  use x <- atto.do(p)
  use _ <- atto.do(ops.maybe(text.match("\\s*")))
  atto.pure(x)
}

fn keyword(s: String) -> atto.Parser(String, String, String, a, b) {
  use <- atto.label(s)
  case string.length(s) {
    1 -> lexeme(atto.token(s))
    _ -> lexeme(text.match(s))
  }
}

pub fn run(input: String) -> Result(Sheet, atto.ParseError(a, String)) {
  let parser = {
    use _ <- atto.do(ops.maybe(text.match("\\s*")))
    use elements <- atto.do(ops.many(element()))
    use _ <- atto.do(atto.eof())
    atto.pure(Sheet(id: "sheet", elements: elements))
  }
  atto.run(parser, text.new(input), Nil)
}

pub fn explain(err: atto.ParseError(a, String), input: String) {
  let in = text.new(input)
  error.pretty(err, in, color: False)
}

fn element() -> atto.Parser(Element, String, String, a, b) {
  ops.choice([group(), value_element()])
}

fn key() -> atto.Parser(String, String, String, a, b) {
  use matched <- atto.do(lexeme(text.match("[^\\n:\\{\\}]+")))
  atto.pure(string.trim(matched))
}

fn word() {
  lexeme(text.match("[a-zA-Z]+"))
}

fn trigger_phrase() {
  use first <- atto.do(word())
  use rest <- atto.do(ops.many(word()))
  atto.pure(string.join([first, ..rest], " "))
}

fn triggers() {
  ops.sep(trigger_phrase(), by: keyword(","))
}

fn group() -> atto.Parser(Element, String, String, a, b) {
  use _ <- atto.do(keyword("group"))
  use name <- atto.do(key())
  use _ <- atto.do(keyword("{"))
  use elements <- atto.do(ops.many(element()))
  use _ <- atto.do(keyword("}"))
  atto.pure(Group(name: name, elements: elements))
}

fn value_element() -> atto.Parser(Element, String, String, a, b) {
  use name <- atto.do(key())
  use _ <- atto.do(keyword(":"))
  use field_val <- atto.do(field_value())
  atto.pure(Value(name: name, value: field_val))
}

fn field_value() -> atto.Parser(FieldValue, String, String, a, b) {
  ops.choice([
    resource(Numeric, "resource"),
    resource(Counter, "counter"),
    link(),
    checkbox(),
    modifier_value(into: Modifier),
    integer(),
    short_text(),
    long_text(),
  ])
}

fn link() -> atto.Parser(FieldValue, String, String, a, b) {
  use <- atto.label("< link >")
  use link <- atto.do(lexeme(text.match("<[^>]*>")))
  let link_content = link |> string.drop_start(1) |> string.drop_end(1)
  atto.pure(Link(link_content))
}

fn integer() -> atto.Parser(FieldValue, String, String, a, b) {
  use digits <- atto.do(lexeme(text_util.decimal()))
  atto.pure(Integer(digits))
}

fn modifier_value(
  into constructor: fn(Int) -> field_value,
) -> atto.Parser(field_value, String, String, a, b) {
  use <- atto.label("modifier (+-N)")
  use mod_str <- atto.do(lexeme(text.match("[+-][0-9]+")))
  case int.parse(mod_str) {
    Ok(n) -> atto.pure(constructor(n))
    Error(_) -> atto.fail_msg("Could not parse modifier")
  }
}

fn checkbox() -> atto.Parser(FieldValue, String, String, a, b) {
  ops.choice([
    keyword("On") |> atto.map(fn(_) { Checkbox(On) }),
    keyword("Off") |> atto.map(fn(_) { Checkbox(Off) }),
    keyword("Special") |> atto.map(fn(_) { Checkbox(Special) }),
  ])
}

fn short_text() -> atto.Parser(FieldValue, String, String, a, b) {
  use <- atto.label("quoted text")
  use quoted <- atto.do(lexeme(text.match("\"[^\"]*\"")))
  let unquoted = quoted |> string.drop_start(1) |> string.drop_end(1)
  atto.pure(ShortText(unquoted))
}

fn long_text() -> atto.Parser(FieldValue, String, String, a, b) {
  use <- atto.label("long text wrapped in {}")
  use parens <- atto.do(lexeme(text.match("\\{[\\s\\S]*?\\}")))
  let unparens = parens |> string.drop_start(1) |> string.drop_end(1)
  atto.pure(LongText(unparens))
}

fn resource(
  kind: ResourceKind,
  keyword_name: String,
) -> atto.Parser(FieldValue, String, String, a, b) {
  use _ <- atto.do(keyword(keyword_name))
  use _ <- atto.do(keyword("{"))
  use frac <- atto.do(lexeme(text.match("[0-9]+/[0-9]+")))
  use _ <- atto.do(keyword("["))
  use triggers <- atto.do(triggers())
  use _ <- atto.do(keyword("]"))
  use recovery_kind_val <- atto.do(recovery_kind())
  use _ <- atto.do(keyword("}"))

  let parts = string.split(frac, on: "/")
  let value = case parts {
    [c, ..] -> result.unwrap(int.parse(c), 0)
    _ -> 0
  }
  let max = case parts {
    [_, m, ..] -> result.unwrap(int.parse(m), 0)
    _ -> 0
  }

  let recovery = RecoveryRule(triggers:, kind: recovery_kind_val)
  atto.pure(Resource(value:, max:, recovery:, kind:))
}

fn recovery_kind() -> atto.Parser(RecoveryKind, String, String, a, b) {
  ops.choice([
    keyword("to_full") |> atto.map(fn(_) { ToFull }),
    keyword("to_half") |> atto.map(fn(_) { ToHalfMax }),
    keyword("to_zero") |> atto.map(fn(_) { ToZero }),
    modifier_value(into: ByAmount),
  ])
}
