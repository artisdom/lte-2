#!/usr/bin/env ruby

require 'json'
require 'fileutils'
require_relative 'lte_lib'

CONFIG = ARGV[0]
MODE = ARGV[1]

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
  commands << "#{File.dirname(File.expand_path(__FILE__))}/sender.rb #{sender_port + stream} #{ud['pkgSize']} #{ud['pkgInterval']} #{stream} #{MODE}"
  stream += 1
end

# setup receiver
offset = 0
udp_receiver.each do |ud|
  commands << "#{File.dirname(File.expand_path(__FILE__))}/receiver.rb #{receiver_port + offset} #{MODE}"
  offset += 1
end

if MODE == 'rp'
  # setup gps logger
  commands << "#{File.dirname(File.expand_path(__FILE__))}/gps.rb /dev/ttyUSB0"
end

if MODE == 'rp'
  # setup lte modem logger
  commands << "#{File.dirname(File.expand_path(__FILE__))}/modem.rb /dev/ttyUSB0"
end

# start all proccesses
pids = []
commands.each do |cmd|
  pids << spawn(cmd)
  puts cmd
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

package = "/tmp/#{Time.now.strftime("%Y-%m-%d--%H-%M-%S.%L")}.tar"
logit "#303;Pack logresults;#{package}"
`tar cf #{package} /tmp/lte_test.log #{CONFIG}`
