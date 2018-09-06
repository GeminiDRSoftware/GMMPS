.. -*- coding: utf-8 -*-

.. index:: OT

=============================
Object Tables (OTs) -- Format
=============================

Object Tables (OTs) are FITS tables containing all necessary information
for the mask design. This section describes the OT format, and the next
section :ref:`how to create an OT <create_OT_label>`.

.. index:: OT; Mandatory columns

.. _mandatory_OT_columns_label:

Mandatory columns
=================

OTs have the following mandatory columns, ideally in this order:

:ID:    Unique object id (16-bit **integer**)
:RA:    Right ascension in hours (**float**)
:DEC:   Declination in degrees (**float**)
:x_ccd: X coordinate of object position in pixels (**float**)
:y_ccd: Y coordinate of object position in pixels (**float**)
:MAG:   Relative magnitude (**float**)

The column names are **case sensitive**.

The numeric format is **mandatory**, in particular **the ID must be an integer**.


.. note::
   The RA and DEC columns are used to plot the object 
   positions in the image. Cartesian x and y coordinates are used to define
   (and plot) the positions of the slits.

.. index:: OT; Optional columns

.. _optional_OT_columns_label:

Optional columns
================

The following columns (if absent) will be added automatically by *GMMPS*.

:slitsize_x: Slit extent in X-direction in arcsec (**float**)
:slitsize_y: Slit extent in Y-direction in arcsec (**float**)
:slitpos_x: Offset in X-direction relative to the object in arcsec (**float**)
:slitpos_y: Offset in Y-direction relative to the object in arcsec (**float**)
:slittilt: Slit position angle in degrees (**float**)
:slittype: Slit type. Currently, only rectangular slits are allowed (slittype = R; **char*1**)
:priority: Priority (**char*1**)
:redshift: Redshift of the source (if any, otherwise zero) (**float**)

.. index:: Priority

Priority
++++++++

An object's priority is represented by a single character with 5 possible 
values.

* *priority = 0*: Acquisition star (at least two required, better three)
* *priority = 1*: Highest priority
* *priority = 2*: Medium priority
* *priority = 3*: Lowest priority
* *priority = X*: Ignore object

More information on :ref:`how GMMPS uses priorities <gmmakemasks_label>`.

.. index:: GMOS; Dispersion direction, F2; Dispersion direction, Dispersion direction; GMOS, 
	   Dispersion direction; F2

slitsize and slitpos
++++++++++++++++++++

**GMOS has a horizontal dispersion** (in image coordinates), and 
therefore *slitsize_x/y* refer to the slit width and slit length, 
respectively. To offset the object along the slit you would introduce 
a non-zero value for *slitpos_y*. A non-zero value for *slitpos_x* 
would quickly lead to flux losses for point-like objects as they are 
driven off the slit.

**F2 has a vertical dispersion**. Therefore, *slitsize_x/y* refer to 
the slit length and slit width, respectively. To offset the object 
along the slit you would introduce a non-zero value for *slitpos_x*.
A non-zero value for *slitpos_y* would quickly lead to flux losses 
for point-like objects as they are driven off the slit.

.. index:: GMOS; Default slit length/width, F2; Default slit length/width,
	   Default slit length/width

**Defaults:** The following values are used if optional columns are added:

* slit width = 1.0 (*slitsize_x* for **GMOS**, *slitsize_y* for **F2**)
* slit length = 5.0 (*slitsize_y* for **GMOS**, *slitsize_x* for **F2**)
* *slitpos_x = 0.0*
* *slitpos_y = 0.0*
* *slittilt = 0.0*
* *priority = 2*

.. index:: Tilted slits, Curved slits

.. _tilted_slits_label:

Tilted and curved slits
+++++++++++++++++++++++

* Positive angles rotate the slit counter-clockwise.

* Angles larger than 45 degrees are not permitted.

* A tilted slit is represented by a parallelogram. Its width
  in dispersion direction remains unchanged (i.e. *slitsize_x*
  for GMOS, and *slitsize_y* for F2). The spectral resolution is
  conserved among slits with different tilt angles and identical
  widths.

* Tilted slits are permitted in Nod & Shuffle masks, provided
  a :math:`q=0` offset is used in the GMOS Nod & Shuffle component
  of the `Observing Tool <http://www.gemini.edu/node/11161>`_
  (:ref:`see here <tiltslit_in_NS_label>`).

* Curved slits are not supported. They can be mimicked by
  concatenating neighboring slits with different tilt angles.
