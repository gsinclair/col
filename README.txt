col: high-level console color formatting for Ruby

If you want a dash of color in your Ruby console program, use Term::ANSIColor.
If your color formatting requirements are more complicated, use Col.
Col provides as much convenience as possible without modifying builtin classes.

=== SYNOPSIS

    require 'col'

    puts Col("Hello world!").red.bold
    puts Col("Hello world!").rb
    puts Col("Hello world!").fmt [:red, :bold]
    puts Col("Hello world!").fmt :rb

    puts Col("Hello ", "world!").fmt :red, :green
    puts Col("Hello ", "world!").fmt "r,g"

    puts Col("Hello ", "world!").fmt [:red, :bold], [:green, :bold]
    puts Col("Hello ", "world!").fmt "rb,gb"

    puts Col("Hello ", "world!").fmt [:bold], [:cyan, :italic, :on_white]
    puts Col("Hello ", "world!").fmt "_b,ciow"

    puts Col("Hello ", "world!").fmt [:blue, :on_yellow], [:on_green]
    puts Col("Hello ", "world!").fmt "b_oy,__og"

    puts Col.inline( "Hello ", :red, "world!", :blue )

    puts Col.inline(
      "Hello ",   [:red, :bold, :on_white],
      "world!",   :b_oy
    )

See http://gsinclair.github.com/col.html for full details.
