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

# $Id: vmSkyQueryResult.tcl,v 1.2 2011/04/25 18:27:34 gmmps Exp $
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
# vmSkyQueryResult.tcl
#
# PURPOSE:
# Widget for viewing query results with skycat image support.
#
# Orignial from:
# E.S.O. - VLT project/ESO Archive
# by:
# D.Bottini 01 Apr 00   created
#
# METHOD NAME(S)
# save_catalog_to_file	 
#
#
# $Log: vmSkyQueryResult.tcl,v $
# Revision 1.2  2011/04/25 18:27:34  gmmps
# Forked from 0.401.12 .
#
# Revision 1.1  2011/01/24 20:02:16  gmmps
# Compiled for RedHat 5.5 32 and 64 bit.
#
# Revision 1.1.1.1  2002/07/19 00:02:09  callen
# importing gmmps as recieved from Jennifer Dunn
# gmmps is a skycat plugin and processes for creating masks
#
# Revision 1.3  2001/05/04 22:49:23  dunn
# *** empty log message ***
#
# Revision 1.2  2001/05/02 18:03:02  dunn
# Added new fits stuff.
#
#
#****     D A O   I N S T R U M E N T A T I O N   G R O U P        *****
#***********************************************************************
#


# A vmSkyQueryResult widget is defined as a vmQueryResult (see cat package)
# with some added support for skycat image access, used for selecting objects
# to add to a local catalog.

itcl::class skycat::vmSkyQueryResult {
    inherit cat::vmQueryResult


    # constructor

    constructor {args} {
	eval itk_initialize $args
    }
    

    # pop up a dialog to enter the data for a new object for a local catalog
    # The command is evaluated after the users enters the new data.
    # (redefined from parent class to add image support)

    public method enter_new_object {{command ""}} {
	catch {delete object $w_.ef}
	EnterObject $w_.ef \
	    -title {Please enter the data for the object below:} \
	    -labels $headings_ \
	    -center 0 \
	    -image $skycat \
	    -command [code $this enter_object $command]
    }

    # pop up a window so that the user can edit the selected object(s)
    # The optional command is evaluated with no args if the object is
    # changed.
    # (redefined from parent class AstroCat to add image support)
    public method edit_selected_object {{command ""}} {
	catch {destroy $w_.ef}
	set values [lindex [get_selected] 0]

	if {[llength $values] == 0} {
	    ::cat::vmAstroCat::error_dialog "No rows are selected" $w_
	    return;
	}

	EnterObject $w_.ef \
	    -title {Please enter the data for the object below:} \
	    -image $skycat \
	    -labels $headings_ \
	    -values $values \
	    -command [code $this enter_object $command]
    }


    # save the current data as a FITS table in the current image file.
    # The argument is the catalog config entry.
    
    public method save_with_image {entry} {
	set image [$skycat get_image]

	# make sure file exists
	set file [$image cget -file]
	set suffix [file extension $file]

	switch -exact -- "$suffix" {
	    ".gz" -
	    ".gzfits" -
	    ".gfits" -
	    ".Z" -
	    ".cfits" -
	    ".hfits" {
		::cat::vmAstroCat::error_dialog "Can't save catalog data to compressed image file."
		return
	    }
	}

	set headings [$image hdu listheadings]
	
	# get the short name of the catalog and use it as the table name
	set extname ""
	foreach i $entry {
	    lassign $i key value
	    if {"$key" == "short_name"} {
		set extname $value
		break
	    }
	}
	# build the name from the catalog name and the file base name
	set file [file tail [file rootname $file]]
	if {[string first "$file-" $extname] == 0} {
	    set extname [string range $extname [expr [string length $file]+1] end]
	}
	
	if {"$extname" == ""} {
	    set extname [::cat::vmAstroCat::my_input_dialog "Please enter a name for the FITS table"]
	}
	if {"$extname" == ""} {
	    return
	}
	
	# use all ASCII formats (use inherited size_ array)
	set tform {}
	if {$num_cols_ <= 1} {
	    ::cat::vmAstroCat::error_dialog "No data to save"
	    return
	}
	if {! [info exists size_]} {
	    ::cat::vmAstroCat::error_dialog "No column size info"
	    return
	}
	for {set i 1} {$i <= $num_cols_} {incr i} {
	    lappend tform "$size_($i)A"
	}
	
	# If there is aleady a table by this name in the file, delete it
	# and replace it with the new one.
	set hdu_list [$image hdu list]
	foreach hdu $hdu_list {
	    eval lassign [list $hdu] $headings
	    if {"$extname" == "$ExtName"} {
		if {[catch {$image hdu delete $HDU} msg]} {
		    ::cat::vmAstroCat::error_dialog $msg
		}
	    }
	}

	# save the current HDU number and restore it before returning
	set saved_hdu [$image hdu]

	# create a new binary table
	if {[catch {
	    $image hdu create binary $extname $headings_ $tform $info_
	} msg]} {
	    ::cat::vmAstroCat::error_dialog "error creating FITS table '$extname': $msg"
	    return
	}

	# create/update catalog config info to a special FITS table
	if {[catch {
	    save_config_info_to_fits_table $extname $entry
	} msg]} {
	    after idle [list ::cat::vmAstroCat::error_dialog $msg]
	}

	# restore saved HDU
	set numHDUs [$image hdu count]
	if {$saved_hdu <= $numHDUs} {
	    $image hdu $saved_hdu
	} else {
	    # shouldn't happen, but if the HDU was deleted, use the new last one
	    $image hdu $numHDUs
	}

	# update/display the HDU window
	$skycat update_fits_hdus
    }

    
    #############################################################
    #  Name: save_catalog_to_file
    #
    #  Description:
    #   Save the current catalog as a FITS table.
    #############################################################
    #############################################################

    
    public method save_catalog_to_file{entry} {
    }


    # Save the given catalog config entry in a FITS table with the name
    # $catinfo. The hdu arg gives the HDU number of the $catinfo table,
    # or 0 if it does not exist.
    
    protected method save_config_info_to_fits_table {extname entry} {
	set image [$skycat get_image]

	# Look for an existing $catinfo table
	set headings [$image hdu listheadings]
	set hdu_list [$image hdu list]
	set hdu 0
	foreach row $hdu_list {
	    eval lassign [list $row] $headings
	    if {"$ExtName" == "$catinfo"} {
		set hdu $HDU
		break
	    }
	}

	# If the table exists, get the data and remove it, so that
	# we can recreate it, with possibly new columns or column
	# widths
	set rowNum 0
	if {$hdu} {
	    if {[catch {
		set headings [$image hdu headings $hdu]
		set info [$image hdu get $hdu]
		$image hdu delete $hdu
	    } msg]} {
		::cat::vmAstroCat::error_dialog $msg
		return
	    }
	    # scan the current info, allow for future additions to headings
	    foreach row $info {
		eval lassign [list $row] $headings
		foreach i $headings {
		    set ar($rowNum,$i) [set $i]
		}
		if {"$SHORT_NAME" == "$extname"} {
		    # replace this entry with the new one
		    continue
		}
		incr rowNum
	    }
	}

	# set headings for catalog config table
	set headings "SHORT_NAME ID_COL RA_COL DEC_COL X_COL Y_COL EQUINOX SYMBOL \
                      SEARCH_COLS SORT_COLS SORT_ORDER SHOW_COLS HELP COPYRIGHT"
	
	# initialize min column widths
	foreach i $headings {
	    set width($i) 1
	}

	# get values from config entry
	foreach i $entry {
	    lassign $i key value
	    if {"$key" == "symbol" || "$key" == "search_cols"} {
		# special treatment needed here (see CatalogInfo.tcl)
		set value [join $value " : "]
	    }
	    set ar($rowNum,[string toupper $key]) $value
	}
	set ar($rowNum,SHORT_NAME) $extname

	# build table data list and get max col widths for FITS formats
	set info {}
	set numRows [incr rowNum]
	for {set rowNum 0} {$rowNum < $numRows} {incr rowNum} {
	    set row {}
	    foreach i $headings {
		if {[info exists ar($rowNum,$i)]} {
		    lappend row $ar($rowNum,$i)
		    set width($i) [max $width($i) [string length $ar($rowNum,$i)]]
		} else {
		    lappend row {}
		}
	    }
	    lappend info $row
	}

	# build the tform argument
	set tform {}
	foreach i $headings {
	    lappend tform "$width($i)A"
	}

	# create a new binary table and insert the info
	if {[catch {
	    $image hdu create binary $catinfo $headings $tform $info
	} msg]} {
	    ::cat::vmAstroCat::error_dialog "error creating FITS table '$catinfo': $msg"
	    return
	}
    }


    # -- public variables --

    # name of SkyCatCtrl itcl widget
    public variable skycat {}

    # name of the FITS table containing catalog config info
    public variable catinfo "CATINFO"
}
