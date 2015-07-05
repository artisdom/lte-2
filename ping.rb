#!/usr/bin/env ruby

require_relative 'lte_lib'

logit "#600;Start Ping Daemon"

def p(ip)
  result = `ping -w1 -c3 -s4 #{ip}|grep "round-trip"`
  logit "#601;Ping Result;#{ip};#{result.strip}"
end
loop do
  p(QC_IP_1)
  p(QC_IP_2)
  sleep 1
end
