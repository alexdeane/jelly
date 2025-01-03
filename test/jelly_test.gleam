import gleam/dict
import gleam/io
import gleeunit
import jelly
import simplifile

pub fn main() {
  gleeunit.main()
}

pub fn data_types_test() {
  let assert Ok(json_text) = simplifile.read("test/data_types.json")

  let assert Ok(json) = jelly.parse(json_text)

  let assert jelly.Object(object) = json

  // Primitives
  let assert Ok(jelly.String("a")) = dict.get(object, "string")
  let assert Ok(jelly.Int(1)) = dict.get(object, "int")
  let assert Ok(jelly.Float(1.1)) = dict.get(object, "float")
  let assert Ok(jelly.Bool(True)) = dict.get(object, "bool")

  // Arrays
  let assert Ok(jelly.Array([jelly.Int(1), jelly.Int(2), jelly.Int(3)])) =
    dict.get(object, "int_array")

  let assert Ok(jelly.Array([
    jelly.Float(1.1),
    jelly.Float(2.2),
    jelly.Float(3.3),
  ])) = dict.get(object, "float_array")

  let assert Ok(jelly.Array([
    jelly.String("a"),
    jelly.String("b"),
    jelly.String("c"),
  ])) = dict.get(object, "string_array")

  let assert Ok(jelly.Array([jelly.Int(1), jelly.Float(1.1), jelly.String("a")])) =
    dict.get(object, "mixed_array")

  // Flat object
  let assert Ok(jelly.Object(_)) = dict.get(object, "object")
}

pub fn nested_test() {
  let assert Ok(json_text) = simplifile.read("test/nested.json")
  let assert Ok(json) = jelly.parse(json_text)

  let assert jelly.Object(data) = json
  let assert Ok(jelly.Object(a)) = dict.get(data, "a")
  let assert Ok(jelly.Object(b)) = dict.get(a, "b")
  let assert Ok(jelly.Object(c)) = dict.get(b, "c")
  let assert Ok(jelly.Array(d)) = dict.get(c, "d")
  let assert [jelly.Object(e_wrapper)] = d
  let assert Ok(jelly.Array(e)) = dict.get(e_wrapper, "e")
  let assert [jelly.Object(f_wrapper)] = e
  let assert Ok(jelly.String("g")) = dict.get(f_wrapper, "f")
}

pub fn path_test() {
  let assert Ok(json_text) = simplifile.read("test/data_types.json")
  let assert Ok(json) = jelly.parse(json_text)

  let assert Ok(jelly.String("a")) = jelly.path(json, "string")
}

pub fn nested_path_test() {
  let assert Ok(json_text) = simplifile.read("test/nested.json")
  let assert Ok(json) = jelly.parse(json_text)

  let assert Ok(jelly.String("g")) = jelly.path(json, "a.b.c.d[0].e[0].f")
}

pub fn readme_test() {
  let assert Ok(json) = jelly.parse("{ \"foo\": \"bar\" }")
  let assert Ok(jelly.String(foo)) = jelly.path(json, "foo")
  let assert "bar" = foo
}
