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

# $Id: vmTableList.tcl,v 1.4 2013/02/15 14:56:45 gmmps Exp $
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
# vmTableList.tcl
#
# PURPOSE:
# A listbox based table widget.  Keeps a list of what's in the display window
# and provides methods to edit them.
#
# METHOD NAME(S)
# constructor		- Constructor
# debugStatement
# calculate_format
# move_down -
# move_up -
# clear -
# edit_row 	- pop up a dialog window to edit the values in the selected row
# set_row -
# add_row -
# remove_row -
# save_yview -
# restore_yview -
# save_selection -
# restore_selection -
# append_row -
# append_rows -
# new_inf -
# new_headings -
# search -
# get_selected 	- return a list of the selected rows
# get_select_with_rownum
# get_headings -
# removed_selected -
# layout_dialog -
# total_rows -
# method_info_rows -
# sort_dialog -
# print_dialog -
# print -
# get_contents -
# myprint -	Function to select and print out only specific columns
# set_option -
# set_options -
# get_option -
# xview -
# yview -
# load_config -
# delete_config -
# save_dialog -
# make_table_menu -
# update_sort_info -
# 
# $Log: vmTableList.tcl,v $
# Revision 1.4  2013/02/15 14:56:45  gmmps
# Made corners of gmos fov deeper to match real masks, fix priority/slittype bug
#
# Revision 1.3  2013/02/04 18:38:06  gmmps
# Small features and bug fixes from Dec2012 and Jan2013.
#
# Revision 1.2  2011/04/25 18:27:34  gmmps
# Forked from 0.401.12 .
#
# Revision 1.2  2011/04/08 20:13:25  gmmps
# N&S bugfixes.
#
# Revision 1.1  2011/01/24 20:02:17  gmmps
# Compiled for RedHat 5.5 32 and 64 bit.
#
# Revision 1.8  2003/01/17 05:02:17  callen
# more of the validation and interface features from inger's testing
#
# Revision 1.7  2003/01/16 10:27:42  callen
# debugging puts for linux bug (!!! meant to work on regular list! but the next users are linux based and I run into the bug when I use my laptop/linux)  I did track it down quite a bit
#
# Revision 1.6  2002/12/21 03:34:53  callen
# got past the roadblocks using vmTableList but, made some changes to text messages.
#
# Not yet done with band shuffling interface.  Checking things in for safety
# before vacation.
#
# Revision 1.5  2002/12/03 10:29:39  callen
# added nodPx support
# worked on the bad "R" column bug... removed info_dialog workaround
# (which is that if I bring up an info_dialog in vmTableList new_headings {}
# the bug doesn't show up, never shows up in Solaris)
#
# Revision 1.4  2002/11/27 03:18:15  callen
#
# modifications at work, checked in to get them at home.
#
# Revision 1.3  2002/11/21 19:41:39  callen
# while making changes to debug I found this module was the source of the
# bug (seems to have been) which was seen only in linux of the ("R" not found)
#
# I do see why this problem existed but not why it didn't effect solaris.
#
# Revision 1.2  2002/11/20 03:45:20  callen
# these changes bring up a nod and shuffle interface which can start the mask design interface.
#
# note: the feature is not yet active... it's just a GUI!
#
# Revision 1.1.1.1  2002/07/19 00:02:09  callen
# importing gmmps as recieved from Jennifer Dunn
# gmmps is a skycat plugin and processes for creating masks
#
# Revision 1.7  2001/10/11 21:10:55  dunn
# Added MAG column.
#
# Revision 1.6  2001/08/22 22:55:24  dunn
# *** empty log message ***
#
# Revision 1.5  2001/08/03 21:08:07  dunn
# Changes to handle multiple windows and object selection.
#
# Revision 1.4  2001/08/02 20:07:58  dunn
# *** empty log message ***
#
# Revision 1.3  2001/07/17 19:46:49  dunn
# *** empty log message ***
#
# Revision 1.2  2001/04/25 17:01:22  dunn
# Initial revisions.
#
#
#****     D A O   I N S T R U M E N T A T I O N   G R O U P        *****
#***********************************************************************
itk::usual vmTableList {
    keep -activebackground -activerelief -background -borderwidth -cursor \
	-foreground -highlightcolor -highlightthickness \
	-selectbackground -selectborderwidth -selectforeground 
}


#***********************************************************************
#+
# CLASS NAME:
# vmTableList
#
# PURPOSE:
# vmTableList is an itcl widget for displaying tabular information
# and headings in a Tk listbox. It lines up columns of data 
# (specified in tcl list format) with column headings, optionally sorts
# the data by given columns, in a given order, can "hide" columns,
# rearrange columns, or display columns matching certain expressions. 
# You can even print the contents of the table. 
# This widget has been in use for a number of years and has grown to include
# quite a few features. It is well suited to displaying the results 
# of database or catalog queries.
#
#***********************************************************************
itcl::class util::vmTableList {
    inherit util::ListboxWidget

    #############################################################
    #  Name: constructor
    #
    #  Description:
    #  create a new vmTableList object
    #############################################################
    #############################################################
    constructor {args} {
	# listbox used to display table headings
	global tlDebugLevel

	set tlDebugLevel 0

	itk_component add headbox {
	    listbox $w_.headbox -setgrid 1 -height 1
	} {
	    keep -relief -borderwidth -width -relief -exportselection -selectmode
	    rename -font -headingfont headingFont HeadingFont
	    rename -height -headinglines headingLines HeadingLines
	}
	set headbox_ $itk_component(headbox)
	
	# This class creates an object for reading and writing an optional 
	# config file and managing table options
	itk_component add config_file {
	    util::TableListConfigFile $w_.config_file
	}

	# insert header listbox
	pack $headbox_  -before $listbox_ -fill x

	# sync scrolling
	$itk_component(hscroll) config -command [code $this xview]
	foreach i "$listbox_ $headbox_" {
	    bind $i <2> "$listbox_ scan mark %x %y; $headbox_ scan mark %x 0"
	    bind $i <B2-Motion> "$listbox_ scan dragto %x %y; $headbox_ scan dragto %x 0"
	}
	bind $headbox_ <B1-Motion> { }
	bind $headbox_ <Shift-B1-Motion> { }
	bind $headbox_ <Shift-1> { }
	bind $headbox_ <1> { }

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
	global tlDebugLevel

	if { $tlDebugLevel == 1 } {
	    puts $line
	}
    }

    #############################################################
    #  Name: format_line_
    #
    #  Description:
    # format the given line with the given format string and return
    # the new string. The line is assumed to be a list of strings.
    # $formats_ is a list of format strings, one for each element.
    # If the line consists of only one char in the set "_-=", a line
    # is drawn using that char.
    #############################################################
    #############################################################
    private method format_line_ {line} {
	eval $itk_option(-filtercmd) line
	if {[string match {[-=_]} $line]} {
	    return [replicate $line $line_length_]
	}
	return [eval "format {$formats_} $line"]
    }


    # format and return the table headings
    private method format_headings_ {h} {
	return [eval "format {$hformats_} $h"]
    }



    #############################################################
    #  Name: get_col_sizes_
    #
    #  Description:
    # setup the sizes_ array to hold the max width of each column.
    # if the -sizes option was specified, use it, otherwise scan
    # the info for the max widths.
    #############################################################
    #############################################################
    private method get_col_sizes_ {} {
	if {$itk_option(-static_col_sizes) && [info exists size_(1)]} {
	    return
	}
	for {set c 1} {$c <= $num_cols_} {incr c} {
	    set size_($c) $hsize_($c)
	}
	if {[llength $itk_option(-sizes)] == $num_cols_} {
	    # use list of column sizes
	    set c 0
	    foreach i $itk_option(-sizes) {
		incr c
		set size_($c) [max $size_($c) $i]
	    }
	} else {
	    # calculate max col size (loop through each row, col)
	    foreach j $disp_info_ {
		set c 0
		foreach i $j {
		    incr c
		    if { $c > $num_cols_ } {
			error "Unknown column : $i, position $c, num_cols_ = $num_cols_"
		    } else {
			set size_($c) [max $size_($c) [string length $i]]
		    }
		}
	    }
	}
    }


    #############################################################
    #  Name: calculate_format
    #
    #  Description:
    # Calculate the print formats for table rows from the max 
    # column widths and options. The format string takes care of
    # column widths, show/hide column and column separators.
    #
    # If the format was set explicitly (formats_flag_ = 1), use it
    # otherwise, if the column widths are known (-sizes was set) use them,
    # otherwise calculate the max column widths from the info list.
    #
    # The formats list uses %n$-s type format strings to set left/right 
    # alignment, width and order all at once, for example:
    # "%-10s" for left justify, "%.0s" effectively hides the item...
    #
    # If the Precision option is set for a column, assume it is a floating
    # point value to be formatted like: %6.2f for example (precision = 2)
    #############################################################
    #############################################################
    public method calculate_format {} {
	if {$formats_flag_} {
	    return
	}
	get_col_sizes_

	set hformats_ {}
	set formats_ {}
	set order_ {}

	foreach name [$itk_component(config_file) get_order] {
	    if {! [info exists ord_($name)]} {
		error "Unknown column name: '$name'"
	    }
	    set col $ord_($name)
	    lappend order_ [expr $num_cols_-1]

	    set align [$itk_component(config_file) get_option $name Align]
	    set show [$itk_component(config_file) get_option $name Show]
	    set sep [$itk_component(config_file) get_option $name Separator]
	    set prec [$itk_component(config_file) get_option $name Precision]

	    if {"$align" == "Left"} {
		set a -
	    } else {
		set a {}
	    }

	    if {$prec == 0} {
		set p {}
		set t s
	    } else {
		set p .$prec
		set t f
	    }

	    if {!$show} {
		::append formats_ [set f [format {%%%d$.0s} $col]]
		::append hformats_ $f
		#debugStatement "!Show:Appending $f.."
	    } else {
		::append formats_ [format {%%%d$%s%d%s%s %s } $col $a $size_($col) $p $t $sep]
		::append hformats_ [format {%%%d$%s%ds %s } $col $a $size_($col) $sep]
	    }
	}
    }


    #############################################################
    #  Name: setup_matching_
    #
    #  Description:
    # set up the wildcard list to filter the info list
    #############################################################
    #############################################################    
    private method setup_matching_ {} {
	set m {}
	set match_all_ 1
	foreach name $headings_ {
	    set wildcard [$itk_component(config_file) get_option $name Wildcard]
	    if {"$wildcard" == ""} {
		set wildcard $match_any_
	    } elseif {"$wildcard" != "$match_any_"} {
		set match_all_ 0
	    }
	    ::append m "{$wildcard} "
	}
	set match_list_ [string trimright $m]
    }

    #############################################################
    #  Name: match_info_
    #
    #  Description:
    # apply the current wildcard filters to the info list
    # so that only the rows that match will be displayed
    #############################################################
    #############################################################
    private method match_info_ {} {
	#  Compose the matching string, set
	#  info_cols=#cols and num of rows to total_rows
	#  If we are to match then all, then just set the
	#  display list (disp_info_) to be the whole list (info_),
	#  otherwise for each row in info_ check to see if we are
	#  to add this row, and appends to disp_info_ accordingly.
	setup_matching_
	set info_cols_ [llength $headings_]
	set total_rows_ [llength $info_]

	if {$match_all_} {
	    set disp_info_ $info_
	    set info_rows_ $total_rows_
	} else {
	    set disp_info_ {}
	    set info_rows_ 0
	    foreach i $info_ {
		if {[$match_proc_ $i]} {
		    lappend disp_info_ $i
		    incr info_rows_
		} 
	    }
	}
    }


    #############################################################
    #  Name: sort_info_
    #
    #  Description:
    # sort the info list, if requested, based on the
    # sort keys
    #############################################################
    #############################################################
    private method sort_info_ {} {
	if {"$itk_option(-sort_by)" != ""} {
	    debugStatement "sort_info_: entry...."
	    set disp_info_ [lsort -$itk_option(-sort_order) \
				-command [code $this cmp_row_] $disp_info_]
	}
    }

    #############################################################
    #  Name: cmp_row_
    #
    #  Description:
    # compare the 2 given rows, ascii version (called by lsort above)
    # (see lsort man page for desc.)
    #############################################################
    #############################################################
    private method cmp_row_ {r1 r2} {
	foreach i $itk_option(-sort_by) {
	    if {"[set v1 [lindex $r1 $i]]" > "[set v2 [lindex $r2 $i]]"} {
		return 1
	    } elseif {$v1 < $v2} {
		return -1
	    }
	}
	return 0
    }


    #############################################################
    #  Name: move_down
    #
    #  Description:
    # move the selected row down 1 row
    # and make the changes in the info list
    #############################################################
    #############################################################
    public method move_down {} {
	set list [$listbox_ curselection]
	if {"$list" == ""} {
	    return
	}
	set rlist [lsort -decreasing $list]
	foreach i $rlist {
	    set s [$listbox_ get $i]
	    set r [lindex $disp_info_ $i]
	    $listbox_ delete $i
	    set disp_info_ [lremove $disp_info_ $i]
	    set j [expr $i+1]
	    $listbox_ insert $j $s
	    set disp_info_ [linsert $disp_info_ $j $r] 
	}
	select_rows [expr [lindex $list 0]+1] [expr [lindex $rlist 0]+1]
    }

    
    #############################################################
    #  Name: move_up
    #
    #  Description:
    # move the selected row up 1 row
    # and make the changes in the info list
    #############################################################
    #############################################################
    public method move_up {} {
	set list [$listbox_ curselection]
	if {"$list" == ""} {
	    return
	}
	foreach i $list {
	    set s [$listbox_ get $i]
	    set r [lindex $disp_info_ $i]
	    $listbox_ delete $i
	    set disp_info_ [lremove $disp_info_ $i]
	    set j [expr $i-1]
	    $listbox_ insert $j $s
	    set disp_info_ [linsert $disp_info_ $j $r] 
	}
	select_rows [expr [lindex $list 0]-1] [expr $i-1]
    }


    #############################################################
    #  Name: clear
    #
    #  Description:
    # make the table empty
    #############################################################
    #############################################################
    public method clear {} {
	config -info {}
    }


    #############################################################
    #  Name: edit_row
    #
    #  Description:
    # pop up a dialog window to edit the values in the selected row
    #############################################################
    #############################################################
    public method edit_row {} {
	if {! $itk_option(-editable)} {
	    return
	}
	set sel [lindex [get_selected] 0]
	
	if {"$sel" == ""} {
	    set buttons [list [list "Add new row" [code $this add_row]]]
	} else {
	    set buttons [list [list "Add new row" [code $this add_row]] \
			     [list "Delete this row" [code $this remove_row]]]
	}
	
	catch {destroy $w_.form}
	EntryForm $w_.form \
	    -title "Edit Values" \
	    -labels $headings_ \
	    -values $sel \
	    -command [code $this set_row $sel] \
	    -buttons $buttons
    }


    #############################################################
    #  Name: set_row
    #
    #  Description:
    # replace the contents of the given row with the new info
    # Note: this assumes that no 2 rows are exactly alike.
    # We can't use the row index here, since sorting and matching 
    # may mix things up too much.
    #############################################################
    #############################################################
    public method set_row {oldrow newrow} {
	debugStatement "set_row:  entry.... "
	#
	#  Find the row that contains the id_index
	#  Warning: this won't work if some columns are hidden.
	set index [lsearch -exact $info_ $oldrow]
	# WARNING, remove tmprow later.
	set tmprow [lindex $info_ $index]
	debugStatement "set_row: info index = $index, row=$tmprow"
	set info_ [lreplace $info_ $index $index $newrow]
	set tmprow [lindex $info_ $index]
	debugStatement "set_row: after replace, row=$tmprow"
	#save_yview
	#save_selection
	config -info $info_
	#restore_selection
	#restore_yview
    }

    #############################################################
    #  Name: save_rows
    #
    #  Description:
    # Save to config file.
    #############################################################
    #############################################################
    public method save_rows { file } {
	debugStatement "save_rows: entry...."

	calculate_format
	set n 0
	foreach linez $info_ {
	    incr n
	    if {[catch {format_line_ $linez} msg]} {
                ::cat::vmAstroCat::error_dialog "error in input for table row $n:\n'$i'\n: wrong no. of columns ?"
		break
	    }
	    puts $file $msg
	}
	debugStatement "save_rows: finished writing out file..."
    }
    
    #############################################################
    #  Name: add_row
    #
    #  Description:
    # add a new row to the list and update the display
    #############################################################
    #############################################################
    public method add_row {newrow} {
	lappend itk_option(-info) $newrow
	new_info
    }

    

    #############################################################
    #  Name: remove_row
    #
    #  Description:
    # remove the given row (given by its value)
    #############################################################
    #############################################################
    public method remove_row {row} {
	set index [lsearch -exact $info_ $row]
	select_row $index
	remove_selected
    }


    
    #############################################################
    #  Name: save_yview
    #
    #  Description:
    # save the current scroll position so it can be restored
    # later. 
    #############################################################
    #############################################################
    public method save_yview {} {
	set saved_yview_ [lindex [$listbox_ yview] 0]
	set tmpview [$listbox_ yview]
	debugStatement "saved_yview = $saved_yview_ "
	debugStatement "save_yview , listbox yview = $tmpview"
    }


    #############################################################
    #  Name: restore_yview
    #
    #  Description:
    # restore the previously saved scroll position 
    #############################################################
    public method restore_yview {} {
	$listbox_ yview moveto $saved_yview_
	debugStatement "restore_yview = $saved_yview_ "
    }

    
    # save a list of the currently selected rows so they can be restored
    # later. 
    public method save_selection {} {
	set saved_selection_ [$listbox_ curselection]
	debugStatement "save_selection:  $saved_selection_..."
    }


    # restore the previously saved row selection
    public method restore_selection {} {
	set n [llength $saved_selection_]
	debugStatement "restore, num rows previously selected=$n..."
	if {$n > 1 } {
	    set x [lindex $saved_selection_ 0]
	    debugStatement "x=$x"
	    set y  $n
	    set y1 [incr y -1]
	    debugStatement "y=$y, y1=$y1"
	    set z [lindex $saved_selection_ $y1]
	    debugStatement "second thing: $z"
	    select_rows [lindex $saved_selection_ 0] \
		[lindex $saved_selection_ [incr n -1]]
	} elseif {$n == 1}  {
	    set x [lindex $saved_selection_ 0]
	    debugStatement "x=$x"
	    select_rows [lindex $saved_selection_ 0] \
		[lindex $saved_selection_ 0] 
	}
    }


    # return true if the given row matches the current wildcard patterns
    private method match_glob_ {row} {
	for {set i 0} {$i < $info_cols_} {incr i} {
	    if {![string match [lindex $match_list_ $i] [lindex $row $i]]} {
		return 0
	    }
	}
	return 1
    }


    # return true if the given row matches the current regexp
    private method match_regexp_ {row} {
	for {set i 0} {$i < $info_cols_} {incr i} {
	    if {![regexp -- [lindex $match_list_ $i] [lindex $row $i]]} {
		return 0
	    }
	}
	return 1
    }


    # return true if the given row matches the current regexp (ignore case)
    private method match_regexp_nocase_ {row} {
	for {set i 0} {$i < $info_cols_} {incr i} {
	    if {![regexp -nocase -- [lindex $match_list_ $i] [lindex $row $i]]} {
		return 0
	    }
	}
	return 1
    }


    # append a row to the table. (call new_info when done)
    public method append_row {row} {
	lappend itk_option(-info) $row
    }


    # append a list of rows to the table
    public method append_rows {rows} {
	foreach i $rows {
	    append_row $i
	}
	new_info
    }

    
    # this method is called whenever the info list changes
    public method new_info {} { 
	debugStatement "new_info: entry... "
	set info_ $itk_option(-info)
	match_info_
	sort_info_
	set_info_
    }


    # this method is called whenever the headings list changes
    public method new_headings {} {

        set headings_ $itk_option(-headings)

        #@@cba
        # puts "new_headings $headings_"
        if {"$headings_" != ""} {
            if {[winfo exists $menubutton_]} {
		$menubutton_ config -state normal
            }
            #puts "in block"
    	    # set number of cols, heading sizes, col order
    	    set num_cols_ 0
            #@cba
            # puts "headings = $headings_"
    	    foreach i $headings_ {
		incr num_cols_
		if {$itk_option(-headinglines) == 1} {
		    set hsize_($num_cols_) [string length $i]
		} else {
		    set hsize_($num_cols_) \
			[max [string length [lindex $i 0]] \
			     [string length [lindex $i 1]]]
		}
		set ord_($i) $num_cols_                
    	    }
	    $itk_component(config_file) config -headings $headings_
    	}
    }


    # update the display with the new info
    private method set_info_ {} {
	debugStatement "set_info_: entry ..."
	calculate_format
	set_headings_
	$listbox_ delete 0 end

	set n 0
	foreach i $disp_info_ {
	    incr n
	    if {[catch {format_line_ $i} msg]} {
                ::cat::vmAstroCat::error_dialog "error in input for table row $n:\n'$i'\n: wrong no. of columns ?"
		break
	    }
	    $listbox_ insert end $msg
	}
    }

    
    # if using 2 line headings, split the table headings in 2 lines 
    # and return the results as a list of heading lines, otherwise 
    # just return a list whose only element is the single line of headings.
    private method split_headings_ {} {
	if {$itk_option(-headinglines) == 1} {
	    return [list $headings_]
	}
	set h1 {}
	set h2 {}
	foreach i $headings_ {
	    if {[llength $i] == 2} {
		lappend h1 [lindex $i 0]
		lappend h2 [lindex $i 1]
	    } else {
		lappend h1 {}
		lappend h2 $i
	    }
	}
	return [list $h1 $h2]
    }


    # set the table headings -
    # Note: headings may be 1 or 2 lines. The first and second lines
    # should be separated by spaces i.e.: {Sub Total} to put "Sub"
    # on the first line and "Total" on the second.
    # use the -headinglines 2 option to enable this...
    private method set_headings_ {} {
	$headbox_ delete 0 end
	foreach h [split_headings_] {
	    $headbox_ insert end [set s [format_headings_ $h]]
	}
	set line_length_ [string length $s]
	debugStatement "set_headings_: formated headings<$line_length_>: $s..."
	
    }


    # search for and highlight the first row containing the given value
    # in the named column
    public method search {name value} {
	if {[set idx [lsearch -exact $headings_ $name]] < 0} {
	    return
	}
	set n 0
	foreach row $disp_info_ {
	    if {"[lindex $row $idx]" == "$value"} {
		select_row $n
		break
	    }
	    incr n
	}
    }


    
    #############################################################
    #  Name: get_selected
    #
    #  Description:
    # return a list of the selected rows
    # note: uses disp_info_, since listbox contains formated lines
    #############################################################
    #############################################################
    public method get_selected {} {
	#
	#  For each item highlighted in the list box, put it as a
	#  line in the list array.  Then return that list.
	set list {}
	foreach i [$listbox_ curselection] {
	    lappend list [lindex $disp_info_ $i]
	}
	return $list
    }

    
    # return a list of {{rownum row} {rownum row} ...} for the
    # selected rows.
    public method get_selected_with_rownum {} {
	set list {}
	foreach i [$listbox_ curselection] {
	    lappend list [list $i [lindex $disp_info_ $i]]
	}
	return $list
    }
    

    # return the table headings
    public method get_headings {} {
	return $headings_
    }


    # remove the selected rows from the table
    # and return them as a list of lists
    public method remove_selected {} {
	set list [get_selected]
	set n 0
	foreach i [lsort -decreasing [$listbox_ curselection]] {
	    set disp_info_ [lremove $disp_info_ $i]
	    incr n
	}
	# note: hack: assumes matching is off...
	config -info $disp_info_
	if {$n} {
	    select_row $i
	}
	return $list
    }


    # pop up a window to change the layout of the table and
    # call the optional command when done.
    public method layout_dialog {} {
	if {"$headings_" == ""} {
	    return
	}
	busy {
	    set w [format {%s.tblcfg} [utilGetTopLevel $w_]]
	    utilReUseWidget TableListConfig $w \
		-table $this \
		-command $itk_option(-layoutcommand) \
		-transient 1
	}
    }


    # return the total number of rows (before matching)
    public method total_rows {} {
	return $total_rows_
    }


    # return the number of rows being displayed in the table (after matching)
    public method info_rows {} {
	return $info_rows_
    }


    # pop up a dialog to sort the contents of the table
    public method sort_dialog {} {
	if {"$headings_" == ""} {
	    return
	}
	busy {
	    set w [format {%s.tblsort} [utilGetTopLevel $w_]]
	    utilReUseWidget util::TableListSort $w \
		-table $this \
		-command $itk_option(-sortcommand) \
		-transient 1
	}
    }


    # pop up a dialog to print the contents of the table to a printer
    # or file
    public method print_dialog {} {
	if {"$headings_" == ""} {
	    ::cat::vmAstroCat::error_dialog "There is nothing to print"
	    return
	}
	busy {
	    set w [format {%s.tblprint} [utilGetTopLevel $w_]]
	    if {[winfo exists $w]} {
		wm deiconify $w
	    } else {
		TableListPrint $w -table $this -printcmd $itk_option(-printcmd)
	    }
	}
    }


    # print the table heading(s) given by h1 and h2 to the given fd and 
    # underline it (them) with the given underline char
    private method print_heading_ {fd h1 h2 underline} {
	puts $fd "\n$h1"
	if {"$h2" != ""} {
	    puts $fd $h2
	}
	puts $fd "[replicate $underline [max [string length $h1] [string length $h2]]]\n"
    }
    

    # print the contents of the table to the open file descriptor
    public method print {fd} {
	if {"$itk_option(-title)" != ""} {
	    print_heading_ $fd "$itk_option(-title)" "" "*"
	}

	if {$itk_option(-headinglines) == 1} {
	    print_heading_ $fd [format_headings_ $headings_] "" "="
	} else {
	    set h [split_headings_] 
	    print_heading_ $fd [format_headings_ [lindex $h 0]] \
		[format_headings_ [lindex $h 1]] "="
	}
	foreach i $disp_info_ {
	    puts $fd [format_line_ $i]
	}
    }

    # return the contents of the table as a list of rows
    public method get_contents {} {
	return $disp_info_
    }


    #***********************************************************************
    # PROC NAME:
    # myprint
    #
    # PUBLIC METHODS: 
    # (type) method - description
    #
    # PUBLIC DATA: (">" input, "!" modified, "<" output)
    # (type) data - description
    #
    # PURPOSE:
    # Print info retrieved from the file to result.  This file is used
    # as input for the SPOC function.
    # For each thing in the config file, which somehow is like
    # the table that is in the display.   ???not following, -mischa
    #
    #***********************************************************************
    public method myprint {file maxSlitsizeX maxSlitsizeY} {
	get_col_sizes_
	set formats_ {}
	set order_ {}
	set prOrder_ {"ID" "RA" "DEC" "x_ccd" "y_ccd" "slitpos_x" "slitpos_y" "slitsize_x" "slitsize_y" "slittilt" "MAG" "priority" "slittype" "redshift"}
	
	# The content of this variable will be displayed to the user,
	# at some point.
	# --umh, i don't know where... -mischa
	set outputMessage ""
	set prioWarningFlag 0
	set slitXSizeWarningFlag 0
	set slitYSizeWarningFlag 0
	
	set slitsize_yName ""
	set slitsize_yIndex [lsearch -regex $headings_ "(?i)slitsize_y" ]
	if {$slitsize_yIndex != -1 && [lindex $headings_ $slitsize_yIndex ] != "slitsize_y"} {
	    # slitsize_y is present but not in the correct case, save name for array lookup.
	    set slitsize_yName [lindex $headings_ $slitsize_yIndex ]
	} else {
	    set slitsize_yName "slitsize_y"
	}

	#  Given the columns name  and a specific order that we 
	#  need them in, get the format string for those specific
	#  fields.  Warning, index of columns starts at 0, but $ord($name)
	#  returns position, starting at 1.  So have to subtract.
	set i 0
	foreach name $prOrder_ {
	    incr i	    
	    set knownIndex [lsearch -regex $headings_ "(?i)$name" ]
	    if {$knownIndex != -1 && [lindex $headings_ $knownIndex ] != $name} {
		# This heading is a case-insensitive match with a known column,
		# so set name to the case of the actual heading. 
		set name [lindex $headings_ $knownIndex ]
	    }
	    
	    set col $ord_($name)
	    set numOrder_($i) [expr $col-1 ]
	    set align [$itk_component(config_file) get_option $name Align]
	    set sep [$itk_component(config_file) get_option $name Separator]
	    set prec [$itk_component(config_file) get_option $name Precision]

	    if {"$align" == "Left"} {
		set a -
	    } else {
		set a {}
	    }

	    if {$prec == 0} {
		set p {}
		set t s
	    } else {
		set p .$prec
		set t f
	    }

	    #  Create the format string to be used when printing.
	    ::append formats_ [format {%%%d$%s%d%s%s %s } $i $a $size_($col) $p $t $sep]    
	}

	#  Open file *.dat_temp.  Then for each line in the mycatname.cat
	#  print out only the col's we are interested in the format
	#  we determined above.
	#  
	#### WARNING, Clean up later, and put in 1 line. Hah.
	set dat [open [file rootname $file].dat_temp w]

	set linez {}
	foreach linez $disp_info_ {

	    # Slits with invalid priorities should not be added.
	    if {[lindex $linez $numOrder_(12)] > 3} {
		# Invalid priority.
		if {!$prioWarningFlag} {
		    set prioWarningFlag 1
		    set prioWarn "WARNING: Slit(s) dropped for invalid priority."
		    set outputMessage [concat $outputMessage "$prioWarn"]
		}
		continue
	    }
	    if {[lindex $linez $numOrder_(8)] > $maxSlitsizeX} {
		# Slit is too long in the 'x' dimension.		
		if {!$slitXSizeWarningFlag} {
		    set slitXSizeWarningFlag 1
		    set xWarn "WARNING: Slit(s) dropped for exceeding max slitsize_x ($maxSlitsizeX arcseconds)."
		    set outputMessage [concat $outputMessage "$xWarn"]
		}
		continue
	    }
	    
	    if {[lindex $linez $numOrder_(9)] > $maxSlitsizeY} {
		# Slit is too long in the 'y' dimension.
		
		if {!$slitYSizeWarningFlag} {
		    set slitYSizeWarningFlag 1
		    set yWarn "WARNING: Slit(s) dropped for exceeding max slitsize_y ($maxSlitsizeY arcseconds)."
		    set outputMessage [concat $outputMessage "$yWarn"]
		}
		continue
	    }
	    
	    set freshLine_ {}
	    set freshLine_ "[lindex $linez $numOrder_(1)]"
	    set freshLine_ "$freshLine_ [lindex $linez $numOrder_(2)]"
	    set freshLine_ "$freshLine_ [lindex $linez $numOrder_(3)]"
	    set freshLine_ "$freshLine_ [lindex $linez $numOrder_(4)]"
	    set freshLine_ "$freshLine_ [lindex $linez $numOrder_(5)]"
	    set freshLine_ "$freshLine_ [lindex $linez $numOrder_(6)]"
	    set freshLine_ "$freshLine_ [lindex $linez $numOrder_(7)]"
	    set freshLine_ "$freshLine_ [lindex $linez $numOrder_(8)]"
	    set freshLine_ "$freshLine_ [lindex $linez $numOrder_(9)]"
	    set freshLine_ "$freshLine_ [lindex $linez $numOrder_(10)]"
	    set freshLine_ "$freshLine_ [lindex $linez $numOrder_(11)]"
	    # Make sure priority is only one character.
	    set freshLine_ "$freshLine_ [string index [lindex $linez $numOrder_(12)] 0]"
	    set freshLine_ "$freshLine_ [lindex $linez $numOrder_(13)]"
	    set freshLine_ "$freshLine_ [lindex $linez $numOrder_(14)]"

	    #  Now print the fresh line, using the format string.
	    set x [format_line_ $freshLine_]
	    puts $dat $x
	}
	close $dat

	return $outputMessage
    }

    
    # set the option value for the given heading name
    # 
    # Options: 
    #  Show (bool)         - display or don't display the column
    #  Align (Left,Right)  - for left or right justify
    #  Separator           - set the separator string (goes after col)
    #  Wildcard            - only show rows where wildcard matches
    #  Precision           - number of places after the decimal for floating point values
    public method set_option {name option value} {
	$itk_component(config_file) set_option $name $option $value
    }

    
    # same as set_option, but works on a list of column heading names
    public method set_options {headings option value} {
	foreach name $headings {
	    $itk_component(config_file) set_option $name $option $value
	}
    }
    
    # return the option value for the given heading name.
    # See above for list of Options...
    public method get_option {name option} {
	return [$itk_component(config_file) get_option $name $option]
    }

    
    # scroll both the heading box and the main listbox syncronously
    # (called for horizontal scrolling in listbox)
    public method xview {args} {
	eval "$listbox_ xview $args"
	eval "$headbox_ xview $args"
    }


    # scroll the listbox vertically
    public method yview {args} {
	eval "$listbox_ yview $args"
    }


    # load the named config file and update the display based on the new settings
    protected method load_config {file} {
	$itk_component(config_file) load $file
	#puts "loading $file"
	new_info
    }

    
    # get a name from the user and use it to save the current 
    # configuration to a file under the user's home directory
    protected method delete_config {file} {
	set s [file tail $file]
	exec rm -f $file
	if {[winfo exists $menubutton_]} {
	    $menubutton_.menu.load_pr delete $s
	    $menubutton_.menu.delete_pr delete $s
	}
    }

    
    # get a name from the user and use it to save the current 
    # configuration to a file under the user's home directory
    public method save_dialog {} {
	set name [::cat::vmAstroCat::my_input_dialog "Please enter a name to use for this configuration:" $w_]
	if {"$name" == ""} {
	    return
	}
	set file [utilGetConfigFilename $w_ $name]
	set s [file tail $file]
	if {[winfo exists $menubutton_]} {
	    if {![file exists $file]} {
		$menubutton_.menu.load_pr add command -label $s \
		    -command [code $this load_config $file]
		$menubutton_.menu.delete_pr add command -label $s \
		    -command [code $this delete_config $file]
	    }
	}
	$itk_component(config_file) save $file
    }


    # add the table config menu items to the given menu
    public method make_table_menu {} {
	# optional menu with table operations
	itk_component add menubutton {
	    menubutton $itk_option(-menubar).table \
		-text Table \
		-menu $itk_option(-menubar).table.menu \
		-state disabled
	}
	set menubutton_ $itk_component(menubutton)
	pack $menubutton_ -side left -padx 1m -ipadx 1m
	set m [menu $menubutton_.menu]
	$m add command -label "Print..." \
	    -command [code $this print_dialog]
	$m add command -label "Sort..." \
	    -command [code $this sort_dialog]
	$m add command -label "Configure..." \
	    -command [code $this layout_dialog]
	$m add command -label "Save Configuration..." \
	    -command [code $this save_dialog]
	# add a menu for the previously saved configurations
	$m add cascade -label "Load Configuration" \
	    -menu $m.load_pr
	$m add cascade -label "Delete Configuration" \
	    -menu $m.delete_pr
	menu $m.load_pr
	menu $m.delete_pr
	set dir [utilGetConfigFilename $w_]
	foreach file [glob -nocomplain $dir/*] {
	    set s [file tail $file]
	    $m.load_pr add command -label $s \
		-command [code $this load_config $file]
	    $m.delete_pr add command -label $s \
		-command [code $this delete_config $file]
	}
    }


    # update the indexes ($sort_by) for the sort columns
    public method update_sort_info {} {
	# map headings to col index
	set i -1
	foreach name $headings_ {
	    set col($name) [incr i]
	}
	set sort_by {}
	foreach name $itk_option(-sort_cols) {
	    lappend sort_by $col($name)
	}
	config -sort_by $sort_by
    }


    # -- options --
    
    # name of menubar frame in which to place table menubutton (optional)
    itk_option define -menubar menubar Menubar {} {
	if {"$itk_option(-menubar)" != ""} {
	    make_table_menu
	}
    }

    # field names for heading - Note: specify before "-info"
    itk_option define -headings headings Headings {} {
	new_headings
    }

    # list of lists, one per line to display in table/list
    itk_option define -info info Info {} {
	new_info
    }

    # list of column sizes
    # (if not specified, will be calculated)
    itk_option define -sizes sizes Sizes {}

    # if true, reuse the calculated column sizes rather than recalculate
    # for new info
    itk_option define -static_col_sizes static_col_sizes Static_col_sizes 0

    # list of printf formats for columns
    # (if not specified, will be calculated, see also -sizes)
    itk_option define -formats formats Formats {} {
	if {"$itk_option(-formats)" != ""} {
	    set formats_flag_ 1
	    config -hformats [set formats_ $itk_option(-formats)]
	}
    }

    # print format string for the headings 
    # (set after -formats, defaults to same as $formats_)
    # This might be different for headings if a column uses %f formats...
    itk_option define -hformats hformats Hformats {} {
	set hformats_ $itk_option(-hformats)
    }
    
    # command to call to filter each row,
    # hook to modify the row before it is displayed
    # arg is is the name of the list holding the row (call by reference)
    itk_option define -filtercmd filtercmd Filtercmd "#"

    # default print command
    itk_option define -printcmd printcmd Printcmd {lpr}

    # -- sort options --

    # list of col names to sort by (empty means don't sort)
    itk_option define -sort_cols sort_cols Sort_cols {} {
	update_sort_info
    }

    # set the order of the columns
    itk_option define -order order Order {} {
	if {"$itk_option(-order)" != ""} {
	    $itk_component(config_file) config -order $itk_option(-order)
	}
    }

    # list of col index: sort table based on given columns 
    # (empty means don't sort)
    itk_option define -sort_by sort_by Sort_by {} {
	$itk_component(config_file) config -sort_by $itk_option(-sort_by)
    }

    # set direction of sort: may be one of (increasing, decreasing) 
    itk_option define -sort_order sort_order Sort_order {increasing} {
	if {"$itk_option(-sort_order)" == ""} {
	    config -sort_order increasing
	} else {
	    $itk_component(config_file) config -sort_order $itk_option(-sort_order)
	}
    }

    # command to call when sort options have been selected
    itk_option define -sortcommand sortCommand SortCommand {}

    # command to call when layout options have been selected
    itk_option define -layoutcommand layoutCommand LayoutCommand {}

    # -- match options --

    # flag: if true, use regular exprs for matching, otherwise use wildcards
    itk_option define -use_regexp use_regexp Use_regexp {0} {
	if {$itk_option(-use_regexp)} {
	    set match_any_ ".*"
	    set match_proc_ match_regexp_
	} else {
	    set match_any_ "*"
	    set match_proc_ match_glob_
	}
	$itk_component(config_file) config \
	    -headings $headings_ \
	    -use_regexp $itk_option(-use_regexp)
    }

    # flag: if true, ignore case in matching 
    # (only works when -use_regexp 1 was specified)
    itk_option define -ignore_case ignore_case Ignore_case 0 {
	if {$itk_option(-ignore_case)} {
	    set match_any_ ".*"
	    set match_proc_ match_regexp_nocase_
	} else {
	    config -use_regexp $itk_option(-use_regexp)
	}
    }

    # -- protected members --

    # table column headings
    protected variable headings_ {}

    # table contents as list of rows/cols
    protected variable info_ {}

    # printf format string for table rows
    protected variable formats_ {}

    # printf format string for table headings
    protected variable hformats_ {}

    # flag: true if the -formats option was specified
    # so that we don't have to calculate the format string for a row
    protected variable formats_flag_ {0}

    # list of indexes in row for headings (indep. of viewing order)
    protected variable order_ {}

    # box for headings
    protected variable headbox_

    # list of glob expressions for matching rows to wildcards
    protected variable match_list_ {*}

    # flag: true if match_list_ should match all rows
    protected variable match_all_ {1}

    # string used to match any string
    protected variable match_any_ {*}

    # method to use for matching rows (match_glob_ or match_regexp_)
    protected variable match_proc_ {match_glob_}

    # number of rows in the info list (not including hidden rows)
    protected variable info_rows_ {0}

    # number of columns in table 
    protected variable info_cols_ 0

    # length of a line in the table
    protected variable line_length_ 0

    # total number of rows, including hidden rows
    protected variable total_rows_ {0}

    # list of info to display (after filtering and sorting)
    protected variable disp_info_ {}

    # used for save_/restore_yview methods
    protected variable saved_yview_ 0

    # used for save_/restore_selection methods
    protected variable saved_selection_ {}

    # array(col) of col width
    protected variable size_
    
    # array(col) of heading width
    protected variable hsize_

    # number of columns
    protected variable num_cols_ 0

    # array(heading) of column order
    protected variable ord_

    # menubutton widget
    protected variable menubutton_ {}

    # debugLevel
    protected variable tlDebugLevel 0
}
