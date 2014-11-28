#encoding: utf-8

require File.expand_path('../spec_helper', __FILE__)

describe 'XCRes::LoggerSpec' do

  def subject
    XCRes::Logger
  end

  before do
    @logger = subject.new

    # Capture the STDOUT
    @out = StringIO.new("")
    $stdout = @out
    def out
      @out.string.chomp
    end
  end

  after do
    $stdout = STDOUT
  end

  describe '#initialize' do
    it 'should set attribute colored to true by default' do
      @logger.colored.should.be.true?
    end

    it 'should set attribute verbose to false by default' do
      @logger.verbose.should.be.false?
    end

    it 'should set attribute silent to false by default' do
      @logger.silent.should.be.false?
    end

    it 'should set attribute indentation to an empty string by default' do
      @logger.indentation.should.be.eql?('')
    end
  end

  describe '#inform' do
    it 'prints the message' do
      @logger.inform '%s %s %s', 'a', 'b', 'c'
      out.should.be.eql? 'a b c'
    end

    it 'prints the message with indentation if set' do
      @logger.indentation = '    '
      @logger.inform 'attention'
      out.should.be.eql? '    attention'
    end
  end

  describe '#inform_colored' do
    it 'works with string placeholders' do
      @logger.inform_colored 'a %s c', :red, 'b'
      out.should.be.eql? "\e[31ma \e[0m\e[31m\e[1mb\e[0m\e[0m\e[31m c\e[0m"
    end

    it 'works with multiple placeholders' do
      @logger.inform_colored 'a %s c %s e', :red, 'b', 'd'
      out.should.be.eql? "\e[31ma \e[0m\e[31m\e[1mb\e[0m\e[0m\e[31m c \e[0m\e[31m\e[1md\e[0m\e[0m\e[31m e\e[0m"
    end

    it 'works with integer number placeholders' do
      @logger.inform_colored '%d', :red, 2
      out.should.be.eql? "\e[31m\e[1m2\e[0m\e[0m"
    end

    it 'works with floating point number placeholders' do
      @logger.inform_colored '%.5f', :red, 3.14159265359
      out.should.be.eql? "\e[31m\e[1m3.14159\e[0m\e[0m"
    end

    it 'works with more complex placeholders' do
      @logger.inform_colored '%1$#+10.d', :red, 1234
      out.should.be.eql? "\e[31m\e[1m     +1234\e[0m\e[0m"
    end

    it 'works with escaped percents' do
      @logger.inform_colored '%%', :red
      out.should.be.eql? "\e[31m%\e[0m"
    end

    it 'works with empty arrays' do
      @logger.inform_colored '%s', :red, []
      out.should.be.eql? "\e[31m\e[1m[]\e[0m\e[0m"
    end

    it 'doesn\'t fail because of unescaped percents' do
      -> {
        @logger.inform_colored '%s', :red, '%'
      }.should.not.raise?(ArgumentError)
    end
  end

  describe '#log' do
    it 'prints nothing by default' do
      @logger.log 'test'
      out.should.be.empty?
    end

    it 'prints the message in verbose mode' do
      @logger.verbose = true
      @logger.log 'test'
      out.should.be.eql? "\e[35mⓋ test\e[0m"
    end
  end

  describe '#success' do
    it 'prints the message' do
      @logger.success 'test'
      out.should.be.eql? "\e[32m✓ test\e[0m"
    end
  end

  describe '#warn' do
    it 'prints the message' do
      @logger.warn 'test'
      out.should.be.eql? "\e[33m⚠ test\e[0m"
    end

    it 'accepts an Exception as message' do
      @logger.warn StandardError.new('test')
      out.should.be.eql? "\e[33m⚠ test\e[0m"
    end
  end

  describe '#fail' do
    it 'accepts a String as message' do
      @logger.fail 'test'
      out.should.be.eql? "\e[31m✗ test\e[0m"
    end

    it 'accepts an Exception as message' do
      @logger.fail StandardError.new('test')
      out.should.be.eql? "\e[31m✗ test\e[0m"
    end

    it 'prints the backtrace in verbose mode' do
      @logger.verbose = true
      exception = StandardError.new 'test'
      exception.expects(backtrace: %w[a b])
      @logger.fail exception
      out.should.be.eql? "\e[31m✗ test\e[0m\n\e[35mⓋ Backtrace:\na\nb\e[0m"
    end
  end

end
