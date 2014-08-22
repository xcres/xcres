#encoding: utf-8

require 'colored'

# A Logger utility help class
#
class XCRes::Logger

  # @return [Bool]
  #         if set to false, calls to #log will be ignored
  #         otherwise they will be printed, false by default.
  attr_accessor :verbose
  alias :verbose? verbose

  # @return [Bool]
  #         if set to true, all log calls of all kinds will be ignored
  #         otherwise they will be printed, false by default.
  attr_accessor :silent
  alias :silent? silent

  # @return [Bool]
  #         if set to true, ANSI colors will be used to color the output
  #         otherwise it will output plain text, true by default.
  attr_accessor :colored
  alias :colored? colored

  # @return [String]
  #         the indentation of the output, empty string by default.
  attr_accessor :indentation

  # Initialize a new logger
  #
  def initialize
    self.silent = false
    self.verbose = false
    self.colored = true
    self.indentation = ''
  end

  # Prints a formatted message
  #
  # @param [String] message
  #        the message, which can have format placeholders
  #
  # @param [#to_s...] format_args
  #        will be passed as right hand side to the percent operator,
  #        which will fill the format placeholders used in the message
  #
  def inform message, *format_args
    puts indentation + message % format_args unless silent?
  end

  # Prints a formatted message in a given color, and prints its arguments
  # with bold font weight
  #
  # @param [String] message
  #        the message, which can have format placeholders
  #
  # @param [Symbol] color
  #        the color, String has to #respond_to? this
  #
  # @param [#to_s...] format_args
  #        will be passed as right hand side to the percent operator,
  #        which will fill the format placeholders used in the message
  #
  def inform_colored message, color, *format_args
    if colored?
      parts = message
         .gsub(/%[\ +#]?\d*\.?\d*[a-z]/, "\0"+'\0'+"\0")
         .split("\0")
         .reject(&:empty?)
      message = parts.map do |part|
        if part[0] == '%' && part[1] != '%'
          (part % format_args.shift).bold.gsub('%', '%%')
        else
          part
        end
      end.map(&color).join('')
    end
    inform message, *format_args
  end

  # Print a log message of log level verbose
  #
  # @param [String] message
  #        the message, which can have format placeholders
  #
  # @param [#to_s...] format_args
  #        will be passed as right hand side to the percent operator,
  #        which will fill the format placeholders used in the message
  #
  def log message, *format_args
    inform_colored 'Ⓥ' + ' ' + message, :magenta, *format_args if verbose?
  end

  # Print a log message to indicate success of an operation in green color
  #
  # @param [String] message
  #        the message, which can have format placeholders
  #
  # @param [#to_s...] format_args
  #        will be passed as right hand side to the percent operator,
  #        which will fill the format placeholders used in the message
  #
  def success message, *format_args
    inform_colored '✓' + ' ' + message, :green, *format_args
  end

  # Print a warning log message in yellow color
  #
  # @param [String] message
  #        the message, which can have format placeholders
  #
  # @param [#to_s...] format_args
  #        will be passed as right hand side to the percent operator,
  #        which will fill the format placeholders used in the message
  #
  def warn message, *format_args
    inform_colored '⚠' + ' ' + message, :yellow, *format_args
  end

  # Print a log message to indicate failure of an operation in red color
  #
  # @param [String|Exception] message
  #        The message, which can have format placeholders,
  #        can also be a kind of Exception, then its message would been
  #        used instead. The backtrace will be only printed, if the verbose
  #        mode is enabled.
  #
  # @param [#to_s...] format_args
  #        will be passed as right hand side to the percent operator,
  #        which will fill the format placeholders used in the message
  #
  def fail message, *format_args
    exception = nil
    if message.kind_of? Exception
      exception = message
      message = exception.message
    end

    inform_colored '✗' + ' ' + message, :red, *format_args

    if verbose? && exception != nil
      log "Backtrace:\n"+exception.backtrace.join("\n"), :red
    end
  end

end
