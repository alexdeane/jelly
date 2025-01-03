import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/regexp
import gleam/result
import gleam/string

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
  case decode_to_dict(json) {
    Ok(dict) ->
      dict
      |> dynamic.from
      |> decode
      |> Ok
    Error(error) -> Error(error)
  }
}

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

/// Select a nested value from a JsonType object
/// using a path expression (e.g. "a.b.c[3]"). Returns
/// Nil if the path does not lead to a value.
/// 
pub fn path(json: JsonType, path: String) -> Result(JsonType, Nil) {
  let keys = parse_path_keys(path)
  do_path(json, keys)
}

fn do_path(json: JsonType, keys: List(PathKey)) -> Result(JsonType, Nil) {
  // Ensure we have a key
  io.debug(keys)
  io.debug(json)
  case keys {
    // If we are still here without any keys left,
    // we have our result
    [] -> Ok(json)
    // If more keys, continue to traverse
    [key, ..remaining_keys] -> {
      case json, key {
        // Property is a valid accessor for an object
        Object(x), Property(property) ->
          case dict.get(x, property) {
            Ok(value) -> do_path(value, remaining_keys)
            Error(_) -> Error(Nil)
          }
        // Indexer is a valid accessor for an array
        Array(x), Indexer(index) ->
          list_get(x, index) |> result.try(do_path(_, remaining_keys))
        // Anything else is not valid and means the path leads nowhere
        _, _ -> Error(Nil)
      }
    }
  }
}

fn parse_path_keys(path: String) -> List(PathKey) {
  string.split(path, ".")
  |> list.map(fn(path_key) {
    case parse_indexer(path_key) {
      Ok(keys) -> keys
      Error(_) -> [Property(path_key)]
    }
  })
  |> list.flatten()
}

fn parse_indexer(val: String) -> Result(List(PathKey), Nil) {
  let assert Ok(regex) =
    regexp.from_string("^(?<property>[A-z]+)\\[(?<index>[0-9]+)\\]$")
  case regexp.scan(regex, val) {
    [match] ->
      case match.submatches {
        [Some(property), Some(index)] ->
          case int.parse(index) {
            Ok(index) -> Ok([Property(property), Indexer(index)])
            Error(_) -> Error(Nil)
          }
        _ -> Error(Nil)
      }
    _ -> Error(Nil)
  }
}

type PathKey {
  // Root
  Indexer(Int)
  Property(String)
}

@external(erlang, "jelly_json", "decode")
fn decode_to_dict(json: String) -> Result(Dict(Dynamic, Dynamic), DecodeError)

fn list_get(list: List(a), index: Int) -> Result(a, Nil) {
  case index {
    0 -> list.first(list)
    _ ->
      case list.rest(list) {
        Ok(rest) -> list_get(rest, index - 1)
        Error(_) -> Error(Nil)
      }
  }
}
