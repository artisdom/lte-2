#!/usr/bin/env ruby

require 'date'

d = ''

fn = ARGV[0]
nn = ARGV[1]
File.open(fn) do |f|
  f.each_line do |l|
    next unless l =~ /\#501/
    a = l.split ';'
    date = a[0]
    date = date.match /^\[(....)\-(..)\-(..)\-\-(..)\-(..)\-(..)\.(...)/
    date = DateTime.new(date[1].to_i, date[2].to_i, date[3].to_i, date[4].to_i, date[5].to_i, date[6].to_i, date[7].to_i)
    result = a[3]
    result = result.split ' '
    result = result[12].to_s
    result = result.match /\((.*?)%\)/
    if result.nil?
      result = 0.0
    else
      result = result[1].to_f
    end
    d <<  "#{date.strftime("%Y-%m-%d--%H:%M:%S")} #{result}\n"
  end
end
File.open('_tmp', 'w') do |f|
  f.puts d
end

`gnuplot error.gp`
`mv error.png #{nn}.error.png`
