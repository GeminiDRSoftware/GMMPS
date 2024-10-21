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

# $Id: vmAstroCat.tcl,v 1.10 2013/08/14 15:46:39 gmmps Exp $
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
# vmAstroCat.tcl
#
# PURPOSE:
# User interface class for viewing catalog info
#
# WARNING:
# The catalog file is both kept and used in memory AND for some weird
# reason also written to - WITHOUT being asked.  A lot of re-processing of the
# catalog when the darn thing is already in memory.  Its almost like 2 different
# people worked on it with completely different ideas.
#
# CLASS NAME(S)
# itk::usual vmAstroCat - Main menu class
#

itk::usual vmAstroCat {}

######################################################################
# The vmAstroCat widget class defines a top level widget for searching and
# displaying astronomical catalog data. It contains a menubar with items
# for loading, editing, and saving catalog data and a table displaying
# rows and columns of catalog data. This class does not know anything
# about images or plotting objects in images, however these features may
# be added in a derived class (see the SkySearch(n) in the skycat
# package for an example).
#
# You can also run this class as a standalone application with the
# command "astrocat". The application options are the same as the class
# options.
######################################################################

itcl::class cat::vmAstroCat {
    inherit util::TopLevelWidget

    #############################################################
    #  Name: constructor
    #
    #  Description:
    #   Constructor, what can I say.
    #############################################################
    #############################################################
    constructor {args} {
    	set home $::env(GMMPS)

	# This is where the debug level is set. 
	# (Unless there are more places where someone has decided to turn it off...)
	global acDebugLevel
	set acDebugLevel 0

	eval itk_initialize $args
	
	wm protocol $w_ WM_DELETE_WINDOW [code $this close ]
    }

    
    #############################################################
    #  Name: destructor
    #
    #  Description:
    #   destructor - delete C++ based objects so that the temp 
    #   files are deleted
    #############################################################
    #############################################################
    destructor {

        catch {
            if {"[$w_.cat servtype]" == "local"} {
		if {"[string range $itk_option(-catalog) 0 4]" == "/tmp/"} {
		    file delete $itk_option(-catalog)
		}
            }
        }
        catch {$w_.cat delete}
        catch {unset instances_($instance_idx_)}
        if {"$current_instance_" == "$w_"} {
            set current_instance_ {}
        }
        
        # Clear all marks if this is the last catalog closed.
        if {[array size instances ] == 0} {
	    set target_canvas_ .skycat1.image.imagef.canvas
	    
	    $target_canvas_ delete cbo_ma
	    $target_canvas_ delete cbo_da
	    $target_canvas_ delete cbo_2ndorder
	    $target_canvas_ delete cbo_showwave
	    $target_canvas_ delete cbo_po
	    $target_canvas_ delete cbo_dg
            $target_canvas_ delete slitMarkOT
            $target_canvas_ delete slitMarkODF
            $target_canvas_ delete shading
	    $target_canvas_ delete
        }
    }

    
    #############################################################
    #  Name: init
    #
    #  Description:
    #   This function is called ??? after options have been evaluated
    #   It will : set the logfile
    #             do the window layout: which opens the catalog.
    #             enter widget name in instance array
    #             add a short help window
    #             create an object for running interruptable batch queries
    #             position from previous window, if pos.
    #		  for local catalogs, start search automatically
    #             Then ... something I don't understand.
    #############################################################
    #############################################################
    protected method init {} {
	# CBA: not working; I'm following what seems a bad use of globals to initialize an object
        # because it's already followed for catType and I think it may make a 
        # bigger mess to screw with that in this code.  So, instrument type...
        
	set instType $itk_option(-instType)

	# Set some global variables that are used everywhere
	set valid_wcs [get_global_data]
	if {$valid_wcs == "ERROR"} {
	    return
	}

	# if running stand-alone, setup X defaults
	if {$itk_option(-standalone)} {
	    util::setXdefaults
	    cat::setXdefaults  
	}

	# set the file used to keep track of URLs (for debugging)
	set_logfile

	# do window layout.  This opens the catalog, and saves to table.
	set checkerror [layout_dialog]
	if {$checkerror == "wrongfiletype"} {
	    return
	}

	# enter widget name in instance array for later reference
	set_instance

	# add a short help window
	make_short_help

	# position from previous window, if pos.
	if {"$current_instance_" != ""} {
	    wm geometry $w_ +[winfo x $current_instance_]+[winfo y $current_instance_]
	}
	set current_instance_ $w_

	# for local catalogs, start search automatically
	# Search will add the columns missing: x_ccd, y_ccd, MPS, ST
	set name $itk_option(-catalog)
	if {"[$w_.cat servtype]" == "local"} {
	    #  Set the title on the window to be the name listed
	    #  after the longname in the file.  And icon is the shortname
	    wm title $w_ "[file tail $name] ($itk_option(-number))"
	    wm iconname $w_ "[file tail [$w_.cat shortname $name]]"
	    search
	}

	set initialized_ 1

	# Configure the dialog window depending on whether this is an OT or an ODF
	set catType $itk_option(-catType)

	if { $catType == 1 || $catType == 3 } {
	    # Change window color for OT.
	    $w_ configure -background $ot_bg_
	    ot_slit_add_dialog_buttons $instType
	} elseif { $catType == 2 || $catType == 4} {
	    # Change window color for ODF.
	    $w_ configure -background $odf_bg_
	    odf_slit_add_dialog_buttons $instType
	}
	
	# Change shorthelp colors.
	$w_.shelp configure -background $ot_bg2_ -foreground $ot_text_	

    } 


    #############################################################
    #  Name: debugStatement
    #
    #  Description:
    #   Pop up a window so that the user can edit the selected object(s)
    #############################################################
    #############################################################
    protected proc debugStatement {line} {
	global acDebugLevel
	
	if { $acDebugLevel == 1 } {
	    puts $line
	}
    }


    #############################################################
    #  Name: set_logfile
    #
    #  Description:
    #   Create the ~/.skycat dir if it does not already exists and
    #   keep a log file there.
    #############################################################
    #############################################################
    protected method set_logfile {} {
	global ::env

	# open log file used to keep track of URLs (for debugging)
	set dir $env(HOME)/.skycat

	if {! [file isdirectory $dir]} {
	    catch {mkdir $dir}
	}
	set logfile_name_ $dir/log
    }


    #############################################################
    #  Name: readInFitsFile
    #
    #  Description:
    #   Convert a fits file to a catalog file format.
    #############################################################
    #############################################################
    protected proc readInFitsFile {fitsFile} {
	if {[catch {exec gmFits2Cat $fitsFile} msg]} {
	    puts "Error: vmAstroCat.tcl: readInFitsFile: $msg"
	    error_dialog "$msg" 
	    return -1
	}
	return 0
    }

    
    #############################################################
    #  Name: set_instance
    #
    #  Description:
    #   Keep an array of instances(name,id) to help locate the 
    #   window for a catalog
    #############################################################
    #############################################################    
    protected method set_instance {} {
	set name [$w_.cat longname $itk_option(-catalog)]
	set id $itk_option(-id)
	set instance_idx_ "$name,$id"
	set instances_($instance_idx_) $w_ 
    }


    #############################################################
    #  Name: add_menubar
    #
    #  Description:
    #    Add the menu bar in the object table window.
    #############################################################
    #############################################################
    protected method add_menubar {} {
	TopLevelWidget::add_menubar
	
	set home $::env(GMMPS)
	set m [add_menubutton File "Display File menu"]
	set file_menu_ $m

	if {$itk_option(-catType) == 1 || $itk_option(-catType) == 3} {
	    $m configure -foreground $menu_text_ot_ -background $menu_bg_ot_	
	} elseif {$itk_option(-catType) == 2 || $itk_option(-catType) == 4} {
	    $m configure -foreground $menu_text_odf_ -background $menu_bg_odf_
	}
	
	if {$iscat_} {
	    add_menuitem $m command "Save as..." \
		{Save listed objects to a local catalog file} \
		-command [code $this save_as] \
		-accelerator "Control-s"

	    add_menuitem $m command "Add to..." \
		{Add listed objects to a local catalog file} \
		-command [code $this add_to] \
		-accelerator "Control-a"

	    add_menuitem $m command "Add selected..." \
		{Add selected rows to a local catalog file} \
		-command [code $this add_selected] \
		-accelerator "Control-A"

	    $m add separator

	    add_menuitem $m command "Print..." \
		{Print the listing to a printer or file} \
		-command [code $this print] \
		-accelerator "Control-p"

	    add_menuitem $m command "Clear" \
		{Clear the catalog listing} \
		-command [code $this clear]

	    $m add separator
	}
	
	add_menuitem $m command "Close" \
	    {Close this window} \
	    -command [code $this close]
	
	if {$itk_option(-standalone)} {
	    add_menuitem $m command "Exit" \
		{Exit the application} \
		-command [code $this quit] \
		-accelerator "Control-q"
	}
	
	if {$iscat_ && $itk_option(-catType) <= 4} {
	    # Edit menu
	    set m [add_menubutton Edit "Display Edit menu"]
	    set edit_menu_ $m
	    
	    if {$itk_option(-catType) == 1 || $itk_option(-catType) == 3} {
		$m configure -foreground $menu_text_ot_ -background $menu_bg_ot_		
	    } else {
		$m configure -foreground $menu_text_odf_ -background $menu_bg_odf_
	    }
	    
	    add_menuitem $m command "Remove selected" \
		{Remove selected rows from the local catalog} \
		-command [code $this remove_selected] \
		-state disabled
	    
	    add_menuitem $m command "Enter new object..." \
		{Enter the data for a new object for the local catalog} \
		-command [code $this enter_new_object] \
		-state disabled
	    
	    add_menuitem $m command "Edit selected object..." \
		{Edit the data for the selected object in the local catalog} \
		-command [code $this edit_selected_object] \
		-state disabled
	}
	
	# Options menu
	if {$itk_option(-catType) <= 4} {
	    set m [add_menubutton Options "Display Options menu"]
	    set options_menu_ $m

	    if {$itk_option(-catType) == 1 || $itk_option(-catType) == 3} {
		$m configure -foreground $menu_text_ot_ -background $menu_bg_ot_ 			
	    } else {
		$m configure -foreground $menu_text_odf_ -background $menu_bg_odf_ 
	    }

	    if {$iscat_} {
		add_menuitem $m command "Set Sort Columns..." \
		    {Set options for sorting the query results} \
		    -command [code $this sort_dialog] \
		    -state disabled
		
		add_menuitem $m command "Hide/Show Columns..." \
		    {Set options for displaying columns of the query results} \
		    -command [code $this select_columns] \
		    -state disabled
		
		add_menuitem $m command "Set Plot Symbols..." \
		    {Set the symbol (color, size, etc.) to use to plot objects} \
		    -command [code $this set_plot_symbols] \
		    -state disabled
	    }
	}
    }


    #############################################################
    #  Name: set_menu_states
    #
    #  Description:
    #   Enable or disable some menus
    #############################################################
    #############################################################
    protected method set_menu_states {} {

	$options_menu_ entryconfig "Set Sort Columns..." -state normal
	$options_menu_ entryconfig "Hide/Show Columns..." -state normal

	if {[$w_.cat iswcs] || [$w_.cat ispix]} {
	    set state normal
	} else {
	    set state disabled
	}
	$options_menu_ entryconfig "Set Plot Symbols..." -state $state

	# determine states for some menu items
	if {"[$w_.cat servtype]" == "local"} {
	    set state [set sstate normal]
	} else {
	    set state [set sstate disabled]
	    # allow user to edit search cols if URL contains "%cond"
	    if {[string first "%cond" [$w_.cat url]] >= 0} {
		set sstate normal
	    } 
	}
	$edit_menu_ entryconfig "Remove selected" -state $state
	$edit_menu_ entryconfig "Enter new object..." -state $state
	$edit_menu_ entryconfig "Edit selected object..." -state $state
    }
    
    
    #############################################################
    #  Name: update_catalog_menus
    #
    #  Description:
    #   Update all of the catalog menus in all instances to show 
    #   the current catalog info. 
    #############################################################
    #############################################################
    public proc update_catalog_menus {} {
	foreach i [array names catalog_menu_info_] {
	    if {[winfo exists [utilNamespaceTail $i]]} {
		eval $catalog_menu_info_($i)
	    }
	}
    }
    

    #############################################################
    #  Name: set_plot_symbols
    #
    #  Description:
    #   Pop up a dialog to set the plot symbols to use for this
    #   catalog.
    #############################################################
    #############################################################
    public method set_plot_symbols {} {
	set columns $itk_option(-headingx)
	if {[llength $columns] == 0} {
	    info_dialog "Please make a query first so that the column names are known" $w_
	    return
	}

	utilReUseWidget cat::SymbolConfig $w_.symconf \
	    -catalog $itk_option(-catalog) \
	    -astrocat [code $w_.cat] \
	    -columns $columns \
	    -command [code $this plot]
    }


    #############################################################
    #  Name: update_search_options
    #
    #  Description:
    #    Update the search option entries after they have been edited
    #############################################################
    #############################################################
    public method update_search_options {} {
	$searchopts_ update_search_options
    }


    #############################################################
    #  Name: close
    #
    #  Description:
    #    Close this window
    #############################################################
    #############################################################
    public method close {} {
	global ::cbo_specbox ::cbo_ot_slits

	catch {$this delete_objects}
	
	if {$itk_option(-catType) == 1 || $itk_option(-catType) == 3} {
	    if {$cbo_ot_slits} {
		catch {clearslits_OT}
	    }
	}
	if {$itk_option(-catType) == 2 || $itk_option(-catType) == 4} {
	    catch {file delete "gemwm.input"}
	    catch {file delete "gemwm.output"}
	    catch {file delete "gemwm_indwave.input"}
	    catch {file delete "gemwm_indwave.label"}
	    if {$cbo_specbox} {
		catch {clearslits_ODF}
	    }
	}

        destroy $w_ 
    }

    
    #############################################################
    #  Name: sort_dialog
    #
    #  Description:
    #   Pop up a dialog to sort the list
    #############################################################
    #############################################################
    public method sort_dialog {} {
	$results_ sort_dialog
    }

    
    
    #############################################################
    #  Name: set_sort_cols
    #
    #  Description:
    #   This function is called when the user has selected columns 
    #   to sort the results by.
    #   The first arg is the sort columns, the second arg is the 
    #   order (increasing, decreasing)
    #############################################################
    #############################################################
    public method set_sort_cols {sort_cols sort_order} {
	if {"[$w_.cat sortcols]" != "$sort_cols" \
		|| "[$w_.cat sortorder]" != "$sort_order"} {
	    $w_.cat sortcols $sort_cols
	    $w_.cat sortorder $sort_order
	    cat::CatalogInfo::save {} $w_ 0
	    $results_ config -sort_cols $sort_cols -sort_order $sort_order
	    search
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
	$results_ select_columns
    }


    #############################################################
    #  Name: set_show_cols
    #
    #  Description:
    #   Called when the user has selected columns to show
    #############################################################
    #############################################################
    public method set_show_cols {cols} {
	set show [$w_.cat showcols]
	if {"$show" == ""} {
	    set show [$results_ get_headings]
	}
    }


    #############################################################
    #  Name: reset_table
    #
    #  Description:
    #    Reset table dialogs if needed
    #############################################################
    #############################################################
    public method reset_table {} {
	$results_ reset
	$results_ set_options {MORE PREVIEW more preview} Show 0
	$w_.cat showcols {}
	$w_.cat sortcols {}
	cat::CatalogInfo::save {} $w_ 0
    }

    
    
    #############################################################
    #  Name: clear
    #
    #  Description:
    #   Clear the table listing
    #############################################################
    #############################################################    
    public method clear {} {
	catch {$results_ clear}
    }

    
    #############################################################
    #  Name: print
    #
    #  Description:
    #   Pop up a dialog to print the table listing
    #############################################################
    #############################################################
    public method print {} {
	$results_ print_dialog
    }

    
    #############################################################
    #  Name: local_catalog
    #
    #  Description:
    #   Called from menu item "Load from file..." to load in a catalog.
    #   This function asks the user for the name of a local 
    #   catalog file and then opens a window for the catalog.
    #
    #   id is an optional unique id to be associated with a new
    #   catalog widget.
    #
    #   classname is the name of the vmAstroCat subclass to use to 
    #   create new catalog widgets (defaults to "vmAstroCat").
    #
    #   $debug is a flag set from the command line arg.
    #
    #   $tType is the catalog type, Object Table, Master OT.
    #
    #   $w should be the top level window of the caller, 
    #   if specified.
    #############################################################
    #############################################################
    public proc local_catalog {{id ""} {classname vmAstroCat} {debug 0} tType {w ""} {instType "NONE"}} {

	# Debuglevel is being set here because this is a procedure.
	global acDebugLevel
	set acDebugLevel 0

	set loadedImage [$target_image_ cget -file ]
	
	if {$loadedImage == ""} {
	    error_dialog "Please load a preimage file into Skycat before loading an object catalog."
	    return
	}

	# Set file pattern based on catalog type. 
	if { $tType == 1 } {
	    # .cat OT
	    set filePattern *.cat
	} elseif { $tType == 3 } {
	    # .fits OT	
	    set filePattern *.fits
	} elseif { $tType == 2 } {
	    # .cat ODF
	    set filePattern *ODF*.cat
	} elseif { $tType == 4 } {
	    # .fits ODF
	    set filePattern *ODF*.fits
	}
	
	if {$tType <= 4} {
	    # Prompt user to choose file to open.
	    # the $w argument for filename_dialog forces the dialog into the foreground
	    set file [filename_dialog [pwd ] $filePattern $w]
	    if {"$file" != ""} {
		if {[file isfile $file]} {
		    if {[catch {$astrocat_ check $file} msg]} {
			error_dialog $msg
		    } else {
			select_catalog $file local $id $classname $debug $tType $w $instType
		    }
		} else {
		    error_dialog "There is no file named '$file'"
		}
	    }
	}
    }
    
    
    #############################################################
    #  Name: save_as
    #
    #  Description:
    #   Save the current data to a local catalog
    #############################################################
    #############################################################
    public method save_as {} {
	$results_ save_as
    }


    #############################################################
    #  Name: add_to
    #
    #  Description:
    #   Add the rows in the current listing to a local catalog file
    #############################################################
    #############################################################
    public method add_to {} {
	$results_ add_to
    }

    
    #############################################################
    #  Name: add_selected
    #
    #  Description:
    #   Add the currently selected rows to a local catalog file
    #############################################################
    #############################################################
    public method add_selected {} {
	$results_ add_selected
    }

    
    #############################################################
    #  Name: remove_selected
    #
    #  Description:
    #   Remove the currently selected rows from a local catalog file
    #############################################################
    #############################################################
    public method remove_selected {} {
	$results_ remove_selected

	# update the display
	clear
	search
    }

    
    #############################################################
    #  Name: enter_new_object
    #
    #  Description:
    #   Pop up a dialog to enter the data for a new object for a local catalog
    #############################################################
    #############################################################
    public method enter_new_object {} {
	$results_ enter_new_object [code $this search]
    }

    
    #############################################################
    #  Name: edit_selected_object
    #
    #  Description:
    #   Pop up a window so that the user can edit the selected object(s)
    #############################################################
    #############################################################
    public method edit_selected_object {} {
	$results_ edit_selected_object [code $this search]
    }


    ####################################################################################################
    #  Name: drawBoundaries
    #
    #  Description:
    #   Reads in the information about field of view, possible gaps and the overall detector dimensions
    #   Toggles the corresponding boundaries depending on the status of the respective checkbuttons; 
    #   returns the spectral min and max coordinates available to determine possible spectral truncation
    ####################################################################################################
    ####################################################################################################
    public method drawBoundaries {} {
	
	global ::cbo_maskarea ::cbo_pointing

	set bg black
	set fg cyan
	set crosshair cyan
	set gapcol cyan
	set cbo_tag_maskarea cbo_ma
	set cbo_tag_detarea  cbo_da
	set cbo_tag_pointing cbo_po
	set cbo_tag_detgaps  cbo_dg

	set target_canvas_ .skycat1.image.imagef.canvas
	set target_image_ image2
	set home $::env(GMMPS)
	set instType $itk_option(-instType)

	# Declare a couple of lists that contain the vertices for the 
	# corners of fov, gaps, and detector dimensions
	set fov_x {}
	set fov_y {}
	set dim_x {}
	set dim_y {}
	set gap1_x {}
	set gap1_y {}
	set gap2_x {}
	set gap2_y {}
	# Counters for the vertices
	set n_fov 0
	set n_dim 0
	set n_gap1 0
	set n_gap2 0

	# everything known already:
	set fov_x  $FOVX
	set fov_y  $FOVY
	set gap1_x $GAP1X
	set gap1_y $GAP1Y
	set gap2_x $GAP2X
	set gap2_y $GAP2Y
	set dim_x  $DIMX
	set dim_y  $DIMY
	set n_fov  $N_FOV
	set n_dim  $N_DIM
	set n_gap1 $N_GAP1
	set n_gap2 $N_GAP2

	# SCHEME (likewise for GAP and DIM, but with 4 vertices only)
	# The 'X' in the center is represented by $CRPIX1 and CRPIX2
	# The corners Xi/Yi are in arcsec with respect to 'X'
	# GMOS has 12 vertices, check the respective detector fov.dat files in the config/ subdir
	#
	#
	#       X4-Y4 ----- X5-Y5
	#       /              \
	#      /                \
	#   X3-Y3              X6-Y6
	#     |                  | 
	#     |         X        | 
	#     |                  | 
	#   X2-Y2              X7-Y7
	#      \                /
	#       \              /
	#       X1-Y1 ----- X8-Y8


	# Convert the coordinates so that we can plot them

	set xtmp 0
	set ytmp 0

	set xtext [ expr [lindex $dim_x 0] + 50]
	set ytext [ expr [lindex $dim_y 0] + 50]
	$target_image_ convert coords $xtext $ytext image xtext ytext canvas

	for {set i 0} {$i < $n_fov} {incr i 1} {
	    $target_image_ convert coords [lindex $fov_x $i] [lindex $fov_y $i] image xtmp ytmp canvas
	    set fov_x [lreplace $fov_x $i $i $xtmp]
	    set fov_y [lreplace $fov_y $i $i $ytmp]
	}

	for {set i 0} {$i < $n_dim} {incr i 1} {
	    $target_image_ convert coords [lindex $dim_x $i] [lindex $dim_y $i] image xtmp ytmp canvas
	    set dim_x [lreplace $dim_x $i $i $xtmp]
	    set dim_y [lreplace $dim_y $i $i $ytmp]
	}

	if {$n_gap1 == 4} {
	    for {set i 0} {$i < $n_gap1} {incr i 1} {
		$target_image_ convert coords [lindex $gap1_x $i] [lindex $gap1_y $i] image xtmp ytmp canvas
		set gap1_x [lreplace $gap1_x $i $i $xtmp]
		set gap1_y [lreplace $gap1_y $i $i $ytmp]
	    }
	}

	if {$n_gap2 == 4} {
	    for {set i 0} {$i < $n_gap2} {incr i 1} {
		$target_image_ convert coords [lindex $gap2_x $i] [lindex $gap2_y $i] image xtmp ytmp canvas
		set gap2_x [lreplace $gap2_x $i $i $xtmp]
		set gap2_y [lreplace $gap2_y $i $i $ytmp]
	    }
	}

	# Plot the stuff
	# This depends on the value of the variables associated with the CheckBoxes (called cbo_something)
	set n_fov_mod [expr $n_fov - 1]
	set n_dim_mod [expr $n_dim - 1]
	set n_gap1_mod [expr $n_gap1 - 1]
	set n_gap2_mod [expr $n_gap2 - 1]

	# Toggle the area available for slitlets
	if {$cbo_maskarea == 1} {
	    for {set i 0} {$i < $n_fov} {incr i 1} {
		if {$i < $n_fov_mod} {
		    set ii [expr $i + 1]
		} else {
		    set ii 0
		}
		$target_canvas_ create line \
		    [lindex $fov_x $i]  [lindex $fov_y $i] \
		    [lindex $fov_x $ii] [lindex $fov_y $ii] \
		    -fill $fg -width 3 -tags $cbo_tag_maskarea
	    }
	} else {
	    $target_canvas_ delete cbo_ma
	}

	# Toggle the detector dimensions
	for {set i 0} {$i < $n_dim} {incr i 1} {
	    if {$i < $n_dim_mod} {
		set ii [expr $i + 1]
	    } else {
		set ii 0
	    }
	    $target_canvas_ create line \
		[lindex $dim_x $i]  [lindex $dim_y $i] \
		[lindex $dim_x $ii] [lindex $dim_y $ii] \
		-fill white -width 2 -tags $cbo_tag_detarea
	}
	
	# A ID label at the lower left to indicate the instrument
	$target_canvas_ create text $xtext $ytext -anchor w -font {Arial 16} \
	    -text $instType -tags $cbo_tag_detarea -fill white
	
	# Toggle the 1st gap (if any)
	if {$n_gap1 == 4} {
	    $target_canvas_ create rect \
		[lindex $gap1_x 0] [lindex $gap1_y 1] \
		[lindex $gap1_x 2] [lindex $gap1_y 3] \
		-outline $gapcol -fill $gapcol -stipple gray12 -width 1 -tags $cbo_tag_detgaps
	}

	# Toggle the 2nd gap (if any)
	if {$n_gap2 == 4} {
	    $target_canvas_ create rect \
		[lindex $gap2_x 0] [lindex $gap2_y 1] \
		[lindex $gap2_x 2] [lindex $gap2_y 3] \
		-outline $gapcol -fill $gapcol -stipple gray12 -width 1 -tags $cbo_tag_detgaps
	}

	# Elements we need for the center mark cross hair
	set cw 20
	set circle1_ulx [expr $CRPIX1-$cw]
	set circle1_uly [expr $CRPIX2+$cw]
	set circle1_lrx [expr $CRPIX1+$cw]
	set circle1_lry [expr $CRPIX2-$cw]

	set line1_x1 $CRPIX1
	set line1_x2 $CRPIX1
	set line1_y1 [expr $CRPIX2 + 1 * $cw]
	set line1_y2 [expr $CRPIX2 + 2 * $cw]
	set line2_x1 $CRPIX1
	set line2_x2 $CRPIX1
	set line2_y1 [expr $CRPIX2 - 1 * $cw]
	set line2_y2 [expr $CRPIX2 - 2 * $cw]
	set line3_x1 [expr $CRPIX1 - 1 * $cw]
	set line3_x2 [expr $CRPIX1 - 2 * $cw]
	set line3_y1 $CRPIX2
	set line3_y2 $CRPIX2
	set line4_x1 [expr $CRPIX1 + 1 * $cw]
	set line4_x2 [expr $CRPIX1 + 2 * $cw]
	set line4_y1 $CRPIX2
	set line4_y2 $CRPIX2

	$target_image_ convert coords $circle1_ulx $circle1_uly image circle1_ulx circle1_uly canvas
	$target_image_ convert coords $circle1_lrx $circle1_lry image circle1_lrx circle1_lry canvas
	$target_image_ convert coords $line1_x1 $line1_y1 image line1_x1 line1_y1 canvas
	$target_image_ convert coords $line1_x2 $line1_y2 image line1_x2 line1_y2 canvas
	$target_image_ convert coords $line2_x1 $line2_y1 image line2_x1 line2_y1 canvas
	$target_image_ convert coords $line2_x2 $line2_y2 image line2_x2 line2_y2 canvas
	$target_image_ convert coords $line3_x1 $line3_y1 image line3_x1 line3_y1 canvas
	$target_image_ convert coords $line3_x2 $line3_y2 image line3_x2 line3_y2 canvas
	$target_image_ convert coords $line4_x1 $line4_y1 image line4_x1 line4_y1 canvas
	$target_image_ convert coords $line4_x2 $line4_y2 image line4_x2 line4_y2 canvas

	
	# Toggle the central crosshair
	if {$cbo_pointing == 1} {
	    $target_canvas_ create oval $circle1_ulx $circle1_uly $circle1_lrx $circle1_lry \
		-outline $crosshair -width 2 -tags $cbo_tag_pointing
	    $target_canvas_ create line $line1_x1 $line1_y1 $line1_x2 $line1_y2 \
		-fill $crosshair -width 2 -tags $cbo_tag_pointing
	    $target_canvas_ create line $line2_x1 $line2_y1 $line2_x2 $line2_y2 \
		-fill $crosshair -width 2 -tags $cbo_tag_pointing
	    $target_canvas_ create line $line3_x1 $line3_y1 $line3_x2 $line3_y2 \
		-fill $crosshair -width 2 -tags $cbo_tag_pointing
	    $target_canvas_ create line $line4_x1 $line4_y1 $line4_x2 $line4_y2 \
		-fill $crosshair -width 2 -tags $cbo_tag_pointing
	} else {
	    $target_canvas_ delete cbo_po
	}
    }


    #############################################################
    #  Name: dist_line_segment
    #
    #  Description:
    #  This function returns the minimum distance of a point to
    #  a line segment.
    #############################################################
    #############################################################
    public method dist_line_segment {xp yp x1 y1 x2 y2} {

	set px [expr $x2-$x1]
	set py [expr $y2-$y1]

	set D [expr $px*$px + $py*$py]
	set u [expr (($xp - $x1) * $px + ($yp - $y1) * $py) / $D]

	if {$u > 1.} {
	    set u 1.
	} elseif {$u < 0.} {
	    set u 0.
	}

	set x  [expr $x1 + $u * $px]
	set y  [expr $y1 + $u * $py]
	set dx [expr $x - $xp]
	set dy [expr $y - $yp]

	return [expr sqrt($dx*$dx + $dy*$dy)]
    }
    
    #############################################################
    #  Name: check_proximity
    #
    #  Description:
    #  This function checks whether an alignment star box is 
    #  close to a gap or boundary
    #############################################################
    #############################################################
    public method check_proximity {xobj yobj id {maskcheck ""}} {
	
	set instType $itk_option(-instType)
	set home $::env(GMMPS)

	set error_gap ""
	set error_boundary ""
	set testvar 0.0

	# The size of our acquisition boxes is 2 arcsecs, in pixel:
	set acq_box_size [expr 2.0 / $PIXSCALE]

	# Check box distance from gaps (distances measured in pixels!)
	if {$N_GAP1 > 0} {
	    if {$DISPDIR == "horizontal"} {
		set gap1 [lindex $GAP1X 0]
		set gap2 [lindex $GAP1X 3]
		set testvar $xobj
		set dist1 [expr abs($testvar - $gap1)]
		set dist2 [expr abs($testvar - $gap2)]
	    } else {
		set gap1 [lindex $GAP1Y 0]
		set gap2 [lindex $GAP1Y 1]
		set testvar $yobj
		set dist1 [expr abs($testvar - $gap1)]
		set dist2 [expr abs($testvar - $gap2)]
	    } 
	    # If close (star within 4 arcsec)
	    if {$dist1 <= [expr 2.0 * $acq_box_size] || 
		$dist2 <= [expr 2.0 * $acq_box_size]} {
		set error_gap "WARNING: Acq star $id within 4\" of gap.\n"
	    }
	    # If truncated, or star within less than 2 arcsec from gap
	    if {$dist1 <= [expr 1.0 * $acq_box_size] || 
		$dist2 <= [expr 1.0 * $acq_box_size] ||
		($testvar >= $gap1 && $testvar <= $gap2)} {
		set error_gap "ERROR: Acq star $id too close to gap!\n"
	    }
	}
	if {$N_GAP2 > 0} {
	    if {$DISPDIR == "horizontal"} {
		set gap1 [lindex $GAP2X 0]
		set gap2 [lindex $GAP2X 3]
		set testvar $xobj
		set dist1 [expr abs($testvar - $gap1)]
		set dist2 [expr abs($testvar - $gap2)]
	    } else {
		set gap1 [lindex $GAP2Y 0]
		set gap2 [lindex $GAP2Y 1]
		set testvar $yobj
		set dist1 [expr abs($testvar - $gap1)]
		set dist2 [expr abs($testvar - $gap2)]
	    } 
	    # If close (star within 4 arcsec)
	    if {$dist1 <= [expr 2.0 * $acq_box_size] || 
		$dist2 <= [expr 2.0 * $acq_box_size]} {
		set error_gap "WARNING: Acq star $id within 4\" of gap.\n"
	    }
	    # If truncated, or star within 2 arcsec from gap
	    if {$dist1 <= [expr 1.0 * $acq_box_size] || 
		$dist2 <= [expr 1.0 * $acq_box_size] ||
		($testvar >= $gap1 && $testvar <= $gap2)} {
		set error_gap "ERROR: Acq star $id too close to gap!\n"
	    }
	}

	# Check box distance from mask area boundary

	# Smallest distance to the mask area boundary
	set n_fov_mod [expr $N_FOV - 1]
	for {set i 0} {$i < $N_FOV} {incr i 1} {
	    if {$i < $n_fov_mod} {
		set ii [expr $i + 1]
	    } else {
		set ii 0
	    }
	    # Distance from acq star to line made by indices i and ii
	    set x1 [lindex $FOVX $i]
	    set x2 [lindex $FOVX $ii]
	    set y1 [lindex $FOVY $i]
	    set y2 [lindex $FOVY $ii]

	    set distance [dist_line_segment $xobj $yobj $x1 $y1 $x2 $y2]

	    if {$distance <= [expr 2.0 * $acq_box_size]} {
		set error_boundary "WARNING: Acq star $id within 4\" of boundary.\n"
	    }
	    if {$distance <= [expr 1.0 * $acq_box_size]} {
		set error_boundary "ERROR: Acq star $id too close to boundary!\n"
	    }
	}
	
	# Amplifier mode (for internal mask checking purposes, only)
	if {$maskcheck != ""} {
	    set ampresult ""
	    if {$N_AMP > 0} {
		for {set i 0} {$i < $N_AMP} {incr i} {
		    set ampi [lindex $AMP $i]
		    if {$DISPDIR == "horizontal"} {
			set dist [expr abs($xobj - $ampi)]
		    } else {
			set dist [expr abs($yobj - $ampi)]
		    }
		    # Flag if within 1"
		    if {$dist <= [expr 1.0 / $PIXSCALE]} {
			set ampresult "Slit $id: possibly on top of amplifier boundary.\n"
		    }
		}
	    }

	    if {$N_GAP1 > 0} {
		if {$DISPDIR == "horizontal"} {
		    set gap1 [lindex $GAP1X 0]
		    set gap2 [lindex $GAP1X 3]
		    set testvar $xobj
		    set dist1 [expr abs($testvar - $gap1)]
		    set dist2 [expr abs($testvar - $gap2)]
		} else {
		    set gap1 [lindex $GAP1Y 0]
		    set gap2 [lindex $GAP1Y 1]
		    set testvar $yobj
		    set dist1 [expr abs($testvar - $gap1)]
		    set dist2 [expr abs($testvar - $gap2)]
		}
		# Flag if within 1"
		if {$dist1 <= [expr 1.0 / $PIXSCALE] ||
		    $dist2 <= [expr 1.0 / $PIXSCALE] ||
		    ($testvar >= $gap1 && $testvar <= $gap2)} {
		    set ampresult "Slit $id: close to, partially or fully hidden by detector gap.\n"
		}
	    }
	    if {$N_GAP2 > 0} {
		if {$DISPDIR == "horizontal"} {
		    set gap1 [lindex $GAP2X 0]
		    set gap2 [lindex $GAP2X 3]
		    set testvar $xobj
		    set dist1 [expr abs($testvar - $gap1)]
		    set dist2 [expr abs($testvar - $gap2)]
		} else {
		    set gap1 [lindex $GAP2Y 0]
		    set gap2 [lindex $GAP2Y 1]
		    set testvar $yobj
		    set dist1 [expr abs($testvar - $gap1)]
		    set dist2 [expr abs($testvar - $gap2)]
		}
		# Flag if within 1"
		if {$dist1 <= [expr 1.0 / $PIXSCALE] ||
		    $dist2 <= [expr 1.0 / $PIXSCALE] ||
		    ($testvar >= $gap1 && $testvar <= $gap2)} {
		    set ampresult "Slit $id: close to, partially or fully hidden by detector gap.\n"
		}
	    }
	    return $ampresult
	}

	# Return the concatenated error string
	return $error_gap$error_boundary
    }
    

    #############################################################
    #  Name: plotSlit
    #
    #  Description:
    #  Draws a slit
    #############################################################
    #############################################################
    protected method plotSlit {x y dx dy tilt prior obj_id tags tags_ind} {

	set target_canvas_ .skycat1.image.imagef.canvas

	# x y:   slit center
	# dx dy: half slit dimensions

	##################################################
	#   Slit vertex indices
	#
	#    GMOS                   F2
	#
	#   1 __ 2
	#    |  |           1 ________________ 2
	#    |	|            |                |
	#    |  |            |________________|
	#    |  |           4                  3
	#    |__|
	#   4    3
	##################################################
	
	# Pi/180
	set rad 0.01745329252

	# The slit vertices; dtilt is a non-zero offset at the end of the slit in case of non-zero tilt
	if {$DISPDIR == "horizontal"} {
	    set dtilt [expr $dy * tan($tilt * $rad)]
	    set x1 [expr $x - $dtilt - $dx]
	    set x2 [expr $x - $dtilt + $dx]
	    set x3 [expr $x + $dtilt + $dx]
	    set x4 [expr $x + $dtilt - $dx]
	    set y1 [expr $y + $dy]
	    set y2 [expr $y + $dy]
	    set y3 [expr $y - $dy]
	    set y4 [expr $y - $dy]
	} else {
	    set dtilt [expr $dx * tan($tilt * $rad)]
	    set x1 [expr $x - $dx]
	    set x2 [expr $x + $dx]
	    set x3 [expr $x + $dx]
	    set x4 [expr $x - $dx]
	    set y1 [expr $y - $dtilt + $dy]
	    set y2 [expr $y + $dtilt + $dy]
	    set y3 [expr $y + $dtilt - $dy]
	    set y4 [expr $y - $dtilt - $dy]
	}

	# Variables in canvas coordinates have a _cv appended.
	# Unfortunately, the rest of GMMPS does not make this distinction very clearly,
	# which can cause you quite some headaches when it comes to fixing plotting issues.
	$target_image_ convert coords $x1 $y1 image x1_cv y1_cv canvas
	$target_image_ convert coords $x2 $y2 image x2_cv y2_cv canvas
	$target_image_ convert coords $x3 $y3 image x3_cv y3_cv canvas
	$target_image_ convert coords $x4 $y4 image x4_cv y4_cv canvas
	$target_image_ convert coords $x $y image x_cv y_cv canvas

	if {$prior == 0} {
	    set slitcolor magenta
	} else {
	    set slitcolor yellow
	}

	# Draw the slit
	$target_canvas_ create line $x1_cv $y1_cv $x2_cv $y2_cv -fill $slitcolor -width 2 -tags "$tags $tags_ind " 
	$target_canvas_ create line $x2_cv $y2_cv $x3_cv $y3_cv -fill $slitcolor -width 2 -tags "$tags $tags_ind " 
	$target_canvas_ create line $x3_cv $y3_cv $x4_cv $y4_cv -fill $slitcolor -width 2 -tags "$tags $tags_ind " 
	$target_canvas_ create line $x4_cv $y4_cv $x1_cv $y1_cv -fill $slitcolor -width 2 -tags "$tags $tags_ind " 

	# Show the object ID
	if {$DISPDIR == "horizontal"} {
	    $target_canvas_ create text [expr $x_cv+8] $y_cv -anchor w -font {Arial 12 bold} \
		-text $obj_id -tags "$tags $tags_ind" -fill orange
	} else {
	    $target_canvas_ create text $x_cv [expr $y_cv+8] -anchor n -font {Arial 12 bold} \
		-text $obj_id -tags "$tags $tags_ind" -fill orange
	}
    }
    

    #############################################################
    #  Name: transform_gmos_x_old2new (1x1 binning!)
    #
    #  Description:
    #  Transforms GMOS EEV pixel coords to GMOS HAM coords
    #############################################################
    #############################################################
    public method transform_gmos_x_old2new {x_old nativeScale instType} {
	if {$instType == "GMOS-S"} {
	    set offset 295.04
	} else {
	    set offset 304.18
	}
	set x_new [expr $offset + $x_old * $PIXSCALE / $nativeScale ]
	return $x_new
    }

    #############################################################
    #  Name: transform_gmos_y_old2new (1x1 binning!)
    #
    #  Description:
    #  Transforms GMOS EEV pixel coords to GMOS HAM coords
    #############################################################
    #############################################################
    public method transform_gmos_y_old2new {y_old nativeScale instType} {
	if {$instType == "GMOS-S"} {
	    set offset 14.4
	} else {
	    set offset -7.26
	}
	set y_new [expr -1. * $offset + $y_old * $PIXSCALE / $nativeScale ]
	return $y_new
    }

    #############################################################
    #  Name: transform_gmos_x_new2old (1x1 binning!)
    #
    #  Description:
    #  Transforms GMOS HAM pixel coords to GMOS EEV coords
    #############################################################
    #############################################################
    public method transform_gmos_x_new2old {x_new nativeScale instType} {
	if {$instType == "GMOS-S"} {
	    set offset 295.04
	} else {
	    set offset 304.18
	}
	set x_old [expr ($x_new - $offset) * $nativeScale / $PIXSCALE ]
	return $x_old
    }

    #############################################################
    #  Name: transform_gmos_y_new2old (1x1 binning!)
    #
    #  Description:
    #  Transforms GMOS HAM pixel coords to GMOS EEV coords
    #############################################################
    #############################################################
    public method transform_gmos_y_new2old {y_new nativeScale instType} {
	if {$instType == "GMOS-S"} {
	    set offset 14.4
	} else {
	    set offset -7.26
	}
	set y_old [expr ($y_new + $offset) * $nativeScale / $PIXSCALE ]
	return $y_old
    }

    #############################################################
    #  Name: isnumeric
    #
    #  Description:
    #  Check whether a string is numeric
    #############################################################
    #############################################################
    proc isnumeric value {
	if {![catch {expr {abs($value)}}]} {
	    return 1
	}
	set value [string trimleft $value 0]
	if {![catch {expr {abs($value)}}]} {
	    return 1
	}
	return 0
    }


    #############################################################
    #  Name: display_overlays
    #
    #  Description:
    #  reads the output of gemwm and displays the various
    #  overlays
    #############################################################
    #############################################################
    protected method display_overlays {tags tags_specbox tags_2ndorder tags_shading \
					   tags_showwave tags_indwave spect_disp \
					   spect_lmin spect_lmax spect_cwl grating \
					   ODF_shuffleMode ODF_shuffleSize ODF_binning} {
	
	global ::cbo_shading ::cbo_showwave ::cbo_acqonly ::cbo_indwave 
	global outsidewarning_shown R600warning_shown
	
	set target_canvas_ .skycat1.image.imagef.canvas
	set instType $itk_option(-instType)

	# do not print wavelength labels closer than 30 pixels to the CWL marks
	# no extra factor 10 is because this is done in nm
	set minsep_cwl [expr 30*$spect_disp]

	# do not print wavelength labels closer than 80 pixels to gap
	# extra factor 10 is because this is done in Angstrom
	set minsep_gap [expr 60*$spect_disp*10]
	
	# Where to draw wavelength lines and labels, depending on dispersion factor
	if {$instType == "GMOS-N" || $instType == "GMOS_S"} {
	    set offset_cv 5
	} else {
	    set offset_cv 10
	}

	# Open the output of gemwm
	catch { set gemwm_output [open "gemwm.output" r] }
	
	set cwl_outside_spectrum_global "FALSE"

	# Declare a couple of lists that contain the output
	set type  {}
	set xslit {}
	set yslit {}
	set label {}
	set value {}
	set nslit 0
	set rad 0.01745329252

	set outsidewarning ""
	set blank " "

	set nativeScale 0.0

	if {$instType == "GMOS-N"} {
	    set nativeScale 0.0807
	} elseif {$instType == "GMOS-S"} {
	    set nativeScale 0.0800
	} elseif {$instType == "F2"} {
	    set nativeScale 0.1792
	} elseif {$instType == "F2-AO"} {
	    # needs to be verified and must be the same as the numeric value used in Gemini/IRAF
	    set nativeScale 0.0896
	} else {
	    error_dialog "Unknown instrument type: $instType"
	    return
	}

	# This might cause slight inaccuracies in the overlay of spectral boxes, if the
	# native pixel scale is not exactly the same as the true pixel scale.

	# Wavelength models are for 1x1 binning. If the current image has a different plate scale, then
	# we need to transform the output of gemwm.
	set corrfac [expr $nativeScale / $PIXSCALE]

	# Get the gap x coordinates (for wavelength calculations)
	# F2 will never have a gap keyword in gemwm.output, hence no case distinction necessary
	if {$instType == "GMOS-N" || $instType == "GMOS-S"} {
	    set detgap0 [lindex $GAP1X 0]
	    set detgap1 [lindex $GAP1X 2]
	    set detgap2 [lindex $GAP2X 0]
	    set detgap3 [lindex $GAP2X 2]
	    set detgaps [list $detgap0 $detgap1 $detgap2 $detgap3]
	}
	
	# Plot the wavelength grid and other stuff
	while {[gets $gemwm_output line] >= 0} {
	    # Read the output of gemwm
	    set type   [lindex $line 0]
	    # We deal with order overlap elsewhere (in display_overlays_order)
	    if {$type == "2ndorder"} {
		continue
	    }		
	    if {$instType == "GMOS-N" || $instType == "GMOS-S" } {
		set xslit  [lindex $line 1]
		set yslit  [lindex $line 2]
		set dimx   [lindex $line 5]
		set dimy   [lindex $line 6]
		set xshift [lindex $line 7]
		set yshift [lindex $line 8]
	    } else {
		set xslit  [lindex $line 2]
		set yslit  [lindex $line 1]
		set dimx   [lindex $line 5]
		set dimy   [lindex $line 6]
		set xshift [lindex $line 8]
		set yshift [lindex $line 7]
	    }

	    set label  [lindex $line 3]
	    set value  [lindex $line 4]
	    # OVERLOADING columns 5, 7, 8!
	    # Elements in gemwm.output columns have multiple meaning depending on keyword.
	    # Sorry about that.
	    set gapid  [lindex $line 5]
	    set spec_min [lindex $line 7]
	    set spec_max [lindex $line 8]

	    set slittilt [lindex $line 9]
	    set obj_id   [lindex $line 10]
	    set indlabel [lindex $line 11]

	    # Model calculations were done for 1x1 binning; correct if images have different pixel scale.

	    # HACK! For a long time, GMOS pseudo-images were still in the
	    # GMOS-S EEV/E2VDD geometry and pixel scale even after the Hamamatsu upgrade.
	    # For backwards compatibility we need the following.
	    # This takes care of the pixel scale, too.
	    if {($instType == "GMOS-S" && $NAXIS1 == "6218" && $NAXIS2 == "4608") ||
		($instType == "GMOS-N" && $NAXIS1 == "6218" && $NAXIS2 == "4608")} {
		set xslit [transform_gmos_x_new2old $xslit $nativeScale $instType]
		set yslit [transform_gmos_y_new2old $yslit $nativeScale $instType]
		set spec_min [transform_gmos_x_new2old $spec_min $nativeScale $instType]
		set spec_max [transform_gmos_x_new2old $spec_max $nativeScale $instType]
		if {$type != "gap"} {
		    set value [transform_gmos_x_new2old $value $nativeScale $instType]
		} else {
		    set label [transform_gmos_x_new2old $label $nativeScale $instType]
		}
	    } else {	
		set xslit  [expr $xslit*$corrfac]
		set yslit  [expr $yslit*$corrfac]
		set xshift [expr $xshift*$corrfac]
		set yshift [expr $yshift*$corrfac]
		set dimx   [expr $dimx*$corrfac]
		set dimy   [expr $dimy*$corrfac]
		set spec_min [expr $spec_min*$corrfac]
		set spec_max [expr $spec_max*$corrfac]
		if {$type != "gap"} {
		    set value [expr $value*$corrfac]
		} else {
		    set label [expr $label*$corrfac]
		}
	    }

	    # catch nonsense due to wavelength inversion
	    if {$spec_min < $spec_max} {
		if {$spec_min < 0} {
		    set spec_min 1e4
		}
		if {$spec_max > 0} {
		    set spec_max -1e4
		}
	    }

	    # Don't plot anything if the spectrum is entirely outside the detector area,
	    # or other nonsense appears
	    # spec_max is the red end of the spectrum in image coordinates
	    # spec_min is the blue end of the spectrum in image coordinates
	    if {$type == "box" || $type == "acq"} {
		if {$DISPDIR == "horizontal"} {
		    if {$spec_max > $DETXMAX || $spec_min < $DETXMIN} {
			set outsidewarning $outsidewarning$obj_id$blank
			continue
		    }
		} else {
		    if {$spec_max > $DETYMAX || $spec_min < $DETYMIN} {
			set outsidewarning $outsidewarning$obj_id$blank
			continue
		    }
		}
	    }

	    # truncate at the detector boundary
	    set spec_min [truncate_spec $spec_min "blue"]
	    set spec_max [truncate_spec $spec_max "red" ]
	    
	    # the vertices of the slits
	    set slit_xmin [expr $xslit - $dimx]
	    set slit_xmax [expr $xslit + $dimx]
	    set slit_ymin [expr $yslit - $dimy]
	    set slit_ymax [expr $yslit + $dimy]

	    # Convert coordinates to canvas system (need them at many places)
	    set tmp 0
	    $target_image_ convert coords $slit_xmin $slit_ymin image slit_xmin_cv slit_ymin_cv canvas
	    $target_image_ convert coords $slit_xmax $slit_ymax image slit_xmax_cv slit_ymax_cv canvas
	    if {$DISPDIR == "horizontal"} {
		$target_image_ convert coords $spec_min $slit_ymin image spec_xmin_cv spec_ymin_cv canvas
		$target_image_ convert coords $spec_max $slit_ymax image spec_xmax_cv spec_ymax_cv canvas
		$target_image_ convert coords $value $tmp image value_cv tmp canvas
	    } else {
		$target_image_ convert coords $slit_xmin $spec_min image spec_xmin_cv spec_ymin_cv canvas
		$target_image_ convert coords $slit_xmax $spec_max image spec_xmax_cv spec_ymax_cv canvas
		$target_image_ convert coords $tmp $value image tmp value_cv canvas
	    }

	    # Acquisition stars have different colors and less dense stipples
	    if {$type == "acq"} {
		set stipple gray25
		set acq_color magenta
		set proximity_alert [check_proximity $xslit $yslit $obj_id]
		if {[string match *within* $proximity_alert] == 1} { 
		    set acq_color yellow
		}
		set fill $acq_color
		set footprintcolor $acq_color
	    } else {
		set stipple gray12
		set fill #999
		set footprintcolor GhostWhite
	    }

	    set cwl_outside_spectrum "FALSE"
	    set slit_outside_spectrum "FALSE"

	    # what do do if we are looking at other things than a gap
	    if {$type != "gap"} {

		if {$type == "cwl" && ($spect_cwl < $spect_lmin || $spect_cwl > $spect_lmax)} {
		    set cwl_outside_spectrum "TRUE"
		    set cwl_outside_spectrum_global "TRUE"
		}
		if {$type == "box" || $type == "acq"} {
		    if {$DISPDIR == "horizontal"} {
			if {$xslit > $spec_min || $xslit < $spec_max} {
			    set slit_outside_spectrum "TRUE"
			}
		    } else {
			if {$yslit > $spec_min || $yslit < $spec_max} {
			    set slit_outside_spectrum "TRUE"
			}
		    }
		}

		# markers
		if {$type == "grid"} {
		    set markercolor yellow
		} elseif {$type == "cwl"} {
		    set markercolor red
		} elseif {$type == "indwave"} {
		    set markercolor green
		} elseif {$type == "box"} {
		    set markercolor white
		}

		# The slit vertices; dtilt is a non-zero offset at the end of the slit in case of non-zero tilt
		# tilt_dcwl (offset by which we have to shift the line connecting the CWL with the object)
		
		# Initialize the variables
		set dtilt   0.
		set tilt_dcwl 0.
		if {$DISPDIR == "horizontal"} {
		    set dtilt  [expr $dimy * tan ($slittilt * $rad)]
		    set tilt_dcwl [expr $dtilt * $yshift / $dimy]
		} else {
		    set dtilt   [expr $dimx * tan ($slittilt * $rad)]
		    set tilt_dcwl [expr $dtilt * $xshift / $dimx]
		}

		# WAVELENGTHS (in pixel coordinates)
		if {$DISPDIR == "horizontal"} {
		    set wave_x1 [expr { $value - $dtilt }]
		    set wave_x2 [expr { $value + $dtilt }]
		    set wave_y1 $slit_ymax
		    set wave_y2 $slit_ymin
		    if {$type=="grid" && ($wave_x1 > $DETXMAX || $wave_x2 > $DETXMAX || 
					  $wave_x1 < $DETXMIN || $wave_x2 < $DETXMIN)} {
			continue
		    }
		} else {
		    set wave_x1 $slit_xmax
		    set wave_x2 $slit_xmin
		    set wave_y1 [expr { $value + $dtilt }]
		    set wave_y2 [expr { $value - $dtilt }]
		    if {$type=="grid" && ($wave_y1 > $DETYMAX || $wave_y2 > $DETYMAX ||
					  $wave_y1 < $DETYMIN || $wave_y2 < $DETYMIN)} {
			continue
		    }
		}

		# Convert coordinates to canvas system (need them at many places)
		$target_image_ convert coords $wave_x1 $wave_y1 image wave_x1_cv wave_y1_cv canvas
		$target_image_ convert coords $wave_x2 $wave_y2 image wave_x2_cv wave_y2_cv canvas

		# Draw hashed areas
		if {$cbo_shading == 1 && ($type == "box" || $type == "acq") } {
		    if {$type != "acq" && $cbo_acqonly == 1} {
			continue
		    }

		    # Hashed area left and right of the slit
		    if {$DISPDIR == "horizontal"} {
			# bluewards of the slit
			set min_shade1 [minval [expr $spec_min - $dtilt] [expr $spec_min + $dtilt]]
			set max_shade1 [maxval [expr $xslit + $dimx - $dtilt] [expr $xslit + $dimx + $dtilt]]
			# redwards of the slit
			set max_shade2 [maxval [expr $spec_max - $dtilt] [expr $spec_max + $dtilt]]
			set min_shade2 [minval [expr $xslit - $dimx - $dtilt] [expr $xslit - $dimx + $dtilt]]

			$target_image_ convert coords $min_shade1 $tmp image min_shade1_cv tmp canvas
			$target_image_ convert coords $min_shade2 $tmp image min_shade2_cv tmp canvas
			$target_image_ convert coords $max_shade1 $tmp image max_shade1_cv tmp canvas
			$target_image_ convert coords $max_shade2 $tmp image max_shade2_cv tmp canvas
			if {$cwl_outside_spectrum == "FALSE" && $slit_outside_spectrum == "FALSE"} {
			    $target_canvas_ create rect $max_shade1_cv $spec_ymax_cv $min_shade1_cv $spec_ymin_cv \
				-fill $fill -stipple $stipple -width 0 -tags "$tags $tags_shading"
			    $target_canvas_ create rect $max_shade2_cv $spec_ymax_cv $min_shade2_cv $spec_ymin_cv \
				-fill $fill -stipple $stipple -width 0 -tags "$tags $tags_shading"
			} else {
			    $target_canvas_ create rect $min_shade1_cv $spec_ymax_cv $max_shade2_cv $spec_ymin_cv \
				-fill $fill -stipple $stipple -width 0 -tags "$tags $tags_shading"
			}
		    } else {
			# bluewards of the slit
			set min_shade1 [minval [expr $spec_min - $dtilt] [expr $spec_min + $dtilt]]
			set max_shade1 [maxval [expr $yslit + $dimy - $dtilt] [expr $yslit + $dimy + $dtilt]]
			# redwards of the slit
			set max_shade2 [maxval [expr $spec_max - $dtilt] [expr $spec_max + $dtilt]]
			set min_shade2 [minval [expr $yslit - $dimy - $dtilt] [expr $yslit - $dimy + $dtilt]]

			# Hashed area above and below the slit
			$target_image_ convert coords $tmp $min_shade1 image tmp min_shade1_cv canvas
			$target_image_ convert coords $tmp $min_shade2 image tmp min_shade2_cv canvas
			$target_image_ convert coords $tmp $max_shade1 image tmp max_shade1_cv canvas
			$target_image_ convert coords $tmp $max_shade2 image tmp max_shade2_cv canvas
			if {$cwl_outside_spectrum == "FALSE" && $slit_outside_spectrum == "FALSE"} {
			    $target_canvas_ create rect $spec_xmin_cv $max_shade1_cv $spec_xmax_cv $min_shade1_cv \
				-fill $fill -stipple $stipple -width 0 -tags "$tags $tags_shading"
			    $target_canvas_ create rect $spec_xmin_cv $max_shade2_cv $spec_xmax_cv $min_shade2_cv \
				-fill $fill -stipple $stipple -width 0 -tags "$tags $tags_shading"
			} else {
			    $target_canvas_ create rect $spec_xmin_cv $max_shade2_cv $spec_xmax_cv $min_shade1_cv \
				-fill $fill -stipple $stipple -width 0 -tags "$tags $tags_shading"
			}
		    }
		}
		
		# Draw the spectrum box (composite of four lines, because tilted in the general case)
		if {$type == "box" || $type == "acq"} {
		    # Continue if we plot acq stars only, and the current one is not an acq star
		    if {$type != "acq" && $cbo_acqonly == 1} {
			continue
		    }

		    # SPECTRAL BOXES (same transformations as for the wavelengths above)
		    if {$DISPDIR == "horizontal"} {
			set x1 [expr $spec_min - $dtilt]
			set x2 [expr $spec_max - $dtilt]
			set x3 [expr $spec_max + $dtilt]
			set x4 [expr $spec_min + $dtilt]
			set y1 $slit_ymax
			set y2 $slit_ymax
			set y3 $slit_ymin
			set y4 $slit_ymin
		    } else {
			set x1 $slit_xmin
			set x2 $slit_xmax
			set x3 $slit_xmax
			set x4 $slit_xmin
			set y1 [expr $spec_max - $dtilt]
			set y2 [expr $spec_max + $dtilt]
			set y3 [expr $spec_min + $dtilt]
			set y4 [expr $spec_min - $dtilt]
		    }
		
		    $target_image_ convert coords $x1 $y1 image x1_cv y1_cv canvas
		    $target_image_ convert coords $x2 $y2 image x2_cv y2_cv canvas
		    $target_image_ convert coords $x3 $y3 image x3_cv y3_cv canvas
		    $target_image_ convert coords $x4 $y4 image x4_cv y4_cv canvas

		    $target_canvas_ create line $x1_cv $y1_cv $x2_cv $y2_cv -fill $footprintcolor \
			-width 1 -tags "$tags $tags_specbox"
		    $target_canvas_ create line $x2_cv $y2_cv $x3_cv $y3_cv -fill $footprintcolor \
			-width 1 -tags "$tags $tags_specbox"
		    $target_canvas_ create line $x3_cv $y3_cv $x4_cv $y4_cv -fill $footprintcolor \
			-width 1 -tags "$tags $tags_specbox"
		    $target_canvas_ create line $x4_cv $y4_cv $x1_cv $y1_cv -fill $footprintcolor \
			-width 1 -tags "$tags $tags_specbox"

		    # Plot the microshuffle storage bands above and below each spectrum
		    if {$ODF_shuffleMode == "microShuffle"} {

			set ymin1 [expr $yslit - $dimy - $ODF_shuffleSize / $ODF_binning]
			set ymax1 [expr $yslit - $dimy]
			set ymin2 [expr $yslit + $dimy]
			set ymax2 [expr $yslit + $dimy + $ODF_shuffleSize / $ODF_binning]
			
			$target_image_ convert coords $spec_min $ymin1 image spec_min_cv ymin1_cv canvas
			$target_image_ convert coords $spec_max $ymax1 image spec_max_cv ymax1_cv canvas
			$target_image_ convert coords $spec_min $ymin2 image spec_min_cv ymin2_cv canvas
			$target_image_ convert coords $spec_max $ymax2 image spec_max_cv ymax2_cv canvas
			
			# draw the storage rectangle
			$target_canvas_ create rect $spec_min_cv $ymax1_cv $spec_max_cv $ymin1_cv \
			    -outline red -fill red -stipple gray25 -width 0 -tags bandrects
			$target_canvas_ create rect $spec_min_cv $ymax2_cv $spec_max_cv $ymin2_cv \
			    -outline red -fill red -stipple gray25 -width 0 -tags bandrects
		    }
		}

		# Leave here if acq object, or if only acq objects should be shown
		if {$type == "acq" || $cbo_acqonly == 1} {
		    continue
		}
		
		# Only if we want a wavelength grid with labels:
		if {$cbo_showwave == 1} {

		    # draw the wavelength grid (yellow, if not too close to cwl) and the cwl (red)
		    if {$type == "grid" || $type == "cwl"} {
			$target_canvas_ create line $wave_x1_cv $wave_y1_cv $wave_x2_cv $wave_y2_cv \
			    -fill $markercolor -width 1 -tags "$tags $tags_showwave"
		    }
		    
		    # Draw red line connecting CWL with object
		    if {$type == "cwl"} {
			if {$DISPDIR == "horizontal"} {
			    set con_x1 [expr $value + $tilt_dcwl] 
			    set con_x2 [expr $xslit + $tilt_dcwl]
			    set con_y1 $yslit
			    set con_y2 $yslit
			} else {
			    set con_x1 $xslit
			    set con_x2 $xslit
			    set con_y1 [expr $value + $tilt_dcwl]
			    set con_y2 [expr $yslit + $tilt_dcwl]
			}
			$target_image_ convert coords $con_x1 $con_y1 image con_x1_cv con_y1_cv canvas
			$target_image_ convert coords $con_x2 $con_y2 image con_x2_cv con_y2_cv canvas
			$target_canvas_ create line $con_x1_cv $con_y1_cv $con_x2_cv $con_y2_cv \
			    -fill $markercolor -width 1 -tags "$tags $tags_specbox "
		    }
		    
		    # labels (don't print negative labels, i.e. only every second one)
		    if {$label < 0.} {
			continue
		    }

		    if {($type == "grid" && [expr abs($spect_cwl - $label)] >= $minsep_cwl)} {
			# Don't print a label if we are too close to a chip gap (GMOS, only)
			if { $instType == "F2" || 
			    ($instType != "F2" && 
			     [expr abs([lindex $detgaps 0] - $value)] >= $minsep_gap &&
			     [expr abs([lindex $detgaps 1] - $value)] >= $minsep_gap &&
			     [expr abs([lindex $detgaps 2] - $value)] >= $minsep_gap &&
			     [expr abs([lindex $detgaps 3] - $value)] >= $minsep_gap)} {
			    
			    # convert to microns for F2
			    if {$instType == "F2" || $instType == "F2-AO"} {
				set label [format "%.1f" [expr $label*0.001]]
			    }
				
			    if {$DISPDIR == "horizontal"} {
				$target_canvas_ create text [expr $value_cv+$offset_cv] [expr ($slit_ymin_cv+$slit_ymax_cv)/2.] \
				    -anchor w -font {Arial 12} -text $label -tags "$tags $tags_showwave" \
				    -fill yellow
			    } else {
				$target_canvas_ create text [expr ($slit_xmin_cv+$slit_xmax_cv)/2.] [expr $value_cv+$offset_cv] \
				    -anchor n -font {Arial 12} -text $label -tags "$tags $tags_showwave" \
				    -fill yellow
			    }
			}
		    }
		}

		# Only if we want individual wavelengths with labels:
		if {$cbo_indwave == 1 && $type == "indwave"} {

		    # microns for F2
		    if {[isnumeric $indlabel] && ($instType == "F2" || $instType == "F2-AO")} {
			set indlabel [format "%.3f" [expr $indlabel*0.001]]
		    }
			
		    # draw the wavelength grid (yellow, if not too close to cwl) and the cwl (red)
		    $target_canvas_ create line $wave_x1_cv $wave_y1_cv $wave_x2_cv $wave_y2_cv \
			-fill $markercolor -width 1 -tags "$tags $tags_indwave"
		    
		    # show wavelength labels
		    if {$DISPDIR == "horizontal"} {
			$target_canvas_ create text [expr $value_cv+$offset_cv] [expr ($slit_ymin_cv+$slit_ymax_cv)/2.] \
			    -anchor w -font {Arial 12} -text $indlabel -tags "$tags $tags_indwave" -fill $markercolor
		    } else {
			$target_canvas_ create text [expr ($slit_xmin_cv+$slit_xmax_cv)/2.] [expr $value_cv+$offset_cv] \
			    -anchor n -font {Arial 12} -text $indlabel -tags "$tags $tags_indwave" -fill $markercolor
		    }
		}
	    }

	    # Show detector gap wavelengths
	    # Don't need to filter for F2 because "gap" keyword will appear only for GMOS
	    if {$type == "gap" && $cbo_showwave == 1 && $cbo_acqonly == 0} {
		# Detector gap positions
		set gap $label
		$target_image_ convert coords $gap $tmp image gap_cv tmp canvas
		# Detector gap wavelengths, rounded integers
		if {$gapid == 1 || $gapid == 3} {
		    set gapwave [expr round($value)]
		    set offset_cv -5
		    set anchor e
		} else {
		    set gapwave [expr round($value)]
		    set offset_cv 5
		    set anchor w
		}

		$target_canvas_ create text [expr $gap_cv+$offset_cv] [expr ($slit_ymin_cv+$slit_ymax_cv)/2.] \
		    -anchor $anchor -font {Arial 12 bold} -text $gapwave -tags "$tags $tags_showwave" -fill cyan
	    }
	}

	if {$outsidewarning != "" && $outsidewarning_shown == 0} {
	    warn_dialog "Spectra for object(s):\n $outsidewarning \nfall entirely outside the detector area due to bad CWL/filter choice.\nThis warning will be suppressed for this ODF and this session."
	    set outsidewarning_shown 1
	}

	if {$grating == "R600" && $R600warning_shown == 0} {
	    warn_dialog "R600 grating.\nWavelength mapping has not been performed for the R600.\nThe wavelengths shown are based on the B600 and are approximate, only. Use CWL dithers if in doubt.\nThis warning will be suppressed for this ODF and this session."
	    set R600warning_shown 1
	}
	
	return $cwl_outside_spectrum_global
    }

    
    #############################################################
    #  Name: display_overlays_order
    #
    #  Description:
    #  reads the output of gemwm and displays the order overlap
    #############################################################
    #############################################################
    protected method display_overlays_order {tags tags_2ndorder spect_disp \
						 spect_lmin spect_lmax spect_cwl grating} {
	
	set target_canvas_ .skycat1.image.imagef.canvas
	set instType $itk_option(-instType)

	# Open the output of gemwm
	catch { set gemwm_output [open "gemwm.output" r] }
	
	# Declare a couple of lists that contain the output
	set type  {}
	set xslit {}
	set yslit {}
	set label {}
	set value {}
	set nslit 0

	set nativeScale 0.0

	if {$instType == "GMOS-N"} {
	    set nativeScale 0.0807
	} elseif {$instType == "GMOS-S"} {
	    set nativeScale 0.0800
	} elseif {$instType == "F2"} {
	    set nativeScale 0.1792
	} elseif {$instType == "F2-AO"} {
	    # needs to be verified and must be the same as the numeric value used in Gemini/IRAF
	    set nativeScale 0.0896
	} else {
	    error_dialog "Unknown instrument type: $instType"
	    return
	}

	# This might cause slight inaccuracies in the overlay of spectral boxes, if the
	# native pixel scale is not exactly the same as the true pixel scale.

	# Wavelength models are for 1x1 binning. If the current image has a different plate scale, then
	# we need to transform the output of gemwm.
	set corrfac [expr $nativeScale / $PIXSCALE]

	# Plot the order overlap boxes.
	# We are interested in the "2ndorder" keyword entries of the gemwm output, only.
	while {[gets $gemwm_output line] >= 0} {
	    # Read the output of gemwm
	    set type   [lindex $line 0]
	    # leave if not in order overlap mode, or in box mode (the latter is needed for the R150)
	    if {! ($type == "2ndorder" || $type == "box")} {
		continue
	    }
	    set xslit  [lindex $line 1]
	    set yslit  [lindex $line 2]
	    set dimx   [lindex $line 5]
	    set dimy   [lindex $line 6]
	    set spec_min [lindex $line 7]
	    set spec_max [lindex $line 8]

	    # Model calculations were done for 1x1 binning; correct if images have different pixel scale.

	    # HACK! Pseudo-images from GMOS-S Hamamatsu were still in the
	    # GMOS-S EEV geometry and pixel scale for a long time. This takes care of the pixel scale, too.
	    if {($instType == "GMOS-S" && $NAXIS1 == "6218" && $NAXIS2 == "4608") ||
		($instType == "GMOS-N" && $NAXIS1 == "6218" && $NAXIS2 == "4608")} {
		set xslit [transform_gmos_x_new2old $xslit $nativeScale $instType]
		set yslit [transform_gmos_y_new2old $yslit $nativeScale $instType]
		set spec_min [transform_gmos_x_new2old $spec_min $nativeScale $instType]
		set spec_max [transform_gmos_x_new2old $spec_max $nativeScale $instType]
	    } else {	
		set xslit  [expr $xslit*$corrfac]
		set yslit  [expr $yslit*$corrfac]
		set dimx   [expr $dimx*$corrfac]
		set dimy   [expr $dimy*$corrfac]
		set spec_min [expr $spec_min*$corrfac]
		set spec_max [expr $spec_max*$corrfac]
	    }

	    set spec_min_orig $spec_min
	    set spec_max_orig $spec_max
	    
	    # catch nonsense due to wavelength inversion
	    if {$spec_min < $spec_max} {
		if {$spec_min < 0} {
		    set spec_min 1e4
		}
		if {$spec_max > 0} {
		    set spec_max -1e4
		}
	    }

	    # truncate at the detector boundary
	    set spec_min_orig $spec_min
	    set spec_max_orig $spec_max
	    set spec_min [truncate_spec $spec_min "blue"]
	    set spec_max [truncate_spec $spec_max "red" ]
	    
	    # the vertices of the slits
	    set slit_xmin [expr $xslit - $dimx]
	    set slit_xmax [expr $xslit + $dimx]
	    set slit_ymin [expr $yslit - $dimy]
	    set slit_ymax [expr $yslit + $dimy]

	    # Convert coordinates to canvas system (need them at many places)
	    set tmp 0
	    $target_image_ convert coords $slit_xmin $slit_ymin image slit_xmin_cv slit_ymin_cv canvas
	    $target_image_ convert coords $slit_xmax $slit_ymax image slit_xmax_cv slit_ymax_cv canvas
	    $target_image_ convert coords $spec_min $slit_ymin image spec_xmin_cv spec_ymin_cv canvas
	    $target_image_ convert coords $spec_max $slit_ymax image spec_xmax_cv spec_ymax_cv canvas

	    
	    if {$type == "2ndorder"} {
		# GUESS: 2nd order is twice as long as first order, and we know the starting point.
		# GUESS: R831_2nd: 1st order is half as long as second order, and we know the end point. 
		if {$grating != "R831_2nd"} {
		    set spec_max [expr $spec_min_orig - 2.0 * ($spect_lmax - $spect_lmin) / $spect_disp]
		} else {
		    set spec_min [expr $spec_max_orig + 0.5 * ($spect_lmax - $spect_lmin) / $spect_disp]
		}
		# Truncate at the detector boundary
		set spec_max [truncate_spec $spec_max "red" ]
		set spec_min [truncate_spec $spec_min "blue"]
		
		# Don't plot anything if the order is entirely outside the detector area,
		if {$spec_max > $DETXMAX || $spec_min < $DETXMIN} {
		    continue
		}
		
		$target_image_ convert coords $spec_max $tmp image spec_xmax_cv tmp_cv canvas
		$target_image_ convert coords $spec_min $tmp image spec_xmin_cv tmp_cv canvas
		# Draw the order overlap
		$target_canvas_ create rect $spec_xmax_cv $spec_ymax_cv $spec_xmin_cv $spec_ymin_cv \
		    -outline orange -fill orange -stipple gray12 -width 1 -tags "$tags $tags_2ndorder"
	    }

	    if {$type == "box" && $grating == "R150"} {
		# Show the approximate zero-th order position for the R150
		# GUESS: zero-th order linearly extrapolated from 1st order properties
		# +/- 10 so that zero order is not an infinitely thin line
		set zero_min [expr $spec_min_orig + $spect_lmin / $spect_disp - 10]
		set zero_max [expr $spec_min_orig + $spect_lmin / $spect_disp + 10]
		
		# Truncate at the blue detector boundary
		set zero_min [truncate_spec $zero_min "blue" ]
		set zero_max [truncate_spec $zero_max "blue"]
		
		# Don't plot anything if the order is entirely outside the detector area,
		if {$zero_min > $DETXMAX} {
		    continue
		}
		
		$target_image_ convert coords $zero_min $tmp image zero_min_cv tmp_cv canvas
		$target_image_ convert coords $zero_max $tmp image zero_max_cv tmp_cv canvas
		# Draw the order overlap
		$target_canvas_ create rect $zero_min_cv $spec_ymax_cv $zero_max_cv $spec_ymin_cv \
		    -outline orange -fill orange -stipple gray12 -width 1 -tags "$tags $tags_2ndorder"
	    }
	}
    }
    

    #############################################################
    #  Name: truncate_spec
    #
    #  Description:
    #  Truncates the min / max spectral range at the detector 
    #  boundary
    #  NOTE:
    #  pos = spec_min is the blue end of the spectrum position (large x/y value)
    #  and spec_max is the red end of the spectrum position (small x/y value)
    #############################################################
    #############################################################
    public method truncate_spec {pos type} {

	# $pos is either spec_min or spec_max, i.e. the spatial ends 
	# of the spectrum in pixel coordinates
	# Type is either "red" or "blue", depending on which end of the spectrum we want to truncate

	if {$DISPDIR == "horizontal"} {
	    if {$type == "red"} {
		set pos [max $DETXMIN $pos]
	    } else {
		set pos [min $DETXMAX $pos]
	    }
	} else {
	    if {$type == "red"} {
		set pos [max $DETYMIN $pos]
	    } else {
		set pos [min $DETYMAX $pos]
	    }
	}
	return $pos
    }


    #############################################################
    #  Name: reset_CWL
    #
    #  Description:
    #  Rereads the CWL from the ODF when the CWL undo button is 
    #  pressed in the ODF window
    #############################################################
    #############################################################
    protected method reset_CWL {} {
	# Remove old gemwm files (i.e. make sure we start fresh when loading a new ODF)
	catch {file delete "gemwm.input"}
	catch {file delete "gemwm.output"}
	
	# initialise these globals, used to decide whether gemwm has to be rerun or not
	set cwl_current ""
	set cwl_previous ""
	set linelist_current ""
	set linelist_previous ""
	set redshift_current ""
	set redshift_previous ""

	if {$itk_option(-instType) == "GMOS-N" || $itk_option(-instType) == "GMOS-S" } {
	    set odfcwl [get_keyword "#fits WAVELENG" $itk_option(-catalog)]
	    $w_.odfCWLSpinBox set $odfcwl
	    set cwl_current $odfcwl
	    set cwl_previous $odfcwl
	    # must run after the initialisation, because slits_ODF may update one of these values set above
	    slits_ODF
	}
    }

    #######################################################################
    #  Name: gemwm_solver
    #
    #  Description:
    #  This function runs the external 'gemwm' program over all slitlets
    #  to return the wavelength grid. It is faster doing this in one go
    #  than to open/close the connection many times
    #######################################################################
    #######################################################################
    public method gemwm_solver {run} {

	global oldODFwarning

	set catname $itk_option(-catalog)
	set instType $itk_option(-instType)
	
	# Get the gap x coordinates (for wavelength calculations)
	if {$instType == "GMOS-N" || $instType == "GMOS-S"} {
	    set detgap0 [lindex $GAP1X 0]
	    set detgap1 [lindex $GAP1X 2]
	    set detgap2 [lindex $GAP2X 0]
	    set detgap3 [lindex $GAP2X 2]
	    set detgaps [list $detgap0 $detgap1 $detgap2 $detgap3]
	} else {
	    set detgaps [list 0 0 0 0]
	}
	
	# Determine spectrum min and max lambda, dispersion, and central wavelength by 
	# greping the ASCII catalog file. Very cheesy way of doing this...
	set spect_lmin [get_keyword "#fits SPEC_MIN" $catname]
	set spect_lmax [get_keyword "#fits SPEC_MAX" $catname]
	set spect_disp [get_keyword "#fits SPEC_DIS" $catname]
	set grating    [get_keyword "#fits GRATING"  $catname]
	set filter     [get_keyword "#fits FILTSPEC" $catname]
	set filter     [string map {"_and_" "+"} $filter]
	# Old GMOS ODFs might have the grating/filter ID attached. To allow for throughput plots
	# and wavelength grids, we must trim these IDs
	if {$oldODFwarning && $instType != "F2" && $instType != "F2-AO"} {
	    set grating [lindex [split $grating "_"] 0]
	    set filter [lindex [split $filter "_"] 0]
	}
	set FilterTitle $filter

	# what to do for an old ODF
	if {$spect_lmin == "" || $spect_lmax == ""} {
	    set home $::env(GMMPS)
	    set subdir "/config/transmissiondata/"
	    set filterfile $home$subdir${instType}_${filter}.txt
	    set gratingfile $home$subdir${instType}_grating_${grating}.txt

	    # Detector name
	    set detectorfile $home$subdir${instType}_QE.txt
	    # Atmospheric throughput
	    set atmospherefile $home${subdir}atmosphere.txt
	    
	    # When filters and order sorting filter are combined, then
	    # extract the corresponding two transmission files like this:
	    if {[string match *_and_* $filter] == 1} {
		set filt1 [lindex [string map {"_and_" " "} $filter] 0]
		set filt2 [lindex [string map {"_and_" " "} $filter] 1]
		set fname ${instType}_${filt1}.txt
		set oname ${instType}_${filt2}.txt
		set filterfile $home$subdir$fname
		set orderfilterfile $home$subdir$oname
		set FilterTitle ${filt1}+${filt2}
	    } else {
		set orderfilterfile "empty"
	    }

	    # remove the " from the filenames (gotta love tcltk...)
	    set filterfile      [string trim $filterfile "\""]
	    set gratingfile     [string trim $gratingfile "\""]
	    set detectorfile    [string trim $detectorfile "\""]
	    set atmospherefile  [string trim $atmospherefile "\""]
	    set orderfilterfile [string trim $orderfilterfile "\""]
	    
	    # Determine wavelength cutoffs and the ideal CWL
	    
	    # cutoff is the minimum considered relative throughput wrt to 
	    # the maximum throughput.
	    # It could be a user-definable parameter
	    set cutoff "0.01"
	    set title ${instType}_${grating}+${FilterTitle}
	    if {[catch { 
		set output [exec calc_throughput \
				$filterfile $gratingfile $detectorfile \
				$atmospherefile $orderfilterfile $title \
				$cutoff "ODF"]
	    } msg]} {
		error_dialog "ERROR calculating system throughput : $msg"
		return
	    }
	    set spect_lmin [lindex $output 0]
	    set spect_lmax [lindex $output 1]
	}

	# For GMOS-N/S: get the CWL from the CWL SpinBox
	# (where it is initially set to what is written in the ODF header)
	# For F2: get it from the ODF header as the CWL is fixed
	if {$instType == "GMOS-N" || $instType == "GMOS-S"} {
	    set spect_cwl [$w_.odfCWLSpinBox get]
	} else {
	    set spect_cwl [get_keyword "#fits WAVELENG" $catname]
	}


	# exit if gemwm doesn't need to be rerun because nothing has changed:
	if {$run == 0} {
	    return [list $spect_lmin $spect_lmax]
	}

	# Do we have second order overlap with this configuration?
	set check_2ndorder_overlap "FALSE"
	if {$grating != "R831_2nd"} {
	    set spect_2ndorder_begin [expr 2.*$spect_lmin]
	    set spect_2ndorder_end [expr 2.*$spect_lmax]
	    if {$spect_2ndorder_begin < $spect_lmax} {
		set check_2ndorder_overlap "TRUE"
	    }
	} else {
	    set spect_2ndorder_begin [expr 0.5*$spect_lmin]
	    set spect_2ndorder_end [expr 0.5*$spect_lmax]
	    if {$spect_2ndorder_end > $spect_lmin} {
		set check_2ndorder_overlap "TRUE"
	    }
	}
	
	# Open a file that contains all slit positions
	set gemwm_input [open "gemwm.input" w ]

	if {$instType == "GMOS-N"} {
	    set nativeScale 0.0807
	} elseif {$instType == "GMOS-S"} {
	    set nativeScale 0.0800
	} elseif {$instType == "F2"} {
	    set nativeScale 0.1792
	} elseif {$instType == "F2-AO"} {
	    # needs to be verified and must be the same as the numeric value used in Gemini/IRAF
	    set nativeScale 0.0896
	} else {
	    error_dialog "Unknown instrument type: $instType"
	    return
	}

	# The wavelength models were calculated for 1x1 binning, for the Hamamatsu plate scale (0.0800).
	# For correct wavelength overlays, we need to transform the pixel coordinates in the current image
	# to those they would have in the native Hamamatsu format. This is mostly determined by the
	# binning factor, and / or the general plate scale of the (pseudo-)image:
	set corrfac [expr $PIXSCALE / $nativeScale]

	# Note that OLD pseudo-images (created before about March 2017) have the old plate scale of
	# 0.073 "/pixel (GMOS-S) and 0.0727 (GMOS-N), and the old EEV detector format (always in 1x1
	# binning), even after the Hamamatsu's were installed.
	# Hence we need to transform them to the Hamamatsu format:
	if {$instType != "F2"} {
	    if {($instType == "GMOS-S" && $NAXIS1 == "6218" && $NAXIS2 == "4608") ||
		($instType == "GMOS-N" && $NAXIS1 == "6218" && $NAXIS2 == "4608")} {
		# No explicit correction by 'corrfac' needed as these "bad" pseudo-images
		# were always done the same way.
		set detgap0 [transform_gmos_x_old2new $detgap0 $nativeScale $instType]
		set detgap1 [transform_gmos_x_old2new $detgap1 $nativeScale $instType]
		set detgap2 [transform_gmos_x_old2new $detgap2 $nativeScale $instType]
		set detgap3 [transform_gmos_x_old2new $detgap3 $nativeScale $instType]
		set detgaps [list $detgap0 $detgap1 $detgap2 $detgap3]
	    } else {
		set detgap0 [expr $detgap0*$corrfac]
		set detgap1 [expr $detgap1*$corrfac]
		set detgap2 [expr $detgap2*$corrfac]
		set detgap3 [expr $detgap3*$corrfac]
		set detgaps [list $detgap0 $detgap1 $detgap2 $detgap3]
	    }
	}
	
	#############################################
	# For adding individual wavelengths...
	#############################################
	set wavelengths [$w_.odfWavelengthEdit get]
	set instType $itk_option(-instType)
	# Replace atomic chars by wavelengths
	set substitution [cat::waveMapper::replace_X_lambda $wavelengths]
	set wavelengths [lindex $substitution 0]
	set wavename [lindex $substitution 1]
	set numwave [llength $wavelengths]
	set redshift  [$w_.odfRedshiftEdit get]
	# a flag whether a global redshift has been given or not
	set redshift_set 1
	if {$redshift == ""} {
	    set redshift 0.0
	    set redshift_set 0
	}
	if {! [string is double $redshift] || $redshift < 0.} {
	    error_dialog "Non-numeric or negative redshift."
	    return -1
	}

	set head $itk_option(-headingx)
	set PRIORITY  [lsearch -regex $head {(?i)priority}]
	set TYPE      [lsearch -regex $head {(?i)slittype}]
	set ID        [lsearch -regex $head {(?i)ID}]
	set OBJX      [lsearch -regex $head {(?i)x_ccd}]
	set OBJY      [lsearch -regex $head {(?i)y_ccd}]
	set SLITSIZEX [lsearch -regex $head {(?i)slitsize_x}]
	set SLITSIZEY [lsearch -regex $head {(?i)slitsize_y}]
	set SLITTILT  [lsearch -regex $head {(?i)slittilt}]
	set SLITPOSX  [lsearch -regex $head {(?i)slitpos_x}]
	set SLITPOSY  [lsearch -regex $head {(?i)slitpos_y}]
	set INDZ      [lsearch -regex $head {(?i)redshift}]

	# R831_2nd wavelength model too wild if wavelengths far outside detector.
	# Introduce safe cutoff wavelengths that are certainly outside
	# need a backup copy of these:
	set spect_lmin_orig $spect_lmin
	set spect_lmax_orig $spect_lmax
	if {$grating == "R831_2nd"} {
	    if {[expr $spect_lmax - $spect_lmin] > 300} {
		set spect_lmin [expr $spect_cwl-150]
		set spect_lmax [expr $spect_cwl+150]
	    }
	}

	#  Cycle through each item in the objects list
	set nobj [$results_ total_rows]
	for {set n 0} {$n < $nobj} {incr n} {
	    set row [lindex $info_ $n]
	    set obj_id [lindex $row $ID]
	    # cartesian slit position coordinates, arcsec -> pixel
	    set xccd [expr [lindex $row $OBJX] + ([lindex $row $SLITPOSX]/$PIXSCALE) ]
	    set yccd [expr [lindex $row $OBJY] + ([lindex $row $SLITPOSY]/$PIXSCALE) ]
	    # slit offsets, arcsec -> pixel
	    set xshift [expr [lindex $row $SLITPOSX ]/$PIXSCALE]
	    set yshift [expr [lindex $row $SLITPOSY ]/$PIXSCALE]
	    # slit dimensions, arcsec -> pixel
	    set dimx [expr [lindex $row $SLITSIZEX] / 2.0 / $PIXSCALE]
	    set dimy [expr [lindex $row $SLITSIZEY] / 2.0 / $PIXSCALE]
	    set prior [lindex $row $PRIORITY]
	    set slittilt [lindex $row $SLITTILT]
	    set indredshift [lindex $row $INDZ]
	    if {$indredshift == ""} {
		set indredshift 0.0
	    }
	    
	    # HACK! Pseudo-images from GMOS-S Hamamatsu were still in the
	    # GMOS-S EEV geometry and pixel scale for a long time.
	    # For the time being, same transformation for GMOS-S and GMOS-N
	    if {($instType == "GMOS-S" && $NAXIS1 == "6218" && $NAXIS2 == "4608") ||
		($instType == "GMOS-N" && $NAXIS1 == "6218" && $NAXIS2 == "4608")} {
		set xccd [transform_gmos_x_old2new $xccd $nativeScale $instType]
		set yccd [transform_gmos_y_old2new $yccd $nativeScale $instType]
	    } else {
		# Correct for potentially different pixel scale
		# (wavelength models are for 1x1 binning).
		# Bad pseudo-images are already put onto the correct
		# transformation using transform_gmos_xy_old2new:
		set xccd   [expr $xccd*$corrfac]
		set yccd   [expr $yccd*$corrfac]
		set dimx   [expr $dimx*$corrfac]
		set dimy   [expr $dimy*$corrfac]
		set xshift [expr $xshift*$corrfac]
		set yshift [expr $yshift*$corrfac]
	    }

	    set label "label"

	    if {$instType != "F2"} {
		if {$prior == 0} {
		    puts $gemwm_input [format "acq %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %d %s" \
					   $xccd $yccd 0 [expr $spect_lmin*10] [expr $spect_lmax*10] \
					   $dimx $dimy $xshift $yshift $slittilt $obj_id $label]
		} else {
		    puts $gemwm_input [format "box %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %d %s" \
					   $xccd $yccd 0 [expr $spect_lmin*10] [expr $spect_lmax*10] \
					   $dimx $dimy $xshift $yshift $slittilt $obj_id $label]
		    if {$grating != "R831_2nd"} {
			puts $gemwm_input [format "2ndorder %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %d %s" \
					       $xccd $yccd [expr $spect_2ndorder_begin*10] [expr $spect_lmin*10] \
					       [expr $spect_lmax*10] $dimx $dimy $xshift $yshift $slittilt $obj_id $label]
		    } else {
			puts $gemwm_input [format "2ndorder %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %d %s" \
					       $xccd $yccd [expr $spect_2ndorder_end*10] [expr $spect_lmin_orig*10] \
					       [expr $spect_lmax_orig*10] $dimx $dimy $xshift $yshift $slittilt $obj_id $label]
		    }
		    puts $gemwm_input [format "grid %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %d %s" \
					   $xccd $yccd 0 [expr $spect_lmin*10] [expr $spect_lmax*10] \
					   $dimx $dimy $xshift $yshift $slittilt $obj_id $label]
		    puts $gemwm_input [format "cwl %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %d %s" \
					   $xccd $yccd [expr $spect_cwl*10] [expr $spect_lmin*10] [expr $spect_lmax*10] \
					   $dimx $dimy $xshift $yshift $slittilt $obj_id $label]
		    puts $gemwm_input [format "gap %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %d %s" \
					   $xccd $yccd [lindex $detgaps 0] [expr $spect_lmin*10] \
					   [expr $spect_lmax*10] 1.0 0.0 0.0 0.0 0.0 $obj_id $label]
		    puts $gemwm_input [format "gap %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %d %s" \
					   $xccd $yccd [lindex $detgaps 1] [expr $spect_lmin*10] \
					   [expr $spect_lmax*10] 2.0 0.0 0.0 0.0 0.0 $obj_id $label]
		    puts $gemwm_input [format "gap %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %d %s" \
					   $xccd $yccd [lindex $detgaps 2] [expr $spect_lmin*10] \
					   [expr $spect_lmax*10] 3.0 0.0 0.0 0.0 0.0 $obj_id $label]
		    puts $gemwm_input [format "gap %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %d %s" \
					   $xccd $yccd [lindex $detgaps 3] [expr $spect_lmin*10] \
					   [expr $spect_lmax*10] 4.0 0.0 0.0 0.0 0.0 $obj_id $label]
		}
	    }

	    # Swap x and y for F2, and drop detector gaps.
	    # No 2nd order calculations for F2 because it uses a grism.
	    if {$instType == "F2"} {
		if {$prior == 0} {
		    puts $gemwm_input [format "acq %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %d %s" \
					   $yccd $xccd 0 [expr $spect_lmin*10] [expr $spect_lmax*10] \
					   $dimx $dimy $yshift $xshift $slittilt $obj_id $label]
		} else {
		    puts $gemwm_input [format "box %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %d %s" \
					   $yccd $xccd 0 [expr $spect_lmin*10] [expr $spect_lmax*10] \
					   $dimx $dimy $yshift $xshift $slittilt $obj_id $label]
		    puts $gemwm_input [format "grid %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %d %s" \
					   $yccd $xccd 0 [expr $spect_lmin*10] [expr $spect_lmax*10] \
					   $dimx $dimy $yshift $xshift $slittilt $obj_id $label]
		    puts $gemwm_input [format "cwl %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %d %s" \
					   $yccd $xccd [expr $spect_cwl*10] [expr $spect_lmin*10] [expr $spect_lmax*10] \
					   $dimx $dimy $yshift $xshift $slittilt $obj_id $label]
		}
	    }

	    #############################################
	    # For adding individual wavelengths...
	    #############################################
	    set nw 0
	    while {$nw < $numwave} {
		# Wavelengths [nm] to plot;
		# Global redshifts override individual redshifts
		if {$redshift_set == 1} {
		    set wavelength [expr [lindex $wavelengths $nw] * (1. + $redshift)]
		} else {
		    set wavelength [expr [lindex $wavelengths $nw] * (1. + $indredshift)]
		}
		set label [lindex $wavename $nw]
		# will be a blank, not an empty string if numeric wavelength is given instead of atomic element name
		if {$label == " "} {
		    set label [lindex $wavelengths $nw]
		}

		# For gemwm, wavelengths must be in Angstrom [*10]!
		if {$instType != "F2" && $prior != 0} {
		    puts $gemwm_input [format "indwave %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %d %s" \
					   $xccd $yccd [expr $wavelength*10] [expr $spect_lmin*10] [expr $spect_lmax*10] \
					   $dimx $dimy $xshift $yshift $slittilt $obj_id $label]
		}
		if {$instType == "F2" && $prior != 0} {
		    puts $gemwm_input [format "indwave %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %d %s" \
					   $yccd $xccd [expr $wavelength*10] [expr $spect_lmin*10] [expr $spect_lmax*10] \
					   $dimx $dimy $yshift $xshift $slittilt $obj_id $label]
		}
		incr nw 1
	    }
	}
	::close $gemwm_input

	# run gemwm
	if {$instType == "F2" && $grating == "R3000"} {
	    # must use ID string that matches the entries in gemwm/data/F2_wavecal_coeffs.dat
	    if {$filter == "Ks" || $filter == "Kl" || $filter == "Kblue" || $filter == "Kred"} {
		set filter "K"
	    }
	    if {$filter == "Jlow"} {
		set filter "J"
	    }
	    set gratingstring ""
	    append gratingstring $grating "_" $filter
	} else {
	    set gratingstring $grating
	}
	exec gemwm -i $instType -m MOS -g $gratingstring -c [expr $spect_cwl*10] -f "gemwm.input"

	# returning the calculated spect_lmin/max values for old ODFs, 
	# only, so we don't have to guess them
	return [list $spect_lmin $spect_lmax]
    }


    #############################################################
    #  Name: slits
    #
    #  Description:
    #  This function draws the slits for ODF files.
    #############################################################
    #############################################################
    public method slits_ODF {{acqOnly ""}} {
	global ::cbo_2ndorder ::cbo_specbox ::cbo_shading ::cbo_acqonly ::cbo_showwave ::cbo_indwave
	global oldODFwarning oldwavelength_warning_shown

	# Must clear all previous overlays: If the user changes the CWL
	# within the dialog, multiple occurrences of the same elements would happen)

	clearslits_ODF

	set target_canvas_ .skycat1.image.imagef.canvas
	set catname $itk_option(-catalog)
	set instType $itk_option(-instType)

	# Clear slits if requested and return
	if {$cbo_specbox == 0 && $cbo_acqonly == 0} {
	    $w_.odfPlotCBO_shading  configure -state disabled
	    $w_.odfPlotCBO_showwave configure -state disabled
	    $w_.odfPlotCBO_2ndorder configure -state disabled
	    return
	}

	set target_image_ image2
	set tags_shading shading
	set tags_specbox specbox
	set tags_showwave showwave
	set tags_2ndorder secondorder
	set tags_indwave indwave
	set proximity_alert ""
	set proximity_alert_print ""

	# If acq only is activated, toggling slits on/off doesn't do anything
	# as only acq slits are highlighted. To avoid this, we force to switch
	# off the "acq only" setting if it is on and the user toggles the slit button
	if {$acqOnly == ""} {
	    if {$cbo_specbox == 1 && $cbo_acqonly == 1} {
		set cbo_acqonly 0
	    }
	}
	
	# Activate the shading checkbutton; delete previous shading (if any)
	$w_.odfPlotCBO_shading configure -state normal
	if {$cbo_shading == 0} {
	    $target_canvas_ delete shading
	}

	# Activate the wavelength overlay; delete previous wavelength overlay (if any)
	$w_.odfPlotCBO_showwave configure -state normal
	if {$cbo_showwave == 0} {
	    $target_canvas_ delete showwave
	}
	
	# Activate the 2nd order checkbutton (GMOS only); delete previous 2nd order (if any)
	if {$instType == "GMOS-N" || $instType == "GMOS-S"} {
	    $w_.odfPlotCBO_2ndorder configure -state normal
	    if {$cbo_2ndorder == 0} {
		$target_canvas_ delete secondorder
	    }
	}

	# Activate the individual wavelength overlay; delete previous wavelength overlay (if any)
	$w_.odfPlotCBO_indwave configure -state normal
	if {$cbo_indwave == 0} {
	    $target_canvas_ delete indwave
	}

	# Clear slits if requested and return
	if {$cbo_acqonly == 1} {
	    clearslits_ODF
	    set cbo_shading 1
	}

	# OK, now work towards plotting the slits
	set bg black
	set tags slitMarkODF
	set cwl_outside_spectrum_global "FALSE"

	# Determine spectrum min and max lambda, dispersion, and central wavelength by 
	# greping the ASCII catalog file. Very cheesy way of doing this...
	set spect_lmin [get_keyword "#fits SPEC_MIN" $catname]
	set spect_lmax [get_keyword "#fits SPEC_MAX" $catname]
	set spect_disp [get_keyword "#fits SPEC_DIS" $catname]
	set grating    [get_keyword "#fits GRATING"  $catname]
	set acqmag     [get_keyword "#fits ACQMAG"   $catname]
	set filter     [get_keyword "#fits FILTSPEC" $catname]
	set filter     [string map {"_and_" "+"} $filter]

	# Old GMOS ODFs might have the grating/filter ID attached. To allow for throughput plots
	# and wavelength grids, we must trim these IDs
	if {$oldODFwarning} {
	    if {$grating != "R831_2nd"} {
		set grating [lindex [split $grating "_"] 0]
	    }
	    set filter [lindex [split $filter "_"] 0]
	}

	# For GMOS-N/S: get the CWL from the CWL SpinBox
	# (where it is initially set to what is written in the ODF header)
	# For F2: get it from the ODF header as the CWL is fixed
	if {$instType == "GMOS-N" || $instType == "GMOS-S"} {
	    set spect_cwl [$w_.odfCWLSpinBox get]
	} else {
	    set spect_cwl [get_keyword "#fits WAVELENG" $catname]
	}

	if {$spect_disp == ""} {
	    if {$oldwavelength_warning_shown == 0} {
		info_dialog "This ODF does not contain information about the spectral dispersion.\n\nLoading defaults for:\nGrating:\t$grating\nFilter:\t$filter"
		set oldwavelength_warning_shown 1
	    }
	    set spect_disp [load_backup_dispersions $instType $grating $filter]
	    if {$spect_disp == ""} {
		error_dialog "Could not determine spectral dispersion for this ODF!"
		return
	    }
	}
	
	#  Cycle through each item in the objects list
	#  This gets num rows from total_rows(vmTableList)
	#  and info_ connections all rows in the display.
	set nobj [$results_ total_rows]
	if {$nobj == 0} {
	    return
	}

	set num_acq 0

	# Needed to collect warnings about spectra that fall entirely off the detector edge
	set blank " "

	set spect_list [gemwm_solver [test_gemwm_rerun $instType]]

	# Old ODF: no spect_lmin / lmax, take output from gemwm_solver instead
	if {$spect_lmin == "" || $spect_lmax == ""} {
	    set spect_lmin [lindex $spect_list 0]
	    set spect_lmax [lindex $spect_list 1]
	}

	# Is this a N&S mask?
	# Extract information from the ODF to be displayed in the info window
	set ODF_shuffleSize ""
	set ODF_bandSize    ""
	set ODF_yOffset     ""
	set ODF_slitLength  ""
	set ODF_binning  ""
	set ODF_shuffleMode [get_keyword "#fits SHUFMODE" $catname]
	if {!$oldODFwarning && $ODF_shuffleMode != ""} {
	    set ODF_shuffleSize [get_keyword "#fits SHUFSIZE" $catname]
	    set ODF_bandSize    [get_keyword "#fits BANDSIZE" $catname]
	    set ODF_yOffset     [get_keyword "#fits YOFFSET"  $catname]
	    set ODF_slitLength  [get_keyword "#fits SLITLEN"  $catname]
	    set ODF_binning     [get_keyword "#fits BINNING"  $catname]
	}
	# Is there a tilted slit in this mask?
	set hastiltslit [get_keyword "#fits TILTSLIT"  $catname]

	set head $itk_option(-headingx)
	set PRIORITY   [lsearch -regex $head {(?i)priority}]
	set TYPE       [lsearch -regex $head {(?i)slittype}]
	set ID         [lsearch -regex $head {(?i)ID}]
	set OBJX       [lsearch -regex $head {(?i)x_ccd}]
	set OBJY       [lsearch -regex $head {(?i)y_ccd}]
	set SLITSIZEX  [lsearch -regex $head {(?i)slitsize_x}]
	set SLITSIZEY  [lsearch -regex $head {(?i)slitsize_y}]
	set SLITTILT   [lsearch -regex $head {(?i)slittilt}]
	set SLITPOSX   [lsearch -regex $head {(?i)slitpos_x}]
	set SLITPOSY   [lsearch -regex $head {(?i)slitpos_y}]
	set REDSHIFT   [lsearch -regex $head {(?i)redshift}]
	
	set maskcheckstring ""

	for {set n 0} {$n < $nobj} {incr n} {
	    set row [lindex $info_ $n]
	    set obj_id [lindex $row $ID]
	    # cartesian object coordinates 
	    set xobj [lindex $row $OBJX]
	    set yobj [lindex $row $OBJY]
	    # cartesian slit position coordinates (same as object coordinates, plus offset)
	    set xccd [expr [lindex $row $OBJX] + ([lindex $row $SLITPOSX]/$PIXSCALE) ]
	    set yccd [expr [lindex $row $OBJY] + ([lindex $row $SLITPOSY]/$PIXSCALE) ]
	    # slit offsets
	    set xshift [expr [lindex $row $SLITPOSX ]/$PIXSCALE]
	    set yshift [expr [lindex $row $SLITPOSY ]/$PIXSCALE]
	    # slit dimensions (half values for easier plotting calculations)
	    set dimx [expr [lindex $row $SLITSIZEX] / 2.0 / $PIXSCALE]
	    set dimy [expr [lindex $row $SLITSIZEY] / 2.0 / $PIXSCALE]
	    set prior      [lindex $row $PRIORITY]
	    set slittilt   [lindex $row $SLITTILT]

	    # Exit if IDs are not integers
	    if { ![string is integer $obj_id]} {
		error_dialog "Error: Object ID (first column) must be an integer!\n You must recreate the OT/ODF accordingly."
		return
	    }
	    
	    # Skip this object if not an acquisition object and only acq objects should be plotted
	    if {$cbo_acqonly == 1 && $prior != "0"} {
		continue
	    }

	    #  Acq. objects are cyan if not highlighted
	    set acq_color magenta

	    # Check proximity for acquisition stars
	    if {$prior == 0} {
		set num_acq [expr $num_acq + 1]
		set proximity_alert [check_proximity $xobj $yobj $obj_id]
		if { $proximity_alert != ""} {
		    #reduce number of good acq stars by one
		    set num_acq [expr $num_acq - 1]
		    if {$proximity_alert_print == ""} {
			set proximity_alert_print "${proximity_alert}"
		    } else {
			set proximity_alert_print "${proximity_alert_print}${proximity_alert}"
		    }
		    # if in highlighting mode, change color
		    if {$cbo_acqonly == "1"} {
			if {[string match *within* $proximity_alert] == 1} { 
			    set acq_color yellow
			}
			if {[string match *too* $proximity_alert] == 1} { 
			    set acq_color yellow
			}
		    }
		}
	    }
	    
	    set maskcheckstring $maskcheckstring[check_proximity $xobj $yobj $obj_id "maskcheck"]

	    # Plot the slits only (not the spectral boxes!)
	    plotSlit $xccd $yccd $dimx $dimy $slittilt $prior $obj_id $tags $tags_specbox
	}

	# Show bandshuffle regions (only if not in acq highlighting mode)
	if {$ODF_shuffleMode == "bandShuffle" && $cbo_acqonly == 0} {
	    drawBands $ODF_shuffleSize $ODF_bandSize $ODF_yOffset $ODF_binning
	}
	
	# Display the various overlays including the wavelength grid
	set cwl_outside_spectrum_global \
	    [display_overlays \
		 $tags $tags_specbox $tags_2ndorder $tags_shading \
		 $tags_showwave $tags_indwave $spect_disp \
		 $spect_lmin $spect_lmax $spect_cwl $grating \
		 $ODF_shuffleMode $ODF_shuffleSize $ODF_binning]

	# Show order overlap if requested
	# Do this separately (last, i.e. here) so the overlap gets
	# plotted OVER everything else to make it clearly visible.
	if {$cbo_2ndorder == 1 && $cbo_acqonly == 0 } {
	    display_overlays_order $tags $tags_2ndorder $spect_disp \
		$spect_lmin $spect_lmax $spect_cwl $grating
	}

	# ODF properties are displayed in the GMMPS ODF window,
	# and also written to a txt file.

	set ODFsummaryname [file rootname $itk_option(-catalog)]_summary.txt
	set ODFoutput [open $ODFsummaryname w ]

	$w_.odfInfoFrame.03 delete 1.0 end
	if {$ODF_shuffleMode != ""} {
	    if {$ODF_shuffleMode == "microShuffle"} {
		$w_.odfInfoFrame.03 insert end "Micro-shuffling mask:\n" "shuffletype"
		$w_.odfInfoFrame.03 insert end "Shuffle dist. = $ODF_shuffleSize \[unbinned pixel\]\n"
		$w_.odfInfoFrame.03 insert end "Slit length   = $ODF_slitLength \[arcsec\]\n"
		puts $ODFoutput "Micro-shuffling mask:"
		puts $ODFoutput "Shuffle dist. = $ODF_shuffleSize \[unbinned pixel\]"
		puts $ODFoutput "Slit length   = $ODF_slitLength \[arcsec\]\n"
	    } else {
		$w_.odfInfoFrame.03 insert end "Band-shuffling mask:\n" "shuffletype"
		$w_.odfInfoFrame.03 insert end "Shuffle dist. = $ODF_shuffleSize \[unbinned pixel\]\n"
		$w_.odfInfoFrame.03 insert end "Band size     = $ODF_bandSize \[unbinned pixel\]\n"
		$w_.odfInfoFrame.03 insert end "y offset      = $ODF_yOffset \[unbinned pixel\]\n"
		puts $ODFoutput "Band-shuffling mask:"
		puts $ODFoutput "Shuffle dist. = $ODF_shuffleSize \[unbinned pixel\]"
		puts $ODFoutput "Band size     = $ODF_bandSize \[unbinned pixel\]"
		puts $ODFoutput "y offset      = $ODF_yOffset \[unbinned pixel\]\n"
	    }
	    $w_.odfInfoFrame.03 tag configure shuffletype -font "helvetica 12 bold"
	}
	
	$w_.odfInfoFrame.03 tag configure instrument -foreground #069 -font "helvetica 12 bold"
	set evaluation ""
	if {$num_acq <= 1 } {
	    set OT_acq_color #c00
	    set evaluation "ERROR: "
	} elseif {$num_acq == 2 } {
	    set OT_acq_color #c00
	    set evaluation "WARNING: "
	} else {
	    set OT_acq_color black
	}
	if {$ODF_shuffleMode == ""} {
	    $w_.odfInfoFrame.03 insert end "${evaluation}Number of good acq. stars: $num_acq\n" "acquisition"
	    $w_.odfInfoFrame.03 insert end "$acqmag\n" "acquisition"
	} else {
	    $w_.odfInfoFrame.03 insert end "\n${evaluation}Number of good acq. stars: $num_acq\n" "acquisition"
	    $w_.odfInfoFrame.03 insert end "$acqmag\n" "acquisition"
	}
	puts $ODFoutput "${evaluation}Number of good acquisition stars: $num_acq"
	puts $ODFoutput "$acqmag"
	$w_.odfInfoFrame.03 tag configure acquisition -foreground $OT_acq_color
	if { $proximity_alert_print != ""} {
	    $w_.odfInfoFrame.03 insert end "$proximity_alert_print" "proximity_alert"
	    $w_.odfInfoFrame.03 tag configure proximity_alert -foreground #c00
	    puts $ODFoutput "$proximity_alert_print"
	}
	
	set spect_2ndorder_begin [expr 2.*$spect_lmin]
	if {$spect_2ndorder_begin < $spect_lmax} {
	    set check_order_overlap "TRUE"
	}



	set check_order_overlap "FALSE"
	if {$grating != "R831_2nd"} {
	    set orderoverlap_begin [expr round(2.*$spect_lmin)]
	    if {$orderoverlap_begin < $spect_lmax} {
		set warn_order "2nd order overlap above $orderoverlap_begin nm"
		set check_order_overlap "TRUE"
	    }
	} else {
	    set orderoverlap_end [expr round( $spect_lmax/2.)]
	    if {$orderoverlap_end > $spect_lmin && $orderoverlap_end > 360} {
		set warn_order "1st order overlap below $orderoverlap_end nm"
		set check_order_overlap "TRUE"
	    }
	}

	if { $check_order_overlap == "TRUE"} {
	    $w_.odfInfoFrame.03 tag configure OrderOverlap -font "helvetica 12 bold" -foreground #d00
	    $w_.odfInfoFrame.03 insert end "\n$warn_order\n" "OrderOverlap"
	    puts $ODFoutput $warn_order
	}
	if {$cwl_outside_spectrum_global == "TRUE" && ($instType == "GMOS-N" || $instType == "GMOS-S")} {
	    $w_.odfInfoFrame.03 tag configure CWLoutside -font "helvetica 12" -foreground #c00
	    $w_.odfInfoFrame.03 insert end "\nWARNING: CWL outside filter bandpass.\n" "CWLoutside"
	    puts $ODFoutput "WARNING: CWL outside filter bandpass."
	}

	# Add Observing Tool information
	if {$grating == ""} {
	    set grating "UNKNOWN"
	}
	if {$filter == ""} {
	    set filter "UNKNOWN"
	}
	if {$spect_cwl == ""} {
	    set spect_cwl "UNKNOWN"
	}

	$w_.odfInfoFrame.03 tag configure OTsetup -foreground #c06 -font "helvetica 12 bold"
	$w_.odfInfoFrame.03 insert end "\n$instType Observing Tool setup:\n" "OTsetup"
	$w_.odfInfoFrame.03 insert end "Target RA  = $RA\n"
	$w_.odfInfoFrame.03 insert end "Target Dec = $DEC\n"
	$w_.odfInfoFrame.03 insert end "Pos. angle = $PA\n"
	puts $ODFoutput "\nOT setup:"
	puts $ODFoutput "Target RA  = $RA"
	puts $ODFoutput "Target Dec = $DEC"
	puts $ODFoutput "Pos. angle = $PA"
	if {$instType == "GMOS-N" || $instType == "GMOS-S"} {
	    $w_.odfInfoFrame.03 insert end "Grating    = $grating\n"
	    puts $ODFoutput "Grating    = $grating"
	} elseif {$instType == "F2"} {
	    $w_.odfInfoFrame.03 insert end "Grism      = $grating\n"
	    puts $ODFoutput "Grism      = $grating"
	}
	$w_.odfInfoFrame.03 insert end "Filter     = $filter\n"
	puts $ODFoutput "Filter     = $filter"
	if {$instType == "GMOS-N" || $instType == "GMOS-S"} {
	    $w_.odfInfoFrame.03 insert end "CWL        = $spect_cwl\n"
	    puts $ODFoutput "CWL        = $spect_cwl"
	}
	if {!$oldODFwarning && $ODF_shuffleMode != ""} {
	    $w_.odfInfoFrame.03 insert end "N&S Offset = $ODF_shuffleSize (detector rows)\n"
	    puts $ODFoutput "N&S Offset = $ODF_shuffleSize (detector rows)"
	}
	if {!$oldODFwarning && $ODF_shuffleMode != "" && $hastiltslit == 1} {
	    $w_.odfInfoFrame.03 tag configure tiltslitwarning -foreground red -font "helvetica 12 bold"
	    $w_.odfInfoFrame.03 insert end "WARNING: Tilted slit in Nod & Shuffle mask!\n" "tiltslitwarning"
	    $w_.odfInfoFrame.03 insert end "MUST USE q=0 nod offset in Observing Tool!\n" "tiltslitwarning"
	    puts $ODFoutput "WARNING: Tilted slit in Nod & Shuffle mask!"
	    puts $ODFoutput "MUST USE q=0 nod offset in the Observing Tool!"
	}
	
	puts $ODFoutput "\nOther parameters:"
	puts $ODFoutput "Spectral range  = $spect_lmin - $spect_lmax nm"
	puts $ODFoutput "Lin. dispersion = $spect_disp nm/pixel"

	# Add mask check comments for GMOS-N and GMOS-S
	if {$instType != "F2"} {
	    puts $ODFoutput "\nComments for interpreting mask images (PIs ignore please):"
	    puts $ODFoutput $maskcheckstring
	}

	# Redraw boundaries, to force them on top of all other displays
	# (mostly for the detector gaps)
	drawBoundaries

	::close $ODFoutput

	return
    }


    #############################################################
    #  Name: load_backup_dispersions
    #
    #  Description:
    #  Loads backup dispersions in case sth failed (e.g.
    #  someone loads an old ODF/MDF which does not have the
    #  dispersion in the header 
    #############################################################
    #############################################################
    public method load_backup_dispersions {instType grating filter} {

	set spect_disp ""
	if {$instType == "GMOS-N" || $instType == "GMOS-S"} {
	    if {$grating == "R831"} {
		set spect_disp 0.038
	    } elseif {$grating == "R831_2nd"} {
		set spect_disp 0.019
	    } elseif {$grating == "B1200"} {
		set spect_disp 0.026
	    } elseif {$grating == "B600"} {
		set spect_disp 0.051
	    } elseif {$grating == "R600"} {
		set spect_disp 0.052
	    } elseif {$grating == "R400"} {
		set spect_disp 0.076
	    } elseif {$grating == "R150"} {
		set spect_disp 0.199
	    } elseif {$grating == "B480"} {
		set spect_disp 0.062
	    }
		} else {
	    if {$grating == "R1200_JH"} {
		set spect_disp 0.6667
	    } elseif {$grating == "R1200_HK"} {
		set spect_disp 0.7826
	    } elseif {$grating == "R3000" && $filter == "Y"} {
		set spect_disp 0.1667
	    } elseif {$grating == "R3000" && $filter == "Jlow"} {
		set spect_disp 0.1667
	    } elseif {$grating == "R3000" && $filter == "J"} {
		set spect_disp 0.2022
	    } elseif {$grating == "R3000" && $filter == "H"} {
		set spect_disp 0.2609
	    } elseif {$grating == "R3000" && $filter == "Ks"} {
		set spect_disp 0.3462
	    } elseif {$grating == "R3000" && $filter == "Kl"} {
		set spect_disp 0.3462
	    } elseif {$grating == "R3000" && $filter == "Kred"} {
		set spect_disp 0.3462
	    } elseif {$grating == "R3000" && $filter == "Kblue"} {
		set spect_disp 0.3462
	    }
	}
	return $spect_disp
    }
    

    #############################################################
    #  Name: minval
    #
    #  Description:
    #  Returns the smaller of two values
    #############################################################
    #############################################################
    public method minval {v1 v2} {
	if {$v1<$v2} {
	    return $v1
	} else {
	    return $v2
	}
    }


    #############################################################
    #  Name: maxval
    #
    #  Description:
    #  Returns the smaller of two values
    #############################################################
    #############################################################
    public method maxval {v1 v2} {
	if {$v1>$v2} {
	    return $v1
	} else {
	    return $v2
	}
    }

    #############################################################
    #  Name: slits_OT
    #
    #  Description:
    #   This function draws the slits for OT files.
    #############################################################
    #############################################################
    public method slits_OT {} {
	global ::cbo_ot_slits 

	# Clear slits if requested and return
	if {$cbo_ot_slits == 0} {
	    clearslits_OT
	    return
	}

	# OK, Continue plotting slits
	set tags slitMarkOT
	set tags_slitMarkOT slitMarkOT
	set target_canvas_ .skycat1.image.imagef.canvas

	# This is the user INPUT catalog, columns may be in ANY order!
	# the following variables represent the column number, starting
	# with 0, where the respective entry is found
	set head $itk_option(-headingx)
	set PRIORITY  [lsearch -regex $head {(?i)priority}]
	set TYPE      [lsearch -regex $head {(?i)slittype}]
	set ID        [lsearch -regex $head {(?i)ID}]
	set OBJX      [lsearch -regex $head {(?i)x_ccd}]
	set OBJY      [lsearch -regex $head {(?i)y_ccd}]
	set SLITSIZEX [lsearch -regex $head {(?i)slitsize_x}]
	set SLITSIZEY [lsearch -regex $head {(?i)slitsize_y}]
	set SLITTILT  [lsearch -regex $head {(?i)slittilt}]
	set SLITPOSX  [lsearch -regex $head {(?i)slitpos_x}]
	set SLITPOSY  [lsearch -regex $head {(?i)slitpos_y}]

	#  Cycle through each item in the objects list
	#  This gets num rows from total_rows(vmTableList)
	#  and info_ connections all rows in the display.
	set nobj [$results_ total_rows]
	if {$nobj == 0} {
	    return
	}

	for {set n 0} {$n < $nobj} {incr n} {
	    set row [lindex $info_ $n]
	    set objID [lindex $row $ID]
	    # cartesian slit center (object + offset)
	    set xccd [expr [lindex $row $OBJX] + ([lindex $row $SLITPOSX]/$PIXSCALE) ]
	    set yccd [expr [lindex $row $OBJY] + ([lindex $row $SLITPOSY]/$PIXSCALE) ]
	    # HALF slit dimensions (easier plotting)
	    set dimx [expr [lindex $row $SLITSIZEX] / 2.0 / $PIXSCALE]
	    set dimy [expr [lindex $row $SLITSIZEY] / 2.0 / $PIXSCALE]
	    set prior [lindex $row $PRIORITY]
	    set slittilt [lindex $row $SLITTILT]

	    plotSlit $xccd $yccd $dimx $dimy $slittilt $prior $objID $tags $tags_slitMarkOT
	}
	
	return
    }


    #############################################################
    #  Name: clearslits_ODF
    #
    #  Description:
    #   Clear the slits in the ODF window
    #############################################################
    #############################################################
    public method clearslits_ODF {} {
	global ::cbo_specbox ::cbo_shading ::cbo_2ndorder ::cbo_showwave
        set target_canvas_ .skycat1.image.imagef.canvas
        $target_canvas_ delete slitMarkODF
        $target_canvas_ delete shading
        $target_canvas_ delete secondorder
	$target_canvas_ delete bandrects
	#	set cbo_specbox 0
        return
    }


    #############################################################
    #  Name: clearslits_OT
    #
    #  Description:
    #   Clear the slits in the OT window
    #############################################################
    #############################################################
    public method clearslits_OT {} {
	global ::cbo_ot_slits
        set target_canvas_ .skycat1.image.imagef.canvas
        $target_canvas_ delete slitMarkOT
	#	set cbo_ot_slits 0
        return
    }


    #########################################################################
    #  Name: _sel
    #
    #  Modifies a selection of slitlets
    #  Description: 
    #  The "del" argument is UNUSED
    #########################################################################
    #########################################################################
    public method _sel {flag {del 0}} {
	#  Get the results from the display (might be multiple rows)
	set rows [$results_ get_selected ]
	
	# Save selection.
	$results_ save_yview
	$results_ save_selection		
	
	set head $itk_option(-headingx)
	set PRIORITY  [lsearch -regex $head {(?i)priority}]
	set TYPE      [lsearch -regex $head {(?i)slittype}]
	set ID        [lsearch -regex $head {(?i)ID}]
	set SLITSIZEX [lsearch -regex $head {(?i)slitsize_x}]
	set SLITSIZEY [lsearch -regex $head {(?i)slitsize_y}]
	set SLITTILT  [lsearch -regex $head {(?i)slittilt}]
	set SLITPOSX  [lsearch -regex $head {(?i)slitpos_x}]
	set SLITPOSY  [lsearch -regex $head {(?i)slitpos_y}]
	
	set originalRowIds [list ]
	foreach row $rows {
	    set originalRowIds [lappend originalRowIds [lindex $row $ID ]]
	}
	
	set catname $itk_option(-catalog)
	set cattype $itk_option(-catalogtype)
	
	# Make sure the list of rows is in increasing order by ID.
	#if { ![is_sorted $rows ]} {	
	#	set rows [sort_rowlist $rows ]
	#}
	
	#  Check that the flag value pasted in is valid.
	# but we don't offer to change the slit type
	set flagCheck [regexp {Sall|0|1|2|3|X} $flag ]
	
	if { $flagCheck == 0 } {
	    error_dialog "Invalid priority or slittype <$flag>."
	    return 1
	}
	
	# The current row index in rows that we are replacing.
	set allRows [$results_ get_contents ]
	
	# construct list of columns that will be changed. 
	if {$flag == "Sall"}  {
	    set cols [list $SLITSIZEX $SLITSIZEY $SLITPOSX $SLITPOSY $SLITTILT]
	} else {
	    set cols [list $PRIORITY ]
	}
	
	# Send start signal to undo object.
	
	# Here we are hoping that the rows are sorted in order by ID, 
	# if they are not then we will need several iterations of the while
	# loop... but, this is still going to be more efficient than before.
	while { [llength $rows ] > 0 } {
	    
	    # Clear the catalog widget. 
	    $results_ clear
	    
	    # Set found flag to true for init.
	    set found 1
	    
	    # Scan through all rows			
	    foreach catRow $allRows {
		
		if { $found == 1 && [llength $rows ] > 0 } {
		    set row [lindex $rows 0 ]
		    
		    # Remove first item from the list.
		    set rows [lrange $rows 1 end ]
		    
		    # found flag off.
		    set found 0
		}
		
		if { [llength $rows ] >= 0 && [lindex $row $ID ] == [lindex $catRow $ID ] } { 
		    # ID match, found a row to edit...
		    
		    #puts "row [lindex $row $ID ] found."
		    
		    set found 1
		    set oldrow $row
		    set newrow $row
		    set problemsStr ""
		    set prio [lindex $row $PRIORITY]
		    
		    # Confirm when editing acq objects (only if clicked on the pink priority buttons, i.e. flag != Sall
#		    if {$prio == "0" && $flag != "Sall"} {
#			set answer [tk_messageBox -message "Object [lindex $row $ID ] is an acquisition object.\n You must update the slit geometry to the desired value.\nChange?" -title "WARNING" -parent $w_ -type yesno ]
			
#			if {$answer == "no"} {
#			    tk_messageBox -message "Edit canceled for object [lindex $row $ID ]." -parent $w_
#			    $results_ append_row $catRow
#			    continue
#			}
#		    }
		    
		    if { $flag == "A" || $flag == "R" } {
			set newrow [lreplace $row $TYPE $TYPE $flag]
		    } elseif { [string index $flag 0] == "S" } {
			# I THINK that SLITSIZEX/Y etc will never be -1 because I force added it earlier
			switch -regexp $flag {
			    Sall {
				set newrow $row
				set tsx  [$w_.slitsize_x get]
				set tsy  [$w_.slitsize_y get]
				set tt   [$w_.slittilt get]
				set tspx [$w_.slitpos_x get]
				set tspy [$w_.slitpos_y get]
				if {$tsx != "" && $SLITSIZEX != -1} {
				    if {$prio != 0} {
					set newrow [lreplace $newrow $SLITSIZEX $SLITSIZEX [format "%.6f" $tsx]]
				    } else {
					set newrow [lreplace $newrow $SLITSIZEX $SLITSIZEX 2.0]
				    }
				}
				if {$tsy != "" && $SLITSIZEY != -1} {
				    if {$prio != 0} {
					set newrow [lreplace $newrow $SLITSIZEY $SLITSIZEY [format "%.6f" $tsy]]
				    } else {
					set newrow [lreplace $newrow $SLITSIZEY $SLITSIZEY 2.0]
				    }
				}
				if {$tt != "" && $SLITTILT != -1} {
				    # Make sure slit tilts are valid.
				    if {($tt > 45.0 && !($tt <= 360.0 && $tt >= 315.0) || $tt < -45.0)} {
					append problemsStr "Slit Tilt $tt is outside valid range (-45.0 to 45 degrees).\n"
				    } else {
					if {$prio != 0} {
					    set newrow [lreplace $newrow $SLITTILT $SLITTILT [format "%.6f" $tt]]
					} else {
					    set newrow [lreplace $newrow $SLITTILT $SLITTILT 0.0]
					}
				    }
				}
				if {$tspx != "" && $SLITPOSX != -1} {
				    set newrow [lreplace $newrow $SLITPOSX $SLITPOSX [format "%.6f" $tspx]]
				}
				if {$tspy != "" && $SLITPOSY != -1} {
				    set newrow [lreplace $newrow $SLITPOSY $SLITPOSY [format "%.6f" $tspy]]
				}
			    }
			}
		    } elseif {$flag == "X"} { 
			# If we are ignoring an object be careful not to lose priority info 
			# for that object.
			set newrow [lreplace $row $PRIORITY $PRIORITY "X"]
		    } else {
			# Change priority. Here the priority will be changed to one of 0, 1, 2, 3 from any
			# other priority. Flag can have any of the aformentioned values. 
			if {$SLITTILT != -1} { 
			    set tt [lindex $row $SLITTILT ]
			    if {($tt > 45.0 && !($tt <= 360.0 && $tt >= 315.0) || $tt < -45.0)} {
				append problemsStr "Cannot restore slit. Slittilt $tt is outside valid range (-45.0 to 45 degrees).\n"	
			    }
			}
			
			set newrow [lreplace $row $PRIORITY $PRIORITY $flag]
			
			# Force 2x2 arcsec square box and zero tilt for acquisition objects
			if {$flag == 0} {
			    set newrow [lreplace $newrow $SLITSIZEX $SLITSIZEX 2.0]
			    set newrow [lreplace $newrow $SLITSIZEY $SLITSIZEY 2.0]
			    set newrow [lreplace $newrow $SLITTILT $SLITTILT 0.0]
			}
		    }
		    
		    # If there were problems add the old unmodified row. Else add new row. 
		    if {$problemsStr != ""} {
			error_dialog $problemsStr
			$results_ append_row $catRow
		    } else {		    
			$results_ append_row $newrow
		    }
		} else {
		    # This row is not one we wish to edit at this time. 
		    # So add it back to the catalog unmodified.
		    $results_ append_row $catRow
		}
	    }
	}
	
	# Finished input signal to catalog display widget. 
	$results_ new_info
	
	$results_ save_to_file $itk_option(-catalog) [$this.results get_contents ] "" 1
	
	# Restore the selection.
	reload_catalog OT
	$results_ restore_yview
	$results_ restore_selection
	
	# Check to see if row order or contents has changed. If so warn user.
	set post_rows [$results_ get_selected ]
	set cur 0
	foreach row $post_rows {
	    if {[lindex $row $ID ] != [lindex $originalRowIds $cur ]} {
		tk_messageBox -message "Warning: Table row order changed.\nHighlighted rows may not reflect previous selection." -parent $w_ -title "Row Order Changed"
		break
	    }
	    incr cur
	}
	
	return 0
    }


    #############################################################
    #  Name: Launch wavemapper
    #
    #  Description:
    #  Opens the wavemapper interface
    #############################################################
    #############################################################    
    public proc launch_wavemapper {} {
	
	update idletasks
	# Destroy any open wavemapper window before opening a new one
	catch {destroy $wavemapper_}
	set wavemapper_ [utilReUseWidget ::cat::waveMapper .skycat1.waveMapper $config_file_ ]

	return 
    }


    #########################################################################
    #  Name: drawBands
    #
    #  Description:
    #     does the actual drawing of the bands. 
    #########################################################################
    #########################################################################
    public proc drawBands {ODF_shuffleSize ODF_bandSize ODF_yOffset ODF_binning} {
	set canvas .skycat1.image.imagef.canvas
	set target_im_ image2
	
	# Clear the bands
	$canvas delete bandrects

	# Check for possible errors
	if {$ODF_bandSize == "" || $ODF_shuffleSize == "" || \
		$ODF_yOffset == "" || $ODF_binning == ""} { 
	    return "This bandshuffle ODF is corrupted. It lacks one or more bandshuffle keywords!"
	}

	# The maximum coordinate (in unbinned pixels)
	set maxY [expr $DETDIMY*$ODF_binning - $ODF_bandSize - $ODF_shuffleSize + 1]
	
	set j 0
	set lastyend 0
	for {set y [expr $ODF_shuffleSize + $ODF_yOffset + 1]} \
	    {$y <= $maxY} \
	    {set y [expr $y + $ODF_shuffleSize + $ODF_bandSize ]} {
		incr j
		
		# draw hatch mark of prohibited area, and one extra hash mark block 
		# from last band to top
		set x0loc 0
		set x1loc $DETDIMX
		set y0loc [expr $lastyend / $ODF_binning]
		set y1loc [expr $y        / $ODF_binning]
		set lastyend [expr $y + $ODF_bandSize]
		
		image2 convert coords $x0loc $y0loc image xleft ybot canvas
		image2 convert coords $x1loc $y1loc image xright ytop canvas
		
		# draw the excluded rectangle
		$canvas create rect $xleft $ytop $xright $ybot \
		    -outline yellow -fill yellow -stipple gray25 -width 1 -tags bandrects		
	    }
 
	# draw one extra hash mark block from last band to top
	set x0loc 0
	set x1loc $DETDIMX
	set y0loc [expr $lastyend / $ODF_binning]
	set y1loc $DETDIMY
	set lastyend [expr $y + $ODF_bandSize]
	
	image2 convert coords $x0loc $y0loc image xleft ybot canvas
	image2 convert coords $x1loc $y1loc image xright ytop canvas
	
	# draw the excluded area rectangle
	$canvas create rect $xleft $ytop $xright $ybot \
	    -outline yellow -fill yellow -stipple gray25 -width 1 -tags bandrects
	
	return
    }


    #############################################################
    #  Name: define_bands
    #
    #  Description:
    #   opens the "define bands" interface 
    # 
    #  Author: cba
    #############################################################
    #############################################################    
    public method define_bands {args} {
	
	# Make sure there are no slit tilts (not allowed in band-shuffling mode) 

	update idletasks

	# Find detector info.		
	set instType $itk_option(-instType)
	setDetInfo $instType

	if {($instType == "GMOS-S" && $NAXIS1 == "6218" && $NAXIS2 == "4608") ||
	    ($instType == "GMOS-N" && $NAXIS1 == "6218" && $NAXIS2 == "4608")} {
	    error_dialog "This is an old GMOS pseudo-image representing the detector geometry GMOS had before the Hamamatsu detector upgrade.\nNew, and much more precise, pseudo-image transformations have been obtained since.\nTo create a new pseudo-image and mask design, you must use Gemini IRAF v1.14 (or later) available through AstroConda at\nhttp://astroconda.readthedocs.io/ ."
	    return
	}

	# Leave with an error if one of the acquisition boxes is too close
	# to a gap or the mask area boundary
	set proximity_alert [check_proximity_parent]
	if {$proximity_alert != ""} {
	    return
	}

	# Destroy any open band_def_ui and spoc window before opening a new one
	catch {destroy $bw_}
	catch {destroy $spoc_}

	set globallist [list $CRPIX1 $CRPIX2 $PA $RA $DEC $NAXIS1 $NAXIS2 $DISPDIR \
			 $PIXSCALE $DETDIMX $DETDIMY $DETXMIN $DETXMAX $DETYMIN $DETYMAX]
	
	set bw_ [utilReUseWidget gmmps::band_def_UI .skycat1.bandDefUI $this \
		     $itk_option(-catalog) $itk_option(-binning) \
		     $this.results $config_file_ $DET_IMG_ $DET_SPEC_ \
		     $itk_option(-instType) $globallist]

	return 
    }


    #########################################################################
    #  Name: _sel
    #
    #  Modifies a selection of slitlets
    #  Description: I need this because the "Update slits" button would 
    #  not update the slit drawings in the OT window.
    #########################################################################
    #########################################################################
    public method _sel_parent {flag {del 0}} {
	global ::cbo_ot_slits

	_sel $flag $del
	set cbo_ot_slits 0
	clearslits_OT
	# the following does not work (the catalog known to slits_OT is empty)
#	update idletasks
#	set cbo_ot_slits 1
#	slits_OT
    }



    #############################################################
    #  Name: open_catalog
    #
    #  Description:
    #   This function opens the catalog for this window.
    #   Called by layoutdialog(), which is called by init()
    #   Specifically:
    #        This creates the w_ object used throughout this code.
    #        Initializes it
    #        
    #############################################################
    #############################################################
    public method open_catalog {} {

	# create tcs object
	global ::$w_.tcs

	astrocat $w_.cat

	# normally -catalog should be specified when creating this widget
	# if not, choose a default...
	if {"$itk_option(-catalog)" == ""} {
	    return
	    if {[catch {set catalog_list [$w_.cat info $itk_option(-catalogtype)]} msg]} {
		error_dialog $msg
		return
	    }
	    set itk_option(-catalog) [lindex $catalog_list [expr [llength $catalog_list]-1]]
	}

	# open the catalog file
	set name $itk_option(-catalog)
	if {[catch {$w_.cat open $name} msg]} {
	    error_dialog $msg
	    return
	}
	
	# Check if this is an ODF or an OT
	set ODFteststring [get_keyword "#fits ANAMORPH" $name]
	if {$ODFteststring != ""} {
	    # This is an ODF. Did the user want to open an OT?
	    if {$itk_option(-catType) == 1 || $itk_option(-catType) == 3} {
		error_dialog "This is an ODF file, but you wanted to open an OT file!"
		destroy $w_
		return "wrongfiletype"
	    }
	} else {
	    # This is an OT. Did the user want to open an ODF?
	    if {$itk_option(-catType) == 2 || $itk_option(-catType) == 4 || $itk_option(-catType) >= 5} {
		error_dialog "This is an OT file, but you wanted to open an ODF file!"
		destroy $w_
		return "wrongfiletype"
	    }
	}	    

	# set iscat_ to true if the catalog is not an image server
	set iscat_ 1
	if {"[$w_.cat servtype]" == "imagesvr"} {
	    set iscat_ 0
	} 

	# if this is a local catalog, add it to the catalog menus and tree
	# Should check if local catalog was already known
	if {"[$w_.cat servtype]" == "local"} {
	    update_catalog_menus

	    # add to catalog tree, if there is one
	    catch {.catinf insert_node $name}
	    
	    # add an entry to the config file for this catalog
	    cat::CatalogInfo::save "" $w_ 0
	}
	
	# display catalog name in header and icon
	wm title $w_ "[file tail $name] ($itk_option(-number))"
	wm iconname $w_ "[$w_.cat shortname $name]"    
    }


    #############################################################
    #  Name: reload_catalog
    #
    #  Description:
    #	Reload catalog.
    #############################################################
    #############################################################
    method reload_catalog {catType} {
	global ::cbo_specbox ::cbo_ot_slits

	set catalogName $itk_option(-catalog)
	set instType $itk_option(-instType)
	
	# Call select catalog again with specs for this catalog.
	select_catalog $catalogName local "namespace inscope ::skycat::SkyCat .skycat1.image" \
	    "::skycat::vmSkySearch" 0 1 "" $instType
	
	update idletasks
	after idle [code $this redraw_canvas_items ]

	if {$catType == "ODF"} {
	    reset_CWL
	}
    }


    method redraw_canvas_items {} {
	global ::cbo_specbox ::cbo_ot_slits
	
	set catType $itk_option(-catType)
	
	# Redraw slits if reloading OT/ODF

	if {($catType == 1 || $catType == 3) && $cbo_ot_slits == 1} {
	    # Clear slits on canvas.
	    set target_canvas_ .skycat1.image.imagef.canvas
	    $target_canvas_ delete slitMarkOT
	}

	if {($catType == 2 || $catType == 4) && $cbo_specbox == 1} {
	    # Clear slits on canvas.
	    set target_canvas_ .skycat1.image.imagef.canvas
	    $target_canvas_ delete slitMarkODF
	    $target_canvas_ delete shading
	    $target_canvas_ delete showwave
	    $target_canvas_ delete 2ndorder
	    set cbo_specbox 0
	}
    }


    #############################################################
    #  Name: add_search_options
    #
    #  Description:
    # add the search options panel
    #############################################################
    #############################################################
    protected method add_search_options {} {
	# vmAstroQuery(n) widget for displaying catalog search options.
	itk_component add searchopts {
	    set searchopts_ [::cat::vmAstroQuery $w_.searchopts \
				 -relief groove \
				 -borderwidth 2 \
				 -debug $itk_option(-debug) \
				 -astrocat [code $w_.cat] \
				 -searchcommand [code $this search] \
				 -command [code $this query_done]]
	}
	pack $itk_component(searchopts) \
	    -side top -fill x
    }


    #############################################################
    #  Name: add_result_table
    #
    #  Description:
    #   Create the results_ table, by calling vmQueryResult   
    #   Add the table for displaying the query results
    #############################################################
    #############################################################
    protected method add_result_table {} {
	# QueryResult(n) widget to display catalog query results
	
	itk_component add results {
	    set results_ [::cat::vmQueryResult $w_.results \
			      -astrocat [code $w_.cat] \
			      -title "Search Results" \
			      -hscroll 1 \
			      -height 12 \		      
			  -sortcommand [code $this set_sort_cols] \
			      -layoutcommand [code $this set_show_cols] \
			      -selectmode extended \
			      -exportselection 0]
	} {
	}
	
	pack $itk_component(results) -side top -fill both -expand 1
	bind $results_.listbox <ButtonRelease-1> [code $this select_result_row]
	$results_ set_options {MORE PREVIEW more preview} Show 0
    }


    ##########################################################################
    # Pick a web browser
    ##########################################################################
    public method get_browser {} {
    set os [exec uname -s]
    if {$os == "Darwin"} {
		return "open"
	} elseif {[catch {exec which xdg-open} message] == 0} {
    	return "xdg-open"
	} elseif {[catch {exec which firefox} message] == 0} {
	    return "firefox"
	} elseif {[catch {exec which chrome} message] == 0} {
	    return "chrome"
	} elseif {[catch {exec which opera} message] == 0} {
	    return "opera"
	} else {
	    error_dialog "Could not find a web browser on your machine. Please open the documentation web pages outside GMMPS."
	    return ""
	}
    }

    #########################################################################
    # Create and display a throughput plot using BLT
    #########################################################################
    public method loadThroughputPlot {wavemin wavemax title} {

	set home $::env(GMMPS)
	# package require Img
	package require BLT

	set cwlfloat [expr ($wavemax + $wavemin) / 2.]
	set cwl [expr int(round($cwlfloat))]

	set wavelength {}
	set throughput {}
	set maxthroughput 0.0
	set tfile [open ".total_system_throughput.dat" r]
	while {[gets $tfile line] >= 0} {
		set tline [string trim $line]
		scan $tline "%f %f" wave tput
		# puts [format "%.3f %.3f" $wave $tput]
		lappend wavelength $wave
		lappend throughput $tput
# 		if {($wave >= $wavemin) && ($wave <= $wavemax)} {
# 			lappend wavelength $wave
# 			lappend throughput $tput
# 		}
		if {$wave == $cwl} {
			set cwl_throughput $tput
		}
		if {$tput > $maxthroughput} {
			set maxthroughput $tput
		}
	}
	::close $tfile
	
# 	puts $maxthroughput
	
	# padding 50nm to the left and right. However, the space between
	# min and max throughput wavelengths must at least be 50% of the plot 
	# width, so we decreasethe padding accordingly (narrow-band filters)
	set pad 50.
	set width [expr $wavemax - $wavemin]
	if {[expr $width/(2.*$pad)] < 1.} {
	    set pad [expr $width / 2.]
	}
# 	puts $pad
	set xmin [expr $wavemin - $pad]
	set xmax [expr $wavemax + $pad]
	set xlab [expr $cwl - $width/25.]
		
	# Delete previous image before loading a new one
	destroy $w_.throughputimage
	blt::graph $w_.throughputimage -title $title
	pack  $w_.throughputimage -in $w_.throughput
	$w_.throughputimage element create line -symbol none -linewidth 3 -color "#006699"  \
		-xdata $wavelength -ydata $throughput 
	$w_.throughputimage legend configure -hide yes
	$w_.throughputimage axis configure x -title {Wavelength [nm]} -min $xmin -max $xmax \
		-titlefont { Helvetica 12 } -tickfont { Helvetica 10 }
	$w_.throughputimage axis configure y -title {Throughput} -min 0.0 -max 1.0 \
		-titlefont { Helvetica 12 } -tickfont { Helvetica 10 }

	$w_.throughputimage marker create line -coords { $wavemin 0.0 $wavemin 1.0 } \
		-dashes dash -linewidth 2 -outline forestgreen
	$w_.throughputimage marker create line -coords { $wavemax 0.0 $wavemax 1.0 } \
		-dashes dash -linewidth 2 -outline forestgreen

	$w_.throughputimage marker create line -coords { $cwl 0.0 $cwl $cwl_throughput } \
		-dashes dash -linewidth 2 -outline red
	$w_.throughputimage marker create text -text [format "CWL = %d" $cwl] -rotate 90 \
		-coords { $xlab 0.2 } -font { Helvetica 14 } -outline red	

	update
    }
    
    #############################################################
    #  Name: ot_slit_add_dialog_buttons
    #
    #  Description:
    #   This function is called when init is run for an OT catalog.
    #	It creates the dialog buttons in the object table window.
    #
    #############################################################
    #############################################################
    protected method ot_slit_add_dialog_buttons {instType} {
	
	set home $::env(GMMPS)	

	# I know, stupid globals, but that's the only way I can make that work...
	global ::cbo_pointing ::cbo_grayscale ::cbo_maskarea

	# masking is always on for the OT display
	set cbo_maskarea 1

	# The master frame containing almost everything
	pack [frame $w_.masterFrame -borderwidth 2 -relief groove -background $ot_bg_ ] \
	    -side top -anchor w -padx 5 -pady 5 -ipadx 5 -ipady 5

	# The Help frame below
	pack [frame $w_.help -borderwidth 2 -relief groove -background $ot_bg_] \
	    -side top -anchor w -padx 5 -ipadx 5 -ipady 5 -fill x

	#############################################################
	#    There are four main frames: EDIT SHOW CONTROL
	#############################################################
	pack [frame $w_.editMainFrame -background $ot_bg_ ] \
	    -side left -anchor n -fill y -padx 5 -pady 5 -ipadx 5 -ipady 5 -in $w_.masterFrame

	pack [frame $w_.showMainFrame1 -background $ot_bg_] \
	    -side left -anchor n -fill y -padx 5 -pady 5 -ipadx 5 -ipady 5 -in $w_.masterFrame

	pack [frame $w_.controlMainFrame -background $ot_bg_] \
	    -side left -anchor n -fill y -padx 5 -pady 5 -ipadx 5 -ipady 5 -in $w_.masterFrame

	#############################################################
	#                The EDIT Main Frame
	#############################################################
	# Frame for editing slit parameters
	pack [frame $w_.editSlitFrame -background $ot_bg_] \
	    -side left -in $w_.editMainFrame -anchor n -fill x -padx 5 -ipadx 5

	# Frame for setting object priorities
	pack [frame $w_.editPriorityFrame -background $ot_bg_] \
	    -side left -in $w_.editMainFrame -anchor n -fill x -padx 5 -ipadx 5

	# The 5 slit parameters we keep available for editing
	pack \
	    [label $w_.slitLabel -text "(Bulk) Edit Slits" -bg $ot_bg_ -foreground "#55f" -anchor w] \
	    [frame $w_.slitEditSpacer1 -height 10 -bg $ot_bg_] \
	    [LabelEntry $w_.slitsize_x -text "Size X  :" -valuewidth 3 -labelwidth 10 -background $ot_bg_ \
		 -command [code $this _sel_parent Sall]] \
	    [LabelEntry $w_.slitsize_y -text "Size Y  :" -valuewidth 3 -labelwidth 10 -background $ot_bg_ \
		 -command [code $this _sel_parent Sall]] \
	    [LabelEntry $w_.slittilt   -text "Tilt    :" -valuewidth 3 -labelwidth 10 -background $ot_bg_ \
		 -command [code $this _sel_parent Sall]] \
	    [LabelEntry $w_.slitpos_x  -text "Offset X:" -valuewidth 3 -labelwidth 10 -background $ot_bg_ \
		 -command [code $this _sel_parent Sall]] \
	    [LabelEntry $w_.slitpos_y  -text "Offset Y:" -valuewidth 3 -labelwidth 10 -background $ot_bg_ \
		 -command [code $this _sel_parent Sall]] \
	    -side top -anchor w -in $w_.editSlitFrame -fill x
	
	pack [button $w_.updateslit -text "Update Slit(s)" -bg "#ff9" -fg $button_text_ot_ \
		  -activebackground "#ffb" -activeforeground $button_text_active_ot_ \
		  -command [code $this _sel_parent Sall] ] \
	    -side bottom -anchor w -in $w_.editSlitFrame -fill x


	# Apply colors to entry boxes of LabelEntry widgets.
	$w_.slitsize_y.entry configure -background $ot_bg_ -highlightbackground $ot_bg_
	$w_.slitsize_x.entry configure -background $ot_bg_ -highlightbackground $ot_bg_
	$w_.slittilt.entry   configure -background $ot_bg_ -highlightbackground $ot_bg_
	$w_.slitpos_y.entry  configure -background $ot_bg_ -highlightbackground $ot_bg_
	$w_.slitpos_x.entry  configure -background $ot_bg_ -highlightbackground $ot_bg_

	# Help
	add_short_help $w_.slitsize_x \
	    {{bitmap b1} = Edit slit length (<cr> updates just this item on selection!)}
	add_short_help $w_.slitsize_y \
	    {{bitmap b1} = Edit slit width (<cr> updates just this item on selection!)}
	add_short_help $w_.slittilt   \
	    {{bitmap b1} = Edit slit tilt (<cr> updates just this item on selection!)}
	add_short_help $w_.slitpos_x  \
	    {{bitmap b1} = Edit slit x-offset with respect to object (<cr> updates just this item on selection!)}
	add_short_help $w_.slitpos_y  \
	    {{bitmap b1} = Edit slit y-offset with respect to object (<cr> updates just this item on selection!)}
	add_short_help $w_.updateslit \
	    {{bitmap b1} = Update selected object with values from the edit fields}
	
	# Add the priority buttons
	pack \
	    [label $w_.prioLabel -text "Set Priority" -bg $ot_bg_ -foreground "#55f" -anchor w] \
	    [frame $w_.slitEditSpacer2 -height 10 -bg $ot_bg_] \
	    [button $w_.prio0button -text "Acquisition" -bg "#fcc" -fg $button_text_ot_ \
		 -activebackground "#fee" -activeforeground $button_text_active_ot_ \
		 -command [code $this _sel_parent 0]] \
	    [button $w_.prio1button -text "Priority 1" -bg "#fcc" -fg $button_text_ot_ \
		 -activebackground "#fee" -activeforeground $button_text_active_ot_ \
		 -command [code $this _sel_parent 1]] \
	    [button $w_.prio2button -text "Priority 2" -bg "#fcc" -fg $button_text_ot_ \
		 -activebackground "#fee" -activeforeground $button_text_active_ot_ \
		 -command [code $this _sel_parent 2]] \
	    [button $w_.prio3button -text "Priority 3" -bg "#fcc" -fg $button_text_ot_ \
		 -activebackground "#fee" -activeforeground $button_text_active_ot_ \
		 -command [code $this _sel_parent 3]] \
	    [button $w_.prioXbutton -text "Ignore" -bg "#fcc" -fg $button_text_ot_ \
		 -activebackground "#fee" -activeforeground $button_text_active_ot_ \
		 -command [code $this _sel_parent X]] \
	    -side top -anchor w -in $w_.editPriorityFrame -fill x

	# Help
	add_short_help $w_.prio0button {{bitmap b1} = Make this an acquisition object (Priority 0)}
	add_short_help $w_.prio1button {{bitmap b1} = Highest priority for this object (Priority 1)}
	add_short_help $w_.prio2button {{bitmap b1} = Second highest priority for this object (Priority 2)}
	add_short_help $w_.prio3button {{bitmap b1} = Third highest priority for this object (Priority 3)}
	add_short_help $w_.prioXbutton {{bitmap b1} = Ignore this object (Priority X)}


	##################################################################
	#               The SHOW Main Frame
	##################################################################
	pack [label $w_.gmmpsFuncLabel -text "Display options" -background $ot_bg_ -foreground #55f] \
	    [frame $w_.showSpacer1 -height 10 -bg $ot_bg_] \
	    -in $w_.showMainFrame1 -anchor w

	# CheckBoxes for plotting things
	# The OBJECTS checkbutton is defined in vmSkySearch as we need access to its plotting functions
	checkbutton $w_.plotCBO_slits -background $ot_bg_ -command [code $this slits_OT] \
	    -activebackground $button_bg_active_ot_ -text "Slits" -variable cbo_ot_slits
	checkbutton $w_.plotCBO_pointing -background $ot_bg_ -command [code $this drawBoundaries] \
	    -activebackground $button_bg_active_ot_ -text "Pointing center" -variable cbo_pointing
	checkbutton $w_.plotCBO_grayscale  -background $ot_bg_ -command [code $this toggle_grayscale] \
	    -activebackground $button_bg_active_ot_ -text "Grayscale" -variable cbo_grayscale

	# default states
	$w_.plotCBO_slits     deselect
	$w_.plotCBO_pointing  deselect
	$w_.plotCBO_grayscale select

	# Pack checkboxes
	# The objects checkbutton gets inserted at the top from within vmSkySearch
	pack $w_.plotCBO_slits    -in $w_.showMainFrame1 -anchor w
	pack $w_.plotCBO_pointing  -in $w_.showMainFrame1 -anchor w
	pack $w_.plotCBO_grayscale -in $w_.showMainFrame1 -anchor w

	# Help
	add_short_help $w_.plotCBO_slits    {{bitmap b1} = Displays the individual slits}
	add_short_help $w_.plotCBO_pointing {{bitmap b1} = Show the pointing center (CRPIX1/CRPIX2)}


	##################################################################
	#                 The CONTROL Main Frame
	##################################################################    
	pack [frame $w_.controlMainFrame.toplabel -background $ot_bg_] \
	    -side top -anchor w -fill x
	pack [frame $w_.controlMainFrame.toplabel.miniframe -relief sunken -borderwidth 2 -background $ot_bg_] \
	    -anchor w -side left
	pack [label $w_.l1 -text $instType -foreground #55f -background #ccf] \
	    -in $w_.controlMainFrame.toplabel.miniframe -anchor w -side left
	pack [label $w_.l2 -text "Mask Design" -background $ot_bg_ -foreground #55f] \
	    -in $w_.controlMainFrame.toplabel -anchor w -side left
	pack \
	    [frame $w_.spocSpacer1 -height 5 -bg $ot_bg_] \
	    [button $w_.spoc -text "Configure Mask" \
		 -bg #bfb -fg $button_text_ot_ \
		 -activebackground #dfd \
		 -activeforeground $button_text_active_ot_ \
		 -command [code $this export $instType]] \
	    -side top -in $w_.controlMainFrame -fill x
	
	if {$instType == "GMOS-N" || $instType == "GMOS-S"} {
	    pack [button $w_.defineBands -text "Configure Nod & Shuffle Mask" \
		      -bg "#bfb" -fg $button_text_ot_ \
		      -activebackground "#dfd" \
		      -activeforeground $button_text_active_ot_ \
		      -command [code $this define_bands]] \
		-side top -in $w_.controlMainFrame -fill x

	    add_short_help $w_.defineBands {{bitmap b1} = Configure a Nod & Shuffle mask}
	}
	
	pack \
	    [frame $w_.spacer -height 30 -bg $button_bg_ot_] \
	    [button $w_.reloadCat -text "Reload OT" \
		 -bg $button_bg_ot_ -fg $button_text_ot_ \
		 -activeforeground $button_text_active_ot_ \
		 -activebackground $button_bg_active_ot_ \
		 -command [code $this reload_catalog OT]] \
	    [button $w_.closeCat -text "Close OT" \
		 -bg $button_bg_ot_ -fg $button_text_ot_ \
		 -activebackground $button_bg_active_ot_ \
		 -activeforeground $button_text_active_ot_ \
		 -command [code $this close ]] \
	    -side top -in $w_.controlMainFrame -fill x
	
	add_short_help $w_.spoc      {{bitmap b1} = Configure a normal mask}
	add_short_help $w_.reloadCat {{bitmap b1} = Reload catalog from file}
	add_short_help $w_.closeCat  {{bitmap b1} = Close this catalog}

	##################################################################
	#                 The Help Main Frame
	##################################################################    
	pack [button $w_.helpOT -text "Help - About Object tables" -bg "#9ff" -fg "#000" \
		  -activebackground "#bff" -activeforeground "#000" \
		  -command [code $this help file://$home/html/OTformat.html] -anchor w] \
	    -side left -anchor w -in $w_.help -padx 10

	pack [button $w_.helpOTwindow -text "Help - This window" -bg "#9ff" -fg "#000" \
		  -activebackground "#bff" -activeforeground "#000" \
		  -command [code $this help file://$home/html/editOT.html] -anchor w] \
	    -side left -anchor w -in $w_.help -padx 10

	pack [button $w_.helpOTacqstars -text "Help - Acquisition stars" -bg "#9ff" -fg "#000" \
		  -activebackground "#bff" -activeforeground "#000" \
		  -command [code $this help file://$home/html/acquisition.html] -anchor w] \
	    -side left -anchor w -in $w_.help -padx 10

	# Lastly, update the boundaries such that they reflect the checkbutton choices

	drawBoundaries
	toggle_grayscale
    }

    ##########################################################################
    # Load the help pages
    ##########################################################################
    public method help {URL} {
	
	set browser [cat::vmAstroCat::get_browser]	
	if {$browser != ""} {
		exec $browser $URL &
	}
    }

    #############################################################
    # A nicer error dialog that does not suffer from HUGE fonts
    # This overrides a default skycat 'error_dialog' function
    #############################################################
    #############################################################
    public method error_dialog {message} {
	tk_messageBox -type ok -icon error -title Error -message $message
    }

    #############################################################
    # A nicer info dialog that does not suffer from HUGE fonts
    # This overrides a default skycat 'info_dialog' function
    #############################################################
    #############################################################
    public method info_dialog {message} {
	tk_messageBox -type ok -icon info -title Information -message $message
    }


    #############################################################
    # A nicer warn dialog that does not suffer from HUGE fonts
    # This overrides a default skycat 'warn_dialog' function
    #############################################################
    #############################################################
    public method warn_dialog {message} {
	tk_messageBox -type ok -icon warning -title Warning -message $message
    }


    #############################################################
    # A nicer choice dialog that does not suffer from HUGE fonts
    # This replaces the default skycat 'choice_dialog' function
    #############################################################
    #############################################################
    public method my_choice_dialog {msg {buttons "OK Cancel"} {default_button "OK"} {parent ""}} {

	if {"$parent" != ""} {
	    if {"[set parent [winfo toplevel $parent]]" == "."} {
		set parent ""
	    }
	}
	set w $parent.my_choice_dialog
	catch {destroy $w}
	
	set n -1
	set def 0
	foreach button $buttons {
	    set idx([incr n]) $button
	    if {"$button" == "$default_button"} {
		set def $n
	    }
	}

	set d [util::DialogWidget $w \
		   -title Choice \
		   -text $msg \
		   -bitmap question \
		   -transient 1 \
		   -default $def \
		   -messagewidth 5i \
		   -buttons $buttons \
		   -messagefont {Arial 12 bold} ]
	return $idx([$d activate])
    }


    #############################################################
    # A nicer input dialog that does not suffer from HUGE fonts
    # This replaces the default skycat 'choice_dialog' function
    #############################################################
    #############################################################
    public method my_input_dialog {msg {parent ""}} {
	
	if {"$parent" != ""} {
	    if {"[set parent [winfo toplevel $parent]]" == "."} {
		set parent ""
	    }
	}
	set w $parent.input_dialog
	catch {destroy $w}
	set d [InputDialog $w \
		   -title Input \
		   -text $msg \
		   -bitmap questhead \
		   -transient 1 \
		   -messagewidth 5i \
		   -default 0 \
		   -buttons {OK Cancel} \
		   -messagefont {Arial 12 bold}]
	return [$d activate]
    }

    
    #############################################################
    # A nicer confirm dialog that does not suffer from HUGE fonts
    # This replaces the default skycat 'choice_dialog' function
    #############################################################
    #############################################################
    public method my_confirm_dialog {msg {parent ""}} {
	
	if {"$parent" != ""} {
	    if {"[set parent [winfo toplevel $parent]]" == "."} {
		set parent ""
	    }
	}
	set w $parent.confirm_dialog
	catch {destroy $w}
	set d [util::DialogWidget $w \
		   -title Confirm \
		   -text $msg \
		   -bitmap questhead \
		   -transient 1 \
		   -default 0 \
		   -buttons {Yes Cancel} \
		   -messagefont {Arial 12 bold}]
	return [expr {[$d activate] == 0}]
    }

    
    #############################################################
    #  Name: odf_slit_add_dialog_buttons
    #
    #  Description:
    #   This function is called when an ODF is loaded.
    #	It creates the dialog buttons.
    #
    #############################################################
    #############################################################
    protected method odf_slit_add_dialog_buttons {instType} {

	set home $::env(GMMPS)	

	# Globals...
	global ::cbo_2ndorder ::cbo_maskarea ::cbo_acqonly ::cbo_indwave
	global ::cbo_pointing ::cbo_specbox ::cbo_shading ::cbo_grayscale ::cbo_showwave
	global oldODFwarning outsidewarning_shown R600warning_shown oldwavelength_warning_shown

	# reset a warning
	set outsidewarning_shown 0
	set R600warning_shown 0
	set oldwavelength_warning_shown 0
	
	##########################################################
	# Main frame setup
	##########################################################
	pack [frame $w_.odfLeft -background $odf_bg_] \
	    -side left -anchor w

	pack [frame $w_.odfMainFrame -borderwidth 2 -relief groove -background $odf_bg_] \
	    -side top -anchor w -padx 5 -pady 5 -ipadx 5 -ipady 5 -in $w_.odfLeft

	pack [frame $w_.odfEmLineFrame -borderwidth 2 -relief groove -background $odf_bg_] \
	    -side top -anchor w -padx 5 -pady 5 -ipadx 5 -ipady 5 -in $w_.odfLeft -fill x

	pack [frame $w_.help -borderwidth 2 -relief groove -background $odf_bg_] \
	    -side top -anchor w -padx 5 -pady 5 -ipadx 5 -ipady 5 -in $w_.odfLeft -fill x

	pack [frame $w_.helpTop -background $odf_bg_] \
	    -side top -anchor w -in $w_.help -fill x

	pack [frame $w_.helpBottom -background $odf_bg_] \
	    -side top -anchor w -in $w_.help -fill x

	pack [frame $w_.odfInfoFrame -borderwidth 2 -relief groove -background $odf_bg_] \
	    -side left -anchor w -padx 5 -pady 5 -ipadx 5 -ipady 5


	##########################################################
	# The two frames containing the checkbuttons, 
	# and one for the Reload/Close buttons
	##########################################################
	pack \
	    [frame $w_.odfButtonFrame1 -background $ot_bg_] \
	    -in $w_.odfMainFrame -fill x -padx 10 -pady 10 -side left -anchor n
	pack \
	    [frame $w_.odfButtonFrame2 -background $ot_bg_] \
	    -in $w_.odfMainFrame -fill x -padx 10 -pady 10 -side left -anchor s
	pack \
	    [frame $w_.odfButtonFrame3 -background $ot_bg_] \
	    -in $w_.odfMainFrame -fill x -padx 10 -pady 10 -side left -anchor n

	# CheckBoxes for plotting things
	# The OBJECTS checkbutton is defined in vmSkySearch as we need access to its plotting functions
	checkbutton $w_.odfPlotCBO_specbox   -background $ot_bg_ -command [code $this slits_ODF] \
	    -activebackground $button_bg_active_ot_ -text "Slits & Spectra" -variable cbo_specbox
	checkbutton $w_.odfPlotCBO_shading   -background $ot_bg_ -command [code $this slits_ODF] \
	    -activebackground $button_bg_active_ot_ -text "Shading" -variable cbo_shading -disabledforeground #666
	checkbutton $w_.odfPlotCBO_showwave  -background $ot_bg_ -command [code $this slits_ODF] \
	    -activebackground $button_bg_active_ot_ -text "Wavelengths" -variable cbo_showwave -disabledforeground #666
	checkbutton $w_.odfPlotCBO_2ndorder   -background $ot_bg_ -command [code $this slits_ODF] \
	    -activebackground $button_bg_active_ot_ -text "Order overlap" -variable cbo_2ndorder -disabledforeground #666
	checkbutton $w_.odfPlotCBO_pointing  -background $ot_bg_ -command [code $this drawBoundaries] \
	    -activebackground $button_bg_active_ot_ -text "Pointing center" -variable cbo_pointing
	checkbutton $w_.odfPlotCBO_maskarea  -background $ot_bg_ -command [code $this drawBoundaries] \
	    -activebackground $button_bg_active_ot_ -text "Slit placement area" -justify left -variable cbo_maskarea
	checkbutton $w_.odfPlotCBO_grayscale -background $ot_bg_ -command [code $this toggle_grayscale] \
	    -activebackground $button_bg_active_ot_ -text "Grayscale" -variable cbo_grayscale
	checkbutton $w_.odfPlotCBO_acqonly   -background $ot_bg_ -command [code $this slits_ODF "acqOnly"] \
	    -activebackground $button_bg_active_ot_ -text "Highlight acq stars" -variable cbo_acqonly

	checkbutton $w_.odfPlotCBO_indwave -background $ot_bg_ -command [code $this slits_ODF] \
	    -activebackground $button_bg_active_ot_ -text "Show other wavelengths \[nm\]" -variable cbo_indwave \
	    -disabledforeground #666

	# default states
	$w_.odfPlotCBO_specbox   deselect
	$w_.odfPlotCBO_shading   select
	$w_.odfPlotCBO_showwave  select

	# No order overlap for F2
	if {$instType == "GMOS-N" || $instType == "GMOS-S"} {
	    $w_.odfPlotCBO_2ndorder  select
	} else {
	    $w_.odfPlotCBO_2ndorder  deselect
	    $w_.odfPlotCBO_2ndorder configure -state disabled
	}

	$w_.odfPlotCBO_pointing  deselect
	$w_.odfPlotCBO_maskarea  select
	$w_.odfPlotCBO_grayscale select
	$w_.odfPlotCBO_acqonly   deselect
	$w_.odfPlotCBO_indwave   deselect

	# Pack checkboxes

	# Button frame 1
	# The objects checkbutton gets inserted at the top from within vmSkySearch
	pack [label $w_.odfButtonLabel -text "Display options" -background $ot_bg_ -foreground #55f] \
	    -in $w_.odfButtonFrame1 -anchor w -ipady 5
	pack $w_.odfPlotCBO_specbox  -in $w_.odfButtonFrame1 -anchor w
	pack $w_.odfPlotCBO_shading  -in $w_.odfButtonFrame1 -anchor w
	pack $w_.odfPlotCBO_showwave -in $w_.odfButtonFrame1 -anchor w
	pack $w_.odfPlotCBO_2ndorder -in $w_.odfButtonFrame1 -anchor w
	pack $w_.odfPlotCBO_grayscale -in $w_.odfButtonFrame1 -anchor w

	# Button frame 2

	# Add a SpinBox to display a change in CWL
	if { $instType == "GMOS-N" || $instType == "GMOS-S"} {
	    set OdfCWL [get_keyword "#fits WAVELENG" $itk_option(-catalog)]
	    set home $::env(GMMPS)
	    image create photo undoarrow -format GIF -file $home/src/undoarrow.gif
	    pack \
		[frame $w_.odfCWLFrame -background $odf_bg_ ] \
		-side top -anchor w -fill x -padx 5 -ipadx 5 -ipady 5 \
		-in $w_.odfButtonFrame2
	    pack \
		[label $w_.odfCWLLabel -text "CWL:" -anchor w -background $odf_bg_ ] \
		[spinbox $w_.odfCWLSpinBox -from 350 -to 1050 -increment 1 -background $odf_bg_ \
		     -width 6 -justify right \
		     -command [code $this slits_ODF] ] \
		-side left -in $w_.odfCWLFrame -expand 1 -fill x
	    pack \
		[button $w_.odfCWLUndoButton -image undoarrow -command [code $this reset_CWL] ] \
		-side right -in $w_.odfCWLFrame -expand 1 -fill x -padx 10
	    $w_.odfCWLSpinBox set $OdfCWL
	    bind $w_.odfCWLSpinBox <Return> [code $this slits_ODF]
	    add_short_help $w_.odfCWLSpinBox    {{bitmap b2} = Display the spectra for a different CWL}
	    add_short_help $w_.odfCWLUndoButton {{bitmap b2} = Reset the CWL to the value in the ODF}
	}

	pack $w_.odfPlotCBO_acqonly   -in $w_.odfButtonFrame2 -anchor w
	pack $w_.odfPlotCBO_maskarea  -in $w_.odfButtonFrame2 -anchor w
	pack $w_.odfPlotCBO_pointing  -in $w_.odfButtonFrame2 -anchor w
	
	# Help
	add_short_help $w_.odfPlotCBO_acqonly   {{bitmap b1} = Show acquisition sources only}
	add_short_help $w_.odfPlotCBO_maskarea  {{bitmap b1} = Show the area where slitlets may be placed}
	add_short_help $w_.odfPlotCBO_pointing  {{bitmap b1} = Show the pointing center (CRPIX1/CRPIX2)}
	add_short_help $w_.odfPlotCBO_showwave  {{bitmap b1} = Show wavelength labels and markers}
	add_short_help $w_.odfPlotCBO_shading   {{bitmap b1} = Shade the spectral footprints}
	add_short_help $w_.odfPlotCBO_2ndorder  {{bitmap b1} = Show order overlap}
	add_short_help $w_.odfPlotCBO_grayscale {{bitmap b1} = Toggles grayscale and classic skycat color maps}

	# Button frame 3
	pack [label $w_.odfButtonLabel2 -text "Catalog options" -background $ot_bg_ -foreground #55f] \
	    -in $w_.odfButtonFrame3 -anchor w -ipady 5
	pack \
	    [button $w_.odfCloseCat -text "Close ODF" \
		 -bg $button_bg_ot_ -fg $button_text_ot_ \
		 -activebackground $button_bg_active_ot_ \
		 -activeforeground $button_text_active_ot_ \
		 -command [code $this close ]] \
	    [button $w_.odfReloadCat -text "Reload ODF" \
		 -bg $button_bg_ot_ -fg $button_text_ot_ \
		 -activeforeground $button_text_active_ot_ \
		 -activebackground $button_bg_active_ot_ \
		 -command [code $this reload_catalog ODF]] \
	    -side bottom -anchor s -in $w_.odfButtonFrame3 -fill both

	add_short_help $w_.odfPlotCBO_specbox {{bitmap b1} = Plot slits and spectrum overlay}
	add_short_help $w_.odfReloadCat       {{bitmap b1} = Reload catalog from file}
	add_short_help $w_.odfCloseCat        {{bitmap b2} = Close catalog window}


	##################################################################
	#   Individual wavelength overlays
	##################################################################    
	pack [frame $w_.odfEmLineFrame.sub1 -background $ot_bg_] \
	    -side left -anchor w -fill both \
	    -in $w_.odfEmLineFrame
	pack [frame $w_.odfEmLineFrame.sub2 -background $ot_bg_] \
	    -side left -anchor w -fill both -padx 5 \
	    -in $w_.odfEmLineFrame
	pack $w_.odfPlotCBO_indwave -in $w_.odfEmLineFrame.sub1 -anchor w
	pack [entry $w_.odfWavelengthEdit -width 50 -background $ot_bg_] \
	    -side top -anchor w -in $w_.odfEmLineFrame.sub1 -expand 1 -fill x	
	pack [label $w_.odfRedshiftLabel -text "Redshift:" -background $ot_bg_] \
	    -in $w_.odfEmLineFrame.sub2 -anchor w
	global default_redshift
	pack [entry $w_.odfRedshiftEdit \
		  -width 3 \
		  -background $ot_bg_ ]\
	    -side top -anchor w -in $w_.odfEmLineFrame.sub2 -expand 1 -fill x 
	bind $w_.odfWavelengthEdit <Return> [code $this slits_ODF]
	bind $w_.odfRedshiftEdit   <Return> [code $this slits_ODF]

	add_short_help $w_.odfWavelengthEdit {{bitmap b1} = Blank-separated list of wavelengths}
	add_short_help $w_.odfRedshiftEdit   {{bitmap b1} = Optional redshift for wavelengths}

	##################################################################
	#                 The Help Main Frame
	##################################################################    
	pack [button $w_.helpODFwindow -text "Help - This window" -bg #9ff -fg #000 \
		  -activebackground #bff -activeforeground #000 \
		  -command [code $this help file://$home/html/loadODF.html] -anchor w] \
	    -side left -anchor w -in $w_.helpTop -padx 10 -pady 5

	pack [button $w_.helpODFotsetup -text "Help - Observing Tool setup" -bg #9ff -fg #000 \
		  -activebackground #bff -activeforeground #000 \
		  -command [code $this help file://$home/html/loadODF.html#observing-tool-setup] -anchor w] \
	    -side left -anchor w -in $w_.helpTop -padx 10 -pady 5

	pack [button $w_.helpODFmaskcheck -text "Mask check instructions" -bg #9ff -fg #000 \
		  -activebackground #bff -activeforeground #000 \
		  -command [code $this help file://$home/html/ngo.html] -anchor w] \
	    -side left -anchor w -in $w_.helpBottom -padx 10 -pady 5

	# The ODF info window
	text $w_.odfInfoFrame.03 -width 40 -height 10 -setgrid true -wrap none \
	    -xscrollcommand [list $w_.odfInfoFrame.01 set] \
	    -yscrollcommand [list $w_.odfInfoFrame.02 set] \
	    -background white
	scrollbar $w_.odfInfoFrame.01 \
	    -command [list $w_.odfInfoFrame.03 xview] -orient horiz
	scrollbar $w_.odfInfoFrame.02 \
	    -command [list $w_.odfInfoFrame.03 yview] -orient vert
	pack $w_.odfInfoFrame.01 -side bottom -fill x
	pack $w_.odfInfoFrame.02 -side right -fill y
	pack $w_.odfInfoFrame.03 -side left -fill both -expand true
	pack $w_.odfInfoFrame -side left -fill both -expand true
	
	# Update the image display with the button choices
	drawBoundaries

	toggle_grayscale

	# Cleanup potential leftover stuff
	catch {file delete gemwm.input}
	catch {file delete gemwm.output}

	# Warning if loading old ODFs
	if {$oldODFwarning} {

	    if {$instType == "GMOS-N" || $instType == "GMOS-S"} {
		set ODF_shuffleMode ""
		set ODF_shuffleMode [get_keyword "#fits SHUFMODE" $itk_option(-catalog)]
		set ODF_shuffleMode [regsub -all "\[' \t]+" $ODF_shuffleMode {}]
		if {$ODF_shuffleMode != ""} {
		    warn_dialog "This Nod & Shuffle mask was created with an old version (< v1.4.5) of GMMPS. Nod & Shuffle regions and Observing Tool parameters will not be shown."
		} else {
		    warn_dialog "This mask was created with an old version (< v1.4.5) of GMMPS."
		}
	    } else {
		warn_dialog "This mask was created with an old version (< v1.4.5) of GMMPS."
	    }
	}
    }


    #############################################################
    #  Name: toggle_grayscale
    #
    #  Description:
    #  Toggles between grayscale and classic skycat color maps
    #
    #############################################################
    #############################################################
    protected method toggle_grayscale {} {
	global ::cbo_grayscale
	global rtd_library

	if {$cbo_grayscale == 1} {
	    image2 cmap file $rtd_library/colormaps/ramp.lasc
	} else {
	    image2 cmap file $rtd_library/colormaps/real.lasc
	}
    }


    #############################################################
    #  Name: symbol
    #
    #  Description:
    #   This function is used to retrieve from the image information
    #   and to write that information, including the symbol information
    #   to the catalog file.
    #
    #############################################################
    #############################################################
    public proc symbol {name} {
	
	#  Open a file name.tmp for appending.
	#  Put in:
	#    the query results, 
	#    how to draw the symbols
	#    also fits keyword information that we extracted above.
	#    Finish with an "End config entry" line.
	#
	set tmp [open $name.tmp a]
	puts $tmp "QueryResult"
	puts $tmp ""
	puts $tmp "# Config entry for original catalog server:"
	puts $tmp "serv_type: local"
	puts $tmp "long_name: $name"
	puts $tmp "short_name: [file tail $name]"
	puts $tmp "url: $name"
	puts $tmp "symbol: \{x_ccd y_ccd priority\} \{diamond magenta \{\} \{\} \{\} \{\$priority == \"0\"\}\} \{20 \{\}\}:\{x_ccd y_ccd priority\} \{circle red \{\} \{\} \{\} \{\$priority == \"1\"\}\} \{15 \{\}\}:\{x_ccd y_ccd priority\} \{square green \{\} \{\} \{\} \{\$priority == \"2\"\}\} \{15 \{\}\}:\{x_ccd y_ccd priority\} \{triangle turquoise \{\} \{\} \{\} \{\$priority == \"3\"\}\} \{15 \{\}\}:\{x_ccd y_ccd priority\} \{cross yellow \{\} \{\} \{\} \{\$priority == \"X\"\}\} \{15 \{\}\}"
	puts $tmp "# Fits keywords"
	set buffer ""
	catch { set buffer [exec grep #fits $name ] }
	puts $tmp "$buffer"
	puts $tmp "# End fits keywords"
	puts $tmp "# Curved slits"
	puts $tmp "# End curved slits"
	puts $tmp "# End config entry"
	::close $tmp
	
	#  Grep in the catalog file the line "End config entry" and get
	#  the line number.  Which will give you the line where the
	#  headers and data actually starts.
	#  Then append to the above written name.tmp file all of the header
	#  and data out of the original configuration file.  
	#  Then move name.tmp to name.
	set n [exec grep -n "# End config entry" $name | cut -d: -f1]
	set n [expr $n + 1]
	
	exec tail -n +$n $name >> $name.tmp
	catch {file delete $name}
	file rename -force $name.tmp $name
    }


    #############################################################
    #  Name: check_proximity_parent
    #
    #  Description:
    #   Needed to check how close acquisition sources come to 
    #   detector gaps and field boundaries
    #
    #############################################################
    #############################################################
    protected method check_proximity_parent {} {
	
	set target_canvas_ .skycat1.image.imagef.canvas
	set target_image_ image2
	set catname $itk_option(-catalog)
	set instType $itk_option(-instType)
	set head $itk_option(-headingx)
	set PRIORITY  [lsearch -regex $head {(?i)priority}]
	set ID        [lsearch -regex $head {(?i)ID}]
	set OBJX      [lsearch -regex $head {(?i)x_ccd}]
	set OBJY      [lsearch -regex $head {(?i)y_ccd}]

	set nobj [$results_ total_rows]

	if {$nobj == 0} {
	    return
	}

	set proximity_alert ""
	for {set n 0} {$n < $nobj} {incr n} {
	    set row [lindex $info_ $n]
	    # object ID, coordinates and priority
	    set obj_id [lindex $row $ID]
	    set xobj [lindex $row $OBJX]
	    set yobj [lindex $row $OBJY]
	    set prior [lindex $row $PRIORITY]

	    if {$prior == 0} {
		set proximity_alert [check_proximity $xobj $yobj $obj_id]
		if {[string match *ERROR* $proximity_alert] == 1} { 
		    error_dialog $proximity_alert
		    return "ERROR"
		}
	    }
	}
    }

    #############################################################
    #  Name: export
    #
    #  Description:
    #   This function is called when the "Configure Mask(s)" button
    #   is pressed. It creates the Master ODF file(s). 
    #   It calls the gmmps_spoc method.  Which will bring up
    #	  the popup to allow you to run the spoc algorithm.
    #
    #############################################################
    #############################################################
    public method export {instType} {
	
	if {($instType == "GMOS-S" && $NAXIS1 == "6218" && $NAXIS2 == "4608") ||
	    ($instType == "GMOS-N" && $NAXIS1 == "6218" && $NAXIS2 == "4608")} {
	    error_dialog "This is an old GMOS pseudo-image representing the detector geometry GMOS had before the Hamamatsu detector upgrade.\nNew, and much more precise, pseudo-image transformations have been obtained since.\nTo create a new pseudo-image and mask design, you must use Gemini IRAF v1.14 (or later) available through AstroConda at\nhttp://astroconda.readthedocs.io/ ."
	    return
	}

	# Make sure slit tilts are valid.
	if {[check_tilts -45.0 45.0 ]} {
	    return
	}
	
	# Find detector info.
	setDetInfo $instType
	
	# Leave with an error if one of the acquisition boxes is too close
	# to a gap or the mask area boundary
	set proximity_alert [check_proximity_parent]
	if {$proximity_alert != ""} {
	    return
	}

	#  Call the gmmps_spoc.tcl init function

	# Destroy any spoc window before opening a new one
	catch {destroy $spoc_}

	set globallist [list $CRPIX1 $CRPIX2 $PA $RA $DEC $NAXIS1 $NAXIS2 $DISPDIR \
			    $PIXSCALE $DETDIMX $DETDIMY $DETXMIN $DETXMAX $DETYMIN $DETYMAX]

	set spoc_ [utilReUseWidget cat::gmmps_spoc .skycat1.spoc \
		       $this $itk_option(-catalog) $itk_option(-binning) $this.results $instType \
		       $config_file_ $DET_IMG_ $DET_SPEC_ $globallist]
    }


    #############################################################
    #  Name: check_tilts
    #
    #  Description:
    #   Makes sure there are no invalid slittilts in the catalog. 
    #############################################################
    #############################################################
    protected method check_tilts {min max} {

	# Make sure there are no invalid slittilts.
	set rows [$this.results get_contents ]
	set columns [$this.results get_headings ]
	set tilt_col [lsearch  -regex $columns {(?i)slittilt} ]
	set id_col [lsearch -regex $columns {(?i)ID} ]
	set prio_col [lsearch -regex $columns {(?i)priority} ]
	set bad_tilt_rows [list ]
	
	# No slit tilts are good slit tilts.
	if {$tilt_col == -1} {
	    return 0
	}

	set cnt 0
	set changed 0
	foreach row $rows {
	    set tilt [format %.6f [lindex $row $tilt_col ]]

	    set id [lindex $row $id_col ]

	    # Exit if IDs are not integers
	    if { ![string is integer $id]} {
		error_dialog "Error: Object ID (first column) must be an integer!\n."
		return 1
	    }
	    
	    if {$tilt > $max || $tilt < $min} {
		set choice [my_choice_dialog "Tilted slits (object $id) not allowed in Nod&Shuffle masks!" {{Ignore Object} {Reset Angle to 0.0} Cancel} {Ignore Object} $w_]
		if {$choice == "Cancel"} {
		    return 1
		} elseif {$choice == "Reset Angle to 0.0" } {
		    set newrow [lreplace $row $tilt_col $tilt_col 0.000000 ]
		    $this.results set_row $row $newrow
		    set changed 1
		} elseif {$choice == "Ignore Object" } {
		    set newrow [lreplace $row $prio_col $prio_col "X" ]
		    $this.results set_row $row $newrow
		    set changed 1
		}		
		incr cnt
	    }
	}
	
	# Save changes to file.
	if {$changed} {
	    $this.results save_to_file $itk_option(-catalog) [$this.results get_contents ] "" 1
	}
	
	return 0
    }



    #############################################################
    #  Name: layout_dialog
    #
    #  Description:
    #   Do the dialog window layout.  Specifically:
    #     Open the catalog
    #     Add the menu bar and search options,
    #     Get the named servers
    #     create a results_ table 
    #     Add the dialog buttons and progress bar
    #############################################################
    #############################################################
    protected method layout_dialog {} {
	set instType $itk_option(-instType)
	set catType  $itk_option(-catType)

	set checkerror [open_catalog]
	if {$checkerror == "wrongfiletype"} {
	    return "wrongfiletype"
	}

	if {$catType <= 4} {
	    add_menubar
	    add_search_options
	}

	# If not an image server, then assume its our type.
	if {$iscat_ && $catType <= 4} {
	    add_result_table
	}
	
	# Add bindings for GUI editing.
	# Load colorscheme.
	if {$catType == 1 || $catType == 3} {
	    # load OT colorscheme.
	    set bg $ot_bg_
	    set bg2 $ot_bg2_
	    set fg_text $ot_text_
	    set catalog_bg_active $catalog_bg_active_ot_
	    set catalog_text_active $catalog_text_active_ot_
	    set catalog_bg $catalog_bg_ot_
	    set catalog_text $catalog_text_ot_
	    set button_bg $button_bg_ot_
	    set button_text $button_text_ot_
	    set button_bg_active $button_bg_active_ot_
	    set button_text_active $button_text_active_ot_
	    set menu_bg $menu_bg_ot_
	    set menu_text $menu_text_ot_
	    set menu_bg_active $menu_bg_active_ot_
	    set menu_text_active $menu_text_active_ot_
	} elseif {$catType == 2 || $catType == 4} {
	    # load ODF colorscheme.
	    set bg $odf_bg_
	    set bg2 $odf_bg2_
	    set fg_text $odf_text_
	    set catalog_bg_active $catalog_bg_active_odf_
	    set catalog_text_active $catalog_text_active_odf_
	    set catalog_bg $catalog_bg_odf_
	    set catalog_text $catalog_text_odf_
	    set button_bg $button_bg_odf_
	    set button_text $button_text_odf_
	    set button_bg_active $button_bg_active_odf_
	    set button_text_active $button_text_active_odf_	
	    set menu_bg $menu_bg_odf_
	    set menu_text $menu_text_odf_
	    set menu_bg_active $menu_bg_active_odf_
	    set menu_text_active $menu_text_active_odf_
	}

	# Change tables settings here because the widget doesn't seem to want to 
	# listen to args we pass in.  

	set tableheight 18
	set tablewidth 80

	$results_ configure \
	    -height $tableheight \
	    -width $tablewidth \
	    -background $bg \
	    -foreground $fg_text \
	    -selectbackground $catalog_bg_active \
	    -selectforeground $catalog_text_active \
	    -activebackground $button_bg_active \

	$results_.listbox configure \
	    -background $catalog_bg \
	    -foreground $catalog_text
	$results_.headbox configure \
	    -background $catalog_bg \
	    -foreground $catalog_text \
	    -selectbackground $catalog_bg \
	    -selectforeground $catalog_text
	$results_.tf configure \
	    -background $bg
	$results_.vf.vscroll configure  \
	    -troughcolor $bg2 \
	    -background $button_bg
	$results_.hf.hscroll configure  \
	    -troughcolor $bg2 \
	    -background $button_bg
	
	#  Change menu colors here. 
	$w_.menubar configure \
	    -background $menu_bg \
	    -highlightbackground $menu_bg_active\
	    -highlightcolor $menu_text_active
	
	$w_.menubar.file configure \
	    -background $menu_bg \
	    -foreground $menu_text \
	    -activebackground $menu_bg_active\
	    -activeforeground $menu_text_active 

	$w_.menubar.edit configure \
	    -background $menu_bg \
	    -foreground $menu_text \
	    -activebackground $menu_bg_active\
	    -activeforeground $menu_text_active 
	
	$w_.menubar.options configure \
	    -background $menu_bg \
	    -foreground $menu_text \
	    -activebackground $menu_bg_active\
	    -activeforeground $menu_text_active

	return
    }


    #############################################################
    #  Name: make_short_help
    #
    #  Description:
    #   Add a short help window and set the help texts
    #############################################################
    #############################################################
    protected method make_short_help {} {
	TopLevelWidget::make_short_help
	
	add_short_help $results_ \
	    {Query results: {bitmap b1} = select object, \
		 double click {bitmap b1} = label object, \
		 {bitmap dragb2} = scroll list}
    }


    #############################################################
    #  Name: select_catalog
    #
    #  Description:
    #   This proc is called when the named catalog is selected from the menu.
    #   It will check for specific column headings, set flags if the PRIORITY
    #   slittype, and X/Y column headings are missing. It will then open
    #   the catalog and save an instance of it.
    #
    #  Args:
    #   name is the name of the catalog file.
    #
    #   serv_type is the type of the catalog: one of: catalog, archive, 
    #   local, imagesvr, etc...
    #
    #   id is an optional unique id to be associated with a new catalog widget.
    #	Not used at all?
    #
    #   classname is the name of the vmAstroCat subclass to use to create new
    #   catalog widgets (defaults to "vmAstroCat").
    #
    #   $debug is a flag set from the command line arg.
    #
    #   $w should be the top level window of the caller (optional).
    #############################################################
    #############################################################
    public proc select_catalog {name serv_type id classname {debug 0} tType {w ""} instType} {

	#  Declare global var.s
	# WARNING, have to attach these global variables to a specific
	# window.  Otherwise, when I open another window where slitsize_x
	# is there, and then go back to the original window, where it isn't
	# addXSIZE will be invalid.

	global acDebugLevel
	set acDebugLevel 0

	set itk_option(-prior) "no"
	set itk_option(-xsize) "no"
	set itk_option(-ysize) "no"
	set itk_option(-tilt) "no"
	set itk_option(-stype) "no"
	set itk_option(-xoffset) "no"
	set itk_option(-yoffset) "no"
	set itk_option(-redshift) "no"
	set itk_option(-catType) $tType
	set itk_option(-binning) 1

	#  This type of file should be a FITS file, read it
	#  in and convert to a catalog file.
	if { $tType == 3 || $tType == 4} {
	    set index1 [string last . $name ]
	    if { $index1 != -1 } {
		set index1 [expr $index1 - 1 ]
		set inName [string range $name 0 $index1 ]
	    } else {
		set inName $name
	    }
	    set x -1
	    if {[catch {set x [ readInFitsFile $inName]} msg]} {
		error_dialog $msg
		return
	    } else {
		if { $x == -1 } {
		    return
		} else {
		    set name [append inName ".cat"]
		    # @@cba: get the image info in the cat file!
		    symbol $name
		}
	    }
	} elseif {$tType == 1 || $tType == 2} {
	    #  ELSE this should be a catalog file, grep for "QueryResult"
	    #  should be there for a catalog file.
	    set catCheck ""
	    catch {set catCheck [ exec grep QueryResult $name ] }
	    if { $catCheck == "" } {
		error_dialog "Error! This does not appear to be a valid OT/ODF ASCII catalog file."
		return 
	    }
	}
	
	# Set the pixel scale.
	set pixelScale [get_pixelscale_image]
	if {$pixelScale == 0.0 || $pixelScale == "NOT FOUND"} {
	    error_dialog "ERROR: Invalid preimage. Could not identify pixel scale!"
	    return
	}

	# Set instrument type from image (and catalog if unsuccessful) if it is not already set.
	# Executed if OT (ODF) catalog is loaded for the first time
	if {$instType == "NONE" && $tType <= 4} {
	    set instType [getInstType $name]
	    if {$instType == "NOT FOUND"} {
		error_dialog "ERROR: Could not identify which instrument you want to create a mask for!"
		return
	    }
	}

	if {$tType == 5 || $tType == 6 || $tType == 7} {
	    set instType "GMOS-N"
	} elseif {$tType == 8 || $tType == 9 || $tType == 10} {
	    set instType "GMOS-S"
	}

	# Get the binning factor from the pixel scale.
	# Do not get it from the header, because sometimes users tamper with the 
	# images and/or use custom software that does not set the CCDSUM keyword 
	# correctly.
	# We recognize the binning if within 15% of the expected values
	set itk_option(-binning) 1
	set nativeScale 0.0

	if {$instType == "GMOS-N"} {
	    set nativeScale 0.0807
	} elseif {$instType == "GMOS-S"} {
	    set nativeScale 0.0800
	} elseif {$instType == "F2"} {
	    set nativeScale 0.1792
	} elseif {$instType == "F2-AO"} {
	    # needs to be verified and must be the same as the numeric value used in Gemini/IRAF
	    set nativeScale 0.0896
	} else {
	    error_dialog "Unknown instrument type: $instType"
	    return
	}

	set ratio [expr $pixelScale / $nativeScale]
	set ratio_round [expr {round($ratio)}]
	set deviation [expr abs(($pixelScale - $ratio_round * $nativeScale) / $pixelScale)]

	# In principle, this tolerance could be much smaller, but until recently the
	# pseudo-images were resampled to the EEV pixel scale rather than the Hamamatsu
	# pixel scale...
	if {$deviation <= 0.15} {
	    set itk_option(-binning) $ratio_round
	} else {
	    error_dialog "Could not determine binning factor! Pixel scale ($PIXSCALE) deviates by more than 15% from nearest integer multiple of the native pixel scale, $nativeScale"
	    return
	}

	global oldODFwarning

	set ODFteststring [get_keyword "#fits ANAMORPH" $name]
	if {$ODFteststring != ""} {
	    # This is an ODF! Check GMMPS version
	    set gmmpsversion [check_ODF_version $name]
	}


	# Also, rewrite file making sure the catalog data are tab-separated. 
	# Get the column headings and save them.

	# Search for the line with all the "----------"
	set buffer [exec grep -n --regexp "^--" $name]
	set headlen [exec echo $buffer | cut -d: -f1]
	set ncol [exec echo $buffer | wc -w]

	set cat [open $name r ]
	set cattmp [open $name.tmp w ]
	
	# Copy all the header lines from the catalog into the new catalog.
	for {set n 1} {$n <= $headlen} {incr n 1} {
	    gets $cat line
	    puts $cattmp $line
	}
	
	# We do no want space separated lists, we want tab separated lists.
	while {[gets $cat line ] >= 0} {
	    set line [concat $line ]
	    set line [join $line "\t" ]
	    puts $cattmp $line
	}
	
	::close $cat
	::close $cattmp

	file rename -force $name.tmp $name

	# Extract the column header line and check for keyword presence

	set found_header_line 0
	set columnheadings ""
	catch { set asciifile [open $name r] }
	while {[gets $asciifile line] >= 0} {
	    # remove all leading and trailing white space
	    # condense internal white space to single blanks
	    set line [string trim $line ]
	    set line [regsub -all "\[ \t]+" $line { }]
	    # search for the end of the config entry
	    if {[string match "# End config entry" $line] == 1} {
		set found_header_line 1
	    }
	    # If the end config entry was found, search for the next non-empty line.
	    # This must be the header line.
	    if {$found_header_line == 1 && $line != "" && $line != "# End config entry"} {
		set columnheadings $line
		break
	    }
	}

	if {$columnheadings == ""} {
	    error_dialog "ERROR: $name appears to be a badly formatted input catalog!"
	    return
	}

	if { [lsearch -exact $columnheadings ID    ] == -1 ||
	     [lsearch -exact $columnheadings RA    ] == -1 ||
	     [lsearch -exact $columnheadings DEC   ] == -1 ||
	     [lsearch -exact $columnheadings MAG   ] == -1 ||
	     [lsearch -exact $columnheadings x_ccd ] == -1 ||
	     [lsearch -exact $columnheadings y_ccd ] == -1} {
	    error_dialog "ERROR: One or more of the following mandatory columns are missing in $name: ID RA DEC MAG x_ccd y_ccd. Note that these are CASE SENSITIVE!"
	    return
	}
	
	# When reading in the ASCII catalog, check for missing columns
	# If we didn't find the extra columns we need then
	# set the flag to indicate we need to add them.
	if { $tType == 1 || $tType == 3} {
	    if { [lsearch -exact $columnheadings slitsize_x ] == -1} {
		set itk_option(-xsize) "yes"
	    }
	    if { [lsearch -exact $columnheadings slitsize_y ] == -1} {
		set itk_option(-ysize) "yes"
	    }
	    if { [lsearch -exact $columnheadings slittilt ] == -1} {
		set itk_option(-tilt) "yes"
	    }
	    if { [lsearch -exact $columnheadings priority ] == -1} {
		set itk_option(-prior) "yes"
	    }
	    if { [lsearch -exact $columnheadings slittype ] == -1} {
		set itk_option(-stype) "yes"
	    }
	    if { [lsearch -exact $columnheadings slitpos_x ] == -1} {
		set itk_option(-xoffset) "yes"
	    }
	    if { [lsearch -exact $columnheadings slitpos_y ] == -1} {
		set itk_option(-yoffset) "yes"
	    }
	    if { [lsearch -exact $columnheadings redshift ] == -1} {
		set itk_option(-redshift) "yes"
	    }
	}

	#  Complicated way to set the column positions of id, ra, dec.
	#  This gets used later to set the headings for the gmmps_sel call.
	set col_numb 0
	set ids ""
	set ras ""
	set decs ""
	
	foreach i $columnheadings {
	    if { $i == "ID" } { 
		set ids "id_col $col_numb"
	    } elseif {$i == "RA" } { 
		set ras "ra_col $col_numb"
	    } elseif { $i == "DEC" } { 
		set decs "dec_col $col_numb"
	    }
	    incr col_numb
	}
	set itk_option(-uphead) [list $ids $ras $decs]
	
	#  Open the catalog, and create an instance of it
	new_catalog $name $id $classname $debug "catalog" $tType \
	    $itk_option(-prior) \
	    $itk_option(-stype) \
	    $itk_option(-tilt) \
	    $itk_option(-ysize) \
	    $itk_option(-xsize) \
	    $itk_option(-xoffset) \
	    $itk_option(-yoffset) \
	    $itk_option(-redshift) \
	    $w $instType $PIXSCALE $itk_option(-binning)
    }


    #############################################################
    #  Name: set_state
    #
    #  Description:
    #   Set/reset widget states while busy 
    #############################################################
    #############################################################

    public method set_state {state} {
	set state_ $state
	if {"$state" == "normal"} {
	    catch {blt::busy release $w_.options}
	    catch {focus -lastfor $w_.options}
	} else {
	    catch {focus .}
	    catch {blt::busy hold $w_.options}
	}
	update idletasks
    }


    #############################################################
    #  Name: query_done
    #
    #  Description:
    #   This method is called when the background query is done.
    #
    #   errmsg - If this is not empty, it contains an error message and
    #   the following args should be ignored. If there were no
    #   errors, this arg is an empty string.
    #
    #   headings  - are the column headings 
    #
    #   info - is a list of rows (result of query)
    #
    #   more - is a flag set to 1 if there were more rows available that were
    #   not returned due to the maxrows limit set.
    #
    #############################################################
    #############################################################
    public method query_done {errmsg headings info more} {

	if {"$errmsg" != ""} {
	    # check if we need user/passwd info. errmsg should have the format:
	    # "Authorization Required for <realm> at <host>"
	    if {[regsub {Authorization Required} $errmsg {Enter username} msg]} {
		lassign [passwd_dialog $msg] username passwd
		if {"$username" != "" && "$passwd" != ""} {
		    lassign $errmsg {} {} {} realm {} host
		    $w_.cat authorize $username $passwd $realm $host
		    $searchopts_ search
		}
	    } else {
		set_state normal
		catch {$results_ config -title "Search Results"}
		# error messages starting with "***" are only 
		# displayed in progress win
		if {"[string range $errmsg 0 2]" != "***"} {
		    error_dialog $errmsg
		}
		# after 0 [list $w_.progress config -text $errmsg]
	    }
	} else {
	    if {! $iscat_} {
		# for image servers, the info is the image file name
		set filename $info
		# load the image and remove the temp file
		display_image_file $filename
		catch {file delete $filename}
	    } else {
		busy {
		    #	$results_ save_yview
		    #	$results_ save_selection
		    set prev_headings $itk_option(-headingx)

		    set itk_option(-headingx) $headings
		    set headings_ $headings

		    set info_ $info

		    # update table
		    $results_ config -headings $itk_option(-headingx)
		    if {$reset_columns_} {
			set reset_columns_ 0
			reset_table
		    }

		    if {"$prev_headings" != "$itk_option(-headingx)"} {
			$results_ update_options
			set_menu_states
		    }

		    $results_ config -info $info
		    
		    # need to know the equinox of the results, if using world coords
		    if {[$w_.cat iswcs]} {
			lassign [$w_.searchopts get_pos_radius] {} {} equinox
			$results_ config -equinox $equinox
		    } 

		    if {$more} {
			set more "+"
		    } else {
			set more ""
		    }
		    $results_ config -title "Search Results ([$results_ total_rows]$more)"

		    # note column indexes in array (use upper case to simplify search)
		    catch {unset col_}
		    set n -1
		    foreach i $itk_option(-headingx) {
			set col_($i) [incr n]
		    }

		    # plot stars
		    plot

		    $results_ restore_yview
		    $results_ restore_selection
		}
	    }
	    set_state normal
	}
    }


    #############################################################
    #  Name: search
    #
    #  Description:
    #   Start the catalog search based on the current search options
    #   and display the results in the table.
    #############################################################
    #############################################################
    public method search {args} {

	set addPRIORITY $itk_option(-prior)
	set addSLITTYPE $itk_option(-stype)
	set addXSIZE    $itk_option(-xsize)
	set addYSIZE    $itk_option(-ysize)
	set addXOFFSET  $itk_option(-xoffset)
	set addYOFFSET  $itk_option(-yoffset)
	set addREDSHIFT $itk_option(-redshift)
	set addTILT     $itk_option(-tilt)
	set instType    $itk_option(-instType)
	set catname     $itk_option(-catalog)

	# start the query in the background
	catch {
	    $results_ config -title "Searching ..."
	    $results_ clear
	}
	set_state disabled
	set servtype [$w_.cat servtype]

	#  Add additional columns required

	# buffer:  Grep for dashes in the catalog  
	# headlen: Line number where the header ends
	# ncol:    Get the number of sets of unlines in the catalog, or number
	#          of column's in the catalog.
	# tmp:     Get the number of lines in the catalog
	# datalen: Get number of data lines (tmp-headlen)
	set buffer  [exec grep -n --regexp "^--" $catname]
	set headlen [exec echo $buffer | cut -d: -f1]
	set ncol    [exec echo $buffer | wc -w]
	set tmp     [exec wc -l $catname]
	set datalen [expr [lindex $tmp 0] - $headlen]

	# In the following we create a temporary catalog which contains
	# all the missing columns. This catalog is then merged with the original one.
	# It is much better to enforce all the columns we need now in the beginning, 
	# rather than adding them much later on demand, where it might be more complicated,
	# and having to remember which columns to add. I have cleaned that up as much as possible,
	# some routines were essentially unreadable because of this.
	set headerline1 ""
	set headerline2 ""
	set objectline  ""

	if {$DISPDIR == "horizontal"} {
	    set dimx "1.0"
	    set dimy "5.0"
	} else {
	    set dimx "5.0"
	    set dimy "1.0"
	}

	# Add slitsize_x
	if {$addXSIZE == "yes" } {
	    set headerline1 [append headerline1 "slitsize_x\t"]
	    set headerline2 [append headerline2 "----------\t"]
	    set objectline  [append objectline $dimx "\t"]
	    set addXSIZE "no"
	    set itk_option(-xsize) "no"
	}
	
	# Add slitsize_y
	if {$addYSIZE == "yes" } {
	    set headerline1 [append headerline1 "slitsize_y\t"]
	    set headerline2 [append headerline2 "----------\t"]
	    set objectline  [append objectline $dimy "\t"]
	    set addYSIZE "no"
	    set itk_option(-ysize) "no"
	}
	
	# Add slitpos_x
	if {$addXOFFSET == "yes" } {
	    set headerline1 [append headerline1 "slitpos_x\t"]
	    set headerline2 [append headerline2 "---------\t"]
	    set objectline  [append objectline 0.0 "\t"]
	    set addXOFFSET "no"
	    set itk_option(-xoffset) "no"
	}
	
	# Add slitpos_y
	if {$addYOFFSET == "yes" } {
	    set headerline1 [append headerline1 "slitpos_y\t"]
	    set headerline2 [append headerline2 "---------\t"]
	    set objectline  [append objectline 0.0 "\t"]
	    set addYOFFSET "no"
	    set itk_option(-yoffset) "no"
	}
	
	# Add slittilt
	if {$addTILT == "yes" } {
	    set headerline1 [append headerline1 "slittilt\t"]
	    set headerline2 [append headerline2 "--------\t"]
	    set objectline  [append objectline "0.0\t"]
	    set addTILT "no"
	    set itk_option(-tilt) "no"
	}

	# Add priority
	if {$addPRIORITY == "yes"} {
	    set headerline1 [append headerline1 "priority\t"]
	    set headerline2 [append headerline2 "--------\t"]
	    set objectline  [append objectline  "2\t"]
	    set addPRIORITY "no"
	    set itk_option(-prior) "no"
	}

	# Add slittype
	if {$addSLITTYPE == "yes"} {
	    set headerline1 [append headerline1 "slittype\t"]
	    set headerline2 [append headerline2 "--------\t"]
	    set objectline  [append objectline  "R\t"]
	    set addSLITTYPE "no"
	    set itk_option(-stype) "no"
	}

	# Add redshift
	if {$addREDSHIFT == "yes" } {
	    set headerline1 [append headerline1 "redshift\t"]
	    set headerline2 [append headerline2 "--------\t"]
	    set objectline  [append objectline 0.0 "\t"]
	    set addREDSHIFT "no"
	    set itk_option(-redshift) "no"
	}
	
	# We must trim the trailing "tab" as it would otherwise lead to an error when parsing the
	# input catalog
	set headerline1 [string trim $headerline1 " \t"]
	set headerline2 [string trim $headerline2 " \t"]

	# Only do the following if columns have to be added!
	# If not, you'll end up in a lot of mess!
	if {$headerline1 != "" && $headerline2 != ""} {
	    #  Open a file for writing called name.col
	    #  Write in there empty lines, up to where the data starts.
	    set col [open $catname.col w]
	    for {set n 3} {$n <= $headlen} {incr n 1} {
		puts $col ""
	    }
	    
	    # Put in name.col the header lines
	    puts $col $headerline1
	    puts $col $headerline2
	    
	    # Put in name.col the missing object lines
	    for {set n 1} {$n <= $datalen} {incr n 1} {
		set objectline [string trim $objectline " \t"]
		puts $col $objectline
	    }
	    ::close $col
	    
	    #  Mush the 2 files together to get the new column(s) in there.
	    #  Then rename the name.tmp to name
	    #  We have to sleep for 1 second as otherwise skycat moves on before the process is done
	    #  and then we get a "missing columns" errors (or something like that) when loading the OT 
	    #  catalog. Has to be at least 1s, I got errors for less than that.
	    set mx [sleep 1.5]
	    set mx [exec paste $catname $catname.col > $catname.tmp]
	    catch {file delete $catname.col}
	    file rename -force $catname.tmp $catname
	}

	$searchopts_ search $itk_option(-catalog) $itk_option(-uphead)
    }


    #############################################################
    #  Name: check_local_catalog
    #
    #  Description:
    #   If the given name is the name of a local catalog, check 
    #   that the file exists, and if not, ask the user for a new 
    #   path name or remove it from the menu.
    #############################################################
    #############################################################
    public proc check_local_catalog {name {id ""} {classname vmAstroCat} 
				     {debug 0} {type "catalog"} tType addPRIORITY addSLITTYPE addTILT \
					 addYSIZE addXSIZE addXOFFSET addYOFFSET addREDSHIFT {w ""}} {
	
	if {"[$astrocat_ servtype $name]" != "local"} {
	    return 0
	}
	set file [$astrocat_ url $name]
	if {[file isfile $file]} {
	    return 0
	}
	
	set msg "The catalog file [file tail $file] does not exist. \
     Do you want to specify a new name?"
	switch [my_choice_dialog $msg {{Specify a new name} Cancel {Remove from menu}} {Specify a new name} $w] {
	    {Specify a new name} {
		set file [filename_dialog]
		if {[file isfile $file]} {
		    $astrocat_ entry remove $name
		    new_catalog $file $id $classname $debug $type $tType \
			$addPRIORITY $addSLITTYPE $addTILT $addYSIZE $addXSIZE $addXOFFSET $addYOFFSET $addREDSHIFT $w
		    if {[winfo exists .catinf]} {
			.catinf reinit_tree
		    }
		}
	    }
	    Cancel {
		return 1
	    }
	    {Remove from menu} {
		$astrocat_ entry remove $name
		if {[winfo exists .catinf]} {
		    .catinf reinit_tree
		}
	    }
	}

	# update config file and menus
	cat::CatalogInfo::save "" $w 0
	update_catalog_menus
	return 1
    }


    #############################################################
    #  Name: set_pos_radius
    #
    #  Description:
    # set the values for the position and radius entries from the given
    # list, which should be in the format {ra dec equinox radius} if
    # we are using wcs, otherwise {x y radius}.
    #############################################################
    #############################################################
    public method set_pos_radius {list} {
	$searchopts_ set_pos_radius $list
    }


    #############################################################
    #  Name: set_pos_width_height
    #
    #  Description:
    # set the values for the position, width and height entries from 
    # the given list, which should be in the format 
    # {ra dec equinox width height (in arcmin)} for wcs, or {x y width height},
    # for pixel coordinates. 
    #############################################################
    #############################################################
    public method set_pos_width_height {list} {
	$searchopts_ set_pos_width_height $list
    }


    #############################################################
    #  Name: new_catalog
    #
    #  Description:
    #   This proc is used to open a window for the named catalog, 
    #   or reuse the existing one for the catalog, if it is already open.
    #   Specifically:
    #     check that type = "local"
    #     save this instance
    #     open the catalog
    #     put the window under top level window
    #
    #  Args:
    #   name is the long name of catalog from config file
    #
    #   id is an optional unique id to be associated with a new catalog widget.
    #
    #   classname is the name of the vmAstroCat subclass to use to create new
    #   catalog widgets (defaults to "vmAstroCat").
    #
    #   debug is a flag: if true, run queries in foreground
    #
    #   type is the catalog serv_type (here it is enough to specify "catalog" or
    #   "imagesvr".
    #
    #   w should be the top level window of the caller, if specified.
    #############################################################
    #############################################################
    public proc new_catalog {name {id ""} {classname vmAstroCat} {debug 0} 
			     {type "catalog"} tType addPRIORITY addSLITTYPE addTILT addYSIZE addXSIZE \
				 addXOFFSET addYOFFSET addREDSHIFT {w ""} iType {PIXSCALE ""} binning} {
	
	# if it is a local catalog: make sure it exists still, or get a new name
	if {[check_local_catalog $name $id $classname $debug $type $tType \
		 $addPRIORITY $addSLITTYPE $addTILT $addYSIZE $addXSIZE $addXOFFSET $addYOFFSET $addREDSHIFT $w] != 0} {
	    return
	}
	
	# Send last loaded image and catalog info to config file.
	set loadedImage [$target_image_ cget -file ]
	gmmps_config [list "catalog" "image" "instrument" "catalog_type"] [list $name $loadedImage $iType $tType] 
	
	#  Save this as an instance name, id
	set i "$name,$id"
	if {[info exists instances_($i)] && [winfo exists $instances_($i)]} {
	    utilRaiseWindow $instances_($i)
	    if {"[$instances_($i).cat servtype]" == "local"} {
		# for local catalogs, search automatically when opened
		$instances_($i) search
	    }
	    return
	}
	
	#  Open the catalog
	if {[catch {$astrocat_ open $name} msg]} {
	    error_dialog $msg
	    return
	}
	
	if { $iType == 1 || $iType == 3} {
	    if {($instType == "GMOS-S" && $NAXIS1 == "6218" && $NAXIS2 == "4608") ||
		($instType == "GMOS-N" && $NAXIS1 == "6218" && $NAXIS2 == "4608")} {
		puts "H3\n"
                warn_dialog "This is an old GMOS pseudo-image representing the detector geometry\nGMOS had before the Hamamatsu detector upgrade. New, and much more precise,\npseudo-image transformations have been obtained since.\nGMMPS allows you to visualize an old mask design (ODF) created previously\nfor this pseudo-image, but it will not allow you to create a new mask design.\n To create a new mask, you must use Gemini IRAF v1.14 (or later) available through\nAstroConda at\nhttp://astroconda.readthedocs.io/\n. 
"
		return
	    }
	}

	# If $w was specified, put the window under that top level window
	# so we get the window numbers right (for cloning, see TopLevelWidget).
	if {[winfo exists $w]} {
	    set instname $w.vmac[incr n_instances_]
	} else {
	    set instname .vmac[incr n_instances_]
	}

	set instances_($i) \
	    [$classname $instname \
		 -id $id \
		 -debug $debug \
		 -catalog $name \
		 -catalogtype $type \
		 -transient 0 \
		 -center 0 \
		 -catType $tType \
		 -prior $addPRIORITY \
		 -stype $addSLITTYPE \
		 -xsize $addXSIZE \
		 -ysize $addYSIZE \
		 -xoffset $addXOFFSET \
		 -yoffset $addYOFFSET \
		 -redshift $addREDSHIFT \
		 -tilt $addTILT \
		 -pixs $PIXSCALE \
		 -instType $iType \
		 -binning $binning]
    }


    public method gmmps_config_ {keys {data ""}} {
	return [gmmps_config $keys $data ]
    }


    #############################################################
    #  Name: gmmps_config
    #
    #  Description:
    #	Read or write configuration data to $config_file_
    #	keys is a list of keys
    #	data is a lits of associated data
    #
    #	If no data argument is provided we are assumed to be in 
    #		read mode and the val corresponding to the keys are 
    #		returned in a list, in order they were given. 
    #	If a data argument is provided then that data is written
    #		to the config file, based on its corresponding keys.
    #		NOTE: all keys must have valid data for the method to complete.
    #############################################################
    #############################################################
    public proc gmmps_config {keys {data ""}} {
	
	# Make sure keys and data are the same length if we are in write mode.
	if {$data != "" && ([llength $keys ] != [llength $data ])} {
	    return ""
	}
	
	# If config file does not exist, create a new one. 
	if {![file exists $config_file_ ]} {
	    set newConfig [open $config_file_ w ]
	    ::close $newConfig
	}

	# Open config file for reading. 
	set gmmpsConfig [open $config_file_ r ]
	
	set fileKeys [list ]
	set fileData [list ]
	set blanksAndComments [list ]
	set cnt 0
	
	# Populate fileKeys and fileData lists from config file.
	while {[gets $gmmpsConfig pair] >= 0} {	
	    # Ignore comments and empty lines.
	    if {$pair == "" || [string index [string trim $pair ] 0 ] == "#"} { 
		# Store positions and contents of any blank lines and comments,
		# so they can be restored later.
		set blanksAndComments [lappend blanksAndComments [list $cnt $pair ]]
		incr cnt
		continue
	    }
	    
	    set pair [split [string trim $pair ] "=" ]
	    set fileKeys [lappend fileKeys [string trim [lindex $pair 0 ]]]
	    set fileData [lappend fileData [string trim [lindex $pair 1 ]]]
	    incr cnt
	}
	
	# Done reading, close file. Will reopen if a write is needed. 
	::close $gmmpsConfig
	
	if {$data == ""} {
	    set targetData [list ]
	} else {
	    set targetKeys $fileKeys
	    set targetData $fileData
	}
	
	# Gather relevant data in targetKeys and targetData. 
	set cnt 0
	foreach key $keys {
	    # Search for key in keys loaded form file.
	    set idx [lsearch -exact $fileKeys [string trim $key ]]
	    
	    set newDat [lindex $data $cnt ]
	    set oldDat [lindex $fileData $idx ]
	    
	    if {$idx != -1} {
		# Key present in config file.
		
		if {$data == ""} {
		    # In read mode append the data to output list.	
		    set targetData [lappend targetData $oldDat ]
		} else {
		    # In write mode edit data in targetData.
		    set targetData [lreplace $targetData $idx $idx $newDat ]
		}
	    } else {
		# Key not present in config file.
		
		if {$data == ""} {
		    # In read mode all keys must be present.
		    return ""
		} else {
		    # In write mode we want to add new data.
		    set targetKeys [lappend targetKeys $key ]
		    set targetData [lappend targetData $newDat ]
		}
	    }
	    
	    incr cnt
	}
	
	if {$data == ""} {
	    # Read mode return data values.
	    return $targetData
	} else {
	    # Write mode edit file.
	    
	    # Open config file for writing.
	    set gmmpsConfig [open $config_file_ w ]
	    
	    set keyCnt 0
	    set lineCnt 0
	    
	    # Write all keys back into config file.
	    foreach key $targetKeys {
		
		# Write blank lines and comments back into place. 
		if {[llength $blanksAndComments ] != 0 } {
		    set tempBAC $blanksAndComments
		    foreach blankLine $tempBAC {
			if {[lindex $blankLine 0 ] == $lineCnt} {
			    puts $gmmpsConfig [format "%s" [lindex $blankLine 1 ]]

			    # Remove first element from blank and comment list. 
			    if {[llength $blanksAndComments ] > 1} {
				set blanksAndComments [lrange $blanksAndComments 1 end ] 
			    } else {
				set blanksAndComments ""
			    }
			    
			    incr lineCnt
			} else {
			    break
			}
		    }
		}
		
		set curData [lindex $targetData $keyCnt ]
		set line "$key=$curData"
		
		puts $gmmpsConfig $line
		
		incr lineCnt
		incr keyCnt
	    }

	    # Write blank lines and comments back into place. 
	    # (for after config values are done.)
	    if {[llength $blanksAndComments ] != 0 } {
		set tempBAC $blanksAndComments
		foreach blankLine $tempBAC {
		    if {[lindex $blankLine 0 ] == $lineCnt} {
			puts $gmmpsConfig [format "%s" [lindex $blankLine 1 ]]

			# Remove first element from blank and comment list. 
			if {[llength $blanksAndComments ] > 1} {
			    set blanksAndComments [lrange $blanksAndComments 1 end ] 
			} else {
			    set blanksAndComments ""
			}
			incr lineCnt
		    } else {
			break
		    }
		}
	    }
	    
	    ::close $gmmpsConfig
	    
	    # Return success.
	    return 0
	}
    }

    #############################################################
    #  Name: instances
    #
    #  Description:
    #   Return a Tcl list of instances of this class. By default
    #   (and for backward compatibility) only catalog windows are
    #   included - not image servers. If "choice" is "all", then
    #   all instances are returned. If choice is imagesvr, only 
    #   image server windows are returned.
    #############################################################
    #############################################################
    public proc instances {{choice catalogs}} {
	set list {}
	if {[info exists instances_]} {
	    foreach i [array names instances_] {
		if {[winfo exists $instances_($i)]} {
		    if {[$instances_($i) iscat]} {
			# instance of a catalog window
			if {"$choice" == "catalogs" || "$choice" == "all"} {
			    lappend list $instances_($i)
			}
		    } else {
			# instance of an image server window
			if {"$choice" == "imagesvr"} {
			    lappend list $instances_($i) 
			}
		    }
		}
	    }
	}
	return $list
    }


    #############################################################
    #  Name: get_instance
    #
    #  Description:
    #   Return the widget instance for the given catalog, if found,
    #   otherwise an empty string
    #############################################################
    #############################################################
    public proc get_instance {catalog} {
	foreach w [cat::vmAstroCat::instances all] {
	    if {"[$w cget -catalog]" == "$catalog"} {
		return $w
	    }
	}
    }


    #############################################################
    #  Name: iscat
    #
    #  Description:
    #   Return 1 if this window is for a searchable catalog, 
    #   and 0 otherwise (in which case it must be an image server window).
    #############################################################
    #############################################################
    public method iscat {} {
	return $iscat_
    }


    # ---------------------------------------------------------------
    # The following methods deal with images and plotting of objects
    # in an image and are meant to be defined in a derived class.
    # See the skycat/skycat/interp/library/SkySearch.tcl for an example.
    # ---------------------------------------------------------------


    # see plot method in vmSkySearch.tcl -df 
    public method plot {} {
    }


    # display the given image file (To be defined in a subclass)
    public method display_image_file {filename} {
    }


    #  return the equinox
    public method get_equinox {} {
	return [component searchopts get_equinox]
    }


    #  return the name of the TableList
    public method get_table {} {
	if {[info exists itk_component(results)]} {
	    return $itk_component(results)
	}
	error "This catalog is an image server"
    }


    #############################################################
    # Fetch pixelscale from fits image. 
    # This is a recursive function!
    #############################################################
    public proc get_pixelscale_image {{HDU ""}} {
	
	set pixelScale "NOT FOUND"

	if {$HDU == ""} {
	    # Search the primary HDU
	    set fits [$target_image_ hdu fits ]
	} else {
	    # Search the first extension HDU
	    set fits [$target_image_ hdu fits 1]
	}

	# Get the (average) pixelscale from the CD matrix, ignoring any distortion
	set CD11 "NOT FOUND"
	set CD12 "NOT FOUND"
	set CD21 "NOT FOUND"
	set CD22 "NOT FOUND"

	# IMPORTANT: Note that I search a keyword including a trailing blank,
	# because I have seen pre-images which had e.g. CRPIX1A and CD1_1A in addition to CRPIX1 and CD1_1

	foreach header [split $fits "\n" ] {
	    if {[string range $header 0 5 ] == "CD1_1 "} {
		set CD11 [lindex [split [lindex [split $header "=" ] 1 ] "/" ] 0 ]
		break
	    }
	}
	foreach header [split $fits "\n" ] {
	    if {[string range $header 0 5 ] == "CD1_2 "} {
		set CD12 [lindex [split [lindex [split $header "=" ] 1 ] "/" ] 0 ]
		break
	    }
	}
	foreach header [split $fits "\n" ] {
	    if {[string range $header 0 5 ] == "CD2_1 "} {
		set CD21 [lindex [split [lindex [split $header "=" ] 1 ] "/" ] 0 ]
		break
	    }
	}
	foreach header [split $fits "\n" ] {
	    if {[string range $header 0 5 ] == "CD2_2 "} {
		set CD22 [lindex [split [lindex [split $header "=" ] 1 ] "/" ] 0 ]
		break
	    }
	}
	
	if {$CD11 != "NOT FOUND" && $CD12 != "NOT FOUND" && $CD21 != "NOT FOUND" && $CD22 != "NOT FOUND"} {
	    set ps1 [expr sqrt($CD11*$CD11+$CD12*$CD12) * 3600. ]
	    set ps2 [expr sqrt($CD22*$CD22+$CD21*$CD21) * 3600. ]
	    set pixelScale [expr ($ps1+$ps2) / 2. ]
	    return $pixelScale
	}

	# No? Then try and get the pixelscale from the CDELT keywords
	if { $pixelScale == "NOT FOUND" } {
	    set CDELT1 "NOT FOUND"
	    set CDELT2 "NOT FOUND"
	    foreach header [split $fits "\n" ] {
		if {[string range $header 0 6 ] == "CDELT1 "} {
		    set CDELT1 [lindex [split [lindex [split $header "=" ] 1 ] "/" ] 0 ]
		    break
		}
	    }
	    foreach header [split $fits "\n" ] {
		if {[string range $header 0 6 ] == "CDELT2 "} {
		    set CDELT2 [lindex [split [lindex [split $header "=" ] 1 ] "/" ] 0 ]
		    break
		}
	    }
	    if {$CDELT1 != "NOT FOUND" && $CDELT2 != "NOT FOUND"} {
		set pixelScale [expr sqrt($CDELT1*$CDELT1+$CDELT2*$CDELT2) * 3600. ]
		return $pixelScale
	    }
	}

	# Still nothing? Here is the recursive part (this function calling itself) 
	# (will run only once, because HDU="")
	if {$pixelScale == "NOT FOUND" && $HDU == ""} {
	    set pixelScale [get_pixelscale_image 1]
	}

	# Getting desperate!
	if {$pixelScale == "NOT FOUND"} {
	    tk_messageBox -message "WARNING: No valid WCS information (CD matrix nor CDELT) in the FITS header!!! Looking for PIXSCALE keyword..." -parent $w_ -title "Missing WCS information"

	    # Try and find the PIXSCALE keyword in the primary HDY
	    set fits [$target_image_ hdu fits ]
	    foreach header [split $fits "\n" ] {
		if {[string range $header 0 7 ] == "PIXSCALE"} {
		    set pixelScale [lindex [split [lindex [split $header "=" ] 1 ] "/" ] 0 ]
		    break
		}
	    }
	    if {$pixelScale == "NOT FOUND"} {
		# Try and find the PIXSCALE keyword in the first extension HDU
		set fits [$target_image_ hdu fits 1]
		foreach header [split $fits "\n" ] {
		    if {[string range $header 0 7 ] == "PIXSCALE"} {
			set pixelScale [lindex [split [lindex [split $header "=" ] 1 ] "/" ] 0 ]
			break
		    }
		}
	    }
	    # Return whatever we have ("NOT FOUND" will trigger an error in the calling function) 
	    return [string trim $pixelScale ]
	}
    }


    #########################################################################
    #  Name: check_ODF_version
    #
    #  Description:
    #     Tries to read the GMMPSVER string in the ODF
    #########################################################################
    #########################################################################
    public proc check_ODF_version {ODFfile} {
	global oldODFwarning
	set gmmpsver   [get_keyword "#fits GMMPSVER" $ODFfile]
	set gmmpsver   [lindex ${gmmpsver} 0]
	set gmmpsvernum [string map {"." ""} $gmmpsver]
	if {$gmmpsvernum < 140 || [string match 0* $gmmpsver] == 1} {
	    set oldODFwarning 1
	} else {
	    set oldODFwarning 0
	}
	return $gmmpsver
    }

    #########################################################################
    #  Name: get_keyword
    #
    #  Description:
    #     get keywords from ASCII files (read: output from gmMakeMasks)
    #     The syntax works for both of these formats:
    #     KEYWORD = KEYVALUE
    #     KEYWORD = KEYVALUE / COMMENT
    #########################################################################
    #########################################################################
    public proc get_keyword {keyword asciifile} {

	set keyval ""
	if {[file exists $asciifile]} {
	    catch {set keyval [string trim [exec grep $keyword $asciifile | cut -f2 -d= | cut -f1 -d/ ] "' \t"]}
	} else {
	    error_dialog "Cannot find file $asciifile!"
	}
	return $keyval
    }


    #############################################################
    #  Name: getInstsType
    #
    #  Description:
    #   Finds the instrument type from the image, and alternatively the catalog.
    #  
    #############################################################
    #############################################################
    protected proc getInstType {name} {
	
	set instType "NOT FOUND"

	# Search in the image
	set fits [$target_image_ hdu fits 1 ]    
	foreach header [split $fits "\n" ] {
	    if {[string range $header 0 7 ] == "INSTRUME"} {
		set instType [lindex [split $header "'" ] 1 ]
		break
	    }
	}

	# Grep from the catalog if unsuccessful
	if {$instType == "NOT FOUND"} {
	    # The second 'cut' is to trim any comments
	    # (which break the string comparison to determine instType)
	    # Must use catch as otherwise a 'main: child process exited abnormally' is thrown even though
	    # the Linux command itself just returns an empty string. Don't understand why.
	    catch {set instType [exec grep "#fits INSTRUME" $name | cut -f2 -d= | cut -f1 -d/]}
	}
	
	if {$instType == "NOT FOUND"} {
	    # Will return error in parent
	    return $instType;
	}

	# Capitalize the instrument name, remove blanks, tabs and quotes
	set instType [string toupper $instType]
	set instType [regsub -all "\[' \t]+" $instType {}]
	
	# Check for AO configuration with F2
	if {$instType == "F2"} {
	    set aofold ""
	    catch { set aofold [$target_image_ fits get AOFOLD] }
	    if {$aofold == "in"} {
		set instType "F2-AO"
	    }
	}
	
	# If your instrument had different INSTRUME keywords in the past, then here is the place
	# to translate them to the latest valid string
	
	return $instType
    }


    #############################################################
    #  Name: setDetInfo
    #
    #  Description:
    #   Search for detector information in the detector
    #	configuration file.
    #############################################################
    #############################################################	
    protected method setDetInfo {instType} {
	
	# Find DET_SPEC_ based on instType and info in detector config file.
	set detFile [open "$home_/config/Detectors.dat" r ]
	
	while {[gets $detFile line ] >= 0} {	
	    if {$line == ""} {
		continue
	    } elseif {[string index $line 0 ] == "#" } {
		continue
	    }
	    
	    # remove all leading and trailing white space
	    # condense internal white space to single blanks
	    # split the string into a list
	    set line [string trim $line ]
	    set line [regsub -all "\[ \t]+" $line { }]
	    set line [split $line " " ]
	    
	    set lineInst [lindex $line 1 ]
	    set installed [lindex $line 0 ]
	    
	    if {$lineInst == $instType && $installed == 1} {
		# Found the installed detector for our instrument! 
		set DET_SPEC_ [lindex $line 2 ]
		break
	    }
	}
	::close $detFile
	
	return
    }



    #############################################################
    #  Name: is_sorted
    #
    #  Description: Inputs a list of column rows and outputs 1 or 0, depending
    #	if the list is in sorted ascending order in the ID column, or not. 
    #   
    #############################################################
    protected method is_sorted {rows} {
	set id_col 0
	set last -1
	
	foreach row $rows {
	    set cur [lindex $row $id_col ]
	    if {$cur > $last} {
		set last $cur
	    } else {
		return 0
	    }
	}
	return 1
    }


    #############################################################
    #  Name: sort_rowlist
    #
    #  Description: Sorts a given rowlist by id, and returns the sorted list 
    #	(increasing order).
    #############################################################
    protected method sort_rowlist {rows} {
	set id_col 0
	# Sort this data. 
	set sorted_rows [lsort -integer -index $id_col $rows ]
	return $sorted_rows
    }

    #############################################################
    #  Name: test_gemwm_rerun
    #
    #  Checks whether gemwm needs to be rerun
    #############################################################
    public method test_gemwm_rerun {instType} {
	if {[file exists "gemwm.output"] == 0} {
	    return 1
	}
	set redshift_current [$w_.odfRedshiftEdit get]
	set linelist_current [$w_.odfWavelengthEdit get]
	set flag 0
	if {$redshift_current != $redshift_previous} {
	    set redshift_previous $redshift_current
	    set flag 1
	}
	if {$linelist_current != $linelist_previous} {
	    set linelist_previous $linelist_current
	    set flag 1
	}
	if {$instType != "F2"} {
	    set cwl_current [$w_.odfCWLSpinBox get]
	    if {$cwl_current != $cwl_previous} {
		set cwl_previous $cwl_current
		set flag 1
	    }
	}
	if {$flag == 1} {
	    return 1
	} else {
	    return 0
	}
    }



    ######################################################################
    # Search a keyword in a FITS image
    ######################################################################
    public method get_fits_keyword {keyname} {

	# regsub: replace multiple empty spaces by single spaces
	set target_image_ image2
	
	set keyval "UNKNOWN"
	set keylength [expr [string length $keyname]-1]

	# Search the primary HDU
	# oddly enough, this seems to scan the first extension header
	set fitshead [$target_image_ hdu fits]
	foreach header [split $fitshead "\n" ] {
	    if {[string range $header 0 $keylength] == $keyname} {
		set keyval [lindex [split [lindex [split $header "=" ] 1 ] "/" ] 0 ]
		regsub -all { +} $keyval { } keyval
		set keyval [string trim $keyval ]
		break
	    }
	}

	# Search the first extension HDU
	# oddly enough, this seems to search the primary HDU
	if {$keyval == "UNKNOWN" } {
	    set fitshead [$target_image_ hdu fits 1]
	    foreach header [split $fitshead "\n" ] {
		if {[string range $header 0 $keylength] == $keyname} {
		    set keyval [lindex [split [lindex [split $header "=" ] 1 ] "/" ] 0 ]
		    regsub -all { +} $keyval { } keyval
		    set keyval [string trim $keyval ]
		    break
		}
	    }
	}
	return $keyval
    }


    #############################################################
    # Return the name of this skycat instance. 
    #############################################################
    public method get_skycat {} {
	if {[string range $this 2 8 ] == ".skycat"} {
	    return [string range $this 2 9 ]
	} else { 
	    return 1
	}
    }


    ################################################################
    # Collect basic information about this image and the instrument,
    # to avoid multiple file i/o
    ################################################################
    public method get_global_data {} {

	set home $::env(GMMPS)
	set instType $itk_option(-instType)

	# Must initialize, otherwise repeated calls to get_global_data (opening new mask files, different inst)
	# will increment these values!
	set FOVX  {}
	set FOVY  {}
	set GAP1Y {}
	set GAP2X {}
	set GAP2Y {}
	set DIMX  {}
	set DIMY  {}
	set AMP   {}
	set N_DIM  0
	set N_GAP1 0
	set N_GAP2 0
	set N_FOV  0
	set N_AMP  0
	
	set pseudoimage "no"
	set PA 0
	set PIXSCALE 0
	
	set NAXIS1 [get_fits_keyword "NAXIS1 "]
	set NAXIS2 [get_fits_keyword "NAXIS2 "]
	set CRPIX1 [get_fits_keyword "CRPIX1 "]
	set CRPIX2 [get_fits_keyword "CRPIX2 "]
	set CD11   [get_fits_keyword "CD1_1 "]
	set CD12   [get_fits_keyword "CD1_2 "]
	set CD21   [get_fits_keyword "CD2_1 "]
	set CD22   [get_fits_keyword "CD2_2 "]
	set OBJECT [get_fits_keyword "OBJECT "]
	set OBJECT [string toupper $OBJECT]
	if {[string match *PSEUDO* $OBJECT] == 1} {
	    set pseudoimage "yes"
	}

	set RA  [get_fits_keyword "CRVAL1 "]
	set DEC [get_fits_keyword "CRVAL2 "]
	if {$RA == "UNKNOWN"} {
	    set RA [get_fits_keyword "RA "]
	}
	if {$DEC == "UNKNOWN"} {
	    set DEC [get_fits_keyword "DEC "]
	}
	# truncate to reasonable number of digits
	set RA [format "%.5f" $RA]
	set DEC [format "%.5f" $DEC]
	
	set DET_IMG_ [get_fits_keyword "DETID "]
	set DET_IMG_ [lindex [split $DET_IMG_ "'" ] 1 ]
	set DET_IMG_ [string trim $DET_IMG_]
	set DET_IMG_ [regsub -all { +} $DET_IMG_ {_}]
	
	# The dispersion direction
	if {$instType == "GMOS-S" || $instType == "GMOS-N"} {
	    set DISPDIR "horizontal"
	}
	if {$instType == "F2" || $instType == "F2-AO"} {
	    set DISPDIR "vertical"
	}
	
	# CRPIX unusable for pseudo-image (can be outside the image), reset to image center
	if {$pseudoimage == "yes"} {
	    set CRPIX1 [expr $NAXIS1/2]
	    set CRPIX2 [expr $NAXIS2/2]
	    set fitsfile [$target_image_ cget -file ]
	    set RA  [lindex [exec xy2sky -j $fitsfile $CRPIX1 $CRPIX2] 0]
	    set DEC [lindex [exec xy2sky -j $fitsfile $CRPIX1 $CRPIX2] 1]
	}

	# POSITION ANGLE
	if {$CD11 != "UNKNOWN" && $CD12 != "UNKNOWN" && $CD21 != "UNKNOWN" && $CD22 != "UNKNOWN"} {
	    if {[catch {
		set PA [exec get_OT_posangle "-i" $instType "-c" $CD11 $CD12 $CD21 $CD22]
	    } msg ]} {
		set PA [get_fits_keyword "PA "]
	    }
	    if {$PA == "UNKNOWN"} {
		error_dialog "ERROR: Could not determine position angle from CD matrix nor from PA keyword. Bad WCS!"
		return "ERROR"
	    } else {
		set PA [format "%.1f" $PA]
	    }
	}

	# PIXELSCALE
	if {$CD11 != "UNKNOWN" && $CD12 != "UNKNOWN" && $CD21 != "UNKNOWN" && $CD22 != "UNKNOWN"} {
	    set ps1 [expr sqrt($CD11*$CD11+$CD12*$CD12) * 3600. ]
	    set ps2 [expr sqrt($CD22*$CD22+$CD21*$CD21) * 3600. ]
	    set PIXSCALE [expr ($ps1+$ps2) / 2. ]
	}
	if {$PIXSCALE == 0} {
	    set CDELT1 [get_fits_keyword "CDELT1 "]
	    set CDELT2 [get_fits_keyword "CDELT2 "]
	    if {$CDELT1 != "UNKNOWN" && $CDELT2 != "UNKNOWN"} {
		set PIXSCLE [expr sqrt($CDELT1*$CDELT1+$CDELT2*$CDELT2) * 3600. ]
	    }
	}
	if {$PIXSCALE == 0} {
	    error_dialog "No valid WCS information (CD matrix nor CDELT) in the FITS header!"
	    return "ERROR"
	}

	# Read in FOV, GAP and DETDIM
	set fovfilename $home/config/${instType}_current_fov.dat
	if {[catch {set fovList [open $fovfilename r] } msg]} {
	    error_dialog "$msg"
	    return
	}
	# Read fov values into lists
	while {[gets $fovList line] >= 0} {
	    # remove all leading and trailing white space
	    # condense internal white space to single blanks
	    set line [string trim $line ]
	    set line [regsub -all "\[ \t]+" $line { }]
	    # extract the paired values when the line matches a keyword (and is not a comment)
	    if {[string match #* $line] == 0} {
		if {[string match FOV_CORNER* $line] == 1} {
		    set FOVX [lappend FOVX [expr [lindex $line 1 ] / $PIXSCALE + $CRPIX1 ]]
		    set FOVY [lappend FOVY [expr [lindex $line 2 ] / $PIXSCALE + $CRPIX2 ]]
		    incr N_FOV
		}
		if {[string match DIM_CORNER* $line] == 1} {
		    set DIMX [lappend DIMX [expr [lindex $line 1 ] / $PIXSCALE + $CRPIX1 ]]
		    set DIMY [lappend DIMY [expr [lindex $line 2 ] / $PIXSCALE + $CRPIX2 ]]
		    incr N_DIM
		}
		if {[string match GAP1_CORNER* $line] == 1} {
		    set GAP1X [lappend GAP1X [expr [lindex $line 1 ] / $PIXSCALE + $CRPIX1 ]]
		    set GAP1Y [lappend GAP1Y [expr [lindex $line 2 ] / $PIXSCALE + $CRPIX2 ]]
		    incr N_GAP1
		}
		if {[string match GAP2_CORNER* $line] == 1} {
		    set GAP2X [lappend GAP2X [expr [lindex $line 1 ] / $PIXSCALE + $CRPIX1 ]]
		    set GAP2Y [lappend GAP2Y [expr [lindex $line 2 ] / $PIXSCALE + $CRPIX2 ]]
		    incr N_GAP2
		}
		if {[string match AMP* $line] == 1} {
		    set AMP [lappend AMP [expr [lindex $line 1 ] / $PIXSCALE + $CRPIX1 ]]
		    incr N_AMP
		}
	    }
	}
	::close $fovList

	# The min and max detector boundaries, in image pixels
	# (may be negative, if old pseudo-image is smaller than new detector)
	set DETXMIN [lindex $DIMX 0]
	set DETXMAX [lindex $DIMX 3]
	set DETYMIN [lindex $DIMY 0]
	set DETYMAX [lindex $DIMY 1]

	# Overall extent in pixels (for waveMapper)
	set DETDIMX [expr round([expr $DETXMAX - $DETXMIN])]
	set DETDIMY [expr round([expr $DETYMAX - $DETYMIN])]
    }

    #############################################################
    # -- options --
    #############################################################

    # name of catalog
    itk_option define -catalog catalog Catalog "" {
	# make sure we use full path name for local catalogs
	set f $itk_option(-catalog)
	if {[file exists $f] && "[string index $f 0]" != "/"} {
	    set itk_option(-catalog) [pwd]/$f
	}
    }

    # type of catalog (catalog or archive)
    itk_option define -catalogtype catalogType CatalogType "catalog"

    # Optional unique id, used in searching for already existing catalog widgets.
    itk_option define -id id Id ""

    # Contains the type of file loaded in, Object Tbl, Master OT , or fitsFile 
    itk_option define -catType catType CatType "1"

    # Options indicating col's that exist
    itk_option define -prior prior Prior "no"
    itk_option define -stype stype SType "R"
    itk_option define -xsize xsize XSize "no"
    itk_option define -ysize ysize YSize "no"
    itk_option define -tilt tilt Tilt "no"
    itk_option define -uphead uphead UpHead {}
    itk_option define -headingx headingx Headingx {}
    itk_option define -pixs pixs Pixs "0.0"
    itk_option define -binning binning Binning 1
    itk_option define -xoffset xoffset Xoffset "no"
    itk_option define -yoffset yoffset Yoffset "no"
    itk_option define -redshift redshift Redshift "no"

    # list of catalog column headings (from results of most recent query)
    protected variable headings_ {}

    # result from most recent query (list of rows)
    protected variable info_ {}

    # set the anchor for labels
    itk_option define -anchor anchor Anchor e

    # flag: if true, run queries in foreground for better debugging
    itk_option define -debug debug Debug 0

    # vmAstroQuery widget used to manage search options
    protected variable searchopts_ {}

    # QueryResult widget used to display search results
    protected variable results_ {}

    # array(uppercase col name) of col index from catalog headings
    protected variable col_

    # current state: normal, disabled (i.e.: waiting)
    protected variable state_ {normal}

    # log file handle (used to log URLs)
    protected variable logfile_name_ 

    # flag: set at end of constructor
    protected variable initialized_ 0

    # index of this object in the instances_ array
    protected variable instance_idx_ {}

    # name of File menu widget
    protected variable file_menu_

    # name of Edit menu widget
    protected variable edit_menu_

    # name of Options menu widget
    protected variable options_menu_

    # flag: set when the column headings are changed between TCS and normal
    protected variable reset_columns_ {0}

    # currently selected object (Id field in row)
    protected variable object_name_ {}

    # flag: true if catalog is not an image server
    protected variable iscat_ 1

    # The detector ID of the image loaded into skycat.
    protected variable DET_IMG_ ""

    # The detector ID that the mask is intended for.
    protected variable DET_SPEC_ ""

    # GMMPS version warning
    protected variable oldODFwarning 0

    # other global flags
    protected variable outsidewarning_shown 0
    protected variable R600warning_shown 0
    protected variable oldwavelength_warning_shown 0
    
    # Formatting variables. 

    # The OT window
    protected variable ot_text_ "black"
    protected variable ot_bg_ "grey86"
    protected variable ot_bg2_ "grey86"

    protected variable button_text_ot_ "black"
    protected variable button_text_active_ot_ "black"
    protected variable button_bg_ot_ "grey86"
    protected variable button_bg_active_ot_ "white"

    protected variable catalog_text_ot_ "black"
    protected variable catalog_text_active_ot_ "black"
    protected variable catalog_bg_ot_ "white"
    protected variable catalog_bg_active_ot_ "yellow"

    protected variable menu_bg_ot_ #b33
    protected variable menu_text_ot_ "white"
    protected variable menu_bg_active_ot_ "white"
    protected variable menu_text_active_ot_ "black"

    # The ODF window
    protected variable odf_text_ "black"
    protected variable odf_bg_ "grey86"
    protected variable odf_bg2_ "grey86"

    protected variable button_text_odf_ "black"
    protected variable button_text_active_odf_ "black"
    protected variable button_bg_odf_ "grey86"
    protected variable button_bg_active_odf_ "white"

    protected variable catalog_text_odf_ "black"
    protected variable catalog_text_active_odf_ "black"
    protected variable catalog_bg_odf_ "white"
    protected variable catalog_bg_active_odf_ "yellow"

    protected variable menu_bg_odf_ #36d
    protected variable menu_text_odf_ "white"
    protected variable menu_bg_active_odf_ "white"
    protected variable menu_text_active_odf_ "black"

    # Color scheme
    # protected variable acq_color magenta

    # -- common variables (common to all instances of this class) --

    # C++ astrocat object used by static member procs
    protected common astrocat_ [astrocat ::cat::.vmastrocat]

    # A reference to the band_def_UI window. Useful if we want to destroy
    # previous windows on new window loads.
    protected common bw_ ""

    # A reference to the mask design window, if open.
    protected common spoc_ ""

    # array mapping catalog name to widget/class name
    protected common instances_

    # instance count
    protected common n_instances_ 0

    # current instance name
    protected common current_instance_ {}

    # array(TopLevelWidget instance) of command used to update the
    # Data-Servers menu. This is used to make it posible to update
    # all instances of this menu in various top level windows.
    protected common catalog_menu_info_

    # Reference to the skycat image widget. 
    protected common target_image_ image2

    protected common home_ $::env(GMMPS)

    # Globals to test whether gemwm needs to be rerun
    protected common cwl_current ""
    protected common cwl_previous ""
    protected common redshift_current ""
    protected common redshift_previous ""
    protected common linelist_current ""
    protected common linelist_previous ""
    
    # A lot more "globals" because I can't figure out how else to do this with tclTk...
    # best GMMPS style...
    protected common CRPIX1 ""
    protected common CRPIX2 ""
    protected common PA ""
    protected common RA ""
    protected common DEC ""
    protected common NAXIS1 ""
    protected common NAXIS2 ""
    protected common DISPDIR ""
    protected common PIXSCALE ""
    protected common DETDIMX ""
    protected common DETDIMY ""
    protected common DETXMIN ""
    protected common DETXMAX ""
    protected common DETYMIN ""
    protected common DETYMAX ""
    protected common FOVX  {}
    protected common FOVY  {}
    protected common GAP1X {}
    protected common GAP1Y {}
    protected common GAP2X {}
    protected common GAP2Y {}
    protected common DIMX  {}
    protected common DIMY  {}
    protected common AMP   {}
    protected common N_DIM  0
    protected common N_FOV  0
    protected common N_GAP1 0
    protected common N_GAP2 0
    protected common N_AMP  0
    
    # GMMPS configuration filename
    protected common config_file_ [format "%s/.gmmps.cfg" $::env(HOME) ]

    # Information about the detector being used. A list. 
    # Will be set to 0 on construction.
    # GMOS Order: Currently-Installed Instrument-Name Detector-Id Detector-Name Pixel-Scale Bandsize
    # For F2:     Curently-Installed Instrument-Name Detector-Id Detector-Name Pixel-Scale
    protected common detector_ 0
}
