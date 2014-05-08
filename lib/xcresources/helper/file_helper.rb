class File

  def self.basename_without_ext file_path
    self.basename file_path, self.extname(file_path)
  end

end
