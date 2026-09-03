import atto
import atto/ops
import atto/text
import atto/text_util
import gleam/int
import gleam/list
import gleam/result
import gleam/string

// Import your custom types package/module here
import chrs/sheet.{
  type CheckboxValue, type Element, type FieldValue, type RecoveryKind,
  type RecoveryRule, type ResourceKind, type Sheet, ByAmount, Checkbox, Counter,
  Group, Integer, LongText, Modifier, NoChange, Numeric, Off, On, RecoveryRule,
  Reference, Resource, Sheet, ShortText, Special, ToFull, ToHalfMax, ToZero,
  Value,
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
  case string.length(s) {
    1 -> lexeme(atto.token(s))
    _ -> lexeme(text.match(s))
  }
}

pub fn parse_sheet(input: String) -> Result(Sheet, atto.ParseError(a, String)) {
  let parser = {
    use elements <- atto.do(ops.many(element()))
    use _ <- atto.do(atto.eof())
    atto.pure(Sheet(id: "sheet", elements: elements))
  }
  atto.run(parser, text.new(input), Nil)
}

fn element() -> atto.Parser(Element, String, String, a, b) {
  ops.choice([group(), value_element()])
}

fn key() -> atto.Parser(String, String, String, a, b) {
  use matched <- atto.do(lexeme(text.match("[^\\n:\\{\\}]+")))
  atto.pure(string.trim(matched))
}

fn group_name() {
  use matched <- atto.do(lexeme(text.match("[^\\{]+")))
  atto.pure(string.trim(matched))
}

fn group() -> atto.Parser(Element, String, String, a, b) {
  use _ <- atto.do(keyword("group"))
  use name <- atto.do(group_name())
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
    reference(),
    checkbox(),
    modifier(),
    integer(),
    short_text(),
    long_text(),
  ])
}

fn reference() {
  use matched <- atto.do(lexeme(text.match("\\[[^\\]]+\\](\\([^\\)]*\\))*")))
  case string.split_once(matched, on: "](") {
    Ok(#(left, right)) -> {
      let label = string.drop_start(left, 1) |> string.trim()
      let href = string.drop_end(right, 1) |> string.trim()
      atto.pure(Reference(label: label, href: href))
    }
    Error(Nil) -> {
      let label =
        string.drop_start(string.drop_end(matched, 1), 1) |> string.trim()
      atto.pure(Reference(label: label, href: ""))
    }
  }
}

fn integer() -> atto.Parser(FieldValue, String, String, a, b) {
  use digits <- atto.do(lexeme(text_util.decimal()))
  atto.pure(Integer(digits))
}

fn modifier() -> atto.Parser(FieldValue, String, String, a, b) {
  use mod_str <- atto.do(lexeme(text.match("[+-][0-9]+")))
  case int.parse(mod_str) {
    Ok(n) -> atto.pure(Modifier(n))
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
  use quoted <- atto.do(lexeme(text.match("\"[^\"]*\"")))
  let unquoted = quoted |> string.drop_start(1) |> string.drop_end(1)
  atto.pure(ShortText(unquoted))
}

fn long_text() -> atto.Parser(FieldValue, String, String, a, b) {
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
  use triggers <- atto.do(ops.sep(
    lexeme(text.match("[a-zA-Z_][a-zA-Z0-9_]*")),
    by: keyword(","),
  ))
  use _ <- atto.do(keyword("]"))
  use recovery_kind_val <- atto.do(recovery_kind())
  use _ <- atto.do(keyword("}"))

  let parts = string.split(frac, on: "/")
  let current = case parts {
    [c, ..] -> result.unwrap(int.parse(c), 0)
    _ -> 0
  }
  let max = case parts {
    [_, m, ..] -> result.unwrap(int.parse(m), 0)
    _ -> 0
  }

  let recovery = RecoveryRule(triggers: triggers, kind: recovery_kind_val)
  atto.pure(Resource(value: current, max: max, recovery: recovery, kind: kind))
}

fn recovery_kind() -> atto.Parser(RecoveryKind, String, String, a, b) {
  ops.choice([
    keyword("to_full") |> atto.map(fn(_) { ToFull }),
    keyword("to_half") |> atto.map(fn(_) { ToHalfMax }),
    keyword("to_zero") |> atto.map(fn(_) { ToZero }),
    keyword("no_change") |> atto.map(fn(_) { NoChange }),
    modifier_recovery(),
  ])
}

fn modifier_recovery() -> atto.Parser(RecoveryKind, String, String, a, b) {
  use mod_val <- atto.do(lexeme(text.match("[+-][0-9]+")))
  case int.parse(mod_val) {
    Ok(n) -> atto.pure(ByAmount(n))
    Error(_) -> atto.fail_msg("Could not parse modifier-based recovery")
  }
}
