!=======================================================================
!

      module icepack_fluffballs

      use icepack_kinds
      use icepack_warnings, only: warnstr, icepack_warnings_add
      use icepack_warnings, only: icepack_warnings_setabort, icepack_warnings_aborted

      implicit none

      private
      public :: increment_fluff

!=======================================================================

      contains

!=======================================================================

!  Increase ice fluff tracer by timestep length.

      subroutine increment_fluff (dt, ifluff)

      real (kind=dbl_kind), intent(in) :: &
         dt                    ! time step

      real (kind=dbl_kind), intent(inout) :: &
         ifluff

      character(len=*),parameter :: subname='(increment_fluff)'

      ifluff = ifluff + dt / 86400.0d0

      ! Other processes that could impact the number of fluffballs

      ! Congelation growth (see icepack_isotopes.F90)

      ! Snow-ice formation (see icepack_aerosols.F90)

      ! Evaporation / Sublimation

      ! Condensation

      ! Snow fall

      ! Snow melt

      ! Top ice melt or internal ice melt.

      end subroutine increment_fluff

!=======================================================================

      end module icepack_fluffballs

!=======================================================================
