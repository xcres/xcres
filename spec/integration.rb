require 'bacon'
require 'pretty_bacon'
require 'clintegracon'

ROOT = Pathname.new(File.expand_path('../..', __FILE__))
BIN  = ROOT + 'bin'

CLIntegracon.configure do |c|
  c.context.spec_path = ROOT + 'spec/integration'
  c.context.temp_path = ROOT + 'tmp/integration'

  c.hook_into :bacon
end


describe_cli 'xcresources' do

  subject do |s|
    s.executable = "#{BIN}/xcresources"
    s.default_args = [
      '--verbose',
      '--no-ansi'
    ]
    s.has_special_path ROOT.to_s, 'ROOT'
  end

  context do |c|
    c.ignores '.DS_Store'
    c.ignores '**.DS_Store'
    c.ignores '.gitkeep'
    c.ignores %r[/xcuserdata/]
  end

  describe 'Build' do
    behaves_like cli_spec('build', '', 'Example')
  end

  describe 'Get help' do
    behaves_like cli_spec('help', '--help')
  end

end
