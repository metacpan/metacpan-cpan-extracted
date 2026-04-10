#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdlib.h>
#include <string.h>

static double PRECISION = 0.01;
static double OFFSET = 0.5555555;
static int precision_places(double prec) {
	int places = 0;
	double p = prec;
	while (p < 1.0) {
		p *= 10.0;
		places++;
		if (places > 18) break;
	}
   	return places;
}

static SV *sn_to_sv(double val) {
	dTHX;
	int places = precision_places(PRECISION);
	double scaled = val / PRECISION;
	double delta = 1e-12;
	double rounded_units;
	if (scaled >= 0) {
		rounded_units = floor(scaled + 0.5 + delta);
	} else {
		rounded_units = ceil(scaled - 0.5 - delta);
	}
	double rounded = rounded_units * PRECISION;

	char fmt[16];
	snprintf(fmt, sizeof(fmt), "%%.%df", places);
	char *num = Perl_form(aTHX_ fmt, rounded);
	size_t len = strlen(num);
	char *dot = strchr(num, '.');
	if (dot) {
		while (len > 1 && num[len - 1] == '0') {
			num[--len] = '\0';
		}
		if (len > 0 && num[len - 1] == '.') {
			num[--len] = '\0';
		}
	}
	double val_out = strtod(num, NULL);
	if (val_out == 0.0 && val != 0.0) {
		return newSVnv(val);
	}
	return newSVpv(num, 0);
}

static SV * new (double num) {
	dTHX;
	SV *sv = newSVnv(num);
	return sv_bless(newRV_noinc(sv), gv_stashsv(newSVpv("smallnum::XS", 12), 0));
}

static double _sref (SV * n) {
	dTHX;
	double num;
	if (SvROK(n)) {
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
		RETVAL = sn_to_sv(PRECISION);
	OUTPUT:
		RETVAL

SV * _set_offset (num)
	SV * num
	CODE:
		OFFSET = SvNV(num);
		RETVAL = sn_to_sv(OFFSET);
	OUTPUT:
		RETVAL

SV * _num (...)
	OVERLOAD: \"\"
	CODE:
		double num = _sref(ST(0));
		double out = num >= 0
			? PRECISION * floor((num + (OFFSET * PRECISION)) / PRECISION)
			: PRECISION * ceil((num - OFFSET * PRECISION) / PRECISION);
		RETVAL = sn_to_sv(out);
	OUTPUT:
		RETVAL

SV * _divide (...)
	OVERLOAD: /
	CODE:
		double num1 = _sref(ST(0));
		double num2 = _sref(ST(1));
		double out = (num1 && num2)
			? (SvOK(ST(2)) && SvIV(ST(2)) > 0
				? num2 / num1
				: num1 / num2)
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
