# thin start -R http_router -p 3000
#
# http://localhost:3000/media/170x240+210+210/m/pic1.jpg
# http://localhost:3000/media/170x240/m/pic1.jpg
# http://localhost:3000/media/100x100-ne/m/pic1.jpg
# http://localhost:3000/media/100x100-c/m/pic1.jpg
# http://localhost:3000/media/100x100-c/greyscale/pic1.jpg

require 'rubygems'
# require 'bundler'
# Bundler.setup

require 'http_router'

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'anisoptera'

Anisoptera[:media].configure do |config|
  config.base_path = './'
end


routes = HttpRouter.new do
  
  add('/media/:geometry/:color_mode/:filename').to Anisoptera[:media].end_point {|image, params|
    image.file(params[:filename]).thumb(params[:geometry])
    image.greyscale if params[:color_mode] == 'grey'
    image.encode('png')
  }
  
end

run routes