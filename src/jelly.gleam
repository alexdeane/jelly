import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/list

/// From gleam/json
/// 
pub type DecodeError {
  UnexpectedEndOfInput
  UnexpectedByte(String)
  UnexpectedSequence(String)
}

/// Represents a JSON tree of arbitrary schema
/// 
pub type JsonType {
  Unknown
  Null
  Bool(Bool)
  Float(Float)
  Int(Int)
  String(String)
  Array(List(JsonType))
  Object(dict.Dict(String, JsonType))
}

pub fn parse(from json: String) -> Result(JsonType, DecodeError) {
  let json_decode_result = decode_to_dict(json)

  case json_decode_result {
    Ok(dict) ->
      dict
      |> dynamic.from
      |> decode
      |> Ok
    Error(error) -> Error(error)
  }
}

@external(erlang, "jelly_json", "decode")
fn decode_to_dict(json: String) -> Result(Dict(Dynamic, Dynamic), DecodeError)

/// Decodes any Dynamic into a JsonType which can be matched
/// on to extract the data. If decoding fails, the dynamic value is returned.
/// 
pub fn decode(from value: dynamic.Dynamic) -> JsonType {
  case value |> dynamic.dict(dynamic.string, dynamic.dynamic) {
    Ok(dict_value) -> {
      dict_value
      |> dict.map_values(fn(_key, value) { decode(value) })
      |> Object
    }
    Error(_) ->
      case dynamic.string(value) {
        Ok(string_value) -> String(string_value)
        Error(_) ->
          case dynamic.bool(value) {
            Ok(bool_value) -> Bool(bool_value)
            Error(_) ->
              case dynamic.float(value) {
                Ok(float_value) -> Float(float_value)
                Error(_) ->
                  case dynamic.int(value) {
                    Ok(int_value) -> Int(int_value)
                    Error(_) ->
                      case dynamic.shallow_list(value) {
                        Ok(list_value) -> {
                          list_value
                          |> list.map(decode)
                          |> Array
                        }
                        Error(_) ->
                          // We need a dynamic.nil
                          case dynamic.classify(value) {
                            "Nil" -> Null
                            _ -> Unknown
                          }
                      }
                  }
              }
          }
      }
  }
}
