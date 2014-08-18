require 'xcresources/analyzer/resources_analyzer/base_resources_analyzer'
require 'xcresources/model/xcassets/bundle'

module XCResources
  module ResourcesAnalyzer

    # A +XCAssetsAnalyzer+ scans the project for .xcassets bundles,
    # which should be included in the output file.
    #
    class XCAssetsAnalyzer < BaseResourcesAnalyzer

      def analyze
        sections = []
        sections += build_sections_for_xcassets
        @sections = sections.compact
      end

      # Build a section for each xcassets bundle if it contains any resources
      #
      # @return [Array<Section>]
      #         the built sections
      #
      def build_sections_for_xcassets
        file_refs = find_file_refs_by_extname '.xcassets'

        log "Found #%s xcassets bundles in project.", file_refs.count

        file_refs.map do |file_ref|
          bundle = XCAssets::Bundle.open(file_ref.real_path)
          section = build_section_for_xcassets(bundle)
          log 'Add section for %s with %s elements', section.name, section.items.count unless section.nil?
          section
        end.compact
      end

      # Build a section for a xcassets bundle
      #
      # @param  [XCAssets::Bundle] xcassets_bundle
      #         the file reference to the resources bundle file
      #
      # @return [Section?]
      #         a section or nil
      #
      def build_section_for_xcassets bundle
        log "Found xcassets bundle %s with #%s image files.",
          bundle.path.basename, bundle.resources.count

        return nil if bundle.resources.empty?

        section_data = build_images_section_data(bundle.resources.map(&:name))

        return nil if section_data.empty?

        section_name = "#{basename_without_ext(bundle.path)}Assets"

        XCResources::Section.new section_name, section_data
      end

    end

  end
end
