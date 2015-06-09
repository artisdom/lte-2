#!/usr/bin/env ruby

require 'socket'
require_relative 'lte_lib'

TARGET_IP = ARGV[0]
TARGET_PORT = ARGV[1]
PKG_SIZE = ARGV[2]
PKG_INTERVAL = ARGV[3]
STREAM_ID = ARGV[4]

a=0
[
  TARGET_IP, TARGET_PORT,
  PKG_SIZE, PKG_INTERVAL, STREAM_ID
].each do |p|
  raise ArgumentError.new "#{a} argument missing... (TARGET_IP, TARGET_PORT, PKG_SIZE, PKG_INTERVAL, STREAM_ID)" if p.nil?
  a+=1
end
if PKG_SIZE.to_i <= 24
  raise ArgumentError.new 'package size has to be bigger than 24byte'
end

logit "#100;Start Sender;#{TARGET_IP};#{TARGET_PORT};#{PKG_SIZE};#{PKG_INTERVAL}"
socket = UDPSocket.new
interval = PKG_INTERVAL.to_f
content = ("a" * (PKG_SIZE.to_i - 24))
stream_id = STREAM_ID.rjust '4', '0'
c=0
loop do
  c+=1
  socket.send (c.to_s.rjust(20,'0') + stream_id + content), 0, TARGET_IP, TARGET_PORT
  logit "#101;Send UDP Telegram;#{c};#{PKG_SIZE};#{TARGET_IP};#{TARGET_PORT}"
  sleep interval
end
