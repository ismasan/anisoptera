require 'ostruct'
require 'rack/mime'
require 'anisoptera/commander'
require 'anisoptera/serializer'
require 'anisoptera/version'
require 'anisoptera/app'
require 'anisoptera/endpoint'

module Anisoptera
  
  HEADERS = {
    'Cache-Control'   => 'public, max-age=3153600'
  }.freeze
  
  @apps = {}
  @prefer_async = true
  
  def prefer_async=(bool)
    @prefer_async = bool
  end
  
  def prefer_async
    !!@prefer_async
  end
  
  def [](app_name)
    @apps[app_name] ||= Anisoptera::App.new
  end
  
  extend self
  
end
