/*******************************************************************************
*
* MODULE: DataTree.xs
*
********************************************************************************
*
* DESCRIPTION: XS utilities for Tk::DataTree
*
********************************************************************************
*
* $Project: /Tk-DataTree $
* $Author: mhx $
* $Date: 2008/01/11 00:18:48 +0100 $
* $Revision: 8 $
* $Snapshot: /Tk-DataTree/0.06 $
* $Source: /DataTree.xs $
*
********************************************************************************
*
* Copyright (c) 2004-2008 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#if !defined(IVSIZE) && defined(LONGSIZE)
#  define IVSIZE LONGSIZE
#endif
#ifndef IVSIZE
#  define IVSIZE 4
#endif

#ifndef IVdf
#  if IVSIZE == LONGSIZE
#    define IVdf "ld"
#    define UVuf "lu"
#  else
#    if IVSIZE == INTSIZE
#      define IVdf "d"
#      define UVuf "u"
#    endif
#  endif
#endif

#ifndef NVff
#  if defined(USE_LONG_DOUBLE) && defined(HAS_LONG_DOUBLE) && defined(PERL_PRIfldbl)
#    define NVff PERL_PRIfldbl
#  else
#    define NVff "f"
#  endif
#endif

MODULE = Tk::DataTree			PACKAGE = Tk::DataTree

PROTOTYPES: ENABLE

################################################################################
#
#   ROUTINE: _getval
#
#   WRITTEN BY: Marcus Holland-Moritz             ON: Mar 2004
#   CHANGED BY: Marcus Holland-Moritz             ON: Jan 2008
#
################################################################################

void
_getval(val)
	SV *val

	PREINIT:
		SV *text;

	PPCODE:
		if (SvROK(val) || !(SvPOK(val) || SvPOKp(val))) {
		  SV *copy = sv_mortalcopy(val);
		  char  *p;
		  STRLEN l;
		  p = SvPV(copy, l);
		  text = newSVpvn(p, l);
		}
		else {
		  if (SvPOK(val) || SvPOKp(val)) {
		    text = newSVpvn(SvPVX(val), SvCUR(val));
#if defined(SvUTF8) && defined(SvUTF8_on)
		    if (SvUTF8(val))
		      SvUTF8_on(text);
#endif
		    if (SvNOK(val))
		      sv_catpvf(text, " (%"NVff")", SvNVX(val));
#if defined(SvUOK) && defined(SvUVX)
		    else if (SvUOK(val))
		      sv_catpvf(text, " (%"UVuf")", SvUVX(val));
#endif
		    else if (SvIOK(val))
		      sv_catpvf(text, " (%"IVdf")", SvIVX(val));
		  }
		  else {
		    text = newSVpvn("", 0);
		    if (SvNOK(val))
		      sv_catpvf(text, "%"NVff, SvNVX(val));
#if defined(SvUOK) && defined(SvUVX)
		    else if (SvUOK(val))
		      sv_catpvf(text, "%"UVuf, SvUVX(val));
#endif
		    else if (SvIOK(val))
		      sv_catpvf(text, "%"IVdf, SvIVX(val));
		  }
		}

		PUSHs(sv_2mortal(text));
		XSRETURN(1);
