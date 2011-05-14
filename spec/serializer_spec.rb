require File.dirname(__FILE__) + '/test_helper'

describe Anisoptera::Serializer do
  before do
    @data = {:a => 'a', :b => 'b', :c => 11}
    @encoded = Anisoptera::Serializer.marshal_encode(@data)
  end

  describe "encoding" do
    it "must convert object into a string" do
      @encoded.class.must_equal String
    end
  end
  
  describe 'decoding' do
    it 'should recover original object' do
      decoded = Anisoptera::Serializer.marshal_decode(@encoded)
      decoded.must_equal @data
    end
  end

end