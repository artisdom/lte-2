#!/usr/bin/env ruby

require 'json'
require 'fileutils'
require_relative 'lte_lib'

CONFIG = ARGV[0]
MODE = ARGV[1]
SERVER_IDX = ARGV[2]
SERVER_IP_1 = ARGV[3]
SERVER_IP_2 = ARGV[4]

raise ArgumentError.new('wrong mode') unless MODE == 'rp' or MODE == 'qc'

File.open("/tmp/lte_test.log", 'w') do |f|
  f.print ''
end

File.open("/tmp/testrun.pid", 'w') do |f|
  f.print Process.pid
end

File.open("/tmp/testrun.state", 'w') do |f| 
  f.print 'init'
end

s = File.read CONFIG
data = JSON.parse s

testid = data["TestID"]
bandwidth = data["bandwidth"].to_i

logit "#300;Start Testrun;#{testid}"

sender_port = 0
receiver_port = 0
if MODE == 'rp' 
  udp_sender = data["rp"]
  udp_receiver = data["qc"]
  sender_port = 8000
  receiver_port = 9000
else
  udp_sender = data["qc"]
  udp_receiver = data["rp"]
  sender_port = 9000
  receiver_port = 8000
end

s_ip = SERVER_IP_1
commands = []

# setup sender
stream = 0
udp_sender.each do |ud|
  if ud['modem'] == 'lte1'
    s_ip = SERVER_IP_1
  else
    s_ip = SERVER_IP_2
  end
  if (ud['modem'] == 'lte1' and SERVER_IDX == '1') or (ud['modem'] == 'lte2' and SERVER_IDX == '2') or MODE == 'rp'
    commands << "#{File.dirname(File.expand_path(__FILE__))}/sender.rb #{sender_port + stream} #{ud['pkgSize']} #{ud['pkgInt']} #{stream} #{MODE} #{s_ip}"
  end
  stream += 1
end

# setup receiver
offset = 0
udp_receiver.each do |ud|
  if ud['modem'] == 'lte1'
    s_ip = SERVER_IP_1
  else
    s_ip = SERVER_IP_2
  end
  if (ud['modem'] == 'lte1' and SERVER_IDX == '1') or (ud['modem'] == 'lte2' and SERVER_IDX == '2') or MODE == 'rp'
    commands << "#{File.dirname(File.expand_path(__FILE__))}/receiver.rb #{receiver_port + offset} #{MODE} #{s_ip}"
  end
  offset += 1
end

if MODE == 'rp'
  # setup gps logger
  commands << "#{File.dirname(File.expand_path(__FILE__))}/gps.rb"
end

if MODE == 'rp'
  # setup lte modem logger
  commands << "#{File.dirname(File.expand_path(__FILE__))}/modem.rb"
end

if bandwidth == 1
  # Bandwidth test
  commands << "#{File.dirname(File.expand_path(__FILE__))}/bandwidth.rb #{MODE}"
end

=begin
# we don't need the dial in, we dial up before the start
if MODE == 'rp'
  # dial up modem
  cmd = "#{File.dirname(File.expand_path(__FILE__))}/dial.rb"
  `#{cmd}`
  logit "#306;Dialup modem;#{cmd}"
end
=end

# start all proccesses
pids = []
commands.each do |cmd|
  # spawn all processes
  p = spawn(cmd)
  pids << p
  logit "#305;Spawn Process;#{p};#{cmd}"
end

trap('TERM') do
  logit '#301;Kill all processes'
  pids.each do |pro|
    logit "#304;Kill one process;#{pro}"
    Process.kill('TERM', pro)
  end
end

pids.each do |p|
  logit "#302;Waiting for Process;#{p}"
  Process.waitpid(p)
end

File.open("/tmp/testrun.state", 'w') do |f|
  f.print 'packing'
end

package = "/tmp/#{Time.now.strftime("%Y-%m-%d--%H-%M-%S.%L")}_#{testid}.#{MODE}.#{SERVER_IDX}.tar.gz"
logit "#303;Pack logresults;#{package}"
`tar czf "#{package}" /tmp/lte_test.log #{CONFIG}`

File.open("/tmp/testrun.state", 'w') do |f|
  f.print 'end'
end
