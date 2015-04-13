require 'xcres/analyzer/analyzer'
require 'json'

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

      if items.count > 0
        new_section('Strings', items)
      else
        nil
      end
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
      info_plist_paths.map do |path|
        absolute_project_file_path(path)
      end.select do |path|
        if path.to_s.include?('$')
          warn "Couldn't resolve all placeholders in INFOPLIST_FILE %s.", path.to_s
          false
        else
          true
        end
      end
    end

    # Find the native development languages by trying to use the
    # "Localization native development region" from Info.plist
    #
    # @return [Set<String>]
    #
    def native_dev_languages
      @native_dev_languages ||= absolute_info_plist_paths.map do |path|
        begin
          read_plist_key(path, :CFBundleDevelopmentRegion)
        rescue ArgumentError => e
          warn e
        end
      end.compact.to_set
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
      raise ArgumentError, "File '#{path}' doesn't exist" unless path.exist?
      raise ArgumentError, 'Path is required, but nil' if path.nil?
      raise ArgumentError, 'Key is required, but nil' if key.nil?
      out = `/usr/libexec/PlistBuddy -c "Print :#{key}" "#{path}" 2>&1`.chomp
      raise ArgumentError, "Error reading plist: #{out}" unless $?.success?
      out
    end

    # Read a .strings file given as a path
    #
    # @param [Pathname] path
    #        the path of the strings file
    #
    # @return [Hash]
    #
    def read_strings_file(path)
      raise ArgumentError, "File '#{path}' doesn't exist" unless path.exist?
      raise ArgumentError, "File '#{path}' is not a file" unless path.file?
      error = `plutil -lint -s "#{path}" 2>&1`
      raise ArgumentError, "File %s is malformed:\n#{error}" % path.to_s unless $?.success?
      json_or_error = `plutil -convert json "#{path}" -o -`.chomp
      raise ArgumentError, "File %s couldn't be converted to JSON.\n#{json_or_error}" % path.to_s unless $?.success?
      JSON.parse(json_or_error.force_encoding('UTF-8'))
    rescue EncodingError => e
      raise StandardError, "Encoding error in #{path}: #{e}"
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
      source_root = (project.path + '..').realpath
      if file_path.to_s.include?('$')
        Pathname(file_path.to_s.gsub(/\$[({]?SRCROOT[)}]?/, source_root.to_s))
      else
        source_root + file_path
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
        strings = read_strings_file(path)

        # Reject generated identifiers used by Interface Builder
        strings.reject! { |key, _| /^[a-zA-Z0-9]{3}(-[a-zA-Z0-9]{3}){2}/.match(key) }

        keys = Hash[strings.map do |key, value|
          [key, { value: key, comment: value.gsub(/[\r\n]/, ' ') }]
        end]

        log 'Found %s keys in file %s', keys.count, path

        keys
      rescue ArgumentError => error
        raise ArgumentError, 'Error while reading %s: %s' % [path, error]
      end
    end

  end
end
