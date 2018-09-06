.. -*- coding: utf-8 -*-

.. _submit_masks_label:

===========================
Submitting the mask designs
===========================

Once the ODFs have been created and verified, you submit the ODF **FITS**
to Gemini by means of the `Observing Tool <http://www.gemini.edu/node/11161>`_
for double-checking and final cutting.

.. _ODF_naming_convention_label:

.. index:: ODF; Naming convention

Standard naming convention for ODFs
===================================

The standard naming convention when submitting a mask is as follows: ::

  G(N/S)YYYYS<type>PPP-XX_ODF.fits

:N/S:  North or South
:YYYY: Year
:S:    Semester (A or B)
:type: Q (Normal Queue Programs), LP (Large and Long Programs), DD (Director's Discretionary Time), FT (Fast Turnaround)
:PPP:  Your program number
:XX:   The mask number

Examples:

* **GS2015AQ023-01_ODF.fits:** Regular queue program at Gemini South, mask 01
* **GN2014BLP001-04_ODF.fits:** Long-term program at Gemini North, mask 04
* **GS2014BDD008-03_ODF.fits:** Director's time at Gemini South, mask 03

.. note:: Masks that do not follow this naming convention will be removed from the 
	  `Observing Tool <http://www.gemini.edu/node/11161>`_ and must be re-submitted.

.. index:: ODF; Using mask name in the Observing Tool

The root name (e.g. GS2015AQ023-01) of a mask must be entered into the 
Observing Tool's *Custom Mask MDF* field in the instrument static component 
when defining the phase II observations:

.. figure:: images/gmmps_GMOS_MDF_component.png
   :width: 100%

   *Entering the ODF's root name in the Observing Tool.*

.. index:: ODF; Uploading in the Observing Tool
.. index:: Observing Tool; Mask submission / Uploading an ODF

Uploading ODFs (et al.)
=======================

Use the Observing Tool's 
`file attachment facility <http://www.gemini.edu/node/11200#summary>`_
to upload the following files:

* ODF FITS files (\*.cat files are not accepted)
   
* Pre-images or :ref:`pseudo-images <pseudo_image_label>` (if the masks are based on external catalogs instead of pre-imaging)

Once the ODF is uploaded, you must add a comment to it in the 
`Observing Tool <http://www.gemini.edu/node/11161>`_ that unambiguously associates 
the ODF with its pre-image (or pseudo-image). Likewise, you may add a comment to each 
pre-image associating it with its respective ODF(s). At least one of the two is 
required.

.. figure:: images/gmmps_fileattachment.png
   :scale: 66

   *Add comments to the preimages (or ODFs) that 
   unambiguously tell us which ones belong together.*
