/* vim: ts=4 sw=4
 */
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"


#include <stdlib.h>
#include <stdio.h>
#include <wchar.h>
#include <gmp.h>

#include <unicode.h>
#include <nsdefs.h>
#include <uninum.h>

typedef HV* Unicode__Number;          /* Unicode::Number */
typedef HV* Unicode__Number__System;  /* Unicode::Number::System */

const char* uninum_error_str() {
	switch(uninum_err) {
		case NS_ERROR_OKAY:                  return "No error";
		case NS_ERROR_BADCHARACTER:          return "String contains illegal character";
		case NS_ERROR_DOESNOTFIT:            return "Value does not fit into binary type";
		case NS_ERROR_NUMBER_SYSTEM_UNKNOWN: return "The number system identifier is unknown";
		case NS_ERROR_BADBASE:               return "The specified base is not acceptable";
		case NS_ERROR_NOTCONSISTENTWITHBASE: return "The string contains a digit too large for the base";
		case NS_ERROR_OUTOFMEMORY:           return "Storage allocation failed";
		case NS_ERROR_RANGE:                 return "Number is larger than is representable in the number system";
		case NS_ERROR_OUTSIDE_BMP:           return "The string contains a character outside the BMP";
		case NS_ERROR_NOZERO:                return "The number system cannot represent zero";
		case NS_ERROR_ILLFORMED:             return "The string is not a valid number in the specified number system for a reason other than one of those specified above, e.g. it lacks a required number marker.";
	}
	return "Invalid error";
}

int uninum_is_ok() {
	return uninum_err == NS_ERROR_OKAY;
}

MODULE = Unicode::Number      PACKAGE = Unicode::Number

PROTOTYPES: ENABLE

const char*
version(Unicode::Number self)
	CODE:
		RETVAL = uninum_version();
	OUTPUT: RETVAL

# retrieves number systems as an array
# and caches the result
AV*
number_systems(Unicode::Number self)
	INIT:
		AV* l;
		char* ns_str;
		STRLEN len;
		int ns_num;
		AV** ref;
		int which;
		int count;
	CODE:
		if( NULL == (ref = (AV**)hv_fetchs(self, "_ns_cache", 0)) ) {
			dSP;
			EXTEND(SP, 4);
			SV* sv_uns_package = sv_2mortal(newSVpvs("Unicode::Number::System"));
			SV* sv_ns_str = sv_2mortal(newSVpv("", 0));
			SV* sv_ns_num = sv_2mortal(newSViv(0));
			/* not cached yet */
			l = (AV *)sv_2mortal((SV *)newAV());
			/* which = 1 : get all number systems that can be used in both
			 *             directions
			 * which = 0 : get number systems that can only be used from string
			 *             to numbers
			 */
			for(which = 0; which <= 1; which++ ) {
				while (ns_str = ListNumberSystems(1,which)) {
					HV * rh;

					/* get the ID for the number system */
					ns_num = StringToNumberSystem(ns_str);

					len = strlen(ns_str);
					sv_setpvn(sv_ns_str, ns_str, len);
					sv_setiv(sv_ns_num, ns_num);

					ENTER;
					SAVETMPS;
					PUSHMARK(SP);
					PUSHs(sv_uns_package);
					PUSHs(sv_ns_str);
					PUSHs(sv_ns_num);
					PUSHs(boolSV( !which ));
					PUTBACK;
					count = call_pv("Unicode::Number::System::_new", G_SCALAR);
					SPAGAIN;
					if (count != 1)
						croak("Big trouble\n");
					rh = (HV*) POPs;
					SvREFCNT_inc(rh);
					PUTBACK;
					FREETMPS;
					LEAVE;


					av_push(l, (SV *)rh); /* and add to list */
				}
				ListNumberSystems(0,0); /* Reset */
			}
			hv_stores(self, "_ns_cache", SvREFCNT_inc((SV*) l));
			ref = &l;
		}
		RETVAL = (AV*)SvREFCNT_inc(*ref);
	OUTPUT: RETVAL

# this will return a UTF-8 string
SV*
_StringToNumberString(Unicode::Number self, SV* u32_str_sv, int NumberSystem)
	INIT:
		U32* u32_str;
		union ns_rval val;
		STRLEN len;
		int i;
	CODE:
		uninum_err = 0;

		u32_str = (U32*)SvPV(u32_str_sv, len);

		/*[>DEBUG<]for(i = 0; i < len/sizeof(U32); i++) {
			fprintf(stderr, "%lx\n", u32_str[i]);
		}*/
		StringToInt(&val, u32_str, NS_TYPE_STRING, NumberSystem);

		if(0 != uninum_err){
			/* TODO structured exceptions: croak_sv */
			croak("libuninum: (%d) %s", uninum_err, uninum_error_str());
		} else {
			len = strlen(val.s);
			RETVAL = newSVpv(val.s, len);
			Safefree(val.s);
		}
	OUTPUT: RETVAL

# this returns an integer ID
SV* _GuessNumberSystem(Unicode::Number self, SV* u32_str_sv)
	INIT:
		U32* u32_str;
		STRLEN len;
		int ns;
	CODE:
		uninum_err = 0;

		u32_str = (U32*)SvPV(u32_str_sv, len);

		ns = GuessNumberSystem(u32_str);

		if(0 != uninum_err){
			/* TODO structured exceptions: croak_sv */
			croak("libuninum: (%d) %s", uninum_err, uninum_error_str());
		} else {
			RETVAL = newSViv(ns);
		}
	OUTPUT: RETVAL

# this returns a UTF-32 string in the native byte-order
SV*
_NumberStringToString(Unicode::Number self, SV* decimal_str_sv, int NumberSystem)
	INIT:
		char* decimal_str;
		union ns_rval val;
		STRLEN len;
		U32* u32_str;
		U32* u32_idx;
	CODE:
		decimal_str = SvPV(decimal_str_sv, len);
		val.s = decimal_str;
		u32_str = IntToString(&val, NumberSystem, NS_TYPE_STRING);

		if(0 != uninum_err){
			/* TODO structured exceptions: croak_sv */
			croak("libuninum: (%d) %s", uninum_err, uninum_error_str());
		} else {
			len = 0;
			u32_idx = u32_str;
			while( *(u32_idx++) ) len += sizeof(U32);
			RETVAL = newSVpv((char*)u32_str, len );
			Safefree(u32_str);
		}
	OUTPUT: RETVAL

MODULE = Unicode::Number      PACKAGE = Unicode::Number::System

SV*
_new(SV* klass, SV* ns_str, int ns_num, bool both_dir)
	INIT:
		Unicode__Number__System hash;
		STRLEN len;
	CODE:
		hash = newHV(); /* Create a hash */
		/* store in hash
		 * { _name => $ns_str, _id => $ns_num, _both_dir => $both_dir }
		 */
		hv_stores(hash, "_name", newSVsv(ns_str)); /* string with the name of
													  number system */
		hv_stores(hash, "_id", newSViv(ns_num));  /* this is a numeric ID */
		hv_stores(hash, "_both_dir", boolSV( both_dir )); /* can be converted
															 back? */

		/* Create a reference to the hash */
		SV *const self = newRV_noinc( (SV *)hash );
		/* bless into the proper package */
		RETVAL = (SV*)sv_bless( self, gv_stashsv( klass, 0 ) );
	OUTPUT: RETVAL

SV*
name(Unicode::Number::System self)
	CODE:
		RETVAL = SvREFCNT_inc(*hv_fetchs(self, "_name", 0));
	OUTPUT: RETVAL

SV*
_id(Unicode::Number::System self)
	CODE:
		RETVAL = SvREFCNT_inc(*hv_fetchs(self, "_id", 0));
	OUTPUT: RETVAL

SV*
convertible_in_both_directions(Unicode::Number::System self)
	CODE:
		RETVAL = SvREFCNT_inc(*hv_fetchs(self, "_both_dir", 0));
	OUTPUT: RETVAL

SV*
_MaximumValue(Unicode::Number::System self)
	INIT:
		int ns;
		char* max_str;
		STRLEN len;
	CODE:
		uninum_err = 0;
		ns = SvIV(*hv_fetchs(self, "_id", 0));
		max_str = UninumStringMaximumValue(ns);
		if(0 != uninum_err){
			/* TODO structured exceptions: croak_sv */
			croak("libuninum: (%d) %s", uninum_err, uninum_error_str());
		} else {
			len = strlen(max_str);
			RETVAL = newSVpv(max_str, len);
			Safefree(max_str);
		}
	OUTPUT: RETVAL
