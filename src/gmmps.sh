#!/bin/sh 
if [ "`uname`" = "Linux" ]; then enable -n echo; fi
#***********************************************************************
#****     D A O   I N S T R U M E N T A T I O N   G R O U P        *****
#
# (c) <2000>				(c) <2000>
# National Research Council		Conseil national de recherches
# Ottawa, Canada, K1A 0R6 		Ottawa, Canada, K1A 0R6
# All rights reserved			Tous droits reserves
# 					
# NRC disclaims any warranties,		Le CNRC denie toute garantie
# expressed, implied, or statu-		enoncee, implicite ou legale,
# tory, of any kind with respect	de quelque nature que se soit,
# to the software, including		concernant le logiciel, y com-
# without limitation any war-		pris sans restriction toute
# ranty of merchantability or		garantie de valeur marchande
# fitness for a particular pur-		ou de pertinence pour un usage
# pose.  NRC shall not be liable	particulier.  Le CNRC ne
# in any event for any damages,		pourra en aucun cas etre tenu
# whether direct or indirect,		responsable de tout dommage,
# special or general, consequen-	direct ou indirect, particul-
# tial or incidental, arising		ier ou general, accessoire ou
# from the use of the software.		fortuit, resultant de l'utili-
# 					sation du logiciel.
#
#***********************************************************************
#
# FILENAME
# gmmps
#
# PURPOSE:
# Shell script to start the GMOS Mask preparation software.
#
# This shell script sets all relevant UNIX environment variables
# to plugin the GMMPS module to the ESO SkyCat Tool
#
## Originally created by 
## E.S.O. - VLT project
## Authors: vimosmgr 04/05/00 created for cmm
#  D.Bottini 13/07/99   created
## "@(#) $Id: gmmps.sh,v 1.2 2011/04/25 18:27:32 gmmps Exp $" 
#
#
#INDENT-OFF*
# $Log: gmmps.sh,v $
# Revision 1.2  2011/04/25 18:27:32  gmmps
# Forked from 0.401.12 .
#
# Revision 1.1  2011/01/24 20:02:14  gmmps
# Compiled for RedHat 5.5 32 and 64 bit.
#
# Revision 1.2  2002/08/13 04:06:12  callen
# checking in changes to:
# vmAstroCat.tcl (to draw GMOS detector gaps)
# gmmps.sh (to allow passing an image argument to the gmmps script to load and image immediately)
#
# Revision 1.1.1.1  2002/07/19 00:02:09  callen
# importing gmmps as recieved from Jennifer Dunn
# gmmps is a skycat plugin and processes for creating masks
#
#INDENT-ON*
#
#****     D A O   I N S T R U M E N T A T I O N   G R O U P        *****
#***********************************************************************
#

# command line options for skycat
OPTION="-rtd 0"

# where gmmps is installed
INTROOT=$GMMPS; export INTROOT;

# P L U G I N S 
SKYCAT_PLUGIN=$INTROOT/src/SkyCat_plugin.tcl; export SKYCAT_PLUGIN

#echo "path = $PATH"
# call skycat
skycat $OPTION $*
