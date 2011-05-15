module Anisoptera
  
  class SyncEndpoint
    
    include Anisoptera::Endpoint
    
    def call(env)
      params = routing_params(env)
      job = Anisoptera::Commander.new( @config.base_path )
      convert = @handler.call(job, params)
      
      result = `#{convert.command}`
      headers = Anisoptera::HEADERS.dup.update('Content-Type' => convert.mime_type)
      
      [200, headers, [result]]
    end
    
  end
  
end