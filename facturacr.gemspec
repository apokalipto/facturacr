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

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "minitest", '~> 5.11'
  spec.add_development_dependency "minitest-colorize", '~> 0.0'

  spec.add_dependency 'rest-client', '~> 2.0'
  spec.add_dependency 'nokogiri', '~> 1.8'
  spec.add_dependency 'colorize', '~> 0.8'
  spec.add_dependency 'thor', '~> 1.2.1'
  spec.add_dependency 'activemodel', '>= 3.2'
  spec.add_dependency 'awesome_print', '~> 1.8'
end
