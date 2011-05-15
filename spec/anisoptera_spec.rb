require File.dirname(__FILE__) + '/test_helper'

describe Anisoptera do

  describe "defaults" do
    it "must prefer async by default" do
      Anisoptera.prefer_async.must_equal true
    end
  end

end