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

end
