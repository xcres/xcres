require 'xcodeproj'
require 'yaml'

class Xcodeproj::Project::Object::PBXShellScriptBuildPhase
  def pretty_print
    hash = {}
    simple_attributes.each do |attr|
      value = attr.get_value(self)
      hash[attr.plist_name] = value if value
    end
    { display_name => hash }
  end
end

class Xcodeproj::Project::Object::XCBuildConfiguration
  def pretty_print
    data = {}
    data['Build Settings'] = {}.tap do |sorted_settings|
      build_settings.keys.sort.each do |key|
        sorted_settings[key] = build_settings[key]
      end
    end
    if base_configuration_reference
      data['Base Configuration'] = base_configuration_reference.pretty_print
    end
    { name => data }
  end
end

class Xcodeproj::Project
  def to_yaml
    pretty_print_output = pretty_print
    sections = []
    sorted_keys = ['File References', 'Targets', 'Build Configurations']
    sorted_keys.each do |key|
      yaml =  { key => pretty_print_output[key] }.to_yaml
      sections << yaml
    end
    (sections * "\n\n").gsub!('---', '')
  end
end
