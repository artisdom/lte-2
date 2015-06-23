#!/usr/bin/env ruby

log = ARGV[0]

coords = ''
File.open(log).each_line do |l|
  next unless l =~ /\$GPRMC/
  a = l.split ','

  m = a[3].match /^(.*?)(..)\.(.*?)$/
  degree = m[1].to_i
  minute = "#{m[2]}.#{m[3]}".to_f
  hem = a[4]
  lat = degree + (minute / 60)

  m = a[5].match /^(.*?)(..)\.(.*?)$/
  degree = m[1].to_i
  minute = "#{m[2]}.#{m[3]}".to_f
  hem = a[6]
  long = degree + (minute / 60)

  coords << "#{long},#{lat},100\n"
end

puts <<KML
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Paths</name>
    <description>Examples of paths. Note that the tessellate tag is by default
      set to 0. If you want to create tessellated lines, they must be authored
      (or edited) directly in KML.</description>
    <Style id="yellowLineGreenPoly">
      <LineStyle>
        <color>7f00ffff</color>
        <width>4</width>
      </LineStyle>
      <PolyStyle>
        <color>7f00ff00</color>
      </PolyStyle>
    </Style>
    <Placemark>
      <name>Absolute Extruded</name>
      <description>Transparent green wall with yellow outlines</description>
      <styleUrl>#yellowLineGreenPoly</styleUrl>
      <LineString>
        <extrude>1</extrude>
        <tessellate>1</tessellate>
        <altitudeMode>absolute</altitudeMode>
        <coordinates>#{coords}
        </coordinates>
      </LineString>
    </Placemark>
  </Document>
</kml>
KML
