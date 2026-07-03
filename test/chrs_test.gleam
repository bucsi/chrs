import chrs/sheet.{
  ByAmount, Checkbox, Counter, Field, FieldGroup, Integer, LongText, Modifier,
  Numeric, Off, On, RecoveryRule, Resource, Sheet, Special, SuperGroup, Text,
  ToFull, ToHalfMax,
}
import gleeunit

import gleam/json

pub fn main() -> Nil {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  let character =
    Sheet("human gish", [
      FieldGroup("basics", [
        Field("name", Text("John Actionman")),
        Field("species", Text("human")),
        Field("class", Text("gish")),
        Field("player", Text("Bucsi")),
        Field("level", Integer(1)),
        Field("proficiency", Modifier(2)),
        Field("inspiration", Checkbox(Off)),
      ]),
      SuperGroup("attributes", [
        FieldGroup("strength", [
          Field("Strength", Integer(10)),
          Field("Strength Modifier", Modifier(0)),
        ]),
      ]),
      SuperGroup("Saving Throws", [
        FieldGroup("strength", [
          Field("Saving Throw", Modifier(2)),
          Field("Proficient?", Checkbox(On)),
        ]),
      ]),
      FieldGroup("Senses", [
        Field("Passive Perception", Integer(9)),
        Field("Additional", Text("Darkvision 30ft.")),
      ]),
      SuperGroup("Skills", [
        FieldGroup("Acrobatics", [
          Field("mod", Modifier(2)),
          Field("ability", Text("Dex")),
          Field("proficient", Checkbox(Special)),
        ]),
      ]),

      FieldGroup("combat", [
        Field(
          "hp",
          Resource(10, 10, RecoveryRule(["longRest"], ToFull), Numeric),
        ),
        Field("ac", Integer(12)),
        Field("initiative", Modifier(2)),
      ]),

      FieldGroup("actions", [
        Field(
          "Shortsword",
          LongText(
            "+1 to hit (DEX), 1d6+2 piercing, Simple, Finesse",
            "https://5etools.bucsi.net/items.html#shortsword_xphb",
            value: "",
          ),
        ),
        Field(
          "Fire Bolt",
          LongText(
            "+8 to hit (INT), 2d10 fire, V/S, 120ft.",
            "https://li.nk",
            "",
          ),
        ),
      ]),
      FieldGroup("Proficiencies & Training", [
        Field("Armor", Text("None")),
        Field("Weapons", Text("Simple Weapons")),
        Field("Tools", Text("Calligraphers'")),
        Field("Languages", Text("Common, Elvish")),
      ]),
    ])

  assert Ok(character)
    == character
    |> sheet.to_json
    |> json.to_string
    |> echo
    |> json.parse(sheet.decoder())
}
