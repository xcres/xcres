require 'xcres/analyzer/analyzer'

module XCRes

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
      @sections = analyzers.map(&:analyze).flatten.compact
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
    # @return [Analyzer]
    #
    def add_with_class(analyzer_class, options={})
      analyzer = analyzer_class.new(target, self.options.merge(options))
      analyzer.exclude_file_patterns = exclude_file_patterns
      analyzer.logger = logger
      self.analyzers << analyzer
      analyzer
    end

  end

end
