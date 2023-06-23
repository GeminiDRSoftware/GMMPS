.. -*- coding: utf-8 -*-

.. index:: OT; Creating with SExtractor

.. _create_OT_label:

============
Creating OTs
============

OTs can be created in two different ways:

1. Using a GMOS/F2 pre-image that shows all science targets

2. Using a RA/DEC catalog and an external image (pseudo-image)

One method's strength is the other's weakness, and vice versa.

Comparing pre-images and pseudo-images
======================================   

Mask designs based on pre-images and pseudo-images are equally accurate,
provided the external catalog used with the pseudo-image has sufficiently
high relative astrometric accuracy (0.1" or better). In this case, slit
positions between the two methods are well within a single pixel:

.. figure:: images/pseudoimage_results.png
   :width: 50%

   *Accuracy of the pseudo-image mode. In 2017, the transformations
   from the RA/DEC system to distorted image coordinates have been
   re-measured. We observed stellar fields in good seeing, and
   calibrated the data against GAIA DR1. The new transformations
   dramatically improve the performance compared to the previous
   tranformations that were obtained
   in 2006.*


Pre-images: Pros and Cons
+++++++++++++++++++++++++

**Advantages:**

* Always highly accurate relative slit positions
* Image provided by Gemini, ready to be used in *GMMPS*
* Largely immune against proper motions, because science data will
  be taken soon thereafter.

**Disadvantages:**

* Additional telescope time required, perhaps prohibitively much
* Lag between the semester start and the start of the MOS observations.
  The pre-images must be taken before masks can be designed.

Pseudo-images: Pros and Cons
++++++++++++++++++++++++++++

**Advantages:**

* Masks can be designed early, no need to wait for pre-images

**Disadvantages:**

* Accuracy of the relative slit positions determined by the accuracy of the
  targets' sky coordinates
* Proper motions may render the mask design invalid if the data is older than
  about a year.

.. index:: Proper motions

.. _proper_motion_label:  
  
Impact of proper motions
========================

Each mask has at least two reference slits (squared, 2" wide)
to align the mask on sky, using acquisition stars (:numref:`Sect. %s <acquisition_label>`).
Proper motions may void a mask design in two ways:

1. One or more of the acquisition stars has high proper motion. In this case
   it can happen that the mask cannot be aligned on sky anymore. To avoid
   this problem, *GMMPS* displays the proper motions
   (from `PPMXL <http://dc.zah.uni-heidelberg.de/ppmxl/q/cone/infoof>`_,
   and in the future from GAIA) of all acquisition stars. An additional warning is
   shown if any component of the proper motion vector exceeds 100 mas/yr,
   and an error if 250 mas/yr are exceeded.

2. Even if the mask was acquired successfully, individual proper motions may
   drive stellar science targets off their respective slits. In its current
   version, *GMMPS* does not check the proper motions of science targets,
   nor does it correct the slit positions for proper motions. 


.. _OT_from_preimage_label:

Creating OTs based on pre-images
================================

Object detection with SExtractor
++++++++++++++++++++++++++++++++

.. index:: SExtractor, Object detection; SExtractor

Use `SExtractor <http://www.astromatic.net/software/sextractor>`_ to detect 
objects in the pre-image. You need the following configuration files, 
available in the *examples/* sub-directory in the *GMMPS* distribution tree: ::

  gmmps.conv
  gmmps.conf
  gmmps.nnw
  gmmps.param

Copy all files into the directory with your pre-image. Change to that 
directory, and then run ::

  sex -c gmmps.conf <image.fits>

This will create a FITS table called *preimage.sex.fits*, requiring that the *SExtractor* 
executable can be found in your PATH variable. Detection parameters can be changed in 
*gmmps.conf*.

.. index:: IRAF; Converting FITS tables to OT format, OT; Creating with IRAF, stsdas2objt (IRAF task)

.. _stsdas2objt_label:

The *preimage.sex.fits* table must be converted to OT format before it can be loaded in *GMMPS*.
The conversion is done with *stsdas2objt*, available in *gemini.gmos.mostools* in 
`Gemini IRAF <http://www.gemini.edu/sciops/data-and-results/processing-software?q=node/11823>`_. 
Open an *IRAF* session and do: ::

  cd /path/to/image
  gemini
  gmos
  mostools
  epar stsdas2objt

Configure the task *stsdas2objt* like this, leaving the other parameters 
empty or at their default values:

.. code-block:: none

   intable = preimage.sex.fits
   image   = <image.fits>
   fl_wcs  = yes
   instrum = gmos (gmos|flamingos)
   id_col  = NUMBER
   mag_col = MAG_AUTO
   x_col   = X_IMAGE
   y_col   = Y_IMAGE

**You must** let *stsdas2objt* recalculate (RA,DEC) using the WCS in the image
headers (*fl_wcs = yes*). This is because *SExtractor* calculates RA in
degrees, but *stsdas2objt* wants it in hours instead. The converted FITS table
will be called *preimage.sex_OT.fits*. You may rename it arbitrarily. However,
we recommend you keep the *_OT.fits* suffix.

.. index:: daophot (IRAF task), daofind (IRAF task), apphot (IRAF task), allstar (IRAF task), nstar (IRAF task), IRAF; Object detection, Object detection; IRAF

Object detection with IRAF
++++++++++++++++++++++++++

*IRAF* may also be used to create the object tables using *daophot*.

First, find the objects ::

  daofind mrgN20011021S104_add[1] output=mrgN20011021S104.coo \
       fwhm=12 threshold=100 verify- ccdread="RDNOISE" gain="GAIN" sigma=14.

Aperture photometry using *apphot.phot* ::

  photpars.apertures="10"
  phot mrgN20011021S104_add[1] coords=mrgN20011021S104.coo \
       output=mrgN20011021S104.mag  ccdread="RDNOISE" gain="GAIN" \
       sigma=14. verify- verbose- inter-

Like before with *SExtractor*, the resulting *daophot* table must be converted to OT format.
To this end use the task *gemini.gmos.mostools.app2objt*. Note that *app2objt* will remove 
any objects with mag=INDEF since *GMMPS* cannot handle these values. ::

  app2objt mrgN20011021S104.mag verbose+ image=mrgN20011021S104_add.fits priority="2" 

The result, *mrgN20011021S104_OT.fits*, can be loaded in *GMMPS*.

| Further examples and explanations can be found in these two IRAF scripts: 
| `objtexample1.cl <http://www.gemini.edu/sciops/instruments/gmos/gmmps/objtexample1.cl>`_ `objtexample2.cl <http://www.gemini.edu/sciops/instruments/gmos/gmmps/objtexample2.cl>`_



.. _external_catalog_label:

Creating OTs based on target lists and pseudo-images
====================================================

A mask can also be designed based on a list of RA/DEC coordinates. The relative
accuracy of the coordinates should be equal or better than 0.1". The RA/DEC values
are transformed to the x/y coordinates the targets would have in a (distorted)
GMOS/F2 pre-image.
  
You also need an external image with a valid WCS header that covers the area of
the target list. This image does not need to be the same image as the one from
which the target list was extracted; it merely serves as a visual reference in
*GMMPS*. The image will be transformed into a *pseudo-image*, mimicking a
GMOS / F2 pre-image.

*The slit positions are entirely based on the list of sky coordinates.*

.. index:: gmskcreate (IRAF task), pseudo-image

.. _gmskcreate_label:

.. _pseudo_image_label:


Configuring *gmskcreate*
++++++++++++++++++++++++

The pseudo-image and the OT for the mask design are built using 
the *Gemini IRAF* task *gmskcreate*. This task is available in
*gemini.gmos.mostools* and **must be** configured as follows:

.. code-block:: none

   indata    = Input ASCII file containing the spectroscopy targets (see below)
   inimage   = Input FITS file used to create the pseudo-image (see below)
   gprgid    = Your Gemini program ID (e.g. GS-2017A-Q-1)
   instrume  = Instrument (gmos-n|gmos-s|flamingos2)
   rafield   = RA value of field center (decimal degrees or hours)
   decfield  = Dec value of field center (decimal degrees)
   pa        = Position angle of field
   fl_getxy  = yes
   fl_getim  = yes
   iraunits  = degrees or hours (units in the input catalog)
   fraunits  = degrees or hours (units for "rafield")
   outtab    = name for the output OT ("GMI<indata>_OT.fits" if empty)
   outcoords = name for an optional file containing x/y positions  

.. note::
   RA, DEC and PA **must be identical** to the ones defined in the phase II
   observations. You **must also verify** in the
   `Gemini Observing Tool <http://www.gemini.edu/node/11161>`_ 
   that a suitable guide star is available for the chosen RA, DEC and position
   angle.

The file specified by the *outcoords* parameter contains the
instrumental (x,y) coordinates, one object per line. It is not used
by *GMMPS*, but may be useful for overplotting the (x,y) coordinates
on the pseudo-image using the *IRAF* task *tvmark*.


Input ASCII file for *gmskcreate*
+++++++++++++++++++++++++++++++++

The input file must contain one line per spectroscopic target,
in this order (note that the line below is not included in the file): ::

  ID   RA   DEC   MAG   priority   slitsize_x   slitsize_y   slittilt   slitpos_y/x

*ID*, *RA*, *DEC* and *MAG* are :ref:`mandatory columns <mandatory_OT_columns_label>`.
The others are :ref:`optional <optional_OT_columns_label>`.
Values must be **blank separated**. Optional values may be set for some
objects and omitted for others. If provided, then all five optional values
must be set, otherwise they will be defaulted as

.. code-block:: none

   priority   = 1
   slitsize_x = slitszx
   slitsize_y = slitszy
   slittilt   = 0
   slitpos_y  = 0

where *slitsize_x/y* are input parameters for *gmskcreate*. Note that *slitpos_y/x*
refers to the offset of the object *along* the slit, i.e. this is *slitpos_y* for GMOS, and
*slitpos_x* for F2.

.. note::
   *GMMPS* enforces that acquisition stars (*priority = 0*) have *slitsize_x/y = 2.0*, 
   *slittilt = 0* and *slitpos_x/y = 0*. Any optional values given for 
   acquisition stars will be ignored.

   The RA/DEC coordinates in the target list must match the WCS in the
   input image, otherwise plotting symbols in *GMMPS* will not line up
   properly.


Input FITS image for *gmskcreate*
+++++++++++++++++++++++++++++++++

The pseudo-image is created from an external image, which must contain
the WCS keywords *CRPIX1/2*, *CRVAL1/2*, and the four CD matrix entries,
CDi_j. The WCS of the external image should correspond reasonably well with the
astrometry of the input objects. Otherwise, the slits plotted in *GMMPS* will
not lie on top of the objects. This is not a problem for the mask creation,
as the slit positions are based on the target catalog. However,
mask checking will be more difficult.

The resulting pseudo-images will always be pre-fixed with the string *GMI*,
so that they can be recognized as such when submitted to the observatory.

Example
+++++++

The input ASCII file contains the following columns: ::

  ID   RA   DEC   MAG   priority   slitsize_x   slitsize_y   slittilt   slitpos_y

Note that for F2 *slitpos_y* would be replaced by *slitpos_x* (offset along the slit).

The actual input file would look like this (note that the column names listed above
are absent): ::

  10	201.67725788	-47.65156978 	17 	2   1.0   15.0 	0.0   3.0
  11	201.68830528	-47.64194528 	17
  12	201.66749228	-47.65391578 	17 	2   1.0   15.0 -6.0   0.0
  13	201.68427878	-47.66114059 	17
  14	201.71123928	-47.64720188 	17 	3
  15	201.69364588	-47.62953180 	17
  16	201.69952048	-47.63118018 	17
  17	201.69640768	-47.66783558 	14.6 	0   1.0   5.0   0.0   0.0
  18	201.71233788	-47.63684878 	14.3 	3   1.0   20.0  3.0
  20	201.64417083	-47.68341666 	14.7 	0   2.0   2.0   0.0   0.0
  21	201.73536249	-47.61178055 	14.6 	0   2.0   2.0   0.0   0.0

Here, the optional values for objects 11, 13, 15, and 16 have been omitted, and 
default values will be used. Likewise, for objects 14 and 18, incomplete optional values
are provided, resulting in *all of them* being defaulted. Objects 10 and 12 have 15" long 
slits, number 12 is tilted by -6 degrees, and object 10 offset by 3.0"x along the slit.

Objects 17, 20 and 21 are acquisition stars (*priority = 0*), meaning all other optional 
values provided will be ignored and *slitsize_x/y = 2.0*, *slittilt = 0* and *slitpos_x/y = 0* 
enforced. The aquisition objects can be changed interactively in *GMMPS*. It is 
important that the OT contains sufficiently many potential acquisition sources to allow for flexibility in the mask design.

Configure *gmskcreate* as follows:

.. code-block:: none

   indata     = test
   gprgid     = GS-2017A-Q-1
   instrument = gmos-s
   rafield    = 201.68298
   decfield   = -47.64762
   pa         = 35
   fl_getxy   = yes
   fl_getim   = yes
   inimage    = sdss.fits
   iraunits   = degrees
   fraunits   = degrees

The output files are:

* *GMItest* - A file containing the GMOS-S x,y coordinates for the pseudo-image
* *GMItest_OT.fits*  - The Object Table
* *GMIsdss.fits* - The pseudo-image
* *gmos.log* - a log file

GMItest_OT.fits contains ::

  #     ID 	RA 	  DEC 	        x_ccd     y_ccd       MAG 	priority   slitsize_x 	slitsize_y  slittilt  slitpos_y
  #             H 	  deg 	        pixels 	  pixels      mag 	           arcsec 	arcsec 	    degrees   arcsec
  1 	10 	13.44515  -47.65157 	3291.15	  2561.97     17. 	2 	   1.0 	        15.0 	    0.0       3.0
  2 	11 	13.44589  -47.64194 	2924.58   2088.10     17. 	1 	   1.0	         5.0 	    0.0       0.0
  3 	12 	13.44450  -47.65392 	3615.19   2677.60     17. 	2 	   1.0	        15.0 	   -6.0       0.0
  4 	13 	13.44562  -47.66114 	3058.21   3033.21     17. 	1 	   1.0 	         5.0 	    0.0       0.0
  5 	14 	13.44742  -47.64720 	2163.62   2347.12     17. 	3 	   1.0 	         5.0 	    0.0       0.0
  6 	15 	13.44624  -47.62953 	2747.09	  1476.67     17. 	1 	   1.0 	         5.0 	    0.0       0.0
  7 	16 	13.44663  -47.63118 	2552.11   1557.89     17. 	1 	   1.0 	         5.0 	    0.0       0.0
  8 	17 	13.44643  -47.66784 	2655.82	  3363.20     14.6 	0 	   2.0 	         2.0 	    0.0       0.0
  9 	18 	13.44749  -47.63685 	2126.77   1837.18     14.3 	1 	   1.0 	         5.0 	    0.0       0.0
  10 	20 	13.44294  -47.68342 	4390.63   4133.77     14.7 	0 	   2.0 	         2.0 	    0.0       0.0
  11 	21 	13.44902  -47.61178 	1358.33    599.68     14.6 	0 	   2.0 	         2.0 	    0.0       0.0


Data sources
++++++++++++

Often, input catalogs and images for *gmskcreate* are related.
E.g., both catalog and image are based on a particular survey.
This is not a requirement, though. One could also use e.g. the
RA/DEC positions from the UCAC4 catalog, and an SDSS FITS image
of the same area.


.. index:: Good mask design

Recommendations and requirements
================================

* **Targets and acquisition stars** must be selected from **the same object catalog** with relative astrometry better than 0.1". Otherwise it is most likely that the mask design is critically flawed (partial or full slit losses).

* **At least 2 acquisition stars** are required for masks created from pre-imaging.

* **At least 3 acquisition stars** are required for masks created from pseudo-imaging.

* **More than 4 acquisition stars** increase overheads unnecessarily. 

* **It is a good idea to include a brighter star** in one of the science slits, easily
  detected in a single exposure. Put a note in the phase II observing tool asking the
  observer to inspect the first science exposure, and to **abandon the observations**
  if no obvious spectrum from the bright star is seen. This is particularly useful if
  your science targets are very faint. It also allows you to judge the accuracy of the
  reduction and stacking of the spectra. The star might also serve for
  **telluric calibration**. For GMOS, select two stars near the right and left edges
  of the field to cover the whole wavelength range (not necessary for F2).

.. warning::
   If the mask acquisition went fine and if the science targets are too faint to be seen
   in a single exposure, then we will continue observing. If the PI determines after the 
   fact that the mask design was bad, then the time will be charged to the program and the 
   partner country. A new mask design may be submitted to use the remainder of the time 
   allocation.
