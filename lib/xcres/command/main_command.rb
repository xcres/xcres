require 'xcodeproj'
require 'xcres/logger'
require 'xcres/command/command'
require 'xcres/command/build_command'
require 'xcres/command/install_command'
require 'xcres/command/version_command'

class XCRes::MainCommand < XCRes::Command

  subcommand 'build', 'Build the resources index files', XCRes::BuildCommand
  subcommand 'install', 'Install a build phase into the project', XCRes::InstallCommand
  subcommand 'version', 'Show the gem version', XCRes::VersionCommand

end
