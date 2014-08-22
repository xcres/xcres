require File.expand_path('../../../spec_helper', __FILE__)

describe 'XCRes::ResourcesAnalyzer::LooseResourcesAnalyzer' do

  def subject
    XCRes::ResourcesAnalyzer::LooseResourcesAnalyzer
  end

  before do
    @analyzer = subject.new
    @analyzer.logger = stub('Logger', :log)
  end

  describe '#analyze' do
    # TODO
  end

  describe '#build_section_for_loose_images' do
    # TODO
  end

end
