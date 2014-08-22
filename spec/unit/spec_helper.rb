require 'bacon'
require 'pretty_bacon'
require 'mocha-on-bacon'
require 'xcresources'
require 'pathname'

def fixture_path
  @fixture_path ||= Pathname(File.expand_path('../../fixtures', __FILE__))
end

def xcodeproj
  Xcodeproj::Project.open(fixture_path + 'Example/Example.xcodeproj')
end

def app_target
  xcodeproj.targets.find { |t| t.name == 'Example' }
end
