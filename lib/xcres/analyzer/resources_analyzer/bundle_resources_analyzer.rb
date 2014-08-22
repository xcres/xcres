require 'xcres/analyzer/resources_analyzer/base_resources_analyzer'

module XCRes
  module ResourcesAnalyzer

    # A +BundleResourcesAnalyzer+ scans the project for bundles, whose resources
    # should be included in the output file.
    #
    class BundleResourcesAnalyzer < BaseResourcesAnalyzer

      def analyze
        @sections = build_sections_for_bundles.compact
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
        find_file_refs_by_extname '.bundle'
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

        new_section(section_name, section_data)
      end

    end

  end
end
