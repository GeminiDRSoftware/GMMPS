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

##################################################################
#              NOTE NOTE NOTE
#
#   GLOBAL variables in this routine are UPPERCASE
#   Sorry about the globals, but they make it much easier here
# 
##################################################################

itcl::class cat::waveMapper {
    inherit util::TopLevelWidget
    
    #  constructor
    constructor {config_file} {
		
		set args {}
		eval itk_initialize $args
		set config_file_ $config_file

		# The default instrument shown is GMOS-N
		set itk_option(-instType) "GMOS-N"
	    }

    
    # destructor    
    destructor {
        close
    }
    
    
    #############################################################
    #  Name: init
    #
    #  Description:
    #############################################################
    #############################################################
    protected method init {} {
	wm title $w_ "GMOS Wavelength Mapper"
	wm iconname $w_ "GMOS Wavelength Mapper ($itk_option(-number)"
	set home $::env(GMMPS)
	make_layout
    }
    
    #############################################################
    #  Name: make_layout
    #
    #  Description: 
    #    Draw the WMODF window
    #############################################################
    #############################################################    
    protected method make_layout {} {
	# Globals...
	global ::cbo_wmodf_2ndorder  ::cbo_wmodf_slitpos
	global ::cbo_wmodf_spectra   ::cbo_wmodf_showwavegrid

	set home $::env(GMMPS)	

	set instType $itk_option(-instType)

	##########################################################
	# The main frame containing all elements
	##########################################################
	pack [frame $w_.wmodfInstTypeFrame -borderwidth 2 -relief groove -background $wmodf_bg_] \
	    -side top -anchor w -fill both

	pack [frame $w_.wmodfMainFrame -borderwidth 2 -relief groove -background $wmodf_bg_] \
	    -side top -anchor w -fill both
	
	pack [frame $w_.wmodfEmLineFrame -borderwidth 2 -relief groove -background $wmodf_bg_] \
	    -side top -anchor w -fill both -ipady 10 -ipadx 10
	
	pack [frame $w_.throughput -relief groove -borderwidth 2 -background $wmodf_bg_] \
	    -side top -anchor w -fill both
	
	
	#############################################################
	# The top frame from which we chose what GMOS type to display
	#############################################################
	pack [frame $w_.topLeft  -background $wmodf_bg_] \
	    -side left -anchor w -fill both -in $w_.wmodfInstTypeFrame
	pack [frame $w_.topRight -background $wmodf_bg_] \
	    -side right -anchor e -fill both -in $w_.wmodfInstTypeFrame

	pack [label $w_.topLeft.label -text "Wavelength maps for" \
		  -background $wmodf_bg_ -foreground "#55f"] \
	    -in $w_.topLeft -anchor w -ipady 5
	# The options
	pack [LabelMenu $w_.topLeft.options \
		  -text "" -relief groove -background $wmodf_bg_ \
		  -orient horizontal -labelfont "Arial 12 bold" ] \
	    -side top -anchor w -in $w_.topLeft \
	    -padx 5 -ipadx 5 -ipady 5
	
	pack [button $w_.help -text "Help" -bg "#9ff" -fg "#00f" \
		  -activebackground "#bff" -activeforeground "#00f" \
		  -command [code $this help file://$home/html/wavemapper.html] -anchor w] \
	    -side right -anchor n -in $w_.topRight

	$w_.topLeft.options add -label "GMOS-N Longslit" \
	    -command [code $this update_instwavetype]
	$w_.topLeft.options add -label "GMOS-N IFU-R" \
	    -command [code $this update_instwavetype]
	$w_.topLeft.options add -label "GMOS-N IFU-2" \
	    -command [code $this update_instwavetype]
	$w_.topLeft.options add -label "GMOS-S Longslit" \
	    -command [code $this update_instwavetype]
	$w_.topLeft.options add -label "GMOS-S IFU-R" \
	    -command [code $this update_instwavetype]
	$w_.topLeft.options add -label "GMOS-S IFU-2" \
	    -command [code $this update_instwavetype]

	##########################################################
	# The two frames containing the checkbuttons, 
	# and one for the Reload/Close buttons
	##########################################################
	pack \
	    [frame $w_.wmodfButtonFrame1 -background $wmodf_bg_] \
	    -in $w_.wmodfMainFrame -fill x -padx 10 -pady 10 -side left -anchor n
	
	pack \
	    [frame $w_.wmodfButtonFrame2 -background $wmodf_bg_] \
	    -in $w_.wmodfMainFrame -fill x -padx 10 -pady 10 -side right -anchor n
	
	# CheckBoxes for plotting things
	checkbutton $w_.wmodfPlotCBO_spectra   -background $wmodf_bg_ -command [code $this slits_WMODF] \
	    -activebackground $button_bg_active_wmodf_ -text "Spectra" -variable cbo_wmodf_spectra
	checkbutton $w_.wmodfPlotCBO_showwavegrid  -background $wmodf_bg_ -command [code $this slits_WMODF] \
	    -activebackground $button_bg_active_wmodf_ -text "Wavelength grid" -variable cbo_wmodf_showwavegrid \
	    -disabledforeground #666
	checkbutton $w_.wmodfPlotCBO_2ndorder   -background $wmodf_bg_ -command [code $this slits_WMODF] \
	    -activebackground $button_bg_active_wmodf_ -text "2nd order" -variable cbo_wmodf_2ndorder \
	    -disabledforeground #666
	checkbutton $w_.wmodfPlotCBO_slitpos   -background $wmodf_bg_ -command [code $this slits_WMODF] \
	    -activebackground $button_bg_active_wmodf_ -text "Slit position" -variable cbo_wmodf_slitpos \
	    -disabledforeground #666
	checkbutton $w_.wmodfPlotCBO_indwave -background $wmodf_bg_ -command [code $this slits_WMODF] \
	    -activebackground $button_bg_active_wmodf_ -text "Other wavelengths \[nm\]" -variable cbo_wmodf_indwave \
	    -disabledforeground #666
	
	# default states
	$w_.wmodfPlotCBO_spectra    deselect
	$w_.wmodfPlotCBO_showwavegrid  deselect
	$w_.wmodfPlotCBO_2ndorder   deselect
	$w_.wmodfPlotCBO_slitpos    deselect
	$w_.wmodfPlotCBO_indwave    deselect

	# Pack checkboxes
	
	# Button frame 1
	pack [label $w_.wmodfButtonLabel -text "Display options" -background $wmodf_bg_ -foreground #55f] \
	    -in $w_.wmodfButtonFrame1 -anchor w -ipady 5
	pack $w_.wmodfPlotCBO_spectra      -in $w_.wmodfButtonFrame1 -anchor w
	pack $w_.wmodfPlotCBO_showwavegrid -in $w_.wmodfButtonFrame1 -anchor w
	pack $w_.wmodfPlotCBO_2ndorder     -in $w_.wmodfButtonFrame1 -anchor w
	pack $w_.wmodfPlotCBO_slitpos      -in $w_.wmodfButtonFrame1 -anchor w
	
	# Help
	add_short_help $w_.wmodfPlotCBO_spectra   {{bitmap b1} = Show the spectra}
	add_short_help $w_.wmodfPlotCBO_slitpos   {{bitmap b1} = Show the slit positions}
	add_short_help $w_.wmodfPlotCBO_acqonly   {{bitmap b1} = Show acquisition sources only}
	add_short_help $w_.wmodfPlotCBO_showwavegrid  {{bitmap b1} = Show wavelength labels and markers}
	add_short_help $w_.wmodfPlotCBO_2ndorder  {{bitmap b1} = Show the 2nd order overlap}
	
	# Button frame 2
	pack [label $w_.wmodfButtonLabel2 -text "Settings" -background $wmodf_bg_ -foreground #55f] \
	    -in $w_.wmodfButtonFrame2 -anchor w -ipady 5
	
	# Read the filter and grating configuration files; this sets some global variables such as 
	# wmodf_buf_grate and wmodf_ngrate
	read_grating_filter_data 
	
	# The grating data
	pack [LabelMenu $w_.wmodfButtonFrame2.grateorder \
		  -text "Grating" -relief groove -background $wmodf_bg_ \
		  -orient horizontal] \
	    -side top -anchor w -in $w_.wmodfButtonFrame2 \
	    -padx 5 -ipadx 5 -ipady 5 -fill x

	for {set n 0} {$n < $wmodf_ngrate} {incr n 1} {
	    set grating_name [lindex [lindex $wmodf_buf_grate $n] 0]
	    # Not the combobox, but each entry gets the command assigned!
	    if {$grating_name != "R831_2nd" } { 
		$w_.wmodfButtonFrame2.grateorder add -label $grating_name \
		    -command [code $this procs_for_comboboxes "$instType-wmodf-grating" $grating_name]
	    }
	}
	
	# The filter data
	pack [LabelMenu $w_.wmodfButtonFrame2.filter \
		  -text "Filter" -relief groove -background $wmodf_bg_ \
		  -orient horizontal] \
	    -side top -anchor w -in $w_.wmodfButtonFrame2 \
	    -padx 5 -ipadx 5 -ipady 5 -fill x
	
	for {set n 0} {$n < $wmodf_nfilter} {incr n 1} {
	    set filter_name [lindex $wmodf_buf_filter $n]
	    # Not the combobox, but each entry gets the command assigned!
	    $w_.wmodfButtonFrame2.filter add -label $filter_name \
		-command [code $this procs_for_comboboxes "$instType-wmodf-filter" $filter_name]
	}
	
	# Add a SpinBox to display a change in CWL
	set home $::env(GMMPS)
	image create photo undoarrow -format GIF -file $home/src/undoarrow.gif
	pack \
	    [frame $w_.wmodfCWLFrame -background $wmodf_bg_ ] \
	    -side top -anchor w -fill x -padx 5 -ipadx 5 -ipady 5 \
	    -in $w_.wmodfButtonFrame2
	pack \
	    [label $w_.wmodfCWLLabel -text "CWL \[nm\]" -anchor w -background $wmodf_bg_ ] \
	    [spinbox $w_.wmodfCWLSpinBox -from 350 -to 1050 -increment 1 -background white \
		 -width 6 -justify right -command [code $this slits_WMODF]] \
	    -side left -in $w_.wmodfCWLFrame -expand 1 -fill x
		pack \
	    [button $w_.wmodfCWLUndoButton -image undoarrow \
		 -command [code $this procs_for_undobutton]] \
	    -side right -in $w_.wmodfCWLFrame -expand 1 -fill x -padx 10
	bind $w_.wmodfCWLSpinBox <Return> [code $this slits_WMODF]
	
	pack [label $w_.wmodf2ndOrderLabel -text "2nd order overlap: " -background $wmodf_bg_] \
	    -in $w_.wmodfButtonFrame1 -anchor w -ipady 5

	pack [label $w_.wmodfIFU2OverlapLabel -text "" -background $wmodf_bg_] \
	    -in $w_.wmodfButtonFrame2 -anchor w -ipady 5

	# pack the optional wavelength and redshift labels / frames next:
	pack [frame $w_.wmodfEmLineFrame.sub1 -background $wmodf_bg_] \
	    -side left -anchor w -fill both \
	    -in $w_.wmodfEmLineFrame
	pack [frame $w_.wmodfEmLineFrame.sub2 -background $wmodf_bg_] \
	    -side left -anchor w -fill both -padx 5 \
	    -in $w_.wmodfEmLineFrame
	pack $w_.wmodfPlotCBO_indwave -in $w_.wmodfEmLineFrame.sub1 -anchor w
	pack [entry $w_.wmodfWavelengthEdit -width 34 -background white] \
	    -side top -anchor w -in $w_.wmodfEmLineFrame.sub1 -expand 1 -fill x	
	pack [label $w_.wmodfRedshiftLabel -text "Redshift:" -background $wmodf_bg_] \
	    -in $w_.wmodfEmLineFrame.sub2 -anchor w
	global default_redshift
	pack [entry $w_.wmodfRedshiftEdit -width 3 -background white ]\
	    -side top -anchor w -in $w_.wmodfEmLineFrame.sub2 -expand 1 -fill x 
	bind $w_.wmodfWavelengthEdit <Return> [code $this slits_WMODF]
	bind $w_.wmodfRedshiftEdit   <Return> [code $this slits_WMODF]
	
	add_short_help $w_.wmodfCWLSpinBox     {{bitmap b1} = Display the spectra for a different CWL}
	add_short_help $w_.wmodfCWLUndoButton  {{bitmap b1} = Reset the CWL to the ideal CWL for this Grating / Filter combination}
	add_short_help $w_.wmodfPlotCBO_specbox {{bitmap b1} = Plot slits and spectrum overlay}
	add_short_help $w_.wmodfPlotCBO_indwave {{bitmap b1} = Show individual wavelengths}
	add_short_help $w_.wmodfWavelengthEdit {{bitmap b1} = Blank-separated list of wavelengths}
	add_short_help $w_.wmodfRedshiftEdit   {{bitmap b1} = Optional redshift for wavelengths}
	
	# Load the image currently chosen
	update_instwavetype

	# Lastly, update the image display with the button choices and update the CWL setting
	wmodf_drawBoundaries
	global rtd_library

	# Set the gray scale
	image2 cmap file $rtd_library/colormaps/ramp.lasc
	wmodf_calcSpectrum "updatecwl"
	
	global filter_old grating_old instType_old
	
	set filter_old [$w_.wmodfButtonFrame2.filter get]
	set grating_old [$w_.wmodfButtonFrame2.grateorder get]
	set instType_old $instType

	# Set the dynamic range to something nice
	set_cuts -4 20
    }


    ###############################################################################
    # A method that sequentially executes commands for the Instrument change menu
    ###############################################################################
    public method update_instwavetype {} {

	set home $::env(GMMPS)

	# get the user option
	set type [$w_.topLeft.options get]

	# which instrument are we mapping
	if {[string match GMOS-N* $type] == 1} {
	    set instType "GMOS-N"
	} else {
	    set instType "GMOS-S"
	}

	set itk_option(-instType) $instType

	# load the corresponding default image
	set wavemapimage $home/wavemaps/${instType}.fits
	if {[file exists $wavemapimage]} {
	    if {[catch {image2 config -file $wavemapimage} msg]} {
		::cat::vmAstroCat::error_dialog $msg
		clear
		return
	    }
	} else {
	    ::cat::vmAstroCat::error_dialog "warning: $wavemapimage does not exist"
	    set file ""
	    clear
	    return
	}

	# Which gratings and filters are available
	read_grating_filter_data 
	
	# Add the grating data to the pulldown menu (after erasing it)
	$w_.wmodfButtonFrame2.grateorder clear
	for {set n 0} {$n < $wmodf_ngrate} {incr n 1} {
	    set grating_name [lindex [lindex $wmodf_buf_grate $n] 0]
	    # Not the combobox, but each entry gets the command assigned!
	    if {$grating_name != "R831_2nd" } { 
		$w_.wmodfButtonFrame2.grateorder add -label $grating_name \
		    -command [code $this procs_for_comboboxes "$instType-wmodf-grating" $grating_name]
	    }
	}

	# Add the filter data to the pulldown menu
	$w_.wmodfButtonFrame2.filter clear
	for {set n 0} {$n < $wmodf_nfilter} {incr n 1} {
	    set filter_name [lindex $wmodf_buf_filter $n]
	    # Not the combobox, but each entry gets the command assigned!
	    $w_.wmodfButtonFrame2.filter add -label $filter_name \
		-command [code $this procs_for_comboboxes "$instType-wmodf-filter" $filter_name]
	}

	# erase all previous plots
	clearslits_WMODF
	$w_.wmodfPlotCBO_spectra deselect

	# Define some global variables used everywhere
	get_global_data

    }
    

    ##########################################################################
    # A method that sequentially executes commands for the CWL undo button
    ##########################################################################
    public method procs_for_undobutton {} {
	wmodf_calcSpectrum "updatecwl"
	slits_WMODF
    }
    
    
    ###################################################################
    # Set the image cuts so that the overlays can be discerned better
    ###################################################################
    public method set_cuts {low high} {
	busy {image2 cut $low $high}
    }

    ##########################################################################
    # A method that sequentially executes commands for the ComboBoxes
    ##########################################################################
    public method procs_for_comboboxes {config name} {
	wmodf_calcSpectrum "updatecwl"
	slits_WMODF
    }
    

    #############################################################
    #  Name: wmodf_init
    #
    #  Description: Reads the grating and filter combinations for
    #  the WMODF dialog
    #############################################################
    #############################################################
    protected method read_grating_filter_data {} {

	set home $::env(GMMPS)	
	set instType $itk_option(-instType)
	set filter_file    $home/config/${instType}_filters.lut
	set grate_file     $home/config/${instType}_gratings.lut
	set grateList_file $home/config/${instType}_gratingeq.dat
	set filter    [open $filter_file r]
	set grate     [open $grate_file r]
	set grateList [open $grateList_file r]

	set wmodf_buf_filter ""
	set wmodf_buf_grate ""
	set wmodf_buf_grequest ""
	set wmodf_buf_gtilt ""

	#  Read in the config files.
	while {[gets $filter line] >= 0} {
	    if {[string match *#* $line] == 0} { lappend wmodf_buf_filter $line}
	}
	::close $filter
	
	# Do not inlcude the R600, have no data about it
	while {[gets $grate line] >= 0} {
	    if {[string match *#* $line] == 0 && [string match R600* $line] == 0} { lappend wmodf_buf_grate $line}
	}
	::close $grate

	# Get the gRequest/gTilt table read in. Put in wmodf_buf_grequest & wmodf_buf_gtilt
	set cnt 0
	while {[gets $grateList line] >= 0} {
	    if {[string match *#* $line] == 0} { 

		#  Break up the line into parts: gRequest gTilt
		incr cnt 1
		set wmodf_buf_grequest [lappend wmodf_buf_grequest [lindex $line 0] ]
		set tmpbuf [lindex $line 0]
		set wmodf_buf_gtilt [lappend wmodf_buf_gtilt [lindex $line 1] ]
	    }
	}
	::close $grateList

	#  Set pull down list values
	set wmodf_nfilter [llength $wmodf_buf_filter]
	set wmodf_ngrate  [llength $wmodf_buf_grate]
 	set wmodf_ngtilt  [llength $wmodf_buf_gtilt]
    }


    #########################################################################
    #  Name: wmodf_wave_config
    #
    #  Description:
    #	Sends wavelength information to the gmmps configuration file.
    #########################################################################
    #########################################################################    
    protected method wmodf_wave_config {key value} {
	cat::vmAstroCat::gmmps_config_ [concat $key] [concat $value]
    }


    #########################################################################
    #  Name: wmodf_calcSpectrum
    #
    #  Description:
    #  Calculates the spectrum length; this is the same as in gmmps_spoc.
    #########################################################################
    #########################################################################
    public method wmodf_calcSpectrum { {update_cwl ""}} {

	# WARNING! This calculates the IDEAL CWL, i.e. the mid point between the
	# spectral cut-on and cut-off, and displays it in the line edit field
	# $w_.cwlButtonFrame.edit . The user may override this value by manually 
	# entering a new value. 
	# For clarity, here I store the CWL in the variable 'cwl_ideal'
	
	set home $::env(GMMPS)
	set subdir "/config/transmissiondata/"

	set instType $itk_option(-instType)

	#  Get information selected from the pop-up
	set Filter [$w_.wmodfButtonFrame2.filter get]
	set Grating [$w_.wmodfButtonFrame2.grateorder get]
	
	set FilterTitle $Filter
	
	# Determine filter name; using globals nfilter and buf_filter, etc;
	# note to self: hate globals
	for {set n 0} {$n < $wmodf_nfilter} {incr n 1} {
	    if {$Filter == "[lindex [lindex $wmodf_buf_filter $n] 0]"} {
		set filterfile $home$subdir${instType}_${Filter}.txt
	    }
	}
	# Determine grating name and number of rulings (gnm)
	for {set n 0} {$n < $wmodf_ngrate} {incr n 1} {
	    if {$Grating == "[lindex [lindex $wmodf_buf_grate $n] 0]"} {
		set gnm [lindex [lindex $wmodf_buf_grate $n] 1]
		set gratingfile $home$subdir${instType}_grating_${Grating}.txt
	    }
	}

	# Detector name
	set detectorfile $home$subdir${instType}_QE.txt
	# Atmospheric throughput
	set atmospherefile $home${subdir}atmosphere.txt

 	# When filters and order sorting filter are combined, then
	# extract the corresponding two transmission files like this:
	if {[string match *_and_* $Filter] == 1} {
	    set filt1 [lindex [string map {"_and_" " "} $Filter] 0]
	    set filt2 [lindex [string map {"_and_" " "} $Filter] 1]
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

	set title ${instType}_${Grating}+${FilterTitle}

	if {[catch { 
	    set output [exec calc_throughput \
			    $filterfile $gratingfile $detectorfile \
			    $atmospherefile $orderfilterfile $title $cutoff "OT"]
	} msg]} {
	    ::cat::vmAstroCat::error_dialog "ERROR calculating system throughput : $msg"
	    return
	}

	# The automatically estimated throughput boundaries, and their mid-point;
	# The latter is the best-guess CWL
	set lambda_min [lindex $output 0]
	set lambda_max [lindex $output 1]
	set cwl_ideal [expr {round([lindex $output 2])}]

	if {$update_cwl != ""} {
	    $w_.wmodfCWLSpinBox set $cwl_ideal
	}

	# Update the throughput plot
	::cat::vmAstroCat::loadThroughputPlot $lambda_min $lambda_max $title
		
	# gRequest is the CWL times the number of rulings per nm;
	# How and why this relates to the Gtilt? I have no idea...

	# NOTE: here we must use the value from the line edit, as the user might want to
	# override the automatic value
	set wmodf_gRequest [ expr $cwl_ideal * $gnm / pow(10,6)]   
	
	#  Determine gRequest, gTilt, Anamorphic factor, linear disperson.
	# e.g., this calculates wmodf_gTilt used below
	wmodf_calcGTilt  $wmodf_gRequest 

	set rad [expr 3.14159/180.]
	
	# Determine the spectral resolution (nm/pixel)
	set dpix 0.0

	if {($instType == "GMOS-N" || $instType == "GMOS-S")} {
	    set anaMorphic \
		[expr sin(($wmodf_gTilt + 50.0) * $rad) / sin($wmodf_gTilt * $rad)]
	    # dpix: I don't understand ALL of it, e.g. the 81.0 and the 3600.
	    # In any case, it delivers reasonable nm/pixel values as tabulated on our web pages.
	    # It is also the same as in the IRAF gscut.cl task, so be it     -mischa
	    set dpix \
		[expr $anaMorphic * $PIXSCALE * $cwl_ideal * 81.0 * sin($wmodf_gTilt * $rad) / \
		     (3600.0 / $rad * $wmodf_gRequest) ]
	}
	
	if {$dpix == 0.0} {
	    ::cat::vmAstroCat::error_dialog "ERROR: Could not determine spectral resolution!"
	    return -1
	}

	# Do we have second order overlap with this configuration?
	set spect_2ndorder_begin [expr {round(2.*$lambda_min)}]
	if {$spect_2ndorder_begin < $lambda_max} {
	    $w_.wmodf2ndOrderLabel configure -text "2nd order overlap: >$spect_2ndorder_begin nm" \
		-foreground #f55
	} else {
	    $w_.wmodf2ndOrderLabel configure -text "2nd order overlap: No" \
		-foreground black
	}
	
	global spect_lmin_old spect_lmax_old spect_disp_old filter_old grating_old instType_old 
	set spect_lmin_old $lambda_min
	set spect_lmax_old $lambda_max
	set spect_disp_old $dpix
	set filter_old $Filter
	set grating_old $Grating
	set instType_old $instType
	
	return [list $lambda_min $lambda_max $dpix $cwl_ideal]
    }
    

    #############################################################
    #  Name: wmodf_calcGTilt
    #
    #  Description:
    #    Calculate Gtilt from the GRequest. same as in gmmps_spoc
    #############################################################
    #############################################################
    protected method wmodf_calcGTilt { wmodf_gRequest } {

	set max [lindex $wmodf_buf_grequest 0]
	set cntr 0
	
	for {set n 1} {$n < $wmodf_ngtilt } {incr n 1} {
	    set min [lindex $wmodf_buf_grequest $n]
	    if { $wmodf_gRequest < $min } {
		set max $min
	    } else {
		break
	    }
	}
	
	#  Do a linear interpolation of the gTilt, given the cntr.
	if { $min == $max } {
	    set wmodf_gTilt [ lindex $wmodf_buf_gtilt $n ]
	} else {
	    set gtiltMax [ lindex $wmodf_buf_gtilt $n ]
	    set gtiltMin [ lindex $wmodf_buf_gtilt [expr $n-1] ]
	    set slope [ expr ( $gtiltMin - $gtiltMax ) / ( $min - $max ) ] ;
	    set xo [ expr ( $gtiltMax - ( $slope * $max ) ) ]
	    set wmodf_gTilt [ expr ( $slope * $wmodf_gRequest ) + $xo ]
	}
    }
    


    ####################################################################################################
    #  Name: wmodf_drawBoundaries
    #
    #  Description:
    #   This is a simplified version of drawBoundaries
    ####################################################################################################
    ####################################################################################################
    public method wmodf_drawBoundaries {} {
	
	global ::cbo_wmodf_detgaps

	set gapcol cyan
	
	set target_canvas_ .skycat1.image.imagef.canvas
	set target_image_ image2
	set home $::env(GMMPS)
	set instType $itk_option(-instType)

	# Declare a couple of lists that contain the vertices for the 
	# corners of fov, gaps, and detector dimensions; already known!
	set dim_x  $DIMX
	set dim_y  $DIMY
	set gap1_x $GAP1X
	set gap1_y $GAP1Y
	set gap2_x $GAP2X
	set gap2_y $GAP2Y

	# Convert the coordinates so that we can plot them
	set xtmp 0
	set ytmp 0

	set xtext [ expr [lindex $dim_x 0] + 50]
	set ytext [ expr [lindex $dim_y 0] + 50]
	$target_image_ convert coords $xtext $ytext image xtext ytext canvas

	for {set i 0} {$i < $N_DIM} {incr i 1} {
	    $target_image_ convert coords [lindex $dim_x $i] [lindex $dim_y $i] image xtmp ytmp canvas
	    set dim_x [lreplace $dim_x $i $i $xtmp]
	    set dim_y [lreplace $dim_y $i $i $ytmp]
	}

	if {$N_GAP1 == 4} {
	    for {set i 0} {$i < $N_GAP1} {incr i 1} {
		$target_image_ convert coords [lindex $gap1_x $i] [lindex $gap1_y $i] image xtmp ytmp canvas
		set gap1_x [lreplace $gap1_x $i $i $xtmp]
		set gap1_y [lreplace $gap1_y $i $i $ytmp]
	    }
	}

	if {$N_GAP2 == 4} {
	    for {set i 0} {$i < $N_GAP2} {incr i 1} {
		$target_image_ convert coords [lindex $gap2_x $i] [lindex $gap2_y $i] image xtmp ytmp canvas
		set gap2_x [lreplace $gap2_x $i $i $xtmp]
		set gap2_y [lreplace $gap2_y $i $i $ytmp]
	    }
	}

	# Plot the stuff
	set n_gap1_mod [expr $N_GAP1 - 1]
	set n_gap2_mod [expr $N_GAP2 - 1]

	# Toggle the 1st gap (if any)
	if {$N_GAP1 == 4} {
	    $target_canvas_ create rect \
		    [lindex $gap1_x 0] [lindex $gap1_y 1] \
		[lindex $gap1_x 2] [lindex $gap1_y 3] \
		-outline $gapcol -fill $gapcol -stipple gray12 -width 1
	}
	# Toggle the 2nd gap (if any)
	if {$N_GAP2 == 4} {
	    $target_canvas_ create rect \
		[lindex $gap2_x 0] [lindex $gap2_y 1] \
		[lindex $gap2_x 2] [lindex $gap2_y 3] \
		-outline $gapcol -fill $gapcol -stipple gray12 -width 1
	}
    }


    #############################################################
    # Name: plot_curve
    # Plots an approximate curve spliced together by individual 
    # line segments
    #############################################################
    public method plot_curve {x coeff1 coeff2 tags \
				  tags_wmodf_showwavegrid color width} {

	set target_canvas_ .skycat1.image.imagef.canvas
	set target_image_ image2
	set ymin 50
	set ymax [expr $DETDIMY - 50]
	set step 10
	
	set y $ymin
	while {$y < $ymax} {
	    set y1 $y
	    set y2 [expr $y + $step]
	    set zerooffset [expr $coeff1*$DETDIMY / 2. + $coeff2*pow($DETDIMY / 2., 2)]
	    set offset1 [expr $coeff1*$y1 + $coeff2*pow($y1,2) - $zerooffset]
	    set offset2 [expr $coeff1*$y2 + $coeff2*pow($y2,2) - $zerooffset]
	    # Plot the markers
	    set x1 [expr $x + $offset1]
	    set x2 [expr $x + $offset2]
	    $target_image_ convert coords $x1 $y1 image x1_cv y1_cv canvas
	    $target_image_ convert coords $x2 $y2 image x2_cv y2_cv canvas
	    $target_canvas_ create line $x1_cv $y1_cv $x2_cv $y2_cv \
		-fill $color -width $width -tags "$tags $tags_wmodf_showwavegrid"
	    incr y $step
	}
    }
    

    #############################################################
    #  Name: wmodf_slit_plot_spectralbox
    #
    #  Description:
    #  Draws the spectrum and a (shaded) box in the ODF window 
    #  for a single slit. This module handles both dispersion
    #  directions with a more general approach
    #############################################################
    #############################################################
    protected method wmodf_slit_plot_spectralbox {cwl_outside_spectrum slit_outside_spectrum \
						      spec_xmin spec_xmax spec_ymin spec_ymax \
						      dimx dimy xccd yccd tags tags_wmodf_specbox \
						      tags_wmodf_2ndorder tags_wmodf_showwavegrid \
						      tags_wmodf_indwave spect_2ndorder_begin_pixel \
						      check_2ndorder_overlap \
						      spect_cwl spect_disp detgaps grating slitnr} {

	global ::cbo_wmodf_2ndorder ::cbo_wmodf_showwavegrid
	global ::cbo_wmodf_slitpos ::cbo_wmodf_indwave

	set target_canvas_ .skycat1.image.imagef.canvas
	set target_image_ image2
	set instType $itk_option(-instType)

	# A model for the spatial distortion, i.e. the curved arcs
	# I fit a 2nd order polynomial to describe the arc curvature, neglecting the constant term, yielding coefficients
	# coeff1 and coeff2. At a given CWL the arc curvature is pretty constant as a function of wavelength.
	# I then modelled coeff1 and coeff2 as a function of the number of grooves in the grating and the central wavelength.
	# A linear plane fit takes care of most of it and is good enough for our purposes and within the repeatability of GMOS.
	# The dependence on the pixel scale is because the fitting of the arc curvature was based on a
	# spectral WCS type coordinate system.
	set pS [expr ${PIXSCALE} / 3600.]
	set R [grating_to_R $grating]
	if {$instType == "GMOS-N"} {
	    set coeff1 [expr (-7.63138e-3 + 3.67893e-5 * $R + 7.02844e-6 * $spect_cwl)]
	    set coeff2 [expr ( 0.170532   - 3.26538e-4 * $R - 2.81314e-4 * $spect_cwl) * $pS]
	}
	if {$instType == "GMOS-S"} {
	    set coeff1 [expr (-1.26839e-2 + 2.72459e-5 * $R + 2.71206e-5 * $spect_cwl)]
	    set coeff2 [expr ( 0.161034   - 3.30173e-4 * $R - 3.17152e-4 * $spect_cwl) * $pS]
	}

	# Transform some variables from the image system to the canvas system;
	# In principle, one could do everything in canvas system, but some conditions must
	# be evaluated in the image/wavelength system, hence we need both. 
	# For clarity, I'm paranoid about it. Variables in canvas coordinates have a _cv 
	# appended. Unfortunately, the rest of GMMPS does not make this distinction very clearly,
	# which can cause quite some headaches when it comes to fixing plotting issues.

	$target_image_ convert coords $spec_xmin $spec_ymin image spec_xmin_cv spec_ymin_cv canvas
	$target_image_ convert coords $spec_xmax $spec_ymax image spec_xmax_cv spec_ymax_cv canvas
	
	# the vertices of the slits
	set slit_xmin [expr $xccd - $dimx]
	set slit_xmax [expr $xccd + $dimx]
	set slit_ymin [expr $yccd - $dimy]
	set slit_ymax [expr $yccd + $dimy]

	# Pi/180
	set rad 0.01745329252

	# dummy variable for coordinate conversions
	set tmp 0

	# Colors and stippling
	set stipple gray12
	set fill #999

	if {$DISPDIR == "horizontal"} {
	    set spec_min $spec_xmin
	    set spec_max $spec_xmax
	    set ccd $xccd
	    # For the slits
	    set slit_min $slit_ymin
	    set slit_max $slit_ymax
	} else {
	    set spec_min $spec_ymin
	    set spec_max $spec_ymax
	    set ccd $yccd
	    # For the slits
	    set slit_min $slit_xmin
	    set slit_max $slit_xmax
	}
	
	# Draw the outline of the spectral box
	spectralbox_plot_outline $spec_xmin $spec_xmax $spec_ymin $spec_ymax \
	    $tags $tags_wmodf_specbox

	# Show 2nd order if requested (hashed area)
	if {$cbo_wmodf_2ndorder == 1 && $check_2ndorder_overlap == "TRUE"} {
	    spectralbox_plot_2ndorder $spec_xmin $spec_xmax $spec_ymin $spec_ymax \
		$spect_2ndorder_begin_pixel $tags $tags_wmodf_2ndorder
	}

	# Draw red line for CWL; use a huge number (100) to hide the numeric label
	spectralbox_plot_wavelength $spect_cwl $spect_cwl \
	    $spec_xmin $spec_xmax $spec_ymin $spec_ymax 0 $coeff1 $coeff2 \
	    $tags $tags_wmodf_specbox red "" "" 100 \
	    $grating $slitnr $ccd

	# Show the CWL label
	set offset_curvature [expr $coeff1*$DETDIMY/2 + $coeff2*pow($DETDIMY / 2., 2)]
	$target_image_ convert coords $offset_curvature $tmp image offset_curvature_cv tmp canvas
	set offset_cv [expr 5+$offset_curvature_cv]
	set type [$w_.topLeft.options get]
	set ifu2_slitnr ""
	if {$type == "GMOS-N IFU-2" || $type == "GMOS-S IFU-2"} {
	    set ifu2_slitnr $slitnr
	}
	set waveccd [lambda_to_spatial $spect_cwl $spect_cwl $grating 1 $DETDIMX $ifu2_slitnr]
	$target_image_ convert coords $waveccd 100 image waveccd_cv ypos_cv canvas
	$target_canvas_ create text [expr $waveccd_cv+$offset_cv] $ypos_cv \
	    -anchor w -font {Arial 12} -text "CWL" -tags "$tags $tags_wmodf_showwavegrid" -fill red

	# Draw the slit rectangle
	if {$cbo_wmodf_slitpos == 1} {
	    $target_image_ convert coords $slit_xmin $slit_ymin image slit_xmin_cv slit_ymin_cv canvas
	    $target_image_ convert coords $slit_xmax $slit_ymax image slit_xmax_cv slit_ymax_cv canvas
	    $target_canvas_ create rect $slit_xmin_cv $slit_ymax_cv $slit_xmax_cv $slit_ymin_cv \
		-outline green -width 1 -tags "$tags $tags_wmodf_specbox"
	}

	# Now for the wavelength overlays
	set tmp 0
	set increment_marker 0
	set increment_label 0
	# do not print wavelength labels closer than 30 pixels to the CWL marks
	set minsep [expr 30*$spect_disp]
	
	# Show wavelength grid, depending on dispersion factor
	if {$cbo_wmodf_showwavegrid == 1} {
	    if {$spect_disp > 0.1} {
		set increment_marker 50
		set increment_label 100
	    } else {
		set increment_marker 25
		set increment_label 50
	    }

	    set plotwavelength 300
	    while {$plotwavelength<1200} {
		set label1 $plotwavelength
		set label2 ""

		set yfrac 0.50
		if {$type == "GMOS-N IFU-2" || $type == "GMOS-S IFU-2"} {
		    if {$slitnr == 0} {
			set yfrac 0.51
		    } else {
			set yfrac 0.49
		    }
		}

		spectralbox_plot_wavelength $plotwavelength $spect_cwl \
		    $spec_xmin $spec_xmax $spec_ymin $spec_ymax $minsep $coeff1 $coeff2 \
		    $tags $tags_wmodf_showwavegrid yellow $label1 $label2 $yfrac \
		    $grating $slitnr $ccd
		incr plotwavelength $increment_label
	    }

	    # Show gap wavelengths
	    spectralbox_plot_gaps 6 $coeff1 $coeff2 $detgaps $spect_cwl \
		$spec_xmin $spec_max $tags $tags_wmodf_showwavegrid $grating $slitnr
	}

	
	# Show user-defined wavelengths
	if {$cbo_wmodf_indwave == 1} {
	    spectralbox_plot_indwave $spect_cwl \
		$spec_xmin $spec_xmax $spec_ymin $spec_ymax \
		$minsep $coeff1 $coeff2 $tags $tags_wmodf_indwave $grating $slitnr $ccd
	}

	# Draw a red hashmark in case the two spectral banks of the IFU-2 overlap
	hashmark_ifu2_slitoverlap $tags $tags_wmodf_specbox
    }



    #############################################################
    #  Name: replace_X_lambda
    #
    #  Description:
    #  Replaces an atomic identifier with typical wavelengths
    #############################################################
    #############################################################
    public method replace_X_lambda {wavestring} {
	set blank " "
	# We need a blank at the end to distinguish between H and He in the string functions
	set wavestring $wavestring$blank
	set labelstring $wavestring

	# Replace atomic identifiers with wavelengths
	if {[string first "He " $wavestring] != -1} {
	    set wavestring [string map {"He " "164.0 320.4 389.0 468.7 541.3 587.7 668.0 1083 2058 "} $wavestring]
	    set labelstring [string map {"He " "HeII HeII HeI HeII HeII HeI HeI HeI HeI "} $labelstring]
	}

	if {[string first "H " $wavestring] != -1} {
	    set wavestring [string map {"H " "121.6 410.3 434.3 486.4 656.5 1875 1282 1094 2166 2122 2248 "} $wavestring]
	    set labelstring [string map {"H " "Lya Hd Hg Hb Ha Paa Pab Pag Brg H2_1-0 H2_2-1 "} $labelstring]
	}

	if {[string first "O " $wavestring] != -1} {
	    set wavestring [string map {"O " "103.2 103.8 372.7 436.3 496.0 500.8 630.2 636.6 732.1 "} $wavestring]
	    set labelstring [string map {"O " "OVI OVI \[OII\] \[OIII\] \[OIII\] \[OIII\] \[OI\] \[OI\] \[OII\] "} $labelstring]
	}

	if {[string first "N " $wavestring] != -1} {
	    set wavestring [string map {"N " "655.0 658.6 "} $wavestring]
	    set labelstring [string map {"N " "\[NII\] \[NII\] "} $labelstring]
	}

	if {[string first "C " $wavestring] != -1} {
	    set wavestring [string map {"C " "97.7 154.9 232.6 "} $wavestring]
	    set labelstring [string map {"C " "CIII CIV CII\] "} $labelstring]
	}

	if {[string first "Ar " $wavestring] != -1} {
	    set wavestring [string map {"Ar " "713.8 "} $wavestring]
	    set labelstring [string map {"Ar " "\[ArIII\] "} $labelstring]
	}

	if {[string first "S " $wavestring] != -1} {
	    set wavestring [string map {"S " "406.9 407.6 520.3 671.8 673.3 907.1 953.3 "} $wavestring]
	    set labelstring [string map {"S " "\[SII\] \[SII\] SII \[SII\] \[SII\] \[SIII\] \[SIII\] "} $labelstring]
	}
	
	if {[string first "Na " $wavestring] != -1} {
	    set wavestring [string map {"Na " "589.0 589.6 "} $wavestring]
	    set labelstring [string map {"Na " "NaD2 NaD1 "} $labelstring]
	}
	
	if {[string first "Ne " $wavestring] != -1} {
	    set wavestring [string map {"Ne " "242.4 334.7 342.7 386.9 396.8 "} $wavestring]
	    set labelstring [string map {"Ne " "\[NeIV\] \[NeV\] \[NeV\] \[NeIII\] \[NeIII\] "} $labelstring]
	}
	
	if {[string first "Ca " $wavestring] != -1} {
	    set wavestring [string map {"Ca " "393.4 396.9 849.9 854.2 866.2 "} $wavestring]
	    set labelstring [string map {"Ca " "CaH CaK CaT1 CaT2 CaT3 "} $labelstring]
	}

	if {[string first "Mg " $wavestring] != -1} {
	    set wavestring [string map {"Mg " "279.9 516.7 517.3 518.4 "} $wavestring]
	    set labelstring [string map {"Mg " "\[MgII\] Mgb Mgb Mgb "} $labelstring]
	}

	# Trim leading and trailing blanks
	set wavestring [string trim $wavestring]
	set labelstring [string trim $labelstring]

	# split the strings into lists
	set wavelist [split $wavestring " "]
	set labellist [split $labelstring " "]

	# replace numeric values in the labelstring with blanks
	set nlabel [llength $labelstring]
	set n 0
	while {$n < $nlabel} {
	    set element [lindex $labelstring $n]
	    if {[isnumeric $element] == 1} {
		set labellist [lreplace $labellist $n $n " "]
	    }
	    incr n 1
	}
	return [list $wavelist $labellist]
    }

    #############################################################
    # Check if a value is numeric
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
    #  Name: grating_to_R
    #
    #  Description:
    #  Returns the number of rulings for a grating
    #############################################################
    #############################################################
    protected method grating_to_R {grating} {

	if {$grating == "B1200"} {
	    set R 1200.
	} elseif {$grating == "R831"} {
	    set R 831.
	} elseif {$grating == "R831_2nd"} {
	    set R 1662.
	} elseif {$grating == "B600" || $grating == "R600"} {
	    set R 600.
	} elseif {$grating == "R400"} {
	    set R 400.
	} elseif {$grating == "R150"} {
	    set R 150.
	} elseif {$grating == "B480"} {
	    set R 480.
	} else {
	    ::cat::vmAstroCat::error_dialog "grating_to_R: Grating $grating not known!"
	    return -1
	}
	return $R
    }


    #############################################################
    #  Name: wavemapper_model
    #
    #  Description:
    #  Returns the nonlinear coefficients of the wavelength model
    #############################################################
    #############################################################
    protected method wavemapper_model {CWL grating {ifu2_slitnr ""}} {

	set instType $itk_option(-instType)
	set R [grating_to_R $grating]

	set type [$w_.topLeft.options get]

	# I obtained 3rd order polynomial wavelength solutions for a series of arcs and gratings,
	# stepping from 4000A to 9000A in 500A steps. The mapping between spatial and spectral
	# coordinates is
	# lambda = p0 + p1*x + p2*x^2 + p3*x^3
	# where x is the pixel position in a 2x2 binned GMOS image, and the p0-p3 are the coefficients.
	# The coefficients depend on the number of rulings, R, for the gratings, and the chosen CWL.
	# I could fit a common smooth 2D polynomial surface to p0 and p1 as a function of inverse R and CWL.
	# p2 and p3 form a smooth surface as well, however, I could not find a suitable common analytic
	# description, mostly because the R150 throws them off. Hence these are simple quadratic 
	# fits, individual per grating.

	# NOTE: wavelengths (CWL) in Angstrom

	# p0: note the pow(x,5) term, and absence of pow(x,4)
	# p1: no CWL dependence
	if {$type == "GMOS-S Longslit"} {
	    if {$grating == "R150"} {
		set p0 [expr +5.655718e+03 +1.155098e+00 * $CWL -1.150032e-05 * $CWL*$CWL ]
		set p1 [expr -3.811895e+00 -6.180017e-05 * $CWL +5.689806e-09 * $CWL*$CWL ]
		set p2 [expr -2.054652e-05 +2.213525e-08 * $CWL -2.511702e-12 * $CWL*$CWL ]
		set p3 [expr +2.098619e-08 -5.027971e-12 * $CWL +4.555610e-16 * $CWL*$CWL ]
	    } elseif {$grating == "R400"} {		    		          
		set p0 [expr +2.194582e+03 +1.040510e+00 * $CWL -2.120559e-06 * $CWL*$CWL ]
		set p1 [expr -1.454243e+00 -1.888055e-05 * $CWL +1.071748e-09 * $CWL*$CWL ]
		set p2 [expr -1.492328e-06 +5.014962e-09 * $CWL -5.119544e-13 * $CWL*$CWL ]
		set p3 [expr +7.427494e-09 -1.990126e-12 * $CWL +1.529461e-16 * $CWL*$CWL ]
	    } elseif {$grating == "B600"} {		    		          
		set p0 [expr +1.496648e+03 +1.024727e+00 * $CWL -1.168811e-06 * $CWL*$CWL ]
		set p1 [expr -9.821197e-01 -1.198473e-05 * $CWL +6.503497e-10 * $CWL*$CWL ]
		set p2 [expr +1.073015e-05 -8.781973e-10 * $CWL -3.610247e-14 * $CWL*$CWL ]
		set p3 [expr +1.609782e-09 -2.757901e-13 * $CWL +2.240864e-17 * $CWL*$CWL ]
	    } elseif {$grating == "R831"} {		    		          
		set p0 [expr +1.093144e+03 +1.020897e+00 * $CWL -1.333520e-06 * $CWL*$CWL ]
		set p1 [expr -7.125011e-01 -1.079183e-05 * $CWL +7.600093e-10 * $CWL*$CWL ]
		set p2 [expr +1.247921e-05 -2.555653e-09 * $CWL +1.034847e-13 * $CWL*$CWL ]
		set p3 [expr -6.963898e-11 +2.135580e-13 * $CWL -1.632539e-17 * $CWL*$CWL ]
	    } elseif {$grating == "B1200"} {		    		          
		set p0 [expr +8.113080e+02 +9.991071e-01 * $CWL -1.595486e-07 * $CWL*$CWL ]
		set p1 [expr -4.746415e-01 -1.739428e-05 * $CWL +1.671325e-09 * $CWL*$CWL ]
		set p2 [expr +6.571810e-07 +2.335510e-10 * $CWL -9.952524e-14 * $CWL*$CWL ]
		set p3 [expr +1.424845e-09 -2.710707e-13 * $CWL +1.767501e-17 * $CWL*$CWL ]
	    } elseif {$grating == "B480"} {		    		          
		set p0 0.
		set p1 0.
		set p2 0.
		set p3 0.
	    }
	}

	if {$type == "GMOS-S IFU-R"} {
	    if {$grating == "R150"} {
		set p0 [expr +6.057958e+03 +1.037702e+00 * $CWL -2.105472e-06 * $CWL*$CWL ]
		set p1 [expr -3.872073e+00 -4.756072e-05 * $CWL +3.688168e-09 * $CWL*$CWL ]
		set p2 [expr +2.357209e-05 +8.672987e-09 * $CWL -1.206323e-12 * $CWL*$CWL ]
		set p3 [expr -1.898276e-09 +4.520139e-13 * $CWL +6.341491e-17 * $CWL*$CWL ]
	    }
	    if {$grating == "R400"} {
		set p0 [expr +2.306933e+03 +1.010428e+00 * $CWL +1.169994e-07 * $CWL*$CWL ]
		set p1 [expr -1.492488e+00 -9.018030e-06 * $CWL +2.772727e-10 * $CWL*$CWL ]
		set p2 [expr +1.383041e-05 -7.109480e-10 * $CWL -2.177409e-14 * $CWL*$CWL ]
		set p3 [expr +1.942608e-09 -2.515047e-13 * $CWL +1.696197e-17 * $CWL*$CWL ]
	    }
	    if {$grating == "B600"} {
		set p0 [expr +1.483557e+03 +1.035310e+00 * $CWL -2.268159e-06 * $CWL*$CWL ]
		set p1 [expr -9.981875e-01 -8.484970e-06 * $CWL +4.127739e-10 * $CWL*$CWL ]
		set p2 [expr +1.399107e-05 -2.365092e-09 * $CWL +1.006807e-13 * $CWL*$CWL ]
		set p3 [expr -4.785091e-10 +3.861944e-13 * $CWL -2.968327e-17 * $CWL*$CWL ]
	    }
	    if {$grating == "R831"} {
		set p0 [expr +1.112215e+03 +1.017262e+00 * $CWL -1.194172e-06 * $CWL*$CWL ]
		set p1 [expr -7.127886e-01 -1.181362e-05 * $CWL +8.917063e-10 * $CWL*$CWL ]
		set p2 [expr +2.001722e-06 +4.605994e-10 * $CWL -1.105440e-13 * $CWL*$CWL ]
		set p3 [expr +3.014250e-09 -7.078554e-13 * $CWL +4.889146e-17 * $CWL*$CWL ]
	    }
	    if {$grating == "B1200"} {
		set p0 [expr +1.243094e+03 +8.387563e-01 * $CWL +1.415161e-05 * $CWL*$CWL ]
		set p1 [expr -4.768037e-01 -1.752517e-05 * $CWL +1.761947e-09 * $CWL*$CWL ]
		set p2 [expr -2.493240e-06 +1.101568e-09 * $CWL -1.606944e-13 * $CWL*$CWL ]
		set p3 [expr +3.091190e-09 -7.610527e-13 * $CWL +5.176919e-17 * $CWL*$CWL ]
	    } elseif {$grating == "B480"} {		    		          
		set p0 0.
		set p1 0.
		set p2 0.
		set p3 0.
	    }
	}
	
	# The IFU-2 covers a relatively small wavelength range and can be well fitted with 
	# common 2nd order polynomials (i.e. p3 = 0)
	if {$type == "GMOS-S IFU-2"} {
	    # Left slit
	    if {$ifu2_slitnr == 0} {
		if {$grating == "R150"} {
		    set p0 [expr +1.295763e+03 +1.424831e+00 * $CWL -2.694420e-05 * $CWL*$CWL ]
		    set p1 [expr -3.269925e+00 -1.771714e-04 * $CWL +1.025318e-08 * $CWL*$CWL ]
		    set p2 [expr -4.393182e-04 +1.200782e-07 * $CWL -7.357464e-12 * $CWL*$CWL ]
		    set p3 0.
		} elseif {$grating == "R400"} {
		    set p0 [expr +9.424335e+02 +1.050682e+00 * $CWL -1.597363e-06 * $CWL*$CWL ]
		    set p1 [expr -1.484936e+00 -9.605755e-06 * $CWL +2.801125e-10 * $CWL*$CWL ]
		    set p2 [expr +2.435962e-05 -2.322717e-09 * $CWL +7.185940e-14 * $CWL*$CWL ]
		    set p3 0.
		} elseif {$grating == "B600"} {
		    set p0 [expr +7.171127e+02 +1.020263e+00 * $CWL +4.999612e-07 * $CWL*$CWL ]
		    set p1 [expr -9.804777e-01 -1.303941e-05 * $CWL +7.034823e-10 * $CWL*$CWL ]
		    set p2 [expr +8.765488e-06 +3.370276e-10 * $CWL -1.179390e-13 * $CWL*$CWL ]
		    set p3 0.
		} elseif {$grating == "R831"} {
		    set p0 [expr +4.615590e+02 +1.040951e+00 * $CWL -1.182174e-06 * $CWL*$CWL ]
		    set p1 [expr -7.048087e-01 -1.292913e-05 * $CWL +8.602584e-10 * $CWL*$CWL ]
		    set p2 [expr +6.785455e-06 -5.325474e-10 * $CWL -2.980861e-14 * $CWL*$CWL ]
		    set p3 0.
		} elseif {$grating == "B1200"} {
		    set p0 [expr +1.570243e+02 +1.084181e+00 * $CWL -4.660096e-06 * $CWL*$CWL ]
		    set p1 [expr -4.682847e-01 -1.885458e-05 * $CWL +1.717804e-09 * $CWL*$CWL ]
		    set p2 [expr -1.068371e-05 +3.847067e-09 * $CWL -3.587057e-13 * $CWL*$CWL ]
		    set p3 0.
		} elseif {$grating == "B480"} {		    		          
			set p0 0.
			set p1 0.
			set p2 0.
			set p3 0.
	    }
	    }

	    # Right slit
	    if {$ifu2_slitnr == 1} {
		if {$grating == "R150"} {
		    set p0 [expr +8.716344e+03 +1.224279e+00 * $CWL -1.686180e-05 * $CWL*$CWL ]
		    set p1 [expr -4.350675e+00 +7.287800e-05 * $CWL -4.547995e-09 * $CWL*$CWL ]
		    set p2 [expr +1.421310e-04 -1.913569e-08 * $CWL +1.014710e-12 * $CWL*$CWL ]
		    set p3 0.
		} elseif {$grating == "R400"} {
		    set p0 [expr +3.474587e+03 +1.021872e+00 * $CWL -2.214717e-06 * $CWL*$CWL ]
		    set p1 [expr -1.518913e+00 -7.276286e-06 * $CWL +2.980340e-10 * $CWL*$CWL ]
		    set p2 [expr +3.072999e-05 -2.305014e-09 * $CWL +3.992211e-14 * $CWL*$CWL ]
		    set p3 0.
		} elseif {$grating == "B600"} {
		    set p0 [expr +2.475059e+03 +9.658196e-01 * $CWL +1.912408e-06 * $CWL*$CWL ]
		    set p1 [expr -1.064715e+00 +1.151301e-05 * $CWL -1.283022e-09 * $CWL*$CWL ]
		    set p2 [expr +2.919149e-05 -5.391555e-09 * $CWL +3.426688e-13 * $CWL*$CWL ]
		    set p3 0.
		} elseif {$grating == "R831"} {		    		          
		    set p0 [expr +1.714261e+03 +1.000729e+00 * $CWL -1.441763e-06 * $CWL*$CWL ]
		    set p1 [expr -7.693325e-01 +5.269812e-06 * $CWL -4.560850e-10 * $CWL*$CWL ]
		    set p2 [expr +2.599426e-05 -5.771576e-09 * $CWL +3.418967e-13 * $CWL*$CWL ]
		    set p3 0.
		} elseif {$grating == "B1200"} {		    		          
		    set p0 [expr +1.003335e+03 +1.055807e+00 * $CWL -6.465088e-06 * $CWL*$CWL ]
		    set p1 [expr -4.988556e-01 -1.035226e-05 * $CWL +1.070431e-09 * $CWL*$CWL ]
		    set p2 [expr +8.979963e-06 -1.585921e-09 * $CWL +3.612282e-14 * $CWL*$CWL ]
		    set p3 0.
		} elseif {$grating == "B480"} {		    		          
			set p0 0.
			set p1 0.
			set p2 0.
			set p3 0.
	    }
	    }
	}

	if {$type == "GMOS-N Longslit"} {
	    if {$grating == "R150"} {
		set p0 [expr +5.460068e+03 +1.015217e+00 * $CWL -2.081742e-07 * $CWL*$CWL ]
		set p1 [expr -3.594184e+00 -6.629349e-06 * $CWL +1.341989e-10 * $CWL*$CWL ]
		set p2 [expr +6.677164e-05 -8.941085e-09 * $CWL +4.486883e-13 * $CWL*$CWL ]
		set p3 [expr -7.245025e-09 +2.680537e-12 * $CWL -1.697887e-16 * $CWL*$CWL ]
	    } elseif {$grating == "R400"} {
		set p0 [expr +2.030666e+03 +1.021153e+00 * $CWL -5.726949e-07 * $CWL*$CWL ]
		set p1 [expr -1.337395e+00 -1.140258e-05 * $CWL +3.739519e-10 * $CWL*$CWL ]
		set p2 [expr +9.035038e-06 +4.935751e-10 * $CWL -7.560706e-14 * $CWL*$CWL ]
		set p3 [expr +3.127098e-09 -6.346868e-13 * $CWL +3.691598e-17 * $CWL*$CWL ]
	    } elseif {$grating == "B600"} {
		set p0 [expr +1.365436e+03 +1.019302e+00 * $CWL -8.308851e-07 * $CWL*$CWL ]
		set p1 [expr -8.885767e-01 -1.234977e-05 * $CWL +6.331752e-10 * $CWL*$CWL ]
		set p2 [expr +7.484338e-06 -2.170800e-10 * $CWL -4.611808e-14 * $CWL*$CWL ]
		set p3 [expr +8.419983e-10 -1.124977e-13 * $CWL +6.561831e-18 * $CWL*$CWL ]
	    } elseif {$grating == "R831"} {
		set p0 [expr +9.842260e+02 +1.019347e+00 * $CWL -1.172306e-06 * $CWL*$CWL ]
		set p1 [expr -6.376804e-01 -1.324562e-05 * $CWL +9.006607e-10 * $CWL*$CWL ]
		set p2 [expr +4.273689e-06 -1.568516e-10 * $CWL -4.639321e-14 * $CWL*$CWL ]
		set p3 [expr +8.186011e-10 -1.215586e-13 * $CWL +6.131594e-18 * $CWL*$CWL ]
	    } elseif {$grating == "B1200"} {
		set p0 [expr +6.500525e+02 +1.028833e+00 * $CWL -2.487198e-06 * $CWL*$CWL ]
		set p1 [expr -4.365627e-01 -1.470472e-05 * $CWL +1.403729e-09 * $CWL*$CWL ]
		set p2 [expr +3.236079e-06 -4.631113e-10 * $CWL -3.044672e-14 * $CWL*$CWL ]
		set p3 [expr +7.345513e-10 -1.277076e-13 * $CWL +6.924252e-18 * $CWL*$CWL ]
	    } elseif {$grating == "B480"} {		    		          
		set p0 0.
		set p1 0.
		set p2 0.
		set p3 0.
	    }
	}

	if {$type == "GMOS-N IFU-R"} {
	    if {$grating == "R150"} {
		set p0 [expr +5.628393e+03 +9.705206e-01 * $CWL +3.616317e-06 * $CWL*$CWL ]
		set p1 [expr -3.667320e+00 +5.844242e-06 * $CWL -5.836830e-10 * $CWL*$CWL ]
		set p2 [expr +1.057988e-04 -2.148618e-08 * $CWL +1.276887e-12 * $CWL*$CWL ]
		set p3 [expr -2.443128e-08 +8.039792e-12 * $CWL -5.509846e-16 * $CWL*$CWL ]
	    } elseif {$grating == "R400"} {		    		          
		set p0 [expr +2.067883e+03 +1.014361e+00 * $CWL -2.299767e-07 * $CWL*$CWL ]
		set p1 [expr -1.355762e+00 -8.943455e-06 * $CWL +2.544056e-10 * $CWL*$CWL ]
		set p2 [expr +1.653039e-05 -1.674798e-09 * $CWL +6.336200e-14 * $CWL*$CWL ]
		set p3 [expr -7.467655e-10 +3.490098e-13 * $CWL -2.461557e-17 * $CWL*$CWL ]
	    } elseif {$grating == "B600"} {		    		          
		set p0 [expr +1.389305e+03 +1.013805e+00 * $CWL -5.554779e-07 * $CWL*$CWL ]
		set p1 [expr -9.025855e-01 -9.585727e-06 * $CWL +4.701958e-10 * $CWL*$CWL ]
		set p2 [expr +5.480141e-06 -5.451921e-11 * $CWL -4.098774e-14 * $CWL*$CWL ]
		set p3 [expr +2.345383e-09 -5.003472e-13 * $CWL +3.036570e-17 * $CWL*$CWL ]
	    } elseif {$grating == "R831"} {		    		          
		set p0 [expr +9.738811e+02 +1.022566e+00 * $CWL -1.308951e-06 * $CWL*$CWL ]
		set p1 [expr -6.456328e-01 -1.189247e-05 * $CWL +8.577016e-10 * $CWL*$CWL ]
		set p2 [expr -3.589660e-07 +1.131780e-09 * $CWL -1.401817e-13 * $CWL*$CWL ]
		set p3 [expr +3.189519e-09 -8.312758e-13 * $CWL +5.702102e-17 * $CWL*$CWL ]
	    } elseif {$grating == "B1200"} {		    		          
		set p0 [expr +2.369385e+01 +1.286633e+00 * $CWL -2.904502e-05 * $CWL*$CWL ]
		set p1 [expr -3.774367e-01 -3.910647e-05 * $CWL +3.901736e-09 * $CWL*$CWL ]
		set p2 [expr -4.012357e-05 +1.636085e-08 * $CWL -1.663204e-12 * $CWL*$CWL ]
		set p3 [expr +9.897124e-09 -3.716916e-12 * $CWL +3.555667e-16 * $CWL*$CWL ]
	    } elseif {$grating == "B480"} {		    		          
		set p0 0.
		set p1 0.
		set p2 0.
		set p3 0.
	    }
	}

	# The IFU-2 covers a relatively small wavelength range and can be well fitted with common 2nd order 
	# polynomials (i.e. p3 = 0)
	# Had to cover GMOS-N with sparser archival data, which can be fit with a common surface. 
	# R150 and B1200 had 1 and 2 data points, only.
	if {$type == "GMOS-N IFU-2"} {
	    # Left slit
	    if {$ifu2_slitnr == 0} {
		if {$grating == "R150"} {
		    set p0 0.
		    set p1 0.
		    set p2 0.
		    set p3 0.
		} elseif {$grating == "R400"} {
		    set p0 [expr +9.965902e+02 +9.691216e-01 * $CWL +4.188183e-06 * $CWL*$CWL ]
		    set p1 [expr -1.321620e+00 -1.627890e-05 * $CWL +7.196424e-10 * $CWL*$CWL ]
		    set p2 [expr -1.876339e-05 +8.710156e-09 * $CWL -6.590458e-13 * $CWL*$CWL ]
		    set p3 0.
		} elseif {$grating == "B600"} {
		    set p0 [expr +4.112061e+02 +1.068663e+00 * $CWL -3.399504e-06 * $CWL*$CWL ]
		    set p1 [expr -8.707982e-01 -1.925200e-05 * $CWL +1.243123e-09 * $CWL*$CWL ]
		    set p2 [expr -1.264169e-05 +7.078991e-09 * $CWL -6.678829e-13 * $CWL*$CWL ]
		    set p3 0.
		} elseif {$grating == "R831"} {
		    set p0 [expr +4.333540e+02 +1.009765e+00 * $CWL +1.599993e-06 * $CWL*$CWL ]
		    set p1 [expr -5.963429e-01 -2.851289e-05 * $CWL +2.259427e-09 * $CWL*$CWL ]
		    set p2 [expr -2.655025e-05 +1.115436e-08 * $CWL -1.040424e-12 * $CWL*$CWL ]
		    set p3 0.
		} elseif {$grating == "B1200"} {		    		          
		    set p3 0.
		    set p0 [expr +2.245234e+02 +1.044247e+00 * $CWL -1.890037e-06 * $CWL*$CWL ]
		    set p1 [expr -4.412075e-01 -1.343027e-05 * $CWL +1.293003e-09 * $CWL*$CWL ]
		    set p2 [expr +1.145761e-05 -3.058908e-09 * $CWL +1.898305e-13 * $CWL*$CWL ]
		} elseif {$grating == "B480"} {		    		          
			set p0 0.
			set p1 0.
			set p2 0.
			set p3 0.
	    }
	    }

	    # Right slit
	    if {$ifu2_slitnr == 1} {
		if {$grating == "R150"} {
		    set p0 0.
		    set p1 0.
		    set p2 0.
		    set p3 0.
		} elseif {$grating == "R400"} {
		    set p0 [expr +3.538204e+03 +9.309951e-01 * $CWL +4.488626e-06 * $CWL*$CWL ]
		    set p1 [expr -1.404928e+00 +5.978735e-06 * $CWL -8.567674e-10 * $CWL*$CWL ]
		    set p2 [expr +2.566722e-05 -3.159719e-09 * $CWL +1.675236e-13 * $CWL*$CWL ]
		    set p3 0.
		} elseif {$grating == "B600"} {
		    set p0 [expr +2.080952e+03 +1.043602e+00 * $CWL -4.460090e-06 * $CWL*$CWL ]
		    set p1 [expr -8.921350e-01 -1.473152e-05 * $CWL +9.357414e-10 * $CWL*$CWL ]
		    set p2 [expr +9.341828e-06 +4.053242e-10 * $CWL -1.258809e-13 * $CWL*$CWL ]
		    set p3 0.
		} elseif {$grating == "R831"} {
		    set p0 [expr +1.542619e+03 +1.018444e+00 * $CWL -2.742271e-06 * $CWL*$CWL ]
		    set p1 [expr -5.630119e-01 -4.213519e-05 * $CWL +3.497916e-09 * $CWL*$CWL ]
		    set p2 [expr -1.014835e-05 +5.988838e-09 * $CWL -6.111707e-13 * $CWL*$CWL ]
		    set p3 0.
		} elseif {$grating == "B1200"} {
		    set p0 [expr +1.063929e+03 +1.019227e+00 * $CWL -4.068384e-06 * $CWL*$CWL ]
		    set p1 [expr -4.496164e-01 -1.336423e-05 * $CWL +1.468092e-09 * $CWL*$CWL ]
		    set p2 [expr +8.671850e-06 -1.231516e-09 * $CWL -1.836226e-14 * $CWL*$CWL ]
		    set p3 0.
		} elseif {$grating == "B480"} {		    		          
			set p0 0.
			set p1 0.
			set p2 0.
			set p3 0.
	    }
	    }
	}

	return [list $p0 $p1 $p2 $p3]
    }


    #############################################################
    #  Name: transform_gmos_x_old2new (2x2 binning!)
    #
    #  Description:
    #  Transforms GMOS EEV pixel coords to GMOS HAM coords
    #  Reimplementation from vmAstroCat because globvar PIXSCALE
    #  is unknown if called as ::cat::vmAstroCat::.....
    #  Only used for GMOS-N because it was calibrated based on E2VDD
    #############################################################
    #############################################################
    public method transform_gmos_x_old2new {x_old nativeScale instType} {
	if {$instType == "GMOS-S"} {
	    set offset 295.04
	} else {
	    set offset 304.18
	}
	
	set x_new [expr $offset + $x_old * 0.14576 / $nativeScale ]
	return $x_new
    }


    #############################################################
    #  Name: transform_gmos_x_new2old (2x2 binning!)
    #
    #  Description:
    #  Transforms GMOS HAM pixel coords to GMOS EEV coords
    #  Reimplementation from vmAstroCat because globvar PIXSCALE
    #  is unknown if called as ::cat::vmAstroCat::.....
    #  Only used for GMOS-N because it was calibrated based on E2VDD
    #############################################################
    #############################################################
    public method transform_gmos_x_new2old {x_new nativeScale instType} {
	if {$instType == "GMOS-S"} {
	    set offset 295.04
	} else {
	    set offset 304.18
	}
	set x_old [expr ($x_new - $offset) * $nativeScale / 0.14576 ]
	return $x_old
    }


    #############################################################
    #  Name: spatial_to_lambda
    #
    #  Description:
    #  Calculates the wavelength at a given pixel position.
    #  Based on non-linear models of GMOS-N/S (2x2 binning)
    #############################################################
    #############################################################
    protected method spatial_to_lambda {x CWL grating {ifu2_slitnr ""}} {

	set instType $itk_option(-instType)
	
	# WARNING! INPUT CWL is in nm, but the model is in Angstrom! Therefore:
	set CWL [expr $CWL*10]

	set model [wavemapper_model $CWL $grating $ifu2_slitnr]
	set p0 [lindex $model 0]
	set p1 [lindex $model 1]
	set p2 [lindex $model 2]
	set p3 [lindex $model 3]

	# WARNING: Calculations for GMOS-N were made for the old E2VDD detectors.
	# The image shown is for the new 2x2 Hamamatsu detectors, hence we must transform:
	if {$instType == "GMOS-N"} {
	    set x [expr 2. * $x]
	    set x [transform_gmos_x_new2old $x 0.1614 "GMOS-N"]
	    set x [expr $x / 2.]
	}
	    
	set lambda [expr $p0 + $p1*$x + $p2*pow($x,2) + $p3*pow($x,3)]

	# convert to nm
	set lambda [format "%.1f" [expr $lambda / 10.]]
	
	return $lambda
    }


    #############################################################
    #  Name: lambda_to_spatial
    #
    #  Description:
    #  Calculates the pixel position at which a given wavelength
    #  occurs. Based on non-linear models of GMOS-N/S
    #############################################################
    #############################################################
    protected method lambda_to_spatial {lambda CWL grating spect_xmin spect_xmax {ifu2_slitnr ""}} {

	set instType $itk_option(-instType)
	
	# WARNING! INPUT CWL and LAMBDA are in nm, but the model is in Angstrom! Therefore:
	set lambda [expr $lambda*10]
	set CWL    [expr $CWL*10]

	set model [wavemapper_model $CWL $grating $ifu2_slitnr]
	set p0 [lindex $model 0]
	set p1 [lindex $model 1]
	set p2 [lindex $model 2]
	set p3 [lindex $model 3]

	# Nonlinear inversion is only interesting if we are inside the wavelength range that is actually
	# caught by the detector / transmitted by the filter / grating combination.
	# One of the functions calling THIS function loops over 300nm-1200nm.
	# Check wavelength boundaries, and return these if significantly outside 
	# the region of interest; add a 100 angstrom safety margin
	set lmax [expr $p0 + $p1*$spect_xmin + $p2*pow($spect_xmin,2) + $p3*pow($spect_xmin,3) + 100.]
	set lmin [expr $p0 + $p1*$spect_xmax + $p2*pow($spect_xmax,2) + $p3*pow($spect_xmax,3) - 100.]
	
	# This third order polynomial is in general very well behaved over the lambda_min and lambda_max
	# range, i.e. it is close to linear and monotonic. We use Newton's method to find the 
	# pixel that corresponds to a given wavelength. The iteration terminates when the last step is 
	# less than 0.1 pixel, or if more than 15 steps were done (usually, it converges after 3-5 steps)

	set x0 [expr ($lambda - $p0)/$p1]
	set eps 1000.
	set convergence 0.1
	set iter 0
	while {$eps > $convergence && $iter <= 15} {
	    set f0 [expr $p0 + $p1*$x0 + $p2*pow($x0,2) + $p3*pow($x0,3) - $lambda]
	    set df0 [expr $p1 + 2.*$p2*$x0 + 3.*$p3*pow($x0,2)]
	    set x1 [expr $x0 - $f0 / $df0]
	    # Reset the iterators
	    set eps [expr abs($x1 - $x0)]
	    set x0 $x1
	    incr iter 1
	}
	if {$iter >= 15} {
	    set x_linear [expr ($lambda - $p0) / $p1]
	    # Warning: In case of GMOS-N, calculations were made for the old E2VDD
	    # Must transform old 2x2 binned pixels to new Hamamatsu 2x2 pixels
	    if {$instType == "GMOS-N"} {
		set x_linear [expr 2. * $x_linear]
		set x_linear [transform_gmos_x_old2new $x_linear 0.1614 "GMOS-N"]
		set x_linear [expr $x_linear / 2.]
	    }
	    return $x_linear
	}

	# Warning: In case of GMOS-N, calculations were made for the old E2VDD
	# Must transform old 2x2 binned pixels to new Hamamatsu 2x2 pixels
	if {$instType == "GMOS-N"} {
	    set x1 [expr 2. * $x1]
	    set x1 [transform_gmos_x_old2new $x1 0.1614 "GMOS-N"]
	    set x1 [expr $x1 / 2.]
	}
	return $x1
    }


    #############################################################
    #  Name: spectralbox_plot_indwave
    #
    #  Description:
    #  This function draws user-defined wavelengths
    #############################################################
    #############################################################
    protected method spectralbox_plot_indwave {spect_cwl spec_xmin spec_xmax spec_ymin spec_ymax \
						   minsep coeff1 coeff2 tags tags_ind grating slitnr \
						   slitpos} {
	set wavelengths [$w_.wmodfWavelengthEdit get]

	# Replace atomic chars by wavelengths
	set substitution [replace_X_lambda $wavelengths]
	set wavelengths [lindex $substitution 0]
	set wavename [lindex $substitution 1]

	set numwave [llength $wavelengths]
	set redshift  [$w_.wmodfRedshiftEdit get]
	if {$redshift == ""} {
	    set redshift 0.0
	}
	if {! [string is double $redshift] || $redshift < 0.} {
	    ::cat::vmAstroCat::error_dialog "Non-numeric or negative redshift."
	    return -1
	}
	set n 0
	while {$n < $numwave} {
	    # Wavelengths [nm] to plot
	    set wavelength [expr [lindex $wavelengths $n] * (1. + $redshift)]
	    # Labels [nm]
	    set label1 [lindex $wavelengths $n]
	    set label2 [lindex $wavename $n]
	    spectralbox_plot_wavelength $wavelength $spect_cwl \
		$spec_xmin $spec_xmax $spec_ymin $spec_ymax $minsep $coeff1 $coeff2 \
		$tags $tags_ind cyan $label1 $label2 0.80 \
		$grating $slitnr $slitpos
	    incr n 1
	}
	return 0
    }

    #############################################################
    #  Name: spectralbox_plot_wavelength
    #
    #  Description:
    #  This function draws a line at a given wavelength
    #############################################################
    #############################################################
    protected method spectralbox_plot_wavelength {wavelength spect_cwl \
						      spec_xmin spec_xmax spec_ymin spec_ymax \
						      minsep coeff1 coeff2 tags tags_ind color \
						      label1 label2 yfrac grating slitnr slitpos} {

	set target_canvas_ .skycat1.image.imagef.canvas
	set target_image_ image2
	set tmp 0

	# Wavelengths must be in Angstrom. Interface gets nm

	$target_image_ convert coords $spec_xmin $spec_ymin image spec_xmin_cv spec_ymin_cv canvas
	$target_image_ convert coords $spec_xmax $spec_ymax image spec_xmax_cv spec_ymax_cv canvas

	set offset_curvature [expr $coeff1*$DETDIMY/2 + $coeff2*pow($DETDIMY / 2., 2)]
	$target_image_ convert coords $offset_curvature $tmp image offset_curvature_cv tmp canvas
	set offset_cv [expr 5+$offset_curvature_cv]

	set type [$w_.topLeft.options get]
	set ifu2_slitnr ""
	if {$type == "GMOS-N IFU-2" || $type == "GMOS-S IFU-2"} {
	    set ifu2_slitnr $slitnr
	    if {$slitnr == 1} {
		set color orange
	    }
	}	    

	set wavelength_pixel [lambda_to_spatial $wavelength $spect_cwl $grating $spec_xmin $spec_xmax $ifu2_slitnr]

	if {$DISPDIR == "horizontal"} {
	    set spec_min $spec_xmin
	    set spec_max $spec_xmax
	} else {
	    set spec_min $spec_ymin
	    set spec_max $spec_ymax
	}

	# Override minsep (i.e., we plot the wavelength markers always)
	set minsep 0

	# Reset the color if we plot a wavelength grid and one grid line coincides with the red CWL marker
	if {($color == "yellow" || $color == "orange") && $wavelength == $spect_cwl} {
	    set color red
	}

	# Show wavelength marker (curved line)
	if {[expr abs($spect_cwl - $wavelength)] >= $minsep && \
		$wavelength_pixel > $spec_min && $wavelength_pixel < $spec_max} {
	    plot_curve $wavelength_pixel $coeff1 $coeff2 $tags $tags_ind $color 2
	}

	# Show wavelength labels
	if {[expr abs($spect_cwl - $wavelength)] >= $minsep && \
		$wavelength_pixel > $spec_min && $wavelength_pixel < $spec_max} {
	    if {$DISPDIR == "horizontal"} {
		$target_image_ convert coords $wavelength_pixel $tmp image wavelength_pixel_cv tmp canvas
		$target_canvas_ create text [expr $wavelength_pixel_cv+$offset_cv] [expr $yfrac*($spec_ymin_cv+$spec_ymax_cv)] \
		    -anchor w -font {Arial 12} -text ${label1}\n${label2} -tags "$tags $tags_ind" -fill $color
	    } else {
		$target_image_ convert coords $tmp $wavelength_pixel image tmp wavelength_pixel_cv canvas
		$target_canvas_ create text [expr $yfrac*($spec_xmin_cv+$spec_xmax_cv)] [expr $wavelength_pixel_cv+$offset_cv] \
		    -anchor n -font {Arial 12} -text ${label1}\n${label2} -tags "$tags $tags_ind" -fill $color
	    }
	}
    }

    #############################################################
    #  Name: spectralbox_plot_2ndorder
    #
    #  Description:
    #  This function draws 2ndorder overlap
    #############################################################
    #############################################################
    protected method spectralbox_plot_2ndorder {spec_xmin spec_xmax spec_ymin spec_ymax \
						    spect_2ndorder_begin_pixel \
						    tags tags_wmodf_2ndorder} {

	if {$spect_2ndorder_begin_pixel <= 1} {
	    return
	} else {
	    set target_canvas_ .skycat1.image.imagef.canvas
	    set target_image_ image2
	    set tmp 0
	    set stipple gray12

	    $target_image_ convert coords $spec_xmin $spec_ymin image spec_xmin_cv spec_ymin_cv canvas
	    $target_image_ convert coords $spec_xmax $spec_ymax image spec_xmax_cv spec_ymax_cv canvas

	    # box coordinates (Left Top Right Bottom)
	    set l2nd_cv $spec_xmin_cv
	    set b2nd_cv $spec_ymin_cv
	    if {$DISPDIR == "horizontal"} {
		$target_image_ convert coords $spect_2ndorder_begin_pixel $tmp image spect_2nd_cv tmp canvas
		set t2nd_cv $spec_ymax_cv 
		set r2nd_cv $spect_2nd_cv 
	    } else {
		$target_image_ convert coords $tmp $spect_2ndorder_begin_pixel image tmp spect_2nd_cv canvas
		set t2nd_cv $spect_2nd_cv 
		set r2nd_cv $spec_xmax_cv
	    }
	    
	    # Draw the 2nd order box
	    $target_canvas_ create rect $l2nd_cv $t2nd_cv $r2nd_cv $b2nd_cv -outline orange \
		-fill orange -stipple $stipple -width 1 -tags "$tags $tags_wmodf_2ndorder"
	}
    }


    #############################################################
    #  Name: spectralbox_plot_outline
    #
    #  Description:
    #  This function draws the spectral box
    #############################################################
    #############################################################
    protected method spectralbox_plot_outline {spec_xmin spec_xmax spec_ymin spec_ymax \
						   tags tags_wmodf_specbox} {

	set target_canvas_ .skycat1.image.imagef.canvas
	set target_image_ image2
	set footprintcolor GhostWhite

	if {$DISPDIR == "horizontal"} {
	    # Spectrum box: right line
	    set r1x [expr $spec_xmax]
	    set r2x [expr $spec_xmax]
	    set r1y $spec_ymax
	    set r2y $spec_ymin
	    # Spectrum  box: bottom line
	    set b1x [expr $spec_xmax]
	    set b2x [expr $spec_xmin]
	    set b1y $spec_ymin
	    set b2y $spec_ymin
	    # Spectrum  box: left line
	    set l1x [expr $spec_xmin]
	    set l2x [expr $spec_xmin]
	    set l1y $spec_ymin
	    set l2y $spec_ymax
	    # Spectrum  box: top line
	    set t1x [expr $spec_xmin]
	    set t2x [expr $spec_xmax]
	    set t1y $spec_ymax
	    set t2y $spec_ymax
	    # For the two shaded boxes to the left and right of the slit
	    set spec_min $spec_xmin
	    set spec_max $spec_xmax
	} else {
	    # Spectrum box: right line
	    set r1x $spec_xmax
	    set r2x $spec_xmax
	    set r1y [expr $spec_ymax]
	    set r2y [expr $spec_ymin]
	    # Spectrum  box: bottom line
	    set b1x $spec_xmax
	    set b2x $spec_xmin
	    set b1y [expr $spec_ymin]
	    set b2y [expr $spec_ymin]
	    # Spectrum  box: left line
	    set l1x $spec_xmin
	    set l2x $spec_xmin
	    set l1y [expr $spec_ymin]
	    set l2y [expr $spec_ymax]
	    # Spectrum  box: top line
	    set t1x $spec_xmin
	    set t2x $spec_xmax
	    set t1y [expr $spec_ymax]
	    set t2y [expr $spec_ymax]
	    # For the two shaded boxes to the left and right of the slit
	    set spec_min $spec_ymin
	    set spec_max $spec_ymax
	}

	# Convert to canvas coordinate system
	$target_image_ convert coords $r1x $r1y image r1x_cv r1y_cv  canvas
	$target_image_ convert coords $r2x $r2y image r2x_cv r2y_cv  canvas
	$target_image_ convert coords $b1x $b1y image b1x_cv b1y_cv  canvas
	$target_image_ convert coords $b2x $b2y image b2x_cv b2y_cv  canvas
	$target_image_ convert coords $l1x $l1y image l1x_cv l1y_cv  canvas
	$target_image_ convert coords $l2x $l2y image l2x_cv l2y_cv  canvas
	$target_image_ convert coords $t1x $t1y image t1x_cv t1y_cv  canvas
	$target_image_ convert coords $t2x $t2y image t2x_cv t2y_cv  canvas

	# Draw the spectrum box (composite of four lines, because tilted in the general case)
	$target_canvas_ create line $r1x_cv $r1y_cv $r2x_cv $r2y_cv -fill $footprintcolor -width 1 -tags "$tags $tags_wmodf_specbox"
	$target_canvas_ create line $b1x_cv $b1y_cv $b2x_cv $b2y_cv -fill $footprintcolor -width 1 -tags "$tags $tags_wmodf_specbox"
	$target_canvas_ create line $l1x_cv $l1y_cv $l2x_cv $l2y_cv -fill $footprintcolor -width 1 -tags "$tags $tags_wmodf_specbox"
	$target_canvas_ create line $t1x_cv $t1y_cv $t2x_cv $t2y_cv -fill $footprintcolor -width 1 -tags "$tags $tags_wmodf_specbox"
    }


    #############################################################
    #  Name: spectralbox_plot_gaps
    #
    #  Description:
    #  This function displays the gap wavelengths
    #############################################################
    #############################################################
    protected method spectralbox_plot_gaps {nlabels coeff1 coeff2 detgaps \
						spect_cwl spec_xmin spec_max \
						tags tags_wmodf_showwavegrid grating slitnr} {

	set target_canvas_ .skycat1.image.imagef.canvas
	set target_image_ image2

	set type [$w_.topLeft.options get]
	set ifu2_slitnr ""
	if {$type == "GMOS-N IFU-2" || $type == "GMOS-S IFU-2"} {
	    set ifu2_slitnr $slitnr
	}

	set step [expr round($DETDIMY / ($nlabels+1))]
	set n 1
	set offset_cv 5
	while {$n <= $nlabels} {
	    # y positions of the plot labels
	    set y [expr $n*$step]
	    # offset at that y position because of spectral curvature
	    set zerooffset [expr $coeff1*$DETDIMY / 2. + $coeff2*pow($DETDIMY / 2., 2)]
	    set offset [expr $coeff1*$y + $coeff2*$y*$y - $zerooffset]
	    set gap1 [expr [lindex $detgaps 0] - $offset]
	    set gap2 [expr [lindex $detgaps 1] - $offset]
	    set gap3 [expr [lindex $detgaps 2] - $offset]
	    set gap4 [expr [lindex $detgaps 3] - $offset]
	    set gapwave1 [expr round([spatial_to_lambda $gap1 $spect_cwl $grating $ifu2_slitnr])]
	    set gapwave2 [expr round([spatial_to_lambda $gap2 $spect_cwl $grating $ifu2_slitnr])]
	    set gapwave3 [expr round([spatial_to_lambda $gap3 $spect_cwl $grating $ifu2_slitnr])]
	    set gapwave4 [expr round([spatial_to_lambda $gap4 $spect_cwl $grating $ifu2_slitnr])]
	    $target_image_ convert coords $gap1 $y image gap1_cv y_cv canvas
	    $target_image_ convert coords $gap2 $y image gap2_cv y_cv canvas
	    $target_image_ convert coords $gap3 $y image gap3_cv y_cv canvas
	    $target_image_ convert coords $gap4 $y image gap4_cv y_cv canvas
	    # Show gap wavelengths only if gap is within a spectral box
	    if {$gap1 >= $spec_xmin && $gap1 <= $spec_max} {
		$target_canvas_ create text [expr $gap1_cv-$offset_cv] $y_cv \
		    -anchor e -font {Arial 12 bold} -text $gapwave1 -tags "$tags $tags_wmodf_showwavegrid" -fill cyan
	    }
	    if {$gap2 >= $spec_xmin && $gap2 <= $spec_max} {
		$target_canvas_ create text [expr $gap2_cv+$offset_cv] $y_cv \
		    -anchor w -font {Arial 12 bold} -text $gapwave2 -tags "$tags $tags_wmodf_showwavegrid" -fill cyan
	    }
	    if {$gap3 >= $spec_xmin && $gap3 <= $spec_max} {
		$target_canvas_ create text [expr $gap3_cv-$offset_cv] $y_cv \
		    -anchor e -font {Arial 12 bold} -text $gapwave3 -tags "$tags $tags_wmodf_showwavegrid" -fill cyan
	    }
	    if {$gap4 >= $spec_xmin && $gap4 <= $spec_max} {
		$target_canvas_ create text [expr $gap4_cv+$offset_cv] $y_cv \
		    -anchor w -font {Arial 12 bold} -text $gapwave4 -tags "$tags $tags_wmodf_showwavegrid" -fill cyan
	    }
	    incr n 1
	}
    }


    #############################################################
    #  Name: slits_WMODF
    #
    #  Description:
    #  This function draws the slits for WMODF files.
    #############################################################
    #############################################################
    public method slits_WMODF {} {
	global ::cbo_wmodf_2ndorder ::cbo_wmodf_spectra ::cbo_wmodf_showwavegrid
	global ::cbo_wmodf_slitpos ::cbo_wmodf_indwave
	global spect_lmin_old spect_lmax_old spect_disp_old filter_old grating_old instType_old

	set spect_cwl  [$w_.wmodfCWLSpinBox get]

	# First, clear everything
	clearslits_WMODF
	
	# Clear slits if requested and return
	if {$cbo_wmodf_spectra == 0} {
	    $w_.wmodfPlotCBO_showwavegrid configure -state disabled
	    $w_.wmodfPlotCBO_2ndorder configure -state disabled
	    return
	}
	
	set target_canvas_ .skycat1.image.imagef.canvas
	set target_image_ image2
	set tags_wmodf_specbox wmodf_specbox
	set tags_wmodf_showwavegrid wmodf_showwavegrid
	set tags_wmodf_2ndorder wmodf_secondorder
	set tags_wmodf_indwave wmodf_indwave

	# Activate the wavelength overlay; delete previous wavelength overlay (if any)
	$w_.wmodfPlotCBO_showwavegrid configure -state normal
	if {$cbo_wmodf_showwavegrid == 0} {
	    $target_canvas_ delete wmodf_showwavegrid
	}
	
	# Activate the individual wavelength overlay; delete previous wavelength overlay (if any)
	$w_.wmodfPlotCBO_indwave configure -state normal
	if {$cbo_wmodf_indwave == 0} {
	    $target_canvas_ delete wmodf_indwave
	}
	
	# Activate the 2nd order checkbutton; delete previous 2nd order (if any)
	$w_.wmodfPlotCBO_2ndorder configure -state normal
	if {$cbo_wmodf_2ndorder == 0} {
	    $target_canvas_ delete wmodf_secondorder
	}

	# OK, now work towards plotting the slits
	set bg black
	set tags slitMarkWMODF
	set instType $itk_option(-instType)
	set cwl_outside_spectrum_global "FALSE"

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
	
	# Draw the boundary, and retrieve the lower and upper spectral detector cutoffs
	# The boundaries are already in canvas coordinates!
	wmodf_drawBoundaries
	if {$DISPDIR == "horizontal"} {
	    set detspecmin $DETXMIN
	    set detspecmax $DETXMAX
	} else {
	    set detspecmin $DETYMIN
	    set detspecmax $DETYMAX
	}

	# Determine spectrum min and max lambda, dispersion, and central wavelength
	# Calculate the spectrum length
	# calcSpectrum returns a list; it sets the global var SpecLen

	#  Get information selected from the pop-up
	set filter [$w_.wmodfButtonFrame2.filter get]
	set grating [$w_.wmodfButtonFrame2.grateorder get]

	# To make the interface faster, only calculate if the grating / filter combination has changed!
	if {$filter == $filter_old && $grating == $grating_old && $instType == $instType_old} {
	    set spect_lmin $spect_lmin_old
	    set spect_lmax $spect_lmax_old
	    set spect_disp $spect_disp_old
	} else {
	    if {[catch {set outlist [wmodf_calcSpectrum]} msg]} {
		::cat::vmAstroCat::error_dialog $msg 
		return
	    }
	    if {$outlist == ""} {
		return
	    }
	    # Extract the output of calcSpectrum()
	    set spect_lmin [lindex $outlist 0]
	    set spect_lmax [lindex $outlist 1]
	    set spect_disp [lindex $outlist 2]
	}

	set filter [string map {"_and_" "+"} $filter]
	set spect_length 0

	# Do we have second order overlap with this configuration?
	set check_2ndorder_overlap "FALSE"
	set spect_2ndorder_begin [expr {round(2.*$spect_lmin)}]
	if {$spect_2ndorder_begin < $spect_lmax} {
	    set check_2ndorder_overlap "TRUE"
	}

	set nobj 1
	set type [$w_.topLeft.options get]
	# Through-slit positions (y positions are approximate)
	if {$type == "GMOS-N Longslit"} {
	    set xccd_list 1569
	    set yccd_list 1050
	} elseif {$type == "GMOS-N IFU-R"} {
	    set xccd_list 698
	    set yccd_list 1050
	} elseif {$type == "GMOS-N IFU-2"} {
	    set xccd_list [list 701 2444]
	    set yccd_list [list 1050 1050]
	    set nobj 2
	} elseif {$type == "GMOS-S Longslit"} {
	    set xccd_list 1568
	    set yccd_list 1050
	} elseif {$type == "GMOS-S IFU-R"} {
	    set xccd_list 688
	    set yccd_list 1050
	} elseif {$type == "GMOS-S IFU-2"} {
	    set xccd_list [list 691 2455]
	    set yccd_list [list 1050 1050]
	    set nobj 2
	}
	
	if {$type == "GMOS-N IFU-2" && $grating == "R150"} {
	    ::cat::vmAstroCat::error_dialog "The GMOS-N IFU-2 has not been mapped with the R150 grating."
	    return
	}


	set dimx [expr 1.   / 2.0 / $PIXSCALE]
	set dimy [expr 330. / 2.0 / $PIXSCALE]

	# Needed to collect warnings about spectra that fall entirely off the detector edge
	set outsidewarning ""
	set blank " "

	set type [$w_.topLeft.options get]

	#  Cycle through each item in the objects list
	for {set n 0} {$n < $nobj} {incr n} {
	    
	    set ifu2_slitnr ""
	    if {$type == "GMOS-N IFU-2" || $type == "GMOS-S IFU-2"} {
		set ifu2_slitnr $n
	    }

	    # In case we have two slits (IFU-2) we need this:
	    set xccd [lindex $xccd_list $n]
	    set yccd [lindex $yccd_list $n]
	    set type [$w_.topLeft.options get]
	    set waveccd [lambda_to_spatial $spect_cwl $spect_cwl $grating 1 $DETDIMX $ifu2_slitnr]

	    # Convert upper and lower spectral limits into pixel coordinates
	    set spect_lmin_pixel [lambda_to_spatial $spect_lmin $spect_cwl $grating 1 $DETDIMX $ifu2_slitnr]
	    set spect_lmax_pixel [lambda_to_spatial $spect_lmax $spect_cwl $grating 1 $DETDIMX $ifu2_slitnr]

	    set spect_2ndorder_begin [expr 2.*$spect_lmin]
	    set spect_2ndorder_begin_pixel \
		[lambda_to_spatial $spect_2ndorder_begin $spect_cwl $grating 1 $DETDIMX $ifu2_slitnr]

	    # Don't plot anything if the spectrum is entirely outside the detector area 
	    if {$DISPDIR == "horizontal"} {
		if {($spect_lmax_pixel < 1 && $spect_lmin_pixel < 1) ||
		    ($spect_lmax_pixel > $DETDIMX && $spect_lmin_pixel > $DETDIMX)} {
		    set outsidewarning $outsidewarning$n$blank
		    continue
		}
	    } else {
		if {($spect_lmax_pixel < 1 && $spect_lmin_pixel < 1) ||
		    ($spect_lmax_pixel > $DETDIMY && $spect_lmin_pixel > $DETDIMY)} {
		    set outsidewarning $outsidewarning$n$blank
		    continue
		}
	    }
	    
	    # The border of spectral footprint in image coordinates;
	    # also truncate dispersion dimension at detector boundaries
	    if {$DISPDIR == "horizontal"} {
		set spec_xmin [max 1 $spect_lmax_pixel]
		set spec_xmax [min $DETDIMX $spect_lmin_pixel]
		set spec_ymin [expr $yccd - $dimy]
		set spec_ymax [expr $yccd + $dimy]
	    } else {
		set spec_xmin [expr $xccd - $dimx]
		set spec_xmax [expr $xccd + $dimx]
		set spec_ymin [max 1 $spect_lmax_pixel]
		set spec_ymax [min $DETDIMY $spect_lmin_pixel]
	    }
	    
	    # A flag that checks whether the CWL is outside the spectral box
	    set cwl_outside_spectrum "FALSE"
	    if {$waveccd > $spect_lmin_pixel || $waveccd < $spect_lmax_pixel} {
		set cwl_outside_spectrum "TRUE"
		set cwl_outside_spectrum_global "TRUE"
	    }
	    
	    # A flag that checks whether the slit is outside the spectral box
	    set slit_outside_spectrum "FALSE"
	    if {$DISPDIR == "horizontal"} {
		if {$xccd > $spect_lmin_pixel || $xccd < $spect_lmax_pixel} {
		    set slit_outside_spectrum "TRUE"
		}
	    } else {
		if {$yccd > $spect_lmin_pixel || $yccd < $spect_lmax_pixel} {
		    set slit_outside_spectrum "TRUE"
		}
	    }
	    
	    # Plot the (shaded) spectral boxes and wavelengths
	    wmodf_slit_plot_spectralbox \
		$cwl_outside_spectrum $slit_outside_spectrum \
		$spec_xmin $spec_xmax $spec_ymin $spec_ymax \
		$dimx $dimy $xccd $yccd $tags $tags_wmodf_specbox \
		$tags_wmodf_2ndorder $tags_wmodf_showwavegrid \
		$tags_wmodf_indwave $spect_2ndorder_begin_pixel $check_2ndorder_overlap \
		$spect_cwl $spect_disp $detgaps $grating $n
        }
	
	if {$outsidewarning != ""} {
	    ::cat::vmAstroCat::warn_dialog "Spectra fall entirely outside the detector area due to bad CWL/filter choice."
	    return
	}
	
	return
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
    #  Name: hashmark_ifu2_slitoverlap
    #
    #  Description:
    #  Draws hashed areas if the 1st orders of the two spectral 
    #  banks of the IFU-2 overlap, and if the 2nd order of the
    #  right slit overlaps the first order of the left slit
    #############################################################
    #############################################################
    public method hashmark_ifu2_slitoverlap {tags tags_wmodf_specbox} {

	global spect_lmin_old spect_lmax_old spect_disp_old filter_old grating_old instType_old

	# Remove the IFU2 overlap warning label
	$w_.wmodfIFU2OverlapLabel configure -text "" -foreground #f55

	# This is only meaningful for GMOS IFU-2s
	set type [$w_.topLeft.options get]
	if {$type != "GMOS-N IFU-2" && $type != "GMOS-S IFU-2"} {
	    return
	}

	set instType $itk_option(-instType)

	set spect_cwl  [$w_.wmodfCWLSpinBox get]

	set target_canvas_ .skycat1.image.imagef.canvas
	set target_image_ image2

	# Get the detector extent in pixels

	# Determine spectrum min and max lambda, dispersion, and central wavelength
	# Calculate the spectrum length
	# calcSpectrum returns a list; it sets the global var SpecLen

	#  Get information selected from the pop-up
	set filter [$w_.wmodfButtonFrame2.filter get]
	set grating [$w_.wmodfButtonFrame2.grateorder get]
	
	# To make the interface faster, only calculate if the grating / filter combination has changed!
	if {$filter == $filter_old && $grating == $grating_old && $instType == $instType_old} {
	    set spect_lmin $spect_lmin_old
	    set spect_lmax $spect_lmax_old
	} else {
	    if {[catch {set outlist [wmodf_calcSpectrum]} msg]} {
		::cat::vmAstroCat::error_dialog $msg 
		return
	    }
	    if {$outlist == ""} {
		return
	    }
	    # Extract the output of calcSpectrum()
	    set spect_lmin [lindex $outlist 0]
	    set spect_lmax [lindex $outlist 1]
	}

	set nobj 2
	if {$type == "GMOS-N IFU-2"} {
	    set yccd_list [list 1152 1152]
	} elseif {$type == "GMOS-S IFU-2"} {
	    set yccd_list [list 1050 1050]
	}
	
	set dimx [expr 1.   / 2.0 / $PIXSCALE]
	set dimy [expr 330. / 2.0 / $PIXSCALE]

	set spec_xmin_0 0
	set spec_xmax_0 0
	set spec_xmin_1 0
	set spec_xmax_1 0
	set spec_ymin 0
	set spec_ymax 0

	#  Cycle through each item in the objects list
	for {set n 0} {$n < $nobj} {incr n} {
	    set yccd [lindex $yccd_list $n]

	    # Convert upper and lower spectral limits into pixel coordinates
	    set spect_lmin_pixel [lambda_to_spatial $spect_lmin $spect_cwl $grating 1 $DETDIMX $n]
	    set spect_lmax_pixel [lambda_to_spatial $spect_lmax $spect_cwl $grating 1 $DETDIMX $n]
	    
	    # The border of spectral footprint in image coordinates;
	    # also truncate dispersion dimension at detector boundaries
	    if {$n == 0} {
		set spec_xmin_0 [max 1 $spect_lmax_pixel]
		set spec_xmax_0 [min $DETDIMX $spect_lmin_pixel]
	    }
	    if {$n == 1} {
		set spec_xmin_1 [max 1 $spect_lmax_pixel]
		set spec_xmax_1 [min $DETDIMX $spect_lmin_pixel]
	    }
	    set spec_ymin [expr $yccd - $dimy]
	    set spec_ymax [expr $yccd + $dimy]
	}

	# Plot a hashed area if the first orders overlap
	if {$spec_xmin_1 < $spec_xmax_0} {
	    $target_image_ convert coords $spec_xmin_1 $spec_ymin image spec_xmin_cv spec_ymin_cv canvas
	    $target_image_ convert coords $spec_xmax_0 $spec_ymax image spec_xmax_cv spec_ymax_cv canvas
	    $target_canvas_ create rect $spec_xmin_cv $spec_ymax_cv $spec_xmax_cv $spec_ymin_cv \
		-fill red -stipple gray12 -width 0 -tags "$tags $tags_wmodf_specbox"

	    # Show the IFU-2 overlap warning label
	    $w_.wmodfIFU2OverlapLabel configure -text "IFU-2 spectral bank overlap" \
		-foreground #f55
	}

	# Plot a hashed area where the second order of the right slit appears
	set spect_2ndorder_begin [expr 2.*$spect_lmin]
	set spect_2ndorder_begin_pixel \
	    [lambda_to_spatial $spect_2ndorder_begin $spect_cwl $grating 1 $DETDIMX 1]
	# truncate by detector boundary
	set spect_2ndorder_begin_pixel [min $DETDIMX $spect_2ndorder_begin_pixel]
#	set spect_2ndorder_limit_bank1 [expr {round([spatial_to_lambda $spect_2ndorder_begin_pixel $spect_cwl $grating 0] / 10.)}]
	set spect_2ndorder_limit_bank1 [spatial_to_lambda $spect_2ndorder_begin_pixel $spect_cwl $grating 0]
	if {$spect_2ndorder_begin_pixel > 1} {
	    $target_image_ convert coords $spect_2ndorder_begin_pixel $spec_ymin image spect_2ndorder_begin_pixel_cv spec_ymin_cv canvas
	    $target_image_ convert coords 1 $spec_ymax image spect_2ndorder_end_pixel_cv spec_ymax_cv canvas
	    $target_canvas_ create rect $spect_2ndorder_end_pixel_cv $spec_ymax_cv $spect_2ndorder_begin_pixel_cv $spec_ymin_cv \
		-fill red -stipple gray12 -width 0 -tags "$tags $tags_wmodf_specbox"

	    # Show the 2nd order warning label
	    $w_.wmodf2ndOrderLabel configure -text "2nd order from right slit\n overlaps left slit at >$spect_2ndorder_limit_bank1 nm" \
		-foreground #f55
	}
    }


    #############################################################
    #  Name: clearslits_WMODF
    #
    #  Description:
    #   Clear the slits in the WMODF window
    #############################################################
    #############################################################
    public method clearslits_WMODF {} {
	global ::cbo_wmodf_spectra ::cbo_wmodf_2ndorder 
	global ::cbo_wmodf_showwavegrid ::cbo_wmodf_slitpos
        set target_canvas_ .skycat1.image.imagef.canvas
        $target_canvas_ delete wmodf_specbox
        $target_canvas_ delete wmodf_2ndorder
        $target_canvas_ delete cbo_wmodf_spectra
        $target_canvas_ delete cbo_wmodf_slitpos
        $target_canvas_ delete wmodf_secondorder
        $target_canvas_ delete slitMarkWMODF
	
        return
    }


     #########################################################################
    #  Name: cancel
    #
    #  Description:
    #     close
    #
    #########################################################################
    #########################################################################    
    public method cancel {} {
	# This method gets called by anything that has a cancel button
	# on it..... not sure how to distinguish it.
        close
    }


    #########################################################################
    #  Name: close
    #
    #  Description:
    #     Destroy window
    #
    #########################################################################
    #########################################################################
    public method close {} {
	catch {clearslits_WMODF}
        catch {destroy $w_ }
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
	set GAP1X {}
	set GAP1Y {}
	set GAP2X {}
	set GAP2Y {}
	set DIMX  {}
	set DIMY  {}
	set N_DIM  0
	set N_GAP1 0
	set N_GAP2 0

	set NAXIS1 [::cat::vmAstroCat::get_fits_keyword "NAXIS1 "]
	set NAXIS2 [::cat::vmAstroCat::get_fits_keyword "NAXIS2 "]
	set CRPIX1 [::cat::vmAstroCat::get_fits_keyword "CRPIX1 "]
	set CRPIX2 [::cat::vmAstroCat::get_fits_keyword "CRPIX2 "]
	set CD11   [::cat::vmAstroCat::get_fits_keyword "CD1_1 "]
	set CD12   [::cat::vmAstroCat::get_fits_keyword "CD1_2 "]
	set CD21   [::cat::vmAstroCat::get_fits_keyword "CD2_1 "]
	set CD22   [::cat::vmAstroCat::get_fits_keyword "CD2_2 "]
	
	# The dispersion direction
	if {$instType == "GMOS-S" || $instType == "GMOS-N"} {
	    set DISPDIR "horizontal"
	}
	if {$instType == "F2" || $instType == "F2-AO"} {
	    set DISPDIR "vertical"
	}
	
	# PIXELSCALE
	set PIXSCALE 0
	if {$CD11 != "UNKNOWN" && $CD12 != "UNKNOWN" && $CD21 != "UNKNOWN" && $CD22 != "UNKNOWN"} {
	    set ps1 [expr sqrt($CD11*$CD11+$CD12*$CD12) * 3600. ]
	    set ps2 [expr sqrt($CD22*$CD22+$CD21*$CD21) * 3600. ]
	    set PIXSCALE [expr ($ps1+$ps2) / 2. ]
	}
	if {$PIXSCALE == 0} {
	    set CDELT1 [::cat::vmAstroCat::get_fits_keyword "CDELT1 "]
	    set CDELT2 [::cat::vmAstroCat::get_fits_keyword "CDELT2 "]
	    if {$CDELT1 != "UNKNOWN" && $CDELT2 != "UNKNOWN"} {
		set PIXSCLE [expr sqrt($CDELT1*$CDELT1+$CDELT2*$CDELT2) * 3600. ]
	    }
	}
	if {$PIXSCALE == 0} {
	    ::cat::vmAstroCat::error_dialog "No valid WCS information (CD matrix nor CDELT) in the FITS header!"
	    return "ERROR"
	}

	# Read in FOV, GAP and DETDIM
	set fovfilename $home/config/${instType}_current_fov.dat
	if {[catch {set fovList [open $fovfilename r] } msg]} {
	    ::cat::vmAstroCat::error_dialog "$msg"
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
		if {[string match DIM_CORNER* $line] == 1} {
		    set DIMX [lappend DIMX [format "%.1f" [expr [lindex $line 1 ] / $PIXSCALE + $CRPIX1 ]]]
		    set DIMY [lappend DIMY [format "%.1f" [expr [lindex $line 2 ] / $PIXSCALE + $CRPIX2 ]]]
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


    # Options indicating col's that exist
    itk_option define -instType instType InstType ""

    # Name of the gmmps program configuration file. 
    protected variable config_file_

    # Reference to the catalog widget instance that called this widget.
    protected variable catClass_

    # Holds the dispersion direction

    protected variable home_ ""
    
    # The wavemapper ODF window
    protected variable wmodf_text_ "black"
    protected variable wmodf_bg_ "grey86"
    protected variable wmodf_bg2_ "grey86"

    protected variable button_text_wmodf_ "black"
    protected variable button_text_active_wmodf_ "black"
    protected variable button_bg_wmodf_ "grey86"
    protected variable button_bg_active_wmodf_ "white"

    protected variable catalog_text_wmodf_ "black"
    protected variable catalog_text_active_wmodf_ "black"
    protected variable catalog_bg_wmodf_ "white"
    protected variable catalog_bg_active_wmodf_ "yellow"

    protected variable menu_bg_wmodf_ #084
    protected variable menu_text_wmodf_ "white"
    protected variable menu_bg_active_wmodf_ "white"
    protected variable menu_text_active_wmodf_ "black"

    # For the WMODF
    protected common wmodf_nfilter
    protected common wmodf_ngrate
    protected common wmodf_ngtilt
    protected common wmodf_buf_filter
    protected common wmodf_buf_grate
    protected common wmodf_buf_grequest
    protected common wmodf_buf_gtilt
    protected common wmodf_gTilt
    protected common wmodf_gRequest

    # A lot more "globals" because I can't figure out how else to do this with tclTk...
    # best GMMPS style...
    protected common CRPIX1 ""
    protected common CRPIX2 ""
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
    protected common GAP1X {}
    protected common GAP1Y {}
    protected common GAP2X {}
    protected common GAP2Y {}
    protected common DIMX  {}
    protected common DIMY  {}
    protected common N_DIM  0
    protected common N_GAP1 0
    protected common N_GAP2 0
 }
