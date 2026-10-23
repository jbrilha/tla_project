#!/usr/bin/gnuplot

R = "results/scale.csv"
V = "results-values/scale.csv"
P = "ChainReplicationScale.cfg"
S = "ChainReplicationScaleSym.cfg"
LP = "without symmetry"
LS = "with symmetry"

sel(c, k) = strcol(1) eq c && strcol(2) eq k && strcol(8) eq "ok"

set terminal pngcairo size 1200,750 enhanced font "Helvetica,18" background "#fcfcfb"
set datafile separator ","
system "mkdir -p charts"

set border 3 lc rgb "#c3c2b7" lw 1
set tics nomirror textcolor rgb "#52514e"
set grid ytics lc rgb "#e1e0d9" lw 1 dt 1
set xlabel textcolor rgb "#52514e"
set ylabel textcolor rgb "#52514e"
set title textcolor rgb "#0b0b0b"
set key top left textcolor rgb "#0b0b0b" samplen 2 spacing 1.3
set style line 1 lc rgb "#2a78d6" lw 2 pt 7 ps 1.4
set style line 2 lc rgb "#eb6834" lw 2 pt 5 ps 1.4
set offsets 0, 0, 0, 0

set logscale y
set format y "10^{%L}"
set yrange [10:1e9]
set ylabel "Distinct states (log scale)"

stats R every ::1 using (sel(P, "MaxUpdates") ? $3 : NaN) nooutput name "UP"
stats R every ::1 using (sel(S, "MaxUpdates") ? $3 : NaN) nooutput name "US"
set output "charts/states-updates.png"
set title "State space vs MaxUpdates (Values = 2, MaxQueries = 2, 120 s cap)"
set xlabel "MaxUpdates"
set xrange [0:19]
plot R every ::1 using (sel(P, "MaxUpdates") ? $3 : NaN):5 with linespoints ls 1 title LP, \
     R every ::1 using (sel(S, "MaxUpdates") ? $3 : NaN):5 with linespoints ls 2 title LS, \
     R every ::1 using (sel(P, "MaxUpdates") && $3 == UP_max ? $3 : NaN):5:(sprintf("%d updates", UP_max)) with labels right offset -1,1 tc rgb "#52514e" notitle, \
     R every ::1 using (sel(S, "MaxUpdates") && $3 == US_max ? $3 : NaN):5:(sprintf("%d updates", US_max)) with labels left offset 1,0 tc rgb "#52514e" notitle

set output "charts/states-queries.png"
set title "State space vs MaxQueries (Values = 2, MaxUpdates = 3, 120 s cap)"
set xlabel "MaxQueries"
set xrange [0:62]
plot R every ::1 using (sel(P, "MaxQueries") ? $3 : NaN):5 with linespoints ls 1 title LP, \
     R every ::1 using (sel(S, "MaxQueries") ? $3 : NaN):5 with linespoints ls 2 title LS

set output "charts/states-values.png"
set title "State space vs |Values| (MaxUpdates = 3, MaxQueries = 2, 120 s cap)"
set xlabel "Number of values"
set xrange [0:41]
plot V every ::1 using (sel(P, "Values") ? $3 : NaN):5 with linespoints ls 1 title LP, \
     R every ::1 using (sel(S, "Values") ? $3 : NaN):5 with linespoints ls 2 title LS

set key top right
set output "charts/time-values.png"
set title "Checking time vs |Values| (MaxUpdates = 3, MaxQueries = 2, 120 s cap)"
set ylabel "Seconds (log scale)"
set format y "%g"
set yrange [0.1:200]
set xrange [0:41]
plot V every ::1 using (sel(P, "Values") ? $3 : NaN):7 with linespoints ls 1 title LP, \
     R every ::1 using (sel(S, "Values") ? $3 : NaN):7 with linespoints ls 2 title LS
