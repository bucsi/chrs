import gleam/bool
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import gleam/string

import lanyard.{NanoID}
import plinth/browser/location
import plinth/browser/window
import plinth/javascript/console
import plinth/javascript/storage
import varasto

import lustre
import lustre/attribute.{checked, readonly, type_, value}
import lustre/element
import lustre/element/html.{
  div, fieldset, input, label, legend, main as main_, section, textarea,
}
import lustre/event

import chrs/sheet.{
  type Element, type FieldValue, type RecoveryKind, type Sheet, ByAmount,
  Checkbox, Counter, Group, Integer, LongText, Modifier, Numeric, Off, On,
  Resource, Sheet, Special, Text, ToFull, ToHalfMax, ToZero, Value,
}

const key_prefix = "net.bucsi.chrs.characters."

const localstorage_set_failure = "LocalStorage.set failed!"

pub type Message {
  UserEditedRawJson(raw: String)
  UserSubmittedRawJson
  UserSetResourceValue(path: List(String), value: Int)
  UserTriggeredRecovery(trigger: String)
  UserSetText(path: List(String), value: String)
  UserSetInteger(path: List(String), value: Int)
  UserSetModifier(path: List(String), value: Int)
  UserToggledCheckbox(path: List(String))
  UserSetLongTextValue(path: List(String), value: String)
  UserSetLongTextExcerpt(path: List(String), excerpt: String)
  UserSetLongTextReference(path: List(String), reference: String)
  UserConfirmedPendingAction
  Nothing
}

pub type Model {
  Model(
    save: fn(Sheet, String) -> Sheet,
    sheet: Sheet,
    id: String,
    draft_json: String,
    parse_error: String,
    action_to_confirm: String,
  )
  NoCharacterSelected
}

pub fn main() {
  let app = lustre.simple(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  window.add_event_listener("hashchange", fn(_event) {
    window.self()
    |> window.location()
    |> location.reload()
  })

  Nil
}

fn init(_flags: a) -> Model {
  let hash =
    window.self()
    |> window.location()
    |> location.hash()

  console.debug("hash: " <> hash |> result.unwrap("error"))
  case hash {
    Ok(str) if str != "" -> do_init(str)
    _ -> NoCharacterSelected
  }
}

fn do_init(local_id: String) -> Model {
  console.debug("do_init")
  let assert Ok(local) = storage.local()
  let typed_storage = varasto.new(local, sheet.decoder(), sheet.to_json)

  let save = fn(new_sheet: Sheet, id: String) -> Sheet {
    case varasto.set(typed_storage, key_prefix <> id, new_sheet) {
      Ok(_) -> new_sheet
      Error(_) -> {
        console.error(localstorage_set_failure)
        console.log(new_sheet |> sheet.to_json |> json.to_string)
        panic as localstorage_set_failure
      }
    }
  }

  let sheet = case typed_storage |> varasto.get(key_prefix <> local_id) {
    Ok(value) -> value
    Error(varasto.NotFound) -> {
      console.debug("No saved sheet found, starting fresh.")
      save(Sheet(local_id, []), local_id)
    }
    Error(err) -> {
      console.error("varasto.get failed: " <> string.inspect(err))
      panic as "varasto.get failed"
    }
  }

  Model(
    save:,
    sheet:,
    id: local_id,
    draft_json: sheet |> sheet.to_json |> json.to_string,
    parse_error: "",
    action_to_confirm: "",
  )
}

fn update(model: Model, msg: Message) -> Model {
  use <- bool.guard(when: model == NoCharacterSelected, return: model)
  let assert Model(..) = model

  case msg {
    Nothing -> model
    UserEditedRawJson(raw:) -> Model(..model, draft_json: raw)
    UserSubmittedRawJson ->
      case json.parse(model.draft_json, sheet.decoder()) {
        Ok(new_sheet) -> {
          let Model(save:, id:, ..) = model
          Model(..model, sheet: save(new_sheet, id), parse_error: "")
        }
        Error(err) -> Model(..model, parse_error: string.inspect(err))
      }
    UserSetResourceValue(path:, value:) -> set_resource(model, path, value)
    UserTriggeredRecovery(trigger:) ->
      Model(..model, action_to_confirm: trigger)
    UserSetText(path:, value:) -> set_text(model, path, value)
    UserSetInteger(path:, value:) -> set_integer(model, path, value)
    UserSetModifier(path:, value:) -> set_modifier(model, path, value)
    UserToggledCheckbox(path:) -> toggle_checkbox(model, path)
    UserSetLongTextValue(path:, value:) ->
      set_long_text_value(model, path, value)
    UserSetLongTextExcerpt(path:, excerpt:) ->
      set_long_text_excerpt(model, path, excerpt)
    UserSetLongTextReference(path:, reference:) ->
      set_long_text_reference(model, path, reference)
    UserConfirmedPendingAction -> {
      let Model(id:, sheet:, save:, ..) = model
      let new_sheet =
        Sheet(
          ..sheet,
          elements: apply_recovery(sheet.elements, model.action_to_confirm),
        )
      Model(..model, sheet: save(new_sheet, id), action_to_confirm: "")
    }
  }
}

fn update_elements(
  model: Model,
  updater: fn(List(Element)) -> List(Element),
) -> Model {
  case model {
    NoCharacterSelected -> model
    Model(sheet:, id:, save:, ..) -> {
      let new_sheet = Sheet(..sheet, elements: updater(sheet.elements))
      Model(..model, sheet: save(new_sheet, id))
    }
  }
}

fn set_text(model: Model, path: List(String), value: String) -> Model {
  use elements <- update_elements(model)
  use field_value <- update_value_at(elements, path)
  case field_value {
    Text(_) -> Text(value:)
    other -> other
  }
}

fn set_integer(model: Model, path: List(String), value: Int) -> Model {
  use elements <- update_elements(model)
  use field_value <- update_value_at(elements, path)
  case field_value {
    Integer(_) -> Integer(value:)
    other -> other
  }
}

fn set_modifier(model: Model, path: List(String), value: Int) -> Model {
  use elements <- update_elements(model)
  use field_value <- update_value_at(elements, path)
  case field_value {
    Modifier(_) -> Modifier(value:)
    other -> other
  }
}

fn toggle_checkbox(model: Model, path: List(String)) -> Model {
  use elements <- update_elements(model)
  use field_value <- update_value_at(elements, path)
  case field_value {
    Checkbox(value: Off) -> Checkbox(value: On)
    Checkbox(value: On) -> Checkbox(value: Off)
    Checkbox(value: Special) -> Checkbox(value: Special)
    other -> other
  }
}

fn set_long_text_value(
  model: Model,
  path: List(String),
  value: String,
) -> Model {
  use elements <- update_elements(model)
  use field_value <- update_value_at(elements, path)
  case field_value {
    LongText(..) as self -> LongText(..self, value:)
    other -> other
  }
}

fn set_long_text_excerpt(
  model: Model,
  path: List(String),
  excerpt: String,
) -> Model {
  use elements <- update_elements(model)
  use field_value <- update_value_at(elements, path)
  case field_value {
    LongText(..) as self -> LongText(..self, excerpt:)
    other -> other
  }
}

fn set_long_text_reference(
  model: Model,
  path: List(String),
  reference: String,
) -> Model {
  use elements <- update_elements(model)
  use field_value <- update_value_at(elements, path)
  case field_value {
    LongText(..) as self -> LongText(..self, reference:)
    other -> other
  }
}

fn set_resource(model: Model, path: List(String), new_value: Int) -> Model {
  use elements <- update_elements(model)
  set_resource_at(elements, path, new_value)
}

fn update_value_at(
  elements: List(Element),
  path: List(String),
  updater: fn(FieldValue) -> FieldValue,
) -> List(Element) {
  case path {
    [head, ..rest] -> do_update_value_at(elements, head, rest, updater)
    [] -> elements
  }
}

fn do_update_value_at(
  elements: List(Element),
  head: String,
  rest: List(String),
  updater: fn(FieldValue) -> FieldValue,
) -> List(Element) {
  list.map(elements, fn(element) {
    case element {
      Group(name:, elements: nested) if name == head ->
        Group(name:, elements: update_value_at(nested, rest, updater))
      Value(name:, value: field_value) if name == head ->
        Value(name:, value: updater(field_value))
      _ -> element
    }
  })
}

fn set_resource_at(
  elements: List(Element),
  path: List(String),
  new_value: Int,
) -> List(Element) {
  case path {
    [head, ..rest] -> do_set_resource_at(elements, head, rest, new_value)
    [] -> elements
  }
}

fn do_set_resource_at(
  elements: List(Element),
  head: String,
  rest: List(String),
  new_value: Int,
) -> List(Element) {
  use element <- list.map(elements)
  case element {
    Group(name:, elements: nested) if name == head ->
      Group(name:, elements: set_resource_at(nested, rest, new_value))
    Value(name:, value: field_value) if name == head ->
      case field_value {
        Resource(max:, recovery:, kind:, ..) -> {
          let clamped = case kind {
            Numeric -> int.max(new_value, 0)
            Counter -> int.clamp(new_value, min: 0, max: max)
          }
          Value(name:, value: Resource(value: clamped, max:, recovery:, kind:))
        }
        _ -> element
      }
    _ -> element
  }
}

fn apply_recovery(elements: List(Element), trigger: String) -> List(Element) {
  use element <- list.map(elements)
  case element {
    Group(name:, elements: nested) ->
      Group(name:, elements: apply_recovery(nested, trigger))
    Value(name:, value: Resource(value:, max:, recovery:, kind:)) -> {
      case list.contains(recovery.triggers, trigger) {
        False -> element
        True ->
          Value(
            name:,
            value: Resource(
              value: apply_recovery_kind(value, max, recovery.kind),
              max:,
              recovery:,
              kind:,
            ),
          )
      }
    }
    Value(..) -> element
  }
}

fn apply_recovery_kind(current: Int, max: Int, kind: RecoveryKind) -> Int {
  case kind {
    ToFull -> max
    ToHalfMax -> max / 2
    ByAmount(value: n) -> int.min(current + n, max) |> int.max(0)
    ToZero -> 0
  }
}

fn recovery_triggers(elements: List(Element)) -> List(String) {
  elements
  |> list.fold([], collect_triggers_from_element)
  |> list.reverse
}

fn collect_triggers_from_element(
  acc: List(String),
  element: Element,
) -> List(String) {
  case element {
    Value(value: Resource(recovery:, ..), ..) ->
      list.fold(recovery.triggers, acc, fn(acc, trigger) {
        case list.contains(acc, trigger) {
          True -> acc
          False -> [trigger, ..acc]
        }
      })
    Value(..) -> acc
    Group(elements: nested, ..) ->
      list.fold(nested, acc, collect_triggers_from_element)
  }
}

fn view(model: Model) {
  use <- bool.guard(
    when: model == NoCharacterSelected,
    return: view_no_character_selected(),
  )
  let assert Model(..) = model

  main_([], [
    view_recovery_bar(model),
    div(
      [attribute.class("fields")],
      list.map(model.sheet.elements, view_element(_, [])),
    ),
    html.details([attribute.class("raw-json")], [
      html.summary([], [html.text("raw json")]),
      textarea([event.on_input(UserEditedRawJson)], model.draft_json),
      case model.parse_error {
        err if err != "" -> html.pre([], [html.text(err)])
        _ -> element.none()
      },
      html.button([event.on_click(UserSubmittedRawJson)], [
        html.text("apply"),
      ]),
    ]),
  ])
}

fn view_recovery_bar(model: Model) -> element.Element(Message) {
  let assert Model(..) = model
    as "view_recovery_bar should be only called when we have a character sheet selected"

  let triggers = recovery_triggers(model.sheet.elements)
  use <- bool.guard(when: triggers == [], return: element.none())

  let buttons = case model.action_to_confirm {
    "" -> [element.none()]
    _ -> [
      html.button([event.on_click(UserConfirmedPendingAction)], [
        html.text("Confirm: "),
        html.code([], [html.text(model.action_to_confirm)]),
        html.text("?"),
      ]),
    ]
  }

  div(
    [attribute.class("recovery-bar"), attribute.role("group")],
    list.fold(triggers, buttons, fn(acc, trigger) {
      html.button([event.on_click(UserTriggeredRecovery(trigger:))], [
        html.text(trigger),
      ])
      |> list.prepend(acc, _)
    }),
  )
}

fn view_element(
  element: Element,
  path_prefix: List(String),
) -> element.Element(Message) {
  case element {
    Value(name:, value: field_value) -> {
      let path = list.append(path_prefix, [name])
      let body = view_field_value(field_value, path)
      let name_span =
        html.span([attribute.class("field-name")], [html.text(name)])
      case field_value {
        Resource(..) -> div([attribute.class("field")], [name_span, body])
        _ -> label([attribute.class("field")], [name_span, body])
      }
    }
    Group(name:, elements: nested) -> {
      let path = list.append(path_prefix, [name])
      fieldset([], [
        legend([], [html.text(name)]),
        ..list.map(nested, view_element(_, path))
      ])
    }
  }
}

fn view_field_value(
  field_value: FieldValue,
  path: List(String),
) -> element.Element(Message) {
  case field_value {
    Text(value: v) ->
      input([
        type_("text"),
        attribute.value(v),
        event.on_change(UserSetText(path:, value: _)),
      ])
    LongText(value:, excerpt:, reference:) -> {
      let excerpt_input =
        input([
          type_("text"),
          attribute.value(excerpt),
          event.on_change(UserSetLongTextExcerpt(path:, excerpt: _)),
        ])
      let value_textarea =
        textarea(
          [event.on_change(UserSetLongTextValue(path:, value: _))],
          value,
        )
      let reference_input =
        input([
          type_("text"),
          attribute.placeholder("reference url"),
          attribute.value(reference),
          event.on_change(UserSetLongTextReference(path:, reference: _)),
        ])
      let reference_link = case reference {
        "" -> element.none()
        _ ->
          html.a([attribute.href(reference), attribute.target("_blank")], [
            html.text("ref"),
          ])
      }
      div([], [
        excerpt_input,
        html.details([], [
          html.summary([], [html.text("details")]),
          value_textarea,
          div([], [reference_input, reference_link]),
        ]),
      ])
    }

    Integer(value: v) ->
      input([
        type_("number"),
        attribute.value(int.to_string(v)),
        event.on_change(fn(str) {
          case int.parse(str) {
            Ok(n) -> UserSetInteger(path:, value: n)
            Error(_) -> Nothing
          }
        }),
      ])
    Modifier(value: v) ->
      input([
        type_("number"),
        attribute.value(int.to_string(v)),
        event.on_change(fn(str) {
          case int.parse(str) {
            Ok(n) -> UserSetModifier(path:, value: n)
            Error(_) -> Nothing
          }
        }),
      ])
    Checkbox(value: cb) ->
      case cb {
        Off ->
          input([
            type_("checkbox"),
            event.on_click(UserToggledCheckbox(path:)),
          ])
        On ->
          input([
            type_("checkbox"),
            checked(True),
            event.on_click(UserToggledCheckbox(path:)),
          ])
        Special ->
          div([], [
            input([
              type_("checkbox"),
              checked(True),
              readonly(True),
              attribute.disabled(True),
            ]),
            html.small([], [html.text(" (special)")]),
          ])
      }
    Resource(value: v, max:, recovery: _, kind:) ->
      case kind {
        Numeric -> view_numeric_resource(path, v, max)
        Counter -> view_counter_resource(path, v, max)
      }
  }
}

fn view_numeric_resource(
  path: List(String),
  current: Int,
  max: Int,
) -> element.Element(Message) {
  let parse_change = fn(str: String) -> Message {
    case int.parse(str) {
      Ok(n) -> UserSetResourceValue(path:, value: n)
      Error(_) -> Nothing
    }
  }
  div([attribute.class("resource numeric"), attribute.role("group")], [
    html.button(
      [event.on_click(UserSetResourceValue(path:, value: current - 1))],
      [
        html.text("-"),
      ],
    ),
    input([
      type_("number"),
      value(int.to_string(current)),
      attribute.classes([#("over", current > max)]),
      event.on_change(parse_change),
    ]),
    html.button(
      [event.on_click(UserSetResourceValue(path:, value: current + 1))],
      [
        html.text("+"),
      ],
    ),
    html.span([], [html.text(" / " <> int.to_string(max))]),
  ])
}

fn view_counter_resource(
  path: List(String),
  current: Int,
  max: Int,
) -> element.Element(Message) {
  let pips =
    int.range(from: max, to: 0, with: [], run: list.prepend)
    |> list.map(fn(i) {
      let is_filled = i <= current
      let target = case is_filled {
        True -> i - 1
        False -> i
      }
      input([
        type_("checkbox"),
        checked(is_filled),
        event.on_click(UserSetResourceValue(path:, value: target)),
      ])
    })
  div([attribute.class("resource counter"), attribute.role("group")], pips)
}

fn view_no_character_selected() {
  let NanoID(first4) = lanyard.custom_length(4)
  let NanoID(last4) = lanyard.custom_length(4)
  let id = first4 <> "-" <> last4
  div([], [
    section([], [
      html.text(
        "No character selected. Please select a character, or create a new one with id: ",
      ),
      html.a([attribute.href("/#" <> id)], [html.text(id)]),
    ]),
  ])
}
