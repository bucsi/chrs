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
  div, fieldset, hr, input, label, legend, li, main as main_, section, textarea,
  ul,
}
import lustre/event.{on_click, on_keypress}

import chrs/sheet.{
  type Field, type FieldValue, type Group, type RecoveryKind, type Sheet,
  ByAmount, Checkbox, Counter, Field, FieldGroup, Integer, LongText, Modifier,
  Numeric, Off, On, Resource, Sheet, Special, SuperGroup, Text, ToFull,
  ToHalfMax,
}

const key_prefix = "net.bucsi.chrs.characters."

const localstorage_set_failure = "LocalStorage.set failed!"

pub type Message {
  UserEditedRawJson(raw: String)
  UserSubmittedRawJson
  UserSetResourceValue(path: List(String), value: Int)
  UserTriggeredRecovery(on: String)
  UserSetText(path: List(String), value: String)
  UserSetInteger(path: List(String), value: Int)
  UserSetModifier(path: List(String), value: Int)
  UserToggledCheckbox(path: List(String))
  UserSetLongTextValue(path: List(String), value: String)
  UserSetLongTextExcerpt(path: List(String), value: String)
  UserSetLongTextReference(path: List(String), value: String)
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
    UserEditedRawJson(raw:) ->
      case model {
        Model(..) -> Model(..model, draft_json: raw)
      }
    UserSubmittedRawJson ->
      case model {
        Model(save:, id:, draft_json:, ..) ->
          case json.parse(draft_json, sheet.decoder()) {
            Ok(new_sheet) ->
              Model(..model, sheet: save(new_sheet, id), parse_error: "")
            Error(err) -> Model(..model, parse_error: string.inspect(err))
          }
      }
    UserSetResourceValue(path:, value: new_value) ->
      case model {
        Model(sheet:, id:, save:, ..) -> {
          let new_sheet =
            Sheet(..sheet, groups: set_resource(sheet.groups, path, new_value))
          Model(..model, sheet: save(new_sheet, id))
        }
      }
    UserTriggeredRecovery(on:) -> Model(..model, action_to_confirm: on)
    UserSetText(path:, value: new) ->
      edit_field(model, path, fn(field) {
        case field.value {
          Text(_) -> Field(..field, value: Text(value: new))
          _ -> field
        }
      })
    UserSetInteger(path:, value: new) ->
      edit_field(model, path, fn(field) {
        case field.value {
          Integer(_) -> Field(..field, value: Integer(value: new))
          _ -> field
        }
      })
    UserSetModifier(path:, value: new) ->
      edit_field(model, path, fn(field) {
        case field.value {
          Modifier(_) -> Field(..field, value: Modifier(value: new))
          _ -> field
        }
      })
    UserToggledCheckbox(path:) ->
      edit_field(model, path, fn(field) {
        case field.value {
          Checkbox(value: Off) -> Field(..field, value: Checkbox(value: On))
          Checkbox(value: On) -> Field(..field, value: Checkbox(value: Off))
          Checkbox(value: Special) -> field
          _ -> panic as "unreachable"
        }
      })
    UserSetLongTextValue(path:, value: new) ->
      edit_field(model, path, fn(field) {
        case field.value {
          LongText(excerpt:, reference:, ..) ->
            Field(..field, value: LongText(value: new, excerpt:, reference:))
          _ -> field
        }
      })
    UserSetLongTextExcerpt(path:, value: new) ->
      edit_field(model, path, fn(field) {
        case field.value {
          LongText(value:, reference:, ..) ->
            Field(..field, value: LongText(value:, excerpt: new, reference:))
          _ -> field
        }
      })
    UserSetLongTextReference(path:, value: new) ->
      edit_field(model, path, fn(field) {
        case field.value {
          LongText(value:, excerpt:, ..) ->
            Field(..field, value: LongText(value:, excerpt:, reference: new))
          _ -> field
        }
      })
    UserConfirmedPendingAction -> {
      let Model(id:, sheet:, save:, ..) = model
      let new_sheet =
        Sheet(
          ..sheet,
          groups: apply_recovery(sheet.groups, model.action_to_confirm),
        )
      Model(..model, sheet: save(new_sheet, id), action_to_confirm: "")
    }
  }
}

fn edit_field(
  model: Model,
  path: List(String),
  f: fn(Field) -> Field,
) -> Model {
  case model {
    NoCharacterSelected -> model
    Model(sheet:, id:, save:, ..) -> {
      let new_sheet =
        Sheet(..sheet, groups: map_field_at(sheet.groups, path, f))
      Model(..model, sheet: save(new_sheet, id))
    }
  }
}

fn map_field_at(
  groups: List(Group),
  path: List(String),
  f: fn(Field) -> Field,
) -> List(Group) {
  case path {
    [head, ..rest] ->
      list.map(groups, fn(group) {
        case group {
          FieldGroup(name:, fields:) if name == head ->
            FieldGroup(name:, fields: map_field_in_fields(fields, rest, f))
          SuperGroup(name:, groups: subgroups) if name == head ->
            SuperGroup(name:, groups: map_field_at(subgroups, rest, f))
          _ -> group
        }
      })
    [] -> groups
  }
}

fn map_field_in_fields(
  fields: List(Field),
  path: List(String),
  f: fn(Field) -> Field,
) -> List(Field) {
  case path {
    [field_name] ->
      list.map(fields, fn(field) {
        case field.name == field_name {
          True -> f(field)
          False -> field
        }
      })
    _ -> fields
  }
}

fn set_resource(
  groups: List(Group),
  path: List(String),
  new_value: Int,
) -> List(Group) {
  use field <- map_field_at(groups, path)
  case field {
    Field(name:, value: Resource(max:, recovery:, kind:, ..)) -> {
      let clamped = case kind {
        Numeric -> int.max(new_value, 0)
        Counter -> int.clamp(new_value, min: 0, max: max)
      }
      Field(name:, value: Resource(value: clamped, max:, recovery:, kind:))
    }
    _ -> field
  }
}

fn apply_recovery(groups: List(Group), on: String) -> List(Group) {
  list.map(groups, fn(group) {
    case group {
      FieldGroup(name:, fields:) ->
        FieldGroup(name:, fields: apply_recovery_to_fields(fields, on))
      SuperGroup(name:, groups: subgroups) ->
        SuperGroup(name:, groups: apply_recovery(subgroups, on))
    }
  })
}

fn apply_recovery_to_fields(fields: List(Field), on: String) -> List(Field) {
  list.map(fields, fn(field) {
    case field {
      Field(name:, value: Resource(value:, max:, recovery:, kind:)) ->
        case list.contains(recovery.on, on) {
          True -> {
            let new_value = apply_recovery_kind(value, max, recovery.kind)
            Field(
              name:,
              value: Resource(value: new_value, max:, recovery:, kind:),
            )
          }
          False -> field
        }
      _ -> field
    }
  })
}

fn apply_recovery_kind(current: Int, max: Int, kind: RecoveryKind) -> Int {
  case kind {
    ToFull -> max
    ToHalfMax -> max / 2
    ByAmount(value: n) -> int.min(current + n, max) |> int.max(0)
  }
}

fn recovery_triggers(groups: List(Group)) -> List(String) {
  groups
  |> list.fold([], collect_triggers_from_group)
  |> list.reverse
}

fn collect_triggers_from_group(
  acc: List(String),
  group: Group,
) -> List(String) {
  case group {
    FieldGroup(fields:, ..) ->
      list.fold(fields, acc, fn(acc, field) {
        case field {
          Field(value: Resource(recovery:, ..), ..) ->
            list.fold(recovery.on, acc, fn(acc, trigger) {
              case list.contains(acc, trigger) {
                True -> acc
                False -> [trigger, ..acc]
              }
            })
          _ -> acc
        }
      })
    SuperGroup(groups: subgroups, ..) ->
      list.fold(subgroups, acc, collect_triggers_from_group)
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
      [attribute.class("groups")],
      list.map(model.sheet.groups, view_group(_, [])),
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

  let triggers = recovery_triggers(model.sheet.groups)
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
    list.fold(triggers, buttons, fn(acc, on) {
      html.button([event.on_click(UserTriggeredRecovery(on:))], [
        html.text(on),
      ])
      |> list.prepend(acc, _)
    }),
  )
}

fn view_group(
  group: Group,
  path_prefix: List(String),
) -> element.Element(Message) {
  case group {
    FieldGroup(name:, fields:) -> {
      let path = list.append(path_prefix, [name])
      fieldset([], [
        legend([], [html.text(name)]),
        ..list.map(fields, view_field(_, path))
      ])
    }
    SuperGroup(name:, groups:) -> {
      let path = list.append(path_prefix, [name])
      fieldset([], [
        legend([], [html.text(name)]),
        ..list.map(groups, view_group(_, path))
      ])
    }
  }
}

fn view_field(
  field: Field,
  path_prefix: List(String),
) -> element.Element(Message) {
  let Field(name:, value: field_value) = field
  let path = list.append(path_prefix, [name])
  let body = view_field_value(field_value, path)
  // <label> forwards clicks to its first descendant form control, which breaks Resource interactions
  let name_span = html.span([attribute.class("field-name")], [html.text(name)])
  case field_value {
    Resource(..) -> div([attribute.class("field")], [name_span, body])
    _ -> label([attribute.class("field")], [name_span, body])
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
          event.on_change(UserSetLongTextExcerpt(path:, value: _)),
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
          event.on_change(UserSetLongTextReference(path:, value: _)),
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
