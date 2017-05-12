/*
 *  Win32API::Const -- Basic API Constants -- parsed from egcs 1.1
 *  Defines.h, Messages.h, Errors.h, Base.h, & Sockets.h
 *  Copyright (C) 1998 Brian Dellert: aspider@pobox.com, 206/689-6828,
 *  http://www.applespider.com

 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License as published by the
 *  Free Software Foundation; either version 2 of the License, or (at your
 *  option) any later version.
 *
 *  This program is distributed in the hope that it will be useful, but
 *  WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 *  or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 *  for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program (gpl.license.txt); if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
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

#include "win32.const.h"

char* const_match_str;
const char** const_match_names;
char* const_match_vals;
size_t const_sizeof_val;

char* lookup_const_array (long min, long max) {
	int match;
	long mid;

	if (max < min) {
		return 0;
	}

	mid = (max + min) /2;
	match = strcmp(const_match_str, const_match_names[mid]);

	if (match <0) {
		return lookup_const_array(min, mid-1);
	}
	else if (match > 0) {
		return lookup_const_array(mid+1, max);
	}
	else {
		return const_match_vals + mid*const_sizeof_val;
	}
}

long lookup_const_start (long min, long max) {
	int match;
	long mid;

	if (max < min || max<0) {
		return min;
	}

	mid = (max + min) /2;
	match = strcmp(const_match_str, const_match_names[mid]);

	if (match <0 || max<0) {
		return lookup_const_start(min, mid-1);
	}
	else if (match > 0) {
		return lookup_const_start(mid+1, max);
	}
	else {
		return mid;
	}
}

long lookup_const_end (long min, long max) {
	int match;
	long mid;

	if (max < min || max<0) {
		return max;
	}

	mid = (max + min) /2;
	match = strcmp(const_match_str, const_match_names[mid]);

	if (match<0) {
		int len = strlen(const_match_str);
		if (strncmp(const_match_str, const_match_names[mid], len)==0)
			match = 1;
	}
	if (match <0) {
		return lookup_const_end(min, mid-1);
	}
	else if (match > 0) {
		return lookup_const_end(mid+1, max);
	}
	else {
		return mid;
	}
}


short* match_short(char* name) {
	const_match_str   = name;
	const_match_names = const_short_names;
	const_match_vals  = (char*)const_short_vals;
	const_sizeof_val  = sizeof(short);

	return (short*)lookup_const_array(0, const_short_max);
}

long* match_long(char* name) {
	const_match_str   = name;
	const_match_names = const_long_names;
	const_match_vals  = (char*)const_long_vals;
	const_sizeof_val  = sizeof(long);

	return (long*)lookup_const_array(0, const_long_max);
}

unsigned long* match_ulong(char* name) {
	const_match_str   = name;
	const_match_names = const_unsigned_long_names;
	const_match_vals  = (char*)const_unsigned_long_vals;
	const_sizeof_val  = sizeof(unsigned long);

	return (unsigned long*)lookup_const_array(0, const_unsigned_long_max);
}

char* match_str(char* name) {
	char** match;
	const_match_str   = name;
	const_match_names = const_charptr_names;
	const_match_vals  = (char*)const_charptr_vals;
	const_sizeof_val  = sizeof(char*);

	match = (char**)lookup_const_array(0, const_charptr_max);
	return match ? *match : 0;
}

wchar_t* match_wstr(char* name) {

	wchar_t** match;
	const_match_str   = name;
	const_match_names = const_wchar_tptr_names;
	const_match_vals  = (char*)const_wchar_tptr_vals;
	const_sizeof_val  = sizeof(wchar_t*);

	match = (wchar_t**)lookup_const_array(0, const_wchar_tptr_max);

	return match ? *match : 0;
}

unsigned char match_number(char* name, double* num) {
	void* val_ptr;

	val_ptr = (void*)match_short(name);
	if (val_ptr) {
		*num = *(short*)val_ptr;
		return 1;
	}

	val_ptr = (void*)match_long(name);
	if (val_ptr) {
		*num = *(long*)val_ptr;
		return 1;
	}

	val_ptr = (void*)match_ulong(name);
	if (val_ptr) {
		*num = *(unsigned long*)val_ptr;
		return 1;
	}

	return 0;
}


MODULE = Win32API::Const		PACKAGE = Win32API::Const

SV*
constant(name)
	char* name;
	PREINIT:
	char* str;
	double num;
	CODE:
	errno=0;
	if (!*name) {
		errno = EINVAL;
		ST(0) = &sv_undef;
	}
	else if (match_number(name, &num)) {
		ST(0) = sv_newmortal();
		sv_setnv(ST(0), (double)num);
	}
	else if (str = match_str(name)) {
		ST(0) = sv_newmortal();
		sv_setpv(ST(0), (char*)str);
	}
	else {
		ST(0) = &sv_undef;
	    errno = ENOENT;
	}

void
constant_get(type, pos)
	unsigned char type;
	long pos;
	PPCODE:
	errno=0;
	if (pos < 0) {
		errno = EINVAL;
		XSRETURN_EMPTY;
	}
	switch (type) {
		case 1:
			if (pos > const_short_max) {
				errno = EINVAL;
				XSRETURN_EMPTY;
			}
			EXTEND(SP, 2);
			PUSHs(sv_2mortal(newSVpv((char*)const_short_names[pos],0)));
			PUSHs(sv_2mortal(newSViv(const_short_vals[pos])));
			break;

		case 2:
			if (pos > const_long_max) {
				errno = EINVAL;
				XSRETURN_EMPTY;
			}
			EXTEND(SP, 2);
			PUSHs(sv_2mortal(newSVpv((char*)const_long_names[pos],0)));
			PUSHs(sv_2mortal(newSViv(const_long_vals[pos])));
			break;

		case 3:
			if (pos > const_unsigned_long_max) {
				errno = EINVAL;
				XSRETURN_EMPTY;
			}
			EXTEND(SP, 2);
			PUSHs(sv_2mortal(newSVpv((char*)const_unsigned_long_names[pos],0)));
			PUSHs(sv_2mortal(newSVnv(const_unsigned_long_vals[pos])));
			break;

		case 4:
			if (pos > const_charptr_max) {
				errno = EINVAL;
				XSRETURN_EMPTY;
			}
			EXTEND(SP, 2);
			PUSHs(sv_2mortal(newSVpv((char*)const_charptr_names[pos],0)));
			PUSHs(sv_2mortal(newSVpv((char*)const_charptr_vals[pos],0)));
			break;

		default:
			errno = EINVAL;
	}

void
constant_match_range(type, name)
	unsigned char type;
	const char* name;
	PREINIT:
	long start=0;
	long end=-1;
	PPCODE:
	errno=0;
	switch (type) {
		case 1:
			const_match_str   = (char*)name;
			const_match_names = const_short_names;
			const_sizeof_val  = sizeof(short);

			start = lookup_const_start(0, const_short_max);
			end   = lookup_const_end(0, const_short_max);
			break;

		case 2:
			const_match_str   = (char*)name;
			const_match_names = const_long_names;
			const_sizeof_val  = sizeof(long);
			start = lookup_const_start(0, const_long_max);
			end   = lookup_const_end(0, const_long_max);
			break;

		case 3:
			const_match_str   = (char*)name;
			const_match_names = const_unsigned_long_names;
			const_sizeof_val  = sizeof(unsigned long);

			start = lookup_const_start(0, const_unsigned_long_max);
			end   = lookup_const_end(0, const_unsigned_long_max);
			break;

		case 4:
			const_match_str   = (char*)name;
			const_match_names = const_charptr_names;
			const_sizeof_val  = sizeof(char*);

			start = lookup_const_start(0, const_charptr_max);
			end   = lookup_const_end(0, const_charptr_max);
			break;

		default:
			errno = EINVAL;
	}
	EXTEND(SP, 2);
	PUSHs(sv_2mortal(newSViv(start)));
	PUSHs(sv_2mortal(newSViv(end)));

void
constant_full_range(type)
	unsigned char type;
	PREINIT:
	long end=-1;
	PPCODE:
	errno=0;
	switch (type) {
		case 1:
			end = const_short_max;
			break;
		case 2:
			end = const_long_max;
			break;
		case 3:
			end = const_unsigned_long_max;
			break;
		case 4:
			end = const_charptr_max;
			break;

		default:
			errno = EINVAL;
	}
	EXTEND(SP, 2);
	PUSHs(sv_2mortal(newSViv(0)));
	PUSHs(sv_2mortal(newSViv(end)));
