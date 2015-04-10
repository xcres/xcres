require 'xcodeproj'
require 'xcres/helper/file_helper'
require 'xcres/model/section'

module XCRes

  # An +Analyzer+ scans the project for references,
  # which should be included in the output file.
  #
  class Analyzer
    include XCRes::FileHelper

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
      @sections = @sections.compact.reject { |s| s.items.nil? || s.items.empty? }
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
    # @return [XCRes::Section]
    #
    def new_section(name, data, options={})
      XCRes::Section.new(name, data, self.options.merge(options))
    end

    # Check if the given path matches the configured exclude file pattern
    #
    # @param Pathname path
    #        the path to match against
    #
    # @param [Bool]
    #        the match result
    #
    def should_exclude_path path
      exclude_file_patterns.any? { |pattern| File.fnmatch("#{pattern}", path) || File.fnmatch("**/#{pattern}", path) }
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
        should_exclude_path path
      end
    end

    # Apply the configured exclude file patterns to a list of file references
    #
    # @param [Array<PBXFileReference>] file_references
    #        the list of files to filter
    #
    # @param [Array<PBXFileReference>]
    #        the filtered list of files
    #
    def filter_ref_exclusions file_references
      file_references.reject do |ref|
        should_exclude_path ref.path
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
