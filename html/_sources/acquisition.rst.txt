.. -*- coding: utf-8 -*-

.. _acquisition_label:

===========================
Appendix: Acquisition stars
===========================

.. index:: Acquisition stars, Aligning the mask on sky

MOS masks are acquired by centering at least two acquisitions stars in 
reference slits (2x2 arcsec square boxes). To this end, the centroids of
the reference slit and of the star are measured.

A list of requirements and recommendations is given below.

Requirements
============

1. **How many stars:** At least two (recommended: three) 
   acquisition stars are required if the mask was designed based on 
   pre-imaging data. If the mask was designed using 
   :ref:`external catalogs and pseudo-images <external_catalog_label>`, 
   then at least three (recommended: four) acquisition stars are required.
   More stars will increase the overhead unnecessarily.

#. **Same astrometric reference system:** It is paramount that acquisition
   stars and science targets are taken from the same catalog or data source.
   
#. **Must not saturate in pre-image:** If saturated in the pre-image, then
   the centroids of the acquisition stars are uncertain, and the 
   acquisition will likely fail.
   
#. **No proper motion stars:** Do not use high proper motion stars, as
   the pre-images and the actual science observations may be taken months
   or years apart. *GMMPS* checks the proper motion vectors.
   
#. **Where on the detector:** Acquisition stars should be placed as far from 
   each other as possible, and ideally in a triangular fashion.

#. **Stay clear of detector gaps and field border:** 
   *GMMPS* issues a warning if an acquisition star is less than 4.0" from a
   detector gap or the border of the slit placement area. An additional
   acquisition star must be included in the mask design as backup unless
   there are already 2 (pre-image) or 3 (pseudo-image) good acquisition
   stars present. Distances
   less than 2.0" are not permitted by *GMMPS* because the centroid measurements
   will likely fail due to truncation and / or shadowing. In this case, the
   star's :ref:`priority <priority_label>` must be changed to a non-zero value.

#. **No OIWFS guide stars:** OIWFS guide stars are shadowed by the guide 
   probe arm. They cannot be used as acquisition stars.


Recommendations
===============

1. **Stars, not galaxies:** Stars should always be preferred over galaxies as 
   they have better defined centroids, and the centroid is independent of the 
   light distribution as a function of seeing. This is not the case for 
   galaxies, where substructures may bias the centroiding. Galaxies may
   be used as a last ressort, only, e.g. if insufficient guide stars are 
   available. In that case, choose featureless galaxies with compact bright 
   nuclei.

#. **Bright enough:** Acquisition stars should be bright enough (between 
   mag 12-19) and ideally within 2 magnitudes (so that they can be displayed
   properly in a single exposure by the observer). Fainter stars may be used
   if necessary, but this will increase the overheads as the observer possibly
   needs to increase the exposure times.

#. **If in doubt:** If you are not certain about a particular acquisition 
   source, for whatever reason (e.g. close to gap, possibly proper motion),
   an additional acquisition star must be provided.

.. note::
   The rms offset of the acquisition stars from the center of the acquisition 
   boxes must be less than 25% of the slit width of the narrowest science 
   slit. Otherwise the observing software decides that the mask cannot be 
   aligned.

.. figure:: images/gmmps_acq_proximity.png
   :scale: 66

   *The acquisition star to the lower right is within 4.0" of the border of
   the slit placement area. Most likely this is ok, but its spectrum is shown
   yellow to highlight it as potentially problematic. An additional
   acquisition star must be included in the mask design unless there are
   already 2 (pre-image) or 3 (pseudo-image) good acquisition stars present.
   The acquisition star to the upper left has a safe distance to the GMOS
   detector gap.*

