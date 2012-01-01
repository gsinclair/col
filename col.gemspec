# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "col/version"

Gem::Specification.new do |s|
  s.name        = "col"
  s.version     = Col::VERSION
  s.authors     = ["Gavin Sinclair"]
  s.email       = ["gsinclair@gmail.com"]
  s.homepage    = "http://gsinclair.github.com/col.html"
  s.summary     = "High-level console color formatting"
  s.description = <<-EOF
    Console color formatting library with abbreviations (e.g. 'rb' for
    red and bold), and the ability to format several strings easily.
    No methods are added to core classes.
  EOF

  s.rubyforge_project = ""
  s.has_rdoc = false

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "term-ansicolor", ">= 1.0"

  #s.add_development_dependency "T"
  s.add_development_dependency "bundler"

  s.required_ruby_version = '>= 1.8.6'    # Not sure about this.
end
