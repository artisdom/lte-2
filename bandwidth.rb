#!/usr/bin/env ruby

require_relative 'lte_lib'

MODE = ARGV[0]

raise ArgumentError.new('wrong mode') unless MODE == 'rp' or MODE == 'qc'

logit "#500;Start Bandwidth;#{BANDWIDTH}"

if MODE == 'qc'
  IO.popen('iperf -s -p 9999') do |p|
    puts p
  end
else
  IO.popen('iperf -c 119.254.210.30 -p 9999') do |p|
    puts p
  end
end
