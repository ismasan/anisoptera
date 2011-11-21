require 'rubygems'
require 'bundler'
Bundler.setup

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'anisoptera'


require 'rspec'

def mock_time(atime)
  t = stub('Now')
  Time.stub!(:now).and_return t
  t.stub!(:gmtime).and_return t
  t.should_receive(:strftime).with("%a, %d %b %Y %H:%M:%S GMT").and_return atime
  atime
end