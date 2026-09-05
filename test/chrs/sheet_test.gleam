import chrs/sheet.{
  ByAmount, Checkbox, Counter, Group, Integer, Link, LongText, Modifier, Numeric,
  Off, On, RecoveryRule, Resource, Sheet, ShortText, Special, ToFull, ToHalfMax,
  ToZero, Value,
}
import gleeunit

import gleam/json

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn round_trip_test() {
  let sheet =
    Sheet(id: "sheet", elements: [
      Group(name: "example sheet with all types", elements: [
        Value(
          name: "Numeric Resource",
          value: Resource(
            value: 10,
            max: 10,
            recovery: RecoveryRule(triggers: ["long rest"], kind: ToFull),
            kind: Numeric,
          ),
        ),
        Value(
          name: "Wizard's Bane",
          value: Resource(
            value: 3,
            max: 5,
            recovery: RecoveryRule(
              triggers: ["short rest", "long rest"],
              kind: ByAmount(value: 1),
            ),
            kind: Counter,
          ),
        ),
        Group(name: "Strength", elements: [
          Value(name: "value", value: Integer(value: 10)),
          Value(name: "modifier", value: Modifier(value: 0)),
        ]),
        Value(name: "It's", value: ShortText(value: "DnD!")),
        Value(name: "DnD Beyond", value: Link(href: "ddb.ac")),
        Value(
          name: "Yeah",
          value: LongText(
            value: "\n     \tD&D! (D&D)\n\t\tD&D Beyond\n\t\tYou got your stats\n\t\tYou got your swords\n\t\tAnd you got your invisible wand\n\t\tIt's D&D (D&D)\n\t\tD&D (D&D)\n\t\tD&D Beyond\n     ",
          ),
        ),
      ]),
    ])

  let expected =
    Ok(
      Sheet(id: "sheet", elements: [
        Group(name: "example sheet with all types", elements: [
          Value(
            name: "Numeric Resource",
            value: Resource(
              value: 10,
              max: 10,
              recovery: RecoveryRule(triggers: ["long rest"], kind: ToFull),
              kind: Numeric,
            ),
          ),
          Value(
            name: "Wizard's Bane",
            value: Resource(
              value: 3,
              max: 5,
              recovery: RecoveryRule(
                triggers: ["short rest", "long rest"],
                kind: ByAmount(value: 1),
              ),
              kind: Counter,
            ),
          ),
          Group(name: "Strength", elements: [
            Value(name: "value", value: Integer(value: 10)),
            Value(name: "modifier", value: Modifier(value: 0)),
          ]),
          Value(name: "It's", value: ShortText(value: "DnD!")),
          Value(name: "DnD Beyond", value: Link(href: "ddb.ac")),
          Value(
            name: "Yeah",
            value: LongText(
              value: "\n     \tD&D! (D&D)\n\t\tD&D Beyond\n\t\tYou got your stats\n\t\tYou got your swords\n\t\tAnd you got your invisible wand\n\t\tIt's D&D (D&D)\n\t\tD&D (D&D)\n\t\tD&D Beyond\n     ",
            ),
          ),
        ]),
      ]),
    )

  assert expected
    == sheet |> sheet.to_json |> json.to_string |> json.parse(sheet.decoder())
}
