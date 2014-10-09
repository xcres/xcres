require File.expand_path('../spec_helper', __FILE__)

module XCAssetsSpec
  describe 'XCRes::XCAssets::Resource' do

    def subject
      Resource
    end

    before do
      # Make protected and private methods accessible for specs
      subject.send(:public, *subject.protected_instance_methods)
    end

    def expected_info
      {
        "version" => 1,
        "author" => "xcode"
      }
    end

    def expected_contents
      {
        "images" => [
          {
            "idiom" => "universal",
            "scale" => "1x",
            "filename" => "doge.png"
          },
          {
            "idiom" => "universal",
            "scale" => "2x",
            "filename" => "doge@2x.png"
          },
          {
            "idiom" => "universal",
            "scale" => "3x"
          },
        ],
        "info" => expected_info
      }
    end

    describe "#initialize" do
      before do
        @bundle = mock('Bundle')
      end

      it 'sets the first argument as attribute bundle' do
        subject.new(@bundle, imageset_fixture_path).bundle
          .should.be.eql?(@bundle)
      end

      it 'sets the second argument as attribute path' do
        subject.new(@bundle, imageset_fixture_path).path
          .should.be.eql?(imageset_fixture_path)
      end
    end

    describe "instance methods" do
      before do
        @res = subject.new(
          Bundle.new(xcassets_fixture_path),
          imageset_fixture_path
        )
      end

      describe "#name" do
        it 'should match the name' do
          @res.name.should.be.eql?('Doge')
        end
      end

      describe "#type" do
        it 'should match the type' do
          @res.type.should.be.eql?('imageset')
        end
      end

      describe "#info" do
        it 'should match the info' do
          @res.info.should.be.eql?({ "version" => 1, "author" => "xcode" })
        end
      end

      describe "#images" do
        before do
          @images = [mock('ResourceImageA'), mock('ResourceImageB')]
        end

        it 'should return the images, which were set, if any' do
          @res.images = @images
          @res.images.should.be.eql?(@images)
        end

        it 'should parse the contents lazily, if no images are set' do
          @res.expects(:read_images).returns(@images)
          @res.images.should.be.eql?(@images)
        end
      end

      describe "#to_hash" do
        it 'should equal the original parsed JSON file contents' do
          @res.to_hash.should.be.eql?(expected_contents)
        end
      end

      describe "#json_path" do
        it 'should match the expected path' do
          @res.json_path.should.be.eql?(imageset_fixture_path + 'Contents.json')
        end
      end

      describe "#parsed_contents" do
        it 'should equal the expected parsed JSON file contents' do
          @res.parsed_contents.should.be.eql?(expected_contents)
        end
      end

      describe "#read" do
        it 'should return the resource' do
          @res.read.should.be.eql?(@res)
        end
      end

      describe "#read_info" do
        it 'should return the expected info' do
          @res.read_info.should.be.eql?(expected_info)
        end
      end

      describe "#read_images" do
        it 'should return the expected images' do
          @res.images.should.be.eql? [
            ResourceImage.new(idiom: 'universal', scale: 1, filename: 'doge.png'),
            ResourceImage.new(idiom: 'universal', scale: 2, filename: 'doge@2x.png'),
            ResourceImage.new(idiom: 'universal', scale: 3),
          ]
        end
      end

      describe "#==" do
        describe 'same class' do
          it 'should be equal for equal file references' do
            other_res = subject.new(
              Bundle.new(xcassets_fixture_path),
              imageset_fixture_path
            )
            @res.should.be ==(other_res)
          end
        end

        describe 'other class' do
          before do
            @res_img_a = stub('ResourceImageA')

            @other_res = stub('Resource')
            @other_res.stubs(:respond_to?).with(:to_hash).returns(true)
            @other_res.expects(:to_hash).returns({
              images: [@res_img_a]
            })
          end

          it 'should be equal for equal hash representations' do
            @res.expects(:to_hash).returns({ images: [@res_img_a] })
            @res.should.be ==(@other_res)
          end

          it 'should differ if hash representations are different' do
            @res.expects(:to_hash).returns({ images: [stub('ResourceImageB')] })
            @res.should.not.be ==(@other_res)
          end
        end
      end

    end

  end
end
