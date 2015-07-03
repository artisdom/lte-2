#!/usr/bin/env ruby

require_relative 'lte_lib'

MODE = ARGV[0]
MB = ARGV[1]

raise ArgumentError.new('wrong mode') unless MODE == 'rp' or MODE == 'qc'

logit "#500;Start Bandwidth;"

if MODE == 'qc'
  loop do
    `iperf -u -s -p 9999`
  end
else
  raise ArgumentError.new('no bandwidth given') if MB.nil?
  loop do
    result = `iperf -c 119.254.210.30 -u -b #{MB}M -p 9999`
    logit "#501;Bandwidth result;#{result.lines.last}"
    sleep 1
  end
end
