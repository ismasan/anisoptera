module Anisoptera
  class App

    def initialize
      @config = OpenStruct.new
    end

    def configure(&block)
      block.call @config
    end

    def endpoint(&block)
      @endpoint ||= Anisoptera::Endpoint.factory(@config, block)
    end

  end
end