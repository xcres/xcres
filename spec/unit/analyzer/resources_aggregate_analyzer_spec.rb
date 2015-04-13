require File.expand_path('../../spec_helper', __FILE__)

describe 'XCRes::ResourcesAggregateAnalyzer' do

  def subject
    XCRes::ResourcesAggregateAnalyzer
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
      font_section = stub('Font Section')

      XCRes::ResourcesAnalyzer::BundleResourcesAnalyzer.any_instance
        .expects(:analyze).returns([bundle_section_a, bundle_section_b])
      XCRes::ResourcesAnalyzer::LooseResourcesAnalyzer.any_instance
        .expects(:analyze).returns(loose_image_section)
      XCRes::ResourcesAnalyzer::XCAssetsAnalyzer.any_instance
        .expects(:analyze).returns(xcassets_section)
      XCRes::ResourcesAnalyzer::FontResourcesAnalyzer.any_instance
          .expects(:analyze).returns(font_section)

      @analyzer.analyze.should.eql?([bundle_section_a, bundle_section_b, loose_image_section, xcassets_section, font_section])
    end

    it 'should return only bundle sections if there are no loose images or fonts' do
      bundle_section = stub('Bundle Section')
      xcassets_section = stub('XCAssets Section')

      XCRes::ResourcesAnalyzer::BundleResourcesAnalyzer.any_instance
        .expects(:analyze).returns(bundle_section)
      XCRes::ResourcesAnalyzer::LooseResourcesAnalyzer.any_instance
        .expects(:analyze).returns([])
      XCRes::ResourcesAnalyzer::XCAssetsAnalyzer.any_instance
        .expects(:analyze).returns(xcassets_section)
      XCRes::ResourcesAnalyzer::FontResourcesAnalyzer.any_instance
          .expects(:analyze).returns([])

      @analyzer.analyze.should.eql?([bundle_section, xcassets_section])
    end
  end

end
