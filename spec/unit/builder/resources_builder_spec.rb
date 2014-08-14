require File.expand_path('../../spec_helper', __FILE__)

describe 'XCResources::ResourcesBuilder' do

  def subject
    XCResources::ResourcesBuilder
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

end
