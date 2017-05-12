#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define PkgName "Unicode::Transform"

/* Some functions are defined in this. */
#include "unitrans.h"

#define Num_UTFs_here	(8)

/* in the range of valid Unicode (0..10FFFF) */
static STDCHAR
MaxLenAmplUni[Num_UTFs_here * Num_UTFs_here] = {
    1, 2, 2, 4, 4, 2, 2, 2,
    2, 1, 1, 2, 2, 2, 2, 2,
    2, 1, 1, 2, 2, 2, 2, 2,
    2, 1, 1, 1, 1, 1, 2, 2,
    2, 1, 1, 1, 1, 1, 2, 2,
    2, 2, 2, 4, 4, 1, 2, 2,
    2, 2, 2, 4, 4, 2, 1, 1,
    2, 2, 2, 4, 4, 2, 1, 1,
};


static UV (*ord_uv_in[Num_UTFs_here])(U8 *, STRLEN, STRLEN *) = {
    ord_in_unicode,
    ord_in_utf16le,
    ord_in_utf16be,
    ord_in_utf32le,
    ord_in_utf32be,
    ord_in_utf8,
    ord_in_utf8mod,
    ord_in_utfcp1047,
};

static U8* (*app_uv_in[Num_UTFs_here])(U8 *, UV) = {
    app_in_unicode,
    app_in_utf16le,
    app_in_utf16be,
    app_in_utf32le,
    app_in_utf32be,
    app_in_utf8,
    app_in_utf8mod,
    app_in_utfcp1047,
};

static void
sv_cat_retcvref (SV *dst, SV *cv, SV *sv)
{
    dSP;
    int count;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(sv));
    PUTBACK;
    count = call_sv(cv, G_EVAL|G_SCALAR);
    SPAGAIN;
    if (SvTRUE(ERRSV) || count != 1) {
	croak("died in subroutine call from XS, " PkgName "\n");
    }
    sv_catsv(dst,POPs);
    PUTBACK;
    FREETMPS;
    LEAVE;
}

MODULE = Unicode::Transform	PACKAGE = Unicode::Transform

SV*
unicode_to_unicode (arg1, arg2=0)
    SV* arg1
    SV* arg2
  PROTOTYPE: $;$
  ALIAS:
    unicode_to_utf16le = 1
    unicode_to_utf16be = 2
    unicode_to_utf32le = 3
    unicode_to_utf32be = 4
    unicode_to_utf8    = 5
    unicode_to_utf8mod = 6
    unicode_to_utfcp1047 = 7
    utf16le_to_unicode = 8
    utf16le_to_utf16le = 9
    utf16le_to_utf16be = 10
    utf16le_to_utf32le = 11
    utf16le_to_utf32be = 12
    utf16le_to_utf8    = 13
    utf16le_to_utf8mod = 14
    utf16le_to_utfcp1047 = 15
    utf16be_to_unicode = 16
    utf16be_to_utf16le = 17
    utf16be_to_utf16be = 18
    utf16be_to_utf32le = 19
    utf16be_to_utf32be = 20
    utf16be_to_utf8    = 21
    utf16be_to_utf8mod = 22
    utf16be_to_utfcp1047 = 23
    utf32le_to_unicode = 24
    utf32le_to_utf16le = 25
    utf32le_to_utf16be = 26
    utf32le_to_utf32le = 27
    utf32le_to_utf32be = 28
    utf32le_to_utf8    = 29
    utf32le_to_utf8mod = 30
    utf32le_to_utfcp1047 = 31
    utf32be_to_unicode = 32
    utf32be_to_utf16le = 33
    utf32be_to_utf16be = 34
    utf32be_to_utf32le = 35
    utf32be_to_utf32be = 36
    utf32be_to_utf8    = 37
    utf32be_to_utf8mod = 38
    utf32be_to_utfcp1047 = 39
    utf8_to_unicode    = 40
    utf8_to_utf16le    = 41
    utf8_to_utf16be    = 42
    utf8_to_utf32le    = 43
    utf8_to_utf32be    = 44
    utf8_to_utf8       = 45
    utf8_to_utf8mod    = 46
    utf8_to_utfcp1047  = 47
    utf8mod_to_unicode = 48
    utf8mod_to_utf16le = 49
    utf8mod_to_utf16be = 50
    utf8mod_to_utf32le = 51
    utf8mod_to_utf32be = 52
    utf8mod_to_utf8    = 53
    utf8mod_to_utf8mod = 54
    utf8mod_to_utfcp1047 = 55
    utfcp1047_to_unicode = 56
    utfcp1047_to_utf16le = 57
    utfcp1047_to_utf16be = 58
    utfcp1047_to_utf32le = 59
    utfcp1047_to_utf32be = 60
    utfcp1047_to_utf8  = 61
    utfcp1047_to_utf8mod = 62
    utfcp1047_to_utfcp1047 = 63
  PREINIT:
    SV *src, *dst, *cvref;
    STRLEN srclen, dstlen, retlen, ulen;
    U8 *s, *e, *p, *d, ubuf[UTF8_MAXLEN + 1];
    UV uv;
    UV  (*ord_uv)(U8 *, STRLEN, STRLEN *);
    U8* (*app_uv)(U8*, UV);
    int from_utf_num, to_utf_num;
    bool from_unicode, to_unicode;
  CODE:
    cvref = NULL;
    if (SvROK(arg1)) {
	if (SvTYPE(SvRV(arg1)) == SVt_PVCV)
	    cvref = SvRV(arg1);
	else
	    croak(PkgName " CALLBACK is not a CODEREF");
    }
    src = cvref
	? items == 1 ? &PL_sv_undef : arg2
	: arg1;

    from_utf_num = ix / Num_UTFs_here;
    to_utf_num   = ix % Num_UTFs_here;

    from_unicode = from_utf_num == 0;
    to_unicode   = to_utf_num   == 0;

    if (!from_unicode && SvUTF8(src)) {
	src = sv_mortalcopy(src);
	sv_utf8_downgrade(src, 0);
    }
    else if (from_unicode && !SvUTF8(src)) {
	src = sv_mortalcopy(src);
	sv_utf8_upgrade(src);
    }

    s = (U8*)SvPV(src,srclen);
    e = s + srclen;

    dstlen = srclen * MaxLenAmplUni[ix] + 1;

    dst = newSV(dstlen);
    (void)SvPOK_only(dst);
    if (to_unicode) {
	SvUTF8_on(dst);
    }

    ord_uv = ord_uv_in[from_utf_num];
    app_uv = app_uv_in[to_utf_num];

    if (cvref) {
	for (p = s; p < e;) {
	    uv = ord_uv(p, e - p, &retlen);

	    if (retlen)
		p += retlen;
	    else
		uv = (UV)*p++;

	    if (retlen && Is_VALID_UTF(uv)) {
		ulen = app_uv(ubuf, uv) - ubuf;
		sv_catpvn(dst, (char*)ubuf, ulen);
	    }
	    else
		sv_cat_retcvref(dst, cvref, newSVuv(uv));
	}
    }
    else {
	d = (U8*)SvPVX(dst);

	for (p = s; p < e;) {
	    uv = ord_uv(p, e - p, &retlen);

	    if (retlen)
		p += retlen;
	    else {
		p++;
		continue;
	    }

	    if (Is_VALID_UTF(uv))
		d = app_uv(d, uv);
	}
	*d = '\0';
	SvCUR_set(dst, d - (U8*)SvPVX(dst));
    }
    RETVAL = dst;
  OUTPUT:
    RETVAL


SV*
chr_unicode (uv)
    UV  uv
  PROTOTYPE: $
  ALIAS:
    chr_utf16le = 1
    chr_utf16be = 2
    chr_utf32le = 3
    chr_utf32be = 4
    chr_utf8    = 5
    chr_utf8mod = 6
    chr_utfcp1047 = 7
  PREINIT:
    SV *dst;
    U8 *u, ubuf[UTF8_MAXLEN + 1];
    U8* (*app_uv)(U8*, UV);
  CODE:
    dst = newSVpvn("", 0);
    (void)SvPOK_only(dst);
    if (ix == 0) {
	SvUTF8_on(dst);
    }

    app_uv = app_uv_in[ix];
    u = app_uv(ubuf, uv);
    if (u == ubuf)
	XSRETURN_UNDEF;

    sv_catpvn(dst, (char*)ubuf, u - ubuf);
    RETVAL = dst;
  OUTPUT:
    RETVAL


SV*
ord_unicode (src)
    SV* src
  PROTOTYPE: $
  ALIAS:
    ord_utf16le = 1
    ord_utf16be = 2
    ord_utf32le = 3
    ord_utf32be = 4
    ord_utf8    = 5
    ord_utf8mod = 6
    ord_utfcp1047 = 7
  PREINIT:
    STRLEN srclen, retlen;
    U8 *s;
    UV uv;
    UV (*ord_uv)(U8 *, STRLEN, STRLEN *);
  CODE:
    if (ix != 0 && SvUTF8(src)) {
	src = sv_mortalcopy(src);
	sv_utf8_downgrade(src, 0);
    }
    else if (ix == 0 && !SvUTF8(src)) {
	src = sv_mortalcopy(src);
	sv_utf8_upgrade(src);
    }

    s = (U8*)SvPV(src,srclen);
    if (!srclen)
	XSRETURN_UNDEF;

    ord_uv = ord_uv_in[ix];
    uv = ord_uv(s, srclen, &retlen);
    RETVAL = retlen ? newSVuv(uv) : &PL_sv_undef;
  OUTPUT:
    RETVAL

