require 'xcres/command/command'
require 'xcodeproj'

# The +ProjectCommand+ is the base class for commands,
# which analyze or modify Xcode projects.
#
class XCRes::ProjectCommand < XCRes::Command

  option ['--[no-]documented'], :flag, 'Add documentation to the generated files', default: true
  #option ['-d', '--dry-run'], :flag, 'Does nothing on the file system'

  option ['-t', '--target'], 'TARGET', 'Target to search & analyze', attribute_name: :target_name
  option ['-x', '--exclude'], 'FILE_PATTERN', 'File pattern which should be excluded (default: ["InfoPlist.strings"])', multivalued: true, attribute_name: :exclude_file_patterns, default: ['InfoPlist.strings']
  option ['-n', '--name'], 'NAME', 'Name of the resources constant (default: `basename OUTPUT_PATH`)', attribute_name: :resources_constant_name
  option ['-l', '--language'], 'LANGUAGE', 'Default language to build the keys', attribute_name: :default_language do |language|
    raise ArgumentError.new 'Expected a two-letter code conforming ISO 639-1 as LANGUAGE' unless String(language).length == 2
    language
  end

  # Define parameter in an inheritable way
  #
  def self.inherit_parameters!
    parameter '[XCODEPROJ]', 'Xcode project file to inspect (automatically located on base of the current directory if not given)', attribute_name: :xcodeproj_file_path
  end


  def execute
    super

    # Try to discover Xcode project at given path.
    self.xcodeproj_file_path = find_xcodeproj
  end


  #----------------------------------------------------------------------------#

  # @!group Xcode Project

  # Opens the Xcode project, if not already opened
  #
  # @return [Xcodeproj::Project]
  #         the Xcode project
  #
  def project
    @project ||= Xcodeproj::Project.open(xcodeproj_file_path)
  end

  # Find the application target to use
  #
  # @return [PBXNativeTarget]
  #
  def target
    @target ||= if target_name != nil
      target = native_targets.find { |t| t.name == target_name }
      if target.nil?
        raise ArgumentError.new "Unknown target '#{target_name}'. "
      end
      target
    else
      if application_targets.count == 1
        application_targets.first
      else
        raise ArgumentError.new 'Multiple application target in project. ' \
          'Please select one by specifying the option `--target TARGET`.'
      end
    end
  end

  # Find all native targets in the project
  #
  # @return [Array<PBXNativeTarget>]
  #
  def native_targets
    @native_targets ||= project.targets.select do |target|
      target.is_a?(Xcodeproj::Project::Object::PBXNativeTarget)
    end
  end

  # Find all application targets in the project
  #
  # @return [Array<PBXNativeTarget>]
  #
  def application_targets
    @application_targets ||= native_targets.select do |target|
      target.product_type == Xcodeproj::Constants::PRODUCT_TYPE_UTI[:application]
    end
  end

  def find_xcodeproj
    path = discover_xcodeproj_file_path!

    if !Dir.exist?(path) || !File.exist?(path + '/project.pbxproj')
      raise ArgumentError.new 'XCODEPROJ at %s was not found or is not a ' \
        'valid Xcode project.' % path
    end

    success 'Use %s as XCODEPROJ.', path

    return path
  end

  def discover_xcodeproj_file_path!
    if xcodeproj_file_path.nil?
      warn 'Argument XCODEPROJ is not set. Use the current directory.'
      discover_xcodeproj_file_path_in_dir! '.'
    elsif Dir.exist?(xcodeproj_file_path) && !File.fnmatch('*.xcodeproj', xcodeproj_file_path)
      warn 'Argument XCODEPROJ is a directory. ' \
           'Try to locate the Xcode project in this directory.'
      discover_xcodeproj_file_path_in_dir! xcodeproj_file_path
    else
      xcodeproj_file_path
    end
  end

  def discover_xcodeproj_file_path_in_dir! dir
    xcodeproj_file_paths = Dir[dir + '/*.xcodeproj']
    if xcodeproj_file_paths.count == 0
      raise ArgumentError.new 'Argument XCODEPROJ was not given and no ' \
                              '*.xcodeproj was found in current directory.'
    end
    xcodeproj_file_paths.first
  end

end
