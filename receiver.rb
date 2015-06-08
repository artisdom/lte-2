#!/usr/bin/env ruby

require 'socket'
require_relative 'lte_lib'

BIND_IP = ARGV[0]
BIND_PORT = ARGV[1]

a=0
[
  BIND_IP, BIND_PORT
].each do |p|
  raise ArgumentError.new "#{a} argument missing..." if p.nil?
  a+=1
end

logit "#000;Start Receiver;#{BIND_IP};#{BIND_PORT}"
socket = UDPSocket.new
socket.bind BIND_IP, BIND_PORT
loop do
  begin
    msg, sender_inet_addr = socket.recvfrom_nonblock(1500)
    leng = msg.count 'a'
    send_port = sender_inet_addr[1]
    ip1 = sender_inet_addr[2]
    ip2 = sender_inet_addr[3]
    logit "#001;Received UDP Telegram;#{leng};#{send_port};#{ip1};#{ip2}"
  rescue IO::WaitReadable
    IO.select([socket])
    retry
  rescue Exception => e
    logit "#002;Exception;#{e.inspect}"
  end
end
