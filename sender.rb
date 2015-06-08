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
  raise ArgumentError.new "#{a} argument missing..." if p.nil?
  a+=1
end

logit "#100;Start Sender;#{TARGET_IP};#{TARGET_PORT};#{PKG_SIZE};#{PKG_INTERVAL}"
socket = UDPSocket.new
interval = PKG_INTERVAL.to_f
content = ("a" * PKG_SIZE.to_i)
loop do
  socket.send content, 0, TARGET_IP, TARGET_PORT
  logit "#101;Send UDP Telegram;#{PKG_SIZE};#{TARGET_IP};#{TARGET_PORT}"
  sleep interval
end
