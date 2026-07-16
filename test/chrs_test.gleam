import chrs/sheet.{
  ByAmount, Checkbox, Counter, Value, Integer, LongText, Modifier,
  Numeric, Off, On, RecoveryRule, Resource, Sheet, Special, Text,
  ToFull, ToHalfMax, ToZero, Group
}
import gleeunit

import gleam/json

pub fn main() -> Nil {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn serah_test() {
  let character =
    Sheet("serah", [
      Group("basics", [
        Value("name", Text("Serah Vidunder")),
        Value("species", Text("Human")),
        Value("class", Text("Wizard (Abjurer)")),
        Value("player", Text("Bucsi")),
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
        Value("Additional", Text("")),
      ]),
      Group("Skills", [
        Group("Acrobatics", [
          Value("mod", Modifier(2)),
          Value("ability", Text("Dex")),
          Value("proficient", Checkbox(Off)),
        ]),
        Group("Animal Handling", [
          Value("mod", Modifier(-1)),
          Value("ability", Text("Wis")),
          Value("proficient", Checkbox(Off)),
        ]),
        Group("Arcana", [
          Value("mod", Modifier(8)),
          Value("ability", Text("Int")),
          Value("proficient", Checkbox(On)),
        ]),
        Group("Athletics", [
          Value("mod", Modifier(0)),
          Value("ability", Text("Str")),
          Value("proficient", Checkbox(Off)),
        ]),
        Group("Deception", [
          Value("mod", Modifier(1)),
          Value("ability", Text("Cha")),
          Value("proficient", Checkbox(Off)),
        ]),
        Group("History", [
          Value("mod", Modifier(8)),
          Value("ability", Text("Int")),
          Value("proficient", Checkbox(On)),
        ]),
        Group("Insight", [
          Value("mod", Modifier(-1)),
          Value("ability", Text("")),
          Value("proficient", Checkbox(Off)),
        ]),
        Group("Intimidation", [
          Value("mod", Modifier(1)),
          Value("ability", Text("Cha")),
          Value("proficient", Checkbox(Off)),
        ]),
        Group("Investigation", [
          Value("mod", Modifier(11)),
          Value("ability", Text("Int")),
          Value("proficient", Checkbox(Special)),
        ]),
        Group("Medicine", [
          Value("mod", Modifier(2)),
          Value("ability", Text("Wis")),
          Value("proficient", Checkbox(On)),
        ]),
        Group("Nature", [
          Value("mod", Modifier(8)),
          Value("ability", Text("Int")),
          Value("proficient", Checkbox(On)),
        ]),
        Group("Perception", [
          Value("mod", Modifier(-1)),
          Value("ability", Text("Wis")),
          Value("proficient", Checkbox(Off)),
        ]),
        Group("Performance", [
          Value("mod", Modifier(1)),
          Value("ability", Text("Cha")),
          Value("proficient", Checkbox(Off)),
        ]),
        Group("Persuasion", [
          Value("mod", Modifier(1)),
          Value("ability", Text("Cha")),
          Value("proficient", Checkbox(Off)),
        ]),
        Group("Religion", [
          Value("mod", Modifier(5)),
          Value("ability", Text("Int")),
          Value("proficient", Checkbox(Off)),
        ]),
        Group("Sleight of Hand", [
          Value("mod", Modifier(2)),
          Value("ability", Text("Dex")),
          Value("proficient", Checkbox(Off)),
        ]),
        Group("Stealth", [
          Value("mod", Modifier(2)),
          Value("ability", Text("Dex")),
          Value("proficient", Checkbox(Off)),
        ]),
        Group("Survival", [
          Value("mod", Modifier(-1)),
          Value("ability", Text("Wis")),
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
        Value("Hit Die", Text("d8")),
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
        Value("Defenses", Text("")),
        Value("Conditions", Text("")),
      ]),

      Group("actions", [
        Value(
          "Dagger",
          LongText(
            "+5 to hit (DEX), 1d4+2 piercing, 20/60ft.",
            "https://5etools.bucsi.net/items.html#dagger_xphb",
            "Finesse, Light, Thrown",
          ),
        ),
        Value(
          "Fire Bolt",
          LongText(
            "+8 to hit (INT), 2d10 fire, V/S, 120ft.",
            "https://li.nk",
            "You hurl a mote of fire at a creature or an object within range. Make a ranged spell attack against the target. On a hit, the target takes 1d10 Fire damage. A flammable object hit by this spell starts burning if it isn’t being worn or carried.\nCantrip Upgrade: The damage increases by 1d10 when you reach levels 5 (2d10), 11 (3d10), and 17 (4d10).",
          ),
        ),
        Value(
          "Toll the Dead",
          LongText(
            "DC 16 WIS, 2d8/2d12 necrotic, V/S, 60ft.",
            "https://li.nk",
            "You point at one creature you can see within range, and the single chime of a dolorous bell is audible within 10 feet of the target. The target must succeed on a Wisdom saving throw or take 1d8 Necrotic damage. If the target is missing any of its Hit Points, it instead takes 1d12 Necrotic damage.\nCantrip Upgrade: The damage increases by one die when you reach levels 5 (2d8 or 2d12), 11 (3d8 or 3d12), and 17 (4d8 or 4d12).",
          ),
        ),
        Value(
          "Mind Sliver",
          LongText(
            "DC 16 INT, 2d6 psychic, -1d4 next save, V, 60ft.",
            "https://li.nk",
            "You try to temporarily sliver the mind of one creature you can see within range. The target must succeed on an Intelligence saving throw or take 1d6 Psychic damage and subtract 1d4 from the next saving throw it makes before the end of your next turn.\nCantrip Upgrade: The damage increases by 1d6 when you reach levels 5 (2d6), 11 (3d6), and 17 (4d6).",
          ),
        ),
      ]),
      Group("Proficiencies & Training", [
        Value("Armor", Text("None")),
        Value("Weapons", Text("Simple Weapons")),
        Value("Tools", Text("Calligraphers'")),
        Value("Languages", Text("Common, Elvish")),
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
  let character = Sheet("Rob Morgan", [
    Group("Details", [
      Value("Level", Integer(2)),
      Value("Class", Text("Necromancer")),
      Value("Ancestry", Text("Human")),
      Value("Background", Text("Necromancer")),

    ])
  ])
}
