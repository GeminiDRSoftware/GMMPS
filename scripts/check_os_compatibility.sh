#!/bin/bash

# This script does a basic check to see whether a library is compatible
# with your operating system. Better: "is definitely not incompatible".

# $1: filename

testfile=$1

# Leave if no file was specified, or if it does not exist
if [ ! -e ${testfile} ]; then
    echo 0
    exit
fi

arch=`uname`
archbit=`uname -m`

if [ "${archbit}" = "x86_64" ]; then
    archbit=64
elif [ "${archbit}" = "i686" ] || [ "${archbit}" = "i386" ]; then
    archbit=32
else
    # Could not determine the bittype of this architecture
    echo 0
    exit
fi

# Get some info about this file
filetype=`file -b ${testfile}`

# Was it built on a matching architecture (Linux or Darwin?)
buildtype=`echo $filetype | awk '{if ($1=="ELF") print "Linux"; if ($1=="Mach-O") print "Darwin"}'`
buildbit=`echo $filetype | awk '{if ($2=="64-bit") print "64"; if ($2=="32-bit") print "32"}'`

# Exit with 1 if the testfile was built on the current architecture
if [ "${buildtype}" == "${arch}" ] && [ "${buildbit}" == "${archbit}" ]; then
    echo 1
else
    echo 0
fi

exit
