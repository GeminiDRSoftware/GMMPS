.. GMMPS documentation master file, created by
   sphinx-quickstart on Sun Mar  1 15:12:18 2015.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

==============================
GMMPS |version|: Documentation
==============================

:Last update: |today|
:Latest changes: `ChangeLog <http://software.gemini.edu/gmmps/ChangeLog>`_

About GMMPS
===========

*GMMPS* is Gemini's mask making software. It supports the following multi-object spectrographs:

* `GMOS <http://www.gemini.edu/sciops/instruments/gmos/>`_ (optical, Gemini North and South)
* `F2 <http://www.gemini.edu/sciops/instruments/flamingos2/>`_ (near-infrared, Gemini South)

Contents
========

.. toctree::
   :maxdepth: 1
   :numbered:

   Obtaining GMMPS <installation.rst>
   Loading Images <loadimage.rst>
   The Object Table (OT) - Format <OTformat.rst>
   Creating an OT<createOT.rst>
   The OT window <editOT.rst>
   Creating Masks (ODFs) <createODF.rst>
   Nod & Shuffle masks <ns.rst>
   The ODF window <loadODF.rst>
   Submitting the mask designs <submit.rst>
   Example 1: Redshift survey (GMOS-S) <example1.rst>
   Example 2: Band-shuffle mask (GMOS-S) <example2.rst>
   Example 3: F2 mask design <example3.rst>
   Appendix: Mask check instructions <ngo.rst>
   Appendix: Acquisition stars <acquisition.rst>
   Appendix: Slit selection algorithm <spoc.rst>
   Appendix: GMMPS wavelength overlays <moswavegrid.rst>
   Appendix: GMOS WaveMapper <wavemapper.rst>
   Appendix: Troubleshooting <tt.rst>


Acknowledgements
================

This documentation is partly based on previous texts written by
Dione Scheltus and Bryan Miller.

*GMMPS* has been originally derived from the ESO/VIMOS Mask Preparation
Software (`VMMPS <https://www.eso.org/sci/observing/phase2/SMGuidelines/VMMPS.html>`_), after agreement with the European Southern Observatory.
*VMMPS* was developed originally by Dario Bottini at the Istituto di
Fisica Cosmica G.Occhialini - CNR, Italy. It has been modified by
Jennifer Dunn, Craig Allen, Dustin Fennell, Bryan Miller, Mischa
Schirmer, Michael Hoenig, and Joy Chavez to work with Gemini instrumentation.

Current *GMMPS* support: Bryan Miller, Joy Chavez
