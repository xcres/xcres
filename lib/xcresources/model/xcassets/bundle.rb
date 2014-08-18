require 'xcresources/model/xcassets/resource'

module XCResources::XCAssets

  # Represents the whole XCAssets bundle
  #
  class Bundle

    # @return [Pathname]
    #
    attr_accessor :path

    # @return [Array<Pathname>]
    #         the paths of the resources contained, relative to the container
    #         given by #path.
    attr_accessor :resource_paths

    # @return [Array<Resource>]
    #         the parsed resources
    attr_accessor :resources

    # Open a XCAssets collection at a given path
    #
    # @return [XCAssets::Bundle]
    #
    def self.open(path)
      self.new(path).read
    end

    # Initialize a new file with given path
    #
    # @param [Pathname] path
    #        the location of the container
    #
    def initialize(path = nil)
      @path = Pathname(path) unless path.nil?
      @resources = []
    end

    # Read the resources from disk
    #
    # @return [XCAssets::Bundle]
    #
    def read
      @resource_paths = Dir.chdir(path) do
        Dir['*'].map { |p| Pathname(p) }
      end
      @resources = @resource_paths.map do |path|
        Resource.new(self, path)
      end
      self
    end
  end

end
