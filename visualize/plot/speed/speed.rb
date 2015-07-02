#!/usr/bin/env ruby

require 'date'

d = ''

fn = ARGV[0]
nn = ARGV[1]
File.open(fn) do |f|
  f.each_line do |l|
    next unless l =~ /\#202/
    a = l.split ';'
    date = a[0]
    date = date.match /^\[(....)\-(..)\-(..)\-\-(..)\-(..)\-(..)\.(...)/
    date = DateTime.new(date[1].to_i, date[2].to_i, date[3].to_i, date[4].to_i, date[5].to_i, date[6].to_i, date[7].to_i)
    speed = a[3]
    d <<  "#{date.strftime("%Y-%m-%d--%H:%M:%S")} #{speed}"
  end
end

File.open('_tmp', 'w') do |f|
  f.puts d
end

`gnuplot speed.gp`
`mv speed.png #{nn}.speed.png`
