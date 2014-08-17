require 'bacon'
require 'pretty_bacon'
require 'mocha-on-bacon'
require 'xcresources'
require 'pathname'

def fixture_path
  @fixture_path ||= Pathname(File.expand_path('../../fixtures', __FILE__))
end
