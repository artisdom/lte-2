set terminal png size 900, 300
set output 'signal.png'
set xdata time
set timefmt "%Y-%m-%d--%H:%M:%S"
set xtics format "%H:%M"
plot [:][:] '_tmp' using 1:2 title "RSSI (dBm)" with lines, \
            '_tmp' using 1:3 title "RSRP (dBm)" with lines, \
            '_tmp' using 1:4 title "SINR (dB)" with lines, \
            '_tmp' using 1:5 title "RSRQ (dB)" with lines
