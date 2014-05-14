class XCResources::Logger

  attr_accessor :verbose, :silent
  alias :verbose? verbose
  alias :silent? silent

  def inform message, *format_args
    puts message % format_args unless silent?
  end

  # Print arguments bold
  def inform_colored message, color, *format_args
    # TODO: Test e.g: 'a %s b %10.00d c %1d d' => ["a %s", " b %10.00d", " c %1d", " d"]
    message = message.gsub(/%\d*\.?\d*[a-z]/, "\0"+'\0'+"\0").split("\0").map(&color).reduce('', :+)
    inform message, *format_args.map(&:to_s).map(&color).map(&:bold)
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
    inform_colored '✗' + ' ' + message, :red, *format_args
  end

end