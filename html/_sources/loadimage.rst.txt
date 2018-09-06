.. -*- coding: utf-8 -*-

.. index:: Loading; Images in skycat

.. _load_image_skycat_label:

==============
Loading Images
==============

An image for visual reference is always required when designing a mask with *GMMPS*.
The image is either a reduced GMOS/F2 image (*pre-image*) supplied by Gemini, or a 
reduced image from a different telescope that has been re-formatted so that it appears
as if it was taken with GMOS or F2 (a :ref:`pseudo-image <pseudo_image_label>`).

Loading
=======

Launch *GMMPS* directly with the image name, ::

  gmmps <image.fits>

or use the *File -> Open* command in the *Skycat* menu.

.. figure:: images/gmmps_loadimage.png
   :scale: 50

   *FITS image displayed in Skycat.*
	   
.. _adjust_skycat_cutlevels_label:

.. index:: Dynamic range; Adjusting in skycat

Adjusting the dynamic range
===========================

Click on *Auto Set Cut Levels* or go to *View -> Cut levels* to adjust the dynamic
range. Alternatively, enter *Low* and *High* levels. For the low value, choose a
number somewhat less than the background value. Pixels exceeding the *High* threshold
will be displayed white.
