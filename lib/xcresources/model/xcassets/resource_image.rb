require 'active_support/core_ext/string/inflections'

module XCResources::XCAssets

  # Represents a single image of a resource in a xcassets bundle
  #
  class ResourceImage

    # The known keys
    KNOWN_KEYS = [
        :filename,
        :scale,
        :orientation,
        :size,
        :idiom,
        :subtype,
        :extent,
        :minimum_system_version
    ].freeze

    # @return [Pathname]
    #         file name
    attr_accessor :filename

    # @return [Integer]
    #         scale of the image
    attr_accessor :scale

    # @return [Symbol]
    #         the orientation, e.g. 'portrait'
    attr_accessor :orientation

    # @return [String]
    #         the size, e.g. '29x29', '40x40'
    attr_accessor :size

    # @return [Symbol]
    #         the idiom, e.g. 'iphone'
    attr_accessor :idiom

    # @return [Symbol]
    #         the subtype, e.g. 'retina4'
    attr_accessor :subtype

    # @return [Symbol]
    #         the extent, e.g. 'full-screen'
    attr_accessor :extent

    # @return [String]
    #         the minimum system version, e.g. '7.0'
    attr_accessor :minimum_system_version

    # @return [Hash{Symbol => String}]
    #         further attributes, not mapped to a specific attribute
    attr_accessor :attributes

    # Read from hash
    #
    # @param  [Hash]
    #         the hash to deserialize
    #
    # @return [ResourceImage]
    #
    def self.read(hash)
      self.new.read(hash)
    end

    # Read from hash
    #
    # @param  [Hash]
    #         the hash to deserialize
    #
    # @return [ResourceImage]
    #
    def read(hash)
      self.scale = hash.delete('scale').sub(/x$/, '').to_i unless hash['scale'].nil?

      KNOWN_KEYS.each do |key|
        self.send "#{key}=".to_sym, hash.delete(key.to_s.dasherize)
      end

      self.attributes = hash

      return self
    end

    # Serialize to hash
    #
    # @return [Hash{String => String}]
    #
    def to_hash
      hash = {}

      hash['scale'] = "#{scale}x" unless scale.nil?

      (KNOWN_KEYS - [:scale]).each do |key|
        value = self.send(key)
        hash[key.to_s.dasherize] = value.to_s unless value.nil?
      end

      attributes.each do |key, value|
        hash[key.to_s] = value
      end

      hash
    end

    def ==(other)
      return false unless other.respond_to?(:to_hash)
      self.to_hash == other.to_hash
    end

    alias eql? ==

  end

end
