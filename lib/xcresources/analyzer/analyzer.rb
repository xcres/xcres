require 'xcodeproj'
require 'xcresources/helper/file_helper'
require 'xcresources/model/section'

module XCResources

  # An +Analyzer+ scans the project for references,
  # which should be included in the output file.
  #
  class Analyzer
    include XCResources::FileHelper

    # @return [PBXNativeTarget]
    #         the application target of the #project to analyze.
    attr_reader :target

    # @return [Array<Section>]
    #         the built sections
    attr_reader :sections

    # @return [Hash]
    #         the options passed to the sections
    attr_accessor :options

    # @return [Array<String>]
    #         the exclude file patterns
    attr_accessor :exclude_file_patterns

    # @return [Logger]
    #         the logger
    attr_accessor :logger

    delegate :inform, :log, :success, :warn, :fail, to: :logger

    # Initialize a new analyzer
    #
    # @param [PBXNativeTarget] target
    #        see +target+.
    #
    # @param [Hash] options
    #        see subclasses.
    #
    def initialize(target=nil, options={})
      @target = target
      @sections = []
      @exclude_file_patterns = []
      @options = options
    end

    # Analyze the project
    #
    # @return [Array<Section>]
    #         the built sections
    #
    def analyze
      # Empty stub implementation
    end

    # Return the Xcode project to analyze
    #
    # @return [Xcodeproj::Project]
    #
    def project
      target.project
    end

    # Create a new +Section+.
    #
    # @param  [String] name
    #         see Section#name
    #
    # @param  [Hash] items
    #         see Section#items
    #
    # @param  [Hash] options
    #         see Section#options
    #
    # @return [XCResources::Section]
    #
    def new_section(name, data, options={})
      XCResources::Section.new(name, data, self.options.merge(options))
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
        exclude_file_patterns.any? { |pattern| File.fnmatch("#{pattern}", path) || File.fnmatch("**/#{pattern}", path) }
      end
    end

    # Discover all references to files with a specific extension in project,
    # which belong to a resources build phase of an application target.
    #
    # @param  [String] extname
    #         the extname, which contains a leading dot
    #         e.g.: '.bundle', '.strings'
    #
    # @return [Array<PBXFileReference>]
    #
    def find_file_refs_by_extname(extname)
      project.files.select do |file_ref|
        File.extname(file_ref.path) == extname \
        && is_file_ref_included_in_application_target?(file_ref)
      end
    end

    # Checks if a file ref is included in any resources build phase of any
    # of the application targets of the #project.
    #
    # @param  [PBXFileReference] file_ref
    #         the file to search for
    #
    # @return [Bool]
    #
    def is_file_ref_included_in_application_target?(file_ref)
      resources_files.include?(file_ref)
    end

    # Find files in resources build phases of application targets
    #
    # @return [Array<PBXFileReference>]
    #
    def resources_files
      target.resources_build_phase.files.map do |build_file|
        if build_file.file_ref.is_a?(Xcodeproj::Project::Object::PBXGroup)
          build_file.file_ref.recursive_children
        else
          [build_file.file_ref]
        end
      end.flatten.compact
    end

  end
end
