set terminal png size 900, 300
set output 'speed.png'
set xdata time
set timefmt "%Y-%m-%d--%H:%M:%S"
set xtics format "%H:%M"
plot [:][:] '_tmp' using 1:2 title "km/h" with lines
