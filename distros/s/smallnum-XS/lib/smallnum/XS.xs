#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros
#include <stdlib.h>         // rand()
#include <string.h>

double PRECISION = 0.01;
double OFFSET = 0.5555555;

static SV * new (double num) {
	return sv_bless(newRV_noinc(newSVnv(num)), gv_stashsv(newSVpv("smallnum::XS", 12), 0));
}

static double _sref (SV * n) {
	double num;
	if ( SvROK(n) ) {
		num = SvNV(SvRV(n));
	} else {
		num = SvNV(n);
	}
	return num;
}


MODULE = smallnum::XS  PACKAGE = smallnum::XS
PROTOTYPES: ENABLE
FALLBACK: TRUE

SV * _smallnum (...)
	CODE:
		double num = SvNV(ST(0));
		RETVAL = new(num);
	OUTPUT:
		RETVAL


SV * _set_precision (num)
	SV * num
	CODE:
		PRECISION = SvNV(num);
		RETVAL = newSVsv(num);
	OUTPUT:
		RETVAL

SV * _set_offset (num)
	SV * num
	CODE:
		OFFSET = SvNV(num);
		RETVAL = newSVsv(num);
	OUTPUT:
		RETVAL

SV * _num (...)
	OVERLOAD: \"\"
	CODE:
		double num = _sref(ST(0));

		double out = num >= 0 
			? PRECISION * floor(( num + ( OFFSET * PRECISION )) / PRECISION)
			: PRECISION * ceil(( num - OFFSET * PRECISION) / PRECISION);

		RETVAL = newSVnv(out);
	OUTPUT:
		RETVAL


SV * _divide (...)
	OVERLOAD: /
	CODE:
		double num1 = _sref(ST(0));
		double num2 = _sref(ST(1));

		double out = num1 && num2 
			? SvOK(ST(2)) && SvIV(ST(2)) > 0
				? num2 / num1
				: num1 / num2
			: 0;

		RETVAL = new(out);
	OUTPUT:
		RETVAL


SV * _multiply (...)
	OVERLOAD: *
	CODE:
		double num1 = _sref(ST(0));
		double num2 = _sref(ST(1));

		double out = num2 * num1;

		RETVAL = new(out);
	OUTPUT:
		RETVAL
