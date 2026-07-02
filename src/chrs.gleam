// import gleam/bool
// import gleam/dict
// import gleam/int
// import gleam/json
// import gleam/list
// import gleam/result

// import plinth/javascript/console
// import plinth/javascript/storage
// import varasto

// import lustre
// import lustre/attribute
// import lustre/element
// import lustre/element/html.{div, hr, input, li, section, ul}
// import lustre/event.{on_click, on_keypress}

// import chrs/task.{
//   type Task, type Tasks, Task, Tasks, tasks_decoder, tasks_to_json,
// }

// const key = "net.bucsi.simplest.tasks"

// const localstorage_set_failure = "LocalStorage.set failed!"

// pub type Message {
//   UserUpdatedCurrentlyEditedTask(currently_edited_task: String)
//   UserSavedCurrentlyEditedTask
//   Nothing
// }

// pub type NewTaskData {
//   NewTaskData(description: String)
// }

// pub type Model {
//   Model(save: fn(Tasks) -> Tasks, tasks: Tasks, currently_edited_task: String)
// }

// pub fn main() {
//   let app = lustre.simple(init, update, view)
//   let assert Ok(_) = lustre.start(app, "#app", Nil)

//   Nil
// }

// fn init(_flags: a) -> Model {
//   let assert Ok(local) = storage.local()
//   let typed_storage = varasto.new(local, tasks_decoder(), tasks_to_json)

//   let save = fn(value: Tasks) -> Tasks {
//     case varasto.set(typed_storage, key, value) {
//       Ok(_) -> value
//       Error(_) -> {
//         console.error(localstorage_set_failure)
//         console.log(value |> tasks_to_json |> json.to_string)
//         panic as localstorage_set_failure
//       }
//     }
//   }

//   let tasks = case typed_storage |> varasto.get(key) {
//     Ok(value) -> value
//     Error(_) -> {
//       console.debug("No saved tasks found, starting fresh.")
//       save(Tasks(dict.new(), dict.new()))
//     }
//   }

//   Model(save:, tasks:, currently_edited_task: "")
// }

// fn update(model: Model, msg: Message) -> Model {
//   case msg {
//     UserUpdatedCurrentlyEditedTask(currently_edited_task:) ->
//       Model(..model, currently_edited_task:)
//     UserSavedCurrentlyEditedTask -> add_task(model)
//     Nothing -> model
//   }
// }

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
