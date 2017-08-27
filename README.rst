Introduction
============

*zlib* is a collection of assembly language libraries for the TI-83 Plus
series of programmable graphing calculators.  The libraries are designed, but
not required, to work with *zproj* (link: zproj_).

Organization and Installation
=============================


The libraries reside in ``lib/spasm``.  The extra layer of indirection
under ``lib`` accommodates the possibility of supporting additional
assembler syntaxes in the future.

The organization of the libraries also cooperates with *zproj*, which
is able to install files arranged in this way.  In particular, if *zproj*
is installed, running

    ``zproj install lib``

in the top-level directory of this repository will install the libraries
for use with *zproj*.

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
  ``draw.asm`` and ``screen.asm``.

These libraries depend on each other as follows:

- ``interrupt.asm``

  - ``keyboard.asm``

  - ``timer.asm``

- ``screen.asm``

  - ``draw.asm``

    - ``write.asm``

In this diagram, each library depends on all libraries above it in the
hierarchy.  For example, ``keyboard.asm`` and ``timer.asm`` both depend
directly on ``interrupt.asm``, while ``write.asm`` depends directly on
``draw.asm`` and indirectly on ``screen.asm``.

Fonts
=====

This distribution contains definitions of two monospaced fonts compatible with
the ``write.asm`` library described above:

- ``fontFBF.asm``
- ``fontSBF.asm``

These two fonts differ primarily in glyph size: those of the first are
**F**\ ive-**B**\ y-**F**\ ive, while those of the second are
**S**\ even-**B**\ y-**F**\ ive, where the dimensions are of the form
<pixels high> by <pixels wide>.  Note, however, that the fonts are both
technically *six* pixels wide, rather than five, to create a pixel-wide
space between adjacent characters.  This matters less than the height,
which is currently implemented as advertised.

Supplementary Files
===================
This distribution also contains two assembler source files which complement
the above libraries:

- ``app.asm`` -- This file supports the structuring of TI-83 plus series
  calculator applications [#]_.

- ``ti83plus.inc`` -- This is a modified version of the standard assembler
  include file supplied by TI. [#]_

.. [#] The term *application* used here refers to the specific TI-83 Plus
       series executable format of that name, not to executables in general.

.. [#] The precise nature of this file's license is unclear, but it seems
       safe to distribute.  I obtained the file from ti83plus.inc_.  Notably,
       it does not contain the license comment included in TI's original
       version, which demands not to be removed from any copies.  I have not
       added this comment to the version I distribute because I have no way
       of knowing whether the file is actually a copy of TI's version.

       **I do not claim authorship of this include file.  If either TI or the
       author of the new version objects to its inclusion in this project,
       please contact me at andrewmichaelhenry@gmail.com.**

.. _ti83plus.inc: http://www.brandonw.net/calcstuff/ti83plus.txt

.. _zproj: https://github.com/AndrewMHenry/zproj
