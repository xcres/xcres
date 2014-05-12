# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'xcresources/version'

Gem::Specification.new do |spec|
  spec.name          = "xcresources"
  spec.version       = XCResources::VERSION
  spec.authors       = ["Marius Rackwitz"]
  spec.email         = ["git@mariusrackwitz.de"]
  spec.description   = %q{TODO: Write a gem description}
  spec.summary       = %q{TODO: Write a gem summary}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_runtime_dependency 'clamp', '~> 0.6.3'
  spec.add_runtime_dependency 'colored', '~> 1.2'
  spec.add_runtime_dependency 'activesupport', '>= 3.2.15', '< 4'
  spec.add_runtime_dependency 'apfel', '~> 0.0.5'

  spec.add_runtime_dependency 'xcodeproj', '~> 0.16.1'
end
