#!/usr/bin/env ruby

require 'date'

folder = ARGV[0]

rp_file = "#{folder}/rp/lte_test.log"
qc1_file = "#{folder}/qc1/lte_test.log"
qc2_file = "#{folder}/qc2/lte_test.log"

$events = []
$global_latency = {'qc1' => {:min_ping_latency => 999999999999999, :min_udp_latency => 999999999999999},
                   'qc2' => {:min_ping_latency => 999999999999999, :min_udp_latency => 999999999999999}}

$current_cell = { 0 => {}, 1 => { area: nil, cell: nil }, 2 => { area: nil, cell: nil } }

def process_file(file, current_machine)
  File.open(file).each_line do |l|
    a = l.split(';')
    date = a[0]
    ts = DateTime.strptime(date, "[%Y-%m-%d--%H-%M-%S.%L]").strftime('%s%3N').to_i
    type = a[1]

    case type
    when '#001' # Received Package
      type = 'package'
      counter = a[3].to_i
      size = a[5].to_i
      src_ip = a[7]
      if src_ip == '119.254.210.30'
        src_machine = 'qc1'
      elsif src_ip == '119.254.100.105'
        src_machine = 'qc2'
      else
        src_machine = 'rp'
      end
      dest_machine = current_machine

      # search when the package was sent out
      idx = nil
      $events.each_with_index do |v,i|
        next unless v[:type] == type
        next unless v[:data][:counter] == counter  # same package sequence
        next unless v[:data][:size] == size        # same package size
        next unless v[:data][:dest_machine] == dest_machine  # the destionation should be our machine
        next unless v[:data][:src_machine] == src_machine    # the source should be the same
        idx = i
      end

      unless idx.nil?
        # the package was found, lets merge the data
        $events[idx][:data][:ts_end] = ts

        latency = $events[idx][:data][:ts_end] - $events[idx][:data][:ts_start]

        # determ machine identifier
        m = ''
        if dest_machine == 'qc1' or src_machine == 'qc1'
          m = 'qc1'
        elsif dest_machine == 'qc2' or src_machine == 'qc2'
          m = 'qc2'
        else
          raise 'this is a bug, package was neither send or received by a server'
        end
        if latency < $global_latency[m][:min_udp_latency].to_i
          $global_latency[m][:min_udp_latency] = latency
        end
      else
        # no package found, probably in a later file
        data = {counter: counter, size: size,
                src_machine: src_machine, dest_machine: current_machine,
                ts_end: ts}
        $events << { ts: ts, type: type, data: data }
      end
    when '#101' # Send a Package
      type = 'package'
      counter = a[3].to_i
      size = a[4].to_i
      dest_ip = a[5]
      if dest_ip == '119.254.210.30'
        dest_machine = 'qc1'
      elsif dest_ip == '119.254.100.105'
        dest_machine = 'qc2'
      else
        dest_machine = 'rp'
      end
      src_machine = current_machine

      # search when the package was received
      idx = nil
      $events.each_with_index do |v,i|
        next unless v[:type] == type
        next unless v[:data][:counter] == counter  # same package sequence
        next unless v[:data][:size] == size        # same package size
        next unless v[:data][:dest_machine] == dest_machine  # the destination is our destination
        next unless v[:data][:src_machine] == src_machine    # the source of the package is our machine
        idx = i
      end

      unless idx.nil?
        # the package was found, lets merge the data
        $events[idx][:data][:ts_start] = ts
        $events[idx][:ts] = ts
        latency = $events[idx][:data][:ts_end] - $events[idx][:data][:ts_start] 

        # determ machine identifier
        m = ''
        if dest_machine == 'qc1' or src_machine == 'qc1'
          m = 'qc1'
        elsif dest_machine == 'qc2' or src_machine == 'qc2'
          m = 'qc2'
        else
          raise 'this is a bug, package was neither send or received by a server'
        end
        if latency < $global_latency[m][:min_udp_latency].to_i
          $global_latency[m][:min_udp_latency] = latency
        end
      else
        # no package found, probably in a later file
        data = {counter: counter, size: size,
                dest_machine: dest_machine, src_machine: src_machine,
                ts_start: ts}
        $events << { ts: ts, type: type, data: data }
      end
    when '#601'
      destination = a[3]
      if destination == '119.254.210.30'
        destination = 'qc1'
      elsif destination == '119.254.100.105'
        destination = 'qc2'
      else
        raise "destination '#{destination}' undefined"
      end
      result = a[4]
      # we consider half of the rtt latency
      min_latency = result.split('/')[2].to_s.split[2].to_f / 2

      if min_latency > 0 and min_latency < $global_latency[destination][:min_ping_latency]
        # update the smallest latency to this destination
        $global_latency[destination][:min_ping_latency] = min_latency
      end
    when '#202'
      type = 'Speed'
      $events << { ts: ts, type: type, data: a[3].strip.to_f }
    when '#201'
      type = 'Coordinates'
      m = a[4].match /^(.*?)(..)\.(.*?)$/
      degree = m[1].to_i
      minute = "#{m[2]}.#{m[3]}".to_f
      hem = a[5]
      lat = degree + (minute / 60)
      lat = -lat if hem == 'S'

      m = a[6].match /^(.*?)(..)\.(.*?)$/
      degree = m[1].to_i
      minute = "#{m[2]}.#{m[3]}".to_f
      hem = a[7]
      long = degree + (minute / 60)
      long = -lat if hem == 'W'

      data = { lat: lat, long: long }
      $events << { ts: ts, type: type, data: data }
    when '#403'
      event = a[3].to_i
      if event == 1
        # Hand over is happening
        area_code = a[4]
        cell_code = a[5]
        modem_id = a[6].to_i
        if $current_cell[modem_id][:area] == area_code
          # area didn't change
          if $current_cell[modem_id][:cell] == cell_code
            # cell didn't change
          else
            type = 'Cell Handover'
            $current_cell[modem_id][:cell] = cell_code
          end
        else
          type = 'Area Handover'
          $current_cell[modem_id][:area] = area_code
          $current_cell[modem_id][:cell] = cell_code
        end
        $events << { ts: ts, type: type, data: 
                     { from: {area: a[4], cell: a[5]}, 
                       to: {area: area_code, cell: cell_code}
                     } 
                   }
      elsif event == 2
        # Regular Cell information
      else
        raise "Hand over event '#{event}' unknown"
      end
    else
      #raise "Type '#{type}' undefined..."
    end
  end
end

puts "[#{Time.now}] Process vehicle logfile"
process_file(rp_file, 'rp')

puts "[#{Time.now}] Process QC1 logfile"
process_file(qc1_file, 'qc1')

puts "[#{Time.now}] Process QC2 logfile"
process_file(qc2_file, 'qc2')

$events.each do |i|
  puts i.inspect
end

puts $global_latency.inspect
