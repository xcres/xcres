require 'xcres/command/project_command'
require 'xcres/command/build_command'

# The +InstallCommand+ integrates a build phase to the Xcode project,
# so that on each build the resources index will be rebuild, if needed.
#
class XCRes::InstallCommand < XCRes::ProjectCommand

  BUILD_PHASE_NAME = 'Build Resource-Index'

  inherit_parameters!

  # Execute the command
  #
  # @return [void]
  #
  def execute
    super

    # Locate the parent group, where the built files will been added to
    parent_group = find_parent_group

    # Locate the output path
    output_path = parent_group.real_path + 'Resources/R'

    inform 'Execute build first:'
    build(output_path)

    integrate!(output_path, parent_group)

    success 'Successfully integrated into %s', project_path
  end

  # Find parent group, where the built files will been added to.
  # It will return the first group, which was found of the following list.
  #   * 'Supporting Files' group
  #   * target-specific group
  #   * main group
  #
  # @raise [ArgumentError]
  #        if no main group exists, which means that the project is invalid
  #
  # @return [PBXGroup]
  #
  def find_parent_group
    # Get main group and ensure that it exists
    main_group = project.main_group
    raise ArgumentError, "Didn't find main group" if main_group.nil?

    # Get target-specific group, if the default project layout is in use
    src_group = main_group.groups.find { |g| g.path == target.name }
    if src_group != nil
      log "Found target group, will use its path as base output path."
    else
      log "Didn't find target group, expected a group with path '#{target.name}'."
    end

    # Find 'Supporting Files' group
    groups = main_group.recursive_children_groups
    support_files_group = groups.find { |g| g.name == 'Supporting Files' }
    warn "Didn't find support files group" if support_files_group.nil?

    support_files_group || src_group || main_group
  end

  # Trigger a build for the current project
  #
  # @param [Pathname] output_path
  #        the argument OUTPUT_PATH for the build subcommand
  #
  # @return [void]
  #
  def build(output_path)
    build_cmd = XCRes::BuildCommand.new("#{invocation_path} build", context, attribute_values)
    build_cmd.logger.indentation = '    '
    build_cmd.run([project_path.to_s, output_path.relative_path_from(Pathname.pwd).to_s])
  end

  # Integrate the build phase and add the built files to the project
  #
  # @param [Pathname] output_path
  #        the argument OUTPUT_PATH for the build subcommand
  #
  # @param [PBXGroup] parent_group
  #        the group where to integrate
  #
  # @return [void]
  #
  def integrate!(output_path, parent_group)
    # Find or create shell script build phase
    build_phase = target.shell_script_build_phases.find do |bp|
      bp.name == BUILD_PHASE_NAME
    end
    build_phase ||= target.new_shell_script_build_phase(BUILD_PHASE_NAME)

    # Remove build phase to re-insert before compile sources
    target.build_phases.delete(build_phase)
    index = target.build_phases.index(target.source_build_phase)
    target.build_phases.insert(index, build_phase)

    # Set shell script
    script_output_path = output_path.relative_path_from(src_root_path)
    documented_argument = documented? ? "--documented" : "--no-documented"
    build_phase.shell_script = "xcres --no-ansi build #{documented_argument} $PROJECT_FILE_PATH $SRCROOT/#{script_output_path}\n"
    build_phase.show_env_vars_in_log = '0'

    # Find or create 'Resources' group in 'Supporting Files'
    res_group = parent_group.groups.find { |g| g.name == 'Resources' }
    res_group ||= parent_group.new_group('Resources', Pathname('Resources'))

    # Find or create references to resources index files
    h_file = res_group.find_file_by_path('R.h') || res_group.new_file('R.h')
    m_file = res_group.find_file_by_path('R.m') || res_group.new_file('R.m')

    # Add .m file to source build phase, if it doesn't not already exist there
    target.source_build_phase.add_file_reference(m_file, true)

    # Add .h file to prefix header
    prefix_headers.each do |path|
      realpath = src_root_path + path
      next unless File.exist?(realpath)
      File.open(realpath, 'a+') do |f|
        import_snippet = "#import \"#{h_file.path}\"\n"
        unless f.readlines.include?(import_snippet)
          f.write "\n#{import_snippet}"
        end
      end
    end

    project.save()
  end

  # Return a relative path to the project
  #
  # @return [Pathname]
  #
  def project_path
    project.path.relative_path_from(Pathname.pwd)
  end

  # Return the path, which would be represented by the value of the
  # build setting `$SRCROOT`.
  #
  # @return [Pathname]
  #
  def src_root_path
    project_path.realpath + '..'
  end

  # Return a hash of attribute values
  #
  # @return [Hash{Clamp::Attribute::Definition => #to_s}]
  #
  def attribute_values
    attribute_values = {}
    self.class.recognised_options.each do |attribute|
      if attribute.of(self).defined?
        attribute_values[attribute] = attribute.of(self).get
      end
    end
    attribute_values
  end

  # Discover prefix header by build settings of the application target
  #
  # @return [Set<Pathname>]
  #         the relative paths to the .pch files
  #
  def prefix_headers
    @prefix_headers ||= target.build_configurations.map do |config|
      setting = config.build_settings['GCC_PREFIX_HEADER']
      setting ? Pathname(setting) : nil
    end.flatten.compact.to_set
  end

end
