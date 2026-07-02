import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/int
import gleam/json

pub type Task {
  Task(id: Int, description: String)
}

pub type Tasks {
  Tasks(do: Dict(Int, Task), done: Dict(Int, Task))
}

pub fn tasks_to_json(tasks: Tasks) -> json.Json {
  let Tasks(do:, done:) = tasks
  json.object([
    #("do", json.dict(do, int.to_string, task_to_json)),
    #("done", json.dict(done, int.to_string, task_to_json)),
  ])
}

pub fn tasks_decoder() -> decode.Decoder(Tasks) {
  use do <- decode.field(
    "do",
    decode.dict(string_to_int_decoder(), task_decoder()),
  )
  use done <- decode.field(
    "done",
    decode.dict(string_to_int_decoder(), task_decoder()),
  )
  decode.success(Tasks(do:, done:))
}

fn task_to_json(task: Task) -> json.Json {
  let Task(id:, description:) = task
  json.object([
    #("id", json.int(id)),
    #("description", json.string(description)),
  ])
}

fn task_decoder() -> decode.Decoder(Task) {
  use id <- decode.field("id", decode.int)
  use description <- decode.field("description", decode.string)
  decode.success(Task(id:, description:))
}

fn string_to_int_decoder() -> decode.Decoder(Int) {
  use value <- decode.then(decode.string)
  case int.parse(value) {
    Ok(v) -> decode.success(v)
    Error(_) -> decode.failure(0, "Expected a string representing an Int")
  }
}
