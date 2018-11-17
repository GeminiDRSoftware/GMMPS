#!/bin/bash

# $1: OS

##################################################
# Do we have 'locate'? If not, leave
##################################################
test=`which locate | awk '($0!="" && $0!~/Command not found/ && $0!~/no locate in/)'`
if [ "${test}"_A = "_A" ]; then
    exit
fi

#########################
# processing arguments
#########################
OS=$1

if [ $OS = "Darwin" ]; then
    libsuffix=".dylib"
    mdfind -name libskycat3.1.4.dylib > libsfound_$$
    mdfind -name libskycat3.1.3.dylib > libsfound_$$
    mdfind -name libskycat3.1.2.dylib >> libsfound_$$
else
    libsuffix=".so"
    locate -e -b '\libskycat3.1.4.so' > libsfound_$$
    locate -e -b '\libskycat3.1.3.so' > libsfound_$$
    locate -e -b '\libskycat3.1.2.so' >> libsfound_$$
fi


############################################
# How many libs were found? Leave if none
############################################
numlibs=`wc libsfound_$$ | awk '{print $1}'`
if [ $numlibs = 0 ]; then
    exit
fi

# Check system-wide libs first (reorder the output of 'locate')
awk '($0  ~ /\/usr/)' libsfound_$$ > libsfound_usr_$$
awk '($0 !~ /\/usr/)' libsfound_$$ > libsfound_else_$$
cat libsfound_usr_$$ libsfound_else_$$ > libsfound_$$
rm libsfound_usr_$$ libsfound_else_$$

#########################################################
# loop over the list and find a directory that
# also contains relevant additional libraries
#########################################################
exec < libsfound_$$
while read lib
do
    path=`dirname ${lib}`
    # Are this and the other required libs compatible with this OS?
    c0=`./scripts/check_os_compatibility.sh $lib`
    c1=`./scripts/check_os_compatibility.sh $path/libastrotcl2.1.0${libsuffix}`
    c2=`./scripts/check_os_compatibility.sh $path/libtclutil2.1.0${libsuffix}`
    c3=`./scripts/check_os_compatibility.sh $path/libcat4.1.0${libsuffix}`
    # If successful, return the library path and exit
    if [ ${c0} == 1 ] && [ ${c1} == 1 ] && [ ${c2} == 1 ] && [ ${c3} == 1 ]; then
	echo $path
	rm libsfound_$$
	exit
    fi
done

rm libsfound_$$
