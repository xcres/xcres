require File.expand_path('../../spec_helper', __FILE__)

describe 'XCResources::StringsAnalyzer' do

  def subject
    XCResources::StringsAnalyzer
  end

  before do
    @project = mock('Project')
    @project.stubs(files: [], targets: [])

    @analyzer = subject.new(@project)
    @analyzer.logger = stub('Logger', :log)
  end

  describe "#initialize" do
    it 'should set given project as attribute' do
      @analyzer = subject.new(@project)
      @analyzer.project.should.be.eql?(@project)
    end

    it 'should set option :default_language as attribute' do
      @analyzer = subject.new(@project, default_language: 'en')
      @analyzer.default_language.should.be.eql?('en')
    end
  end

  describe "#analyze" do
    it 'should return the built sections' do
      section = mock()
      @analyzer.expects(:build_section).returns(section)
      @analyzer.analyze.should.be.eql?([section])
    end
  end

  describe "#build_section" do
    it 'should return an empty section if there are no strings files' do
      @analyzer.stubs(:strings_file_refs).returns([])
      @analyzer.build_section.should.be.eql?(XCResources::Section.new 'Strings', {})
    end

    it 'should return a new section if there are strings files' do
      strings_file_ref = stub('FileRef', name: 'en', path: 'Localizable.strings', real_path: 'en.lproj/Localizable.strings')
      @analyzer.stubs(:strings_file_refs).returns([strings_file_ref])
      @analyzer.stubs(:keys_by_file).with(strings_file_ref.real_path).returns({ 'greeting' => { value: 'greeting' }})
      @analyzer.build_section.should.be.eql?(XCResources::Section.new 'Strings', { 'greeting' => { value: 'greeting' }})
    end
  end

  describe "#languages" do
    it 'should return the default language if it is set' do
      @analyzer.default_language = 'en'
      @analyzer.languages.should.be.eql?(['en'])
    end

    it 'should return an empty array if there is no used language' do
      @analyzer.expects(:native_dev_languages).returns(['en'].to_set).at_least_once
      @analyzer.expects(:used_languages).returns([].to_set).at_least_once
      @analyzer.languages.should.be.eql?([].to_set)
    end

    it 'should return the used languages if there is no matching native dev language' do
      @analyzer.expects(:native_dev_languages).returns(['de'].to_set).at_least_once
      @analyzer.expects(:used_languages).returns(['en', 'es'].to_set).at_least_once
      @analyzer.languages.should.be.eql?(['en', 'es'].to_set)
    end

    it 'should return the intersection of languages if there is a common language' do
      @analyzer.expects(:native_dev_languages).returns(['en'].to_set).at_least_once
      @analyzer.expects(:used_languages).returns(['en', 'es'].to_set).at_least_once
      @analyzer.languages.should.be.eql?(['en'].to_set)
    end
  end

end
