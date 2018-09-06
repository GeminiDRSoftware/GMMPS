.. -*- coding: utf-8 -*-

.. index:: Slit selection algorithm

==================================
Appendix: Slit selection algorithm
==================================

This section describes how *GMMPS* decides which slits are kept
for a particular mask.

Field of View
=============

The algorithm discards an object if more than 10% of the slit
is truncated by the edge of the slit placement area, or if the
object falls entirely outside. In case of band-shuffling mode,
an object is also dropped if the slit is not entirely contained
within a science band.

.. index:: Acquisition stars; Slit positioning algorithm

Acquisition stars
=================

*GMMPS* will place *all* acquisition stars defined in the OT in *all*
masks derived from that OT.

.. _gmmakemasks_label:

.. index:: Priority; Which objects go into the mask (algorithm)

Handling object priorities
==========================

Once the acquisition stars are placed, as many priority 1 objects as
possible will be placed, followed by priority 2 and then priority 3
targets. An object of higher priority will always be placed on a mask
at the expense of any number of lower-priority objects. 

Details of the slit selection algorithm
=======================================

The follwoing information is not required for using *GMMPS*.
The slit selection algorithm is implemented in C++ and works as follows:

1. Each target is represented in a *Slit* object, and an array of *Slit*
   objects is created, too.

#. A *conflict graph* is constructed for all *Slit* objects. This is a 
   representation of all the slits on the mask, with the vectors representing 
   each respective object and edges between any two vectors that cannot both 
   be placed on the same mask. This first conflict map is made so that when 
   a slit is placed the program will know which slits it can remove (and 
   therefore remove from consideration for placement) from the main Slits 
   array. This will be useful in the following steps when we are 
   considering slits of the same priority only (but nonetheless cannot place 
   overlapping slits from different priorities).

#. The acquisition slits are placed on the mask. This step is similar to the 
   following step for slits with priorities 1 to 3, with two exceptions: 
   First, acquisition slits will be placed on all masks. Second, the spectra
   of acquisition stars are allowed to overlap (i.e. they do not create conflicts
   amongst each other). In general, a conflict graph is made for all acquisition
   stars, the objects are then ranked by degree of the object's graph representation 
   (the number of edges connected to the vertex in the conflict graph) in the 
   conflict graph that was based on objects of the same-priority. Objects are 
   then placed on 
   the graph starting with the lowest-degree object and proceeding until no 
   more objects can be placed on the graph. When an object is placed any other 
   object that conflicted with that object is removed from the Slits array, as 
   well as the local (same priority level) and global (all priority levels) 
   conflict graphs. The local conflict graph is updated during this step to 
   reflect the removal of these objects. When the local conflict graph is 
   empty then no more objects can be placed on the graph, and the program 
   moves on to the next-lower priority level and repeats this process.

#. If no auto-expansion is desired then the program moves on to the final ODF 
   creation. Otherwise the algorithm sorts all slits by the non-dispersion 
   direction (the x-direction for F2 and the y-direction for GMOS) and expands 
   each slit as much as possible in that direction without causing spectra to 
   overlap (taking into account the 
   :ref:`minimum slit separation <min_slit_sep_label>`). The modified slit 
   array is stored and the final ODFs are created.
