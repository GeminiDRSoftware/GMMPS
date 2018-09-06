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

# $Id: SkyCat_plugin.tcl,v 1.4 2013/03/15 17:25:23 gmmps Exp $
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
# SkyCat_plugin.tcl
#
# PURPOSE:
# Print out usless (opps, meant useful) stuff.
#
#
# Orignially derived by
# Dario Bottini 01 Apr 00,
# E.S.O. - VLT project/ESO Archive
#
# $Log: SkyCat_plugin.tcl,v $
# Revision 1.4  2013/03/15 17:25:23  gmmps
# Update name and add Mischa to credits
#
# Revision 1.3  2011/08/18 22:37:18  gmmps
# Bugfixes and small improvements, focus on mask design algorithm
#
# Revision 1.2  2011/04/25 18:27:32  gmmps
# Forked from 0.401.12 .
#
# Revision 1.2  2011/03/31 19:37:31  gmmps
# N&S properties are now remembered by the config file. Bugfixes.
#
# Revision 1.1  2011/01/24 20:02:12  gmmps
# Compiled for RedHat 5.5 32 and 64 bit.
#
# Revision 1.3  2002/12/21 03:34:53  callen
# got past the roadblocks using vmTableList but, made some changes to text messages.
#
# Not yet done with band shuffling interface.  Checking things in for safety
# before vacation.
#
# Revision 1.2  2002/12/06 02:50:50  callen
# changed credit banner slightly to look cleaner
#
# Revision 1.1.1.1  2002/07/19 00:02:09  callen
# importing gmmps as recieved from Jennifer Dunn
# gmmps is a skycat plugin and processes for creating masks
#
# Revision 1.5  2001/11/27 23:04:38  dunn
# name change of menu.
#
# Revision 1.4  2001/08/22 22:55:24  dunn
# *** empty log message ***
#
# Revision 1.3  2001/08/20 16:33:25  dunn
# Added the reading/printing of version.
#
#
#****     D A O   I N S T R U M E N T A T I O N   G R O U P        *****
#***********************************************************************
#

#puts "\nGemini MOS Mask Preparation Software Plugin\n"
puts "Derived from the VIMOS Mask Preparation Software"
puts "Developed originally by Dario Bottini at the"
puts "Istituto di Fisica Cosmica G.Occhialini - CNR, Italy."
puts "Modified by Jennifer Dunn, Craig Allen, Dustin Fennell, Bryan Miller"
puts "and Mischa Schirmer\n"

# This proc is required. It will be called once for each skycat
# instance. The parameter is the name ("$this") of the SkyCat
# class object.

proc SkyCat_plugin {this} {
    # get the toplevel widget name
    set w [utilNamespaceTail $this]

    #
    #  Open the version file and read in the first line, which
    #  should be the version number
    #  spit out the version
    #

    set gmmps_version 0.0
    set home_ $::env(GMMPS)
    catch {set channel [open $home_/VERSION r]}
    catch {gets $channel gmmps_version}
    catch {::close $channel }

    # call a proc to add items to the Graphics menu.
    # Note that the directory containing this file is automatically
    # appended to the Tcl auto_path, so we can just call a proc
    # as long as there is a tclIndex file in this directory.
    set menu_info [gmmps_menu $w ]
    
    set lastImageAndCatalog [::cat::vmAstroCat::gmmps_config [list "catalog" "image" "instrument" "catalog_type"]]
    if {$lastImageAndCatalog != 1} {

	# The stuff below is not working. I keeep it alive just in case these variables are needed somewhere else...
    	set last_cat [string trim [lindex $lastImageAndCatalog 0 ]]
   	set last_image [string trim [lindex $lastImageAndCatalog 1 ]]
  	set last_inst  [string trim [lindex $lastImageAndCatalog 2 ]]
    	set last_type [string trim [lindex $lastImageAndCatalog 3 ]]
    	
    	set id [lindex $menu_info 0 ]
    	set classname [lindex $menu_info 1 ]
    	set debug [lindex $menu_info 2 ]
    	
    	set cat_exists [file exists $last_cat ]
    	set image_exists [file exists $last_image]
    	
    	if {$cat_exists && $image_exists} {
	    
	    # Open .cat type if last load was of .fits type.
	    if {$last_type == 2} {
		set last_type 1
	    } elseif {$last_type == 4} {
		set last_type 3
	    }
	    
	    # not quite working.
	    # image2 config -file $last_image
	    #::cat::vmAstroCat::select_catalog $last_cat local $id $classname $debug $last_type "" $last_inst
    	} else {
#	    puts ">>   Could not find these previously used files. You probably deleted or moved them:"
#	    puts ">>      $last_cat"
#	    puts ">>      $last_image"
#	    puts ">>   GMMPS will start from scratch ..."
#	    puts ""
    	}
    } else {
    	puts ">>   Problem loading from gmmps_config"
    }

}
