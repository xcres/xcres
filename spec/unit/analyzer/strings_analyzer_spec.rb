require File.expand_path('../../spec_helper', __FILE__)

describe 'XCRes::StringsAnalyzer' do

  def subject
    XCRes::StringsAnalyzer
  end

  before do
    @target = stub('Target', build_configurations: [])
    @project = stub('Project', files: [], path: Pathname('.'))
    @target.stubs(project: @project)

    @analyzer = subject.new(@target)
    @analyzer.logger = stub('Logger', :log)
    @analyzer.expects(:warn).never
    @analyzer.expects(:error).never
  end

  describe "#initialize" do
    it 'should set given target as attribute' do
      @analyzer = subject.new(@target)
      @analyzer.target.should.be.eql?(@target)
      @analyzer.project.should.be.eql?(@project)
    end

    it 'should set option :default_language as attribute' do
      @analyzer = subject.new(@target, default_language: 'en')
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
      @analyzer.build_section.should.be.eql?(XCRes::Section.new 'Strings', {})
    end

    it 'should return a new section if there are strings files' do
      strings_file_ref = stub('FileRef', {
        name:      'en',
        path:      'Localizable.strings',
        real_path: Pathname(File.expand_path('./en.lproj/Localizable.strings'))
      })
      @analyzer.stubs(:strings_file_refs).returns([strings_file_ref])
      @analyzer.stubs(:keys_by_file)
        .with(Pathname('en.lproj/Localizable.strings'))
        .returns({ 'greeting' => { value: 'greeting' }})
      @analyzer.build_section.should.be.eql?(XCRes::Section.new 'Strings', { 'greeting' => { value: 'greeting' }})
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

  describe "#find_strings_file_refs" do
    before do
      @target = app_target
      @analyzer = subject.new(@target)
    end

    it 'should return the strings files of the fixture project' do
      strings_files = @analyzer.find_file_refs_by_extname('.strings')
      strings_files.count.should.be.eql?(3)
      strings_files[0].path.should.be.eql?('en.lproj/InfoPlist.strings')
      strings_files[1].path.should.be.eql?('en.lproj/Localizable.strings')
      strings_files[2].path.should.be.eql?('de.lproj/Localizable.strings')
    end
  end

  describe "#read_strings_file" do
    it 'should read a valid file' do
      @analyzer.read_strings_file(fixture_path + 'Example/Example/en.lproj/Localizable.strings').should == {
        "foo"               => "Foo String",
        "bar"               => "Bar String",
        "en_exclusive"      => "Only in english",
        "example"           => "Lorem Ipsum",
        "123-abc-3e7.text"  => "Hello Storyboards",
      }
    end

    it 'should raise an error for an invalid file' do
      proc do
        @analyzer.read_strings_file(fixture_path + 'StringsFiles/syntax_error_missing_semicolon.strings')
      end.should.raise(StandardError).message.should.include "Old-style plist parser: missing semicolon in dictionary on line 2."
    end
  end

  describe "#keys_by_file" do
    it 'should return the string keys hash' do
      path = fixture_path + 'Example/Example/en.lproj/Localizable.strings'
      @analyzer.keys_by_file(path).should == {
        "foo"          => { value: "foo",          comment: "Foo String"      },
        "bar"          => { value: "bar",          comment: "Bar String"      },
        "en_exclusive" => { value: "en_exclusive", comment: "Only in english" },
        "example"      => { value: "example",      comment: "Lorem Ipsum"     },
      }
    end
  end

end
