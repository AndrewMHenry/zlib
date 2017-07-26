Introduction
============

``zlib`` is a collection of assembly language libraries for the TI-83 Plus
series of calculators.  The libraries are designed, but not required, to
work with ``zproj`` (``https://github.com/AndrewMHenry/zproj``).

Organization
============

The libraries reside in ``lib/spasm``.  The extra layer of indirection
under ``lib`` accommodates the possibility of supporting additional
assembler syntaxes in the future.

Libraries
=========

This distribution contains the following assembly language libraries:

- ``interrupt.asm`` -- This library facilitates the creation of custom
  interrupt routines which run at uniform time intervals.

- ``keyboard.asm`` -- This library provides routines that read user input
  from the keyboard.

- ``timer.asm`` -- This library implements an interrupt-based timer for use
  by applications.

- ``screen.asm`` -- This library implements an interface for staging
  and applying changes to the contents of the screen.

- ``draw.asm`` -- This library contains a collection of routines that use
  the ``screen.asm`` interface to draw simple geometric shapes on the
  screen.

- ``write.asm`` -- This library implements text-drawing routines using
  routines from ``screen.asm``.

Supplementary Files
===================
This distribution also contains two assembler source files which complement
the above libraries:

- ``app.asm`` -- This file supports the structuring of TI-83 plus series
  calculator applications [#]_.

- ``fontFBF.asm`` -- This file defines a simple monospaced font compatible with
  the included ``write.asm`` library (see description above).

Notably, this distribution does NOT include a ``ti83plus.inc`` include file
for licensing reasons.  No explicit permission is given by TI (the original
author) to distribute it, and the ``spasm``-adapted version is licensed under
the GPL, which I do not want to use.  Since some of the libraries included
in this distribution depend on this include file, the author recommends that
the user download this file from the Internet.

.. [#] The term *application* used here refers to the specific TI-83 Plus
       series executable format of that name, not to executables in general.
