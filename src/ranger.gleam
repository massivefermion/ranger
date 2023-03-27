import gleam/bool
import gleam/order
import gleam/option
import gleam/iterator

pub opaque type Range(item_type) {
  Range(iterator.Iterator(item_type))
}

pub type Options(item_type, step_type) {
  Options(
    validate: fn(item_type) -> Bool,
    negate_step: fn(step_type) -> step_type,
    add: fn(item_type, step_type) -> item_type,
    compare: fn(item_type, item_type) -> order.Order,
  )
}

/// returns a function that can be used to create a range
///
/// ## Examples
///
/// ```gleam
/// > let options =
/// >   Options(
/// >     validate: fn(a) { string.length(a) == 1 },
/// >     negate_step: fn(s) { -1 * s },
/// >     add: fn(a: String, b: Int) {
/// >       let [code] = string.to_utf_codepoints(a)
/// >       let int_code = string.utf_codepoint_to_int(code)
/// >       let new_int_code = int_code + b
/// >       let assert Ok(new_code) = string.utf_codepoint(new_int_code)
/// >       string.from_utf_codepoints([new_code])
/// >     },
/// >     compare: string.compare,
/// >   )
/// > let range = create(options)
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
/// > let options =
/// >   Options(
/// >     validate: fn(_) { True },
/// >     negate_step: fn(s) { -1.0 *. s },
/// >     add: fn(a, b) { a +. b },
/// >     compare: float.compare,
/// >   )
/// > let range = create(options)
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
  options: Options(item_type, step_type),
) -> fn(item_type, item_type, step_type) -> Result(Range(item_type), Nil) {
  let should_negate = fn(a, s) -> option.Option(Bool) {
    case options.compare(a, options.add(a, s)) {
      order.Eq -> option.None
      order.Lt -> option.Some(True)
      order.Gt -> option.Some(False)
    }
  }

  fn(a: item_type, b: item_type, s: step_type) {
    use <- bool.guard(!options.validate(a) || !options.validate(b), Error(Nil))
    let should_negate_option = should_negate(a, s)
    use <- bool.guard(
      option.is_none(should_negate_option),
      iterator.once(fn() { a })
      |> Range
      |> Ok,
    )
    let should_negate = option.unwrap(should_negate_option, True)

    case options.compare(a, b) {
      order.Eq -> iterator.once(fn() { a })

      order.Gt ->
        iterator.unfold(
          a,
          fn(current) {
            case options.compare(current, b) {
              order.Lt -> iterator.Done
              _ ->
                iterator.Next(
                  current,
                  options.add(
                    current,
                    case should_negate {
                      True -> options.negate_step(s)
                      False -> s
                    },
                  ),
                )
            }
          },
        )

      order.Lt ->
        iterator.unfold(
          a,
          fn(current) {
            case options.compare(current, b) {
              order.Gt -> iterator.Done
              _ ->
                iterator.Next(
                  current,
                  options.add(
                    current,
                    case should_negate {
                      True -> s
                      False -> options.negate_step(s)
                    },
                  ),
                )
            }
          },
        )
    }
    |> Range
    |> Ok
  }
}

pub fn unwrap(value: Range(item_type)) -> iterator.Iterator(item_type) {
  case value {
    Range(iterator) -> iterator
  }
}
