#!/usr/bin/env ruby

require 'socket'
require_relative 'lte_lib'

TARGET_IP = ARGV[0]
TARGET_PORT = ARGV[1]
PKG_SIZE = ARGV[2]
PKG_INTERVAL = ARGV[3]
STREAM_ID = ARGV[4]
MODE = ARGV[5]

a=0
[
  TARGET_IP, TARGET_PORT,
  PKG_SIZE, PKG_INTERVAL, STREAM_ID
].each do |p|
  raise ArgumentError.new "#{a} argument missing... (TARGET_IP, TARGET_PORT, PKG_SIZE, PKG_INTERVAL, STREAM_ID, MODE)" if p.nil?
  a+=1
end
if PKG_SIZE.to_i <= 24
  raise ArgumentError.new 'package size has to be bigger than 24byte'
end
raise ArgumentError.new('wrong mode') unless MODE == 'rp' or MODE == 'qc'

logit "#100;Start Sender;#{TARGET_IP};#{TARGET_PORT};#{PKG_SIZE};#{PKG_INTERVAL}"
socket = UDPSocket.new
interval = PKG_INTERVAL.to_f
content = ("a" * (PKG_SIZE.to_i - 24))
stream_id = STREAM_ID.rjust 4, '0'
c=0

if MODE == 'qc'
  socket.bind '0.0.0.0', TARGET_PORT
  msg, sender_inet_addr = socket.read(4)
  if msg == 'poke'
    target_port = sender_inet_addr[1]
    target_ip = sender_inet_addr[2]
  else
    raise Exception.new 'unknown poke command'
  end
else
  target_ip = TARGET_IP
  target_port = TARGET_PORT
end

loop do
  c+=1
  socket.send (c.to_s.rjust(20,'0') + stream_id + content), 0, target_ip, target_port
  logit "#101;Send UDP Telegram;#{c};#{PKG_SIZE};#{TARGET_IP};#{TARGET_PORT}"
  sleep interval
end
