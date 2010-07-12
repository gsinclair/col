require 'rubygems'
require 'term/ansicolor'

# --------------------------------------------------------------------------- #

class Col
  # args: array of strings (to_s is called on each)
  def initialize(*args)
    @strings = args.map { |a| a.to_s }
  end

  def Col.[](*args)
    Col.new(*args)
  end

  # e.g.
  #   Col("one", "two", "three", "four").fmt "rb,y,cb,_b"
  #     # same as:
  #       "one".red.bold + "two".yellow + "three".cyan.bold + "four".bold
  #
  #   Col
  def fmt(*spec)
    ::Col::Formatter.new(@strings, *spec).result
  end

  def to_s
    @strings.join
  end

  def method_missing(message, *args, &block)
    if args.empty?
      Col.new( self.fmt(message) )
    else
      super   # We're not interested in a message with arguments; NoMethodError
    end
  end
end

def Col(*args)
  Col.new(*args)
end

# --------------------------------------------------------------------------- #

class Col::Error < StandardError
end

# --------------------------------------------------------------------------- #

class Col::Formatter
  def initialize(strings, *spec)
    check_correct_number_of_arguments(strings, *spec)
    @strings = strings
    @format_spec = normalise_format_spec(*spec)
    debug "Col::Formatter#initialize"
    debug "  @strings     = #{@strings.inspect}"
    debug "  @format_spec = #{@format_spec.inspect}"
  end

###  def result
###    @strings.zip(@format_spec).map { |string, spec|
###      # spec is an array of methods to apply to string
###      spec.inject(string) { |acc, mth| acc.send(mth) }
###    }.join
###  end

  def result
    unless @strings.size == @format_spec.size
      raise Col::Error, "mismatching strings and specs"
    end
    String.new.tap { |str|
      @strings.zip(@format_spec).each do |string, spec|
        d = decorated_string(string, spec)
        str << d
      end
    }
  end

  # e.g.
  #   string = "hello"
  #   spec = [:yellow, :bold, :on_red]
  #   result = "hello".send(:yellow).send(:bold).send(:on_red)
  def decorated_string(string, spec)
    raise Col::Error unless string.is_a? String and spec.is_a? Array \
                        and spec.all? { |e| e.is_a? Symbol }
    string.extend(Term::ANSIColor)
    spec.inject(string) { |str, symbol| str.send(symbol) }
  end

  #
  # In general, there should be the same number of arguments as there are
  # strings:
  #
  #   Col["one"].fmt( :b )
  #   Col["one", "two"].fmt( [:red, :on_white], [:bold, :negative] )
  #   Col["one", "two", "three"].fmt( :yellow, [:green, :bold], :italic )
  #   Col["one", "two", "three", "four"].fmt(:rb, :y, :cb, :m)
  #   Col["one", "two", "three", "four"].fmt "rb,y,cb,m"
  #
  # As a special case, if there is only one string, it can have any number of
  # arguments:
  #
  #   Col["string"].fmt( :yellow, :bold, :italic, :blink, :negative, :on_magenta )
  #
  # If the number of arguments is incorrect, a Col::Error is thrown.
  #
  def check_correct_number_of_arguments(strings, *spec)
    nargs = spec.size
    if nargs == 1 and spec.first.is_a? String
      nargs = spec.first.split(/,/).size
    end
    if strings.size > 1 and nargs != strings.size
      raise Col::Error, "incorrect number of arguments: #{render(spec)}"
    end
  end

  #
  # Each spec in the following groups is equivalent.  The last one is
  # normalised.
  #
  #   [ :rb ]
  #   [ "rb" ]
  #   [ [:red, :bold] ]
  #
  #   [ :rb, :_n, :y ]
  #   [ "rb", "_n", "y" ]
  #   [ [:red, :bold], [:negative], [:yellow] ]
  #
  #   [ [:green, :concealed], :blue, :bold ]
  #   [ [:green, :concealed], [:blue], [:bold] ]
  #
  #   [ "rb,y,_i,g_ow" ]
  #   [ "rb", "y", "_i", "g_ow" ]
  #   [ [:red, :bold], [:yellow], [:italic], [:green, :on_white] ]
  #
  # {spec} is definitely an array because it was gathered like this:
  #   def fmt(*spec)
  #
  # "Normalised" means an array with one element for each string.
  # Each element is itself an array of all the properties that apply to that
  # string.
  #
  def normalise_format_spec(*spec)
    if spec.size == 1 and spec.first.is_a? String and spec.first.index(',')
                                                    # ^^^ "rb,y,_n"
      spec = spec.first.split(',')                  # ['rb', 'y', '_n']
      normalise_format_spec(*spec)
    else
      # We have an array of items.  We need to treat each item individually and
      # put the items together.
      spec.map { |item| normalise_item(item) }
    end
  end

  # Examples
  #     Item               Normalised item
  #     :r                 [:red]
  #     "r"                [:red]
  #     :red               [:red]
  #     [:red]             [:red]
  #     "rb"               [:red, :bold]
  #     :rb                [:red, :bold]
  #     [:red, :bold]      [:red, :bold]
  #     :b                 [:blue]
  #     :_b                [:bold]
  #     :__b               error
  #     :__ob              [:on_blue]
  #     "gsow"             [:green, :strikethrough, :on_white]
  #     "_noB"             [:negative, :on_black]
  def normalise_item(item)
    case item
    when Symbol then normalise_string(item.to_s)
    when Array  then normalise_array(item)
    when String then normalise_string(item)
    else             raise Col::Error, "Invalid item type: #{item.class}"
    end
  end

  # Input:  array of symbols
  # Result: array of symbols, each of which is a legitimate ANSIColor method
  # Note:   either the output is the same as the input, or an error is raised
  def normalise_array(array)
    invalid_items = array.select { |item| not Col::DB.method? item }
    case invalid_items.size
    when 0 then return array
    when 1 then raise Col::Error, "Invalid item: #{invalid_items.first.inspect}"
    else        raise Col::Error, "Invalid items: #{invalid_items.inspect}"
    end
  end

  # Examples
  #     Input           Output
  #      r               [:red]
  #      b               [:blue]
  #      rb              [:red, :bold]
  #      red             [:red]
  #      bold            [:bold]
  #      gsow            [:green, :strikethrough, :on_white]
  #      _b              [:bold]
  #      __ob            [:on_blue]
  def normalise_string(string)
    # Is it already one of the methods?  If so, easy.  If not, split and parse.
    if Col::DB.method? string
      [ string.intern ]
    elsif (1..4).include? string.size         # say: "g", "gb", "gbow"
      color, style, backg = extract(string)
      color = Col::DB.color(color)            # 'g'  -> :green
      style = Col::DB.style(style)            # 'b'  -> :bold
      backg = Col::DB.background(backg)       # 'ow' -> :on_white
      [ color, style, backg ].compact         # remove nil elements
    else
      raise Col::Error, "Invalid item: #{string.inspect}"
    end
  rescue Col::Error => e
    raise Col::Error, "Invalid item: #{string.inspect} (#{e.message})"
  end

  # Extracts color, style and background color.
  #   "gbow" -> ["g", "b", "ow"]
  #   "g"    -> ["g", nil, nil]
  #   "_b"   -> [nil, "b", nil]
  def extract(string)
    string += "    "
    color, style, backg = /^(.)(.)(..)/.match(string).captures
    color = nil if [' ', '_'].include? color
    style = nil if [' ', '_'].include? style
    backg = nil if ['  ', '__'].include? backg
    [color, style, backg]
  end

  def render(spec)
    ( (spec.size == 1) ? spec.first : spec ).inspect
  end
end

# --------------------------------------------------------------------------- #

class Col::DB
  COLORS = {
    'B' => :black,
    'r' => :red,
    'g' => :green,
    'y' => :yellow,
    'b' => :blue,
    'm' => :magenta,
    'c' => :cyan,
    'w' => :white
  }

  STYLES = {
    'b' => :bold,
    'd' => :dark,
    'i' => :italic,
    'u' => :underline,
    'U' => :underscore,
    'k' => :blink,
    'r' => :rapid_blink,
    'n' => :negative,
    'c' => :concealed,
    's' => :strikethrough,
  }

  BACKGROUND = {
    'oB' => :on_black,
    'or' => :on_red,
    'og' => :on_green,
    'oy' => :on_yellow,
    'ob' => :on_blue,
    'om' => :on_magenta,
    'oc' => :on_cyan,
    'ow' => :on_white
  }

  ALL_METHODS_SYMBOL = COLORS.values + STYLES.values + BACKGROUND.values
  ALL_METHODS_STRING = ALL_METHODS_SYMBOL.map { |x| x.to_s }
  require 'set'
  ALL_METHODS = Set[*ALL_METHODS_SYMBOL] + Set[*ALL_METHODS_STRING]

  def self.method?(x)
    ALL_METHODS.include? x
  end

  def self.color(key)
    get_value COLORS, key, "color"
  end

  def self.style(key)
    get_value STYLES, key, "style"
  end

  def self.background(key)
    get_value BACKGROUND, key, "background color"
  end

  # If the 'key' is nil, we return nil.  Otherwise, we insist that the key be a
  # valid color, style or background color.  If it's not, we raise an error
  # (that's what 'name' is for).
  #
  # Return the method name sought:  :green, :bold, :on_white, etc.
  def self.get_value(hash, key, name)
    if key.nil?
      nil
    else
      method = hash[key.to_s]
      if method.nil?
        raise Col::Error, "Invalid #{name} code: #{key}"
      end
      method
    end
  end

end  # Col::DB
