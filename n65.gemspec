# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'n65/version'

Gem::Specification.new do |spec|
  spec.name          = 'n65'
  spec.version       = N65::VERSION
  spec.authors       = ['Safiire']
  spec.email         = ['safiire@irkenkitties.com']
  spec.summary       = 'An NES assembler for the 6502 microprocessor'
  spec.description   = 'An NES assembler for the 6502 microprocessor'
  spec.homepage      = 'http://github.com/safiire/n65'
  spec.license       = 'GPL2'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.4.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
end
