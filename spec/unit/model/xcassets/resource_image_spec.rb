require File.expand_path('../spec_helper', __FILE__)

module XCAssetsSpec
  describe 'XCRes::XCAssets::ResourceImage' do

    def subject
      ResourceImage
    end

    def input_hash
      {
        filename: "doge.png",
        scale: 2,
        orientation: "portrait",
        size: "40x40",
        idiom: "universal",
        subtype: "retina4",
        extent: "full-screen",
        minimum_system_version: "7.0",
      }
    end

    def serialized_img_hash
      {
        "filename" => "doge.png",
        "scale" => "2x",
        "orientation" => "portrait",
        "size" => "40x40",
        "idiom" => "universal",
        "subtype" => "retina4",
        "extent" => "full-screen",
        "minimum-system-version" => "7.0",
      }
    end

    shared 'has expected attributes' do
      it 'should have expected attributes' do
        @img.filename.should.be.eql? "doge.png"
        @img.scale.should.be.eql? 2
        @img.orientation.should.be.eql? "portrait"
        @img.size.should.be.eql? "40x40"
        @img.idiom.should.be.eql? "universal"
        @img.subtype.should.be.eql? "retina4"
        @img.extent.should.be.eql? "full-screen"
        @img.minimum_system_version.should.be.eql? "7.0"
      end
    end

    describe '::read' do
      describe 'with an empty hash' do
        it 'should be a valid instance' do
          subject.read({}).should.be.an.instance_of?(subject)
        end
      end

      describe 'with all attributes given as hash' do
        before do
          @img = subject.read(serialized_img_hash)
        end

        behaves_like 'has expected attributes'
      end
    end

    describe '#initialize' do
      describe 'without any arguments' do
        it 'should be a valid instance' do
          subject.new.should.be.an.instance_of?(subject)
        end
      end

      describe 'with an empty hash' do
        it 'should be a valid instance' do
          subject.new({}).should.be.an.instance_of?(subject)
        end
      end

      describe 'with all attributes given as hash' do
        before do
          @img = subject.new(input_hash)
        end

        behaves_like 'has expected attributes'
      end
    end

    describe '#read' do
      describe 'with an empty hash' do
        it 'should be a valid instance' do
          subject.new.read({}).should.be.an.instance_of?(subject)
        end
      end

      describe 'with all attributes given as hash' do
        before do
          @img = subject.new.read(serialized_img_hash)
        end

        behaves_like 'has expected attributes'
      end
    end

    describe '#to_hash' do
      it 'should serialize to expected hash' do
        subject.new(input_hash).to_hash.should.be.eql?(serialized_img_hash)
      end
    end

    describe '#==' do
      before do
        @img = subject.new(input_hash)
      end

      describe 'same class' do
        it 'should be equal for same hashes' do
          other_img = subject.new(input_hash)
          @img.should.be ==(other_img)
        end
      end

      describe 'other class' do
        before do
          @other_img = stub('ResourceImage')
          @other_img.stubs(:respond_to?).with(:to_hash).returns(true)
          @other_img.expects(:to_hash).returns({ name: 'Doge' })
        end

        it 'should be equal for equal hash representations' do
          @img.expects(:to_hash).returns({ name: 'Doge' })
          @img.should.be ==(@other_img)
        end

        it 'should differ if hash representations are different' do
          @img.expects(:to_hash).returns({ name: 'NyanCat' })
          @img.should.not.be ==(@other_img)
        end
      end
    end

  end
end
