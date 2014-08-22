# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'xcresources/version'

Gem::Specification.new do |spec|
  spec.name          = "xcresources"
  spec.version       = XCResources::VERSION
  spec.authors       = ["Marius Rackwitz"]
  spec.homepage      = "https://github.com/mrackwitz/xcresources"
  spec.email         = ["git@mariusrackwitz.de"]
  spec.license       = "MIT"

  spec.description   = "xcresources searches your Xcode project for resources" \
                       "and generates an index as struct constants."
  spec.summary       = %q{
  `xcresources` searches your Xcode project for resources and generates an index
  as struct constants. So you will never have to reference a resource, without
  knowing already at compile if it exists or not.
  }

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'bacon', '~> 1.1'
  spec.add_development_dependency 'prettybacon'
  spec.add_development_dependency 'mocha'
  spec.add_development_dependency 'mocha-on-bacon'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'inch'

  spec.add_runtime_dependency 'clamp', '~> 0.6.3'
  spec.add_runtime_dependency 'colored', '~> 1.2'
  spec.add_runtime_dependency 'activesupport', '>= 3.2.15', '< 4'
  spec.add_runtime_dependency 'apfel', '~> 0.0.5'
  spec.add_runtime_dependency 'xcodeproj', '~> 0.18'
  spec.add_runtime_dependency 'libxml-ruby'
end
