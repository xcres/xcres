require 'bacon'
require 'pretty_bacon'
require 'clintegracon'
require File.expand_path('../spec_helper/xcodeproj_project_yaml', __FILE__)

ROOT = Pathname.new(File.expand_path('../..', __FILE__))
BIN  = ROOT + 'bin'

CLIntegracon.configure do |c|
  c.spec_path = ROOT + 'spec/integration'
  c.temp_path = ROOT + 'tmp/integration'

  c.hook_into :bacon

  c.ignores '.DS_Store'
  c.ignores '**.DS_Store'
  c.ignores '.gitkeep'
  c.ignores %r[/xcuserdata/]
  c.ignores %r[/DerivedData/]

  # Transform produced project files to YAMLs
  c.transform_produced "**/*.xcodeproj" do |path|
    # Creates a YAML representation of the Xcodeproj files
    # which should be used as a reference for comparison.
    xcodeproj = Xcodeproj::Project.open(path)
    File.open("#{path}.yaml", "w") do |file|
      file.write xcodeproj.to_yaml
    end
  end

  # So we don't need to compare them directly
  c.ignores %r[\.xcodeproj/]
end


describe_cli 'xcres' do

  subject do |s|
    s.executable = "#{BIN}/xcres"
    s.default_args = [
      '--verbose',
      '--no-ansi'
    ]
    s.replace_path ROOT.to_s, 'ROOT'
  end

  describe 'Build' do
    describe 'with default settings' do
      behaves_like cli_spec('build', '', 'build Example .')
    end

    describe 'with variable INFOPLIST_PATH' do
      behaves_like cli_spec('build-var-infoplist', '', 'build Example .')
    end

    describe 'with resource which has a protected name' do
      behaves_like cli_spec('build-keyword-clash', '', 'build Example .')
    end

    describe 'with swift' do
      behaves_like cli_spec('build-swift', '', 'build --swift Example .')
    end
  end

  describe 'Install' do
    describe 'with default template' do
      behaves_like cli_spec('install', '', 'install Example')
    end

    describe 'with existing installation' do
      behaves_like cli_spec('install-again', '', 'install Example')
    end

    describe 'without supporting files' do
      behaves_like cli_spec('install-no-supporting-files', '', 'install Example')
    end

    describe 'with moved supporting files' do
      behaves_like cli_spec('install-moved-supporting-files', '', 'install Example')
    end
  end

  describe 'Get help' do
    behaves_like cli_spec('help', '--help')
  end

  describe 'Get version' do
    behaves_like cli_spec('version', 'version')
  end

end
