#!/usr/bin/env ruby

require 'socket'
require_relative 'lte_lib'

TARGET_IP = ARGV[0]
TARGET_PORT = ARGV[1]
PKG_SIZE = ARGV[2]
PKG_INTERVAL = ARGV[3]

a=0
[
  TARGET_IP, TARGET_PORT,
  PKG_SIZE, PKG_INTERVAL
].each do |p|
  raise ArgumentError.new "#{a} argument missing... (TARGET_IP, TARGET_PORT, PKG_SIZE, PKG_INTERVAL)" if p.nil?
  a+=1
end
if PKG_SIZE.to_i <= 20
  raise ArgumentError.new 'package size has to be bigger than 20byte'
end

logit "#100;Start Sender;#{TARGET_IP};#{TARGET_PORT};#{PKG_SIZE};#{PKG_INTERVAL}"
socket = UDPSocket.new
interval = PKG_INTERVAL.to_f
content = ("a" * (PKG_SIZE.to_i - 20))
c=0
loop do
  c+=1
  socket.send (c.to_s.rjust(20,'0') + content), 0, TARGET_IP, TARGET_PORT
  logit "#101;Send UDP Telegram;#{c};#{PKG_SIZE};#{TARGET_IP};#{TARGET_PORT}"
  sleep interval
end
