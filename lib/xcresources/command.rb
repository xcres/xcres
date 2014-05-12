require 'xcodeproj'
require 'clamp'
require 'xcresources/builder/resources_builder'

class XCResources::Command < Clamp::Command

  # TODO: Make this configurable
  ICON_FILTER_WORDS = ['icon', 'image']

  option ['--silent'], :flag, 'Show nothing'
  option ['--version'], :flag, 'Show the version'
  #option ['--no-ansi'], :flag, 'Show output without ANSI codes'
  option ['-v', '--verbose'], :flag, 'Show more debugging information'
  #option ['-d', '--dry-run'], :flag, 'Does nothing on the file system'

  option ['-i', '--img-src'], 'FILE_PATH', 'Images which should be included in the resources header', multivalued: true, attribute_name: :img_src_file_paths
  option ['-x', '--exclude'], 'FILE_PATH', 'File paths which should be excluded', multivalued: true, attribute_name: :exclude_file_paths
  option ['-n', '--name'], 'NAME', 'Name of the resources constant (default: `basename OUTPUT_PATH`)', attribute_name: :resources_constant_name
  option ['-l', '--language'], 'LANGUAGE', 'Default language to build the keys', attribute_name: :language, default: 'en' do |language|
    raise ArgumentError.new 'Expected a two-letter code conforming ISO 639-1 as LANGUAGE' unless String(language).length == 2
    language
  end

  parameter '[OUTPUT_PATH]', 'Path where to write to', attribute_name: :output_path
  parameter '[XCODEPROJ]', 'Xcode project file to inspect (automatically located on base of the current directory if not given)', attribute_name: :xcodeproj_file_path

  attr_accessor :xcodeproj

  def execute
    if version?
      inform XCResources::VERSION
      return
    end

    log 'Verbose mode is enabled.'

    # Fall back to `basename OUTPUT_PATH` or 'R' if both are not given
    self.resources_constant_name ||= output_path != nil ? File.basename_without_ext(output_path) : 'R'

    if output_path.nil?
      # Use current dir, if no output path was set
      self.output_path ||= File.realpath('.') + '/' + resources_constant_name
    else
      self.output_path ||= File.absolute_path output_path
    end

    builder = XCResources::ResourcesBuilder.new
    builder.output_path = output_path
    builder.resources_constant_name = resources_constant_name


    # Try to discover Xcode project at given path.
    if xcodeproj_file_path.nil?
      warn 'Argument XCODEPROJ is not set. Use the current directory.'
      self.xcodeproj_file_path = discover_xcodeproj_file_path!
    elsif Dir.exist?(xcodeproj_file_path) && !File.fnmatch('*.xcodeproj', xcodeproj_file_path)
      warn 'Argument XCODEPROJ is a directory. Try to locate the Xcode project in this directory.'
      self.xcodeproj_file_path = discover_xcodeproj_file_path! xcodeproj_file_path
    end

    unless Dir.exist?(xcodeproj_file_path) && File.exist?(xcodeproj_file_path + '/project.pbxproj')
      raise ArgumentError.new 'XCODEPROJ at %s was not found or is not a valid Xcode project.' % xcodeproj_file_path
    end

    success 'Use %s as XCODEPROJ.' % xcodeproj_file_path

    self.xcodeproj = Xcodeproj::Project.open xcodeproj_file_path


    # Build Icons section
    builder.add_section 'Icons', build_icons_section

    # Build Strings section
    builder.add_section 'Strings', build_strings_section

    # Write the files, if needed
    builder.build

    success 'Successfully updated: %s', output_path + '.h'
  rescue ArgumentError => error
    fail error.message
  end

  def inform message, *format_args
    puts message % format_args unless silent?
  end

  def log message, *format_args
    inform ('Ⓥ' + ' ' + message).magenta, *format_args if verbose?
  end

  def success message, *format_args
    inform ('✓' + ' ' + message).green, *format_args
  end

  def warn message, *format_args
    inform ('⚠' + ' ' + message).yellow, *format_args
  end

  def fail message, *format_args
    inform ('✗' + ' ' + message).red, *format_args
  end

  def discover_xcodeproj_file_path! dir = '.'
    xcodeproj_file_paths = Dir[dir + '/*.xcodeproj']
    if xcodeproj_file_paths.count == 0
      raise ArgumentError.new 'Argument XCODEPROJ was not given and no *.xcodeproj file was found in current directory.'
    end
    xcodeproj_file_paths.first
  end
  end

  def build_icons_section
    # Build dictionary of image keys to names
    image_file_paths = find_images

    # Filter out retina images
    image_file_paths.select! { |path| !/@2x\.\w+$/.match path }

    # Map paths to prepared keys
    build_icons_section_map image_file_paths
  end

  def find_images
    # TODO: Grasp all the icons!
    # TODO: Remove test entries and write some proper tests!
    ["test.png", "test@2x.png", "camelCaseTest.png", "snake_case_test.png", "123.png"]
  end

  def build_icons_section_map image_file_paths
    # Prepare icon filter words
    icon_filter_words = ICON_FILTER_WORDS.map &:downcase

    # Transform image file paths to keys
    image_keys_to_paths = {}
    for file_path in image_file_paths
      # Get rid of the file extension
      key = File.basename_without_ext file_path

      # Graphical assets tend to contain words, which you want to strip.
      # Because we want to list the words to ignore only in one variant, we have to ensure that the icon name is
      # prepared for that, without loosing word separation if camel case was used.
      key = key.underscore.downcase

      for filter_word in icon_filter_words do
        key.gsub! filter_word, ''
      end

      image_keys_to_paths[key] = file_path
    end

    image_keys_to_paths
  end

  def build_strings_section
    # TODO: Discover all .strings files (e.g. Localizable.strings)
    # TODO: Apply ignore list
    # TODO: Use specified default lanuage as primary language if there are multiple
    # TODO: Try to use the only one language, which was used
    strings_file_paths = []

    keys = []
    for strings_file_path in strings_file_paths
      begin
        # TODO: Load strings file contents
        # TODO: Merge keys into array
      rescue error
        raise "Error while reading %s: %s", strings_file_path, error
      end
    end

    Hash[keys.map { |k| [k,k] }]
  end
end
