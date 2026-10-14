Finite Element Method Magnetics
David Meeker
dmeeker@ieee.org

Version 4.0 17Jun2004
----------------------------------------------------------------------------
* Added some cosmetic but useful modifications (thanks Davide Pizzolato). 
  Users can now switch between documents via tabs.  The toolbars have been
  re-arranged so that the display doesn't "jump around" when switched
  between different document types.

Version 4.0 27May2004
----------------------------------------------------------------------------
* Added file-based interprocess communication method. This is
  the basis for an interface to Octave. 

Version 4.0 15May2004 Release Candidate 1:
----------------------------------------------------------------------------
* Wire size and type as as material properties for "bulk" wound coil
  regions.
* Continuum model of proximity and skin effect losses added.  This model
  automatically accounts for the AC losses in "bulk" wound coil regions.
* Extra "Properties" section in the main menu added for "Exterior Region."
  The extra "Exterior Region" properties are only active for
  axisymmetric problems.  These extra parameters are required to model
  axisymmetric unbounded regions via the Kelvin Transformation approach.
* All intermediate temporary files are now automatically cleaned up.

Version 4.0 01Apr2004 Development Release:
----------------------------------------------------------------------------
* MathLink interface to Mathematica added.
* Capability to run FEMM as an ActiveX server added.

Version 4.0 26Jan2004 Development Release:
----------------------------------------------------------------------------
* New drag-and-drop materials library implemented.
* Fixes a number of bugs identified in the 18Nov2003 version.

Version 4.0 18Nov2003 Development Release:
----------------------------------------------------------------------------
Substantive changes since the last Development Release:

* A somewhat better notion of "circuits" has been implemented for magnetic
  problems.  The "circuit" properties now allow the user to specify either
  series-connected or parallel connected regions.  In addition,
  series-connected regions can also be assigned a number of turns, so that
  the modeling of multi-turn coils is simplfied.  The number of turns for a
  region is specified at the block label level (e.g. like the way that
  magnetization direction is specified.) In the postprocessor, the program
  calculates the voltage drop, flux link, etc. for each "circuit".  A new
  button has been added to the postprocessor toolbar to make it easier to
  see the circuit results. 

* Density plot of J has been added to the density plot choices for DC
  magnetics problems.

* An extra "problem definition" attibute has been added to allow the user to
  specify the minimum angle constraint used by Triangle when meshing a
  geometry.  The value of this constraint was previously hard-coded.
  Occasionally, a geometries with sharp angles can arise that require the
  minimum angle constraint to be reduced for proper meshing.

* A "log plot" button has been added to the BH curve definition dialog that
  points the entered BH curve with H on a log scale.  The log plot can make
  it easier to visualize the curve at low values of H.

* Extra functionality has been added to the Materials Library that makes it
  possible to import material definitions from either another input file or
  alternate versions of the materials library.

* An extra block integral has been added to magnetic problems for
  calculating moment of inertia.

* The DXF import has been improved.  The import routine is now more savvy
  about identifying and automatically resolving potential DXF import
  problems. Since it was pointed out to me that most DXF problems involve
  endpoints of lines that don't meet, all "orphaned" lines are displayed
  after the DXF import so that the user can inspect for possible problems.
  Multiply defined regions are also noted in the postprocessor, which is
  also a common symptom of DXF import errors.

* A preference has been added to the magnetics postprocessor so that Hc is
  subtracted from what FEMM usually reports a H inside permanent magnets,
  conforming to the "classic" way of thinking about flux inside magnets.

Some things that are still "to do" include (but aren't limited to):

* Take wire size and type as as material properties for wound coil regions.

* Display boundary labels in some way (e.g. similar to the way that the
  names of block labels are displayed?)

----------------------------------------------------------------------------
Version 4.0 16Sept2003 Development Release:

Few changes in solver functionality have been implemented since v3.3 in this
development release.  The significant change is that the magnetics pre- and
post-processors and the electrostatic pre- and post-processors (previously
known as the separate program, BELA) are all incorporated into one
"interactive shell."

