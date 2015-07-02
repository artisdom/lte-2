#!/usr/bin/env ruby

require 'timeout'
require 'expect'
require 'socket'
require_relative 'lte_lib'

logit "#400;Start LTE Modem Logger"

l = ''
TCPSocket.open('192.168.1.1', 7003) do |s|
  # activate cell tower info
  s.print "AT+CREG=2\r\n"
  loop do
    begin
       begin
         c = s.read_nonblock(1)
       rescue
         retry
       end
       if c == "\n"
         unless l == ''
           case l
           when /\^RSSI/
             a = l.split ':'
             logit "#401;Modem RSSI;#{a[1]}"
           when /\^LTERSRP/
             a = l.split ':'
             a = a[1].split ','
             logit "#402;Modem Signal;#{a[0]};#{a[1]}"
             s.print "AT+CREG?\r\n"
           when /^\+CREG/
             a = l.split ','
             logit "#403;Modem Cell Tower;#{a[2]};#{a[3]}"
	     s.print "AT^HCSQ?\r\n"
	   when /^\^HCSQ:/
	     a = l
	     logit "#404;Modem Signal Details;#{a}"
#	     r = `ping -c1 #{QC_IP_1} 2>&1`
#	     if r =~ /Network is unreachable/
#	       Timeout::timeout(5) {
#	         # dial up
#	         s.print "ATZ\r\n"
#	         s.expect 'OK'
#	         s.print "ATQ0 V1 E1 S0=0\r\n"
#	         s.expect 'OK'
#	         s.puts "AT^NDISDUP=1,1,\"cmnet\"\r\n"
#	         s.expect '^NDISSTAT'
#	         logit "#405;Modem Dialup"
#	       }
#	       `udhcpc -i wwan0`
#	     else
#	       # connection should be available   
#	     end
           end
         end
         l = ''
       else
         l << c
       end
    rescue 
    end 
  end
end
