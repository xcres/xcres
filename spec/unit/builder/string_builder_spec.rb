require File.expand_path('../../spec_helper', __FILE__)

describe 'XCResources::StringBuilder' do

  def subject
    XCResources::StringBuilder
  end

  before do
    @builder = subject.new
  end

  describe '#initialize' do
    it 'should set indentation string' do
      @builder.indentation_string.should.be.eql?('    ')
    end

    it 'should set an empty result' do
      @builder.result.should.be.not.nil?
      @builder.result.should.be.empty?
    end
  end

  describe '#write' do
    it 'should add input to result' do
      @builder.write 'test'
      @builder.result.should.be.eql?('test')
    end

    it 'should not add any separation' do
      @builder.write 'foo'
      @builder.write 'bar'
      @builder.result.should.be.eql?('foobar')
    end
  end

  describe '#writeln' do
    it 'should write a new line' do
      @builder.write '{'
      @builder.writeln 'foo'
      @builder.write '}'
      @builder.result.should.be.eql?("{foo\n}")
    end
  end

  describe '#section'  do
    it 'should write a section with increased indentation' do
      @builder.writeln '{'
      @builder.section do |b|
        b.writeln 'c'
      end
      @builder.writeln '}'
      @builder.result.should.be.eql?("{\n    c\n}\n")
    end

    it 'should write a sub section with increased indentation' do
      @builder.indentation_string = ' '
      @builder.writeln 'a{'
      @builder.section do |b|
        b.writeln 'b{'
        b.section do |b|
          b.writeln 'c'
        end
        b.writeln '}b'
      end
      @builder.writeln '}a'
      @builder.result.should.be.eql?("a{\n b{\n  c\n }b\n}a\n")
    end
  end

end
