require 'xcres/analyzer/resources_analyzer/base_resources_analyzer'
require 'xcres/model/xcassets/bundle'

module XCRes
  module ResourcesAnalyzer

    # A +XCAssetsAnalyzer+ scans the project for asset catalogs,
    # which should be included in the output file.
    #
    class XCAssetsAnalyzer < BaseResourcesAnalyzer

      def analyze
        @sections = build_sections_for_xcassets
        super
      end

      # Build a section for each asset catalog if it contains any resources
      #
      # @return [Array<Section>]
      #         the built sections
      #
      def build_sections_for_xcassets
        file_refs = find_file_refs_by_extname '.xcassets'
        file_refs = filter_ref_exclusions(file_refs)

        log "Found #%s asset catalogs in project.", file_refs.count

        file_refs.map do |file_ref|
          bundle = XCAssets::Bundle.open(file_ref.real_path)
          section = build_section_for_xcassets(bundle)
          log 'Add section for %s with %s elements', section.name, section.items.count unless section.nil?
          section
        end.compact
      end

      # Build a section for a asset catalog
      #
      # @param  [XCAssets::Bundle] xcassets_bundle
      #         the file reference to the resources bundle file
      #
      # @return [Section]
      #         a section or nil
      #
      def build_section_for_xcassets bundle
        log "Found asset catalog %s with #%s image files.",
          bundle.path.basename, bundle.resources.count

        section_name = "#{basename_without_ext(bundle.path)}Assets"
        section_data = build_images_section_data(bundle.resources.map(&:path), {
          use_basename:     [:path],
          path_without_ext: true
        })
        new_section(section_name, section_data)
      end

    end

  end
end
