require 'xcresources/analyzer/analyzer'
require 'set'

module XCResources

  # A +ResourcesAnalyzer+ scans the project for resources,
  # which should be included in the output file.
  #
  class ResourcesAnalyzer < Analyzer

    FILTER_WORDS = ['icon', 'image']

    def analyze
      sections = []
      sections += build_sections_for_bundles
      sections << build_section_for_loose_images
      @sections = sections.compact
    end

    # Build a section for each bundle if it contains any resources
    #
    # @return [Array<Section>]
    #         the built sections
    #
    def build_sections_for_bundles
      bundle_file_refs = find_bundle_file_refs

      log "Found #%s resource bundles in project.", bundle_file_refs.count

      bundle_file_refs.map do |file_ref|
        section = build_section_for_bundle(file_ref)
        log 'Add section for %s with %s elements', section.name, section.items.count unless section.nil?
        section
      end.compact
    end

    # Discover all references to resources bundles in project
    #
    # @return [Array<PBXFileReference>]
    #
    def find_bundle_file_refs
      project.files.select { |file| File.extname(file.path) == '.bundle' }
    end

    # Build a section for a resources bundle
    #
    # @param  [PBXFileReference] bundle_file_ref
    #         the file reference to the resources bundle file
    #
    # @return [Section?]
    #         a section or nil
    #
    def build_section_for_bundle bundle_file_ref
      bundle_files = find_files_in_dir(bundle_file_ref.real_path)
      image_files = find_image_files(bundle_files)

      log "Found bundle %s with #%s image files of #%s total files.", bundle_file_ref.path, image_files.count, bundle_files.count

      return nil if image_files.empty?

      section_data = build_images_section_data(image_files)

      return nil if section_data.empty?

      section_name = basename_without_ext(bundle_file_ref.path)

      Section.new section_name, section_data
    end

    # Get a list of all files in a directory
    #
    # @param  [Pathname] dir
    #         the directory
    #
    # @return [Array<Pathname>]
    #         the file paths relative to the given dir
    #
    def find_files_in_dir dir
      Dir.chdir dir do
        Dir['**/*'].map { |path| Pathname(path) }
      end
    end

    # Build a section for loose image resources in the project
    #
    # @return [Section?]
    #
    def build_section_for_loose_images
      image_files = find_image_files(project.files.map(&:path))

      log "Found #%s image files in project.", image_files.count

      return nil if image_files.empty?

      data = build_images_section_data(image_files, use_basename?: true)

      Section.new('Images', data)
    end

    # Build a section for image resources
    #
    # @param  [Array<String>] image_files
    #
    # @param  [Hash] options
    #         see #build_section_data
    #
    # @return [Hash{String => Pathname}]
    #
    def build_images_section_data image_file_paths, options={}
      image_file_paths = filter_exclusions(image_file_paths)
      image_file_paths = filter_device_specific_image_paths(image_file_paths)
      build_section_data(image_file_paths, options)
    end

    # Filter out device scale and idiom specific images (retina, ipad),
    # but ensure the base exist once
    #
    # @param  [Array<Pathname>] file_paths
    #         the file paths to filter
    #
    # @return [Array<String>]
    #         the filtered file paths
    #
    def filter_device_specific_image_paths file_paths
      file_paths.map do |path|
        path.to_s.gsub /(@2x)?(~(iphone|ipad))?(?=\.\w+$)/, ''
      end.to_set.to_a
    end

    # Find image files in a given list of file paths
    #
    # @param  [Array<Pathname>] file_paths
    #         the list of files
    #
    # @return [Array<Pathname>]
    #         the filtered list
    #
    def find_image_files file_paths
      file_paths.select { |path| path.to_s.match /\.(png|jpe?g|gif)$/ }
    end

    # Build a keys to paths mapping
    #
    # @param  [Array<Pathname>] file_paths
    #         the file paths, which will be the values of the mapping
    #
    # @param  [Hash] options
    #         valid options are:
    #         * :use_basename? => see #key_from_path
    #
    # @return [Hash{String => Pathname}]
    #
    def build_section_data file_paths, options={}
      options = { use_basename?: false }.merge options

      # Transform image file paths to keys
      keys_to_paths = {}
      for file_path in file_paths
        key = key_from_path(file_path, options[:use_basename?])
        keys_to_paths[key] = file_path
      end

      keys_to_paths
    end

    # Derive a key from a resource path
    #
    # @param  [String] path
    #         the path to the resource
    #
    # @param  [Bool] use_basename
    #         if set, it will only use the basename of the path for the key
    #
    # @return [String]
    #
    def key_from_path path, use_basename=false
      # Use the basename only if the option is enabled
      key = use_basename ? File.basename(path) : path.to_s

      # Get rid of the file extension
      key = key.sub /#{File.extname(path)}$/, ''

      # Graphical assets tend to contain words, which you want to strip.
      # Because we want to list the words to ignore only in one variant,
      # we have to ensure that the icon name is prepared for that, without
      # loosing word separation if camel case was used.
      key = key.underscore.downcase

      for filter_word in FILTER_WORDS do
        key.gsub! filter_word, ''
      end

      return key
    end

  end
end
