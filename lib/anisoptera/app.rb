module Anisoptera
  
  class Config < OpenStruct
    
    def on_error(&block)
      @on_error = block if block_given?
      @on_error
    end
    
  end
  
  class App
    
    attr_reader :config
    
    def initialize
      @config = Config.new
    end

    def configure(&block)
      block.call @config
    end

    def endpoint(&block)
      Anisoptera::Endpoint.factory(@config, block)
    end

  end
end