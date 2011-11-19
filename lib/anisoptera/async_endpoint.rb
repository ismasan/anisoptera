require 'eventmachine'

module Anisoptera
  
  class DeferrableBody
    include EventMachine::Deferrable

    def call(body)
      body.each do |chunk|
        @body_callback.call(chunk)
      end
    end

    def each &blk
      @body_callback = blk
    end

  end

  class AsyncEndpoint
    
    include Anisoptera::Endpoint
    
    # This is a template async response.
    AsyncResponse = [-1, {}, []].freeze

    STATUSES = {
      0   => 200,
      1   => 500
    }

    def call(env)

      params = routing_params(env)

      body = DeferrableBody.new

      job = Anisoptera::Commander.new( @config.base_path )

      convert = @handler.call(job, params)
      
      EventMachine::next_tick { env['async.callback'].call [-1, {'Content-Type' => convert.mime_type}, body] }
      
      if @config.error_image && !job.check_file
        EM.system( convert.command(@config.error_image) ){ |output, status| 
          env['async.callback'].call [404, {'Content-Type' => Rack::Mime.mime_type(::File.extname(@config.error_image))}, body]
          body.call [output]
          body.succeed
        }
      else
        EM.system( convert.command ){ |output, status| 
          http_status = STATUSES[status.exitstatus]
          headers = update_headers(convert)
          env['async.callback'].call [http_status, headers, body]
          r = http_status == 200 ? output : 'SERVER ERROR'
          body.call [r]
          body.succeed
        }
      end

      AsyncResponse
    end

  end
  
end