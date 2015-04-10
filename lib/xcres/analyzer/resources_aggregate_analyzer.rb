require 'xcres/analyzer/aggregate_analyzer'
require 'xcres/analyzer/resources_analyzer/bundle_resources_analyzer'
require 'xcres/analyzer/resources_analyzer/loose_resources_analyzer'
require 'xcres/analyzer/resources_analyzer/xcassets_analyzer'
require 'xcres/analyzer/resources_analyzer/font_resources_analyzer'

module XCRes

  # A +ResourcesAnalyzer+ scans the project for resources,
  # which should be included in the output file.
  #
  # It is a +AggregateAnalyzer+, which uses the following child analyzers:
  #  * +XCRes::ResourcesAnalyzer::BundleResourcesAnalyzer+
  #  * +XCRes::ResourcesAnalyzer::LooseResourcesAnalyzer+
  #
  class ResourcesAggregateAnalyzer < AggregateAnalyzer

    def analyze
      self.analyzers = []
      add_with_class ResourcesAnalyzer::BundleResourcesAnalyzer
      add_with_class ResourcesAnalyzer::LooseResourcesAnalyzer
      add_with_class ResourcesAnalyzer::XCAssetsAnalyzer
      add_with_class ResourcesAnalyzer::FontResourcesAnalyzer
      super
    end

  end

end
