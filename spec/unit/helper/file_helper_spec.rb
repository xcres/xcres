require File.expand_path('../../spec_helper', __FILE__)

describe 'XCRes::FileHelper' do

  def subject
    Class.new.class_eval { include XCRes::FileHelper }.new
  end

  describe '#basename_without_ext' do
    it 'should raise if the name is not given' do
      -> { subject.basename_without_ext(nil) }.should.raise?(TypeError)
    end

    it 'should return the name itself if there is not extension' do
      subject.basename_without_ext('dir/base').should.be.eql?('base')
    end

    it 'should return the name without extension' do
      subject.basename_without_ext('b/a.gif').should.be.eql?('a')
      subject.basename_without_ext('b/A.bundle').should.be.eql?('A')
    end
  end

end
