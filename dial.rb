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

def dial_it port, interface
  l = ''
  TCPSocket.open('192.168.1.1', port) do |s|
    puts 'ATZ'
    s.print "ATZ\r\n"
    s.expect 'OK'
    puts 'ATQ0 V1 E1 S0=0'
    s.print "ATQ0 V1 E1 S0=0\r\n"
    s.expect 'OK'
    puts 'AT^NDISDUP=1,1,\"cmnet\"'
    s.puts "AT^NDISDUP=1,1,\"cmnet\"\r\n"
    s.expect '^NDISSTAT'
  end
  `udhcpc -i #{interface}`
end

dial_it(7003, 'wwan0')
dial_it(7005, 'wwan1')
