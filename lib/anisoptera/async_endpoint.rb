require 'eventmachine'
require 'thin/async'

module Anisoptera

  class AsyncEndpoint
    
    include Anisoptera::Endpoint
    
    # This is a template async response.
    AsyncResponse = [-1, {}, []].freeze

    STATUSES = {
      0   => 200,
      1   => 500,
      255 => 200 # exit status represented differently when running tests in editor
    }

    def call(env)
      response = Thin::AsyncResponse.new(env)
      
      params = routing_params(env)
      
      begin
        job = Anisoptera::Commander.new( @config.base_path, @config.convert_command )
        convert = @handler.call(job, params)
        response.headers.update(update_headers(convert))
        
        if !job.check_file
          response.headers['X-Error'] = 'Image not found'  
          handle_error error_status(404), response, convert
        else
          handle_success response, convert
        end
      rescue => boom
        response.headers['X-Error'] = boom.message
        response.headers.update(update_headers)
        @config.on_error.call(boom, params, env) if @config.on_error
        handle_error(error_status(500), response)
      end

      response.finish
    end
    
    protected
    
    def handle_success(response, convert)
      EM.system( convert.command ){ |output, status| 
        http_status = STATUSES[status.exitstatus]
        response.status = http_status
        r = http_status == 200 ? output : 'SERVER ERROR'
        response << r
        response.done
      }
    end
    
    def handle_error(status, response, convert = nil)
      response.status = status
      response.headers['Content-Type'] = Rack::Mime.mime_type(::File.extname(error_image))
      if convert # pass error image through original IM command
        EM.system( convert.command(error_image) ){ |output, status| 
          response << output
          response.done
        }
      else # just blocking read because user handler blew up
        response << ::File.read(error_image)
        response.done
      end
    end

  end
  
end