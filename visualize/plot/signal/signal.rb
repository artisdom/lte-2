#!/usr/bin/env ruby

require 'date'

d = ''

fn = ARGV[0]
nn = ARGV[1]
File.open(fn) do |f|
  f.each_line do |l|
    next unless l =~ /\#404/
    a = l.split ';'
    date = a[0]
    date = date.match /^\[(....)\-(..)\-(..)\-\-(..)\-(..)\-(..)\.(...)/
    date = DateTime.new(date[1].to_i, date[2].to_i, date[3].to_i, date[4].to_i, date[5].to_i, date[6].to_i, date[7].to_i)
    list = a[3].split ','
    rssi = -120 + list[1].to_i
    rsrp = -140 + list[2].to_i
    sinr = -20 + (list[3].to_i * 0.2)
    rsrq = -19.5 + (list[4].to_i * 0.5)
    d <<  "#{date.strftime("%Y-%m-%d--%H:%M:%S")} #{rssi} #{rsrp} #{sinr.to_i} #{rsrq.to_i}\n"
  end
end
puts d
File.open('_tmp', 'w') do |f|
  f.puts d
end

`gnuplot signal.gp`
`mv signal.png #{nn}.signal.png`
