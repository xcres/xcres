require File.expand_path('../../spec_helper', __FILE__)

describe 'XCRes::ResourcesBuilder' do

  def subject
    XCRes::ResourcesBuilder
  end

  before do
    @builder = subject.new
    @builder.logger = stub('Logger')
  end

  describe "#initialize" do
    it 'should set attribute documented to true' do
      @builder.documented.should.be.true?
    end

    it 'should set attribute swift to false' do
      @builder.swift.should.be.false?
    end
  end

  describe "#resources_constant_name" do
    it 'should use the configured resources constant name' do
      @builder.resources_constant_name = 'test'
      @builder.resources_constant_name.should.be.eql?('test')
    end

    it 'should fallback to the basename of the output path [swift]' do
      @builder.output_path = 'test/R.swift'
      @builder.resources_constant_name.should.be.eql?('R')
    end
    
    it 'should fallback to the basename of the output path [objc]' do
      @builder.output_path = 'test/R.m'
      @builder.resources_constant_name.should.be.eql?('R')
    end
  end

  describe '#transform_key' do
    it 'should transform to camelCase' do
      @builder.send(:transform_key, 'ab_cd_ef', {}).should == 'abCdEf'
      @builder.send(:transform_key, 'ab/cd/ef', {}).should == 'abCdEf'
      @builder.send(:transform_key, 'Ab_1cdEf', {}).should == 'ab1cdEf'
    end
  end

  describe '#add_section' do
    it 'should raise if no items are given' do
      -> {
        @builder.add_section 'Test', nil
      }.should.raise?(ArgumentError, 'No items are given!')
    end

    it 'should not add keys, which are protected keywords [swift]' do
      @builder.logger.expects(:warn).twice
      @builder.swift = true
      @builder.add_section 'Test', {
        'default' => 'Default.png',
        'cat' => 'cat.gif',
        'auto' => 'auto.jpg',
        'internal' => 'internal.png'
      }
      @builder.sections.should.be.eql?('Test' => { 'cat' => 'cat.gif',
                                                  'auto' => 'auto.jpg' })
    end

    it 'should not add keys, which are protected keywords [objc]' do
      @builder.logger.expects(:warn).twice
      @builder.add_section 'Test', {
        'default' => 'Default.png',
        'cat' => 'cat.gif',
        'auto' => 'auto.jpg',
        'internal' => 'internal.png'
      }
      @builder.sections.should.be.eql?('Test' => { 'cat' => 'cat.gif',
                                              'internal' => 'internal.png' })
    end
  end

end
