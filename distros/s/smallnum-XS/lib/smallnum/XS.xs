#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdlib.h>
#include <string.h>


#ifdef USE_QUADMATH
	#include <quadmath.h>
	typedef __float128 snum_t;
	#define SN_FLOOR floorq
	#define SN_CEIL ceilq
	#define SN_NV(sv) ((__float128)SvNV(sv))
	static snum_t PRECISION = 0.01Q;
	static snum_t OFFSET = 0.5555555Q;
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
		char fmt[32], buf[128];
		snprintf(fmt, sizeof(fmt), "%%.%df", places);
		quadmath_snprintf(buf, sizeof(buf), fmt, (double)val); // cast for display
		char *dot = strchr(buf, '.');
		if (dot) {
			char *end = buf + strlen(buf) - 1;
			while (end > dot && *end == '0') *end-- = '\0';
			if (end == dot) *end = '\0';
		}
		return newSVpv(buf, 0);
	}
#elif defined(USE_LONG_DOUBLE)
	typedef long double snum_t;
	#define SN_FLOOR floorl
	#define SN_CEIL ceill
	#define SN_NV(sv) ((long double)SvNV(sv))
	static snum_t PRECISION = 0.01L;
	static snum_t OFFSET = 0.5555555L;
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
		char fmt[32], buf[64];
		snprintf(fmt, sizeof(fmt), "%%.%dLf", places);
		snprintf(buf, sizeof(buf), fmt, val);
		char *dot = strchr(buf, '.');
		if (dot) {
			char *end = buf + strlen(buf) - 1;
			while (end > dot && *end == '0') *end-- = '\0';
			if (end == dot) *end = '\0';
		}
		return newSVpv(buf, 0);
	}
#else
	typedef double snum_t;
	#define SN_FLOOR floor
	#define SN_CEIL ceil
	#define SN_NV(sv) (SvNV(sv))
	static snum_t PRECISION = 0.01;
	static snum_t OFFSET = 0.5555555;
	static SV *sn_to_sv(snum_t val) {
		dTHX;
		return newSVnv(val);
	}
#endif

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
