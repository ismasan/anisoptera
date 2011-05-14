require File.dirname(__FILE__) + '/test_helper'

describe Anisoptera::Commander do
  
  describe 'building file path' do
    
    before do
      @commander = Anisoptera::Commander.new('/data')
    end
    
    it 'must raise error if no file name given' do
      proc {
        @commander.command
      }.must_raise ArgumentError
    end
    
    it 'must correct missing slashes' do
      @commander.file('foo.jpg').command.must_match /^convert \/data\/foo\.jpg/
      @commander.file('/foo.jpg').command.must_match /^convert \/data\/foo\.jpg/
    end
  end
  
  describe 'commands' do
    before do
      @commander = Anisoptera::Commander.new('/data').file('foo.jpg')
    end
    
    describe 'resize' do
      it 'should add resize command' do
        @commander.resize('10x10').command.must_equal 'convert /data/foo.jpg -resize 10x10 -'
      end
    end

    describe 'crop' do
      it 'should add resize command' do
        @commander.crop('120x120+10+5').command.must_equal 'convert /data/foo.jpg -crop 120x120+10+5 -'
      end
    end
    
    describe 'encode' do
      it 'should add format arguments' do
        @commander.encode('gif').command.must_equal 'convert /data/foo.jpg gif:-'
      end
    end
    
    describe 'greyscale' do
      it 'should add colorspace argument' do
        @commander.greyscale.command.must_equal 'convert /data/foo.jpg -colorspace Gray -'
      end
    end
    
    describe 'combined' do
      
      it 'should combine commands' do
        @commander.
          resize('100x100#').
          crop('120x120+10+5').
          encode('png').
          command.must_equal 'convert /data/foo.jpg -resize 100x100# -crop 120x120+10+5 png:-'
      end
    end
    
  end
  
  describe 'mime_type' do
    before do
      @commander = Anisoptera::Commander.new('/data').file('foo.png')
    end
    
    it 'should get default from filename' do
      @commander.mime_type.must_equal 'image/png'
    end
    
  end

end