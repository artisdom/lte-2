#!/usr/bin/env ruby

require 'socket'
require_relative 'lte_lib'

RCV_IP = ARGV[0]
PORT = ARGV[1]
MODE = ARGV[2]

a=0
[ RCV_IP, PORT, MODE ].each do |p|
  raise ArgumentError.new "#{a} argument missing... (RCV_IP, PORT, MODE)" if p.nil?
  a+=1
end
raise ArgumentError.new('wrong mode') unless MODE == 'rp' or MODE == 'qc'

logit "#000;Start Receiver;#{RCV_IP};#{PORT}"

socket = UDPSocket.new
socket.bind RCV_IP, PORT

if MODE == 'rp'
  # poke firewall
  socket.send 'poke', 0, QC_IP, PORT
end

loop do
  begin
    msg, sender_inet_addr = socket.recvfrom_nonblock(1500)
    seq = msg[0..19]
    stream = msg[20..23]
    leng = (msg.count 'a') + 24
    send_port = sender_inet_addr[1]
    ip1 = sender_inet_addr[2]
    ip2 = sender_inet_addr[3]
    logit "#001;Received UDP Telegram;#{seq.to_i};#{stream.to_i};#{leng};#{send_port};#{ip1};#{ip2}"
  rescue IO::WaitReadable
    IO.select([socket])
    retry
  rescue Exception => e
    logit "#002;Exception;#{e.inspect}"
  end
end
