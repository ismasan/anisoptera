module Anisoptera
  class App

    def initialize
      @config = OpenStruct.new
    end

    def configure(&block)
      block.call @config
    end

    def end_point(&block)
      EndPoint.new(@config, &block)
    end

  end
end