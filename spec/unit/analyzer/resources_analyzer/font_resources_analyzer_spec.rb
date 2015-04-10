require File.expand_path('../../../spec_helper', __FILE__)

describe 'XCRes::ResourcesAnalyzer::FontResourcesAnalyzer' do

  def subject
    XCRes::ResourcesAnalyzer::FontResourcesAnalyzer
  end

  before do
    @analyzer = subject.new
    @analyzer.logger = stub('Logger', :log)
  end

  describe '#analyze' do
    # TODO
  end

  describe '#build_sections_for_fonts' do
    # TODO
  end

end
