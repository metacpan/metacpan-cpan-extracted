/*
  Kakasi.xs

  Copyright (C) 1998, 1999, 2000 NOKUBI Takatsugu <knok@daionet.gr.jp>
	    (C) 2003 Dan Kogai <dankogai@dan.co.jp>
    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

$Id: Kakasi.xs,v 2.0 2003/05/22 18:19:11 dankogai Exp $
*/

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "libkakasi.h"

static int dic_closed = 1;

MODULE = Text::Kakasi		PACKAGE = Text::Kakasi

PROTOTYPES: ENABLE

int
xs_getopt_argv(sv, ...)
    INIT:
	int i;
    CODE:
        if (!dic_closed){
	    kakasi_close_kanwadict();
	}
        for (i = 0; i < items; i ++) {
	    XPUSHs((SV *)SvPV(ST(i), PL_na));
	}
        RETVAL = kakasi_getopt_argv(items, (char **)&ST(items));
    OUTPUT:
	RETVAL

SV*
xs_do_kakasi(src_sv)
	SV* src_sv
    INIT:
	char *dst_pv;
    CODE:
	dst_pv = kakasi_do(SvPV(src_sv, PL_na));
	RETVAL = (dst_pv != NULL) ?
	        newSVpv(dst_pv, strlen(dst_pv)) : &PL_sv_undef;
    OUTPUT:
	RETVAL

int
xs_close_kanwadict()
    CODE:
	RETVAL = kakasi_close_kanwadict();
    OUTPUT:
	RETVAL
