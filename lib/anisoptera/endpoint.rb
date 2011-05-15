module Anisoptera
  
  module Endpoint
    
    def self.factory(config, block)
        
      @end_point ||= if (defined?(EventMachine) && EventMachine.reactor_running?) && Anisoptera.prefer_async
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
    
  end
  
end