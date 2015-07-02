#!/usr/bin/env ruby

require 'timeout'
require 'expect'
require 'socket'
require_relative 'lte_lib'

server = ''
interface = ''
port = 7003
modem = ARGV[0]
if modem == '1' or modem == '2'
  modem = modem.to_i
  case modem
  when 1
    port = 7003
    server = QC_IP_1
    interface = 'wwan0'
  when 2
    port = 7005
    server = QC_IP_2
    interface = 'wwan1'
  end
  logit "#400;Start LTE Modem Logger;#{modem};#{port}"
else
  logit "#405;Could not start LTE Modem Logger;#{modem}"
  raise ArgumentError.new('wrong modem number (1 or 2')
end

def at_log s, cmd, result, log_id, log_message, m
  s.print "#{cmd}\r\n"
  s.expect result
  log = s.gets.strip
  logit "##{log_id};#{log_message};#{log};#{m};"
  log
end

def read_it(s)
  _l = ''
  loop do
    begin
      t =  s.read_nonblock(1)
      if t == "\n"
        break
      else
        _l << t
      end
    rescue Errno::EAGAIN
    end
  end
  _l
end

TCPSocket.open('192.168.1.1', port) do |s|
  s.print "AT+CREG=2\r\n"
  loop do
    begin
      at_log s, "AT+CREG?", '+CREG: ', 403, 'Modem Cell Tower', modem
      at_log s, "AT^HCSQ?", '^HCSQ:', 404, 'Modem Signal Details', modem
      at_log s, "AT+COPS?", '+COPS: ', 407, 'Modem Operator Details', modem
      result = at_log s, "AT^NDISSTATQRY?", '^NDISSTATQRY: ', 408, 'Modem Connection State', modem
      begin
        result = result.split ','
        if result[0] == '0'
          logit "#410;Modem Disconnected, redialing now"
          s.print "AT^SYSCFGEX=\"03\",3FFFFFFF,1,2,A000000000,,\r\n"
          s.expect 'OK'
          s.print "ATZ\r\n"
          s.expect 'OK'
          s.print "ATQ0 V1 E1 S0=0\r\n"
          s.expect 'OK'
          s.puts "AT^NDISDUP=1,1,\"cmnet\"\r\n"
          s.expect 'NDISDUP'
          s.puts "AT^DHCP?\r\n"
          s.expect '^DHCP: '
          ips = read_it(s)
          ips = ips.split(',')
          ips = ips.map {|i| [i].pack('H*').unpack('C*').reverse.join('.')}
          `udhcpc -i #{interface}`
          `ip route del default`
          `ip route add #{server} via #{ips[2]} dev #{interface}`
        end
      rescue Exception => e
        logit "#409;Modem Logger Exception;#{e.inspect}"
      end
      sleep 2
    rescue Exception => e
      logit "#406;Modem Logger Exception;#{e.inspect}"
      sleep 1
    end
  end
end

=begin
l = ''
TCPSocket.open('192.168.1.1', port) do |s|
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
             logit "#401;Modem RSSI;#{a[1].strip};#{modem};"
           when /\^LTERSRP/
             a = l.split ':'
             a = a[1].split ','
             logit "#402;Modem Signal;#{a[0].strip};#{a[1].strip};#{modem};"
             s.print "AT+CREG?\r\n"
           when /^\+CREG/
             a = l.split ','
             logit "#403;Modem Cell Tower;#{a[2].strip};#{a[3].strip};#{modem};"
	     s.print "AT^HCSQ?\r\n"
	   when /^\^HCSQ:/
	     a = l
	     logit "#404;Modem Signal Details;#{a.strip};#{modem};"
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
=end
