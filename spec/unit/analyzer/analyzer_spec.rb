require File.expand_path('../../spec_helper', __FILE__)

describe 'XCResources::Analyzer' do

  def subject
    XCResources::Analyzer
  end

  before do
    @analyzer = subject.new
  end

  describe '#filter_exclusions' do
    describe 'single asterisk' do
      it 'rejects file paths on first hierarchy level' do
        @analyzer.exclude_file_patterns = ['*.gif']
        @analyzer.filter_exclusions(['cat.jpg', 'doge.gif']).should.be.eql?(['cat.jpg'])
      end

      it 'rejects file paths in nested directories by default' do
        @analyzer.exclude_file_patterns = ['*.gif']
        @analyzer.filter_exclusions(['top_doge.gif', 'sub/sub/doge.gif', 'sub/sub/doge.gif']).should.be.eql?([])
      end
    end

    describe 'double asterisk' do
      it 'rejects file paths in nested directories only' do
        @analyzer.exclude_file_patterns = ['**.gif']
        @analyzer.filter_exclusions(['top_doge.gif', 'sub/sub/doge.gif', 'sub/sub/doge.gif']).should.be.eql?([])
      end
    end

    it 'rejects hidden files' do
      @analyzer.exclude_file_patterns = ['.git']
      @analyzer.filter_exclusions(['.git']).should.be.eql?([])
    end
  end

  describe '#find_files_by_extname' do
    before do
      @project = stub('Project')
      @analyzer.stubs(:project).returns(@project)
    end

    it 'should return an empty list for an empty project' do
      @file_ref_bundle = stub('FileRef', path: 'the-whole.bundle')
      @file_ref_jpg    = stub('FileRef', path: 'awesome.jpg')
      @project.stubs(:files).returns([@file_ref_bundle, @file_ref_jpg])
      @analyzer.find_file_refs_by_extname('.bundle').should.be.eql?([@file_ref_bundle])
    end
  end

end
