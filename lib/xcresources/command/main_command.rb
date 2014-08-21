require 'xcodeproj'
require 'xcresources/logger'
require 'xcresources/command/command'
require 'xcresources/command/build_command'
require 'xcresources/command/version_command'

class XCResources::MainCommand < XCResources::Command

  subcommand 'build', 'Build the resources index files', XCResources::BuildCommand
  subcommand 'version', 'Show the gem version', XCResources::VersionCommand

end
