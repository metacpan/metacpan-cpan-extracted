/*
 * Copyright (C) 2000, 2001, 2002, 2004 Loic Dachary <loic@senga.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "perlio.h"

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif /* HAVE_CONFIG_H */

/*
 * Perl config.h defines HAS_VPRINTF if printf variants are 
 * available
 */
#ifdef HAS_VPRINTF
#define HAVE_VSNPRINTF
#endif /* HAS_VPRINTF */

#include "unac.h"

static char* buffer;
static int buffer_length;

static void unac_debug_print(const char* message, void* data)
{
  if(PerlIO_puts(PerlIO_stderr(), message) != strlen(message))
    perror("unac_debug_print");
}

MODULE = Text::Unaccent PACKAGE = Text::Unaccent PREFIX = perl_

BOOT:
	buffer = 0;
	buffer_length = 0;
	{
		SV* sv;
		sv = get_sv("Text::Unaccent::DEBUG_NONE", TRUE|GV_ADDMULTI);
		sv_setiv(sv, UNAC_DEBUG_NONE);
		sv = get_sv("Text::Unaccent::DEBUG_LOW", TRUE|GV_ADDMULTI);
		sv_setiv(sv, UNAC_DEBUG_LOW);
		sv = get_sv("Text::Unaccent::DEBUG_HIGH", TRUE|GV_ADDMULTI);
		sv_setiv(sv, UNAC_DEBUG_HIGH);
	}

SV*
perl_unac_string(charset,in)
	char* charset
	char* in
	PROTOTYPE: $$
	CODE:
		STRLEN in_length;
		in_length = SvCUR(ST(1));
		if(unac_string(charset,
			       in, in_length,
			       &buffer, &buffer_length) == 0) {
	          RETVAL = newSVpv(buffer, buffer_length);
		} else {
		  perror("unac_string");
		  RETVAL = &PL_sv_undef;
		}
         OUTPUT:
		RETVAL

SV*
perl_unac_string_utf16(in)
	char* in
	PROTOTYPE: $
	CODE:
		STRLEN in_length;
		in_length = SvCUR(ST(0));
		if(unac_string_utf16(in, in_length,
				     &buffer, &buffer_length) == 0) {
	          RETVAL = newSVpv(buffer, buffer_length);
		} else {
		  perror("unac_string_utf16");
		  RETVAL = &PL_sv_undef;
		}
	OUTPUT:
		RETVAL

SV*
perl_unac_version()
	CODE:
	        RETVAL = newSVpv((char*)unac_version(), 0);
	OUTPUT:
		RETVAL

void
perl_unac_debug(in)
	int in
	PROTOTYPE: $
	CODE:
	        unac_debug_callback(in, unac_debug_print, NULL);
