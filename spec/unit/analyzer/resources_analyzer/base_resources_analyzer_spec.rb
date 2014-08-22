require File.expand_path('../../../spec_helper', __FILE__)

describe 'XCRes::ResourcesAnalyzer::BaseResourcesAnalyzer' do

  def subject
    XCRes::ResourcesAnalyzer::BaseResourcesAnalyzer
  end

  before do
    @analyzer = subject.new
    @analyzer.logger = stub('Logger', :log)
  end

  describe '#find_files_in_dir' do
    # TODO: Test using fakefs, ...
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
