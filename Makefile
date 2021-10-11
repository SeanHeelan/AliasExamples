CXX=gcc
CXXFLAGS=-O3 -march=native -g -fPIC

all:
	$(CXX) $(CXXFLAGS) -o negative.o -c negative.cpp
	$(CXX) $(CXXFLAGS) -o positive.o -c positive.cpp
	$(CXX) -shared negative.o positive.o -o libaliaseg.so

clean:
	rm *.o
	rm libaliaseg.so
