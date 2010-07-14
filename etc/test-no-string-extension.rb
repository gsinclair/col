require 'attest/auto'
require 'col'

D "String does not have Term::ANSIColor mixed in" do
  E(NoMethodError) { "col".red }
end

D "The result of Col#fmt does not have Term::ANSIColor mixed in" do
  str = Col("string").r
  E { str.red }
end
