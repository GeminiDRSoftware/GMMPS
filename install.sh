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

cd ${GMMPS}
echo " "
test -e bin && \rm bin
test -e lib && \rm lib
test -d bin.$OS && rm -rf bin.$OS
test -d lib.$OS && rm -rf lib.$OS
mkdir -p bin.$OS lib.$OS
ln -sf bin.$OS bin
ln -sf lib.$OS lib

# Check that skycat is found
skycat=`which skycat`
test=`echo $skycat | awk '{if ($0=="" || $0 ~/:/) {print "bad"}}'`
if [ "${test}" = "bad" ]; then
    "ERROR: Could not find the skycat executable in your PATH variable."
    exit
fi


######################################################################
# 1: Check that essential skycat (v3.1.2 or 3.1.3 or 3.1.4) libs are available
# This check DOES NOT verify that ALL skycat dependencies are met.
######################################################################

skycatpath=`scripts/locate_libs.sh $OS`

export LIBRARY_PATH=${skycatpath}

if [ ${skycatpath}_A != "_A" ]; then
    echo "Compatible skycat libraries found in: $skycatpath"
else
    echo "'locate' does not know the location of these skycat libraries:"
    echo "   libskycat3.1.2$libsuffix or libskycat3.1.3$libsuffix or libskycat3.1.4$libsuffix"
    echo "   libastrotcl2.1.0$libsuffix"
    echo "   libtclutil2.1.0$libsuffix"
    echo "   libcat4.1.0$libsuffix"
    read -p "Enter their path and press [ENTER]: " skycatpath
    if [ -e $skycatpath/libskycat3.1.4${libsuffix} ]; then
    	skycatver="3.1.4"
    elif [ -e $skycatpath/libskycat3.1.3${libsuffix} ]; then
    	skycatver="3.1.3"
    elif [ -e $skycatpath/libskycat3.1.2${libsuffix} ]; then
    	skycatver="3.1.2"
	fi
	c0=`./scripts/check_os_compatibility.sh $skycatpath/libskycat${skycatver}${libsuffix}`
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

sleep 1

cd ${GMMPS}

###############################################################################
# 2: Install CFITSIO
###############################################################################

echo " "
echo "################################################################### "
echo "GMMPS Installer: Installing cfitsio ... "
echo "################################################################### "
echo " "

sleep 1

tar xvfz cfitsio3410.tar.gz
cd cfitsio

./configure | tee cfitsio.log
success=`grep "Congratulations, Makefile update was successful." cfitsio.log`
if [ "${success}_A" = "_A" ]; then
    echo " "
    echo "################################################################### "
    echo "GMMPS Installer: ERROR! cfitsio did not configure correctly ..."
    echo "################################################################### "
    echo " "
    exit
else
    echo " "
    echo "################################################################### "
    echo "GMMPS Installer: cfitsio configured fine... making"
    echo "################################################################### "
    echo " "
    sleep 1
fi

make
success=`test -f libcfitsio.a && echo success`
if [ "${success}_A" = "_A" ]; then
    echo " "
    echo "################################################################### "
    echo "GMMPS Installer: ERROR! libcfitsio.a was not created!"
    echo "################################################################### "
    echo " "
    exit
else
    echo " "
    echo "################################################################### "
    echo "GMMPS Installer: libcfitsio.a created ... installing"
    echo "################################################################### "
    echo " "
    sleep 1
fi

make install
rm cfitsio.log


###############################################################################
# 3: Install wcstools
###############################################################################

echo " "
echo "################################################################### "
echo "GMMPS Installer: Installing wcstools ... "
echo "################################################################### "
echo " "

sleep 1

cd ${GMMPS}/wcstools-3.9.2
make sky2xy xy2sky
mv bin/* ${GMMPS}/bin/
make clean

###############################################################################
# 4: Setting up the system
###############################################################################

echo " "
echo "################################################################### "
echo "GMMPS Installer: Building GMMPS ..."
echo "################################################################### "
echo " "

sleep 1

cd ${GMMPS}/cfitsio
cp libcfitsio.a ../lib/
cp include/*.h ../include/

if [ $OS = "Darwin" ]; then
    export DYLD_LIBRARY_PATH=${GMMPS}/lib.$OS:${skycatpath}
else
    export LD_LIBRARY_PATH=${GMMPS}/lib.$OS:${skycatpath}
fi

cd ${GMMPS}/src
make clean
make

# Check if all binaries are there and executable
cd ${GMMPS}/bin/

./gmCat2Fits        | grep USAGE > log
./gmMakeMasks       | grep USAGE >> log
./gmmps_fov         | grep USAGE >> log
./gmmps_sel         | grep USAGE >> log
./gmFits2Cat        | grep USAGE >> log
./calc_throughput   | grep USAGE >> log
./get_OT_posangle   | grep USAGE >> log
./gemwm             | grep USAGE >> log
./sky2xy 2>&1       | grep Usage >> log
./xy2sky 2>&1       | grep Usage >> log
nsuccess=`wc -l log | awk '{print $1}'`
if [ $nsuccess != 10 ]; then
    echo " "
    echo "######################################################################### "
    echo "GMMPS Installer: ERROR: Not all GMMPS executables were built correctly!"
    echo "                 Revise the output below for errors!"
    echo "######################################################################### "
    echo " "
    cat log
    \rm log
    exit
fi
\rm log

# Do the last installation step
cd ${GMMPS}

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
