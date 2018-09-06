.. -*- coding: utf-8 -*-

.. index:: Getting started

===============
Getting started
===============

Step-by-step examples
=====================

If you are a new user to *GMMPS* and you have it already running, then the best way
forward is to follow these three step-by-step examples:


1. :ref:`GMOS-S: A simple redshift survey <example1_label>`

#. :ref:`GMOS-S: A system of globular clusters (band-shuffling mask) <example2_label>`

#. :ref:`FLAMINGOS-2: Knots in a star-forming region <example3_label>`


Download
========

*GMMPS* |version| comes with the source code and example images.
It is available at
`http://software.gemini.edu/gmmps/gmmps-1.4.5.tgz <http://software.gemini.edu/gmmps/gmmps-1.4.5.tgz>`_ (136 MB). **This version is mandatory.**

The following instruments are supported:

* `GMOS-N <http://www.gemini.edu/sciops/instruments/gmos/>`_ (Hamamatsu CCDs)
* `GMOS-S <http://www.gemini.edu/sciops/instruments/gmos/>`_ (Hamamatsu CCDs)
* `FLAMINGOS-2 <http://www.gemini.edu/sciops/instruments/flamingos2/Flamingos-2>`_

Included is the new :ref:`waveMapper <WM_window_label>` Skycat plugin.
It can be used to plan the central wavelength settings for the GMOS
long-slit, IFU-R and IFU-2 modes. This is independent of the mask making
aspects of *GMMPS*.

`Latest changes <../ChangeLog>`_

.. note::
   Not all features in the 
   `original design specifications <http://www.gemini.edu/sciops/instruments/gmos/gmosmaskmakingv104.ps.gz>`_ have been implemented in the current version (e.g. curved slits, and some of the desired interactivity). Many other features have been included, though, for which the necessity arose over time. Amongst them are wavelength displays, further automatisation, much improved user friendliness, and internal consistency checks.

.. index:: Dependencies

Dependencies
============

The following pre-requisites **must be met** before installing *GMMPS*:

* C/C++ compilers and the "make" utilities

* `Skycat v3.1.2 (or v3.1.3) <http://archive.eso.org/cms/tools-documentation/skycat/eso-skycat-download.html>`_ (*GMMPS* is a plugin for Skycat; Skycat has its own dependencies, amongst others `Tcl/Tk 8.4 <https://www.tcl.tk/software/tcltk/8.4.html>`_. Note that for recent Debian/Ubuntu versions Skycat is available from the respective repositories including all dependencies.)
* `Gemini IRAF <http://www.gemini.edu/sciops/data-and-results/processing-software?q=node/11823>`_ (to create the input object tables and, if necessary, pseudo-images)
* `awk <https://www.gnu.org/software/gawk/manual/gawk.html>`_ and `wget <https://www.gnu.org/software/wget/>`_ must be found in your PATH variable
* `Standard TCL library (tcllib) <http://www.tcl.tk/software/tcllib/>`_
* python-tk
* python (v2)
* `matplotlib <http://matplotlib.org/>`_


.. index:: Installation

Installation
============

*GMMPS* is a
`Skycat <http://archive.eso.org/cms/tools-documentation/skycat/eso-skycat-download.html>`_
plugin. You must have a working Skycat installation before you can install *GMMPS*. 

Installing *GMMPS* itself is easy: ::

  tar xvfz gmmps-<version>_src.tgz
  ./install.sh

.. index:: Installation; MacOS

Notes for MacOS users
---------------------

You must use MacOS 10.6 or later. There might be a version conflict depending on
which compiler suite (*clang*, *gcc*) was installed on your Mac, and how it was
installed (*homebrew*, *Xcode*, ...). To test whether you are affected, do the
following:

.. code-block:: none

   cd gmmps-<version>/src/
   make

If this runs without errors then you are fine. Just execute the installation script.

If you encounter a problem, edit *src/Makefile*. Therein, you find the following
section:

.. code-block:: none

   # For Darwin / uncomment if needed
   ifeq ($(os),Darwin)
   #  CC=gcc
   #  CXX=g++
   #  INCLUDE_DIRS += /usr/X11R6/include/X11
   #  INCLUDE_DIRS += /usr/X11R6/include
   #  INCLUDE_DIRS += /opt/include/X11/
   #  INCLUDE_DIRS += /opt/X11/include
   #  LIBRARY_DIRS += /usr/X11R6/lib
   #  LIBRARY_DIRS += /opt/X11/
   endif

If you have *gcc/g++* installed (the real ones, not the *clang* derivatives),
uncomment the lines that set the CC and CXX variables and try again. 
Perhaps you need to provide the full path to the executables to distinguish
them from their *clang* cousins.

The *make* utility should then be able to automatically pick up the relevant
include and library paths. If not, try uncommenting one or more
of the INCLUDE_DIRS and LIBRARY_DIRS lines.
