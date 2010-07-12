# col -- a Ruby string-coloring library

`col` applies ANSI color codes to strings for colorful console output.  It uses
[`term/ansicolor`][1] to do this, but offers an extra way to access its
features.

[1] http://flori.github.com/term-ansicolor/

## Benefits
* An easy way to construct a string with different colors applied to different
  parts.
* Abbreviations like "rb" for _red_ and _bold_.
* Easy, elegant code without adding any methods to the String class.

## Example code

1. Applying different colors and styles to different parts of a string.  This
   is idiomatic `col` usage, although it's a necessarily contrived example.

        puts Col("one","two","three","four").fmt "rb,giow,_n,B_or"

   This is equivalent to (with `term/ansicolor`'s methods mixed in to `String`)

        puts "one".red.bold           \ 
        + "two".green.italic.on_white \ 
        + "three".negative            \ 
        + "four".black.on_red

2. Printing a colorful name and age

        # Using term/ansicolor
        puts "Name: " + name.red.bold + "   Age: " + age.green.bold

        # Using col (1)
        puts Col["Name: ", name, "   Age: ", age].fmt( :_, :rb, :_, :gb )

        # Using col (2)
        puts Col["Name: ", name "   Age: ", age].fmt "_,rb,_,gb"

3. Printing a line of text with green foreground and white background

        # Using term/ansicolor
        puts text.green.on_white

        # Using col (shortest way)
        puts Col[text].g_ow

        # Using col (other ways)
        puts Col[text].fmt :g_ow
        puts Col[text].green.on_white

## Notes

1. `Col(...)` and `Col[...]` are equivalent.
2. `Col(...).fmt "..."` returns a String object.  _That_ string will have the
   `Term::ANSIColor` methods (`:bold`, `:green`, ...) mixed in, but strings in
   general do not.
3. `Col(...).green` returns a `Col` object, but `#to_s` is implemented, so it
   will print as expected.

# Methods and abbreviations

Here are some illustrative examples of abbreviations you can use with `col`.

     Code                        Effect(s) applied
     ----                        -----------------
     Col["..."].g        green
     Col["..."].gb       green bold
     Col["..."]._b       bold
     Col["..."].gbow     green bold on_white
     Col["..."].g_ow     green on_white
     Col["..."].__ow     on_white
   
So you can see that the abbreviations are positional.  If you only want to
specify `on_white`, you must use underscores for the color and style properties.

Using these abbreviations, you can apply at most one color, at most one style,
and at most one background color.  These are listed in full here:

    COLORS = {              STYLES = {                    BACKGROUND = {        
      'B' => :black,          'b' => :bold,                 'oB' => :on_black,  
      'r' => :red,            'd' => :dark,                 'or' => :on_red,    
      'g' => :green,          'i' => :italic,               'og' => :on_green,  
      'y' => :yellow,         'u' => :underline,            'oy' => :on_yellow, 
      'b' => :blue,           'U' => :underscore,           'ob' => :on_blue,   
      'm' => :magenta,        'k' => :blink,                'om' => :on_magenta,
      'c' => :cyan,           'r' => :rapid_blink,          'oc' => :on_cyan,   
      'w' => :white           'n' => :negative,             'ow' => :on_white   
    }                         'c' => :concealed,          }                     
                              's' => :strikethrough,
                            }                       
    
Note: `b` for blue, `B` for black; `u` for underline, `U` for underscore; `b`
for bold; `k` for blink.

All of the methods shown in the block above can be called on a `Col` object
directly, or passed in full as a format specifier.  Examples:

    Col("foo").rapid_blink.strikethrough.on_magenta

    Col("one","two").fmt [:bold, :red, :underscore, :on_cyan], [:negative, :blink]


