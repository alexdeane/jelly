# jelly

[![Package Version](https://img.shields.io/hexpm/v/jelly)](https://hex.pm/packages/jelly)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/jelly/)

JSON parsing library for arbitrary JSON structures

```sh
gleam add jelly@1
```
```gleam
import jelly

pub fn main() {
  // {
  //   "foo": "bar"
  // }
  let assert Ok(json) = jelly.parse("{ \"foo\": \"bar\" }")
  let assert Ok(jelly.String(foo)) = jelly.path(json, "foo")
  io.debug(foo) // "bar"
}
```

Further documentation can be found at <https://hexdocs.pm/jelly>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
