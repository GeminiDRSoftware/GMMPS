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

# $Id: gmmps_spoc.tcl,v 1.8 2013/04/23 15:41:14 gmmps Exp $
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
# gmmps_spoc.tcl 
#
# PURPOSE:
# GUI for SPOC.
#
# Original created by:
# E.S.O. - VLT project/ ESO Archive
# D.Bottini    01 Apr 00 Created

itcl::class cat::gmmps_spoc {
    inherit util::TopLevelWidget
    
    #  constructor
    constructor {catClass catname binning \
		     resultz instType config_file det_img det_spec globallist\
		     {spocbandsargs ""} args} {

			 global vsDebugLevel
			 set vsDebugLevel 1 
			 set args {}
			 eval itk_initialize $args
			 set itk_option(-catalog) $catname
			 set itk_option(-binning) $binning
			 set itk_option(-resultz) $resultz
			 set itk_option(-instType) $instType
			 set itk_option(-spocbandsargs) $spocbandsargs
			 set DET_IMG_ $det_img
			 set DET_SPEC_ $det_spec
			 set config_file_ $config_file
			 set catClass_ $catClass
			 set CRPIX1   [lindex $globallist 0]
			 set CRPIX2   [lindex $globallist 1]
			 set PA       [lindex $globallist 2]
			 set RA       [lindex $globallist 3]
			 set DEC      [lindex $globallist 4]
			 set NAXIS1   [lindex $globallist 5]
			 set NAXIS2   [lindex $globallist 6]
			 set DISPDIR  [lindex $globallist 7]
			 set PIXSCALE [lindex $globallist 8]
			 set DETDIMX  [lindex $globallist 9]
			 set DETDIMY  [lindex $globallist 10]
			 set DETXMIN  [lindex $globallist 11]
			 set DETXMAX  [lindex $globallist 12]
			 set DETYMIN  [lindex $globallist 13]
			 set DETYMAX  [lindex $globallist 14]
			 
			 set gmmps_version 0.0
			 set home_ $::env(GMMPS)
			 catch {set channel [open $home_/VERSION r]}
			 catch {gets $channel gmmps_version}
			 catch {::close $channel }
		     }
    
    # destructor
    destructor {
	catch {close}
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
	global vsDebugLevel
	
	if { $vsDebugLevel == 1 } {
	    puts $line
	}
    }

    
    #############################################################
    #  Name: init
    #
    #  Description:
    #############################################################
    #############################################################
    protected method init {} {

	wm title $w_ "Setup for [file tail $itk_option(-catalog)] ($itk_option(-number))"
	wm iconname $w_ "Setup for [file tail $itk_option(-catalog)] ($itk_option(-number))"
	set home $::env(GMMPS)
	
	set instType $itk_option(-instType)
	
	set filter_file    $home/config/${instType}_filters.lut
	set grate_file     $home/config/${instType}_gratings.lut
	set grateList_file $home/config/${instType}_gratingeq.dat
	
	set filter    [open $filter_file r]
	set grate     [open $grate_file r]
	set grateList [open $grateList_file r]
	
	set buf_filter ""
	set buf_grate ""
	set buf_grequest ""
	set buf_gtilt ""
	
	#  Read in the config files.
	while {[gets $filter line] >= 0} {
	    if {[string match *#* $line] == 0} { lappend buf_filter $line}
	}
	::close $filter
	
	while {[gets $grate line] >= 0} {
	    if {[string match *#* $line] == 0} { lappend buf_grate $line}
	}
	::close $grate

	# Get the gRequest/gTilt table read in. Put in buf_grequest & buf_gtilt
	set cnt 0
	while {[gets $grateList line] >= 0} {
	    if {[string match *#* $line] == 0} { 

		#  Break up the line into parts: gRequest gTilt
		incr cnt 1
		set buf_grequest [lappend buf_grequest [lindex $line 0] ]
		set tmpbuf [lindex $line 0]
		set buf_gtilt [lappend buf_gtilt [lindex $line 1] ]
	    }
	}
	::close $grateList
		
	#  Set pull down list values and then draw spoc box.
	set nfilter [llength $buf_filter]
	set ngrate  [llength $buf_grate]
	set ngtilt  [llength $buf_gtilt]
	make_layout $itk_option(-catalog)
     }

    
    #############################################################
    #  Name: add_widgets
    #
    #  Description:
    #    Draw the SPOC box and its widgets
    #############################################################
    #############################################################
    protected method make_layout {mycatname} {
	TopLevelWidget::make_short_help
		
	set home $::env(GMMPS)	

	global ::spoc_autoexpansion ::pack_spectra
	set spoc_autoexpansion 0
	set pack_spectra 1
	set instType $itk_option(-instType)

	# Load values from configuration file, if they are present.
	set prev_inst        [$catClass_ gmmps_config_ [list "instrument" ]]
	set prev_cenwave     [$catClass_ gmmps_config_ [list "$instType-cenwave" ]]
	set prev_grating     [$catClass_ gmmps_config_ [list "$instType-grating" ]]
	set prev_filter      [$catClass_ gmmps_config_ [list "$instType-filter" ]]
	set prev_expansion   [$catClass_ gmmps_config_ [list "$instType-expand_slits" ]]
	set prev_wiggle      [$catClass_ gmmps_config_ [list "$instType-length_offset_%" ]]
	set prev_minSpecDist [$catClass_ gmmps_config_ [list "$instType-minSpecDist" ]]

	# Determine previous expansion setting, if it exists.
	if {$prev_expansion != 0 && $prev_expansion != 1} {
	    set prev_expansion 0
	}

	# Have we wiggled previously
	if {$prev_wiggle == ""} {
	    set prev_wiggle 0
	}
	
	# Have we given a minimum slit separation previously
	if {$prev_minSpecDist == ""} {
	    set prev_minSpecDist 4
	}
		
	#############################################################
	#    The main frame containing the two setup frames
	#############################################################
	pack [frame $w_.masterTopFrame ] \
	    -side top -anchor w -padx 5 -pady 5 -ipadx 5 -ipady 5
	
	
	#############################################################
	#    Frames for instrumental setup and slit placement
	#############################################################
	pack [frame $w_.instSetup -relief groove -borderwidth 2 ] \
	    -side left -anchor w -fill both -padx 5 -pady 5 -ipadx 5 -ipady 5 \
	    -in $w_.masterTopFrame
	
	pack [frame $w_.throughput -relief groove -borderwidth 2 ] \
	    -side left -anchor w -fill both -padx 5 -pady 5 -ipadx 5 -ipady 5 \
	    -in $w_.masterTopFrame

	pack \
	    [label $w_.throughput.label -text "Range: Dispersion:" \
		 -foreground black -anchor w] \
	    -side bottom -anchor w -in $w_.throughput \
	    -padx 5 -ipadx 5 -fill x


	#############################################################
	#    The main frame containing the gmMakeMasks output
	#    and the rest of the elements
	#############################################################
	pack [frame $w_.masterBottomFrame ] \
	    -side top -anchor w -padx 5 -pady 5 -ipadx 5 -ipady 5 \
	    -fill y -expand 1


	#############################################################
	#    Frame containing the make mask and close buttons
	#############################################################
	pack [frame $w_.masterButtonFrame ] \
	    -side right -anchor n -padx 5 -pady 5 -ipadx 5 -ipady 5 \
	    -in $w_.masterBottomFrame

	# Now fill the master frames

	#############################################################
	# 1. Setup the instrument configuration
	#############################################################
	
	# Pack the instrumental setup widgets
	pack \
	    [label $w_.instSetup.label -text "$instType Setup" -foreground "#55f" -anchor w] \
	    -side top -anchor w -in $w_.instSetup \
	    -padx 5 -ipadx 5 -ipady 5 -fill x

	
	# The grating data
	set gratingstring "Grating:"
	if {$instType == "F2" || $instType == "F2-AO"} {
	    set gratingstring "Grism:"
	}
	pack [LabelMenu $w_.instSetup.grateorder \
		  -text $gratingstring -relief groove -orient horizontal ] \
	    -side top -anchor w -in $w_.instSetup \
	    -padx 5 -ipadx 5 -ipady 5
	
	for {set n 0} {$n < $ngrate} {incr n 1} {
	    set grating_name [lindex [lindex $buf_grate $n] 0]
	    $w_.instSetup.grateorder add -label $grating_name \
		-command [code $this procs_for_comboboxes $instType "$instType-grating" $grating_name ]
	}
	
	# The filter data
	pack [LabelMenu $w_.instSetup.filter \
		  -text "Filter :" -relief groove -orient horizontal ] \
	    -side top -anchor w -in $w_.instSetup \
	    -padx 5 -ipadx 5 -ipady 5
	
	for {set n 0} {$n < $nfilter} {incr n 1} {
	    set filter_name [lindex $buf_filter $n]
	    $w_.instSetup.filter add -label $filter_name \
		-command [code $this procs_for_comboboxes $instType "$instType-filter" $filter_name ]
	}
	
	if {$instType == "GMOS-N" || $instType == "GMOS-S"} {

	    pack [frame $w_.cwlButtonFrame ] \
		-side top -anchor w -padx 5 -pady 5 -ipadx 5 -ipady 5 -in $w_.instSetup

	    pack \
		[button $w_.cwlButtonFrame.button -bg "#bbf" -foreground black \
		     -activeforeground black \
		     -text "Auto CWL" \
		     -command [code $this calcSpectrum $instType "update"]] \
		[LabelEntry $w_.cwlButtonFrame.edit -valuewidth 6 -text "" ] \
		-side left -anchor w -in $w_.cwlButtonFrame \
		-padx 5 -ipadx 5 -ipady 1 -fill x
	    add_short_help $w_.cwlButtonFrame.edit \
		{Set the central wavelength of the observation}
	    add_short_help $w_.cwlButtonFrame.button \
		{Determine the best CWL automatically}
	}

	# Restore previous grating/filter settings, if available. 
	if {$prev_grating != ""} {
	    $w_.instSetup.grateorder configure -value $prev_grating
	}
	if {$prev_filter != ""} {
	    $w_.instSetup.filter configure -value $prev_filter
	}
	if {$instType == "GMOS-N" || $instType == "GMOS-S"} {
	    if {$prev_cenwave != ""} {
		$w_.cwlButtonFrame.edit configure -value $prev_cenwave
	    }
	}
	
	# Help
	add_short_help $w_.instSetup.filter \
	    {The filter for the observation}
	add_short_help $w_.instSetup.grateorder \
	    {The grating & order for the observation}
	

	#############################################################
	# 2. Smart slits
	#############################################################

	# Slit expansion and packing
	pack \
	    [label $w_.instSetup.labelSmart -text "Slit placement" -foreground "#55f" -anchor w] \
	    [checkbutton $w_.instSetup.bias -text "Auto expansion" -variable spoc_autoexpansion] \
	    [checkbutton $w_.instSetup.pack -text "Pack spectra" -variable pack_spectra] \
	    -side top -anchor w -padx 5 -ipadx 5 -ipady 5
	
	if {$prev_expansion == 0} {
	    $w_.instSetup.bias deselect
	} else {
	    $w_.instSetup.bias select
	}

	pack \
	    [LabelEntry $w_.instSetup.minSpecDist \
		 -text "Min. separation \[pix\]:" \
		 -value $prev_minSpecDist \
		 -valuewidth 5 ] \
	    -side top -anchor w -padx 5 -ipadx 5 -ipady 5 -fill x

	# Slit expansion and number of masks are spin boxes with labels
	# We need two extra frames for that
	pack \
	    [frame $w_.instSetup.wiggleFrame ] \
	    [frame $w_.instSetup.maskFrame ] \
	    -side top -anchor w -fill x -padx 5 -ipadx 5 -ipady 5
	
	pack \
	    [label $w_.instSetup.wiggleLabel -text "Wiggle amount \[%\]:" \
		 -anchor w ] \
	    [spinbox $w_.instSetup.wiggleSpinBox -from 0 -to 50 -increment 5 \
		 -width 6 -justify right] \
	    -side left -in $w_.instSetup.wiggleFrame -expand 1 -fill x

	$w_.instSetup.wiggleSpinBox set $prev_wiggle

	pack \
	    [label $w_.instSetup.maskLabel -text "Number of Masks:" -anchor w ] \
	    [spinbox $w_.instSetup.maskSpinBox -from 1 -to 10 -increment 1 \
		 -width 6 -justify right] \
	    -side left -in $w_.instSetup.maskFrame -expand 1 -fill x
	
	# Create binding to poll for value change. 
	bind $w_.instSetup.bias <FocusOut> [code $this bias_change "$instType-expand_slits" ]

	# Get the shuffle mode
	set shuffleMode [lindex $itk_option(-spocbandsargs) 0]
	# Deactivate some features
	# If you find a way to fix gmMakeMasks in this respect, then you may
	# enable the one or other feature here ((e.g. slit expansion or wiggling
	# in band-shuffling mode, where it does make sense)
	if { $shuffleMode == "microShuffle"} {
	    # Deactivate auto-expansion (not allowed in microshuffling mode)
	    set spoc_autoexpansion 0
	    $w_.instSetup.bias configure -state disabled
	    # Deactivate slit wiggling (buggy in gmMakemasks)
	    $w_.instSetup.wiggleSpinBox set 0
	    $w_.instSetup.wiggleSpinBox configure -state disabled
	    $w_.instSetup.wiggleLabel configure -state disabled
	}
	if { $shuffleMode == "bandShuffle"} {
	    # Deactivate auto-expansion (buggy in gmMakeMaks; may expand slits into storage bands) 
	    set spoc_autoexpansion 0
	    $w_.instSetup.bias configure -state disabled
	    # Deactivate slit wiggling (buggy in gmMakemasks)
	    $w_.instSetup.wiggleSpinBox set 0
	    $w_.instSetup.wiggleSpinBox configure -state disabled
	    $w_.instSetup.wiggleLabel configure -state disabled
	}
	
	# Help
	add_short_help $w_.instSetup.maskSpinBox {The number of ODF files (masks) to be generated}
	add_short_help $w_.instSetup.minSpecDist \
	    {The minimum separation of spectra for the auto-expansion mode.}
	add_short_help $w_.instSetup.wiggleSpinBox \
	    {Allow movement of slits during placement (percentage of slit length)}
	add_short_help $w_.instSetup.bias \
	    {Expand slits into unused space for max sky coverage. Not available for Nod&Shuffle masks}
	add_short_help $w_.instSetup.pack \
	    {Allow several short spectra to be packed in dispersion direction}
	

	#############################################################
	# 3. gmMakeMasks output
	#############################################################

	# The frame containing the text output from gmMakeMasks
	frame $w_.masterBottomFrame.gmMM
	text $w_.masterBottomFrame.gmMM.03 -width 52 -height 15 -setgrid true -wrap none \
	    -xscrollcommand [list $w_.masterBottomFrame.gmMM.01 set] \
	    -yscrollcommand [list $w_.masterBottomFrame.gmMM.02 set] \
	    -background white
	scrollbar $w_.masterBottomFrame.gmMM.01 \
	    -command [list $w_.masterBottomFrame.gmMM.03 xview] -orient horiz
	scrollbar $w_.masterBottomFrame.gmMM.02 \
	    -command [list $w_.masterBottomFrame.gmMM.03 yview] -orient vert
	pack $w_.masterBottomFrame.gmMM.01 -side bottom -fill x
	pack $w_.masterBottomFrame.gmMM.02 -side right -fill y
	pack $w_.masterBottomFrame.gmMM.03 -side left -fill both -expand true
	pack $w_.masterBottomFrame.gmMM -side left -fill both -expand true


	# Now place the help button and the two final buttons for mask making and closure
	pack \
	    [button $w_.masterButtonFrame.helpSpoc -text "Help" -bg "#9ff" -fg "#000" \
		  -activebackground "#bff" -activeforeground "#000" -anchor n\
		  -command [code $this help file://$home/html/createODF.html]] \
	    [button $w_.masterButtonFrame.spoc -bg "#bfb" -foreground black \
		 -activebackground "#dfd" -activeforeground black  -anchor n\
		 -text "Make Masks" \
		 -command [code $this spoc $mycatname $instType]] \
	    [button $w_.masterButtonFrame.close -foreground black  -anchor n\
		 -activeforeground black \
		 -text "Close" \
		 -command [code $this cancel $mycatname ]] \
	    -side top -expand 1 -pady 2 -fill x
	
	# Help
	add_short_help $w_.masterBottomFrame.catalog {Name of input catalog}	    
	add_short_help $w_.masterBottomFrame.gmMM \
	    {Output of the Slit Positioning Optimization Code}	    
	add_short_help $w_.buttons.spoc  {Generate the mask (ODF)}
	add_short_help $w_.buttons.close {Close this window}

	# Lastly, create the throughput plot for the initially displayed
	# filter/grating combination and display it.
	if {$prev_cenwave != ""} {
	    set outlist [calcSpectrum $instType "dontupdate"]
	} else {
	    set outlist [calcSpectrum $instType "update"]
	}

	if {$outlist != ""} {
	    # Extract the output of calcSpectrum()
	    set Spec_lmin [lindex $outlist 0]
	    set Spec_lmax [lindex $outlist 1]
	    $w_.throughput.label configure -text "Range: $Spec_lmin - $Spec_lmax nm"
	}
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


    ##########################################################################
    # A method that sequentially executes commands for the ComboBoxes
    ##########################################################################
    public method procs_for_comboboxes {instType config name} {
	wave_config $config $name
	calcSpectrum $instType "update"
    }
    

    #############################################################
    #  Name: calcGTilt
    #
    #  Description:
    #    Calculate Gtilt from the GRequest
    #############################################################
    #############################################################
    protected method calcGTilt { gRequest } {
	set max [lindex $buf_grequest 0]
	set cntr 0
	
	for {set n 1} {$n < $ngtilt } {incr n 1} {
	    set min [lindex $buf_grequest $n]
	    if { $gRequest < $min } {
		set max $min
	    } else {
		break
	    }
	}
	
	#  Do a linear interpolation of the gTilt, given the cntr.
	if { $min == $max } {
	    set gTilt [ lindex $buf_gtilt $n ]
	} else {
	    set gtiltMax [ lindex $buf_gtilt $n ]
	    set gtiltMin [ lindex $buf_gtilt [expr $n-1] ]
	    set slope [ expr ( $gtiltMin - $gtiltMax ) / ( $min - $max ) ] ;
	    set xo [ expr ( $gtiltMax - ( $slope * $max ) ) ]
	    set gTilt [ expr ( $slope * $gRequest ) + $xo ]
	}
    }



    #############################################################
    #  Name: checkGratingFilterCombo
    #
    #  Description:
    #    Check if the submitted grating/filter combination is 
    #    valid.
    #############################################################
    #############################################################
    protected method checkGratingFilterCombo {instType grating filter} {
	set home $::env(GMMPS)
	set pass "FALSE"
	
	if {$instType == "F2" || $instType == "F2-AO" } {
	    set inFile [open "$home/config/F2_gfcombo.dat" r]

	    # Read valid F2 grating/filter combos.
	    while {[gets $inFile line] >= 0} {
		if {[string match *#* $line] == 0} {
		    set grating_test [lindex $line 0]
		    set filter_test  [lindex $line 1]
		    if {$grating == $grating_test && $filter == $filter_test} {
			set pass "TRUE"
			break						
		    }
		}
	    }
	    ::close $inFile
	    if {$pass == "FALSE"} {
		::cat::vmAstroCat::error_dialog "ERROR: This is not a valid Filter / grism combination for F2!"
	    }
	} elseif {($instType == "GMOS-N" || $instType == "GMOS-S")} {
	    # Suggestions and errors are checked in calcSpectrum() further below once the
	    # effective cut-on and cut-offs are known
	    set pass "TRUE"
	}

	return $pass
    }


    #########################################################################
    #  Name: spoc
    #
    #  Description:
    #   Delete file called mycatnameQM*
    #   Set Masknum, Filter, Grating, Bandwith,
    #   Bias, SpecLen, BiasType based on items set in this window.
    #   Rename mycatname.dat to mycatname.dat_temp
    #   Extract the exact field of view, and drop objects that aren't in it.
    #   This is written to mycatname.dat.  Delete the mycatname.dat_temp
    #   Execute the SPOC algorithm., writes to mycatnameQ
    #   Get all fits header info out of the catalog.
    #   Save all that info to catalog.cfg
    #   Then remove catalog.cfg.
    #   For each number of masks, write the *.cat files.
    #
    #########################################################################
    #########################################################################
    public method spoc {mycatname instType} {
	global ::spoc_autoexpansion ::pack_spectra

	# Erase message window in GUI
	$w_.masterBottomFrame.gmMM.03 delete 1.0 end

	set home $::env(GMMPS)
	set target_image_ image2
	
	# Load instrument specific configuration data.
	# (Right now just maximum slit width and length)
	set iConfigFilename $home/config/${instType}.cfg
	
	set instConfig [getInstrumentConfig $iConfigFilename]
	set maximumSlitWidth [lindex $instConfig 0]
	set maximumSlitLength [lindex $instConfig 1]
	
	#  Get information from the SPOC dialog
	set MaskNum [$w_.instSetup.maskSpinBox get]
	set minSpecDist [$w_.instSetup.minSpecDist get]
	$catClass_ gmmps_config_ [list "$instType-minSpecDist" ] [list $minSpecDist ]
	set wiggleVal [$w_.instSetup.wiggleSpinBox get]
	if {$wiggleVal > 50} {
	    ::cat::vmAstroCat::warn_dialog "The wiggle amount cannot be larger than 50%. Will reduce to 50%."
	    set wiggleVal 50
	    $w_.instSetup.wiggleSpinBox set 50
	}
	$catClass_ gmmps_config_ [list "$instType-length_offset_%" ] [list $wiggleVal ]
	set wiggleVal [format "%.2f" [expr $wiggleVal / 100.]]
	set Filter [$w_.instSetup.filter get]
	$catClass_ gmmps_config_ [list "$instType-filter" ] [list $Filter ]
	set Grating  [$w_.instSetup.grateorder get]
	$catClass_ gmmps_config_ [list "$instType-grating" ] [list $Grating ]

	# Warn about the R600
	if {$Grating == "R600"} {
	    set choice [::cat::vmAstroCat::my_choice_dialog "Note: The R600 grating is offered in classical observing mode, only." {OK Cancel} {OK} $w_]
	    if {$choice == "Cancel"} {
		return
	    }
	}
	
	# Check if the auto slit expansion minimum separation is valid
	if { $minSpecDist < 0.} {
	    set msg "The minimum slit separation for the slit expansion mode must be zero or greater."
	    ::cat::vmAstroCat::error_dialog $msg
	    return
	}
	if { $minSpecDist >= 0. && $minSpecDist < 4} {
	    set choice [::cat::vmAstroCat::my_choice_dialog "A minimum slit separation of less than 3-4 pixels\nmay cause problems in the automatic identification of\nspectral footprints during data reduction.\n\nIn this case, you would need to manually identify the location of the spectra." {OK Cancel} {OK} $w_]
	    if {$choice == "Cancel"} {
		return
	    }
	}


	# For GMOS only, pull in the user defined CWL wavelength. It could come from
	# the automatic calculation, but the user might have manually updated the value before
	# hitting the "make masks" button.
	if {$instType == "GMOS-N" || $instType == "GMOS-S"} {
	    set cwl_user [$w_.cwlButtonFrame.edit get]
	} elseif {$instType == "F2" || $instType == "F2-AO"} {
	    set cwl_user [getF2Wave $Grating $Filter]
	}

	$catClass_ gmmps_config_ [list "$instType-cenwave" ] [list $cwl_user]

	# Test if we are in MCAO mode (only relevant for F2).
	set aofold ""
	catch {
	    set aofold [$target_image_ fits get AOFOLD]
	}
	
	# Check that the grating/filter combination is valid.
	set gfTest [checkGratingFilterCombo $instType $Grating $Filter]
	if { $gfTest == "FALSE" } {
	    return
	}

	# Calculate the spectrum length
	# calcSpectrum returns a list; it sets the global var SpecLen
	if {[catch {set outlist [calcSpectrum $instType "dontupdate" $cwl_user]} msg]} {
	    ::cat::vmAstroCat::error_dialog $msg 
	    return
	}
	
	if {$outlist == ""} {
	    return
	}

	# Extract the output of calcSpectrum()
	set Spec_lmin [lindex $outlist 0]
	set Spec_lmax [lindex $outlist 1]
	set Spec_disp [lindex $outlist 2]
	set cwl_ideal [expr {round( [lindex $outlist 3])}]

	if { $instType == "GMOS-N" || $instType == "GMOS-S" } {
	    
	    # Display choice dialog in case of order overlap
	    if {$Grating != "R831_2nd"} {
		set orderoverlap_begin [expr round(2.*$Spec_lmin)]
		if {$orderoverlap_begin < $Spec_lmax} {
		    set choice [::cat::vmAstroCat::my_choice_dialog "2nd order overlap occurs for this configuration above $orderoverlap_begin nm." {OK Cancel} {OK} $w_]
		    if {$choice == "Cancel"} {
			return
		    }
		}
	    } else {
		set orderoverlap_end [expr round( $Spec_lmax/2.)]
		if {$orderoverlap_end > $Spec_lmin && $orderoverlap_end > 360} {
		    set choice [::cat::vmAstroCat::my_choice_dialog "1st order overlap occurs for this configuration below $orderoverlap_end nm." {OK Cancel} {OK} $w_]
		    if {$choice == "Cancel"} {
			return
		    }
		}
	    }

	    if {$Grating == "R150"} {
		set choice [::cat::vmAstroCat::my_choice_dialog "The R150 grating produces relatively short spectra, in particular if combined with a filter. GMMPS then places several spectra next to each other in dispersion direction, with cleanly separated first orders.\nThis is known as \"packing\".\n\nIn case of \"packing\" and the R150, the second orders of slits in the right half of GMOS may overlap the first orders of slits in the left half. The second order of the R150 is very faint (about 1% of the first order) and you may decide to ignore it.\n\nLikewise, the zero-th order of the slits in the left half of the detector may overlap the first orders of the slits in the right half of the detector. The zero-th order is bright, but also very compact." {{OK, pack spectra} {Do not pack spectra - single spectrum only} Cancel} {OK, pack spectra} $w_]
		if {$choice == "Cancel"} {
		    return
		}
		if {$choice == "Do not pack spectra - single spectrum only"} {
		    set pack_spectra 0
		}
	    }

	    # Some WARNINGS and ERRORS
	    if { $cwl_user < 350 || $cwl_user > 1050} {
		error_dialog "Central wavelength outside useful range for GMOS."
		return
	    } elseif { $Grating == "B1200" && $cwl_user > 900 } {
		::cat::vmAstroCat::error_dialog "Low sensitivity. Use the R831 instead."
		return
	    } elseif { $Grating == "R831" && $cwl_user < 550 } {
		::cat::vmAstroCat::error_dialog "Low sensitivity. Use the B1200 instead, or the R831 in 2nd order mode."
		return
	    }

	    # Exclude REALLY NONSENSICAL combinations
	    if {$Grating == "B1200" && $Spec_lmin >= 700} {
		::cat::vmAstroCat::error_dialog "Use R831 or R400 instead of B1200 with this filter and CWL!"
		return
	    } elseif {$Grating == "B600" && $Spec_lmin >= 800} {
		::cat::vmAstroCat::error_dialog "Use R400 or R831 instead of B600 with this filter and CWL!"
		return
	    } elseif {$Grating == "R831" && $Spec_lmax <= 540} {
		::cat::vmAstroCat::error_dialog "Use B1200 or B600 instead of R831 with this filter and CWL!"
		return
	    } elseif {$Grating == "R400" && $Spec_lmax <= 540} {
		::cat::vmAstroCat::error_dialog "Use B600 or B1200 instead of R400 with this filter and CWL!"
		return
	    } elseif {$Grating == "R600" && $Spec_lmax <= 540} {
		::cat::vmAstroCat::error_dialog "Use B600 or B1200 instead of R600 with this filter and CWL!"
		return
	    }
	}
	
	#  Check to see if any of the Minimal ODF catalog files exist
	#  already, and if they do, request overwrite, or different name.
	set newname ""
	set done 0
	for {set n 1} {$n <= $MaskNum} {incr n 1} {
	    set testname [file rootname $mycatname]ODF$n.fits
	    if {[file exists $testname] } {
		while { $done != 1} {
		    set testnamedir  [file dirname $testname]
		    set testnametail [file tail $testname]
		    set choice [::cat::vmAstroCat::my_choice_dialog "$testnametail\n\n    already exists in\n\n$testnamedir" {{Overwrite} {Enter New Filename} {Choose} Cancel} {Overwrite} $w_]
		    if {$choice == "Enter New Filename"} {
			focus -force $w_
			set newname [::cat::vmAstroCat::my_input_dialog "New name for ODF:\n\n\"ODF<n>.fits\" will be appended" $w_]
			focus -force $w_
			if { $newname != "" } {
			    set done 1
			}
		    } elseif { $choice == "Choose"} {
			focus -force $w_
			set newname [file tail [filename_dialog [pwd] *.fits $w_]]
			focus -force $w_
			if { $newname != "" } {
			    set done 1
			}
		    } elseif { $choice == "Cancel" } {
			return
		    } else {
			set done 1
		    }
		}
		break
	    }
	}

	#  Process the new file name (if any)
	if { $newname != "" } {
	    # remove any .fits
	    set newname [file rootname [file tail $newname]]
	    # remove ODF if string ends in that
	    set length [string length $newname]
	    set rest [string range $newname [expr $length-3] $length]
	    if {$rest == "ODF"} {
		set newname [string range $newname 0 [expr $length-4]]
	    } else {
		# try ODF1...9
		for {set index 1} {$index < 10} {incr index} {
		    set rest [string range $newname [expr $length-4] $length]
		    set comp "ODF"
		    if {$rest == [append comp $index]} {
			set newname [string range $newname 0 [expr $length-5]]
			break
		    }
		}
	    }
	    # Add path
	    set addOn ""
	    catch {set addOn [file dirname $mycatname]}
	    set newname $addOn/$newname
	} else {
	    set newname [file rootname $mycatname]
	}

	catch {file delete ${newname}ODF*.cat}
	catch {file delete ${newname}ODF*.fits}

	# Set the Algorithm chosen.
	if {$spoc_autoexpansion == 1} {
	    set BiasType "M"
	} else {
	    set BiasType "N"
	}

	#  Update the screen
	update idletasks
	
	if {$DISPDIR == "horizontal"} {
	    set maximumSlitsizeX $maximumSlitWidth
	    set maximumSlitsizeY $maximumSlitLength
	} else {
	    set maximumSlitsizeX $maximumSlitLength
	    set maximumSlitsizeY $maximumSlitWidth
	}
	
	#  Prepare the temp catalog file, which is a copy of the 
	#  catalog file, but with only specific columns in it.
	#  Do this by calling function 'myprint' in vmTableList.tcl
	#
	# NOTE: This method also checks for invalid priorities and for
	# slits exceeding maximum width. myprintMessage will contain a
	# warning message for the user if slits were dropped for either
	# reason.

	# last three arguments are not used in this call to myprint
	set myprintMessage [$itk_option(-resultz) myprint $itk_option(-catalog) \
				$maximumSlitsizeX $maximumSlitsizeY]
	
	#  Extract the field of view, and drop objects that are outside. Saves to mycatname.dat.
	#  Remove mycatname.dat_temp
	# Print out to frame the results
	set out1 ""
	
	set fovfilename $home/config/${instType}_current_fov.dat

	if {[catch {
	    set out1 [exec gmmps_fov \
			  [file rootname $mycatname].dat_temp \
			  [file rootname $mycatname].dat \
			  $fovfilename $PIXSCALE $CRPIX1 $CRPIX2]
	} msg ]} {
	    ::cat::vmAstroCat::error_dialog "ERROR while getting field of view: $msg"
	    return
	}

	file delete [file rootname $mycatname].dat_temp

	# Add the spec dimensions to the output file
	set msg [append_specdims [file rootname $mycatname].dat $Spec_lmin $Spec_lmax $instType $Grating $Filter $cwl_user]
	if {$msg == "ERROR"} {
	    ::cat::vmAstroCat::error_dialog "Some of the targets could not have their spectra dimensions calculated.\nThis is most likely a bug in GMMPS.\n Please submit a helpdesk ticket at https://www.gemini.edu/sciops/helpdesk."
	    return
	}

	# Erase message window in GUI
	$w_.masterBottomFrame.gmMM.03 delete 1.0 end

	# Check acq stars for proper motion!
	file delete acq_propmotion.dat
	exec awk {{if ($12==0) {print $2, $3, ";", $1}}} [file rootname $mycatname].dat > acq_propmotion1.dat
	catch {exec get_propermotion.sh acq_propmotion1.dat}
	set propmotions   [exec cat acq_propmotion.dat]
	set acqmagnitudes [exec cat acq_magnitudes.dat]
	# Open output
	set msg ""
	set quit 0
	set nstars 0
	catch { set acq_pm_output [open "acq_propmotion.dat" r] }
	while {[gets $acq_pm_output line] >= 0} {
	    set ID   [lindex $line 0]
	    set pmRA [lindex $line 1]
	    set pmDE [lindex $line 2]
	    incr nstars
	    if {$pmRA>250 || $pmDE>250 || $pmRA<-250 || $pmDE<-250} {
		set msg [append msg "ID $ID: $pmRA $pmDE (too high)\n"]
		set quit 1
	    } else {
		if {$pmRA>100 || $pmDE>100 || $pmRA<-100 || $pmDE<-100} {
		    set msg [append msg "ID $ID: $pmRA $pmDE (high)\n"]
		}
	    }
	}
	::close $acq_pm_output
	file delete acq_propmotion1.dat
	file delete acq_magnitudes.dat

	if {$msg != ""} {
	    set out "HIGH acq star proper motions!\n"
	    set out [append out "STAR dRA dDEC \[mas/yr\]:\n"]
	    set out [append out "---------------------------------\n"]
	    set out [append out $msg]
	    if {$quit == 0} {
		::cat::vmAstroCat::warn_dialog $out
	    } else {
		::cat::vmAstroCat::error_dialog $out
		return
	    }
	    # Print statement about proper motion stars in message window
	    $w_.masterBottomFrame.gmMM.03 insert end "HIGH proper motions for some acq stars (>100 mas/yr):\n"
	    $w_.masterBottomFrame.gmMM.03 insert end "ID  dRA  dDEC \[mas/yr\]\n"
	    $w_.masterBottomFrame.gmMM.03 insert end "----------------------\n"
	    $w_.masterBottomFrame.gmMM.03 insert end "$propmotions\n\n"
	} else {
	    # there's a time-out of 6s for the CDS server in get_propermotion.sh
	    if {$nstars == 0} {
		::cat::vmAstroCat::warn_dialog "Could not find proper motion entries in PPMXL for the acquisition stars, or the server is taking too long to respond.\nContinue with mask design."
	    } else {
		# Print statement about proper motion stars in message window
		$w_.masterBottomFrame.gmMM.03 insert end "GOOD! Proper motions for acq stars <100 mas/yr:\n"
		$w_.masterBottomFrame.gmMM.03 insert end "ID  dRA  dDEC \[mas/yr\]\n"
		$w_.masterBottomFrame.gmMM.03 insert end "----------------------\n"
		$w_.masterBottomFrame.gmMM.03 insert end "$propmotions\n\n"
	    }
	}

	# Print fov results to GUI.
	$w_.masterBottomFrame.gmMM.03 insert end $out1
	# Also print any warnings about slits dropped by method myprint.
	$w_.masterBottomFrame.gmMM.03 insert end "$myprintMessage\n\n"
	
	#  Execute the SPOC algorithm.
	#  Passing in mycatname.dat(output of gmmps_fov), write to 
	#  mycatnameODF#.cat (these are MinimalODFs), and assoc. fits files.

	set output ""
	set gmmargs ""

	# Is this a N&S mask?
	if {$itk_option(-spocbandsargs) != ""} {
	    # Get the shuffle mode
	    set shuffleMode [lindex $itk_option(-spocbandsargs) 0]
	    
	    # Read the arguments depending on the shuffleMode
	    if {$shuffleMode == "microShuffle"} {
		set slitLength [lindex $itk_option(-spocbandsargs) 1]
		set shufflePx  [lindex $itk_option(-spocbandsargs) 2]
		set shuffleAmt [lindex $itk_option(-spocbandsargs) 3]
		set nodAmt     [lindex $itk_option(-spocbandsargs) 4]
		set gmmargs    [list $itk_option(-binning) $itk_option(-spocbandsargs)]
		set gmmargs    [string map {" " _} $gmmargs]
	    } else {
		set bandHeight [lindex $itk_option(-spocbandsargs) 1]
		set shufflePx  [lindex $itk_option(-spocbandsargs) 2]
		set shuffleAmt [lindex $itk_option(-spocbandsargs) 3]
		set yoffset    [lindex $itk_option(-spocbandsargs) end-1]
		set numBands   [lindex $itk_option(-spocbandsargs) end]
		set gmmargs    [list $itk_option(-binning) $itk_option(-spocbandsargs)]
		set gmmargs    [string map {" " _} $gmmargs]
		set bandYs     [list]
		for {set i 0} {$i < $numBands} {incr i} {
		    set argindex [expr $i+4]
		    lappend bandYs [lindex $itk_option(-spocbandsargs) $argindex]
		}
	    }
	}

	# Run gmMakeMasks
#	puts "gmMakeMasks [file rootname $mycatname].dat ${newname}ODF $instType $fovfilename $PIXSCALE $MaskNum $BiasType $DISPDIR $DET_IMG_ $DET_SPEC_ $RA $DEC $CRPIX1 $CRPIX2 $minSpecDist $wiggleVal $pack_spectra $gmmargs"

	if {[catch {
	    set output \
		[exec gmMakeMasks \
		     [file rootname $mycatname].dat \
		     ${newname}ODF $instType \
		     $fovfilename $PIXSCALE $MaskNum \
		     $BiasType $DISPDIR $DET_IMG_ $DET_SPEC_ \
		     $RA $DEC $CRPIX1 $CRPIX2 $minSpecDist \
		     $wiggleVal $pack_spectra $gmmargs]
	} msg]} {
	    ::cat::vmAstroCat::error_dialog "ERROR creating mask file(s) : $msg"
	    return
	}
	
	set SpecLengthDisplay [format "%.1f" [expr $SpecLen / 10.]]

	$w_.masterBottomFrame.gmMM.03 insert end $output

	file delete [file rootname $mycatname].dat

	#  Open a mycatname.log and save results of SPOC there
	set log ""
	catch { set log [open [file rootname $mycatname]ODF.log w] }
	
	puts $log "########################## FIELD OF VIEW LOG ##########################"
	puts $log "$out1"
	puts $log "########################## SPOC LOG ##########################"
	puts $log "--------------------------------------------------------------"
	puts $log "Input parameters of SPOC"
	puts $log "--------------------------------------------------------------"
	puts $log "Input catalog name: [file rootname $mycatname].dat"
	puts $log "Minimal Object Table Files: ${newname}ODF<n>.cat"
	puts $log "Filter: $Filter"
	puts $log "Grating: $Grating"
	puts $log "CWL: $cwl_user nm"
	puts $log "Anamorphic Factor: [format "%.4f" $anaMorphic]"
	puts $log "Spectrum Length: $SpecLengthDisplay nm"
	puts $log "Pixel Scale: [format "%.4f" $PIXSCALE] arcsec/pixel"
	puts $log "Number of masks: $MaskNum"
	puts $log "SPOC mode: $BiasType"
	puts $log "--------------------------------------------------------------"
	puts $log "OUTPUT OF SPOC"
	puts $log "--------------------------------------------------------------"
	puts $log "$output"
	puts $log "--------------------------------------------------------------"
	
	#  Get all fits header info out of the catalog.
	#  Save all that info to mycatname.cfg
	set buffer ""
	set myname ""
	set mydate ""
	catch { set myname [exec whoami ] }
	catch { set mydate [exec date -u "+%Y-%m-%dT%H:%M:%S" ] }
	catch { set buffer [exec grep #fits ${newname}ODF1.cat] }

	set cfg [open ${newname}.cfg w]

	set specwidth [expr $Spec_lmax - $Spec_lmin]
	set lowerfrac [expr {round (100.*($cwl_user - $Spec_lmin)) / $specwidth}]
	set upperfrac [expr {round (100.*($Spec_lmax - $cwl_user)) / $specwidth}]
	
	# Show info dialog if CWL outside wavelength range
	if {$instType == "GMOS-N" || $instType == "GMOS-S"} {
	    if {$cwl_user < $Spec_lmin || $cwl_user > $Spec_lmax} {
		::cat::vmAstroCat::warn_dialog "CWL outside the filter bandpass! This means that significant parts of the spectrum will be lost beyond the detector boundaries. This is permissible in special cases, such as e.g. when a certain wavelength range is desired to fall on a particular CCD. In general, however, this CWL/filter combination is a bad choice. A better CWL choice for this filter would be $cwl_ideal nm."
	    } elseif {($lowerfrac < 25 || $upperfrac < 25) && $Filter != "Open"} {
		set minfrac [expr {round([min $lowerfrac $upperfrac])}]
		# Show info dialog if CWL within 25% of spectral boundary
		# Only if no filter was chosen, as gratings have a very wide range
		# and the chosen CWL likely is on purpose. We isseu a warning elsewhere 
		# if the CWL and grating combination is inefficient.
		::cat::vmAstroCat::warn_dialog "CWL within $minfrac% of the spectral boundaries ($Spec_lmin / $Spec_lmax nm) selected by the filter! The spectra will be shifted to one side of the detector array, possibly causing unnecessary wavelength loss. Maybe this is what you want, check the spectrum display in the ODF window. A better CWL choice would be $cwl_ideal nm, or you pick a different filter matching the chosen CWL."
	    }
	}

	puts $cfg $buffer
	puts $cfg "#fits FILTSPEC= '$Filter'"
	puts $cfg "#fits GRATING = '$Grating'"
	puts $cfg "#fits WAVELENG= $cwl_user"
	puts $cfg "#fits SPEC_LEN= $SpecLen"
	puts $cfg "#fits SPEC_MIN= $Spec_lmin"
	puts $cfg "#fits SPEC_MAX= $Spec_lmax"
	puts $cfg "#fits SPEC_DIS= $Spec_disp"
	puts $cfg "#fits ANAMORPH= [format %.4f $anaMorphic]"
	puts $cfg "#fits SPOCMODE= '$BiasType'"
	puts $cfg "#fits GMMPSVER= '$gmmps_version'"
	puts $cfg "#fits MASK_PA = $PA"
	puts $cfg "#fits PERS_ODF= '$myname'"
	puts $cfg "#fits DATE_ODF= '$mydate'"
	puts $cfg "#fits FILE_OT = '[file rootname [file tail $mycatname]].fits'"
	puts $cfg "#fits ACQMAG  = '$acqmagnitudes'"
	
	::close $cfg

	#  Execute gmCat2Fits, which will translate Minimal ODF catalog
	#  files (SPOC output) to Minimal ODF Fits file.
	#  Then remove mycatname.cfg
	#  Add output of gmCat2Fits to the log file.
	puts $log "OUTPUT OF CREATING MINIMAL ODF FITS FILE"
	puts $log "--------------------------------------------------------------"
	set out2 ""

	if {[catch {exec gmCat2Fits ${newname} ${newname}ODF $MaskNum } msg]} {
	    puts $log "$msg"
	}
	
	puts $log "--------------------------------------------------------------"
	::close $log
	
	catch {file delete $newname.cfg}

	# Delete the temporary .cat files as they are still incomplete in terms of header information
	# Create them from the FITS cats instead, just in case someone wants them right away.
	for {set n 1} {$n <= $MaskNum} {incr n 1} {
	    catch {file delete ${newname}ODF${n}.cat}
	    if {[catch {exec gmFits2Cat ${newname}ODF${n}} msg]} {
		::cat::vmAstroCat::error_dialog "$msg" 
		return -1
	    }
	}
    }



    #########################################################################
    #  Name: append_specdims
    #
    #  Description:
    #  Appends the spectra dimensions to the input file of gmMakeMasks
    #
    #########################################################################
    #########################################################################    
    public method append_specdims {infile spec_lmin spec_lmax \
				       instType grating filter spect_cwl} {
	
	catch {file delete gemwm.input}
	catch {file delete gemwm.output}

	if {$instType == "GMOS-N"} {
	    set nativeScale 0.0807
	} elseif {$instType == "GMOS-S"} {
	    set nativeScale 0.0800
	} elseif {$instType == "F2"} {
	    set nativeScale 0.1792
	} elseif {$instType == "F2-AO"} {
	    # THIS NUMBER NEEDS TO BE VERIFIED!!!
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

	set xoffset 0.0
	set yoffset 0.0
	if {$instType == "GMOS-S" && $NAXIS1 == "6218" && $NAXIS2 == "4608"} {
	    set xoffset 298.63
	    set yoffset -11.74
	}
	# needs fine-tuning
	if {$instType == "GMOS-N" && $NAXIS1 == "6218" && $NAXIS2 == "4608"} {
	    set xoffset 298.63
	    set yoffset -11.74
	}
	
	#################################
	# Create the gemwm input file
	# Convert wavelengths to A
	# This creates gemwm.input:
	#################################
	exec create_gemwm_input.sh $infile $PIXSCALE [expr $spec_lmin*10] \
	    [expr $spec_lmax*10] $instType $corrfac $xoffset $yoffset

	###########
	# Run gemwm
	###########
	
	if {($instType == "F2" || $instType == "F2-AO") && $grating == "R3000"} {
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

	
	################################################################################
	# Extract gemwm output, in particular the beginning and endpoints of the spectra
	################################################################################

	# Open gemwm output
	catch { set gemwm_output [open "gemwm.output" r] }
	
	# Wavelength models are for 1x1 binning. If the current image has a different plate scale, then
	# we need to transform the output of gemwm.
	set corrfac [expr $nativeScale / $PIXSCALE]

	# spec_min and spec_max will be written to a tmp file:
	set specdims_file [open "specdim.dat" w ]

	while {[gets $gemwm_output line] >= 0} {
	    set spec_min [lindex $line 7]
	    set spec_max [lindex $line 8]

	    # Model calculations were done for 1x1 binning; correct if images have different pixel scale.
	    # HACK! Pseudo-images from GMOS-S Hamamatsu were still in the
	    # GMOS-S EEV geometry and pixel scale for a long time.
	    # This takes care of the pixel scale, too.
	    # WARNING: using the ::cat::vmAstroCat calls below requires the existence of several
	    # global vars (e.g. DETDIM etc, which were passed into spoc using the "globallist" argument
	    # in the constructor... long live tclTk; want sth easy, have to make it difficult elsewhere)
	    if {($instType == "GMOS-S" && $NAXIS1 == "6218" && $NAXIS2 == "4608") || \
		($instType == "GMOS-N" && $NAXIS1 == "6218" && $NAXIS2 == "4608") } {
		set spec_min [::cat::vmAstroCat::transform_gmos_x_new2old $spec_min $nativeScale $instType]
		set spec_max [::cat::vmAstroCat::transform_gmos_x_new2old $spec_max $nativeScale $instType]
	    } else {	
		set spec_min [expr $spec_min*$corrfac]
		set spec_max [expr $spec_max*$corrfac]
	    }

	    # truncate at the detector boundary
	    set spec_min [::cat::vmAstroCat::truncate_spec $spec_min "blue"]
	    set spec_max [::cat::vmAstroCat::truncate_spec $spec_max "red" ]	    

	    # write to output
	    # spec_max is the red wavelength cutoff (in pixel coords)
	    # spec_min is the blue wavelength cutoff (in pixel coords)
	    # spec_max < spec_min for both GMOS and F2
	    # for gmmakeMasks we need it in this order:
	    puts $specdims_file "$spec_max $spec_min"
	}

	::close $specdims_file
	
	##############################################################
	# Append the specdim columns to the input file for gmMakeMasks
	##############################################################

	# Leave if files don't have the same length
	set n1 [exec wc -l specdim.dat | awk {{print $1}} ]
	set n2 [exec wc -l $infile | awk {{print $1}} ]
	if {$n1 != $n2} {
	    return "ERROR"
	}
	
	# give skycat some time to catch up
	exec paste $infile specdim.dat > tmp.dat
	file rename -force tmp.dat $infile
	catch {file delete gemwm.input}
	catch {file delete gemwm.output}
	catch {file delete specdim.dat}
	catch {file delete tmp.dat}

	return
    }

    #########################################################################
    # Retrieve F2 wavelength based on selected filter. 
    #########################################################################
    method getF2Wave {grate filter} {	
	set home $::env(GMMPS)
	set cenWave ""
	set inFile [open "$home/config/F2_gfcombo.dat" r]
	set cenWav ""

	# Scan for correct filter and input central wavelength
	while {[gets $inFile line] >= 0} {
	    if {[string match *#* $line] == 0} { 
		set grate_test  [lindex $line 0]
		set filter_test [lindex $line 1]
		if {$grate_test == $grate && $filter_test == $filter} {
		    set cenWav [lindex $line 3]
		    break
		}
	    }
	}
	
	::close $inFile
	
	if {$cenWav == ""} {
	    set cenWav 1300
	}
	
	return $cenWav
    }

    
    #########################################################################
    #  Name: wave_config
    #
    #  Description:
    #	Sends wavelength information to the gmmps configuration file.
    #
    #########################################################################
    #########################################################################    
    protected method wave_config {key value} {
	$catClass_ gmmps_config_ [concat $key] [concat $value]
    }

    
    #########################################################################
    #  Name: getInstrumentConfig
    #
    #  Description:
    #     Load instrument-specific configuration data. 
    #     Right now only maximum slit width is loaded, but things are set up
    #     so more config values can be easily added.
    #
    #########################################################################
    #########################################################################    
    protected method getInstrumentConfig {instConfigFilename} {
	set configStream [open $instConfigFilename r]
	
	set maxSlitWidth 1000000
	set maxSlitLength 1000000
	
	while {[gets $configStream line] >= 0} {
	    if {[string index $line 0] == "#" || \
		    $line == ""} {
		continue
	    } elseif {[lindex $line 0] == "max_slit_width"} {
		set maxSlitWidth [lindex $line 1]
	    } elseif {[lindex $line 0] == "max_slit_length"} {
		set maxSlitLength [lindex $line 1]
	    }
	}
	::close $configStream
	
	return [list $maxSlitWidth $maxSlitLength]
    }


    #########################################################################
    #  Name: calcSpectrum
    #
    #  Description:
    #  Calculates the spectrum length
    #
    #########################################################################
    #########################################################################
    public method calcSpectrum { instType update_cwl {cwl_user ""}} {

	# WARNING! This calculates the IDEAL CWL, i.e. the mid point between the
	# spectral cut-on and cut-off, and displays it in the line edit field
	# $w_.cwlButtonFrame.edit . The user may override this value by manually 
	# entering a new one before hitting the "make masks" button.
	# For clarity, here I store the CWL in the variable 'cwl_ideal'
	
	set home $::env(GMMPS)
	set subdir "/config/transmissiondata/"

	#  Get information selected from the pop-up
	set Filter [$w_.instSetup.filter get]
	set Grating [$w_.instSetup.grateorder get]
	
	set FilterTitle $Filter

	if {$instType != "F2" && $instType != "F2-AO" } {
	    set cwl_ideal  [$w_.cwlButtonFrame.edit get]
	} else {
	    set cwl_ideal [getF2Wave $Grating $Filter]
	}
	
	# Determine filter name; using globals nfilter and buf_filter, etc;
	# note to self: hate globals
	for {set n 0} {$n < $nfilter} {incr n 1} {
	    if {$Filter == "[lindex [lindex $buf_filter $n] 0]"} {
		set filterfile $home$subdir${instType}_${Filter}.txt
	    }
	}
	# Determine grating name and number of rulings (gnm)
	for {set n 0} {$n < $ngrate} {incr n 1} {
	    if {$Grating == "[lindex [lindex $buf_grate $n] 0]"} {
		set gnm [lindex [lindex $buf_grate $n] 1]
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

	# Update the throughput plot
	::cat::vmAstroCat::loadThroughputPlot $lambda_min $lambda_max $title
	
	# gRequest is the CWL times the number of rulings per nm;
	# NOTE: here we must use the value from the line edit, as the user might want to
	# override the automatic value
	set gRequest [ expr $cwl_ideal * $gnm / pow(10,6)]   
	
	#  Determine gRequest, gTilt, Anamorphic factor, linear disperson.
	# gTilt is a global variable
	if {($instType == "GMOS-N" || $instType == "GMOS-S")} {
	    calcGTilt  $gRequest 
	} else {
	    set gTilt 0
	}

	set rad [expr 3.14159/180.]
	
	# Determine the spectral resolution (nm/pixel)
	set dpix 0.0

	if {($instType == "GMOS-N" || $instType == "GMOS-S")} {
	    set anaMorphic \
		[expr sin(($gTilt + 50.0) * $rad) / sin($gTilt * $rad)]
	    # dpix: I don't understand ALL of it, e.g. the 81.0 and the 3600.
	    # In any case, it delivers reasonable nm/pixel values as tabulated on our web pages.
	    # It is also the same as in the IRAF gscut.cl task, so be it     -mischa
	    set dpix \
		[expr $anaMorphic * $PIXSCALE * $cwl_ideal * 81.0 * sin($gTilt * $rad) / \
		     (3600.0 / $rad * $gRequest) ]
	}
	
	if {$instType == "F2" || $instType == "F2-AO"} {
	    set anaMorphic 0.99
	    # Load dpix from a file based on the grating/filter combination.
	    # F2 does not rotate the grating, therefore the dpix are fixed
	    catch { set dpixFile [open $home/config/F2_gfcombo.dat r] }
	    while {[gets $dpixFile line] >= 0} {
		if {[string match *#* $line] == 0} {
		    if { [lindex $line 0] == $Grating && [lindex $line 1] == $Filter} {
			set dpix [lindex $line 2]
			break
		    }
		}
	    }
	    
	    # If in AO mode dpix is halved.
	    if {[string match *AO $instType] != 0} {
		set dpix [expr $dpix * 0.5 ]
	    }
	}

	if {$dpix == 0.0} {
	    if {$instType == "GMOS-N" || $instType == "GMOS-S"} {
		::cat::vmAstroCat::error_dialog "ERROR: Could not determine spectral resolution!"
		return -1
	    } else {
		::cat::vmAstroCat::error_dialog "ERROR: This is not a valid Filter / grism combination for F2!"
		return -1		
	    }
	}

	# Calculate the length of the spectrum
	set SpecLen [expr ($lambda_max - $lambda_min) / $dpix]
	set SpecLenDisplay [format "%.1f" $SpecLen]

	if {$SpecLen < 10} {
	    ::cat::vmAstroCat::error_dialog "ERROR: Spectrum length smaller than 10 pixel!"
	    return -1
	}

	if {$cwl_user == ""} {
	    set cwl $cwl_ideal
	} else {
	    set cwl $cwl_user
	}
	
	# Update the CWL entry field when Grating/Filter has changed, and if
	# the AutoCWL button was pressed. Do NOT update when the "make mask (ODF)" 
	# button is pressed, to give the user the option of having the last word
	if {$update_cwl == "update" && ($instType == "GMOS-N" || $instType == "GMOS-S")} {
	    $w_.cwlButtonFrame.edit configure -value $cwl_ideal
	    $w_.cwlButtonFrame.button configure -bg #bbf
	} elseif {$update_cwl != "update" && ($instType == "GMOS-N" || $instType == "GMOS-S")} {
	    set prev_cenwave [$catClass_ gmmps_config_ [list "$instType-cenwave" ]]
	    if {$prev_cenwave != $cwl_ideal} {
		$w_.cwlButtonFrame.button configure -bg #fbb
	    }
	}

	set lmin [format "%.1f" $lambda_min]
	set lmax [format "%.1f" $lambda_max]
	set dpix [format "%.4f" $dpix]
	$w_.throughput.label configure -text "Range: $lmin - $lmax nm"

	return [list $lambda_min $lambda_max $dpix $cwl_ideal]
    }

    
    #########################################################################
    #  Name: bias_change
    #
    #  Description:
    #     Check for a change in slit expansion mode, write to config file.
    #########################################################################
    #########################################################################
    protected method bias_change {key} {
	global ::spoc_autoexpansion
	wave_config [list $key ] [list $spoc_autoexpansion ]
    }
    
    
    #########################################################################
    #  Name: cancel
    #
    #  Description:
    #     close
    #
    #########################################################################
    #########################################################################    
    public method cancel {mycatname } {
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

	set instType $itk_option(-instType)
	# Update the gmmps config file
	set Filter [$w_.instSetup.filter get]
	$catClass_ gmmps_config_ [list "$instType-filter" ] [list $Filter ]
	set Grating  [$w_.instSetup.grateorder get]
	$catClass_ gmmps_config_ [list "$instType-grating" ] [list $Grating ]
	if {$instType == "GMOS-N" || $instType == "GMOS-S"} {
	    set cwl_user [$w_.cwlButtonFrame.edit get]
	} elseif {$instType == "F2" || $instType == "F2-AO"} {
	    set cwl_user [getF2Wave $Grating $Filter]
	}
	$catClass_ gmmps_config_ [list "$instType-cenwave" ] [list $cwl_user]

	# delete temporary throughput files
	#catch {file delete ".throughput.png"}
	catch {file delete ".total_system_throughput.dat"}
	destroy $w_ 
    }


    # Contains the type of file loaded in, Object Tbl, Master OT , or fitsFile 
    itk_option define -catalog catalog Catalog "" 

    # N&S mode
    itk_option define -spocbandsargs spocbandsargs SpocBandsArgs ""
    
    # Options indicating col's that exist
    itk_option define -resultz resultz Resultz ""
    itk_option define -binning binning Binning 1

    protected variable catClass_
    protected variable config_file_ 
    protected variable DET_IMG_ ""
    protected variable DET_SPEC_ ""

    protected common nfilter
    protected common ngrate
    protected common ngtilt
    protected common buf_filter
    protected common buf_grate
    protected common buf_grequest
    protected common buf_gtilt
    protected common gTilt
    protected common anaMorphic
    protected common lambda_min
    protected common lambda_max
    protected common SpecLen
    protected common dpix
    protected common gRequest
    protected common gmmps_version

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
}
