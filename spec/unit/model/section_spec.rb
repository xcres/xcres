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

end
