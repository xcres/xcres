require 'xcres/command/project_command'
require 'xcres/helper/file_helper'
require 'xcres/builder/resources_builder'
require 'xcres/analyzer/aggregate_analyzer'
require 'xcres/analyzer/resources_aggregate_analyzer'
require 'xcres/analyzer/strings_analyzer'

# The +BuildCommand+ builds the resources index files.
#
class XCRes::BuildCommand < XCRes::ProjectCommand

  include XCRes::FileHelper

  inherit_parameters!
  parameter '[OUTPUT_PATH]', 'Path where to write to', attribute_name: :output_path

  def execute
    super

    # Derive the name for the resources constant file
    self.resources_constant_name ||= derive_resources_constant_name

    # Locate output path
    self.output_path = locate_output_path

    build do |builder|
      analyzer = XCRes::AggregateAnalyzer.new(target)
      analyzer.exclude_file_patterns = exclude_file_patterns
      analyzer.logger = logger
      analyzer.add_with_class(XCRes::ResourcesAggregateAnalyzer, shorten_keys: true)
      analyzer.add_with_class(XCRes::StringsAnalyzer, default_language: default_language)
      sections = analyzer.analyze

      sections.each do |section|
        builder.add_section section.name, section.items, section.options
      end
    end

    success 'Successfully updated: %s', "#{output_path}.swift"
  end

  def derive_resources_constant_name
    # Fall back to `basename OUTPUT_PATH` or 'R' if both are not given
    if output_path != nil && !File.directory?(output_path)
      basename_without_ext(output_path)
    else
      'R'
    end
  end

  def output_dir
    if output_path.nil?
      # Use project dir, if no output path was set
      Pathname(xcodeproj_file_path) + '..'
    else
      path = Pathname(output_path)
      if path.directory?
        path
      else
        path + '..'
      end
    end
  end

  def locate_output_path
    output_dir.realdirpath + resources_constant_name
  end

  def build
    # Prepare builder
    builder = XCRes::ResourcesBuilder.new
    builder.output_path = output_path
    builder.logger = logger
    builder.documented = documented?
    builder.resources_constant_name = resources_constant_name

    yield builder

    # Write the files, if needed
    builder.build
  end

end
