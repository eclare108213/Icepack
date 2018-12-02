:tocdepth: 3 

.. _addtrcr:

Adding tracers
====================

We require that any changes made to the code be implemented in such a way that they can
be "turned off" through namelist flags.  In most cases, code run with such changes should 
be bit-for-bit identical with the unmodified code.  Occasionally, non-bit-for-bit changes
are necessary, e.g. associated with an unavoidable change in the order of operations. In
these cases, changes should be made in stages to isolate the non-bit-for-bit changes, 
so that those that should be bit-for-bit can be tested separately.

Tracers added to Icepack will also require extensive modifications to the host
sea ice model, including initialization on the horizontal grid, namelist flags 
and restart capabilities.  Modifications to the Icepack driver should reflect
the modifications needed in the host model but are not expected to match completely.
We recommend that the logical namelist variable
``tr_[tracer]`` be used for all calls involving the new tracer outside of
**ice\_[tracer].F90**, in case other users do not want to use that
tracer.

A number of optional tracers are available in the code, including ice
age, first-year ice area, melt pond area and volume, brine height,
aerosols, and level ice area and volume (from which ridged ice
quantities are derived). Salinity, enthalpies, age, aerosols, level-ice
volume, brine height and most melt pond quantities are volume-weighted
tracers, while first-year area, pond area, level-ice area and all of the
biogeochemistry tracers in this release are area-weighted tracers. In
the absence of sources and sinks, the total mass of a volume-weighted
tracer such as aerosol (kg) is conserved under transport in horizontal
and thickness space (the mass in a given grid cell will change), whereas
the aerosol concentration (kg/m) is unchanged following the motion, and
in particular, the concentration is unchanged when there is surface or
basal melting. The proper units for a volume-weighted mass tracer in the
tracer array are kg/m.

In several places in the code, tracer computations must be performed on
the conserved "tracer volume" rather than the tracer itself; for
example, the conserved quantity is :math:`h_{pnd}a_{pnd}a_{lvl}a_{i}`,
not :math:`h_{pnd}`. Conserved quantities are thus computed according to
the tracer dependencies (weights), which are tracked using the arrays
``trcr_depend`` (indicates dependency on area, ice volume or snow volume),
``trcr_base`` (a dependency mask), ``n_trcr_strata`` (the number of
underlying tracer layers), and ``nt_strata`` (indicies of underlying layers). 
See **icedrv\_state.F90 and icepack\_tracers.F90**.

To add a tracer, follow these steps using one of the existing tracers as
a pattern (.e.g age).

#. **icedrv\_domain\_size.F90**: increase ``max_ntrcr`` (can also add option
   to **icepack.settings** and **icepack.build**)

#. **icepack\_tracers.F90**: 

   -  declare ``nt_[tracer]`` and ``tr_[tracer]`` 

   -  add flags and indices to the init, query and write subroutines

#. **icepack\_[tracer].F90**: create physics routines

#. **icedrv\_init.F90**: (some of this may be done in **icepack\_[tracer].F90**
   instead)

   -  declare ``tr_[tracer]``  and ``nt_[tracer]`` as needed

   -  add logical namelist variable ``tr_[tracer]``

   -  initialize namelist variable

   -  print namelist variable to diagnostic output file

   -  increment number of tracers in use based on namelist input (``ntrcr``)

   -  define tracer dependencies (``trcr_depend`` = 0 for ice area tracers, 1 for
      ice volume, 2 for snow volume, 2+``nt_[tracer]`` for dependence on
      other tracers)

#. **icedrv\_step\_mod.F90** (and elsewhere as needed):

   -  call physics routines in **icepack\_[tracer].F90**

#. **icedrv\_restart.F90**: 

   -  define restart variables

   -  call routines to read, write tracer restart data

#. **icepack\_in**: add namelist variables to *tracer\_nml* and
   *icefields\_nml*

#. If strict conservation is necessary, add diagnostics as noted for
   topo ponds in Section :ref:`ponds`

#. Update documentation, including **icepack_index.rst** and **ug_case_settings.rst**
