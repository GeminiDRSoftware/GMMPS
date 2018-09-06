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

# $Id: band_def_UI.tcl,v 1.5 2013/02/04 18:38:05 gmmps Exp $

itcl::class gmmps::band_def_UI {
    inherit util::TopLevelWidget
    
    #  constructor
#    constructor catClass catname pixs binning \
#		     resultz config_file det_img det_spec ra_img dec_img \
#		     crpix1 crpix2 naxis1 naxis2 dispDirection posangle instType
    constructor {catClass catname binning resultz config_file det_img det_spec \
		     instType globallist} {
			 global vsDebugLevel
			 global EXTRABANDSEP
			 # extra separation between bands of two pixels
			 set EXTRABANDSEP 0
			 set vsDebugLevel 1
			 set args {}
			 eval itk_initialize $args
			 set itk_option(-catalog) $catname
			 set itk_option(-binning) $binning
			 set itk_option(-resultz) $resultz
			 set itk_option(-instType) $instType
			 set config_file_ $config_file
			 set catClass_ $catClass
			 set DET_IMG_ $det_img
			 set DET_SPEC_ $det_spec
			 
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
			 set globlist $globallist
			 
			 set gmmps_version 0.0
			 set home_ $::env(GMMPS)
			 catch {set channel [open $home_/VERSION r]}
			 catch {gets $channel gmmps_version}
			 catch {::close $channel }
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
	wm title $w_ "Nod And Shuffle Parameters ($itk_option(-number))"
	wm iconname $w_ "N&S Definition ($itk_option(-number))"
	set home $::env(GMMPS)
	
	# Populate defaultBandHt_ and defaultBandHtNames_ lists.
	setDefaultBandHt 
	
	make_layout
    }

    #############################################################
    #  Name: make_layout
    #
    #  Description: 
    #    Draw the spoc box.
    #############################################################
    #############################################################    
    protected method make_layout {} {
	
        add_widgets
        add_buttons
        make_short_help
        
        update idletasks
        
        # Try to load previous N&S mode from config file, and switch to that 
        # mode if appropriate.
        set prevShuffleMode [config_get_values "shuffle_mode" ]
       	if {$prevShuffleMode == "bandShuffle"} {
	    global shuffleMode
	    set shuffleMode "bandShuffle"
	    
	    $w_.option.bandShuffle select
	    switchShuffleMode "startup"
	    #validateBandDef "startup"
	    calcBandAry
	    
	} else {
	    #validateBandDef "startup"
        }
    }
    
    
    #############################################################
    #  Name: add_widgets
    #
    #  Description:
    #    Draw widgets
    #############################################################
    #############################################################
    protected method add_widgets {} {
	global EXTRABANDSEP

	pack [frame $w_.option -borderwidth 2 -relief raised] \
	    -side top -fill x
	
	pack [radiobutton $w_.option.microShuffle \
		  -text "Micro-shuffle Mode" \
		  -variable shuffleMode \
		  -value "microShuffle" \
		  -command [code $this switchShuffleMode]] \
	    -side top -anchor w
	
	pack [radiobutton $w_.option.bandShuffle \
		  -text "Band-shuffle Mode" \
		  -variable shuffleMode \
		  -value "bandShuffle"  \
		  -command [code $this switchShuffleMode]] \
	    [frame $w_.option.bandModeFrame] \
	    -side top -anchor w

	pack [button $w_.calcBands \
		  -text "Recalculate Bands" \
		  -command [code $this calcBandAry]] \
	    [button $w_.clearBands \
		 -text "Hide Bands" \
		 -command [code .skycat1.image.imagef.canvas delete bandrects]] \
	    [button $w_.defaults \
		 -text "Restore Defaults" \
		 -command [code $this restoreDefaults ]] \
	    -side left -anchor w -in $w_.option.bandModeFrame

	$w_.option.microShuffle select
	
	global band_tbl

	set band_tbl [util::vmTableList $w_.btbl \
			  -title "Shuffle Bands" \
			  -height 10 \
			  -layoutcommand [code $this set_show_cols] \
			  -headings {"Band ID" "Y Pos" "Band Size"} \
			  -headinglines 1 \
			  -sizes {10 10 10} \
			  -background white \
			  -selectmode extended]

	pack  $band_tbl -fill x -side top -anchor s

	global image2
	
	# Search for stored values in .gmmps.cfg
	set slitLen [config_get_values "slitlen_ms" ]
	if {[lindex $slitLen 0 ] == ""} {
	    set slitLen 5.0
	}
	
	set shuffleAmt [config_get_values "shuffleamt_ms" ]
	if {[lindex $shuffleAmt 0 ] == ""} {
	    set shuffleAmt 5.0
	}
	
	set defpx [expr $shuffleAmt * $itk_option(-binning) / $PIXSCALE]
	set defpx [format "%.0f" [expr ceil($defpx) ]]

	pack \
	    [LabelEntry $w_.option.nsSlitlenOrBandHt\
		 -text "Slitlength (arcsec):" \
		 -labelwidth 30  \
		 -value $slitLen \
		 -state disabled \
		 -disabledforeground #666 \
		 -command [code $this calcBandAry] ] \
	    -side top

	$w_.option.nsSlitlenOrBandHt.entry config -disabledforeground #666

	pack [LabelEntry $w_.option.nodAmtOryOffset \
		  -text "Define Nods In Obs. Tool:" \
		  -labelwidth 30  \
		  -value 0 \
		  -disabledforeground #666 \
		  -command [code $this calcBandAry] ] \
	    -side top

	$w_.option.nodAmtOryOffset config -state disabled
	$w_.option.nodAmtOryOffset.entry config -disabledforeground #666

	pack [LabelEntry $w_.option.shuffleAmt \
		  -text "Shuffle Amt (arcsec):" \
		  -labelwidth 30  \
		  -value $shuffleAmt \
		  -command [code $this calcShufflePx] ] \
	    [LabelEntry $w_.option.shufflePx \
		 -text "Shuffle Amt (unbinned pix):" \
		 -labelwidth 30  \
		 -value $defpx \
		 -command [code $this checkShufflePx] ] \
	    -side top

	# Bind KeyRelease event that will automatically update arcsec shuffle amount
	# into the pixel field. 
	bind $w_.option.shuffleAmt.entry <KeyRelease> [code $this calcShufflePx]
	bind $w_.option.shufflePx.entry  <KeyRelease> [code $this calcShuffleAmt]
	
	
	set catShuffSiz ""
	set catBandSiz ""
	set catBand1Y ""
	set catNodSiz ""
	catch {
	    set catShuffSiz [exec grep "#fits SHUFSIZE" $itk_option(-catalog) | cut -f2 -d= ]
	    set catShuffSiz [string trim $catShuffSiz]
	}

	catch {
	    set catBandSiz [exec grep "#fits BANDSIZE" $itk_option(-catalog) | cut -f2 -d= ]
	    set catBandSiz [string trim $catBandSiz]
	}

	catch {
	    set catBand1Y [exec grep "#fits BAND1Y"  $itk_option(-catalog) | cut -f2 -d= ]
	    set catBand1Y [string trim $catBand1Y]
	}

	catch {
	    set catNodSiz [exec grep "#fits NODSIZE"  $itk_option(-catalog) | cut -f2 -d= ]
	    set catNodSiz [string trim $catNodSiz]
	}

	global shuffleMode

	# if these are present in the cat file, set them as defaults
	if {$catShuffSiz != ""} {
	    if {$catBandSiz != ""} {
		set shuffleMode "bandShuffle"
		$w_.option.bandShuffle select
		switchShuffleMode
		set catyOff [expr $catBand1Y - $catShuffSiz - ($EXTRABANDSEP/2)]
		$w_.option.nsSlitlenOrBandHt config -state normal
		$w_.option.nsSlitlenOrBandHt config -value [format "%.0f" $catBandSiz] 
		$w_.option.nodAmtOryOffset config -value [format "%.0f" $catyOff]
		$w_.option.nodAmtOryOffset config -state normal
		$w_.option.shufflePx config -value [format "%.0f" $catShuffSiz ]
		calcShuffleAmt
		calcBandAry
	    } elseif {$catNodSiz != ""} {
		set shuffleMode "microShuffle"
		$w_.option.microShuffle select
		switchShuffleMode
		$w_.option.nsSlitlenOrBandHt config -value [format "%.3f" $catShuffSiz] -state disabled
		$w_.option.nodAmtOryOffset config -value 0 
		$w_.option.nodAmtOryOffset config -state disabled
		$w_.option.shufflePx config -value [format "%.0f" $catShuffSiz ]
		calcShuffleAmt
	    }
	}
	
	# Push slitlength into shuffle amount. 
	if {$shuffleMode == "microShuffle"} {
	    set sra [$w_.option.shuffleAmt get]
	    $w_.option.nsSlitlenOrBandHt config -state normal
	    $w_.option.nsSlitlenOrBandHt config -value $sra
	    $w_.option.nsSlitlenOrBandHt config -state disabled
	}
    }


    protected method add_buttons {} {
	# dialog buttons
	set home $::env(GMMPS)	

	pack [frame $w_.buttons -borderwidth 2 -relief raised] \
	    -side top -fill x

	pack \
	    [button $w_.spoc -fg #000 -bg #bfb -activebackground #dfd \
		 -activeforeground #000 -text "Continue" \
		 -command [code $this designMask]] \
	    [button $w_.close -fg #000 -activeforeground #000 \
		 -text "Close" \
		 -command [code $this cancel ]] \
	    [button $w_.help -bg #9ff -fg #000 \
		 -activebackground #bff -activeforeground #000 \
		 -text "Help" \
		 -command [code $this help file://$home/html/ns.html]] \
	    -side left -expand 1 -pady 2m -in $w_.buttons
    }

    
    protected method make_short_help {} {
	TopLevelWidget::make_short_help
	
	add_short_help $w_.widgets.mask \
	    {set number of ODF files (masks) to be generated}
	add_short_help $w_.option.filter \
	    {set filter to be used for the observation}
	add_short_help $w_.option.gratingorder \
	    {set grating&order to be used for the observation}
	add_short_help $w_.option.band \
	    {set central wavelength to be used for the observation}
	add_short_help $w_.label.catalog \
	    {name of input catalog}	    
	add_short_help $w_.frame \
	    {output of the Slit Positioning Optimization Code}	    
	add_short_help $w_.spoc \
	    {Make ODF: generate the slit catalog}
	add_short_help $w_.close \
	    {Close: close this window}
    }


    ##########################################################################
    # Load the help pages
    ##########################################################################
    public method help {URL} {
	set browser [cat::vmAstroCat::get_browser]
	if {$browser != ""} {
	    set os [exec uname -s]
	    if {$os != "Darwin"} {
		exec $browser $URL
	    } else {
		exec open -a ${browser} $URL
	    }
	}
    }


    #############################################################
    #  Name: designMask
    #
    #  Description:
    #   This function is called when the "Make Masks (ODF)" button
    #   is pressed. It creates the Master ODF file(s). 
    #       Calls the gmmps_spoc method.  Which will bring up
    #	     the popup to allow you to run the spoc algorithm.
    #
    #############################################################
    #############################################################
    public method designMask {} {
	set retv [validateBandDef ]
	if {$retv == "notValid"} {
	    ::cat::vmAstroCat::error_dialog "Band Definition invalid, cannot make N&S mask prototype."
	    return
	}

	# Update the parameters in case the user didn't hit return (or recalculate)
	# after a parameter change
	calcBandAry

	# save the N&S configs
	saveBandDef
	
	global shuffleMode
	global band_tbl

	#write shufflePx in unbinned pixels
	set shufflePx [$w_.option.shufflePx get]
	set shuffleAmt [$w_.option.shuffleAmt get]

	if {$shuffleMode == "microShuffle"} {
	    $w_.option.nsSlitlenOrBandHt config -state normal
	    set sOb  [$w_.option.nsSlitlenOrBandHt get]
	    $w_.option.nsSlitlenOrBandHt config -state disabled
	    set nodAmt [$w_.option.nodAmtOryOffset get ]
	    set spoc_bands_args [list $shuffleMode $sOb $shufflePx $shuffleAmt $nodAmt]
	} else {
	    set sOb  [$w_.option.nsSlitlenOrBandHt get]
	    set bands [$band_tbl get_contents]
	    set i 0
	    set spoc_bands_args [list $shuffleMode $sOb $shufflePx $shuffleAmt]
	    foreach brow $bands {
		incr i
		set by [lindex $brow 1]
		lappend spoc_bands_args $by
	    }
	    set yoffset [$w_.option.nodAmtOryOffset get]
	    lappend spoc_bands_args $yoffset
	    lappend spoc_bands_args $i
	}

	#  Call the gmmps_spoc.tcl init function
	if { [catch {utilReUseWidget cat::gmmps_spoc .skycat1.spoc \
			 $catClass_ $itk_option(-catalog) \
			 $itk_option(-binning) $itk_option(-resultz) \
			 $itk_option(-instType) $config_file_ \
			 $DET_IMG_ $DET_SPEC_ $globlist $spoc_bands_args} msg]} {
	    ::cat::vmAstroCat::error_dialog $msg
	    return	    
	}
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
    	# Clear bands on window close.
	set canvas .skycat1.image.imagef.canvas
    	catch {$canvas delete bandrects}
    	
        catch {destroy $w_ }
    }

    #########################################################################
    #  Name: switchShuffleMode
    #
    #  Description:
    #     called to switch shuffle modes
    #
    #########################################################################
    #########################################################################
    public method switchShuffleMode {args} {
	global shuffleMode
	
	# Save values to config file when switching modes.
	if {$shuffleMode == "bandShuffle"} {
	    config_save_values "microShuffle"
	} elseif {$shuffleMode == "microShuffle"} {
	    config_save_values "bandShuffle"
	}
	
	if {$args == "textonly"} {
	    if {$shuffleMode == "microShuffle"} {
		# micro shuffle mode entered
		$w_.option.nsSlitlenOrBandHt config \
		    -text "Slitlen (arcsec):" \
		    -state disabled \
		    -disabledforeground #666

		$w_.option.nodAmtOryOffset config \
		    -text "Define Nods In Obs. Tool:" \
		    -disabledforeground #666
		
	    } elseif {$shuffleMode == "bandShuffle"} {
		# band shuffle mode entered
		$w_.option.nsSlitlenOrBandHt config \
		    -text "Band Size (unbinned pix):" \
		    -state disabled \
		    -disabledforeground #666

		$w_.option.nodAmtOryOffset config \
		    -text "Bands y Offset (unbinned pix):"
	    }
	} else {
	    if {$shuffleMode == "microShuffle"} {
		# micro shuffle mode entered
		
		# Search for stored values in .gmmps.cfg
		set slitLen [config_get_values "slitlen_ms" ]
		if {$slitLen == ""} {
		    set slitLen 5.0
		}
		set shuffleAmt [config_get_values "shuffleamt_ms" ]
		if {$shuffleAmt == ""} {
		    set shuffleAmt 5.0
		}
		
		# Edit values in widget.
		$w_.option.shuffleAmt config -value [format "%.3f" $shuffleAmt]
		calcShufflePx
		$w_.option.nsSlitlenOrBandHt config \
		    -text "Slitlen (arcsec):" \
		    -value $slitLen \
		    -state disabled \
		    -disabledforeground #666

		$w_.option.nodAmtOryOffset config \
		    -text "Define Nods In Obs. Tool:" \
		    -value 0 \
		    -disabledforeground #666

		$w_.option.nodAmtOryOffset config -state disabled
		
	    } elseif {$shuffleMode == "bandShuffle"} {
		# band shuffle mode entered
		
		# Search for stored values in .gmmps.cfg
		set bandSize [config_get_values "bandsize_bs" ]
		if {$bandSize == ""} {
		    set bandSize [lindex $bandHtDefault_ 0 ]
		}
		set yOffset  [config_get_values "yoffset_bs" ]
		if {$yOffset == ""} {
		    set yOffset 0
		}
		set shufflePx [config_get_values "shufflepx_bs" ]
		if {$shufflePx == ""} {
		    set shufflePx [lindex $bandHtDefault_ 0 ]
		}
		
		# Edit values in widget.
		$w_.option.nsSlitlenOrBandHt config \
		    -text "Band Size (unbinned pix):" \
		    -value $bandSize \
		    -state normal
		$w_.option.shufflePx config -value [format "%.0f" $shufflePx ]
		$w_.option.nodAmtOryOffset config -state normal
		$w_.option.nodAmtOryOffset config \
		    -text "Bands y Offset (unbinned pix):" -value $yOffset
		
		calcShuffleAmt
	    }
	}
	
	if {$args != "startup"} {
	    calcBandAry
	}
    }
	
    #########################################################################
    #  Name: calcBandAry
    #
    #  Description:
    #     calculate bands, plot them (and then call saveBandDef)
    #
    #########################################################################
    #########################################################################
    public method calcBandAry {args} {
	global band_tbl
	global image2
	global shuffleMode
	global EXTRABANDSEP
	
	set canvas .skycat1.image.imagef.canvas
	
	# first, check if micromode
	if {$shuffleMode == "microShuffle"} {
	    $band_tbl clear
	    $canvas delete bandrects
	    saveBandDef
	    return
	} elseif {$shuffleMode == "bandShuffle"} {
	    # NOTE: calculations for unbinned pixels

	    # check if it's valid before we make a fool of ourself
	    # drawing illegal bands that won't be allowed anyway
	    # when gmMakeMasks is called.
	    if {$args != "novalidate"} {
		validateBandDef "calcBandAry"
	    }
	    
	    set target_im_ image2
	    set iHt [expr [$target_im_ height] * $itk_option(-binning)]
	    set iWd [expr [$target_im_ width]  * $itk_option(-binning)]
	    
	    # note: shufflePx is given in unbinned pixels
	    set shuffPx [$w_.option.shufflePx get]
	    set bandHt [$w_.option.nsSlitlenOrBandHt get]
	    set yOffset [$w_.option.nodAmtOryOffset get]
	    
	    if {$yOffset < 0} {
		set yOffset 0
		$w_.option.nodAmtOryOffset config -value 0
	    }
	    # the maximum coordinate
	    set maxY [expr $iHt - $bandHt - $shuffPx - ($EXTRABANDSEP/2) + 1]
	    
	    $band_tbl clear
	    
	    # clear the bands
	    $canvas delete bandrects

	    # Draw horizontal n&s lines.
	    set j 0
	    set lastyend 0
	    for {set y [expr $shuffPx + ($EXTRABANDSEP/2) + $yOffset + 1]} \
		{$y <= $maxY} \
		{set y [expr $y + $shuffPx + $bandHt + $EXTRABANDSEP]} {
		    incr j
		    
		    #draw hatch mark of prohibited area
		    set x0loc 0
		    set x1loc [expr $iWd / $itk_option(-binning)]
		    set y0loc [expr $lastyend / $itk_option(-binning)]
		    set y1loc [expr $y / $itk_option(-binning)]
		    
		    set lastyend [expr $y + $bandHt]
		    
		    image2 convert coords $x0loc $y0loc image xleft ybot canvas
		    image2 convert coords $x1loc $y1loc image xright ytop canvas
		    
		    # draw the excluded rectangle
		    $canvas create rect $xleft $ytop $xright $ybot \
			-outline yellow -fill yellow -stipple gray25 -width 1 -tags bandrects
		}
	    
	    # draw one extra hash mark block from last band to top
	    # draw hash mark of prohibited area
	    set x0loc 0
	    set x1loc [expr $iWd / $itk_option(-binning)]
	    set y0loc [expr $lastyend / $itk_option(-binning)]
	    set y1loc [expr $iHt / $itk_option(-binning)]
	    
	    set lastyend [expr $y + $bandHt]
	    
	    image2 convert coords $x0loc $y0loc image xleft ybot canvas
	    image2 convert coords $x1loc $y1loc image xright ytop canvas
	    
	    # draw the excluded area rectangle
	    $canvas create rect $xleft $ytop $xright $ybot \
		-outline yellow -fill yellow -stipple gray25 -width 1 -tags bandrects

	    set j 0
	    set lastyend 0
	    for {set y [expr $shuffPx + $yOffset + ($EXTRABANDSEP/2) + 1]} \
		{$y <= $maxY} \
		{set y [expr $y + $shuffPx + $bandHt + $EXTRABANDSEP]} {
		    incr j
		    $band_tbl add_row "band$j $y $bandHt"
		}
	    $band_tbl calculate_format
	}
	saveBandDef "calcBandAry"
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
	    ::cat::vmAstroCat::error_dialog "Cannot find file $asciifile!"
	}
	return $keyval
    }

	
    #########################################################################
    #  Name: calcShufflePx
    #
    #  Description:
    #     calculate shufflePx from shuffleAmt
    #
    #########################################################################
    #########################################################################
    public method calcShufflePx {args} {
	global shuffleMode
	
	set sra [$w_.option.shuffleAmt get]
	# note: shuffle pixels are always UNBINNED!, thus binning is 
	#  factored in below
	
	if { [catch {set spx [expr $sra * $itk_option(-binning) / $PIXSCALE]} ]} {
	    # invalid entry handing.
	    
	    $w_.option.shufflePx config -value "###"
	    
	    # For microshuffle also push slitlen value to "Slitlen (arcsec):"
	    if {$shuffleMode == "microShuffle"} {		
		$w_.option.nsSlitlenOrBandHt config -state normal
		$w_.option.nsSlitlenOrBandHt config -value "###"
		$w_.option.nsSlitlenOrBandHt config -state disabled
	    }
	    
	} else {
	    # Valid entry...convert to pixels and push.
	    
	    set spxf [ expr ceil($spx) ] 
	    
	    $w_.option.shufflePx config -value [format "%.0f" $spxf ]
	    
	    # For microshuffle also push slitlen value to "Slitlen (arcsec):"
	    if {$shuffleMode == "microShuffle"} {		
		$w_.option.nsSlitlenOrBandHt config -state normal
		$w_.option.nsSlitlenOrBandHt config -value $sra
		$w_.option.nsSlitlenOrBandHt config -state disabled
	    }	    
	}
    }


    #########################################################################
    #  Name: calcShuffleAmt
    #
    #  Description:
    #     calculate shuffleAmt from shufflePx
    #
    #########################################################################
    #########################################################################
    public method calcShuffleAmt {args} {
	global shuffleMode	
	
	if {[catch {set spa [expr ceil([$w_.option.shufflePx get]) * $PIXSCALE / $itk_option(-binning) ]}]} {
	    $w_.option.shuffleAmt config -value "###"
	    
	    
	    # For microshuffle also push slitlen value to "Slitlen (arcsec):"
	    if {$shuffleMode == "microShuffle"} {		
		$w_.option.nsSlitlenOrBandHt config -state normal
		$w_.option.nsSlitlenOrBandHt config -value "###"
		$w_.option.nsSlitlenOrBandHt config -state disabled
	    }			
	} else {
	    # Valid entry...convert to arcseconds and push.
	    $w_.option.shuffleAmt config -value [format "%.3f" $spa]
	    
	    # For microshuffle also push slitlen value to "Slitlen (arcsec):"
	    if {$shuffleMode == "microShuffle"} {		
		$w_.option.nsSlitlenOrBandHt config -state normal
		$w_.option.nsSlitlenOrBandHt config -value [format "%.3f" $spa]
		$w_.option.nsSlitlenOrBandHt config -state disabled
	    }
	}

    }



    #########################################################################
    #  Name: saveBandDef
    #
    #  Description:
    #     saveBandDef
    #
    #     essentially this saves all the band vars for use by gmMakeMask
    #########################################################################
    #########################################################################
    public method saveBandDef {{args ""}} {
	global shuffleMode
	global band_tbl
	
	config_save_values $shuffleMode
	
	# Don't re-validate after
	if {$args != "calcBandAry" && $args != "novalidate"} {
	    validateBandDef
	}
	
	# write slitlen from microshuffle mode
	if {$shuffleMode == "microShuffle"} {
	    $w_.option.nsSlitlenOrBandHt config -state normal
	    set sOb  [$w_.option.nsSlitlenOrBandHt get]
	    $w_.option.nsSlitlenOrBandHt config -state disabled
	} else {
	    set sOb  [$w_.option.nsSlitlenOrBandHt get]
	}
    }

    #########################################################################
    #  Name: config_save_values
    #
    #  Description:
    #	Saves N&S widget values to the .gmmps.cfg personal configuration file.
    #########################################################################
    #########################################################################
    protected method config_save_values {shufMode} {
	
	if {$shufMode == "microShuffle"} {
	    $w_.option.nsSlitlenOrBandHt config -state normal
	    set slitLen [$w_.option.nsSlitlenOrBandHt get ]
	    $w_.option.nsSlitlenOrBandHt config -state disabled
	    
	    set shuffleAmt [$w_.option.shuffleAmt get ]
	    
	    $catClass_ gmmps_config_ \
		[list "shuffle_mode" "slitlen_ms" "shuffleamt_ms"] \
		[list $shufMode $slitLen $shuffleAmt ]
	    
	} else {	
	    set bandSize [$w_.option.nsSlitlenOrBandHt get ]
	    set yOffset  [$w_.option.nodAmtOryOffset get ]
	    set shufflePx [$w_.option.shufflePx get ]
	    
	    $catClass_ gmmps_config_ \
		[list "shuffle_mode" "bandsize_bs" "yoffset_bs" "shufflepx_bs"] \
		[list $shufMode $bandSize $yOffset $shufflePx ]
	}
    }

    #########################################################################
    #  Name: config_get_values
    #
    #  Description:
    #	Fetches stored data from the config file, if it exists.
    #########################################################################
    #########################################################################
    protected method config_get_values {keys} {
	
	set vals [$catClass_ gmmps_config_ [concat $keys ]]
	
	if {[llength $vals ] == 0} {
	    return ""
	} else {
	    return $vals
	}
    }
    
    
    #########################################################################
    #  Name: restoreDefaults
    #
    #  Description:
    #	Restore default values to the N&S widget.
    #########################################################################
    #########################################################################	
    protected method restoreDefaults {args} {
	global shuffleMode
	
	if {$shuffleMode == "microShuffle"} {
	    $w_.option.nsSlitlenOrBandHt config -state normal
	    $w_.option.nsSlitlenOrBandHt configure -value 5.000
	    $w_.option.nsSlitlenOrBandHt config -state disabled
	    $w_.option.shuffleAmt configure -value 5.000
	    calcShufflePx
	} else {
	    set def [lindex $bandHtDefault_ 0 ]
	    $w_.option.nsSlitlenOrBandHt configure -value [format "%.0f" $def]
	    $w_.option.nodAmtOryOffset configure -value 0
	    $w_.option.shufflePx configure -value [format "%.0f" $def]
	    calcShuffleAmt
	    
	    if {$args != "calcBandAry"} {
		calcBandAry $args
	    }
	}
	
	saveBandDef $args
    }


    #########################################################################
    #  Name: getShuffleMode
    #
    #  Description:
    #	returns the value of the shufflemode variable.
    #########################################################################
    #########################################################################	
#    public method getShuffleMode {} {
#	global shuffleMode
#	
#	return $shuffleMode		
#    }

    #########################################################################
    #  Name: validateBandDef
    #
    #  Description:
    #     validates band definition values.
    #########################################################################
    #########################################################################
    public method validateBandDef {args} {
	global shuffleMode
	global band_tbl
	
	if { $shuffleMode == "microShuffle" } {
	    $w_.option.nsSlitlenOrBandHt config -state normal
	    set slitlen [$w_.option.nsSlitlenOrBandHt get ]
	    
	    set shufPx  [$w_.option.shufflePx get ]
	    set shufAmt [$w_.option.shuffleAmt get ]
	    
	    if { $slitlen < 0 } {
		$w_.option.nsSlitlenOrBandHt configure -value 0.000
		::cat::vmAstroCat::error_dialog "Slitlen must be > 0\n"
	    }
	    
	    if { $shufPx < 0 } {
		$w_.option.shufflePx configure -value 0
		$w_.option.shuffleAmt configure -value 0.000
		::cat::vmAstroCat::error_dialog "ShufflePx must be > 0\n"
	    }
	    
	    if {$shufPx < $slitlen} {
		# Slit length is less than shuffle amount. Invalid. 

		# Query user for action.				
		set choice [tk_dialog $w_.nserror "N&S Value Error" "Required: Shuffle Amt >= Slit Length" "" 0 "Set Shuffle Amt = $slitlen" "Set Slit Length = $shufAmt" "Restore Defaults"  ]

		if {$choice == 0} {
		    $w_.option.shuffleAmt configure -value [format "%.3f" $slitlen]
		    calcShufflePx
		} elseif {$choice == 1} {
		    $w_.option.nsSlitlenOrBandHt configure -value [format "%.3f" $shufAmt ]
		} else {
		    restoreDefaults $args
		}
	    }
	    
	    $w_.option.nsSlitlenOrBandHt config -state disabled
	    
	} elseif { $shuffleMode  == "bandShuffle" } {
	    set target_im_ image2
	    set iHt [expr [$target_im_ height] * $itk_option(-binning)]

	    set bHt [$w_.option.nsSlitlenOrBandHt get ]
	    set sPx [$w_.option.shufflePx get ]
	    set yOffset [$w_.option.nodAmtOryOffset get ]			
	    
	    # Set valid to false for loop entry.
	    set valid 0

	    # Now assume bands are valid, until otherwise notified.
	    set valid 1
	    
	    if { $bHt < 0 } {
		$w_.option.nsSlitlenOrBandHt configure -value 0.000
		::cat::vmAstroCat::error_dialog "Band Size must be > 0"
		#set valid 0
	    }
	    
	    if { $sPx < 0 } {
		$w_.option.shufflePx configure -value 0
		$w_.option.shuffleAmt configure -value 0.000
		::cat::vmAstroCat::error_dialog "Shuffle Amt (in pix) must be > 0"
	    }
	    
	    if {$bHt > $sPx} {
		# Band size is greater than shuffle amount. Invalid. 
		
		# Query user for action.				
		set choice [tk_dialog $w_.nserror "N&S Value Error" "Error: Band Size must be <= Shuffle Amt in Pix." "" 0 "Set Band Size = $sPx" "Set Shuffle Amt = $bHt" "Restore Defaults"]

		if {$choice == 0} {
		    $w_.option.nsSlitlenOrBandHt configure -value [format "%.0f" $sPx ]
		} elseif {$choice == 1} {
		    $w_.option.shufflePx configure -value [format "%.0f" $bHt ]
		    calcShuffleAmt
		} else {
		    restoreDefaults $args
		}
	    }
	    
	    # Don't let bands become too big... defaults are max sizes.
	    if {[expr $sPx * 2 + $bHt + $yOffset ] > $iHt} {
		restoreDefaults "novalidate"
		
		if {$yOffset > 0} {
		    tk_messageBox -message "Cannot apply offset: spectra pushed off detector." -parent $w_
		}
		
	    }
	    
	    # Check current shuffle amt value against default values for other
	    # detectors.
	    if {$sPx != [lindex $bandHtDefault_ 0 ]} {
		set cnt 1
		foreach bandDefault [lrange $bandHtDefault_ 1 end ] {
		    
		    if {$sPx == $bandDefault} {
			set ourName [lindex $bandHtDefaultNames_ 0]
			set ourValue [lindex $bandHtDefault_ 0 ]
			set badName [lindex $bandHtDefaultNames_ $cnt]
			
			if {$args == "startup"} {
			    $w_.option.shufflePx configure -value [format %.0f $ourValue ]
			    $w_.option.nsSlitlenOrBandHt config -state normal
			    $w_.option.nsSlitlenOrBandHt configure -value [format %.0f $ourValue ]
#			    # eh? we are in bandshuffling mode here all the time!
#			    if {$shuffleMode == "microShuffle"} {
#				$w_.option.nsSlitlenOrBandHt config -state disabled
#			    }
			} else {
			    set titleText "Possible Default Confusion" 
			    set dialogText "Possible error: $sPx is the default shuffle amount for the $badName $itk_option(-instType) detector.\n\nYou are designing a mask for the $ourName detector (default value: $ourValue)."
			    set choice [tk_dialog $w_.defaultConflict $titleText $dialogText "" 0 "Use $ourName Default ($ourValue)" "Keep Current Value ($sPx)" ]
			    if {$choice == 0} {
				$w_.option.shufflePx configure -value [format %.0f $ourValue ]
				$w_.option.nsSlitlenOrBandHt config -state normal
				$w_.option.nsSlitlenOrBandHt configure -value [format %.0f $ourValue ]
				calcShuffleAmt
				# eh? we are in bandshuffling mode here all the time!
#				if {$shuffleMode == "microShuffle"} {
#				    $w_.option.nsSlitlenOrBandHt config -state disabled
#				}
			    }
			}
			break
		    }
		    incr cnt
		}
	    }
	}
	return "valid"
    }
    
    
    #########################################################################
    #  Name: getDefaultBandHt
    #
    #  Description:
    #	Constructs a list of all default band heights for this instrument, 
    #	as defined for each detector. The default for the detector that this
    #	mask is being designed for is to be placed in index 0, the rest may be
    #	in any order.
    # 	Also populates a corresponding list of the detector names corresponding
    #	to the default values.
    #	Returns both these lists.
    #########################################################################
    #########################################################################
    protected method setDefaultBandHt {} {
	set detFile [open "$home_/config/Detectors.dat" "r" ]
	set bandHtDefault_ [list ]
	set bandHtDefaultNames_ [list ]
	
	# Gather detector information from config file. 
	while {[gets $detFile line] >= 0} {
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

	    set detInst [lindex $line 1 ]
	    
	    # Instuments match so this is a relevant detector.
	    # NOTE GMOS-N == GMOS-S in this situation.
	    if {[string range $detInst 0 3 ] == [string range $itk_option(-instType) 0 3 ]} {
		set detId [lindex $line 2 ]
		set detName [lindex $line 3 ]
		set detBandSize [lindex $line 5 ]
		
		# Compare loaded detector ID with target DET_SPEC_ (as was 
		# passed in to the constructor).
		if {$detId == $DET_SPEC_} {
		    #If they match insert the default at the start of the list.
		    set bandHtDefault_ [linsert $bandHtDefault_ 0 $detBandSize ]
		    set bandHtDefaultNames_ [linsert $bandHtDefaultNames_ 0 $detName ]
		} else {
		    # If they don't match append value.
		    set bandHtDefault_ [lappend bandHtDefault_ $detBandSize ]
		    set bandHtDefaultNames_ [lappend bandHtDefaultNames_ $detName ]
		}
	    }
	}
	
	::close $detFile
	return [list $bandHtDefault_ $bandHtDefaultNames_]
    }
    
    
    #########################################################################
    #  Name: checkShufflePx
    #
    #  Description: Format and recalculate the "shuffle amt (in pixels)" 
    #	entrybox.
    #########################################################################
    #########################################################################
    protected method checkShufflePx {args} {
	
	# Set value in shufflePx to ceiling. 
	$w_.option.shufflePx configure -value [expr ceil([$w_.option.shufflePx get ]) ]
	
	# Apply ceiling value to shuffle amt.
	calcShuffleAmt
	
	validateBandDef
	
	# Redraw bands. 
	calcBandAry		
    }
    

    # Contains the type of file loaded in, Object Tbl, Master OT , or fitsFile 
    itk_option define -catalog catalog Catalog "" 

    # Options indicating col's that exist
    itk_option define -resultz resultz Resultz ""
#    itk_option define -pixs pixs Pixs ""
    itk_option define -binning binning Binning 1
    itk_option define -instType instType InstType ""
#    itk_option define -crpix1 crpix1 CRPIX1 0
#    itk_option define -crpix2 crpix2 CRPIX2 0
#    itk_option define -naxis1 naxis1 NAXIS1 0
#    itk_option define -naxis2 naxis2 NAXIS2 0

    # Name of the gmmps program configuration file. 
    protected variable config_file_

    # Reference to the catalog widget instance that called this widget.
    protected variable catClass_

    # Holds detector ID value for preimage.
    protected variable DET_IMG_ ""
    
    # Holds detector ID value for mask design.
    protected variable DET_SPEC_ ""

    # Holds the RA of the preimage
    protected variable RA_IMAG_ ""
    
    # Holds the DEC of the preimage
    protected variable DEC_IMAG_ ""

    # Holds the dispersion direction
    protected variable dispDirection_ ""

    protected variable posangle_ ""

    protected variable home_ ""
    
    # A list of all possible default band heights. 
    protected variable bandHtDefault_ ""
    
    # A list of detector names corresponding to the defaults in $defaultBandHt_
    protected variable bandHtDefaultNames_ ""

    # QueryResult widget used to display search results
    #   protected variable results_ {}

    protected common globallist

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
    protected common globlist {}
}
