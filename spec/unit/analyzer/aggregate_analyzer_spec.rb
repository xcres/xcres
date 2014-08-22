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
      @analyzer = subject.new(mock('Target'))
      @analyzer.logger = mock('Logger')
      @analyzer.exclude_file_patterns = ['foo', 'bar']

      new_analyzer = @analyzer.add_with_class(XCResources::Analyzer, {})
      new_analyzer.should.be.an.instance_of?(XCResources::Analyzer)
      new_analyzer.should.be.equal?(@analyzer.analyzers.last)
      new_analyzer.target.should.be.equal?(@analyzer.target)
      new_analyzer.logger.should.be.equal?(@analyzer.logger)
      new_analyzer.exclude_file_patterns.should.be.equal?(@analyzer.exclude_file_patterns)
    end

    it 'should pass the options to the initializer' do
      result = @analyzer.add_with_class(XCResources::Analyzer, the_answer: 42)
      result.options.should.be.eql?({ the_answer: 42 })
    end

    it 'should pass the merged options to the initializer' do
      @analyzer.options = { the_question: '6x7=?' }
      result = @analyzer.add_with_class(XCResources::Analyzer,the_answer: 42)
      result.options.should.be.eql?({ the_question: '6x7=?', the_answer: 42 })
    end
  end

end
