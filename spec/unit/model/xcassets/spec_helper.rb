require File.expand_path('../../../spec_helper', __FILE__)
require 'xcres/model/xcassets/bundle'

module XCAssetsSpec
  # Bring the classes into the namespace in which the specs are defined.
  # This is better than into the global namespace, which could influence the
  # behavior of other specs.
  include XCRes::XCAssets

  module Helper
    def xcassets_fixture_path
      fixture_path + 'Example/Example/Images.xcassets'
    end

    def imageset_fixture_path
      xcassets_fixture_path + 'Doge.imageset'
    end
  end

  # Define in each root context a inheritable before, which will extend each
  # sub context with Helper.
  def self.describe(description, &block)
    super description do
      before do
        extend Helper
      end
      instance_eval(&block)
    end
  end

end
