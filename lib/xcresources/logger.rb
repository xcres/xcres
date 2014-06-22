require 'colored'

class XCResources::Logger

  attr_accessor :verbose, :silent, :colored
  alias :verbose? verbose
  alias :silent? silent
  alias :colored? colored

  def initialize
    self.colored = true
  end

  def inform message, *format_args
    puts message % format_args unless silent?
  end

  # Print arguments bold
  def inform_colored message, color, *format_args
    if colored?
      # TODO: Test e.g: 'a %s b %10.00d c %1d d' => ["a %s", " b %10.00d", " c %1d", " d"]
      message = message.gsub(/%\d*\.?\d*[a-z]/, "\0"+'\0'+"\0").split("\0").map(&color).reduce('', :+)
      format_args = format_args.map(&:to_s).map(&color).map(&:bold)
    end
    inform message, *format_args
  end

  def log message, *format_args
    inform_colored 'Ⓥ' + ' ' + message, :magenta, *format_args if verbose?
  end

  def success message, *format_args
    inform_colored '✓' + ' ' + message, :green, *format_args
  end

  def warn message, *format_args
    inform_colored '⚠' + ' ' + message, :yellow, *format_args
  end

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
