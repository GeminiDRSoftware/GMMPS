#!/bin/bash

# $1: input file
# $2: pixel scale
# $3: lambda_min [angstrom]
# $4: lambda_max [angstrom]
# $5: instrument
# $6: correction factor (for 1x1 binning)
# $7: xoffset (correct or wrong pseudo image geometry)
# $8: xoffset (correct or wrong pseudo image geometry)

# the input file contains
# "ID" "RA" "DEC" "x_ccd" "y_ccd" "slitpos_x" "slitpos_y"
# "slitsize_x" "slitsize_y" "slittilt" "MAG" "priority"
# "slittype" "redshift"

# need only some of those, in a specific order for gemwm

ps=$2
lmin=$3
lmax=$4
inst=$5
cf=$6
xo=$7
yo=$8

rm -rf gemwm.input

if [ "${inst}" == "GMOS-N" ] || [ "${inst}" == "GMOS-S" ]; then
    awk '{
         print "box", ($4+$6/'$ps')*'$cf'+'$xo', ($5+$7/'$ps')*'$cf'+'$yo', 0, '$lmin', '$lmax', "0 0 0 0 0 0 0"}' $1 > gemwm.input
else
    awk '{
         print "box", ($5+$7/'$ps')*'$cf'+'$yo', ($4+$6/'$ps')*'$cf'+'$xo', 0, '$lmin', '$lmax', "0 0 0 0 0 0 0"}' $1 > gemwm.input
fi
