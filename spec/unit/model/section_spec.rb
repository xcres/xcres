require File.expand_path('../../spec_helper', __FILE__)

describe 'XCResources::Section' do

  def subject
    XCResources::Section
  end

  describe '#initialize' do
    it 'should initialize a new section without options' do
      section = subject.new('Name', { 'a' => 'a.gif' })
      section.name.should.be.eql?('Name')
      section.items.should.be.eql?({ 'a' => 'a.gif' })
      section.options.should.be.eql?({})
    end

    it 'should initialize a new section with options' do
      section = subject.new('Name', { 'a' => 'a.gif' }, { custom_flag: true })
      section.name.should.be.eql?('Name')
      section.items.should.be.eql?({ 'a' => 'a.gif' })
      section.options.should.be.eql?({ custom_flag: true })
    end
  end

  describe '#==' do
    before do
      @left = subject.new('Cats', 'cat' => 'cat.gif')
    end

    it 'should be true for equal sections' do
      (@left == subject.new('Cats', 'cat' => 'cat.gif')).should.be.true?
    end

    it 'should be false if name is different' do
      (@left == subject.new('Dog', 'cat' => 'cat.gif')).should.be.false?
    end

    it 'should be false if items are different' do
      (@left == subject.new('Cat', 'dog' => 'dog.gif')).should.be.false?
    end

    it 'should be false if options are different' do
      (@left == subject.new('Cat', { 'cat' => 'cat.gif' }, custom_flag: true)).should.be.false?
    end
  end

end
