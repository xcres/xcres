require 'json'
require 'xcresources/helper/file_helper'
require 'xcresources/model/xcassets/resource_image'

module XCResources::XCAssets

  # Represents a single resource of a XCAssets bundle
  #
  class Resource
    include XCResources::FileHelper

    # @return [XCAssets::Bundle]
    #         the whole bundle
    attr_accessor :bundle

    # @return [Pathname]
    #         the directory name
    attr_accessor :path

    # @return [Hash]
    #         file meta info
    attr_accessor :info

    # @return [Array<ResourceImage>]
    #         the images contained in this resource
    attr_accessor :images

    # Initialize a new resource
    #
    # @param  [XCAssets:Bundle]
    #         the containing bundle
    #
    # @param  [Pathname]
    #         see #path.
    #
    def initialize(bundle, path)
      self.bundle = bundle
      self.path = path
    end

    # Return the name of the resource
    #
    # @return [String]
    #
    def name
      @name ||= basename_without_ext path
    end

    # Return the type of the resource,
    # e.g. 'appiconset', 'imageset', 'launchimage'
    #
    # @return [String]
    #
    def type
      @type ||= File.extname(path).sub(/^./, '')
    end

    # Lazy read the info, if not initialized
    #
    # @return [Hash]
    #
    def info
      @info ||= read_info
    end

    # Lazy read the images, if not initialized
    #
    # @return [Array<XCAssets::ResourceImage>]
    #
    def images
      @images ||= read_images
    end

    # Serialize to hash
    #
    # @return [Hash]
    #
    def to_hash
      {
        'images' => images.map(&:to_hash),
        'info' => info,
      }
    end

    protected

    # The path of the Contents.json file
    #
    # @return [Pathname]
    #
    def json_path
      bundle.path + path + 'Contents.json'
    end

    # Parse the Content.json file
    #
    # @return [Hash]
    #
    def parsed_contents
      @hash ||= JSON.parse File.read(json_path)
    end

    # Deserialize #contents.
    #
    # @return [XCAssets::Resource]
    #
    def read
      @info = read_info
      @images = read_images
      self
    end

    # Deserialize the file info from the #contents.
    #
    # @return [Hash]
    #
    def read_info
      parsed_contents['info'] || {}
    end

    # Deserialize the images from the #contents.
    #
    # @return [Array<XCAssets::ResourceImage>]
    #
    def read_images
      return [] if parsed_contents['images'].nil?
      parsed_contents['images'].map do |img_hash|
        ResourceImage.read(img_hash)
      end
    end

    def ==(other)
      return false unless other.respond_to?(:to_hash)
      self.to_hash == other.to_hash
    end

    alias eql? ==

  end

end
