require File.expand_path('../../spec_helper', __FILE__)

describe 'XCResources::ResourcesAggregateAnalyzer' do

  def subject
    XCResources::ResourcesAggregateAnalyzer
  end

  before do
    @analyzer = subject.new
    @analyzer.logger = stub('Logger', :log)
  end

  describe '#analyze' do
    it 'should return all sections' do
      bundle_section_a = stub('Bundle Section A')
      bundle_section_b = stub('Bundle Section B')
      loose_image_section = stub('Loose Images Section')
      xcassets_section = stub('XCAssets Section')

      XCResources::ResourcesAnalyzer::BundleResourcesAnalyzer.any_instance
        .expects(:analyze).returns([bundle_section_a, bundle_section_b])
      XCResources::ResourcesAnalyzer::LooseResourcesAnalyzer.any_instance
        .expects(:analyze).returns(loose_image_section)
      XCResources::ResourcesAnalyzer::XCAssetsAnalyzer.any_instance
        .expects(:analyze).returns(xcassets_section)

      @analyzer.analyze.should.eql?([bundle_section_a, bundle_section_b, loose_image_section, xcassets_section])
    end

    it 'should return only bundle sections if there are no loose images' do
      bundle_section = stub('Bundle Section')
      xcassets_section = stub('XCAssets Section')

      XCResources::ResourcesAnalyzer::BundleResourcesAnalyzer.any_instance
        .expects(:analyze).returns(bundle_section)
      XCResources::ResourcesAnalyzer::LooseResourcesAnalyzer.any_instance
        .expects(:analyze).returns([])
      XCResources::ResourcesAnalyzer::XCAssetsAnalyzer.any_instance
        .expects(:analyze).returns(xcassets_section)

      @analyzer.analyze.should.eql?([bundle_section, xcassets_section])
    end
  end

end
