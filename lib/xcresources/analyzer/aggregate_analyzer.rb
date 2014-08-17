require 'xcresources/analyzer/analyzer'

module XCResources

  # A +AggregateAnalyzer+ runs multiple +Analyzer+.
  #
  class AggregateAnalyzer < Analyzer

    # @return [Array<Analyzer>]
    #         an array of +Analyzer+.
    attr_accessor :analyzers

    def initialize(project=nil, options={})
      super
      self.analyzers = []
    end

    # Run all aggregated analyzers
    #
    # @return [Array<Hash>]
    #         the built sections
    #
    def analyze
      @sections = analyzers.map(&:analyze).flatten
    end

    # Instantiate and add an analyzer by its class.
    # All properties will be copied to the child analyzer.
    #
    # @param [Class] analyzer_class
    #        the class of the analyzer to instantiate and add
    #
    # @param [Hash] options
    #        options which will be passed on initialization
    #
    def add_with_class(analyzer_class, options={})
      analyzer = analyzer_class.new(project, options)
      analyzer.exclude_file_patterns = exclude_file_patterns
      analyzer.logger = logger
      self.analyzers << analyzer
    end

  end

end
