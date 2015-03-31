# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'n65/version'

Gem::Specification.new do |spec|
  spec.name          = "n65"
  spec.version       = N65::VERSION
  spec.authors       = ["Safiire"]
  spec.email         = ["safiire@irkenkitties.com"]
  spec.summary       = %q{An NES assembler for the 6502 microprocessor written in Ruby}
  spec.description   = %q{An NES assembler for the 6502 microprocessor written in Ruby}
  spec.homepage      = "http://github.com/safiire/n65"
  spec.license       = "GPL2"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
