/*
#    X11::XFontStruct.pm - An extension to PERL to access XFontStruct structs.
#    Copyright (C) 1996-1997  Martin Bartlett
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <X11/X.h>
#include <X11/Xlib.h>

/*
 * This is a very simple Xsub!! It provides an extension to perl that
 * allows Perl programs read-only access to the XFontStruct structure. So.
 * how do they get hold of an XFontStruct to read? Well, they use ANOTHER
 * Perl extension that blesses pointers to XFontStructs into the XFontStructPtr
 * class. Such an extension would do that by supplying a TYPEMAP as 
 * follows:
 *
 *		XFontStruct *	T_PTROBJ
 *
 * and then returning XFontStruct pointers as appropriate to the perl program.
 * 
 * An extension that does this is the XForms extension. So, using these
 * two extensions the perl programmer can do some pretty reasonable 
 * XWindows application programming.
 *
 * So whats in this package. Well, quite simply, every method in this
 * package is named after a field in the XFontStruct structure. Now, anyone
 * who has seen that structure knows that it is, in fact, a union of 
 * a bunch of other structures, the only common field of which is the
 * first field, the type field.
 *
 * However, this package is written so that you don't have to know the 
 * REAL structure of the event you are interested in, you just have to
 * know the name of the field you are after. ALL XEVent fields are
 * catered for, even the wierd vector ones. ALL are returned as perl
 * scalars of various intuitively obvious types.
 *
 * For info on how to use the XFontStructPtr extension, see XFontStructPtr.pm
 *
 */

/*
 * Structure defining the layout of the contants list
 */
#define NUMCONS 87
typedef struct _const_value {
	const char * constr;
	const double conval;
} const_value;

/*
 * The constants list
 */
static const_value  constants[NUMCONS] = {

	{ "AnyModifier", AnyModifier },
};

static double
constant(name, arg)
char *name;
int arg;
{
	int wrktop, wrkbot, wrkmid, i;

	errno = 0;
	wrktop = 0;
	wrkbot = NUMCONS-1;
	wrkmid = (NUMCONS/2)-1;
	while (wrktop < wrkmid && wrkbot > wrkmid) {
		i = strcmp(constants[wrkmid].constr, name);
		if (i == 0)
			return constants[wrkmid].conval;
		else if (i < 0)
			wrktop = wrkmid;
		else 
			wrkbot = wrkmid;
		wrkmid = wrktop + ((wrkbot - wrktop) / 2);
	}

	/*
	 * If we get here then we check the rest sequentially
	 */

	while (wrktop <=  wrkbot) {
		if (strEQ(constants[wrktop].constr, name))
			return constants[wrktop].conval;
		wrktop++;
	}

	errno = EINVAL;
	return 0;
}

/*
 * The obligitary not_here
 */
static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

MODULE = X11::XFontStruct		PACKAGE = X11::XFontStruct

PROTOTYPES: DISABLE

double
constant(name,arg)
	char *		name
	int		arg

PROTOTYPES: DISABLE
		
void
fid(xfont)
	XFontStruct *	xfont
	ALIAS:
		direction = 1
		min_char_or_byte2 = 2
		max_char_or_byte2 = 3
		min_byte1 = 4
		max_byte1 = 5
		all_chars_exist = 6
		default_char = 7
		n_properties = 8
		ascent = 9
		descent = 10
		properties = 11
		min_bounds = 12
		max_bounds = 13
		per_char = 14
	PPCODE:
	{
		XFontProp	*fprop;
		int		i, n;

		switch (ix) {
		case 0:
			PUSHs(sv_2mortal(newSViv(xfont->fid)));
			break;
		case 1:
			PUSHs(sv_2mortal(newSViv(xfont->direction)));
			break;
		case 2:
			PUSHs(sv_2mortal(newSViv(xfont->min_char_or_byte2)));
			break;
		case 3:
			PUSHs(sv_2mortal(newSViv(xfont->max_char_or_byte2)));
			break;
		case 4:
			PUSHs(sv_2mortal(newSViv(xfont->min_byte1)));
			break;
		case 5:
			PUSHs(sv_2mortal(newSViv(xfont->max_byte1)));
			break;
		case 6:
			PUSHs(sv_2mortal(newSViv(xfont->all_chars_exist)));
			break;
		case 7:
			PUSHs(sv_2mortal(newSViv(xfont->default_char)));
			break;
		case 8:
			PUSHs(sv_2mortal(newSViv(xfont->n_properties)));
			break;
		case 9:
			PUSHs(sv_2mortal(newSViv(xfont->ascent)));
			break;
		case 10:
			PUSHs(sv_2mortal(newSViv(xfont->descent)));
			break;
		case 11:
			fprop = xfont->properties;

			for(i = 0; i < xfont->n_properties; ++i) {
				XPUSHs(sv_2mortal(newSViv(fprop[i].name)));
				XPUSHs(sv_2mortal(newSViv(fprop[i].card32)));
			}
			break;
		case 12:
			XPUSHs(sv_2mortal(newSViv(xfont->min_bounds.lbearing)));
			XPUSHs(sv_2mortal(newSViv(xfont->min_bounds.rbearing)));
			XPUSHs(sv_2mortal(newSViv(xfont->min_bounds.width)));
			XPUSHs(sv_2mortal(newSViv(xfont->min_bounds.ascent)));
			XPUSHs(sv_2mortal(newSViv(xfont->min_bounds.descent)));
			XPUSHs(sv_2mortal(newSViv(xfont->min_bounds.attributes)));
			break;
		case 13:
			XPUSHs(sv_2mortal(newSViv(xfont->max_bounds.lbearing)));
			XPUSHs(sv_2mortal(newSViv(xfont->max_bounds.rbearing)));
			XPUSHs(sv_2mortal(newSViv(xfont->max_bounds.width)));
			XPUSHs(sv_2mortal(newSViv(xfont->max_bounds.ascent)));
			XPUSHs(sv_2mortal(newSViv(xfont->max_bounds.descent)));
			XPUSHs(sv_2mortal(newSViv(xfont->max_bounds.attributes)));
			break;
		case 14:
			n = (xfont->max_char_or_byte2 -
				     xfont->min_char_or_byte2) + 1;

			for(i = 0; i < n; ++i) {
				XPUSHs(sv_2mortal(newSViv(xfont->per_char[i].lbearing)));
       	        		XPUSHs(sv_2mortal(newSViv(xfont->per_char[i].rbearing)));
       	        		XPUSHs(sv_2mortal(newSViv(xfont->per_char[i].width)));
				XPUSHs(sv_2mortal(newSViv(xfont->per_char[i].ascent)));
				XPUSHs(sv_2mortal(newSViv(xfont->per_char[i].descent)));
				XPUSHs(sv_2mortal(newSViv(xfont->per_char[i].attributes)));
			}
		}
	}

