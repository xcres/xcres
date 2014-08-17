require 'xcodeproj'
require 'clamp'
require 'xcresources/helper/file_helper'
require 'xcresources/builder/resources_builder'
require 'xcresources/logger'
require 'xcresources/analyzer/aggregate_analyzer'
require 'xcresources/analyzer/resources_aggregate_analyzer'
require 'xcresources/analyzer/strings_analyzer'

class XCResources::Command < Clamp::Command

  include XCResources::FileHelper

  option ['--silent'], :flag, 'Show nothing'
  option ['--version'], :flag, 'Show the version'
  option ['--[no-]ansi'], :flag, 'Show output without ANSI codes', default: true
  option ['--[no-]documented'], :flag, 'Add documentation to the generated files', default: true
  option ['-v', '--verbose'], :flag, 'Show more debugging information'
  #option ['-d', '--dry-run'], :flag, 'Does nothing on the file system'

  option ['-x', '--exclude'], 'FILE_PATTERN', 'File pattern which should be excluded (default: ["InfoPlist.strings"])', multivalued: true, attribute_name: :exclude_file_patterns, default: ['InfoPlist.strings']
  option ['-n', '--name'], 'NAME', 'Name of the resources constant (default: `basename OUTPUT_PATH`)', attribute_name: :resources_constant_name
  option ['-l', '--language'], 'LANGUAGE', 'Default language to build the keys', attribute_name: :default_language do |language|
    raise ArgumentError.new 'Expected a two-letter code conforming ISO 639-1 as LANGUAGE' unless String(language).length == 2
    language
  end

  parameter '[XCODEPROJ]', 'Xcode project file to inspect (automatically located on base of the current directory if not given)', attribute_name: :xcodeproj_file_path
  parameter '[OUTPUT_PATH]', 'Path where to write to', attribute_name: :output_path


  # Include Logger
  def logger
    @logger ||= XCResources::Logger.new
  end

  delegate :inform, :log, :success, :warn, :fail, to: :logger


  def execute
    if version?
      inform XCResources::VERSION
      return
    end

    # Configure logger
    configure_logger

    # Try to discover Xcode project at given path.
    self.xcodeproj_file_path = find_xcodeproj

    # Derive the name for the resources constant file
    self.resources_constant_name ||= derive_resources_constant_name

    # Locate output path
    self.output_path = locate_output_path

    # Open the Xcode project.
    project = Xcodeproj::Project.open(xcodeproj_file_path)

    build do |builder|
      analyzer = XCResources::AggregateAnalyzer.new(project)
      analyzer.exclude_file_patterns = exclude_file_patterns
      analyzer.logger = logger
      analyzer.add_with_class(XCResources::ResourcesAggregateAnalyzer)
      analyzer.add_with_class(XCResources::StringsAnalyzer, default_language: default_language)
      sections = analyzer.analyze

      sections.each do |section|
        builder.add_section section.name, section.items, section.options
      end
    end

    success 'Successfully updated: %s', "#{output_path}.h"
  rescue ArgumentError => error
    fail error
  end

  def configure_logger
    logger.silent = silent?
    logger.colored = ansi?
    if verbose?
      logger.verbose = verbose?
      log 'Verbose mode is enabled.'
    end
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

  def find_xcodeproj
    path = discover_xcodeproj_file_path!

    if !Dir.exist?(path) || !File.exist?(path + '/project.pbxproj')
      raise ArgumentError.new 'XCODEPROJ at %s was not found or is not a valid Xcode project.' % path
    end

    success 'Use %s as XCODEPROJ.', path

    return path
  end

  def discover_xcodeproj_file_path!
    if xcodeproj_file_path.nil?
      warn 'Argument XCODEPROJ is not set. Use the current directory.'
      discover_xcodeproj_file_path_in_dir! '.'
    elsif Dir.exist?(xcodeproj_file_path) && !File.fnmatch('*.xcodeproj', xcodeproj_file_path)
      warn 'Argument XCODEPROJ is a directory. Try to locate the Xcode project in this directory.'
      discover_xcodeproj_file_path_in_dir! xcodeproj_file_path
    else
      xcodeproj_file_path
    end
  end

  def discover_xcodeproj_file_path_in_dir! dir
    xcodeproj_file_paths = Dir[dir + '/*.xcodeproj']
    if xcodeproj_file_paths.count == 0
      raise ArgumentError.new 'Argument XCODEPROJ was not given and no *.xcodeproj file was found in current directory.'
    end
    xcodeproj_file_paths.first
  end

  def build
    # Prepare builder
    builder = XCResources::ResourcesBuilder.new
    builder.output_path = output_path
    builder.logger = logger
    builder.documented = documented?
    builder.resources_constant_name = resources_constant_name

    yield builder

    # Write the files, if needed
    builder.build
  end

end
