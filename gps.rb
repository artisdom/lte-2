#!/usr/bin/env ruby

require 'serialport'
require_relative 'lte_lib'

port = ARGV[0]

logit "#200;Start GPS Logger;#{port}"

s = SerialPort.new port, 115200
l = ''
loop do
  begin
     c = s.read_nonblock(1)
     if c == "\n"
       a = l.split ','
       if a[0] == '$GPGGA'
         d = a[1]
         cd = "#{d[0..1]}:#{d[2..3]}:#{d[4..5]}#{d[6..8]}"
         lat = a[2]
         long = a[4]
         logit "#201;GPS Coordinates;#{cd};#{lat};#{a[3]};#{long};#{a[5]};#{a[6]};#{a[7]}"
       elsif a[0] == '$GPVTG'
         speed = a[7]
         logit "#202;GPS Speed in km/h;#{speed}"
       end
       l = ''
     else
       l << c
     end
  rescue IO::WaitReadable
  rescue EOFError
  end 
end
