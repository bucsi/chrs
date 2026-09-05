import chrs/parser
import gleam/json
import gleam/result

import chrs/sheet.{
  Checkbox, Counter, Group, Integer, Link, LongText, Modifier, Numeric, Off, On,
  RecoveryRule, Resource, Sheet, ShortText, Special, ToFull, ToZero, Value,
}

pub fn main() {
  let dsl =
    "
group example sheet with all types {
	Numeric Resource: resource { 10/10 [long rest] to_full }
    Wizard's Bane: counter { 3/5 [short rest, long rest] +1 }
    group Strength {
    	value: 10
        modifier: +0
     }
     It's: \"DnD!\"
     DnD Beyond: <ddb.ac>
     Yeah: {
     	D&D! (D&D)
		D&D Beyond
		You got your stats
		You got your swords
		And you got your invisible wand
		It's D&D (D&D)
		D&D (D&D)
		D&D Beyond
     }

}
"
  dsl |> parser.run |> result.map_error(parser.explain(_, dsl)) |> echo
}

pub fn serah_test() {
  let character =
    Sheet("serah", [
      Group("basics", [
        Value("name", ShortText("Serah Vidunder")),
        Value("species", ShortText("Human")),
        Value("class", ShortText("Wizard (Abjurer)")),
        Value("player", ShortText("Bucsi")),
        Value("level", Integer(7)),
        Value("proficiency", Modifier(3)),
        Value("inspiration", Checkbox(Off)),
      ]),
      Group("attributes", [
        Group("strength", [
          Value("Strength", Integer(10)),
          Value("Strength Modifier", Modifier(0)),
        ]),
        Group("dexterity", [
          Value("Dexterity", Integer(15)),
          Value("Dexterity Modifier", Modifier(2)),
        ]),
        Group("constitution", [
          Value("Constitution", Integer(14)),
          Value("Constitution Modifier", Modifier(2)),
        ]),
        Group("intelligence", [
          Value("Intelligence", Integer(20)),
          Value("Intelligence Modifier", Modifier(5)),
        ]),
        Group("wisdom", [
          Value("Wisdom", Integer(8)),
          Value("Wisdom Modifier", Modifier(-1)),
        ]),
        Group("charisma", [
          Value("Charisma", Integer(12)),
          Value("Charisma Modifier", Modifier(1)),
        ]),
      ]),
      Group("Saving Throws", [
        Group("strength", [
          Value("Saving Throw", Modifier(0)),
          Value("Proficient?", Checkbox(Off)),
        ]),
        Group("dexterity", [
          Value("Saving Throw", Modifier(2)),
          Value("Proficient?", Checkbox(Off)),
        ]),
        Group("constitution", [
          Value("Saving Throw", Modifier(2)),
          Value("Proficient?", Checkbox(Off)),
        ]),
        Group("intelligence", [
          Value("Saving Throw", Modifier(8)),
          Value("Proficient?", Checkbox(On)),
        ]),
        Group("wisdom", [
          Value("Saving Throw", Modifier(2)),
          Value("Proficient?", Checkbox(On)),
        ]),
        Group("charisma", [
          Value("Saving Throw", Modifier(1)),
          Value("Proficient?", Checkbox(Off)),
        ]),
      ]),
      Group("Senses", [
        Value("Passive Perception", Integer(9)),
        Value("Passive Investigation", Integer(21)),
        Value("Passive Insight", Integer(9)),
        Value("Additional", ShortText("")),
      ]),
      Group("Skills", [
        Group("Acrobatics", [
          Value("mod", Modifier(2)),
          Value("ability", ShortText("Dex")),
          Value("proficient", Checkbox(Off)),
        ]),
        Group("Animal Handling", [
          Value("mod", Modifier(-1)),
          Value("ability", ShortText("Wis")),
          Value("proficient", Checkbox(Off)),
        ]),
        Group("Arcana", [
          Value("mod", Modifier(8)),
          Value("ability", ShortText("Int")),
          Value("proficient", Checkbox(On)),
        ]),
        Group("Athletics", [
          Value("mod", Modifier(0)),
          Value("ability", ShortText("Str")),
          Value("proficient", Checkbox(Off)),
        ]),
        Group("Deception", [
          Value("mod", Modifier(1)),
          Value("ability", ShortText("Cha")),
          Value("proficient", Checkbox(Off)),
        ]),
        Group("History", [
          Value("mod", Modifier(8)),
          Value("ability", ShortText("Int")),
          Value("proficient", Checkbox(On)),
        ]),
        Group("Insight", [
          Value("mod", Modifier(-1)),
          Value("ability", ShortText("")),
          Value("proficient", Checkbox(Off)),
        ]),
        Group("Intimidation", [
          Value("mod", Modifier(1)),
          Value("ability", ShortText("Cha")),
          Value("proficient", Checkbox(Off)),
        ]),
        Group("Investigation", [
          Value("mod", Modifier(11)),
          Value("ability", ShortText("Int")),
          Value("proficient", Checkbox(Special)),
        ]),
        Group("Medicine", [
          Value("mod", Modifier(2)),
          Value("ability", ShortText("Wis")),
          Value("proficient", Checkbox(On)),
        ]),
        Group("Nature", [
          Value("mod", Modifier(8)),
          Value("ability", ShortText("Int")),
          Value("proficient", Checkbox(On)),
        ]),
        Group("Perception", [
          Value("mod", Modifier(-1)),
          Value("ability", ShortText("Wis")),
          Value("proficient", Checkbox(Off)),
        ]),
        Group("Performance", [
          Value("mod", Modifier(1)),
          Value("ability", ShortText("Cha")),
          Value("proficient", Checkbox(Off)),
        ]),
        Group("Persuasion", [
          Value("mod", Modifier(1)),
          Value("ability", ShortText("Cha")),
          Value("proficient", Checkbox(Off)),
        ]),
        Group("Religion", [
          Value("mod", Modifier(5)),
          Value("ability", ShortText("Int")),
          Value("proficient", Checkbox(Off)),
        ]),
        Group("Sleight of Hand", [
          Value("mod", Modifier(2)),
          Value("ability", ShortText("Dex")),
          Value("proficient", Checkbox(Off)),
        ]),
        Group("Stealth", [
          Value("mod", Modifier(2)),
          Value("ability", ShortText("Dex")),
          Value("proficient", Checkbox(Off)),
        ]),
        Group("Survival", [
          Value("mod", Modifier(-1)),
          Value("ability", ShortText("Wis")),
          Value("proficient", Checkbox(Off)),
        ]),
      ]),

      Group("combat", [
        Value(
          "hp",
          Resource(28, 44, RecoveryRule(["Long Rest"], ToFull), Numeric),
        ),
        Value("ac", Integer(15)),
        Value("initiative", Modifier(2)),
        Value("Speed", Integer(30)),
        Value("Hit Die", ShortText("d8")),
        Value(
          "Hit Dice",
          Resource(7, 7, RecoveryRule(["Long Rest"], ToFull), Counter),
        ),
        Value(
          "Arcane Ward",
          Resource(19, 19, RecoveryRule(["Long Rest"], ToZero), Numeric),
        ),
        Value(
          "Arcane Ward Charges",
          Resource(1, 1, RecoveryRule(["Long Rest"], ToFull), Counter),
        ),
        Value("Defenses", ShortText("")),
        Value("Conditions", ShortText("")),
      ]),

      Group("actions", [
        Group("Dagger", [
          Value(
            "properties",
            ShortText(
              "+5 to hit (DEX), 1d4+2 piercing, 20/60ft, Finesse, Light, Thrown",
            ),
          ),
          Value(
            "reference",
            sheet.Link(href: "https://5etools.bucsi.net/items.html#dagger_xphb"),
          ),
        ]),
      ]),
      Group("Proficiencies & Training", [
        Value("Armor", ShortText("None")),
        Value("Weapons", ShortText("Simple Weapons")),
        Value("Tools", ShortText("Calligraphers'")),
        Value("Languages", ShortText("Common, Elvish")),
      ]),
    ])

  assert Ok(character)
    == character
    |> sheet.to_json
    |> json.to_string
    |> echo
    |> json.parse(sheet.decoder())
}

pub fn rob_morgan_test() {
  let character =
    Sheet("Rob Morgan", [
      Group("Details", [
        Value("Level", Integer(2)),
        Value("Class", ShortText("Necromancer")),
        Value("Ancestry", ShortText("Human")),
        Value("Background", ShortText("Necromancer")),
      ]),
    ])
}
