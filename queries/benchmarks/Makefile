CC=clang++
OPT=-O3 -march=native
BMARGS=-isystem benchmark/include -Lbenchmark/build/src -lbenchmark -lpthread -lbenchmark_main
OTHER=-std=c++20

all:
	$(CC) bitcoin_expandhrp.cc $(OPT) $(BMARGS) $(OTHER) -o bmprog_bitcoin_expandhrp
	./bmprog_bitcoin_expandhrp --benchmark_format=csv > results.csv
	python google_benchmark_plot/plot.py -f results.csv --title "Bitcoin ExpandHRP" --ylabel "time (ns)" --output bitcoin_ExpandHRP.png
