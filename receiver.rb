#!/usr/bin/env ruby

require 'socket'
require_relative 'lte_lib'

PORT = ARGV[0]
MODE = ARGV[1]
SERVER_IP = ARGV[2]

a=0
[ PORT, MODE ].each do |p|
  raise ArgumentError.new "#{a} argument missing... (PORT, MODE, SERVER_IP)" if p.nil?
  a+=1
end
raise ArgumentError.new('wrong mode') unless MODE == 'rp' or MODE == 'qc'

logit "#000;Start Receiver;#{PORT}"

socket = UDPSocket.new
begin
  socket.bind '0.0.0.0', PORT
rescue Errno::EADDRINUSE
  logit '#005;Address already in use'
  exit
end

if MODE == 'rp'
  logit "#003;Poke firewall"
  socket.send 'poke', 0, SERVER_IP, PORT
end

last_poke = Time.now
loop do
  # every minute poke the firewall
  if ((Time.now - last_poke) > 60) and MODE == 'rp'
    logit "#004;Re-Poke firewall"
    socket.send 'poke', 0, SERVER_IP, PORT
    last_poke = Time.now
  end

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
