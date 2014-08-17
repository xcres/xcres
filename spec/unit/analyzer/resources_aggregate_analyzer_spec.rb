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
      bundle_section_a = stub('Section')
      bundle_section_b = stub('Section')
      loose_image_section = stub('Images')

      XCResources::ResourcesAnalyzer::BundleResourcesAnalyzer.any_instance
        .expects(:analyze).returns([bundle_section_a, bundle_section_b])
      XCResources::ResourcesAnalyzer::LooseResourcesAnalyzer.any_instance
        .expects(:analyze).returns(loose_image_section)

      @analyzer.analyze.should.eql?([bundle_section_a, bundle_section_b, loose_image_section])
    end

    it 'should return only bundle sections if there are no loose images' do
      bundle_sections = [stub('Section')]

      XCResources::ResourcesAnalyzer::BundleResourcesAnalyzer.any_instance
        .expects(:analyze).returns(bundle_sections)
      XCResources::ResourcesAnalyzer::LooseResourcesAnalyzer.any_instance
        .expects(:analyze).returns(nil)

      @analyzer.analyze.should.eql?(bundle_sections)
    end
  end

end
