#!/bin/bash

# $1: file with ra dec

timeout 6s vizquery \
	-mime=text \
	-source=I/317 \
	-out.max=10 \
	-out.add=_1 \
	-out.form=mini \
	-out=pmRA \
	-out=pmDE \
	-c.rm=0.05 \
	-list=$1 | \
    awk '($0!~/#/)' | tac | \
    awk '{if ($0 ~/---/) exit; else if (NF==6) printf "%d\t%.1f\t%.1f\n", $4, $5, $6}' | sort -g -k 1 > acq_propmotion.dat

timeout 6s vizquery \
	-mime=text \
	-source=I/337 \
	-out.max=10 \
	-out.add=_1 \
	-out.form=mini \
	-out="<Gmag>" \
	-c.rm=0.05 \
	-list=$1 | \
    awk '($0!~/#/)' | tac | \
    awk '{if ($0 ~/---/) exit; else if (NF==5) printf "%d\t%.1f\n", $4, $5}' | sort -g -k 1 > acq_magnitudes1.dat

# Filter the acq magnitudes:
magmin=`awk '{print $2}' acq_magnitudes1.dat | sort -g  | awk '(NR==1)'`
magmax=`awk '{print $2}' acq_magnitudes1.dat | sort -gr | awk '(NR==1)'`
echo "AcqStar MagRange: $magmin-$magmax" > acq_magnitudes.dat
\rm acq_magnitudes1.dat
