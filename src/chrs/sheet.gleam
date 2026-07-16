import gleam/dynamic/decode
import gleam/json

pub type Sheet {
  Sheet(id: String, elements: List(Element))
}

pub type Element {
  Value(name: String, value: FieldValue)
  Group(name: String, elements: List(Element))
}

pub type FieldValue {
  Text(value: String)
  LongText(excerpt: String, value: String, reference: String)
  Integer(value: Int)
  Modifier(value: Int)
  Checkbox(value: CheckboxValue)
  Resource(value: Int, max: Int, recovery: RecoveryRule, kind: ResourceKind)
}

pub type ResourceKind {
  Numeric
  Counter
}

pub type CheckboxValue {
  Off
  On
  Special
}

pub type RecoveryRule {
  RecoveryRule(triggers: List(String), kind: RecoveryKind)
}

pub type RecoveryKind {
  ToFull
  ToHalfMax
  ByAmount(value: Int)
  ToZero
}

// -------------------------------------------------------------------- to_json
pub fn to_json(sheet: Sheet) -> json.Json {
  let Sheet(id:, elements:) = sheet
  json.object([
    #("id", json.string(id)),
    #("fields", json.array(elements, element_to_json)),
  ])
}

fn element_to_json(element: Element) -> json.Json {
  case element {
    Value(name:, value:) ->
      json.object([
        #("type", json.string("leaf")),
        #("name", json.string(name)),
        #("value", field_value_to_json(value)),
      ])
    Group(name:, elements:) ->
      json.object([
        #("type", json.string("group")),
        #("name", json.string(name)),
        #("fields", json.array(elements, element_to_json)),
      ])
  }
}

fn field_value_to_json(field_value: FieldValue) -> json.Json {
  case field_value {
    Text(value:) ->
      json.object([
        #("type", json.string("text")),
        #("value", json.string(value)),
      ])
    LongText(value:, excerpt:, reference:) ->
      json.object([
        #("type", json.string("long_text")),
        #("value", json.string(value)),
        #("excerpt", json.string(excerpt)),
        #("reference", json.string(reference)),
      ])
    Integer(value:) ->
      json.object([
        #("type", json.string("integer")),
        #("value", json.int(value)),
      ])
    Modifier(value:) ->
      json.object([
        #("type", json.string("modifier")),
        #("value", json.int(value)),
      ])
    Checkbox(value:) ->
      json.object([
        #("type", json.string("checkbox")),
        #("value", checkbox_value_to_json(value)),
      ])
    Resource(value:, max:, recovery:, kind:) ->
      json.object([
        #("type", json.string("resource")),
        #("value", json.int(value)),
        #("max", json.int(max)),
        #("kind", resource_kind_to_json(kind)),
        #("recovery", recovery_rule_to_json(recovery)),
      ])
  }
}

fn resource_kind_to_json(resource_kind: ResourceKind) -> json.Json {
  case resource_kind {
    Numeric -> json.string("numeric")
    Counter -> json.string("counter")
  }
}

fn recovery_rule_to_json(recovery_rule: RecoveryRule) -> json.Json {
  let RecoveryRule(triggers:, kind:) = recovery_rule
  json.object([
    #("on", json.array(triggers, json.string)),
    #("kind", recovery_kind_to_json(kind)),
  ])
}

fn recovery_kind_to_json(recovery_kind: RecoveryKind) -> json.Json {
  case recovery_kind {
    ToFull ->
      json.object([
        #("type", json.string("to_full")),
      ])
    ToHalfMax ->
      json.object([
        #("type", json.string("to_half_max")),
      ])
    ByAmount(value:) ->
      json.object([
        #("type", json.string("by_amount")),
        #("value", json.int(value)),
      ])
    ToZero -> json.object([
      #("type", json.string("to_full")),
    ])
  }
}

fn checkbox_value_to_json(checkbox_value: CheckboxValue) -> json.Json {
  case checkbox_value {
    Off -> json.string("off")
    On -> json.string("on")
    Special -> json.string("special")
  }
}

// -------------------------------------------------------------------- decoder

pub fn decoder() -> decode.Decoder(Sheet) {
  use id <- decode.field("id", decode.string)
  use elements <- decode.field("fields", decode.list(element_decoder()))
  decode.success(Sheet(id:, elements:))
}

fn element_decoder() -> decode.Decoder(Element) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "leaf" -> {
      use name <- decode.field("name", decode.string)
      use value <- decode.field("value", field_value_decoder())
      decode.success(Value(name:, value:))
    }
    "group" -> {
      use name <- decode.field("name", decode.string)
      use elements <- decode.field("fields", decode.list(element_decoder()))
      decode.success(Group(name:, elements:))
    }
    _ -> decode.failure(Value(name: "", value: Text(value: "")), "Element")
  }
}

fn field_value_decoder() -> decode.Decoder(FieldValue) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "text" -> {
      use value <- decode.field("value", decode.string)
      decode.success(Text(value:))
    }
    "long_text" -> {
      use value <- decode.field("value", decode.string)
      use reference <- decode.field("reference", decode.string)
      use excerpt <- decode.field("excerpt", decode.string)
      decode.success(LongText(value:, excerpt:, reference:))
    }
    "integer" -> {
      use value <- decode.field("value", decode.int)
      decode.success(Integer(value:))
    }
    "modifier" -> {
      use value <- decode.field("value", decode.int)
      decode.success(Modifier(value:))
    }
    "checkbox" -> {
      use value <- decode.field("value", checkbox_value_decoder())
      decode.success(Checkbox(value:))
    }
    "resource" -> {
      use value <- decode.field("value", decode.int)
      use max <- decode.field("max", decode.int)
      use recovery <- decode.field("recovery", recovery_rule_decoder())
      use kind <- decode.field("kind", resource_kind_decoder())
      decode.success(Resource(value:, max:, recovery:, kind:))
    }
    _ -> decode.failure(Text(value: ""), "FieldValue")
  }
}

fn resource_kind_decoder() -> decode.Decoder(ResourceKind) {
  use variant <- decode.then(decode.string)
  case variant {
    "numeric" -> decode.success(Numeric)
    "counter" -> decode.success(Counter)
    _ -> decode.failure(Numeric, "ResourceKind")
  }
}

fn recovery_rule_decoder() -> decode.Decoder(RecoveryRule) {
  use triggers <- decode.field("on", decode.list(decode.string))
  use kind <- decode.field("kind", recovery_kind_decoder())
  decode.success(RecoveryRule(triggers:, kind:))
}

fn recovery_kind_decoder() -> decode.Decoder(RecoveryKind) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "to_full" -> decode.success(ToFull)
    "to_half_max" -> decode.success(ToHalfMax)
    "by_amount" -> {
      use value <- decode.field("value", decode.int)
      decode.success(ByAmount(value:))
    }
    _ -> decode.failure(ToFull, "RecoveryKind")
  }
}

fn checkbox_value_decoder() -> decode.Decoder(CheckboxValue) {
  use variant <- decode.then(decode.string)
  case variant {
    "off" -> decode.success(Off)
    "on" -> decode.success(On)
    "special" -> decode.success(Special)
    _ -> decode.failure(Off, "CheckboxValue")
  }
}
