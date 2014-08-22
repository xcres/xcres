require 'xcres/analyzer/analyzer'
require 'apfel'
require 'xcres/helper/apfel+parse_utf16'

module XCRes

  # A +StringsAnalyzer+ scans the project for resources,
  # which should be included in the output file.
  #
  class StringsAnalyzer < Analyzer

    # @return [String]
    #         optional two-letter language code conforming ISO 639-1
    attr_accessor :default_language

    # Initialize a new analyzer
    #
    # @param [Xcodeproj::Project] project
    #        see #project.
    #
    # @param [Hash] options
    #        Possible options:
    #        * :default_language => see #default_language.
    #
    def initialize(project=nil, options={})
      super
      self.default_language = options[:default_language]
    end

    def analyze
      log 'Strings files in project: %s', strings_file_refs.map(&:path)
      log 'Native development languages: %s', native_dev_languages.to_a
      log 'Used languages for .strings files: %s', used_languages.to_a
      log 'Preferred languages: %s', languages.to_a
      log 'Strings files after language selection: %s', selected_strings_file_refs.map(&:path)

      @sections = [build_section]
    end

    # Build the section
    #
    # @return [Section]
    #
    def build_section
      selected_file_refs = selected_strings_file_refs

      # Apply ignore list
      file_paths = filter_exclusions(selected_file_refs.map(&:path))
      filtered_file_refs = selected_file_refs.select { |file_ref| file_paths.include? file_ref.path }
      rel_file_paths = filtered_file_refs.map { |p| p.real_path.relative_path_from(Pathname.pwd) }

      log 'Non-ignored .strings files: %s', rel_file_paths.map(&:to_s)

      keys_by_file = {}
      for path in rel_file_paths
        keys_by_file[path] = keys_by_file(path)
      end
      items = keys_by_file.values.reduce({}, :merge)

      new_section('Strings', items)
    end

    # Discover all references to .strings files in project (e.g. Localizable.strings)
    #
    # @return [Array<PBXFileReference>]
    #
    def strings_file_refs
      @strings_file_refs ||= find_file_refs_by_extname '.strings'
    end

    # Select strings files by language
    #
    # @return [Array<PBXFileReference>]
    #
    def selected_strings_file_refs
      @selected_strings_file_refs ||= strings_file_refs.select { |file_ref| languages.include? file_ref.name }
    end

    # Derive the used languages from given strings files
    #
    # @param [Array<PBXFileReference>] strings_file_refs
    #
    # @return [Set<String>]
    #
    def derive_used_languages(strings_file_refs)
      strings_file_refs.map(&:name).to_set
    end

    # All used languages in the project
    #
    # @return [Set<String>]
    #
    def used_languages
      @used_languages ||= derive_used_languages(strings_file_refs)
    end

    # Find preferred languages, which is:
    #   - either only the default_language, if specified
    #   - or the intersection of native development and used languages
    #   - or all used languages
    #
    # @return [Set<String>]
    #
    def languages
      if default_language != nil
        # Use specified default language as primary language
        [default_language]
      else
        # Calculate the intersection of native development and used languages,
        # fallback to the latter only, if it is empty
        languages = native_dev_languages & used_languages
        if languages.empty?
          used_languages
        else
          languages
        end
      end
    end

    # Discover Info.plist files by build settings of the application target
    #
    # @return [Set<Pathname>]
    #         the relative paths to the .plist-files
    #
    def info_plist_paths
      @info_plist_paths ||= target.build_configurations.map do |config|
        config.build_settings['INFOPLIST_FILE']
      end.compact.map { |file| Pathname(file) }.flatten.to_set
    end

    # Absolute file paths to Info.plist files by build settings.
    # See #info_plist_paths.
    #
    # @return [Set<Pathname>]
    #         the absolute paths to the .plist-files
    #
    def absolute_info_plist_paths
      info_plist_paths.map { |path| absolute_project_file_path(path) }
    end

    # Find the native development languages by trying to use the
    # "Localization native development region" from Info.plist
    #
    # @return [Set<String>]
    #
    def native_dev_languages
      @native_dev_languages ||= absolute_info_plist_paths.map do |path|
        read_plist_key(path, :CFBundleDevelopmentRegion)
      end.to_set
    end

    # Extracts a given key from a plist file given as a path
    #
    # @param  [Pathname] path
    #         the path of the plist file
    #
    # @param  [String] key
    #         the key, whose value should been extracted
    #
    # @return [String]
    #
    def read_plist_key(path, key)
      `/usr/libexec/PlistBuddy -c "Print :#{key}" #{path}`.chomp
    end

    # Calculate the absolute path for a file path given relative to the
    # project / its `$SRCROOT`.
    #
    # We need either absolute paths or relative paths to our current location.
    # Xcodeproj provides this for +PBXFileReference+, but this doesn't work
    # for file references in build settings.
    #
    # @param  [String|Pathname] file_path
    #         the path relative to the project.
    #
    # @return [Pathname]
    #
    def absolute_project_file_path(file_path)
      (project.path + "../#{file_path}").realpath
    end

    # Get relative file paths
    #
    # @return [Array<Pathname>]
    #
    def strings_file_paths
      project_dir = project.path + '..'
      project_dir_realpath = project_dir.realpath
      strings_file_refs.map(&:real_path).map do |path|
        project_dir + path.relative_path_from(project_dir_realpath) rescue path
      end
    end

    # Read a file and collect all its keys
    #
    # @param  [Pathname] path
    #         the path to the .strings file to read
    #
    # @return [Hash{String => Hash}]
    #
    def keys_by_file(path)
      begin
        # Load strings file contents
        strings_file = Apfel.parse(path) rescue Apfel.parse_utf16(path)

        keys = Hash[strings_file.kv_pairs.map do |kv_pair|
          # WORKAROUND: Needed for single-line comments
          comment = kv_pair.comment.gsub /^\s*\/\/\s*/, ''

          [kv_pair.key, { value: kv_pair.key, comment: comment }]
        end]

        log 'Found %s keys in file %s', keys.count, path

        keys
      rescue ArgumentError => error
        raise ArgumentError, 'Error while reading %s: %s' % [path, error]
      end
    end

  end
end
