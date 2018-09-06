#!/bin/sh
# Detects which OS and if it is Linux then it will detect which Linux Distribution.
# Ubuntu and 64 bit support added by Bryan Miller August 24, 2010

OS=`uname -s`
REV=`uname -r`
MACH=`uname -m`

GetVersionFromFile()
{
    VERSION=`cat $1 | tr "\n" ' ' | sed s/.*VERSION.*=\ // `
}

if [ "${OS}" != "Linux" ] && [ "${OS}" != "Darwin" ]; then
    echo "UNSUPPORTED"
    exit
fi


if [ "${OS}" = "Linux" ] ; then
    KERNEL=`uname -r`
    if [ -f /etc/fedora-release ] ; then
	DIST='Fedora'
	PSEUDONAME=`cat /etc/redhat-release | sed s/.*\(// | sed s/\)//`
	REV=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`	    
    elif [ -f /etc/redhat-release ] ; then
	DIST='RedHat'
	PSEUDONAME=`cat /etc/redhat-release | sed s/.*\(// | sed s/\)//`
	REV=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`
    elif [ -f /etc/SuSE-release ] ; then
	DIST=`cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//`
	REV=`cat /etc/SuSE-release | tr "\n" ' ' | sed s/.*=\ //`
    elif [ -f /etc/mandrake-release ] ; then
	DIST='Mandrake'
	PSEUDONAME=`cat /etc/mandrake-release | sed s/.*\(// | sed s/\)//`
	REV=`cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//`
    elif [ -f /etc/lsb-release ] ; then
	DIST=`grep DISTRIB_ID /etc/lsb-release | sed s/.*=//`
	REV=`grep RELEASE /etc/lsb-release | sed s/.*=// | sed 's/\..*//'`
    elif [ -f /etc/debian_version ] ; then
	DIST="Debian `cat /etc/debian_version`"
	REV=""
    elif [ -f /etc/UnitedLinux-release ] ; then
	DIST="${DIST}[`cat /etc/UnitedLinux-release | tr "\n" ' ' | sed s/VERSION.*//`]"
    fi

    OSSTR="${OS} ${DIST} ${REV}(${PSEUDONAME} ${KERNEL} ${MACH})"
fi

if [ "${OS}" = "Darwin" ] ; then
    echo ${OS}
elif [ "${MACH}" = "x86_64" ] ; then
    version="${DIST}${REV}-${MACH}"
    version=`echo ${version} | sed 's/ //g'`
    echo $version
else
    version="${DIST}${REV}"
    version=`echo ${version} | sed 's/ //g'`
    echo $version
fi

if [ "$1" = "all" ] ; then
    echo "DIST = ${DIST}"
    echo "OSSTR = ${OSSTR}"
    echo "PSEUDONAME = ${PSEUDONAME}"
    echo "REV = ${REV}"
fi
