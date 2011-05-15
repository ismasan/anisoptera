require 'rack/mime'
require 'anisoptera/commander'
require 'anisoptera/serializer'
require 'anisoptera/version'
require 'anisoptera/app'
require 'anisoptera/end_point'

module Anisoptera
  @apps = {}
  
  def [](app_name)
    @apps[app_name] ||= Anisoptera::App.new
  end
  
  extend self
  
end
