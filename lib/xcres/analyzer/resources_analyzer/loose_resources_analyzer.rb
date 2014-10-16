require 'xcres/analyzer/resources_analyzer/base_resources_analyzer'

module XCRes
  module ResourcesAnalyzer

    # A +LooseResourcesAnalyzer+ scans the project for resources, which are
    # loosely placed in the project or in a group and should be included in the
    # output file.
    #
    class LooseResourcesAnalyzer < BaseResourcesAnalyzer

      def analyze
        @sections = [build_section_for_loose_images]
        super
      end

      def exclude_file_patterns
        super + ['Default.*', 'Default@2x.*', 'Default-568h@2x.*']
      end

      # Build a section for loose image resources in the project
      #
      # @return [Section]
      #
      def build_section_for_loose_images
        image_files = find_image_files(resources_files.map(&:path))

        log "Found #%s image files in project.", image_files.count

        data = build_images_section_data(image_files, use_basename: [:key, :path])

        new_section('Images', data)
      end

    end

  end
end
