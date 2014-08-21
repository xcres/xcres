require File.expand_path('../../spec_helper', __FILE__)

describe 'XCResources::Analyzer' do

  def subject
    XCResources::Analyzer
  end

  before do
    @project = xcodeproj
    @analyzer = subject.new(@project)
  end

  describe '#new_section' do
    describe 'without configured options' do
      describe 'without options given as argument' do
        it 'should return a new section' do
          @analyzer.new_section('Name', { a: 'a' })
            .should.be.eql? XCResources::Section.new('Name', { a: 'a' })
        end
      end

      describe 'with options given as argument' do
        it 'should return a new section' do
          @analyzer.new_section('Name', { a: 'a' }, the_answer: 42)
            .should.be.eql? XCResources::Section.new('Name', { a: 'a' }, the_answer: 42)
        end
      end
    end

    describe 'with configured options' do
      before do
        @analyzer.options = { the_answer: 42, the_question: '6x7=?' }
      end

      describe 'without options given as argument' do
        it 'should return a new section' do
          @analyzer.new_section('Name', { a: 'a' })
            .should.be.eql? XCResources::Section.new('Name', { a: 'a' }, the_answer: 42,  the_question: '6x7=?')
        end
      end

      describe 'with options given as argument' do
        it 'should return a new section' do
          @analyzer.new_section('Name', { a: 'a' }, the_answer: 21)
            .should.be.eql? XCResources::Section.new('Name', { a: 'a' }, the_answer: 21, the_question: '6x7=?')
        end
      end
    end
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
    it 'should return an empty list for an empty project' do
      @analyzer.project.stubs(:files).returns([])
      @analyzer.find_file_refs_by_extname('.bundle').should.be.eql?([])
    end

    it 'should return matching files' do
      @bundle = stub('FileRef', path: 'the-whole.bundle')
      @img    = stub('FileRef', path: 'awesome.jpg')
      @project.stubs(:files).returns([@bundle, @img])

      @analyzer.stubs(:is_file_ref_included_in_application_target?)
        .returns(true)
      @analyzer.find_file_refs_by_extname('.bundle').should.be.eql?([@bundle])
    end

    it 'should not return files, which do not belong to an application target' do
      @dog_img = stub('FileRef', path: 'doge.jpg')
      @cat_img = stub('FileRef', path: 'nyancat.jpg')
      @project.stubs(:files).returns([@dog_img, @cat_img])

      @analyzer.stubs(:is_file_ref_included_in_application_target?)
        .with(@dog_img).returns(true)
      @analyzer.stubs(:is_file_ref_included_in_application_target?)
        .with(@cat_img).returns(false)
      @analyzer.find_file_refs_by_extname('.jpg').should.be.eql?([@dog_img])
    end
  end

  describe '#application_targets' do
    it 'should return the expected application target' do
      @analyzer.application_targets.count.should.eql? 1
      target = @analyzer.application_targets.first
      target.should.be.an.instance_of?(Xcodeproj::Project::Object::PBXNativeTarget)
      target.name.should.eql?('Example')
    end
  end

  describe '#is_file_ref_included_in_application_target?' do
    it 'should return true for included files' do
      file = @project.files.find { |f| f.path.to_s == 'doge.jpeg' }
      file.should.be.an.instance_of?(Xcodeproj::Project::Object::PBXFileReference)
      @analyzer.is_file_ref_included_in_application_target?(file)
        .should.be.true?
    end

    it 'should return false for non-included files' do
      file = @project.files.find { |f| f.path.to_s == 'nyanCat.png' }
      file.should.be.an.instance_of?(Xcodeproj::Project::Object::PBXFileReference)
      @analyzer.is_file_ref_included_in_application_target?(file)
        .should.be.false?
    end
  end

end
