# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'formant/version'

Gem::Specification.new do |spec|
  spec.name          = "formant"
  spec.version       = Formant::VERSION
  spec.authors       = ["Anthony Garcia"]
  spec.email         = ["polypressure@outlook.com"]

  spec.summary       = "Minimalist form object implementation."
  spec.homepage      = "https://github.com/polypressure/formant"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "activemodel", "~>4.0"
  spec.add_development_dependency "activesupport", "~>4.0"
  spec.add_development_dependency "actionview", "~>4.0"
  spec.add_development_dependency "minitest", "~> 5.5"
  spec.add_development_dependency "m", "~> 1.3.1"
  spec.add_development_dependency 'minitest-reporters'
  spec.add_development_dependency "codeclimate-test-reporter"
  spec.add_development_dependency 'phony_rails'

end
