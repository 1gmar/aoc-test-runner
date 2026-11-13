export def run-test-runner [testPattern: string = '^day\d\d? test' --ignored (-i)]: table -> nothing {
  print $"💡 (ansi yellow)(ansi bo)Running tests...(ansi reset)"
  let tests_criteria = {|it|
    (
      $it.type == "custom"
      and $it.name =~ $testPattern
      and ($ignored or not ($it.description | str starts-with 'ignore'))
    )
  }
  let render_test_case = {|part|
    let test = [$part.item.day $part.item.part] | str join ' '
    [$"print '├⏳ (ansi yellow)Running test: (ansi bo)($test)(ansi reset)'" $test]
  }
  let render_test_part = {|day item|
    let day_cap = $day | str capitalize
    [$"print '🧩(ansi yb)  ($day_cap):(ansi reset)'"]
    | append ($item | enumerate | each --flatten $render_test_case)
    | append [$"print '└☀️ (ansi gb)($day_cap) passed!(ansi reset)'"]
  }
  let test_commands = $in
    | where $tests_criteria
    | get name
    | sort -n
    | parse '{day} {part}'
    | group-by day
    | items $render_test_part
    | flatten
    | str join ";"

  with-env {NU_LIB_DIRS: ($env.NU_LIB_DIRS | str join (char env_sep))} {
    nu -c $"use src * ; ($test_commands)"
  }

  print $"✅ (ansi bo)(ansi green)All tests passed!(ansi reset)"
}
