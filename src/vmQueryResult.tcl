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

# $Id: vmQueryResult.tcl,v 1.3 2013/02/04 18:38:06 gmmps Exp $
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
# vmQueryResult.tcl
#
# PURPOSE:
# Widget for viewing the results of a catalog query. 
#
# CLASS NAME(S)
# itcl::class cat::vmQueryResult  - class to query catalog
#
# METHOD NAME(S)
# constructor		- Constructor
# debugStatement	- Print debug statement if flag is set.
# sort_dialog		- Pop up a dialog to sort the list
# select_result_row	- Called when a result row is selected
# select_columns	- Called when table columns are displayed
# reset			- Reset table dialogs if needed
# save_as		- Save current data to local catalog.
# add_to		- Add rows in current listing to catalog.
# add_selected		- Add current selected rows to catalog.
# add_rows		- Add current info rows to catalog.
# removed_selected	- Removed selected rows from catalog.
# save_to_file		- Save given info to catalog file.
# enter_new_object	- Pop up dialog to enter data for a new object.
# check_row		- Check row contains valid data.
# enter_object		- Data for new object to add to a catalog.
# edit_selected_object	- Popup to allow edit of object.
# update_options	- Update the table sort and column display options.
#
# Original taken from:
# E.S.O. - VLT project/ESO Archive
# @(#) $Id: vmQueryResult.tcl,v 1.3 2013/02/04 18:38:06 gmmps Exp $
#
# Created originally by:
# D.Bottini,01 Apr 00
#
# $Log: vmQueryResult.tcl,v $
# Revision 1.3  2013/02/04 18:38:06  gmmps
# Small features and bug fixes from Dec2012 and Jan2013.
#
# Revision 1.2  2011/04/25 18:27:34  gmmps
# Forked from 0.401.12 .
#
# Revision 1.5  2011/04/25 16:35:19  gmmps
# Bugfixes.
#
# Revision 1.4  2011/04/08 20:13:25  gmmps
# N&S bugfixes.
#
# Revision 1.3  2011/03/21 23:13:01  gmmps
# configuration file development continues.
#
# Revision 1.2  2011/03/17 17:23:50  gmmps
# Generalized detector settings and fixed an install script bug.
#
# Revision 1.1  2011/01/24 20:02:16  gmmps
# Compiled for RedHat 5.5 32 and 64 bit.
#
# Revision 1.2  2003/01/18 03:45:39  callen
# finished version .20 for distribution, including drawing the hashmarks
# on the prohibited area, not the band, fixing some terms
# (px-->pix, Band Height--> Band Size)
#
# Modified Files:
# 	band_def_UI.tcl gmmps_spoc.tcl vmQueryResult.tcl
#
# Revision 1.1.1.1  2002/07/19 00:02:09  callen
# importing gmmps as recieved from Jennifer Dunn
# gmmps is a skycat plugin and processes for creating masks
#
# Revision 1.6  2001/11/28 06:54:46  dunn
# Fixed enter_object bug.
#
# Revision 1.5  2001/10/19 23:54:16  dunn
# Fixed bug in tilted slits.
#
# Revision 1.4  2001/08/22 22:55:24  dunn
# *** empty log message ***
#
# Revision 1.3  2001/07/17 19:47:28  dunn
# *** empty log message ***
#
# Revision 1.2  2001/04/25 17:01:22  dunn
# Initial revisions.
#
#
#****     D A O   I N S T R U M E N T A T I O N   G R O U P        *****
#***********************************************************************
#


#***********************************************************************
# A vmQueryResult widget frame is defined as a vmTableList (see vmTableList(n)
# in the tclutil package) with some methods added for catalog
# support. It is used to display the results of a catalog query. See
# also AstroQuery(n) for the query paramaters, AstroCat(n) for the main
# window or classes derived from these in the skycat package.
# These classes do not deal with images - only catalog data. See the
# derived classes in the skycat package for image support.
#***********************************************************************

itcl::class cat::vmQueryResult {
    inherit util::vmTableList


    #############################################################
    #  Name: constructor
    #
    #  Description:
    #   Constructor, what can I say.
    #############################################################
    #############################################################
    constructor {args} {
	global qrDebugLevel
	set qrDebugLevel 0
	eval itk_initialize $args
    }
    
    #############################################################
    #  Name: debugStatement
    #
    #  Description:
    #   Only print the passed in message, if the debug flag is set.
    #   BIG WARNING:  need to make this its own class.
    #############################################################
    #############################################################

    protected proc debugStatement {line} {
	global qrDebugLevel

	if { $qrDebugLevel == 1 } {
	    puts $line
	}
    }
    
    #############################################################
    #  Name: sort_dialog
    #
    #  Description:
    #   Pop up a dialog to sort the list
    #############################################################
    #############################################################

    public method sort_dialog {} {
	if {[llength $headings_] == 0} {
	    ::cat::vmAstroCat::info_dialog "Please make a query first so that the column names are known" $w_
	    return
	}
	vmTableList::sort_dialog
    }

    
    #############################################################
    #  Name: select_result_row
    #
    #  Description:
    #   This method is called whenever a result row is selected.
    #   If the row edit window exists, update it with the values for
    #   the new row.
    #############################################################
    #############################################################

    public method select_result_row {} {
	if {[winfo exists $w_.ef]} {
	    $w_.ef configure -values [lindex [get_selected] 0]
	}
    }


    #############################################################
    #  Name: select_columns
    #
    #  Description:
    #   Pop up a dialog to select table columns to display
    #############################################################
    #############################################################

    public method select_columns {} {
	if {[llength $headings_] == 0} {
	    ::cat::vmAstroCat::info_dialog "Please make a query first so that the column names are known" $w_
	    return
	}
	vmTableList::layout_dialog
    }


    #############################################################
    #  Name: reset
    #
    #  Description:
    #   Reset table dialogs if needed
    #############################################################
    #############################################################

    public method reset {} {
	foreach w "$w_.tblsort $w_.tblcfg" {
	    if {[winfo exists $w]} {
		$w reset
	    }
	}
	$astrocat showcols {}
	$astrocat sortcols {}
    }
    
    
    #############################################################
    #  Name: save_as
    #
    #  Description:
    #   Save the current data to a local catalog
    #############################################################
    #############################################################
    
    public method save_as {} {
	set file [filename_dialog [pwd] * $w_]
	if {"$file" != ""} {
	    if {[file isfile $file]} {
		if {![::cat::vmAstroCat::my_confirm_dialog "File: `[file tail $file]' exists \
                                      - Do you want to overwrite it ?" $w_]} {
		    return
		}
		if {[file isdir $file]} {
		    ::cat::vmAstroCat::error_dialog "File: `[file tail $file]' is a directory" $w_
		    return
		}
	    }
	    save_to_file $file $info_ $headings_
	}
    }


    #############################################################
    #  Name: add_to
    #
    #  Description:
    #   Add the rows in the current listing to a local catalog file
    #############################################################
    #############################################################
    
    public method add_to {} {
	if {[llength $info_] == 0} {
	    ::cat::vmAstroCat::error_dialog "There are no rows to save" $w_
	    return;
	}
	add_rows $info_ $headings_
    }

    #############################################################
    #  Name: add_selected
    #
    #  Description:
    #   Add the currently selected rows to a local catalog file
    #############################################################
    #############################################################

    public method add_selected {} {
	set info [get_selected]
	if {[llength $info] == 0} {
	    ::cat::vmAstroCat::error_dialog "No rows are selected" $w_
	    return;
	}
	add_rows $info $headings_
    }

    
    #############################################################
    #  Name: add_rows
    #
    #  Description:
    #   Add the given info rows (result of a query) to a local 
    #   catalog file with the given headings. The user selects
    #   the name of the catalog file.
    #############################################################
    #############################################################
    
    public method add_rows {info headings} {
#	puts "vmQR:add_rows ($info, $headings)"
	if {[llength $headings] == 0} {
	    ::cat::vmAstroCat::error_dialog "There is no data to save" $w_
	    return;
	}
	set file [filename_dialog [pwd] * $w_]
	if {"$file" != ""} {
	    if {! [file isfile $file]} {
		if {[::cat::vmAstroCat::my_confirm_dialog "File: `[file tail $file]' does not exists \
                                    - Do you want to create it ?" $w_]} {
		    save_to_file $file $info $headings
		}
	    } else {
		if {[file isdir $file]} {
		    ::cat::vmAstroCat::error_dialog "File: `[file tail $file]' is a directory" $w_
		    return
		}
		save_to_file $file $info $headings 1
	    }
	}
    }

    
    #############################################################
    #  Name: remove_selected
    #
    #  Description:
    #   Remove the currently selected rows from a local catalog file
    #############################################################
    #############################################################
    

    public method remove_selected {} {
	set file [$astrocat longname]
	set info [get_selected]

	if {[llength $info] == 0} {
	    ::cat::vmAstroCat::error_dialog "No rows are selected" $w_
	    return;
	}

	if {! [::cat::vmAstroCat::my_confirm_dialog "Remove selected objects?" $w_]} {
	    return
	}

	if {[catch {$astrocat remove $file $info $equinox $headings_} msg]} {
	    ::cat::vmAstroCat::error_dialog $msg $w_
	    return
	}
    }

    
    #############################################################
    #  Name: save_to_file
    #
    #  Description:
    #   Save the given info (the result of query) to the given catalog file,
    #   using the given column headings.
    #   If iflag is 1, insert rows in the existing file.
    #############################################################
    #############################################################

    public method save_to_file {file info {headings ""} {iflag 0}} {
	#
	# Can't use this one because it writes without the tcs ra/dec col's.
	#
	if {$headings == ""} {
	    set headings $headings_
	}
        
	if {[catch {$astrocat save $file $iflag $info $equinox $headings} msg]} {
	    ::cat::vmAstroCat::error_dialog "Error saving rows to file: $msg" $w_
	    return 1
	}
	return 0
    }
    

    #############################################################
    #  Name: enter_new_object
    #
    #  Description:
    #    Pop up a dialog to enter the data for a new object for a local 
    #    catalog. The command is evaluated after the users enters
    #    the new data.
    #############################################################
    #############################################################
    

# UNUSED? Commented out for testing, may be deleted later if not causing problems

#    public method enter_new_object {{command ""}} {
#	catch {delete object $w_.ef}
#	EnterObject $w_.ef \
#	    -title {Please enter the data for the object below:} \
#	    -labels $headings_ \
#	    -center 0 \
#	    -command [code $this enter_object $command]
#   }

    #############################################################
    #  Name: tilt_object
    #
    #  Description:
    #    Pop up a dialog to enter the angle for a selected object.
    #    The command is evaluated after the users enters
    #    the new data.
    #############################################################
    #############################################################
    

# UNUSED? Commented out for testing, may be deleted later if not causing problems

#    public method tilt_object {{command ""}} {
#	catch {destroy $w_.ef}
#	set lines [lindex [get_selected] 0]
#
#	if {[llength $lines] == 0} {
#	    ::cat::vmAstroCat::error_dialog "No rows are selected" $w_
#	    return;
#	}
#	set title "Angle(deg):"
#	set values 0.0
#
#	EnterObject $w_.ef \
#	    -title {Please enter the angle for the object(s) selected:} \
#	    -labels $title \
#	    -values  $values \
#	    -command [code $this set_angle $command ]
#	
#   }

    
    #############################################################
    #  Name: check_row
    #
    #  Description:
    #   Check that the given row contains valid data for a catalog
    #   and return 0 if OK
    #############################################################
    #############################################################
    
# UNUSED? Commented out for testing, may be deleted later if not causing problems

#    public method check_row {data} {
#       #
#	# Warning, this does a tclCatalog check, which 
#	# relies on the columns being in a specific order.
#	if {[catch {$astrocat checkrow $data} msg]} {
#	    ::cat::vmAstroCat::error_dialog $msg
#	    return 1
#	}
#	return 0
#   }

    
    #############################################################
    #  Name: updater_object
    #
    #  Description:
    #   This method is called with the data for a new object to add to a local
    #   catalog. The row is added to the local catalog file and the
    #   command is evaluated. If a row with the given id already exists, it is
    #   updated (after confirmation).
    #############################################################
    #############################################################
    
# UNUSED? Commented out for testing, may be deleted later if not causing problems

#    public method updater_object {command oldRow newRow } {
#	debugStatement "updater_object: entry..."
#
#	set file [$astrocat longname]
#	set append 1
#	#
#	# Update the row
#	set_row oldRow newRow 
#	save_to_file $file $info_ $headings_
#	if {[save_to_file $file $info_ $headings_ $append] != 0} {
#	    return
#	}
#
#	# eval caller supplied command after change
#	eval $command
#   }

    #############################################################
    #  Name: set_angle
    #
    #  Description:
    #   This method is called with the data for a new object to add to a local
    #   catalog. The row is added to the local catalog file and the
    #   command is evaluated. If a row with the given id already exists, it is
    #   updated (after confirmation).
    #############################################################
    #############################################################
    

# UNUSED? Commented out for testing, may be deleted later if not causing problems

#    public method set_angle { command angle } {
#	debugStatement "set_angle: entry, angle=$angle..."
#
#	# Slittilt must be within valid range. 
#	if {($angle > 45.0 && !($angle <= 360.0 && $angle >= 315.0) || $angle < -45.0)} {
#	    ::cat::vmAstroCat::error_dialog "ERROR: Slit Tilt $angle is outside valid range (-45.0 to 45 degrees).\n" $w_
#	    return
#	} else {
#	    set angle [format %.6f $angle ]
#	}
#
#	# see if this id already exists...
#	# and get the column# for slittilt
#	set angleCol ""
#	set angleCol [lsearch -regex $headings_ {(?i)slittilt} ]
#
#	if { $angleCol == "" || $angleCol < 0 } {
#	    ::cat::vmAstroCat::error_dialog "Missing column slittilt" $w_
#	    return
#	}
#	#
#	#  Get the ID column.
#	set idCol [lsearch -regex $headings_ {(?i)ID} ]
#
#
#	#
#	#  Get the lines selected,  cycle thru and replace if required.
#	#  get the id for that line
#	#  replace slittilt col with new value.
#	set lines [get_selected]
#
#	#
#	#  Save current place, Cycle thru for each row that has been selected.
#	save_yview
#	save_selection
#	foreach row $lines {
#	    # Create new row, get that row's ID
#	    set newrow [lreplace $row $angleCol $angleCol $angle]
#	    set rowId [lindex $row $idCol ]
#	    debugStatement "set_angle: old=$row, new=$newrow, rowId=$rowId..."
#
#	    # Get the index into the grand list for that ID &
#	    # replace that row.
#	    set index [lsearch -exact $info_ $row]
#	    debugStatement "set_angle: index=$index..."
#	    set info_ [lreplace $info_ $index $index $newrow]
#	}
#
#	#
#	# Save new information back to the catalog.
#	debugStatement "headings_= $headings_ "
#	set file [$astrocat longname]
#	save_to_file $file $info_ $headings_
#
#	# eval caller supplied command after change (search)
#	eval $command
#	#
#   }
#
    
    
    #############################################################
    #  Name: enter_object
    #
    #  Description:
    #   This method is called with the data for a new object to add to a local
    #   catalog. The row is added to the local catalog file and the
    #   command is evaluated. If a row with the given id already exists, it is
    #   updated.
    #############################################################
    #############################################################
    
    # Called when manually entering a new object

    public method enter_object {command info} {
	debugStatement "enter_object: entry..."
	
	# see if this id already exists...
	set id [lindex $info [$astrocat id_col]]
	#
	#  Can't do this type of query, returns a row based on tcs catalog.
	#set row [lindex [$astrocat query -id $id] 0]

	# check that slittilt is within valid range. 
	set tilt_col [lsearch -exact $headings_ "slittilt"]
	if {$tilt_col != -1} {
	    set tt [lindex $info $tilt_col ]
	    if {($tt > 45.0 && !($tt <= 360.0 && $tt >= 315.0) || $tt < -45.0)} {
		::cat::vmAstroCat::error_dialog "Cannot add object.\nSlit Tilt $tt is outside valid range (-45.0 to 45 degrees).\n"
		return
	    }
	}

	#
	#  Find the ID col, and get that data out of the 
	debugStatement "id = $id, headings_= $headings_ "
	#set row [lindex [$astrocat query -id $id] 0]
	set row [lsearch -exact $info_ $info]
	debugStatement "row=$row.."
	set file [$astrocat longname]
	set append 1
	debugStatement "enter_object: id=$id, file=$file, row=$row.."
	if {[llength $row]} {
	    if {"$row" == "$info"} {
		::cat::vmAstroCat::info_dialog "No changes were made to $id."
		return
	    }
	    # object with this id already exists
	    #if {! [confirm_dialog "Update object $id ?" $w_]} {
	    #return
	    #}
	    # replace with new data
	    debugStatement "enter_object: about to save_to_file..."

	    #
	    # Save in information to the file.  Save back to the
	    # catalog.
	    if {[save_to_file $file [list $info] $headings_ $append] != 0} {
		return
	    }
	} else {
	    # must be a new object
	    #if {! [confirm_dialog "Enter new object with id $id ?" $w_]} {
	    #return
	    # }
	    save_to_file $file [list $info] $headings_ $append
	}

	# eval caller supplied command after change
	eval $command
    }

    
    #############################################################
    #  Name: edit_selected_object
    #
    #  Description:
    #   Pop up a window so that the user can edit the selected object(s).
    #   The optional command is evaluated with no args if the object is
    #   changed.
    #############################################################
    #############################################################
    
    public method edit_selected_object {{command ""}} {
	catch {destroy $w_.ef}
	set values [lindex [get_selected] 0]

	if {[llength $values] == 0} {
	    ::cat::vmAstroCat::error_dialog "No rows are selected" $w_
	    return;
	}
	
	EnterObject $w_.ef \
	    -title {Please enter the data for the object below:} \
	    -labels $headings_ \
	    -values $values \
	    -command [code $this enter_object $command]
    }

    
    #############################################################
    #  Name: update_options
    #
    #  Description:
    #   Update the table sort and column display options from the
    #   catalog entry
    #############################################################
    #############################################################

    public method update_options {} {
	# sort cols
	config \
	    -sort_cols [$astrocat sortcols] \
	    -sort_order [$astrocat sortorder]

	# show/hide cols
	set show_cols [$astrocat showcols]
	if {[llength $show_cols]} {
	    set_options $headings_ Show 0
	    set_options $show_cols Show 1
	    # $order should be a list of all columns (visible or not)
	    # in the order they should be displayed
	    set order $show_cols
	    foreach i $order {
		set a($i) 1
	    }
	    foreach i $headings_ {
		if {! [info exists a($i)]} {
		    lappend order $i
		}
	    }
	    config -order $order
	} 
    }


    # -- options --

    # save lines retrieved.
    protected common current_selection_ {}

    # astrocat (C++ based) object for accessing catalogs
    public variable astrocat

    # equinox of ra and dec columns in query result
    public variable equinox 2000
}
