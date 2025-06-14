#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdlib.h>
#include <string.h>


typedef double snum_t;
#define SN_FLOOR floor
#define SN_CEIL ceil
#define SN_NV(sv) (SvNV(sv))
static snum_t PRECISION = 0.01;
static snum_t OFFSET = 0.5555555;
static int precision_places(snum_t prec) {
	int places = 0;
	snum_t p = prec;
	while (p < 1.0) {
		p *= 10.0;
		places++;
		if (places > 18) break;
	}
   	return places;
}

static SV *sn_to_sv(snum_t val) {
	dTHX;
	int places = precision_places(PRECISION);
	char fmt[16];
	snprintf(fmt, sizeof(fmt), "%%.%df", places);
	char *num = Perl_form(fmt, val);
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
	snum_t val_out = strtod(num, NULL);
	if (val_out < val) {
		return newSVnv(val);
	}
	return newSVpv(num, 0);
}

static SV * new (snum_t num) {
	dTHX;
	return sv_bless(newRV_noinc(sn_to_sv(num)), gv_stashsv(newSVpv("smallnum::XS", 12), 0));
}

static snum_t _sref (SV * n) {
	dTHX;
	snum_t num;
	if (SvROK(n)) {
		num = SN_NV(SvRV(n));
	} else {
		num = SN_NV(n);
	}
	return num;
}

MODULE = smallnum::XS  PACKAGE = smallnum::XS
PROTOTYPES: ENABLE
FALLBACK: TRUE

SV * _smallnum (...)
	CODE:
		snum_t num = SN_NV(ST(0));
		RETVAL = new(num);
	OUTPUT:
		RETVAL

SV * _set_precision (num)
	SV * num
	CODE:
		PRECISION = SN_NV(num);
		RETVAL = sn_to_sv(PRECISION);
	OUTPUT:
		RETVAL

SV * _set_offset (num)
	SV * num
	CODE:
		OFFSET = SN_NV(num);
		RETVAL = sn_to_sv(OFFSET);
	OUTPUT:
		RETVAL

SV * _num (...)
	OVERLOAD: \"\"
	CODE:
		snum_t num = _sref(ST(0));
		snum_t out = num >= 0
			? PRECISION * SN_FLOOR((num + (OFFSET * PRECISION)) / PRECISION)
			: PRECISION * SN_CEIL((num - OFFSET * PRECISION) / PRECISION);
		RETVAL = sn_to_sv(out);
	OUTPUT:
		RETVAL

SV * _divide (...)
	OVERLOAD: /
	CODE:
		snum_t num1 = _sref(ST(0));
		snum_t num2 = _sref(ST(1));
		snum_t out = (num1 && num2)
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
		snum_t num1 = _sref(ST(0));
		snum_t num2 = _sref(ST(1));
		snum_t out = num2 * num1;
		RETVAL = new(out);
	OUTPUT:
		RETVAL
