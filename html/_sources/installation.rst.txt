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

*GMMPS* |version| comes with the source code and example images. The latest version is recommended. At least version 1.4.5 is required.
It is available at
`http://software.gemini.edu/gmmps/gmmps-1.5.1.tgz <http://software.gemini.edu/gmmps/gmmps-1.5.1.tgz>`_ (155 MB).

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

Running *GMMPS* requires a standard unix-like X11 environment. MacOS users should install `XQuartz <https://www.xquartz.org/>`_. Users of recent Ubuntu releases should start a Xorg session.

Compiling *GMMPS* from sources requires a C/C++ compiler, make, and X11 development libraries. MacOS users will need to download Xcode from the Mac App Store and run it at least once to install
the command line tools.

*GMMPS* now comes with all the packages required to compile it including Tcl/Tk and Skycat. They are installed into the bin and lib directories of *GMMPS* to keep them isolated from any other versions on your system.

The `Gemini IRAF package <http://www.gemini.edu/node/11823>`_ is 
also needed to create the input object tables and, if necessary, 
pseudo-images.

.. index:: Installation

Installation
============

Pre-compiled versions of GMMPS are available for MacOS and 
a few standard flavors of Linux. The compatibility list is not 
exhaustive, it only lists systems that have been tested.

======================================================================================  =============== =========================
File                                                                                    Compiled on     Compatible With
======================================================================================  =============== =========================
`gmmps-1.5.1_rh5_32.tgz <http://software.gemini.edu/gmmps/gmmps-1.5.1_rh5_32.tgz>`_     CentOS 5
`gmmps-1.5.1_rh6_64.tgz <http://software.gemini.edu/gmmps/gmmps-1.5.1_rh6_64.tgz>`_     CentOS 6
`gmmps-1.5.1_rh7_64.tgz <http://software.gemini.edu/gmmps/gmmps-1.5.1_rh7_64.tgz>`_     CentOS 7        Ubuntu 17/18, Fedora 28
`gmmps-1.5.1_ub16_64.tgz <http://software.gemini.edu/gmmps/gmmps-1.5.1_ub16_64.tgz>`_   Ubuntu 16.04    Ubuntu 17/18
`gmmps-1.5.1_macos.tgz <http://software.gemini.edu/gmmps/gmmps-1.5.1_macos.tgz>`_       macOS 10.13.6 
======================================================================================  =============== =========================

Untar the distribution file and then::

  cd /some_path/gmmps-<version>
  ./gmmps_config.sh

to configure the paths in the *GMMPS* startup script (./bin/gmmps).


To compile *GMMPS* from raw sources, do: ::

  tar xvfz gmmps-<version>.tgz
  cd gmmps-<version>
  ./install.sh

There are known problems with compiling *GMMPS* on Ubuntu 17, 18, and Fedora 28. Please use the compatible binary releases on these operating systems.

Finally, put /some_path/gmmps-<version>/bin/gmmps in your path.

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

If you have *gcc/g++* installed (not the *clang* derivatives),
uncomment the lines that set the CC and CXX variables and try again.
Perhaps you need to provide the full path to the executables to distinguish
them from their *clang* cousins.

The *make* utility should then be able to automatically pick up the relevant
include and library paths. If not, try uncommenting one or more
of the INCLUDE_DIRS and LIBRARY_DIRS lines.
