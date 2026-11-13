use std/assert

export def "test part" [part: closure]: table<input: string, expected: int> -> nothing {
  for it in ($in | enumerate) {
    let log_line = {|t|
      [
        $"├✔️ (ansi green)Test case ($it.index + 1):"
        $"⏱️(ansi bo)(ansi u)(if $t > 5sec { ansi red } else { ansi green })"
        $"($t)(ansi reset)(if $t > 5sec { '🥲' })"
      ] | str join
    }
    timeit {
      assert equal ($it.item.input | do $part $it.item.param?) $it.item.expected
    }
    | print (do $log_line $in)
  }
}
