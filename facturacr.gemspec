# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'facturacr/version'

Gem::Specification.new do |spec|
  spec.name          = "facturacr"
  spec.version       = FE::VERSION
  spec.authors       = ["Josef Sauter"]
  spec.email         = ["Josef.Sauter@gmail.com"]

  spec.summary       = %q{Facturación Electrónica de Costa Rica}
  spec.homepage      = "https://github.com/apokalipto/facturacr"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "minitest-colorize"
  
  spec.add_dependency 'rest-client'
  spec.add_dependency 'nokogiri'
  spec.add_dependency 'colorize'
  spec.add_dependency 'thor'
  spec.add_dependency 'activemodel'
  spec.add_dependency 'awesome_print'
end
