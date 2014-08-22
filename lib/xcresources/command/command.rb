require 'clamp'
require 'xcresources/logger'

# Base class for commands
#
class XCResources::Command < Clamp::Command

  option ['--silent'], :flag, 'Show nothing'
  option ['--[no-]ansi'], :flag, 'Show output without ANSI codes', default: true
  option ['-v', '--verbose'], :flag, 'Show more debugging information'

  # Run the command, with the specified arguments.
  #
  # This calls {#parse} to process the command-line arguments,
  # then delegates to {#execute}.
  #
  # @param [Array<String>] arguments command-line arguments
  #
  def run(arguments)
    super
  rescue ArgumentError => error
    fail error
    exit 1
  end

  def execute
    # Configure logger
    configure_logger
  end

  #----------------------------------------------------------------------------#

  # @!group Logger

  # Lazy-instantiate a logger
  #
  def logger
    @logger ||= XCResources::Logger.new
  end

  # Delegate log level methods to the logger
  #
  delegate :inform, :log, :success, :warn, :fail, to: :logger

  # Checks the configured option to configure the logger
  #
  def configure_logger
    logger.silent = silent?
    logger.colored = ansi?
    if verbose?
      logger.verbose = verbose?
      log 'Verbose mode is enabled.'
    end
  end

end
