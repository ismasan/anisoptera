require File.dirname(__FILE__) + '/test_helper'

describe Anisoptera::Serializer do
  before do
    @data = {:a => 'a', :b => 'b', :c => 11}
    @encoded = Anisoptera::Serializer.marshal_encode(@data)
  end

  describe "encoding" do
    it "must convert object into a string" do
      @encoded.class.should == String
    end
  end
  
  describe 'decoding' do
    it 'should recover original object' do
      decoded = Anisoptera::Serializer.marshal_decode(@encoded)
      decoded.should == @data
    end
  end

end