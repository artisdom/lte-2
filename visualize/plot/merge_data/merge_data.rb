#!/usr/bin/env ruby

require 'date'

SEND_CODE = '#101'
RCV_CODE = '#001'

folder = ARGV[0]

rp_file = "#{folder}/rp/lte_test.log"
qc1_file = "#{folder}/qc1/lte_test.log"
qc2_file = "#{folder}/qc2/lte_test.log"

rp_qc_pkg = []
qc1_rp_pkg = []
qc2_rp_pkg = []

puts 'read in mobile client data'
File.open(rp_file).each_line do |l|
  next unless l =~ /#{SEND_CODE}/ or l =~ /#{RCV_CODE}/
  a = l.split(';')
  date = a[0]
  date = DateTime.strptime(date, "[%Y-%m-%d--%H-%M-%S.%L]").strftime('%s%3N').to_i
  dp = {} 
  dp[:sendDT] = 0
  dp[:rcvDT] = 0
  dp[:pkgID] = a[3].to_i

  case l
  when /#{SEND_CODE}/
    dp[:sendDT] = date
    dp[:size] = a[4].to_i
    dp[:dest] = a[5]
    rp_qc_pkg << dp
  when /#{RCV_CODE}/
    dp[:rcvDT] = date
    dp[:size] = a[5].to_i
    dp[:src] = a[7]
   
    if dp[:src] == '119.254.210.30'
      qc1_rp_pkg << dp
    elsif dp[:src] == '119.254.100.105'
      qc2_rp_pkg << dp
    else
      raise 'wrong IP, this wrong, fix your code!'
    end
  end
end

puts 'merge server 1 data'
File.open(qc1_file).each_line do |l|
  a = l.split(';')
  date = a[0]
  date = DateTime.strptime(date, "[%Y-%m-%d--%H-%M-%S.%L]").strftime('%s%3N').to_i
  pkgID = a[3].to_i
  case l
  when /#{SEND_CODE}/
    f = false
    pkgSize = a[4].to_i
    qc1_rp_pkg.each do |e|
      if e[:pkgID] == pkgID and e[:size] == pkgSize and e[:src] == '119.254.210.30'
        e[:sendDT] = date
        f = true
        break
      end
    end
    unless f
      qc1_rp_pkg << {:pkgID => pkgID, :sendDT => date, :rcvDT => 0}
    end
  when /#{RCV_CODE}/
    f = false
    pkgSize = a[5].to_i
    rp_qc_pkg.each do |e|
      if e[:pkgID] == pkgID and e[:size] == pkgSize and e[:dest] == '119.254.210.30'
        e[:rcvDT] = date
        f = true
        break
      end
    end
    unless f
      rp_qc_pkg << {:pkgID => pkgID, :sendDT => 0, :rcvDT => date}
    end
  end
end

# calculate lowest RTT based on ping daemon
lowest_rtt = 999999
`cat #{rp_file}|grep Ping|cut -d '/' -f 3|cut -d ' ' -f 3`.each_line do |l|
  d = l.to_f
  next if d == 0
  lowest_rtt = d if d < lowest_rtt
end
lowest_rtt = lowest_rtt.to_i

# calculate lowest timedifference to zero-out timestamp
lowest_value = 999999
rp_qc_pkg.each do |e|
  if e[:rcvDT] != 0 and e[:sendDT] != 0
    latency = e[:rcvDT] - e[:sendDT]
    lowest_value = latency if latency < lowest_value
  end
end

# spitting out packages from RP -> QC
rp_qc_pkg.each do |e|
  if e[:rcvDT] != 0 and e[:sendDT] != 0
    latency = (e[:rcvDT] - e[:sendDT]) - lowest_value + (lowest_rtt/2)
    #puts "#{e[:pkgID]}\t#{(latency)}"
  end
end

# need to get checked
qc1_rp_pkg.each do |e|
  if e[:rcvDT] != 0 and e[:sendDT] != 0
    latency = (e[:rcvDT] - e[:sendDT]) + lowest_value + (lowest_rtt/2)
    puts "#{e[:pkgID]}\t#{(latency)}"
  end
end
