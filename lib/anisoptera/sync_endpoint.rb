module Anisoptera
  
  class SyncEndpoint
    
    include Anisoptera::Endpoint
    
    def call(env)
      params = routing_params(env)
      job = Anisoptera::Commander.new( @config.base_path )
      convert = @handler.call(job, params)
      
      result = `#{convert.command}`
      
      headers = update_headers(convert)
      
      [200, headers, [result]]
    end
    
  end
  
end