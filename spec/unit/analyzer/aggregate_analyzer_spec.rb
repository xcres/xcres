require File.expand_path('../../spec_helper', __FILE__)

describe 'XCResources::AggregateAnalyzer' do

  def subject
    XCResources::AggregateAnalyzer
  end

  before do
    @analyzer = subject.new
  end

  describe '#initialize' do
    it 'should initialize #analyzers with an empty array' do
      @analyzer.analyzers.should.be.eql?([])
    end
  end

  describe '#analyze' do
    it 'should return aggregated output of all child analyzers' do
      section1 = mock()
      @analyzer.analyzers << mock(analyze: [section1])

      section2 = mock()
      @analyzer.analyzers << mock(analyze: [section2])

      @analyzer.analyze.should.be.eql?([section1, section2])
    end

    it 'should return an empty array if there are no child analyzers' do
      @analyzer.analyze.should.be.empty?
    end
  end

  describe '#add_with_class' do
    it 'should init an analyzer of given class with current attributes' do
      @analyzer = subject.new(mock())
      @analyzer.logger = mock()
      @analyzer.exclude_file_patterns = ['foo', 'bar']

      @analyzer.add_with_class(XCResources::Analyzer, {})
      new_analyzer = @analyzer.analyzers.last
      new_analyzer.project.should.be.equal?(@analyzer.project)
      new_analyzer.logger.should.be.equal?(@analyzer.logger)
      new_analyzer.exclude_file_patterns.should.be.equal?(@analyzer.exclude_file_patterns)
    end

    it 'should pass the options to the initializer' do
      analyzer_class = mock()
      options = mock()
      analyzer_class.expects(:new).with(nil, options).returns(XCResources::Analyzer.new)
      @analyzer.add_with_class(analyzer_class, options)
    end
  end

end
