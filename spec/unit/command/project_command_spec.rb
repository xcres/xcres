require File.expand_path('../../spec_helper', __FILE__)

describe 'XCRes::ProjectCommand' do

  def subject
    XCRes::ProjectCommand
  end

  before do
    @cmd = subject.new('xcres', [], {})
    @cmd.stubs(:project).returns(xcodeproj)
  end

  describe '#application_targets' do
    it 'should return the expected application target' do
      @cmd.application_targets.count.should.eql? 1
      target = @cmd.application_targets.first
      target.should.be.an.instance_of?(Xcodeproj::Project::Object::PBXNativeTarget)
      target.name.should.eql?('Example')
    end
  end

end
