require 'webrick'

include WEBrick

s = HTTPServer.new(Port: 4000)

s.mount '/', HTTPServlet::FileHandler, 'public'

trap("INT") { s.shutdown }

s.start
