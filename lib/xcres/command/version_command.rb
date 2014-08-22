require 'xcres/command/command'

# The +VersionCommand+ prints the gem version.
#
class XCRes::VersionCommand < XCRes::Command

  def execute
    super
    inform XCRes::VERSION
  end

end
