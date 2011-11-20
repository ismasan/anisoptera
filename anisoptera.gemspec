# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "anisoptera/version"

Gem::Specification.new do |s|
  s.name        = "anisoptera"
  s.version     = Anisoptera::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ismael Celis"]
  s.email       = ["ismaelct@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Async Rack app for image thumbnailing}
  s.description = %q{You'll need an Eventmachine server such as Thin to run this. See README.'}

  s.rubyforge_project = "anisoptera"
  
  s.add_dependency 'eventmachine', ">= 0.12.10"
  s.add_dependency 'thin'
  s.add_dependency 'thin_async'
  s.add_dependency 'rack', ">= 1.2.2"
  
  s.add_development_dependency "bundler", ">= 1.0.0"
  s.add_development_dependency "rack-test"
  s.add_development_dependency "rspec"
  s.add_development_dependency "thin-async-test"
  s.add_development_dependency "http_router"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
