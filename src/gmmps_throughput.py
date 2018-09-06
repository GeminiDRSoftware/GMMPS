#!/usr/bin/env python

import sys
from numpy import array
import matplotlib.pyplot as plt
import matplotlib.lines as lines

wavemin=float(sys.argv[1])
wavemax=float(sys.argv[2])
title=sys.argv[3]

cwlfloat = (wavemax + wavemin) / 2.
cwl = int(round(cwlfloat))

# read the data
data=[]; #str = []
file = open(".total_system_throughput.dat")
for line in file.readlines():
    members = line.split()
    data.append(array([float(i) for i in members[0:]]))
data = array(data)

file.close()

wavelength = data[:,0]
throughput = data[:,1]

maxthroughput = max(throughput)

# padding 50nm to the left and right. However, the space between
# min and max throughput wavelengths must at least be 50% of the plot 
# width, so we decreasethe padding accordingly (narrow-band filters)
pad = 50.
width = wavemax - wavemin
if width/(2.*pad) < 1. :
    pad = width / 2.

xrange=[wavemin-pad,wavemax+pad]
yrange=[0,1.02]

oldthroughput = throughput
throughput = throughput / maxthroughput

i=0
for l in wavelength:
    if l == cwl:
        cwl_throughput = throughput[i]
        break
    i=i+1

# the CWL line
vertx_cwl = [cwlfloat,cwlfloat]
verty_cwl = [0,cwl_throughput]

l1x = [wavemin, wavemin]
l1y = [0,1]
l2x = [wavemax, wavemax]
l2y = [0,1]

fig = plt.figure()

rect = 0,1,0,1
ax1 = fig.add_subplot(1,1,1)
# the mode is stored in the second column
ax1.plot(wavelength, throughput, '-', linewidth=2)
ax1.plot(wavelength, oldthroughput, '-', linewidth=1, color='#aaaaaa')
ax1.set_xlabel('Wavelength [nm]', fontsize=20)
ax1.set_ylabel('Normalized transmission', fontsize=20)
ax1.set_title(title, fontsize=20)
ax1.set_xlim(xrange)
ax1.set_ylim(yrange)
ax1.tick_params(axis='both', which='major', labelsize=20)
linecwl = lines.Line2D(vertx_cwl, verty_cwl, color='#bb0000', linestyle='--', linewidth=2)
ax1.add_line(linecwl)
l1 = lines.Line2D(l1x,l1y, color='green', linestyle='--', linewidth=2)
ax1.add_line(l1)
l2 = lines.Line2D(l2x,l2y, color='green', linestyle='--', linewidth=2)
ax1.add_line(l2)
offset = width / 20.
ax1.annotate('CWL'+'='+str(cwl), xy=(cwlfloat,0.1), xytext=(cwlfloat+offset,0.4), fontsize=20, rotation=90, color='#bb0000')

plt.savefig('.throughput.png', bbox_inches='tight', dpi=60)
