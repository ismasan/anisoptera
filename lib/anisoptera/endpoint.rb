module Anisoptera
  
  module Endpoint
    
    def self.factory(config, block)
      if defined?(EventMachine) && Anisoptera.prefer_async
        require 'anisoptera/async_endpoint'
        AsyncEndpoint.new(config, &block)
      else
        require 'anisoptera/sync_endpoint'
        SyncEndpoint.new(config, &block)
      end
      
    end
    
    def initialize(config, &block)
      @config = config
      @handler = block
    end

    private

    # Borrowed from Dragonfly
    #
    def routing_params(env)
      env['rack.routing_args'] ||
        env['action_dispatch.request.path_parameters'] ||
        env['router.params'] ||
        env['usher.params'] ||
        raise(ArgumentError, "couldn't find any routing parameters in env #{env.inspect}")
    end
    
    def update_headers(commander = nil)
      heads = Anisoptera::HEADERS.dup.update(
        'X-Generator'  => self.class.name,
        'Last-Modified' =>  Time.now.gmtime.strftime("%a, %d %b %Y %H:%M:%S GMT")
      )
      heads['Content-Type'] = commander.mime_type if commander
      heads
    end
    
    def error_image
      @config.error_image || ::File.join(File.dirname(__FILE__), 'error.png')
    end
    
  end
  
end