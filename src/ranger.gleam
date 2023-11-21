import gleam/bool
import gleam/order
import gleam/option
import gleam/iterator

pub opaque type Range(item_type) {
  Range(iterator.Iterator(item_type))
}

type Direction {
  Forward
  Backward
}

/// returns a function that can be used to create a range
///
/// ## Examples
///
/// ```gleam
/// > let range =
/// >  create(
/// >    validate: fn(a) { string.length(a) == 1 },
/// >    negate_step: fn(s) { -1 * s },
/// >    add: fn(a: String, b: Int) {
/// >      let [code] = string.to_utf_codepoints(a)
/// >      let int_code = string.utf_codepoint_to_int(code)
/// >      let new_int_code = int_code + b
/// >      let assert Ok(new_code) = string.utf_codepoint(new_int_code)
/// >      string.from_utf_codepoints([new_code])
/// >    },
/// >    compare: string.compare,
/// >  )
///
/// > range("ab", "e", 1)
/// Error(Nil)
///
/// > let assert Ok(a_to_e) = range("a", "e", 1)
/// > a_to_e |> unwrap |> iterator.to_list
/// ["a", "b", "c", "d", "e"]
/// 
/// > let assert Ok(z_to_p) = range("z", "p", 1)
/// > z_to_p |> unwrap |> iterator.to_list
/// ["z", "y", "x", "w", "v", "u", "t", "s", "r", "q", "p"]
///
/// > let assert Ok(z_to_p) = range("z", "p", -2)
/// > z_to_p |> unwrap |> iterator.to_list
/// ["z", "x", "v", "t", "r", "p"]
///
/// > let assert Ok(z_to_p) = range("z", "p", 3)
/// > z_to_p |> unwrap |> iterator.to_list
/// ["z", "w", "t", "q"]
/// ```
///
///
/// ```gleam
/// > let range =
/// >    create(
/// >      validate: fn(_) { True },
/// >      negate_step: fn(s) { -1.0 *. s },
/// >      add: fn(a, b) { a +. b },
/// >      compare: float.compare,
/// >    )
///
/// > let assert Ok(weird_step_case) = range(1.25, 4.5, -0.5)
/// > weird_step_case |> unwrap |> iterator.to_list
/// [1.25, 1.75, 2.25, 2.75, 3.25, 3.75, 4.25]
/// 
/// > let assert Ok(single_item_case) = range(1.25, 1.25, -0.25)
/// > single_item_case |> unwrap |> iterator.to_list
/// [1.25]
///
/// > let assert Ok(zero_step_case) = range(2.5, 5.0, 0)
/// > zero_step_case |> unwrap |> iterator.to_list
/// [2.5]
/// ```
///
pub fn create(
  validate validate: fn(item_type) -> Bool,
  negate_step negate_step: fn(step_type) -> step_type,
  add add: fn(item_type, step_type) -> item_type,
  compare compare: fn(item_type, item_type) -> order.Order,
) -> fn(item_type, item_type, step_type) -> Result(Range(item_type), Nil) {
  let adjust_step = fn(a, b, s) -> option.Option(#(Direction, step_type)) {
    case [compare(a, b), compare(a, add(a, s))] {
      [order.Eq, _] -> option.None
      [_, order.Eq] -> option.None
      [order.Lt, order.Lt] -> option.Some(#(Forward, s))
      [order.Gt, order.Gt] -> option.Some(#(Backward, s))
      [order.Lt, order.Gt] -> option.Some(#(Forward, negate_step(s)))
      [order.Gt, order.Lt] -> option.Some(#(Backward, negate_step(s)))
    }
  }

  fn(a: item_type, b: item_type, s: step_type) {
    use <- bool.guard(!validate(a) || !validate(b), Error(Nil))
    case adjust_step(a, b, s) {
      option.Some(#(direction, step)) ->
        iterator.unfold(
          a,
          fn(current) {
            case #(compare(current, b), direction) {
              #(order.Gt, Forward) -> iterator.Done
              #(order.Lt, Backward) -> iterator.Done
              _ -> iterator.Next(current, add(current, step))
            }
          },
        )
      option.None -> iterator.once(fn() { a })
    }
    |> Range
    |> Ok
  }
}

/// returns a function that can be used to create an infinite range
///
/// should be used carefully because careless use of infinite iterators could crash your app
///
/// ## Examples
///
/// ```gleam
/// > let range =
/// >  create_infinite(
/// >    validate: fn(a) { string.length(a) == 1 },
/// >    add: fn(a: String, b: Int) {
/// >      let [code] = string.to_utf_codepoints(a)
/// >      let int_code = string.utf_codepoint_to_int(code)
/// >      let new_int_code = int_code + b
/// >      let assert Ok(new_code) = string.utf_codepoint(new_int_code)
/// >      string.from_utf_codepoints([new_code])
/// >    },
/// >    compare: string.compare,
/// >   )
///
/// > let assert Ok(from_a) = range("a", 1)
/// > from_a |> unwrap |> iterator.take(26) |> iterator.to_list
/// ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n",
///   "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
/// ```
pub fn create_infinite(
  validate validate: fn(item_type) -> Bool,
  add add: fn(item_type, step_type) -> item_type,
  compare compare: fn(item_type, item_type) -> order.Order,
) -> fn(item_type, step_type) -> Result(Range(item_type), Nil) {
  let is_step_zero = fn(a, s) -> Bool {
    case compare(a, add(a, s)) {
      order.Eq -> True
      _ -> False
    }
  }

  fn(a: item_type, s: step_type) {
    use <- bool.guard(!validate(a), Error(Nil))
    use <- bool.guard(
      is_step_zero(a, s),
      iterator.once(fn() { a })
      |> Range
      |> Ok,
    )

    iterator.unfold(a, fn(current) { iterator.Next(current, add(current, s)) })
    |> Range
    |> Ok
  }
}

pub fn unwrap(value: Range(item_type)) -> iterator.Iterator(item_type) {
  case value {
    Range(iterator) -> iterator
  }
}
