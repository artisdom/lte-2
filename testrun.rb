#!/usr/bin/env ruby

require 'json'

CONFIG = ARGV[0]
MODE = ARGV[1]

raise ArgumentError.new('wrong mode') unless MODE == 'rp' or MODE == 'qc'

s = File.read CONFIG
data = JSON.parse s

testid = data["TestID"]
bandwidth = data["bandwidth"]

sender_port = 0
receiver_port = 0
if MODE == 'rp' 
  udp_sender = data["rpUDP"]
  udp_receiver = data["qcUDP"]
  sender_port = 8000
  receiver_port = 9000
else
  udp_sender = data["qcUDP"]
  udp_receiver = data["rpUDP"]
  sender_port = 9000
  receiver_port = 8000
end

commands = []

# setup sender
stream = 0
udp_sender.each do |ud|
  commands << "./sender.rb #{sender_port + stream} #{ud['pkgSize']} #{ud['pkgInterval']} #{stream} #{MODE}"
  stream += 1
end

# setup receiver
offset = 0
udp_receiver.each do |ud|
  commands << "./receiver.rb #{receiver_port + offset} #{MODE}"
  offset += 1
end

# setup gps logger
commands << "./gps.rb /dev/ttyUSB0"

# start all proccesses
pids = []
commands.each do |cmd|
  pids << spawn(cmd)
  puts cmd
end

trap('INT') do
  puts 'kill all processes'
  pids.each do |pro|
    Process.kill('QUIT', pids)
  end
end
