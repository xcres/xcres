require File.expand_path('../../spec_helper', __FILE__)

describe 'XCResources::ResourcesAnalyzer' do

  def subject
    XCResources::ResourcesAnalyzer
  end

  before do
    @analyzer = subject.new
    @analyzer.logger = stub('Logger', :log)
  end

  describe '#analyze' do
    it 'should return all sections' do
      bundle_section_a = stub('Section')
      bundle_section_b = stub('Section')
      loose_image_section = stub('Images')
      @analyzer.expects(:build_sections_for_bundles).returns([bundle_section_a, bundle_section_b])
      @analyzer.expects(:build_section_for_loose_images).returns(loose_image_section)
      @analyzer.analyze.should.eql?([bundle_section_a, bundle_section_b, loose_image_section])
    end

    it 'should return only bundle sections if there are no loose images' do
      bundle_sections = [stub('Section')]
      @analyzer.expects(:build_sections_for_bundles).returns(bundle_sections)
      @analyzer.expects(:build_section_for_loose_images).returns(nil)
      @analyzer.analyze.should.eql?(bundle_sections)
    end
  end

  describe '#build_sections_for_bundles' do
    it 'should return an empty array if the project does not contain any resource bundles' do
      @analyzer.expects(:find_bundle_file_refs).returns([])
      @analyzer.build_sections_for_bundles.should.eql?([])
    end

    it 'should build sections for given bundles' do
      mock_bundle_a = mock('BundleFileRef').stubs(path: 'A.bundle', real_path: 'b/A.bundle')
      mock_bundle_b = mock('BundleFileRef').stubs(path: 'B.bundle', real_path: 'b/B.bundle')
      section = XCResources::Section.new('A', { 'a' => 'a.gif' })
      @analyzer.expects(:find_bundle_file_refs).returns([mock_bundle_a, mock_bundle_b])
      @analyzer.expects(:build_section_for_bundle).with(mock_bundle_a).returns(section)
      @analyzer.expects(:build_section_for_bundle).with(mock_bundle_b).returns(nil)
      @analyzer.build_sections_for_bundles.should.be.eql?([section])
    end
  end

  describe '#find_bundle_file_refs' do
    # TODO: Prepare a fixture project
  end

  describe '#build_section_for_bundle' do
    before do
      @mock_bundle = mock('Bundle') { stubs(path: 'A.bundle', real_path: 'b/A.bundle') }
    end

    it 'should return nil if the bundle does not contain any images' do
      @analyzer.expects(:find_files_in_dir).with(@mock_bundle.real_path).returns([Pathname('a.m')])
      @analyzer.build_section_for_bundle(@mock_bundle).should.be.nil?
    end

    it 'should return nil if the bundle does not contain any valid images' do
      @analyzer.expects(:find_files_in_dir).with(@mock_bundle.real_path).returns([Pathname('a.gif')])
      @analyzer.exclude_file_patterns = ['a.gif']
      @analyzer.build_section_for_bundle(@mock_bundle).should.be.nil?
    end

    it 'should build a new section if the bundle contain valid images' do
      @analyzer.expects(:find_files_in_dir).with(@mock_bundle.real_path).returns([Pathname('a.gif')])
      @analyzer.build_section_for_bundle(@mock_bundle).should.be.eql?(XCResources::Section.new('A', 'a' => 'a.gif'))
    end
  end

  describe '#find_files_in_dir' do
    # TODO: Test using fakefs, ...
  end

  describe '#build_section_for_loose_images' do
    describe 'if no loose image files were found' do
      before do
        file_ref_imp = mock('FileRef') { stubs(path: Pathname('b/a.m')) }
        project = mock('Project') { stubs(files: [file_ref_imp]) }
        @analyzer.stubs(project: project)
      end

      it 'should return nil' do
        @analyzer.build_section_for_loose_images.should.be.nil?
      end
    end

    describe 'if loose image files were present' do
      before do
        file_ref_imp = mock('FileRef') { stubs(path: Pathname('b/a.m')) }
        file_ref_gif = mock('FileRef') { stubs(path: Pathname('b/a.gif')) }
        project = mock('Project') { stubs(files: [file_ref_imp, file_ref_gif]) }
        @analyzer.stubs(project: project)
      end

      it 'should return a new section' do
        section = XCResources::Section.new('Images', 'a' => 'a.gif')
        @analyzer.expects(:build_images_section_data).with([Pathname('b/a.gif')], use_basename?: true)
          .returns({ 'a' => 'a.gif' })
        @analyzer.build_section_for_loose_images.should.be.eql?(section)
      end
    end
  end

  describe '#build_images_section_data' do
    it 'returns an empty hash if no files were given' do
      @analyzer.build_images_section_data([]).should.eql?({})
    end

    describe 'option use_basename? is not given' do
      it 'builds an items hash and keep the path' do
        @analyzer.build_images_section_data([Pathname('b/a.m'), Pathname('b/a.gif')])
          .should.eql?({ 'b/a' => 'b/a.gif' })
      end
    end

    describe 'option use_basename? is given as true' do
      it 'builds an items hash and remove the path' do
        @analyzer.build_images_section_data([Pathname('b/a.m'), Pathname('b/a.gif')], use_basename?: true)
          .should.eql?({ 'a' => 'a.gif' })
      end
    end
  end

  describe '#filter_device_specific_image_paths' do
    it 'returns an empty list if no files were given' do
      @analyzer.filter_device_specific_image_paths([]).should.eql?([])
    end

    it 'filters device scale specific images without doublets' do
      @analyzer.filter_device_specific_image_paths(['a.png', 'a@2x.png']).should.eql?(['a.png'])
    end

    it 'filters device scale specifiers from image paths' do
      @analyzer.filter_device_specific_image_paths(['a@2x.png']).should.eql?(['a.png'])
    end

    it 'filters idiom specific images without doublets' do
      @analyzer.filter_device_specific_image_paths(['a.png', 'a~iphone.png', 'a~ipad.png']).should.eql?(['a.png'])
    end

    it 'filters idiom specifiers from image paths' do
      @analyzer.filter_device_specific_image_paths(['a~iphone.png']).should.eql?(['a.png'])
      @analyzer.filter_device_specific_image_paths(['a~ipad.png']).should.eql?(['a.png'])
    end
  end

  describe '#find_image_files' do
    it 'returns a empty list if no files were given' do
      @analyzer.find_image_files([]).should.eql?([])
    end

    it 'matches common image formats' do
      @analyzer.find_image_files(['a.png', 'b.jpg', 'c.jpeg', 'd.gif', 'e.txt'])
                     .should.eql?(['a.png', 'b.jpg', 'c.jpeg', 'd.gif'])
    end
  end

  describe '#build_section_data' do
    before do
      @file_paths = [Pathname('a/b')]
    end

    it 'returns an empty hash if no file paths given' do
      @analyzer.build_section_data([]).should.be.eql?({})
    end

    it 'returns a hash with the basename if option use_basename? is enabled' do
      @analyzer.expects(:key_from_path).with('b').returns('b')
      @analyzer.build_section_data(@file_paths, use_basename?: true)
        .should.be.eql?({ 'b' => 'b' })
    end

    it 'returns a hash with relative paths if option use_basename? is disabled' do
      @analyzer.expects(:key_from_path).with('a/b').returns('a/b')
      @analyzer.build_section_data(@file_paths, use_basename?: false)
        .should.be.eql?({ 'a/b' => 'a/b' })
    end

    it 'returns a hash with relative paths if option use_basename? is not given' do
      @analyzer.expects(:key_from_path).with('a/b').returns('a/b')
      @analyzer.build_section_data(@file_paths)
        .should.be.eql?({ 'a/b' => 'a/b' })
    end
  end

  describe '#key_from_path' do
    it 'should keep the path' do
      @analyzer.key_from_path('b/a').should.be.eql?('b/a')
    end

    it 'should cut the file extension' do
      @analyzer.key_from_path('a.gif').should.be.eql?('a')
    end

    it 'should cut only the last file extension' do
      @analyzer.key_from_path('a.gif.gif').should.be.eql?('a.gif')
    end

    it 'should transform camel case to snake case' do
      @analyzer.key_from_path('AbCdEf').should.be.eql?('ab_cd_ef')
    end

    it 'should filter certain words' do
      @analyzer.key_from_path('my_icon_catImage').should.be.eql?('my_cat')
    end

    it 'should not contain unnecessary underscores' do
      @analyzer.key_from_path('__a___b__c___').should.be.eql?('a_b_c')
    end
  end

end
