require 'term/ansicolor'
require 'col/version'

# --------------------------------------------------------------------------- #

class Col

  # args: array of strings (to_s is called on each)
  def initialize(*args)
    @strings = args.map { |a| a.to_s }
  end

  def Col.[](*args)
    Col.new(*args)
  end

  COLORED_REGEXP = /\e\[                             # opening character sequence
                         (?: [34][0-7] | [0-9] ) ?   # optional code
                     ( ; (?: [34][0-7] | [0-9] ))*   # more optional codes
                    m                                # closing character
                   /x

  # Convenience method to remove color codes from a string.
  # Also available as Col.plain.
  def Col.uncolored(string)
    string.gsub(COLORED_REGEXP, '')
  end

  # Convenience method to remove color codes from a string.
  # Also available as Col.uncolored.
  def Col.plain(string)
    string.gsub(COLORED_REGEXP, '')
  end

  def Col.inline(*args)
    unless args.size % 2 == 0    # even? breaks 1.8.6
      raise Col::Error, "Col.inline requires an even number of arguments"
    end
    result = String.new
    Col::Utils.each_pair(args) do |string, format|
      result << Col(string.to_s).fmt(format)
    end
    result
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

  # Works nicely with puts. E.g. puts Col("...").red.bold
  def to_str
    to_s
  end

  def method_missing(message, *args, &block)
    unless args.empty?
      super   # We're not interested in a message with arguments; NoMethodError
    end
    if Col::DB.method?(message)
      Col.new( self.fmt(message) )   # Col["..."].yellow -> Col
                                     #  to allow Col["..."].yellow.bold
    else
      self.fmt(message)              # Col["..."].gbow   -> String
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
  end

  def result
    unless @strings.size == @format_spec.size
      raise Col::Error, "mismatching strings and specs"
    end
    result = String.new
    @strings.zip(@format_spec).each do |string, spec|
      d = decorated_string(string, spec)
      result << d
    end
    result
  end

  # e.g.
  #   string = "hello"
  #   spec = [:yellow, :bold, :on_red]
  #   result = "hello".send(:yellow).send(:bold).send(:on_red)
  def decorated_string(string, spec)
    raise Col::Error unless string.is_a? String and spec.is_a? Array \
                        and spec.all? { |e| e.is_a? Symbol }
    spec.inject(string) { |str, symbol| Term::ANSIColor.send(symbol, str) }
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
      # put the items together.  We remove nil elements.
      spec.map { |item| normalise_item(item) }.compact
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
  #     :_                 []
  #     [:_]               []
  #     [:_, :_]           []
  #       (etc.)
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
  # Note:   underscores and nil items are removed from the array
  def normalise_array(array)
    array.reject! { |x| x.nil? or x == :_ or x == '_' }
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
  #      _               []
  def normalise_string(string)
    # Is it already one of the methods?  If so, easy.  If not, split and parse.
    if string == "_"
      []
    elsif Col::DB.method? string
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

# --------------------------------------------------------------------------- #

# Utility methods to enable Col to work on 1.8.6.
class Col::Utils
  if RUBY_VERSION < "1.8.7"
    def self.each_pair(array)
      a = array.dup
      loop do
        pair = a.slice!(0,2)
        break if pair.empty?
        yield pair
      end
    end
  else
    def self.each_pair(array, &block)
      array.each_slice(2, &block)
    end
  end
end
