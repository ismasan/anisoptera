# encoding: utf-8
require File.dirname(__FILE__) + '/test_helper'

require 'thin'
require 'thin/async'
require 'thin/async/test'
require 'rack/test'
require 'http_router'
require "base64"

$HERE = File.dirname(__FILE__)

Anisoptera[:media].configure do |config|
  config.base_path = File.join($HERE, 'files')
end

describe 'Anisoptera::AsyncEndpoint' do
  include Rack::Test::Methods
  
  def app
    Thin::Async::Test.new(@app)
  end
      
  before do
    @app = HttpRouter.new do
      add('/:g/:file').to Anisoptera[:media].endpoint {|image, params|
        image_path = params[:file]
        p [:serving, image_path]
        image.file(image_path).thumb(params[:g])
        image.greyscale if params[:grey]
        image.encode('jpg')
      }
    end
  end
  
  describe 'success' do
    before do
      @the_time = "Sun, 20 Nov 2011 01:21:21 GMT"
      mock_time(@the_time)
      get '/20x20/test.gif'
    end
    
    it 'should have status 200' do
      last_response.status.should == 200
    end

    it 'should have long-lived headers' do
      last_response.headers["Cache-Control"].should == "public, max-age=3153600"
    end
    
    it 'should return Last-Modified header' do
      last_response.headers['Last-Modified'].should == @the_time
    end
    
    it 'should return encoded content-type' do
      last_response.headers['Content-Type'].should == 'image/jpeg'
    end
    
    it 'should return resized image data' do
      encoded = Base64.encode64(`convert #{File.join($HERE,'files','test.gif')} -resize \"20x20\" jpg:-`)
      Base64.encode64(last_response.body).should == encoded
    end
  end
  
  describe 'with querystring' do
    before do
      get '/20x20/missing.gif?file=test.gif'
    end
    
    it 'should have status 200' do
      last_response.status.should == 200
    end
    
  end
  
  describe 'missing image' do
    before do
      @the_time = "Sun, 20 Nov 2011 01:21:21 GMT"
      mock_time(@the_time)
      get '/20x20/testfoo.gif'
    end
    
    it 'should return status 404' do
      last_response.status.should == 404
    end
    
    it 'should have long-lived headers' do
      last_response.headers["Cache-Control"].should == "public, max-age=3153600"
    end
    
    it 'should return Last-Modified header' do
      last_response.headers['Last-Modified'].should == @the_time
    end
    
    it 'should use default error image' do
      last_response.headers['Content-Type'].should == 'image/png'
      encoded = Base64.encode64(`convert #{File.join($HERE,'..','lib','anisoptera', 'error.png')} -resize \"20x20\" jpg:-`)
      Base64.encode64(last_response.body).should == encoded
    end
  end
  
  describe 'missing image with error image configured' do
    before do
      @the_time = "Sun, 20 Nov 2011 01:21:21 GMT"
      mock_time(@the_time)
      Anisoptera[:media].config.error_image = File.join($HERE, 'files', 'Chile.gif')
      get '/20x20/testfoo.gif'
    end
    
    it 'should return status 404' do
      last_response.status.should == 404
    end
    
    it 'should have long-lived headers' do
      last_response.headers["Cache-Control"].should == "public, max-age=3153600"
    end
    
    it 'should return Last-Modified header' do
      last_response.headers['Last-Modified'].should == @the_time
    end
    
    it 'should use default error image' do
      last_response.headers['Content-Type'].should == 'image/gif'
      encoded = Base64.encode64(`convert #{File.join($HERE,'files', 'Chile.gif')} -resize \"20x20\" jpg:-`)
      Base64.encode64(last_response.body).should == encoded
    end
  end
  
  describe 'with malformed geometry' do
    before do
      @the_time = "Sun, 20 Nov 2011 01:21:21 GMT"
      mock_time(@the_time)
      get '/20x20wtf/test.gif'
    end
    
    it 'should reuturn status 500' do
      last_response.status.should == 500
    end
    
    it 'should have long-lived headers' do
      last_response.headers["Cache-Control"].should == "public, max-age=3153600"
    end
    
    it 'should return Last-Modified header' do
      last_response.headers['Last-Modified'].should == @the_time
    end
    
    it 'should set X-Error header' do
      last_response.headers['X-Error'].should == "Didn't recognise the geometry string 20x20wtf."
    end
  end
  
  describe 'with exceptions in custom block' do
    
    before do
      @the_time = "Sun, 20 Nov 2011 01:21:21 GMT"
      mock_time(@the_time)
      
      @app = HttpRouter.new do
        add('/:g/:file').to Anisoptera[:media].endpoint {|image, params|
          raise 'Oops!'
        }
      end
      
      get '/20x20/test.gif'
    end
    
    it 'should return status 500' do
      last_response.status.should == 500
    end
    
    it 'should have long-lived headers' do
      last_response.headers["Cache-Control"].should == "public, max-age=3153600"
    end
    
    it 'should return Last-Modified header' do
      last_response.headers['Last-Modified'].should == @the_time
    end
    
    it 'should set X-Error header' do
      last_response.headers['X-Error'].should == 'Oops!'
    end
    
  end
  
  describe 'with exceptions and custom config.error_status' do
    before do
      @the_time = "Sun, 20 Nov 2011 01:21:21 GMT"
      mock_time(@the_time)
      Anisoptera[:media].config.error_status = 200
      
      get '/20x20/testfoo.gif'
    end
    
    it 'should return status 200 as set in config.error_status' do
      last_response.status.should == 200
    end
    
    it 'should have long-lived headers' do
      last_response.headers["Cache-Control"].should == "public, max-age=3153600"
    end
    
    it 'should return Last-Modified header' do
      last_response.headers['Last-Modified'].should == @the_time
    end
    
    it 'should set X-Error header' do
      last_response.headers['X-Error'].should == 'Image not found'
    end
    
  end
  
  describe 'with exceptions in custom block and custom error_status' do
    
    before do
      Anisoptera[:media].config.error_status = 200
      @the_time = "Sun, 20 Nov 2011 01:21:21 GMT"
      mock_time(@the_time)
      
      @app = HttpRouter.new do
        add('/:g/:file').to Anisoptera[:media].endpoint {|image, params|
          raise 'Oops!'
        }
      end
      
      get '/20x20/test.gif'
    end
    
    it 'should return status 200' do
      last_response.status.should == 200
    end
    
    it 'should have long-lived headers' do
      last_response.headers["Cache-Control"].should == "public, max-age=3153600"
    end
    
    it 'should return Last-Modified header' do
      last_response.headers['Last-Modified'].should == @the_time
    end
    
    it 'should set X-Error header' do
      last_response.headers['X-Error'].should == 'Oops!'
    end
    
  end
  
  describe 'with exceptions and config.on_error block' do
    
    before do
      @the_time = "Sun, 20 Nov 2011 01:21:21 GMT"
      mock_time(@the_time)
      
      @error_message = ''
      @error_params = nil
      Anisoptera[:media].config.on_error do |exception, params|
        @error_message = 'Oops!'
        @error_params = params
      end

      @app = HttpRouter.new do
        add('/:gg/:file').to Anisoptera[:media].endpoint {|image, params|
          raise 'Oops!'
        }
      end
      
      get '/20x20/test.gif'
    end
    
    it 'should have called error block' do
      @error_message.should == 'Oops!'
      @error_params.should == {:gg => '20x20', :file => 'test.gif'}
    end
    
    it 'should have long-lived headers' do
      last_response.headers["Cache-Control"].should == "public, max-age=3153600"
    end
    
    it 'should return Last-Modified header' do
      last_response.headers['Last-Modified'].should == @the_time
    end
    
    it 'should set X-Error header' do
      last_response.headers['X-Error'].should == 'Oops!'
    end
    
  end
end