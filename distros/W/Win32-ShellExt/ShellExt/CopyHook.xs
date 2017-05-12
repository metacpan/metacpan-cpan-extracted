/* -*- c -*- */
/* 
 *   CopyHook.xs
 *
 *   Copyright (c) 2002 Jean-Baptiste Nivoit. All rights reserved.
 *   This program is free software; you can redistribute it and/or
 *   modify it under the same terms as Perl itself.
 *
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <shellapi.h> 

#ifndef PERL_VERSION
#include "patchlevel.h"
#define PERL_REVISION	5
#define PERL_VERSION	PATCHLEVEL
#define PERL_SUBVERSION	SUBVERSION
#endif

#if PERL_REVISION == 5 && (PERL_VERSION < 4 || (PERL_VERSION == 4 && PERL_SUBVERSION <= 75 ))

#    define PL_sv_undef		sv_undef
#    define PL_na		na
#    define PL_curcop		curcop
#    define PL_compiling	compiling

#endif

// that header is generated using the CopyHook/constants.pl script. you need a recent 
// ExtUtils::MakeMaker for that, it seems.
#include "CopyHook/constants.h"

MODULE = Win32::ShellExt::CopyHook		PACKAGE = Win32::ShellExt::CopyHook	PREFIX = PerlCopyHook_

PROTOTYPES:	DISABLE

INCLUDE: CopyHook/constants.xs

