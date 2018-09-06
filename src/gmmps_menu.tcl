# Copyright (C) 2014 Association of Universities for Research in Astronomy, Inc.
# Contact: mschirme@gemini.edu
#  
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software 
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

#-*-tcl-*-
# $Id: gmmps_menu.tcl,v 1.2 2011/04/25 18:27:33 gmmps Exp $
#
#***********************************************************************
#****     D A O   I N S T R U M E N T A T I O N   G R O U P        *****
#
# (c) <year>				(c) <year>
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
# gmmps_menu.tcl
#
# PURPOSE:
# Setup main menu under Skycat
#
# PROC NAME(S)
# gmmps_menu	- Setup the plug in GMMPS main menu under Skycat
# menu_update	- Update the GMMPS menu.
#
# Original taken from:
# E.S.O. - VLT project/ESO Archive
#
# "@(#) $Id: gmmps_menu.tcl,v 1.2 2011/04/25 18:27:33 gmmps Exp $" 
# $Id: gmmps_menu.tcl,v 1.2 2011/04/25 18:27:33 gmmps Exp $
#
# Created originally by:
# D.Bottini, 01 Apr 00
#
#
# $Log: gmmps_menu.tcl,v $
# Revision 1.2  2011/04/25 18:27:33  gmmps
# Forked from 0.401.12 .
#
# Revision 1.3  2011/03/31 19:37:32  gmmps
# N&S properties are now remembered by the config file. Bugfixes.
#
# Revision 1.2  2011/03/25 23:30:21  gmmps
# *** empty log message ***
#
# Revision 1.1  2011/01/24 20:02:14  gmmps
# Compiled for RedHat 5.5 32 and 64 bit.
#
# Revision 1.4  2006/05/06 09:29:39  callen
# more changes for FLAMINGOS-2
#
# Revision 1.3  2006/05/04 19:38:11  callen
# changes
#
# Revision 1.2  2003/02/05 23:20:15  callen
# added new "Convert and Load ODF from FITS" menuitem
#
# Revision 1.1.1.1  2002/07/19 00:02:09  callen
# importing gmmps as recieved from Jennifer Dunn
# gmmps is a skycat plugin and processes for creating masks
#
# Revision 1.6  2001/11/27 23:06:22  dunn
# Change of name.
#
# Revision 1.5  2001/10/11 21:07:24  dunn
# Changed Master to Minimal.
#
# Revision 1.4  2001/08/13 21:22:35  dunn
# *** empty log message ***
#
# Revision 1.3  2001/06/27 04:48:26  dunn
# *** empty log message ***
#
# Revision 1.2  2001/04/25 17:01:22  dunn
# Initial revisions.
#
#
#****     D A O   I N S T R U M E N T A T I O N   G R O U P        *****
#***********************************************************************
#

#############################################################
#  Name: gmmps_menu
#
#  Description:
#   Setup up GMMS menu items.
#   $w is the name of the top level window.
#############################################################
#############################################################
proc gmmps_menu {w} {

    #
    # Set globals
    #

    #
    # Note: The liberal use of globals is part of what makes gmmps so difficult 
    #  to maintain. If anyone is ever re-writing major parts of this code and 
    #  can manage to remove/reduce greatly the reliance on global variables, 
    #  that would be a large step towards improving the function/maintainability
    #  of the GMMPS software. -df
    #
    
    set id "namespace inscope ::skycat::SkyCat .skycat1.image"
    set classname "::skycat::vmSkySearch"
    set debug 0

    set m [$w add_menubutton "GMMPS" {Gemini Mask Making Software}]

    $w add_menuitem $m command "Create masks from object tables:" \
        {Create masks} -state disabled

    $w add_menuitem $m command "Load Object Table (OT *.cat; experts only!)" \
        {Load an Object Table in *.cat ASCII format} \
        -command [code cat::vmAstroCat::local_catalog $id $classname $debug 1 $w]

    $w add_menuitem $m command "Load Object Table (OT *.fits)" \
        {Load an Object Table in *.fits binary format and convert it to ASCII} \
        -foreground #ff8 -command [code cat::vmAstroCat::local_catalog $id $classname $debug 3 $w]
    
    $m add separator

    $w add_menuitem $m command "Display existing mask designs (ODF):" \
        {Display existing mask designs} -state disabled

    $w add_menuitem $m command "Load Object Definition File (ODF *.cat; experts only!)" \
        {Load an Object Definition File in *.cat ASCII format} \
        -command [code cat::vmAstroCat::local_catalog $id $classname $debug 2 $w]

    $w add_menuitem $m command "Load Object Definition File (ODF *.fits)" \
        {Load an Object Definition File in *.fits binary format and convert it to ASCII} \
        -foreground #ff8 -command [code cat::vmAstroCat::local_catalog $id $classname $debug 4 $w]

    set wavemapper [$w add_menubutton "WaveMapper" {Displays where the wavelengths fall on the GMOS detectors}]

    $w add_menuitem $wavemapper command "GMOS Wavelength Mapper" \
	{Wavelength maps for GMOS-N/S} -foreground #ff8 \
        -command [code cat::vmAstroCat::launch_wavemapper]

    return [list $id $classname $debug ]
}
