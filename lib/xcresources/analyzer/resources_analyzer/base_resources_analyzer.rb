require 'xcresources/analyzer/analyzer'
require 'set'

module XCResources
  module ResourcesAnalyzer

    # A +BaseResourcesAnalyzer+ scans the project for resources,
    # which should be included in the output file.
    #
    class BaseResourcesAnalyzer < Analyzer

      FILTER_WORDS = ['icon', 'image']

      # Get a list of all files in a directory
      #
      # @param  [Pathname] dir
      #         the directory
      #
      # @return [Array<Pathname>]
      #         the file paths relative to the given dir
      #
      def find_files_in_dir dir
        unless dir.exist?
          warn "Can't find files in dir %s as it doesn't exist!",
            dir.relative_path_from(project.path + '..').to_s
          return []
        end
        Dir.chdir dir do
          Dir['**/*'].map { |path| Pathname(path) }
        end
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
      #         * [Bool] :use_basename?
      #           if set, it will only use the basename of the path for the key
      #
      # @return [Hash{String => Pathname}]
      #
      def build_section_data file_paths, options={}
        options = { use_basename?: false }.merge options

        # Transform image file paths to keys
        keys_to_paths = {}
        for path in file_paths
          path = options[:use_basename?] ? File.basename(path) : path.to_s
          key = key_from_path(path)
          keys_to_paths[key] = path
        end

        keys_to_paths
      end

      # Derive a key from a resource path
      #
      # @param  [String] path
      #         the path to the resource
      #
      # @return [String]
      #
      def key_from_path path
        key = path.to_s

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

        # Remove unnecessary underscores
        key = key.gsub(/^_*|_*$|(_)_+/, '\1')

        return key
      end

    end

  end
end
