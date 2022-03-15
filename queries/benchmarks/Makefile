CC=clang++
OPT=-O3 -march=native
BMARGS=-isystem benchmark/include -Lbenchmark/build/src -lbenchmark -lpthread -lbenchmark_main
OTHER=-std=c++20

all:
	$(CC) bitcoin_expandhrp.cc $(OPT) $(BMARGS) $(OTHER) -o bitcoin_expandhrp
