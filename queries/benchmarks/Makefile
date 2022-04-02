CC=clang++
OPT=-O3 -march=native
BMARGS=-isystem benchmark/include -Lbenchmark/build/src -lbenchmark -lpthread -lbenchmark_main -lpfm
OTHER=-std=c++20

bitcoin_ExpandHRP:
	$(CC) bitcoin_expandhrp.cc $(OPT) $(BMARGS) $(OTHER) -o bmprog_bitcoin_expandhrp
	./bmprog_bitcoin_expandhrp --benchmark_format=csv > results.csv
	python google_benchmark_plot/plot.py -f results.csv --title "Bitcoin ExpandHRP" --ylabel "time (ns)" --output bitcoin_ExpandHRP.png

bitcoin_SwapBase64:
	$(CC) bitcoin_SwapBase64.cc $(OPT) $(BMARGS) $(OTHER) -o bmprog_bitcoin_swapbase64
	./bmprog_bitcoin_swapbase64 --benchmark_format=csv > results.csv
	python google_benchmark_plot/plot.py -f results.csv --title "Bitcoin SwapBase64" --ylabel "time (ns)" --output bitcoin_SwapBase64.png

bitcoin_CSubNet:
	$(CC) bitcoin_CSubNet.cc $(OPT) $(BMARGS) $(OTHER) -o bmprog_bitcoin_csubnet

all: bitcoin_ExpandHRP bitcoin_SwapBase64 bitcoin_CSubNet

clean:
	rm -f *.png
	rm -f results.csv
	rm -f bmprog_bitcoin_expandhrp
	rm -f bmprog_bitcoin_swapbase64
	rm -f bmprog_bitcoin_csubnet
