.. -*- coding: utf-8 -*-

.. _troubleshooting_label:

=========================
Appendix: Troubleshooting
=========================

* | **Tables not displayed properly, errors about missing information:**
  | Keep OTs, ODFs and pre-images in the same directory.
    Launch *GMMPS* from the same directory.

* | **Strange Skycat errors / behaviour:**
  | Do not run *GMMPS* in the background if displaying it from a remote
    host. If the connection to the host fails, or other similar 
    problems arise, then unusual errors occur in Skycat. It is safer/easier to 
    just run the software in the foreground. 

* | **Objects not displayed after loading OT/ODF:**
  | Objects are plotted based on their RA/DEC. If they are not shown, then 
    this can be caused by

  * the OT (ODF) not matching the pre-image

  * a conversion error somewhere along the way. For example, you fed
    RA in hour format but specified degrees in one of the *IRAF* tasks (e.g.
    when creating :ref:`pseudo-images <pseudo_image_label>` with
    :ref:`gmskcreate <gmskcreate_label>`).

* | **Desired objects not included in mask/ODF:**
  | Go back to the OT and change the priorities, e.g. ignore more objects
    or give more unwanted objects lower priorities. Alternatively, increase 
    the :ref:`number of masks <number_of_masks_label>` to be created from a 
    single OT.
