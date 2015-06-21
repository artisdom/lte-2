#!/usr/bin/env ruby

require 'socket'
require_relative 'lte_lib'

port = ARGV[0]

logit "#200;Start GPS Logger;#{port}"

l = ''
TCPSocket.open('192.168.1.1', 7001) do |s|
  loop do
    begin
       begin
       c = s.read_nonblock(1)
       rescue
         retry
       end
       if c == "\n"
         a = l.split ','
         logit "#203;GPS rest;#{l}"
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
    rescue 
    end 
  end
end
