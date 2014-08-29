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
  end

  describe "#resources_constant_name" do
    it 'should use the configured resources constant name' do
      @builder.resources_constant_name = 'test'
      @builder.resources_constant_name.should.be.eql?('test')
    end

    it 'should fallback to the basename of the output path' do
      @builder.output_path = 'test/R.m'
      @builder.resources_constant_name.should.be.eql?('R')
    end
  end

  describe '#add_section' do
    it 'should raise if no items are given' do
      -> {
        @builder.add_section 'Test', nil
      }.should.raise?(ArgumentError, 'No items are given!')
    end

    it 'should not add keys, which are protected keywords' do
      @builder.logger.expects(:warn).twice
      @builder.add_section 'Test', {
        'default' => 'Default.png',
        'cat' => 'cat.gif',
        'auto' => 'auto.jpg'
      }
      @builder.sections.should.be.eql?('Test' => { 'cat' => 'cat.gif' })
    end
  end

end
