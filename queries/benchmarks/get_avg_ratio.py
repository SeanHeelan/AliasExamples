#!/usr/bin/env python3

import sys

infile = sys.argv[1]
with open(infile, 'r') as fd:
    data = fd.readlines() 

runtimes = []
for line in data:
    if line.startswith("name"):
        continue
    spl = line.split(',')
    rt = float(spl[2])
    runtimes.append(rt)

ratios = []
half = int(len(runtimes)/2)
for idx in range(half):
    rt0 = runtimes[idx]
    rt1 = runtimes[idx + half]

    ratios.append(rt0/rt1)

print(sum(ratios)/len(ratios))