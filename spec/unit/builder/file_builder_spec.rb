require File.expand_path('../../spec_helper', __FILE__)

describe 'XCRes::FileBuilder' do

  def subject
    XCRes::FileBuilder
  end

  before do
    @builder = subject.new
    @builder.logger = stub('Logger')
  end

  describe "#prepare_output_path!" do
    # TODO: Mock fs
  end

  describe "#build" do
    it 'should prepare output path' do
      @builder.expects(:prepare_output_path!)
      @builder.build
    end
  end

  describe "#build_contents" do
    it 'should call the given block' do
      proc = Proc.new {}
      proc.expects(:call)
      @builder.build_contents &proc
    end

    it 'should pass a StringBuilder as first argument to the given block' do
      @builder.build_contents do |builder|
        builder.should.be.an.instance_of?(XCRes::StringBuilder)
      end
    end
  end

  describe "#write_file_eventually" do
    # TODO: Mock fs
  end

  describe "#write_file" do
    # TODO: Mock fs
  end
end
