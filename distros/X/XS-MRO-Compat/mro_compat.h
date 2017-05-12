/*
----------------------------------------------------------------------------

    Devel::MRO/mro_compat.h - Provides mro functions for XS modules

    Copyright (c) 2008-2009, Goro Fuji (gfx) <gfuji(at)cpan.org>.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

----------------------------------------------------------------------------

Usage:
	#include "mro_compat.h"

Functions:
	AV*  mro_get_linear_isa(HV* stash)
	U32  mro_get_pkg_gen(HV* stash)
	U32  mro_get_cache_gen(HV* stash)
	U32  mro_get_gen(HV* stash)
	void mro_method_changed_in(HV* stash)


    See "perldoc Devel::MRO" for details.
 */

#ifndef MRO_COMPAT

#ifdef mro_get_linear_isa /* >= 5.10.0 */
#define MRO_COMPAT 0

/* NOTE:
	Because ActivePerl 5.10.0 does not provide Perl_mro_meta_init(), 
	which is used in HvMROMETA() macro, this mro_get_pkg_gen() refers
	to xhv_mro_meta directly.
*/
/* compatible with &mro::get_pkg_gen() */
#ifndef mro_get_pkg_gen
#define mro_get_pkg_gen(stash) (HvAUX(stash) ? HvAUX(stash)->xhv_mro_meta->pkg_gen : (U32)0)
#endif

#ifndef mro_get_cache_gen
#define mro_get_cache_gen(stash) (HvAUX(stash) ? HvAUX(stash)->xhv_mro_meta->cache_gen : (U32)0)
#endif

/* pkg_gen + cache_gen */
#ifndef mro_get_gen
#define mro_get_gen(stash) (HvAUX(stash) ? (HvAUX(stash)->xhv_mro_meta->pkg_gen + HvAUX(stash)->xhv_mro_meta->cache_gen) : (U32)0)
#endif

#else /* < 5.10.0  */
#define MRO_COMPAT 1
#define mro_get_linear_isa(stash) mro_compat_mro_get_linear_isa(aTHX_ stash)

#define mro_method_changed_in(stash) mor_compat_mro_method_changed_in(aTHX_ stash)
#define mro_get_pkg_gen(stash)   ((void)stash, PL_sub_generation)
#define mro_get_cache_gen(stash) ((void)stash, (U32)0) /* ??? */
#define mro_get_gen(stash)       ((void)stash, PL_sub_generation)

EXTERN_C AV*  mro_compat_mro_get_linear_isa(pTHX_ HV* const stash);
EXTERN_C void mro_compat_mro_method_changed_in(pTHX_ HV* const stash);

#endif /* !get_linear_isa */

#endif /* !MRO_COMPAT */
