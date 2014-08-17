require 'xcresources/analyzer/aggregate_analyzer'
require 'xcresources/analyzer/resources_analyzer/bundle_resources_analyzer'
require 'xcresources/analyzer/resources_analyzer/loose_resources_analyzer'

module XCResources

  # A +ResourcesAnalyzer+ scans the project for resources,
  # which should be included in the output file.
  #
  # It is a +AggregateAnalyzer+, which uses the following child analyzers:
  #  * +XCResources::ResourcesAnalyzer::BundleResourcesAnalyzer+
  #  * +XCResources::ResourcesAnalyzer::LooseResourcesAnalyzer+
  #
  class ResourcesAggregateAnalyzer < AggregateAnalyzer

    def analyze
      self.analyzers = []
      add_with_class ResourcesAnalyzer::BundleResourcesAnalyzer
      add_with_class ResourcesAnalyzer::LooseResourcesAnalyzer
      super
    end

  end

end
