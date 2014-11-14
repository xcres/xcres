require File.expand_path('../../spec_helper', __FILE__)

describe 'XCRes::InstallCommand' do

  def subject
    XCRes::InstallCommand
  end

  before do
    @cmd = subject.new('xcres', [], {})
    @cmd.stubs(:project).returns(xcodeproj)
  end

  describe '#prefix_headers' do
    it 'should return the expected prefix headers' do
      @cmd.prefix_headers.to_a.should == [Pathname('Example/Example-Prefix.pch')]
    end

    it 'should return empty array if a target has no value for GCC_PREFIX_HEADER' do
      @cmd.target.build_configurations.each do |config|
        config.build_settings.stubs(:[]).with('GCC_PREFIX_HEADER').returns(nil)
      end
      @cmd.prefix_headers.to_a.should == []
    end
  end

end
