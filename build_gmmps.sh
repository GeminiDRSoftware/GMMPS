#!/bin/bash

GMMPS=`pwd`

###############################################################################
# 0: Check OS
###############################################################################

OS=`scripts/discoverOS.sh`
if [ $OS = "UNSUPPORTED" ]; then
    echo " "
    echo "####################################################"
    echo "GMMPS Installer: ERROR: Unsupported operating system"
    echo "####################################################"
    echo " "
    exit
elif [ $OS = "Darwin" ]; then
    libsuffix=".dylib"
else
    libsuffix=".so"
fi

# Check that skycat is found
skycat=`which skycat`
test=`echo $skycat | awk '{if ($0=="" || $0 ~/:/) {print "bad"}}'`
if [ "${test}" = "bad" ]; then
    "ERROR: Could not find the skycat executable in your PATH variable."
    exit
fi

skycatpath=`scripts/locate_libs.sh $OS`

export LIBRARY_PATH=${skycatpath}

if [ ${skycatpath}_A != "_A" ]; then
    echo "Compatible skycat libraries found in: $skycatpath"
else
    echo "'locate' does not know the location of these skycat libraries:"
    echo "   libskycat3.1.2$libsuffix or libskycat3.1.3$libsuffix"
    echo "   libastrotcl2.1.0$libsuffix"
    echo "   libtclutil2.1.0$libsuffix"
    echo "   libcat4.1.0$libsuffix"
    read -p "Enter their path and press [ENTER]: " skycatpath
    if [ -e $skycatpath/libskycat3.1.2${libsuffix} ]; then
	c0=`./scripts/check_os_compatibility.sh $skycatpath/libskycat3.1.2${libsuffix}`
    else
	c0=`./scripts/check_os_compatibility.sh $skycatpath/libskycat3.1.3${libsuffix}`
    fi	
    c1=`./scripts/check_os_compatibility.sh $skycatpath/libastrotcl2.1.0${libsuffix}`
    c2=`./scripts/check_os_compatibility.sh $skycatpath/libtclutil2.1.0${libsuffix}`
    c3=`./scripts/check_os_compatibility.sh $skycatpath/libcat4.1.0${libsuffix}`
    if [ ${c0} != 1 ] || [ ${c1} != 1 ] || [ ${c2} != 1 ] || [ ${c3} != 1 ]; then
	echo "Not all libraries exist, or they are incompatible with $OS"
	exit
    else
	echo "Libraries checked OK."
	echo " "
    fi
fi

# Build startup script
${GMMPS}/scripts/build_gmmps ${GMMPS} $skycatpath $OS > ${GMMPS}/bin/gmmps
chmod a+x ${GMMPS}/bin/gmmps

echo
echo "########################################################################"
echo ""
echo "GMMPS modules verified. The GMMPS startup script is:"
echo "   ${GMMPS}/bin/gmmps"
echo ""
echo "Please add"
echo "   ${GMMPS}/bin/"
echo "to your PATH variable. Restart your shell and type 'gmmps' to run GMMPS."
echo ""
echo "########################################################################"
echo
