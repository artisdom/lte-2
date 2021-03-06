require 'timeout'
require 'expect'
require 'socket'

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

def dial_it port, interface, server
  l = ''
  ips = ''
  TCPSocket.open('192.168.1.1', port) do |s|
    begin
      Timeout::timeout(5) do
        puts 'AT^SYSCFGEX="03",3FFFFFFF,1,2,A000000000,,'
        s.print "AT^SYSCFGEX=\"03\",3FFFFFFF,1,2,A000000000,,\r\n"
        s.expect 'OK'
        puts 'ATZ'
        s.print "ATZ\r\n"
        s.expect 'OK'
        puts 'ATQ0 V1 E1 S0=0'
        s.print "ATQ0 V1 E1 S0=0\r\n"
        s.expect 'OK'
        puts 'AT^NDISDUP=1,1,\"cmnet\"'
        s.puts "AT^NDISDUP=1,1,\"cmnet\"\r\n"
        s.expect 'NDISDUP'
        s.puts "AT^DHCP?\r\n"
        s.expect '^DHCP: '
        ips = read_it(s)
        ips = ips.split(',')
        ips = ips.map {|i| [i].pack('H*').unpack('C*').reverse.join('.')}
        puts ips.inspect
	`udhcpc -i #{interface}`
        `ip route del default`
        `ip route add #{server} via #{ips[2]} dev #{interface}`
        # time server
	`ip route add 202.112.10.36 via #{ips[2]} dev #{interface}`
	puts 'OK'
      end
    rescue Errno::EPIPE
      puts 'KO: Someone is using the modem'
    rescue Timeout::Error
      puts 'KO'
    end
  end
end

dial_it(7003, 'wwan0', '119.254.210.30')
dial_it(7005, 'wwan1', '119.254.100.105')
