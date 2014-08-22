require 'apfel'

Apfel::Reader.class_eval do
  def self.read_utf16(file)
    File.open(file, 'r') do |f|
      content = f.read.force_encoding('UTF-8')
      content.encode!('UTF-8', 'UTF-16')
      # remove the BOM that can be found at char 0 in UTF8 strings files
      if content.chars.first == "\xEF\xBB\xBF".force_encoding('UTF-8')
        content.slice!(0)
      end
      content.each_line.inject([]) do |content_array, line|
        line.gsub!("\n","")
        content_array.push(line)
      end
    end
  end
end

Apfel.module_eval do
  require 'apfel/dot_strings_parser'

  def self.parse_utf16(file)
    file = Apfel::Reader.read_utf16(file)
    Apfel::DotStringsParser.new(file).parse_file
  end
end
