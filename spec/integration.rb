require 'bacon'
require 'pretty_bacon'
require 'clintegracon'

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
  c.ignores %r(^Example/Example[./])
end


describe_cli 'xcresources' do

  subject do |s|
    s.executable = "#{BIN}/xcresources"
    s.default_args = [
      '--verbose',
      '--no-ansi'
    ]
    s.replace_path ROOT.to_s, 'ROOT'
  end

  describe 'Build' do
    behaves_like cli_spec('build', '', 'Example .')
  end

  describe 'Get help' do
    behaves_like cli_spec('help', '--help')
  end

end
