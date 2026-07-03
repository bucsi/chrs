import gleam/bool
import gleam/dict
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option
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
  div, fieldset, hr, input, label, legend, li, section, textarea, ul,
}
import lustre/event.{on_click, on_keypress}

import chrs/sheet.{
  type Field, type FieldValue, type Group, type Sheet, Checkbox, Field,
  FieldGroup, Integer, LongText, Modifier, Off, On, Resource, Sheet, Special,
  SuperGroup, Text,
}

const key_prefix = "net.bucsi.chrs.characters."

const localstorage_set_failure = "LocalStorage.set failed!"

pub type Message {
  //   UserUpdatedCurrentlyEditedTask(currently_edited_task: String)
  //   UserSavedCurrentlyEditedTask
  UserEditedRawJson(raw: String)
  UserSubmittedRawJson
  Nothing
}

// pub type NewTaskData {
//   NewTaskData(description: String)
// }

pub type Model {
  Model(
    save: fn(Sheet, String) -> Sheet,
    sheet: Sheet,
    id: String,
    draft_json: String,
    parse_error: String,
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
    Error(_) -> {
      console.debug("No saved sheet found, starting fresh.")
      save(Sheet(local_id, []), local_id)
    }
  }

  Model(
    save:,
    sheet:,
    id: local_id,
    draft_json: sheet |> sheet.to_json |> json.to_string,
    parse_error: "",
  )
}

fn update(model: Model, msg: Message) -> Model {
  case msg {
    Nothing -> model
    UserEditedRawJson(raw:) ->
      case model {
        NoCharacterSelected -> model
        Model(..) -> Model(..model, draft_json: raw)
      }
    UserSubmittedRawJson ->
      case model {
        NoCharacterSelected -> model
        Model(save:, id:, draft_json:, ..) ->
          case json.parse(draft_json, sheet.decoder()) {
            Ok(new_sheet) ->
              Model(..model, sheet: model.save(new_sheet, id), parse_error: "")
            Error(err) -> Model(..model, parse_error: string.inspect(err))
          }
      }
  }
}

// fn move_done_task_to_do(model: Model, id: Int) -> Model {
//   let Tasks(do:, done:) = model.tasks

//   let assert Ok(task) = done |> dict.get(id)
//   let do = do |> dict.insert(id, task)
//   let done = done |> dict.delete(id)
//   let tasks = Tasks(do:, done:) |> model.save

//   Model(..model, tasks:)
// }

// fn move_do_task_to_done(model: Model, id: Int) -> Model {
//   let Tasks(do:, done:) = model.tasks

//   let assert Ok(task) = do |> dict.get(id)
//   let done = done |> dict.insert(id, task)
//   let do = do |> dict.delete(id)
//   let tasks = Tasks(do:, done:) |> model.save

//   Model(..model, tasks:)
// }

// fn add_task(model: Model) -> Model {
//   use <- bool.guard(when: model.currently_edited_task == "", return: model)

//   let Tasks(do:, done:) = model.tasks

//   let id =
//     int.max(
//       do |> dict.keys |> list.max(int.compare) |> result.unwrap(0),
//       done |> dict.keys |> list.max(int.compare) |> result.unwrap(0),
//     )
//     + 1

//   let task = Task(id:, description: model.currently_edited_task)
//   let do = do |> dict.insert(id, task)
//   let tasks = Tasks(do:, done:) |> model.save

//   Model(..model, tasks:, currently_edited_task: "")
// }

fn view(model: Model) {
  use <- bool.guard(
    when: model == NoCharacterSelected,
    return: view_no_character_selected(),
  )

  let assert Model(..) = model

  div([], [
    div([], list.map(model.sheet.groups, view_group)),
    html.details([], [
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

fn view_group(group: Group) -> element.Element(Message) {
  case group {
    FieldGroup(name:, fields:) ->
      fieldset([], [
        legend([], [html.text(name)]),
        ..list.map(fields, view_field)
      ])
    SuperGroup(name:, groups:) ->
      fieldset([], [
        legend([], [html.text(name)]),
        ..list.map(groups, view_group)
      ])
  }
}

fn view_field(field: Field) -> element.Element(Message) {
  let Field(name:, value: field_value) = field
  label([], [html.text(name), view_field_value(field_value)])
}

fn view_field_value(field_value: FieldValue) -> element.Element(Message) {
  case field_value {
    Text(value:) ->
      input([type_("text"), readonly(True), attribute.value(value)])
    LongText(value:, excerpt:, reference:) -> {
      let txtarea = case value {
        "" -> element.none()
        _ -> textarea([readonly(True)], value)
      }
      let excerpt_input =
        input([type_("text"), readonly(True), attribute.value(excerpt)])
      let reference_link = case reference {
        "" -> element.none()
        _ ->
          html.a([attribute.href(reference), attribute.target("_blank")], [
            html.text("ref"),
          ])
      }
      let details = case value, reference {
        "", "" -> element.none()
        _, _ ->
          html.details([], [
            html.summary([], [html.text("details")]),
            txtarea,
            reference_link,
          ])
      }
      div([], [excerpt_input, details])
    }

    Integer(value: v) ->
      input([type_("number"), readonly(True), value(int.to_string(v))])
    Modifier(value: v) -> {
      let formatted = case v >= 0 {
        True -> "+" <> int.to_string(v)
        False -> int.to_string(v)
      }
      input([type_("text"), readonly(True), value(formatted)])
    }
    Checkbox(value: cb) ->
      case cb {
        Off ->
          input([type_("checkbox"), readonly(True), attribute.disabled(True)])
        On ->
          input([
            type_("checkbox"),
            checked(True),
            readonly(True),
            attribute.disabled(True),
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
    Resource(value: v, max:, recovery: _) ->
      input([
        type_("text"),
        readonly(True),
        value(int.to_string(v) <> " / " <> int.to_string(max)),
      ])
  }
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
// fn view(model: Model) {
//   let Tasks(do:, done:) = model.tasks
//   div([], [
//     section([], [
//       div([attribute.role("group")], [
//         input([
//           attribute.value(model.currently_edited_task),
//           on_keypress(fn(key) {
//             case key {
//               "Enter" -> UserSavedCurrentlyEditedTask
//               _ -> Nothing
//             }
//           }),
//           event.on_input(UserUpdatedCurrentlyEditedTask),
//         ]),
//         input([
//           on_click(UserSavedCurrentlyEditedTask),
//           attribute.type_("button"),
//           attribute.value("Add Task"),
//         ]),
//       ]),
//       ul([], list.map(dict.values(do), do_task_to_li)),
//     ]),
//     hr([]),
//     section([], [
//       ul([], list.map(dict.values(done), done_task_to_li)),
//     ]),
//   ])
// }

// fn do_task_to_li(task: Task) -> element.Element(Message) {
//   let Task(id:, description:) = task

//   li([], [html.text(description)])
// }

// fn done_task_to_li(task: Task) -> element.Element(Message) {
//   let Task(id:, description:) = task

//   li([], [
//     html.del([], [html.text(description)]),
//   ])
// }
