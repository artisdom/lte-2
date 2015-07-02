#!/usr/bin/env ruby

require 'socket'
require_relative 'lte_lib'

TARGET_PORT = ARGV[0]
PKG_SIZE = ARGV[1]
PKG_INTERVAL = ARGV[2]
STREAM_ID = ARGV[3]
MODE = ARGV[4]
SERVER_IP = ARGV[5]

a=0
[
  TARGET_PORT,
  PKG_SIZE, PKG_INTERVAL, STREAM_ID
].each do |p|
  raise ArgumentError.new "#{a} argument missing... (TARGET_PORT, PKG_SIZE, PKG_INTERVAL, STREAM_ID, MODE, SERVER_IP)" if p.nil?
  a+=1
end
if PKG_SIZE.to_i <= 24
  raise ArgumentError.new 'package size has to be bigger than 24byte'
end
raise ArgumentError.new('wrong mode') unless MODE == 'rp' or MODE == 'qc'

logit "#100;Start Sender;#{TARGET_PORT};#{PKG_SIZE};#{PKG_INTERVAL}"
socket = UDPSocket.new
interval = PKG_INTERVAL.to_f
content = ("a" * (PKG_SIZE.to_i - 24))
stream_id = STREAM_ID.rjust 4, '0'
c=0

target_ip = SERVER_IP
target_port = TARGET_PORT

if MODE == 'qc'
  socket.bind '', TARGET_PORT
  loop do
    begin
      msg, sender_inet_addr = socket.recvfrom_nonblock(1500)
      if msg == 'poke'
        target_port = sender_inet_addr[1]
        target_ip = sender_inet_addr[2]
        logit "#102;Firewall poke received;#{target_ip};#{target_port}"
        break
      end
    rescue IO::WaitReadable
      IO.select([socket])
      retry
    end
  end
end

loop do
  c+=1
  socket.send (c.to_s.rjust(20,'0') + stream_id + content), 0, target_ip, target_port
  logit "#101;Send UDP Telegram;#{c};#{PKG_SIZE};#{target_ip};#{target_port}"

  if MODE == 'qc'
    # check if new poke arrived
    begin
      msg, sender_inet_addr = socket.recvfrom_nonblock(1500)
      if msg == 'poke'
        target_port = sender_inet_addr[1]
        target_ip = sender_inet_addr[2]
        logit "#103;Firewall re-poke received;#{target_ip};#{target_port}"
      end
    rescue IO::WaitReadable
      IO.select([socket])
    end
  end

  sleep interval
end
