import gleam/string
import gleam/yielder

import gleeunit
import gleeunit/should

import ranger

pub fn main() {
  gleeunit.main()
}

pub fn invalid_string_test() {
  ranger.create(
    validate: fn(a) { string.length(a) == 1 },
    negate_step: fn(s) { -1 * s },
    add: fn(a: String, b: Int) {
      let assert [code] = string.to_utf_codepoints(a)
      let int_code = string.utf_codepoint_to_int(code)
      let new_int_code = int_code + b
      let assert Ok(new_code) = string.utf_codepoint(new_int_code)
      string.from_utf_codepoints([new_code])
    },
    compare: string.compare,
  )("ab", "e", 1)
  |> should.be_error
}

pub fn a_to_e_test() {
  ranger.create(
    validate: fn(a) { string.length(a) == 1 },
    negate_step: fn(s) { -1 * s },
    add: fn(a: String, b: Int) {
      let assert [code] = string.to_utf_codepoints(a)
      let int_code = string.utf_codepoint_to_int(code)
      let new_int_code = int_code + b
      let assert Ok(new_code) = string.utf_codepoint(new_int_code)
      string.from_utf_codepoints([new_code])
    },
    compare: string.compare,
  )("a", "e", -1)
  |> should.be_ok
  |> yielder.to_list
  |> should.equal(["a", "b", "c", "d", "e"])
}

pub fn z_to_p_double_step_test() {
  ranger.create(
    validate: fn(a) { string.length(a) == 1 },
    negate_step: fn(s) { -1 * s },
    add: fn(a: String, b: Int) {
      let assert [code] = string.to_utf_codepoints(a)
      let int_code = string.utf_codepoint_to_int(code)
      let new_int_code = int_code + b
      let assert Ok(new_code) = string.utf_codepoint(new_int_code)
      string.from_utf_codepoints([new_code])
    },
    compare: string.compare,
  )("z", "p", -2)
  |> should.be_ok
  |> yielder.to_list
  |> should.equal(["z", "x", "v", "t", "r", "p"])
}

pub fn z_to_p_triple_step_test() {
  ranger.create(
    validate: fn(a) { string.length(a) == 1 },
    negate_step: fn(s) { -1 * s },
    add: fn(a: String, b: Int) {
      let assert [code] = string.to_utf_codepoints(a)
      let int_code = string.utf_codepoint_to_int(code)
      let new_int_code = int_code + b
      let assert Ok(new_code) = string.utf_codepoint(new_int_code)
      string.from_utf_codepoints([new_code])
    },
    compare: string.compare,
  )("z", "p", 3)
  |> should.be_ok
  |> yielder.to_list
  |> should.equal(["z", "w", "t", "q"])
}
