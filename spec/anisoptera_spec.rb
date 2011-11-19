require File.dirname(__FILE__) + '/test_helper'

describe Anisoptera do

  describe "defaults" do
    it "must prefer async by default" do
      Anisoptera.prefer_async.should be_true
    end
  end

end