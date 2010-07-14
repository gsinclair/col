require 'rake'  # FileList
Gem::Specification.new do |spec|
  spec.name = "col"
  spec.version = "1.0.0"
  spec.summary = "high-level console color formatting"
  spec.description = <<-EOF
    Console color formatting library with abbreviations (e.g. 'rb' for
    red and bold), and the ability to format several strings easily.
  EOF
  spec.email = "gsinclair@gmail.com"
  spec.homepage = "http://gsinclair.github.com/col.html"
  spec.authors = ['Gavin Sinclair']

  spec.files = FileList['lib/**/*.rb', '[A-Z]*', 'test/**/*'].to_a
  spec.test_files = FileList['test/**/*'].to_a
  spec.has_rdoc = true

  spec.add_dependency("term-ansicolor", ">= 1.0")
  spec.required_ruby_version = '>= 1.8.6'    # Not sure about this.
end
