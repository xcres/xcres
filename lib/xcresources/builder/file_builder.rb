require 'colored'
require 'xcresources/builder/string_builder'
require 'xcresources/helper/file_helper'

class XCResources::FileBuilder

  attr_accessor :output_path

  def prepare_output_path!
    # Ensure that the given directory exists
    output_dir = File.dirname output_path
    unless Dir.exist? output_dir
      puts 'Directory did not exist. Will been created.'.green
      Dir.mkdir output_dir
    end

    # Replace an already existing file, by deleting it and rebuilding from scratch
    if File.exist? output_path
      raise ArgumentError.new 'Output path is a directory!' if Dir.exist? output_path
      puts "Output path already exists. Will be replaced.".yellow
    end
  end

  def build
    prepare_output_path!
  end

  def build_contents &block
    # Pass a new string builder to given block
    builder = XCResources::StringBuilder.new
    block.call builder
    builder.result
  end

  def write_file_eventually file_path, contents
    # Check if the file already exists and touch it only if the contents changed
    if File.exist? file_path
      tmp_dir_path = `/usr/bin/mktemp -d -t xcresources`
      tmp_file_path = tmp_dir_path + File.basename(file_path)

      # Write temp file
      write_file tmp_file_path, contents

      # Diff current version and temporary file
      diff = `/usr/bin/diff #{tmp_file_path} #{file_path}`
      if diff.length == 0
        puts "✓ Existing file is up-to-date. Don't touch.".green
        return
      end
    end

    write_file file_path, contents
  end

  def write_file file_path, contents
    # Write file
    File.open file_path, 'w' do |file|
      file.write contents
    end
  end

end
