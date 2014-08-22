class XCResources::StringBuilder

  attr_accessor :indentation_string
  attr_accessor :result

  def initialize
    self.indentation_string = '    '
    self.result = ''
  end

  def << input
    # Only indent string inputs on nested / delegating string builders
    input = self.indentation_string + input unless result.is_a? String

    self.result << input
  end

  alias write :<<

  def writeln input=''
    self << input + "\n"
  end

  def section &block
    builder = self.class.new
    builder.indentation_string = self.indentation_string
    builder.result = self
    block.call builder
  end

end
