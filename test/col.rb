
# This enhancement to String is needed for testing this file.
class String
  require 'term/ansicolor'
  include Term::ANSIColor
end

D "Simple formatting (single string)" do
  D "yellow" do
    Eq Col["string"].y.to_s,   "string".yellow
    Eq Col["string"].fmt("y"), "string".yellow
    Eq Col["string"].fmt(:y),  "string".yellow
  end
  D "red" do
    Eq Col["string"].r.to_s,   "string".red
    Eq Col["string"].fmt(:r),  "string".red
    Eq Col["string"].fmt("r"), "string".red
  end
  D "red bold" do
    Eq Col["string"].rb.to_s,  "string".red.bold
    Eq Col["string"].fmt(:rb), "string".red.bold
  end
  D "bold" do
    Eq Col["string"]._b.to_s,  "string".bold
    Eq Col["string"].fmt(:_b), "string".bold
  end
  D "black" do
    Eq Col["string"].B.to_s,   "string".black
    Eq Col["string"].fmt(:B),  "string".black
  end
end


D "General formatting (multiple strings)" do
  D "example 1" do
    str1 = Col("one", "two", "three", "four").fmt(:rb, :y, :cb, :m)
    str2 = Col("one", "two", "three", "four").fmt "rb,y,cb,m"
    expected = "one".red.bold + "two".yellow + "three".cyan.bold + "four".magenta
    Eq str1, expected
    Eq str2, expected
  end
  D "example 2" do
    str1 = Col("one", "two", "three").fmt(:Bb, :_b, :w_)  # the _ in w_ is optional
    str2 = Col("one", "two", "three").fmt "Bb,_b,w_"
    expected = "one".black.bold + "two".bold + "three".white
    Eq str1, expected
    Eq str2, expected
  end
  D "example 3" do
    str1 = Col["one","two"].fmt "y,r"
    expected = "one".yellow + "two".red
    Eq str1, expected
    Eq (Col["one","two"].fmt "y,r"), ("one".yellow + "two".red)
  end
  D "including strings where no formatting is done" do
    name, age = "Peter", 14
    str1 = Col["Name: ", name, "   Age: ", age].fmt(:_, :rb, :_, :gb)
    str2 = Col["Name: ", name, "   Age: ", age].fmt "_,rb,_,gb"
    expected = "Name: " + name.red.bold + "   Age: " + age.to_s.green.bold
    Eq str1, expected
    Eq str2, expected
  end
end

D "More complex formatting (on_red, strikethrough, italic, dark, negative, ...)" do
  D "all styles (part 1)" do
    str1 = Col["one","two","three","four","five"].fmt(:_b, :_d, :_i, :_u, :_U)
    str2 = Col["one","two","three","four","five"].fmt "_b,_d,_i,_u,_U"
    expected = "one".bold + "two".dark + "three".italic + "four".underline \
             + "five".underscore
    Eq str1, expected
    Eq str2, expected
  end
  D "all styles (part 2)" do
    str1 = Col["one","two","three","four","five"].fmt(:_k, :_r, :_n, :_c, :_s)
    str2 = Col["one","two","three","four","five"].fmt "_k,_r,_n,_c,_s"
    expected = "one".blink + "two".rapid_blink + "three".negative \
             + "four".concealed + "five".strikethrough
    Eq str1, expected
    Eq str2, expected
  end
  D "all backgrounds (part 1)" do
    str1 = Col["one","two","three","four"].fmt(:__oB, :__or, :__og, :__oy)
    str2 = Col["one","two","three","four"].fmt "__oB,__or,__og,__oy"
    expected = "one".on_black + "two".on_red + "three".on_green + "four".on_yellow
    Eq str1, expected
    Eq str2, expected
  end
  D "all backgrounds (part 2)" do
    str1 = Col["one","two","three","four"].fmt(:__ob, :__om, :__oc, :__ow)
    str2 = Col["one","two","three","four"].fmt "__ob,__om,__oc,__ow"
    expected = "one".on_blue + "two".on_magenta + "three".on_cyan + "four".on_white
    Eq str1, expected
    Eq str2, expected
  end
  D "mixed 1" do
    str1 = Col["one","two","three","four"].fmt(:r_ow, :bnoy, :_d, :gs)
    str2 = Col["one","two","three","four"].fmt "r_ow,bnoy,_d,gs"
    expected = "one".red.on_white + "two".blue.negative.on_yellow \
             + "three".dark + "four".green.strikethrough
    Eq str1, expected
    Eq str2, expected
  end
  D "mixed 2" do
    str1 = Col["one","two","three","four"].fmt(:cUob, :wkoB, :m_or, :yc)
    str2 = Col["one","two","three","four"].fmt "cUob,wkoB,m_or,yc"
    expected = "one".cyan.underscore.on_blue + "two".white.blink.on_black \
             + "three".magenta.on_red + "four".yellow.concealed
    Eq str1, expected
    Eq str2, expected
  end
end

xD "Esoteric options" do
  D "italic,strikethrough,blink" do
    D "separate" do
      D "in full" do
        str1 = Col["one","two","three"].fmt(:italic, :strikethrough, :blink)
        expected = "one".italic + "two".strikethrough + "three".blink
        Eq str1, expected
      end
      D "abbreviated" do
        str1 = Col["one","two","three"].fmt(:it, :str, :bli)
        expected = "one".italic + "two".strikethrough + "three".blink
        Eq str1, expected
      end
    end
    D "combined" do
      # one string, several symbols
      str1 = Col["string"].fmt([:italic, :strikethrough, :blink])
      expected = "string".italic.strikethrough.blink
      Eq str1, expected
    end
  end
end

D "Verbose specification" do
  D "example 1" do
    str1 = Col["one","two"].fmt( [:bold, :yellow, :on_red], [:cyan, :dark] )
    expected = "one".bold.yellow.on_red + "two".cyan.dark
    Eq str1, expected
  end
  D "example 2" do
    str1 = Col["one","two"].fmt([:negative, :dark], [:underscore, :rapid_blink])
    expected = "one".negative.dark + "two".underscore.rapid_blink
  end
end

D "Object properties" do
  D "Col[...].green.on_white is still a Col object" do
    c = Col["..."].green
    Ko c, Col
    c = Col["..."].green.on_white
    Ko c, Col
  end
  D "a Col object is printable (implements to_s)" do
    c = Col["one","two","three"]
    Eq c.to_s, "onetwothree"
    c = Col["..."].green.on_white
    Eq c.to_s, "...".green.on_white
  end
  D "the string returned after formatting has nothing mixed in" do
    # Whilesoever Term::ANSIColor is mixed in to String, as it is at the top of
    # this file, I can't think of a way to test this property :(
    # I could change all the "foo".red.bold to bold(foo("red")) but that's a
    # _lot_ of work and will make this file quite ugly.
  end
end

D "Erroneous specifications" do
  D "incorrect number of arguments" do
    E(Col::Error) { Col["one","two"].fmt :b }
    Mt Attest.exception.message, /incorrect number of arguments/i
    E(Col::Error) { Col["one","two"].fmt(:b, :r, :g) }
    Mt Attest.exception.message, /incorrect number of arguments/i
    E(Col::Error) { Col["one","two"].fmt(:b, :r, :g, :cbow) }
    Mt Attest.exception.message, /incorrect number of arguments/i
  end

  D "invalid code" do
    E(Col::Error) { Col["one","two"].fmt(:T, :r) }
    E(Col::Error) { Col["one","two"].fmt "T,r" }
    Mt Attest.exception.message, /invalid color code/i
  end
end