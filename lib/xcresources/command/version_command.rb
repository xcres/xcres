require 'xcresources/command/command'

# The +VersionCommand+ prints the gem version.
#
class XCResources::VersionCommand < XCResources::Command

  def execute
    super
    inform XCResources::VERSION
  end

end
