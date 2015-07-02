#!/usr/bin/env ruby

require '/Users/dabo/Documents/plot.rb/plot.rb'

d = ''

fn = ARGV[0]
nn = ARGV[1]
last_speed = 0
datapoints = []
File.open(fn) do |f|
  f.each_line do |l|
    next unless l =~ /\#501/ or l =~ /\#202/
    a = l.split ';'
    if l =~ /\#202/
      # this line shows the speed
      last_speed = a[3].to_f
    else
      result = a[3]
      result = result.split ' '
      size = result[7]
      result = result[6].to_f
      if size == 'Kbits/sec'
        result = result / 1024
      end
      datapoints << [result, last_speed]
    end
  end
end

puts plot_it(datapoints, 'Bandwidth (Mbits/sec)', 'speed (km/h)')
