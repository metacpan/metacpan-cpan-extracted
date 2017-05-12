
/* Copyright 1997, 1998 by Ken Fox */

#include <X11/xpm.h>
#undef FUNC

#include "x-api.h"


MODULE = X11::Xpm		PACKAGE = X::Xpm

PROTOTYPES: ENABLE

void
ReadFileToPixmap(display, d, filename)
	Display *		display
	Drawable		d
	char *			filename
	PREINIT:
	    int r;
	    Pixmap icon;
	    Pixmap mask;
	PPCODE:
	    r = XpmReadFileToPixmap(display, d, filename, &icon, &mask, 0);
	    if (r == XpmSuccess) {
		XPUSHs(sv_setref_pv(sv_newmortal(), Pixmap_Package, (void *)icon));
		XPUSHs(sv_setref_pv(sv_newmortal(), Pixmap_Package, (void *)mask));
	    }

void
CreatePixmapFromData_array(display, d, data_in)
	Display *		display
	Drawable		d
	SV *			data_in
	PREINIT:
	    int r, len;
	    Pixmap icon;
	    Pixmap mask;
	    SV **sv;
	    AV *av;
	    char **data;
	PPCODE:
	    if (SvROK(data_in) && SvTYPE(SvRV(data_in)) == SVt_PVAV) {
		av = (AV *)SvRV(data_in);
		len = AvFILL(av) + 1;
	    }
	    else {
		croak("data_in is not an array reference");
	    }
	    if ((data = malloc(len * sizeof(char *))) == 0) {
		croak("not enough memory for Xpm data");
	    }
	    for (r = 0; r < len; ++r) {
		sv = av_fetch(av, r, 0);
		if (sv) {
		    data[r] = SvPV(*sv, na);
		}
		else {
		    data[r] = "";
		}
	    }
	    r = XpmCreatePixmapFromData(display, d, data, &icon, &mask, 0);
	    if (r == XpmSuccess) {
		XPUSHs(sv_setref_pv(sv_newmortal(), Pixmap_Package, (void *)icon));
		XPUSHs(sv_setref_pv(sv_newmortal(), Pixmap_Package, (void *)mask));
	    }
	    free(data);
