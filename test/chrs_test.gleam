import chrs
import chrs/sheet.{Group, Link, LongText, Sheet, Value}
import gleam/string
import lustre/element

import gleeunit

pub fn main() {
  gleeunit.main()
}

fn dummy_model(elements) -> chrs.Model {
  chrs.Model(
    save: fn(s, _id) { s },
    sheet: Sheet("test-id", elements),
    id: "test-id",
    draft_json: "",
    parse_error: "",
    action_to_confirm: "",
  )
}

pub fn view_long_text_test() {
  let model = dummy_model([Value("Backstory", LongText("A tragic tale"))])

  let html_output =
    chrs.view(model)
    |> element.to_string

  assert html_output |> string.contains("A tragic tale")
  assert html_output |> string.contains("textarea")
}

pub fn view_link_test() {
  let model = dummy_model([Value("Website", Link("https://dndbeyond.com"))])

  let html_output =
    chrs.view(model)
    |> element.to_string

  assert html_output
    |> string.contains("href=\"https://dndbeyond.com\"")
}

pub fn update_long_text_test() {
  let model = dummy_model([Value("Notes", LongText("Old"))])
  let msg = chrs.UserEditedLongText(["Notes"], "New")

  // Fails until `set_text` is updated to handle LongText
  let assert chrs.Model(sheet: updated, ..) = chrs.update(model, msg)
  let assert [Value(_, LongText(text))] = updated.elements

  assert text == "New"
}
