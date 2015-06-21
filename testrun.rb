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

FileUtils::rm_rf('/tmp/lte_test.log')

s = File.read CONFIG
data = JSON.parse s

testid = data["TestID"]
bandwidth = data["bandwidth"]

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
    commands << "#{File.dirname(File.expand_path(__FILE__))}/sender.rb #{sender_port + stream} #{ud['pkgSize']} #{ud['pkgInterval']} #{stream} #{MODE} #{s_ip}"
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

if MODE == 'rp'
  # dial up modem
  cmd = "#{File.dirname(File.expand_path(__FILE__))}/dial.rb"
  `#{cmd}`
  logit "#306;Dialup modem;#{cmd}"
end

# start all proccesses
pids = []
commands.each do |cmd|
  # spawn all processes
  p = spawn(cmd)
  pids << p
  logit "#305;Spawn Process;#{p};#{cmd}"
end

trap('INT') do
  logit '#301;Kill all processes'
  pids.each do |pro|
    logit "#304;Kill one process;#{pro}"
    Process.kill('QUIT', pro)
  end
end

pids.each do |p|
  logit "#302;Waiting for Process;#{p}"
  Process.waitpid(p)
end

package = "/tmp/#{Time.now.strftime("%Y-%m-%d--%H-%M-%S.%L")}_#{testid}.tar"
logit "#303;Pack logresults;#{package}"
`tar cf "#{package}" /tmp/lte_test.log #{CONFIG}`
