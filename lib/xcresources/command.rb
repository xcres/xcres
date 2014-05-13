require 'xcodeproj'
require 'clamp'
require 'xcresources/builder/resources_builder'
require 'apfel'

class XCResources::Command < Clamp::Command

  # Monkey-patch PBXFileReference by a helper to get
  class Xcodeproj::Project::Object::PBXFileReference
    def absolute_path
      parents.map(&:path).reverse.reduce { |p1,p2| File.join p1||'', p2||'' } + path
    end
  end

  # TODO: Make this configurable
  ICON_FILTER_WORDS = ['icon', 'image']

  option ['--silent'], :flag, 'Show nothing'
  option ['--version'], :flag, 'Show the version'
  #option ['--no-ansi'], :flag, 'Show output without ANSI codes'
  option ['-v', '--verbose'], :flag, 'Show more debugging information'
  #option ['-d', '--dry-run'], :flag, 'Does nothing on the file system'

  option ['-i', '--img-src'], 'FILE_PATH', 'Images which should be included in the resources header', multivalued: true, attribute_name: :img_src_file_paths
  option ['-x', '--exclude'], 'FILE_PATTERN', 'File pattern which should be excluded (default: ["InfoPlist.strings"])', multivalued: true, attribute_name: :exclude_file_patterns, default: ['InfoPlist.strings']
  option ['-n', '--name'], 'NAME', 'Name of the resources constant (default: `basename OUTPUT_PATH`)', attribute_name: :resources_constant_name
  option ['-l', '--language'], 'LANGUAGE', 'Default language to build the keys', attribute_name: :default_language do |language|
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


    # Prepare builder
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

  def filter_exclusions file_paths
    file_paths.select do |path|
      exclude_file_patterns.map { |pattern| !File.fnmatch '**/' + pattern, path }.reduce true, :&
    end
  end

  def build_icons_section
    # Build dictionary of image keys to names
    image_file_paths = filter_exclusions find_images

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

  def find_strings_files
    # Discover all .strings files (e.g. Localizable.strings)
    xcodeproj.files.select { |file| File.fnmatch '*.strings', file.path }
  end

  def find_preferred_languages strings_files
    if default_language != nil
      # Use specified default language as primary language
      [language]
    else
      # Discover Info.plist files by build settings of all application targets
      application_targets = xcodeproj.targets.select { |t| t.product_type == 'com.apple.product-type.application' }
      info_plist_paths = application_targets.map do |target|
        target.build_configurations.map do |config|
          config.build_settings['INFOPLIST_FILE']
        end
      end.reduce([], :+).to_set

      log 'Info.plist paths: %s', info_plist_paths.to_a

      # Try to use the "Localization native development region" from Info.plist
      native_dev_languages = info_plist_paths.map do |path|
        `/usr/libexec/PlistBuddy -c "Print :CFBundleDevelopmentRegion" #{absolute_project_file_path(path)}`.gsub /\n$/, ''
      end

      log 'Native development languages: %s', native_dev_languages

      # Try to use the languages, which are used
      used_languages = strings_files.map(&:name).to_set

      log 'Used languages for .strings files: %s', used_languages.to_a

      # Calculate union of native development and used languages, fallback to the latter only, if it is empty
      languages = native_dev_languages.to_a & used_languages.to_a
      if languages.empty?
        used_languages
      else
        languages
      end
    end
  end

  # Project file paths are relative to their project.
  # We need either absolute paths or relative paths to our current location.
  def absolute_project_file_path file_path
    File.absolute_path xcodeproj_file_path + '/../' + file_path
  end

  def build_strings_section
    strings_files = find_strings_files

    log 'Strings files in project: %s', (strings_files.map &:path)

    # Find preferred languages
    languages = find_preferred_languages strings_files

    log 'Preferred languages: %s', languages

    # Select strings files by language
    strings_files.select! { |file| languages.include? file.name }

    log 'Strings files after language selection: %s', (strings_files.map &:path)

    # Apply ignore list
    strings_file_paths = filter_exclusions strings_files.map &:absolute_path

    log 'Non-ignored .strings files: %s', strings_file_paths

    keys_by_file = {}
    for strings_file_path in strings_file_paths
      begin
        # Load strings file contents
        strings_file = Apfel.parse absolute_project_file_path(strings_file_path)

        keys = Hash[strings_file.kv_pairs.map do |kv_pair|
          # WORKAROUND: Needed for single-line comments
          comment = kv_pair.comment.gsub /^\s*\/\/\s*/, ''

          [kv_pair.key, { value: kv_pair.key, comment: comment }]
        end]

        log 'Found %s keys in file %s', keys.count, strings_file_path

        keys_by_file[strings_file_path] = keys
      rescue ArgumentError => error
        raise 'Error while reading %s: %s', strings_file_path, error
      end
    end

    keys_by_file.map { |k,v| v }.reduce Hash.new, :merge
  end
end
