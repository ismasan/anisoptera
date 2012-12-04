# encoding: utf-8
require File.dirname(__FILE__) + '/test_helper'

require 'thin'
require 'thin/async'
require 'thin/async/test'
require 'rack/test'
require 'http_router'
require "base64"

$HERE = File.dirname(__FILE__)

$CONVERT = "/usr/local/bin/convert"

describe 'Anisoptera::AsyncEndpoint' do
  include Rack::Test::Methods
  
  def app
    Thin::Async::Test.new(@app)
  end
      
  before do
    # redefine config each time to reset app
    Anisoptera[:media].configure do |config|
      config.base_path = File.join($HERE, 'files')
      config.error_status = nil
      config.error_image = nil
      config.convert_command = $CONVERT
    end
    
    @app = HttpRouter.new do
      add('/:g/:file').to Anisoptera[:media].endpoint {|image, params|
        image_path = params[:file]
        image.file(image_path).thumb(params[:g])
        image.greyscale if params[:grey]
        image.encode('jpg')
      }
    end
  end
  
  shared_examples_for "a cached image" do |status, content_type|
    
    it 'should have status 200' do
      last_response.status.should == status
    end
    
    it 'should have long-lived headers' do
      last_response.headers["Cache-Control"].should == "public, max-age=3153600"
    end
    
    it 'should return Last-Modified header' do
      last_response.headers['Last-Modified'].should == @the_time
    end
    
    it 'should return encoded content-type' do
      last_response.headers['Content-Type'].should == content_type
    end
  end
  
  shared_examples_for 'resized image data' do |test_image, geometry, content_type|
    it 'should return resized image data' do
      tempimg = File.join($HERE, 'files', "temp.#{content_type}")
      Base64.encode64(`#{$CONVERT} #{test_image} -resize \"#{geometry}\" #{tempimg}`)
      Base64.encode64(last_response.body).should == Base64.encode64(File.read(tempimg))
      File.unlink(tempimg)
    end
  end
  
  describe 'success' do
    before do
      @the_time = mock_time("Sun, 20 Nov 2011 01:21:21 GMT") 
      get '/20x20/test.gif'
    end
    
    it_behaves_like 'a cached image', 200, 'image/jpeg'
    
    it_behaves_like 'resized image data', File.join($HERE,'files','test.gif'), '20x20', 'jpg'
    
  end
  
  describe 'with querystring' do
    before do
      @the_time = mock_time("Sun, 20 Nov 2011 01:21:21 GMT")
      get '/20x20/missing.gif?file=test.gif'
    end
    
    it_behaves_like 'a cached image', 200, 'image/jpeg'
    
  end
  
  describe 'with custom headers' do
    before do
      # redefine config each time to reset app
      Anisoptera[:custom].configure do |config|
        config.base_path = File.join($HERE, 'files')
        config.headers = {
          'Cache-Control' => '1234567890',
          'X-Custom'      => 'custom-head'
        }
      end

      @app = HttpRouter.new do
        add('/:g/:file').to Anisoptera[:custom].endpoint {|image, params|
          image_path = params[:file]
          image.file(image_path).thumb(params[:g])
          image.encode('jpg')
        }
      end
      
      it 'should return encoded content-type' do
        last_response.headers['Content-Type'].should == 'image/jpg'
      end
      
      it 'should overwrite passed headers' do
        last_response.headers['Cache-Control'].should == '1234567890'
      end
      
      it 'should add passed new headers' do
        last_response.headers['X-Custom'].should == 'custom-head'
      end
      
    end
  end
  
  describe 'missing image' do
    before do
      @the_time = mock_time("Sun, 20 Nov 2011 01:21:21 GMT")
      get '/20x20/testfoo.gif'
    end
    
    it_behaves_like 'a cached image', 404, 'image/png'
    
    it_behaves_like 'resized image data', File.join($HERE,'..','lib','anisoptera', 'error.png'), '20x20', 'jpg'
  end
  
  describe 'missing image with error image configured' do
    before do
      @the_time = mock_time("Sun, 20 Nov 2011 01:21:21 GMT")
      Anisoptera[:media].config.error_image = File.join($HERE, 'files', 'Chile.gif')
      get '/20x20/testfoo.gif'
    end
    
    it_behaves_like 'a cached image', 404, 'image/gif'
    
    it_behaves_like 'resized image data', File.join($HERE,'files', 'Chile.gif'), '20x20', 'jpg'
  end
  
  describe 'with malformed geometry' do
    before do
      @the_time = mock_time("Sun, 20 Nov 2011 01:21:21 GMT")
      get '/20x20wtf/test.gif'
    end
    
    it_behaves_like 'a cached image', 500, 'image/png'
    
    it 'should set X-Error header' do
      last_response.headers['X-Error'].should == "Didn't recognise the geometry string 20x20wtf."
    end
  end
  
  describe 'with exceptions in custom block' do
    
    before do
      @the_time = mock_time("Sun, 20 Nov 2011 01:21:21 GMT")
      
      @app = HttpRouter.new do
        add('/:g/:file').to Anisoptera[:media].endpoint {|image, params|
          raise 'Oops!'
        }
      end
      
      get '/20x20/test.gif'
    end
    
    it_behaves_like 'a cached image', 500, 'image/png'
    
    it 'should set X-Error header' do
      last_response.headers['X-Error'].should == 'Oops!'
    end
    
  end
  
  describe 'with exceptions and custom config.error_status' do
    before do
      @the_time = mock_time("Sun, 20 Nov 2011 01:21:21 GMT")
      Anisoptera[:media].config.error_status = 200
      
      get '/20x20/testfoo.gif'
    end
    
    it_behaves_like 'a cached image', 200, 'image/png'
    
    it 'should set X-Error header' do
      last_response.headers['X-Error'].should == 'Image not found'
    end
    
  end
  
  describe 'with exceptions in custom block and custom error_status' do
    
    before do
      Anisoptera[:media].config.error_status = 200
      @the_time = mock_time("Sun, 20 Nov 2011 01:21:21 GMT")
      
      @app = HttpRouter.new do
        add('/:g/:file').to Anisoptera[:media].endpoint {|image, params|
          raise 'Oops!'
        }
      end
      
      get '/20x20/test.gif'
    end
    
    it_behaves_like 'a cached image', 200, 'image/png'
    
    it 'should set X-Error header' do
      last_response.headers['X-Error'].should == 'Oops!'
    end
    
  end
  
  describe 'with exceptions and config.on_error block' do
    
    before do
      @the_time = mock_time("Sun, 20 Nov 2011 01:21:21 GMT")
      
      @error_message = ''
      @error_params = nil
      @env = nil
      Anisoptera[:media].config.on_error do |exception, params, env|
        @error_message = 'Oops!'
        @error_params = params
        @env = env
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
      @env['SCRIPT_NAME'].should == '/20x20/test.gif'
    end
    
    it_behaves_like 'a cached image', 500, 'image/png'
    
    it 'should set X-Error header' do
      last_response.headers['X-Error'].should == 'Oops!'
    end
    
  end
end