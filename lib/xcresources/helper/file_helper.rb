module XCResources
  module FileHelper

    # Return the basename without its extname
    # e.g: 'dir/test.jpg' => 'test'
    #
    # @param  [String] file_path
    #
    # @return [String]
    #
    def basename_without_ext file_path
      File.basename file_path, File.extname(file_path)
    end

  end
end
