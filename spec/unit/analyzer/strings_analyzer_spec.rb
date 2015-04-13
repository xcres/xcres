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
    it 'shouldn\'t return a section if there are no strings files' do
      @analyzer.stubs(:strings_file_refs).returns([])
      @analyzer.build_section.should.be.eql?(nil)
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

  describe "with fixture project" do
    before do
      @target = app_target
      @analyzer = subject.new(@target)
      @analyzer.logger = stub('Logger', :log)
      @analyzer.expects(:warn).never
      @analyzer.expects(:error).never
    end

    describe "#strings_file_refs" do
      it 'should return the strings files of the fixture project' do
        strings_files = @analyzer.strings_file_refs
        strings_files.count.should.be.eql?(3)
        strings_files[0].path.should.be.eql?('en.lproj/InfoPlist.strings')
        strings_files[1].path.should.be.eql?('en.lproj/Localizable.strings')
        strings_files[2].path.should.be.eql?('de.lproj/Localizable.strings')
      end
    end

    describe '#derive_used_languages' do
      it 'should find used languages' do
        languages = @analyzer.derive_used_languages(@analyzer.strings_file_refs)
        languages.should == ['en', 'de'].to_set
      end
    end

    describe '#used_languages' do
      it 'should return english and german as used languages' do
        @analyzer.used_languages.should == ['en', 'de'].to_set
      end
    end

    describe '#info_plist_paths' do
      it 'should return a set with the configured paths of the project' do
        @analyzer.info_plist_paths.should == [Pathname('Example/Example-Info.plist')].to_set
      end
    end

    describe '#absolute_info_plist_paths' do
      it 'should resolve the path if it is relative' do
        @analyzer.absolute_project_file_path('Info.plist')
          .relative_path_from(fixture_path)
          .should == Pathname('Example/Info.plist')
      end

      it 'should resolve the path if $SRCROOT is used' do
        @analyzer.absolute_project_file_path('$SRCROOT/Info.plist')
          .relative_path_from(fixture_path)
          .should == Pathname('Example/Info.plist')
      end
    end

    describe '#native_dev_languages' do
      it 'should return english' do
        @analyzer.native_dev_languages.should == ['en'].to_set
      end

      describe 'with non-configured Info.plist' do
        it 'should warn on missing plists' do
          @target.build_configurations[0].build_settings['INFOPLIST_FILE'] = 'NonExisting.plist'
          @analyzer.expects(:warn).once
          @analyzer.native_dev_languages.should == ['en'].to_set
        end
      end
    end

    describe '#read_plist_key' do
      before do
        @plist_path = fixture_path + 'Example/Example/Example-Info.plist'
      end

      it 'should read and return existing keys' do
        @analyzer.read_plist_key(@plist_path, :CFBundleDevelopmentRegion)
          .should == 'en'
      end

      it 'should raise an ArgumentError on non-existing files' do
        plist_path = Pathname('NonExisting.plist')
        proc do
          @analyzer.read_plist_key(plist_path, :XCResNonExistingKey)
        end.should.raise(ArgumentError).message
          .should == "File 'NonExisting.plist' doesn't exist"
      end

      it 'should raise an ArgumentError on non-existing keys' do
        proc do
          @analyzer.read_plist_key(@plist_path, :XCResNonExistingKey)
        end.should.raise(ArgumentError).message
          .should == 'Error reading plist: Print: Entry, ":XCResNonExistingKey", Does Not Exist'
      end
    end

    describe '#absolute_project_file_path' do
      it 'should treat relative paths correctly' do
        @analyzer.absolute_project_file_path('Info.plist')
          .relative_path_from(fixture_path)
          .should == Pathname('Example/Info.plist')
      end

      it 'should replace $SRCROOT with project path' do
        @analyzer.absolute_project_file_path('$SRCROOT/Info.plist')
          .relative_path_from(fixture_path)
          .should == Pathname('Example/Info.plist')
      end

      it 'should replace ${SRCROOT} with project path' do
        @analyzer.absolute_project_file_path('${SRCROOT}/Info.plist')
          .relative_path_from(fixture_path)
          .should == Pathname('Example/Info.plist')
      end

      it 'should replace $(SRCROOT) with project path' do
        @analyzer.absolute_project_file_path('$(SRCROOT)/Info.plist')
          .relative_path_from(fixture_path)
          .should == Pathname('Example/Info.plist')
      end
    end

    describe '#selected_strings_file_refs' do
      describe 'for english development language' do
        before do
          @analyzer.stubs(:languages).returns ['en']
        end

        it 'should return the selected strings file refs' do
          strings_files = @analyzer.selected_strings_file_refs
          strings_files.count.should.be.eql?(2)
          strings_files[0].path.should.be.eql?('en.lproj/InfoPlist.strings')
          strings_files[1].path.should.be.eql?('en.lproj/Localizable.strings')
        end
      end

      describe 'for german development language' do
        before do
          @analyzer.stubs(:languages).returns ['de']
        end

        it 'should return the selected strings file refs' do
          @analyzer.stubs(:languages).returns ['de']
          strings_files = @analyzer.selected_strings_file_refs
          strings_files.count.should.be.eql?(1)
          strings_files[0].path.should.be.eql?('de.lproj/Localizable.strings')
        end
      end
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
