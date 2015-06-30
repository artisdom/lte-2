#!/usr/bin/env ruby

log = ARGV[0]

coord = ''
cell_towers = {}
current_cell_tower = ''
File.open(log).each_line do |l|
  if l =~ /\$GPRMC/
    a = l.split ','

    m = a[3].match /^(.*?)(..)\.(.*?)$/
    degree = m[1].to_i
    minute = "#{m[2]}.#{m[3]}".to_f
    hem = a[4]
    lat = degree + (minute / 60)
    lat = -lat if hem == 'S'

    m = a[5].match /^(.*?)(..)\.(.*?)$/
    degree = m[1].to_i
    minute = "#{m[2]}.#{m[3]}".to_f
    hem = a[6]
    long = degree + (minute / 60)
    long = -long if hem == 'W'

    coord = "#{long},#{lat}"
  elsif l =~ /#402/
    # modem signal
    next if current_cell_tower == ''
    signal = l.split(';')[-2].to_i
    if cell_towers.has_key? current_cell_tower
      if signal > cell_towers[current_cell_tower][:signal]
        cell_towers[current_cell_tower][:signal] = signal
        cell_towers[current_cell_tower][:coord] = coord
      end
    else
      cell_towers[current_cell_tower] = {}
      cell_towers[current_cell_tower][:signal] = signal
      cell_towers[current_cell_tower][:coord] = coord
    end
  elsif l =~ /#403/
    # cell tower
    ct = l.split(';').last.gsub('"', '').strip
    current_cell_tower = ct
  end
end

cell_towers.each_pair do |k,v|
  File.open("#{k}.kml", 'w').puts <<KML
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Placemark>
    <name>#{k}</name>
    <description>Cell Tower #{k} with best signal value #{v[:signal]}</description>
    <Point>
      <coordinates>#{v[:coord]},500</coordinates>
    </Point>
  </Placemark>
</kml>
KML
end
