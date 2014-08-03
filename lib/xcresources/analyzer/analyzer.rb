require 'xcresources/helper/file_helper'
require 'xcresources/model/section'

module XCResources

  # An +Analyzer+ scans the project for references,
  # which should be included in the output file.
  #
  class Analyzer
    include XCResources::FileHelper

    # @return [Xcodeproj::Project]
    #         the Xcodeproj to analyze
    attr_reader :project

    # @return [Array<Section>]
    #         the built sections
    attr_reader :sections

    # @return [Array<String>]
    #         the exclude file patterns
    attr_accessor :exclude_file_patterns

    # @return [Logger]
    #         the logger
    attr_accessor :logger

    delegate :inform, :log, :success, :warn, :fail, to: :logger

    # Initialize a new analyzer
    #
    # @param [Xcodeproj::Project] project
    #        see +project+.
    #
    # @param [Hash] options
    #        see subclasses.
    #
    def initialize(project=nil, options={})
      @project = project
      @sections = []
      @exclude_file_patterns = []
    end

    # Analyze the project
    #
    # @return [Array<Section>]
    #         the built sections
    #
    def analyze
      # Empty stub implementation
    end

    # Apply the configured exclude file patterns to a list of files
    #
    # @param [Array<Pathname>] file_paths
    #        the list of files to filter
    #
    # @param [Array<Pathname>]
    #        the filtered list of files
    #
    def filter_exclusions file_paths
      file_paths.reject do |path|
        exclude_file_patterns.any? { |pattern| File.fnmatch "**/#{pattern}", path }
      end
    end

  end
end
