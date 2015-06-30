require 'webrick'
require "#{File.dirname(File.expand_path(__FILE__))}/../lte_lib"

include WEBrick

s = HTTPServer.new(Port: 4000, :ServerType => WEBrick::Daemon)

s.mount '/', HTTPServlet::FileHandler, "#{File.dirname(File.expand_path(__FILE__))}/public"

trap("INT") { s.shutdown }

s.start
