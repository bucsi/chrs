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
  let msg = chrs.UserSetText(["Notes"], "New")

  let assert chrs.Model(sheet: updated, ..) = chrs.update(model, msg)
  let assert [Value(_, LongText(text))] = updated.elements

  assert text == "New"
}

pub fn update_numeric_resource_test() {
  let model =
    dummy_model([
      Value(
        "HP",
        sheet.Resource(
          5,
          10,
          sheet.RecoveryRule([], sheet.ToFull),
          sheet.Numeric,
        ),
      ),
    ])
  let msg = chrs.UserSetResourceValue(["HP"], -5)
  let assert chrs.Model(sheet: updated, ..) = chrs.update(model, msg)
  let assert [Value(_, sheet.Resource(value: v, ..))] = updated.elements

  assert 0 == v
}

pub fn recovery_flow_test() {
  let rule = sheet.RecoveryRule(["long rest"], sheet.ToFull)
  let model =
    dummy_model([Value("HP", sheet.Resource(2, 10, rule, sheet.Numeric))])

  let model_pending =
    chrs.update(model, chrs.UserTriggeredRecovery("long rest"))
  let assert chrs.Model(..) = model_pending
  assert "long rest" == model_pending.action_to_confirm

  let model_confirmed =
    chrs.update(model_pending, chrs.UserConfirmedPendingAction)
  let assert chrs.Model(..) = model_confirmed
  let assert [Value(_, sheet.Resource(value: v, ..))] =
    model_confirmed.sheet.elements

  assert 10 == v
  assert "" == model_confirmed.action_to_confirm
}

pub fn toggle_checkbox_test() {
  let model = dummy_model([Value("Active", sheet.Checkbox(sheet.Off))])
  let model_on = model |> chrs.update(chrs.UserToggledCheckbox(["Active"]))
  let model_off = model_on |> chrs.update(chrs.UserToggledCheckbox(["Active"]))

  let assert chrs.Model(..) = model_on
  let assert [Value(_, sheet.Checkbox(sheet.On))] = model_on.sheet.elements
  assert model == model_off
}
