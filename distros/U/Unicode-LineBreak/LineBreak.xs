/*
 * LineBreak.xs - Perl XS glue for Sombok package.
 * 
 * Copyright (C) 2009-2013 Hatuka*nezumi - IKEDA Soji <hatuka(at)nezumi.nu>.
 * 
 * This file is part of the Unicode::LineBreak package.  This program is
 * free software; you can redistribute it and/or modify it under the same
 * terms as Perl itself.
 *
 * $Id$
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_newRV_noinc
#define NEED_sv_2pv_flags
#define NEED_newRV_noinc_GLOBAL
#define NEED_sv_2pv_flags_GLOBAL
#define NEED_sv_2pv_nolen
#include "ppport.h"
#include "sombok.h"

/* for Win32 with Visual Studio (MSVC) */
#ifdef _MSC_VER
#  ifndef snprintf
#      define snprintf _snprintf
#  endif /* snprintf */
#  define strcasecmp _stricmp
#endif /* _MSC_VER */

/* Type synonyms for typemap. */
typedef IV swapspec_t;
typedef gcstring_t *generic_string;

/***
 *** Data conversion.
 ***/

/*
 * Create Unicode string from Perl utf8-flagged string.
 */
static
unistr_t *SVtounistr(unistr_t *buf, SV *str)
{
    U8 *utf8, *utf8ptr;
    STRLEN utf8len, unilen, len;
    unichar_t *uniptr;

    if (buf == NULL) {
	if ((buf = malloc(sizeof(unistr_t))) == NULL)
	    croak("SVtounistr: %s", strerror(errno));
    } else if (buf->str)
	free(buf->str);
    buf->str = NULL;
    buf->len = 0;

    if (SvOK(str))
	utf8 = (U8 *)SvPV(str, utf8len);
    else
	return buf;
    if (utf8len <= 0)
	return buf;
    unilen = utf8_length(utf8, utf8 + utf8len);
    if ((buf->str = (unichar_t *)malloc(sizeof(unichar_t) * unilen)) == NULL)
	croak("SVtounistr: %s", strerror(errno));

    utf8ptr = utf8;
    uniptr = buf->str;
    while (utf8ptr < utf8 + utf8len) {
#if PERL_VERSION >= 20 || (PERL_VERSION == 19 && PERL_SUBVERSION >= 4)
	*uniptr = (unichar_t) NATIVE_TO_UNI(
	    utf8_to_uvchr_buf(utf8ptr, utf8 + utf8len, &len));
#elif PERL_VERSION >= 16 || (PERL_VERSION == 15 && PERL_SUBVERSION >= 9)
	*uniptr = (unichar_t) utf8_to_uvuni_buf(utf8ptr, utf8 + utf8len,
						&len);
#else
	*uniptr = (unichar_t) utf8n_to_uvuni(utf8ptr,
					     utf8 + utf8len - utf8ptr, &len,
					     ckWARN(WARN_UTF8) ? 0 :
					     UTF8_ALLOW_ANY);
#endif
	if (len < 0) {
	    free(buf->str);
	    buf->str = NULL;
	    buf->len = 0;
	    croak("SVtounistr: Not well-formed UTF-8");
	}
	if (len == 0) {
	    free(buf->str);
	    buf->str = NULL;
	    buf->len = 0;
	    croak("SVtounistr: Internal error");
	}
	utf8ptr += len;
	uniptr++;
    }
    buf->len = unilen;
    return buf;
}

/*
 * Create Unicode string from Perl string NOT utf8-flagged.
 */
static
unistr_t *SVupgradetounistr(unistr_t *buf, SV *str)
{
    char *s;
    size_t len, i;

    if (buf == NULL) {
	if ((buf = malloc(sizeof(unistr_t))) == NULL)
	    croak("SVupgradetounistr: %s", strerror(errno));
    } else if (buf->str)
	free(buf->str);
    buf->str = NULL;
    buf->len = 0;

    if (SvOK(str))
	s = SvPV(str, len);
    else
	return buf;
    if (len == 0)
	return buf;
    if ((buf->str = malloc(sizeof(unichar_t) * len)) == NULL)
	croak("SVupgradetounistr: %s", strerror(errno));

    for (i = 0; i < len; i++)
	buf->str[i] = (unichar_t)(unsigned char)s[i];
    buf->len = len;
    return buf;
}

/*
 * Create Perl utf8-flagged string from Unicode string.
 */
static
SV *unistrtoSV(unistr_t *unistr, size_t uniidx, size_t unilen)
{
    U8 *buf = NULL, *newbuf;
    STRLEN utf8len;
    unichar_t *uniptr;
    SV *utf8;

    if (unistr == NULL || unistr->str == NULL || unilen == 0) {
	utf8 = newSVpvn("", 0);
	SvUTF8_on(utf8);
	return utf8;
    }

    utf8len = 0;
    uniptr = unistr->str + uniidx;
    while (uniptr < unistr->str + uniidx + unilen &&
	   uniptr < unistr->str + unistr->len) {
	if ((newbuf = realloc(buf,
			      sizeof(U8) * (utf8len + UTF8_MAXLEN + 1)))
	    == NULL) {
	    free(buf);
	    croak("unistrtoSV: %s", strerror(errno));
	}
	buf = newbuf;
#if PERL_VERSION >= 20 || (PERL_VERSION == 19 && PERL_SUBVERSION >= 4)
	utf8len = uvchr_to_utf8(buf + utf8len, UNI_TO_NATIVE(*uniptr)) - buf;
#else
	utf8len = uvuni_to_utf8(buf + utf8len, *uniptr) - buf;
#endif
	uniptr++;
    }

    utf8 = newSVpvn((char *)(void *)buf, utf8len);
    SvUTF8_on(utf8);
    free(buf);
    return utf8;
}

/*
 * Convert Perl object to C object
 */
#define PerltoC(type, arg) \
    (INT2PTR(type, SvIV((SV *)SvRV(arg))))

/*
 * Create Perl object from C object
 */
# define setCtoPerl(arg, klass, var) \
    STMT_START { \
	sv_setref_iv(arg, klass, (IV)(var)); \
	SvREADONLY_on(arg); \
    } STMT_END
static
SV *CtoPerl(char *klass, void *obj)
{
    SV *sv;

    sv = newSViv(0);
    setCtoPerl(sv, klass, obj);  
    return sv;
}

/*
 * Convert Perl utf8-flagged string (GCString) to grapheme cluster string.
 */
static
gcstring_t *SVtogcstring(SV *sv, linebreak_t *lbobj)
{
    unistr_t unistr = {NULL, 0};

    if (!sv_isobject(sv)) {
	SVtounistr(&unistr, sv);
	return gcstring_new(&unistr, lbobj);
    } else if (sv_derived_from(sv, "Unicode::GCString"))
	return PerltoC(gcstring_t *, sv);
    else
	croak("Unknown object %s", HvNAME(SvSTASH(SvRV(sv))));
}

#if 0
/*
 * Convert Perl LineBreak object to C linebreak object.
 */
static
linebreak_t *SVtolinebreak(SV *sv)
{
    if (!sv_isobject(sv))
	croak("Not object");
    else if (sv_derived_from(sv, "Unicode::LineBreak"))
	return PerltoC(linebreak_t *, sv);
    else
	croak("Unknown object %s", HvNAME(SvSTASH(SvRV(sv))));
}
#endif /* 0 */

/*
 * Convert Perl SV to boolean (n.b. string "YES" means true).
 */
static
int SVtoboolean(SV *sv)
{
    char *str;

    if (!sv || !SvOK(sv))
	return 0;
    if (SvPOK(sv))
	return strcasecmp((str = SvPV_nolen(sv)), "YES") == 0 ||
	    atof(str) != 0.0;
    return SvNV(sv) != 0.0;
}

/***
 *** Other utilities
 ***/

/*
 * Do regex match once then returns offset and length.
 */
void do_pregexec_once(REGEXP *rx, unistr_t *str)
{
    SV *screamer;
    char *str_arg, *str_beg, *str_end;
    size_t offs_beg, offs_end;

    screamer = unistrtoSV(str, 0, str->len);
    SvREADONLY_on(screamer);
    str_beg = str_arg = SvPVX(screamer);
    str_end = SvEND(screamer);

    if (pregexec(rx, str_arg, str_end, str_beg, 0, screamer, 1)) {
#if PERL_VERSION >= 11
	offs_beg = ((regexp *)SvANY(rx))->offs[0].start;
	offs_end = ((regexp *)SvANY(rx))->offs[0].end;
#elif ((PERL_VERSION == 10) || (PERL_VERSION == 9 && PERL_SUBVERSION >= 5))
	offs_beg = rx->offs[0].start;
	offs_end = rx->offs[0].end;
#else /* PERL_VERSION */
	offs_beg = rx->startp[0];
	offs_end = rx->endp[0];
#endif
	str->str += utf8_length((U8 *)str_beg, (U8 *)(str_beg + offs_beg));
	str->len = utf8_length((U8 *)(str_beg + offs_beg),
			       (U8 *)(str_beg + offs_end));
    } else
	str->str = NULL;

    SvREFCNT_dec(screamer);
}

/***
 *** Callbacks for Sombok library.
 ***/

/*
 * Increment/decrement reference count
 */
void ref_func(void *sv, int datatype, int d)
{
    if (sv == NULL)
	return;
    if (0 < d)
	SvREFCNT_inc((SV *)sv);
    else if (d < 0)
	SvREFCNT_dec((SV *)sv);
}

/*
 * Call preprocessing function
 */
static
gcstring_t *prep_func(linebreak_t *lbobj, void *dataref, unistr_t *str,
		      unistr_t *text)
{
    AV *data;
    SV *sv, **pp, *func = NULL;
    REGEXP *rx = NULL;
    size_t count, i, j;
    gcstring_t *gcstr, *ret;

    if (dataref == NULL ||
	(data = (AV *)SvRV((SV *)dataref)) == NULL)
	return (lbobj->errnum = EINVAL), NULL;

    /* Pass I */

    if (text != NULL) {
	if ((pp = av_fetch(data, 0, 0)) == NULL)
	    return (lbobj->errnum = EINVAL), NULL;

#if ((PERL_VERSION >= 10) || (PERL_VERSION >= 9 && PERL_SUBVERSION >= 5))
	if (SvRXOK(*pp))
	    rx = SvRX(*pp);
#else /* PERL_VERSION */
	if (SvROK(*pp) && SvMAGICAL(sv = SvRV(*pp))) {
	    MAGIC *mg;
	    if ((mg = mg_find(sv, PERL_MAGIC_qr)) != NULL)
		rx = (REGEXP *)mg->mg_obj;
	}
#endif /* PERL_VERSION */
	if (rx == NULL)
	    return (lbobj->errnum = EINVAL), NULL;

	do_pregexec_once(rx, str);
	return NULL;
    }

    /* Pass II */

    if ((pp = av_fetch(data, 1, 0)) == NULL)
        func = NULL;
    else if (SvOK(*pp))
        func = *pp;
    else
        func = NULL;

    if (func == NULL) {
	if ((ret = gcstring_newcopy(str, lbobj)) == NULL)
	    return (lbobj->errnum = errno ? errno : ENOMEM), NULL;
    } else {
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	linebreak_incref(lbobj); /* mortal but should not be destroyed.*/
	XPUSHs(sv_2mortal(CtoPerl("Unicode::LineBreak", lbobj)));
	XPUSHs(sv_2mortal(unistrtoSV(str, 0, str->len)));
	PUTBACK;
	count = call_sv(func, G_ARRAY | G_EVAL);

	SPAGAIN;
	if (SvTRUE(ERRSV)) {
	    if (!lbobj->errnum)
		 lbobj->errnum = LINEBREAK_EEXTN;
	    return NULL;
	}

	if ((ret = gcstring_new(NULL, lbobj)) == NULL)
	    return (lbobj->errnum = errno ? errno : ENOMEM), NULL;

	for (i = 0; i < count; i++) {
	    sv = POPs;
	    if (!SvOK(sv))
		continue;
	    gcstr = SVtogcstring(sv, lbobj);

	    for (j = 0; j < gcstr->gclen; j++) {
		if (gcstr->gcstr[j].flag &
		    (LINEBREAK_FLAG_ALLOW_BEFORE |
		     LINEBREAK_FLAG_PROHIBIT_BEFORE))
		    continue;
		if (i < count - 1 && j == 0)
		    gcstr->gcstr[j].flag |= LINEBREAK_FLAG_ALLOW_BEFORE;
		else if (0 < j)
		    gcstr->gcstr[j].flag |= LINEBREAK_FLAG_PROHIBIT_BEFORE;
	    }

	    gcstring_replace(ret, 0, 0, gcstr);
	    if (!sv_isobject(sv))
		gcstring_destroy(gcstr);
	}

	PUTBACK;
	FREETMPS;
	LEAVE;
    }

    return ret;
}

/*
 * Call format function
 */
static
char *linebreak_states[] = {
    NULL, "sot", "sop", "sol", "", "eol", "eop", "eot", NULL
};
static
gcstring_t *format_func(linebreak_t *lbobj, linebreak_state_t action,
			gcstring_t *str)
{
    SV *sv;
    char *actionstr;
    int count;
    gcstring_t *ret;

    dSP;
    if (action <= LINEBREAK_STATE_NONE || LINEBREAK_STATE_MAX <= action)
	return NULL;
    actionstr = linebreak_states[(size_t)action];
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    linebreak_incref(lbobj); /* mortal but should not be destroyed. */
    XPUSHs(sv_2mortal(CtoPerl("Unicode::LineBreak", lbobj)));
    XPUSHs(sv_2mortal(newSVpv(actionstr, 0)));
    XPUSHs(sv_2mortal(CtoPerl("Unicode::GCString", gcstring_copy(str))));
    PUTBACK;
    count = call_sv(lbobj->format_data, G_SCALAR | G_EVAL);

    SPAGAIN;
    if (SvTRUE(ERRSV)) {
	if (!lbobj->errnum)
	    lbobj->errnum = LINEBREAK_EEXTN;
	POPs;
	return NULL;
    } else if (count != 1)
	croak("format_func: internal error");
    else
	sv = POPs;
    if (!SvOK(sv))
	ret = NULL;
    else
	ret = SVtogcstring(sv, lbobj);
    if (sv_isobject(sv))
	ret = gcstring_copy(ret);

    PUTBACK;
    FREETMPS;
    LEAVE;

    return ret;
}

/*
 * Call sizing function
 */
static
double sizing_func(linebreak_t *lbobj, double len,
		   gcstring_t *pre, gcstring_t *spc, gcstring_t *str)
{
    int count;
    double ret;

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    linebreak_incref(lbobj); /* mortal but should not be destroyed. */
    XPUSHs(sv_2mortal(CtoPerl("Unicode::LineBreak", lbobj)));
    XPUSHs(sv_2mortal(newSVnv(len))); 
    XPUSHs(sv_2mortal(CtoPerl("Unicode::GCString", gcstring_copy(pre))));
    XPUSHs(sv_2mortal(CtoPerl("Unicode::GCString", gcstring_copy(spc))));
    XPUSHs(sv_2mortal(CtoPerl("Unicode::GCString", gcstring_copy(str))));
    PUTBACK;
    count = call_sv(lbobj->sizing_data, G_SCALAR | G_EVAL);

    SPAGAIN;
    if (SvTRUE(ERRSV)) {
	if (!lbobj->errnum)
	    lbobj->errnum = LINEBREAK_EEXTN;
	POPs;
	return -1;
    } else if (count != 1)
	croak("sizing_func: internal error");
    else
	ret = POPn;

    PUTBACK;
    FREETMPS;
    LEAVE;

    return ret;
}

/*
 * Call urgent breaking function
 */
static
gcstring_t *urgent_func(linebreak_t *lbobj, gcstring_t *str)
{
    SV *sv;
    int count;
    size_t i;
    gcstring_t *gcstr, *ret;

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    linebreak_incref(lbobj); /* mortal but should not be destroyed. */
    XPUSHs(sv_2mortal(CtoPerl("Unicode::LineBreak", lbobj)));
    XPUSHs(sv_2mortal(CtoPerl("Unicode::GCString", gcstring_copy(str))));
    PUTBACK;
    count = call_sv(lbobj->urgent_data, G_ARRAY | G_EVAL);

    SPAGAIN;
    if (SvTRUE(ERRSV)) {
	if (!lbobj->errnum)
	    lbobj->errnum = LINEBREAK_EEXTN;
	return NULL;
    } if (count == 0)
	return NULL;

    ret = gcstring_new(NULL, lbobj);
    for (i = count; i; i--) {
	sv = POPs;
	if (SvOK(sv)) {
	    gcstr = SVtogcstring(sv, lbobj);
	    if (gcstr->gclen)
		gcstr->gcstr[0].flag = LINEBREAK_FLAG_ALLOW_BEFORE;
	    gcstring_replace(ret, 0, 0, gcstr);
	    if (!sv_isobject(sv))
		gcstring_destroy(gcstr);
	}
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    return ret;
}


MODULE = Unicode::LineBreak	PACKAGE = Unicode::LineBreak	

void
EAWidths()
    INIT:
	char **p;
    PPCODE:
	for (p = (char **)linebreak_propvals_EA; *p != NULL; p++)
	    XPUSHs(sv_2mortal(newSVpv(*p, 0)));

void
LBClasses()
    INIT:
	char **p;
    PPCODE:
	for (p = (char **)linebreak_propvals_LB; *p != NULL; p++)
	    XPUSHs(sv_2mortal(newSVpv(*p, 0)));

linebreak_t *
_new(klass)
	char *klass;
    PROTOTYPE: $
    CODE:
	if ((RETVAL = linebreak_new(ref_func)) == NULL)
	    croak("%s->_new: %s", klass, strerror(errno));
	linebreak_set_stash(RETVAL, newRV_noinc((SV *)newHV()));
	SvREFCNT_dec(RETVAL->stash); /* fixup */
    OUTPUT:
	RETVAL

linebreak_t *
copy(self)
	linebreak_t *self;
    PROTOTYPE: $
    CODE:
	RETVAL = linebreak_copy(self);
    OUTPUT:
	RETVAL

void
DESTROY(self)
	linebreak_t *self;
    PROTOTYPE: $
    CODE:
	linebreak_destroy(self);

SV *
_config(self, ...)
	linebreak_t *self;
    PREINIT:
	size_t i;
	char *key;
	void *func;
	SV *val;
	char *opt;
    CODE:
	RETVAL = NULL;
	if (items < 2)
	    croak("_config: Too few arguments");
	else if (items < 3) {
	    key = (char *)SvPV_nolen(ST(1));

	    if (strcasecmp(key, "BreakIndent") == 0)
		RETVAL = newSVuv(self->options &
				 LINEBREAK_OPTION_BREAK_INDENT); 
	    else if (strcasecmp(key, "CharMax") == 0)
		RETVAL = newSVuv(self->charmax);
	    else if (strcasecmp(key, "ColMax") == 0)
		RETVAL = newSVnv((NV)self->colmax);
	    else if (strcasecmp(key, "ColMin") == 0)
		RETVAL = newSVnv((NV)self->colmin);
	    else if (strcasecmp(key, "ComplexBreaking") == 0)
		RETVAL = newSVuv(self->options &
				 LINEBREAK_OPTION_COMPLEX_BREAKING);
	    else if (strcasecmp(key, "Context") == 0) {
		if (self->options & LINEBREAK_OPTION_EASTASIAN_CONTEXT)
		    RETVAL = newSVpvn("EASTASIAN", 9);
		else
		    RETVAL = newSVpvn("NONEASTASIAN", 12);
	    } else if (strcasecmp(key, "EAWidth") == 0) {
		AV *av, *codes = NULL, *ret = NULL;
		propval_t p = PROP_UNKNOWN;
		unichar_t c;
		size_t i;

		if (self->map == NULL || self->mapsiz == 0)
		    XSRETURN_UNDEF;

		for (i = 0; i < self->mapsiz; i++)
		    if (self->map[i].eaw != PROP_UNKNOWN) {
			if (p != self->map[i].eaw){
			    p = self->map[i].eaw;
			    codes = newAV();
			    av = newAV();
			    av_push(av, newRV_noinc((SV *)codes));
			    av_push(av, newSViv((IV)p));
			    if (ret == NULL)
				ret = newAV();
			    av_push(ret, newRV_noinc((SV *)av));
			}
			for (c = self->map[i].beg; c <= self->map[i].end; c++)
			    av_push(codes, newSVuv(c));
		    }

		if (ret == NULL)
		    XSRETURN_UNDEF;
		RETVAL = newRV_noinc((SV *)ret);
	    } else if (strcasecmp(key, "Format") == 0) {
		func = self->format_func;
		if (func == NULL)
		    XSRETURN_UNDEF;
		else if (func == linebreak_format_NEWLINE)
		    RETVAL = newSVpvn("NEWLINE", 7);
		else if (func == linebreak_format_SIMPLE)
		    RETVAL = newSVpvn("SIMPLE", 6);
		else if (func == linebreak_format_TRIM)
		    RETVAL = newSVpvn("TRIM", 4);
		else if (func == format_func) {
		    if ((val = (SV *)self->format_data) == NULL)
			XSRETURN_UNDEF;
		    ST(0) = val; /* should not be mortal. */
		    XSRETURN(1);
		} else
		    croak("_config: internal error");
	    } else if (strcasecmp(key, "HangulAsAL") == 0)
		RETVAL = newSVuv(self->options &
				 LINEBREAK_OPTION_HANGUL_AS_AL);
	    else if (strcasecmp(key, "LBClass") == 0) {
		AV *av, *codes = NULL, *ret = NULL;
		propval_t p = PROP_UNKNOWN;
		unichar_t c;
		size_t i;

		if (self->map == NULL || self->mapsiz == 0)
		    XSRETURN_UNDEF;

		for (i = 0; i < self->mapsiz; i++)
		    if (self->map[i].lbc != PROP_UNKNOWN) {
			if (p != self->map[i].lbc){
			    p = self->map[i].lbc;
			    codes = newAV();
			    av = newAV();
			    av_push(av, newRV_noinc((SV *)codes));
			    av_push(av, newSViv((IV)p));
			    if (ret == NULL)
				ret = newAV();
			    av_push(ret, newRV_noinc((SV *)av));
			}
			for (c = self->map[i].beg; c <= self->map[i].end; c++)
			    av_push(codes, newSVuv(c));
		    }

		if (ret == NULL)
		    XSRETURN_UNDEF;
		RETVAL = newRV_noinc((SV *)ret);
	    } else if (strcasecmp(key, "LegacyCM") == 0)
		RETVAL = newSVuv(self->options & LINEBREAK_OPTION_LEGACY_CM);
	    else if (strcasecmp(key, "Newline") == 0) {
		unistr_t unistr = {self->newline.str, self->newline.len};
		if (self->newline.str == NULL || self->newline.len == 0)
		    RETVAL = unistrtoSV(&unistr, 0, 0);
		else
		    RETVAL = unistrtoSV(&unistr, 0, self->newline.len);
	    } else if (strcasecmp(key, "Prep") == 0) {
		AV *av;
		if (self->prep_func == NULL || self->prep_func[0] == NULL)
		    XSRETURN_UNDEF;
		av = newAV();
		for (i = 0; (func = self->prep_func[i]) != NULL; i++)
		    if (func == linebreak_prep_URIBREAK) {
			if (self->prep_data == NULL ||
			    self->prep_data[i] == NULL)
			    av_push(av, newSVpvn("NONBREAKURI", 11));
			else
			    av_push(av, newSVpvn("BREAKURI", 8));
		    } else if (func == prep_func) {
			if (self->prep_data == NULL ||
			    self->prep_data[i] == NULL)
			    croak("_config: internal error");
			SvREFCNT_inc(self->prep_data[i]); /* avoid freed */
			av_push(av, self->prep_data[i]);
		    } else
			croak("_config: internal error");
		RETVAL = newRV_noinc((SV *)av);
	    } else if (strcasecmp(key, "Sizing") == 0) {
		func = self->sizing_func;
		if (func == NULL)
		    XSRETURN_UNDEF;
		else if (func == linebreak_sizing_UAX11)
		    RETVAL = newSVpvn("UAX11", 5);
		else if (func == sizing_func) {
		    if ((val = (SV *)self->sizing_data) == NULL)
			XSRETURN_UNDEF;
		    ST(0) = val; /* should not be mortal. */
		    XSRETURN(1);
		} else
		    croak("_config: internal error");
	    } else if (strcasecmp(key, "Urgent") == 0) {
		func = self->urgent_func;
		if (func == NULL)
		    XSRETURN_UNDEF;
		else if (func == linebreak_urgent_ABORT)
		    RETVAL = newSVpvn("CROAK", 5);
		else if (func == linebreak_urgent_FORCE)
		    RETVAL = newSVpvn("FORCE", 5);
		else if (func == urgent_func) {
		    if ((val = (SV *)self->urgent_data) == NULL)
			XSRETURN_UNDEF;
		    ST(0) = val; /* should not be mortal. */
		    XSRETURN(1);
		} else
		    croak("_config: internal error");
	    } else if (strcasecmp(key, "ViramaAsJoiner") == 0)
		RETVAL = newSVuv(self->options & LINEBREAK_OPTION_VIRAMA_AS_JOINER);
	    else {
		warn("_config: Getting unknown option %s", key);
		XSRETURN_UNDEF;
	    }
	} else if (!(items % 2))
	    croak("_config: Argument size mismatch");
	else for (RETVAL = NULL, i = 1; i < items; i += 2) {
	    if (!SvPOK(ST(i)))
		croak("_config: Illegal argument");
	    key = (char *)SvPV_nolen(ST(i));
	    val = ST(i + 1);

	    if (strcasecmp(key, "Prep") == 0) {
		SV *sv, *pattern, *func;
		AV *av;
		REGEXP *rx = NULL;

		if (! SvOK(val))
		    linebreak_add_prep(self, NULL, NULL);
		else if (SvROK(val) &&
		    SvTYPE(av = (AV *)SvRV(val)) == SVt_PVAV &&
		    0 < av_len(av) + 1) {
		    pattern = *av_fetch(av, 0, 0);
#if ((PERL_VERSION >= 10) || (PERL_VERSION >= 9 && PERL_SUBVERSION >= 5))
		    if (SvRXOK(pattern))
			rx = SvRX(pattern);
#else /* PERL_VERSION */
		    if (SvROK(pattern) && SvMAGICAL(sv = SvRV(pattern))) {
			MAGIC *mg;
			if ((mg = mg_find(sv, PERL_MAGIC_qr)) != NULL)
			    rx = (REGEXP *)mg->mg_obj;
		    }
#endif
		    if (rx != NULL)
			SvREFCNT_inc(pattern); /* FIXME:avoid freed */
		    else if (SvOK(pattern)) {
#if ((PERL_VERSION >= 10) || (PERL_VERSION == 9 && PERL_SUBVERSION >= 5))
			rx = pregcomp(pattern, 0);
#else /* PERL_VERSION */
			{
			    PMOP *pm;
			    New(1, pm, 1, PMOP);
			    rx = pregcomp(SvPVX(pattern), SvEND(pattern), pm);
			}
#endif
			if (rx != NULL) {
#if PERL_VERSION >= 11
			    pattern = newRV_noinc((SV *)rx);
			    sv_bless(pattern, gv_stashpv("Regexp", 0));
#else /* PERL_VERSION */
			    sv = newSV(0);
			    sv_magic(sv, (SV *)rx, PERL_MAGIC_qr, NULL, 0);
			    pattern = newRV_noinc(sv);
			    sv_bless(pattern, gv_stashpv("Regexp", 0));
#endif
			}
		    } else
			rx = NULL;

		    if (rx == NULL)
			croak("_config: Not a regex");

		    if (av_fetch(av, 1, 0) == NULL)
			func = NULL;
		    else if (SvOK(func = *av_fetch(av, 1, 0)))
			SvREFCNT_inc(func); /* avoid freed */
		    else
			func = NULL;

		    av = newAV();
		    av_push(av, pattern);
		    if (func != NULL)
			av_push(av, func);
		    sv = newRV_noinc((SV *)av);
		    linebreak_add_prep(self, prep_func, (void *)sv);
		    SvREFCNT_dec(sv); /* fixup */
		} else {
		    char *s = SvPV_nolen(val);

		    if (strcasecmp(s, "BREAKURI") == 0)
			linebreak_add_prep(self, linebreak_prep_URIBREAK, val);
		    else if (strcasecmp(s, "NONBREAKURI") == 0)
			linebreak_add_prep(self, linebreak_prep_URIBREAK,
					   NULL);
		    else
			croak("_config: Unknown preprocess option: %s", s);
		}
	    } else if (strcasecmp(key, "Format") == 0) {
		if (! SvOK(val))
		    linebreak_set_format(self, NULL, NULL);
		else if (sv_derived_from(val, "CODE"))
		    linebreak_set_format(self, format_func, (void *)val);
		else {
		    char *s = SvPV_nolen(val);

		    if (strcasecmp(s, "DEFAULT") == 0) {
			warn("_config: "
			     "Method name \"DEFAULT\" for Format option was "
			     "obsoleted. Use \"SIMPLE\"");
			linebreak_set_format(self, linebreak_format_SIMPLE,
					     NULL);
		    } else if (strcasecmp(s, "SIMPLE") == 0)
			linebreak_set_format(self, linebreak_format_SIMPLE,
					     NULL);
		    else if (strcasecmp(s, "NEWLINE") == 0)
			linebreak_set_format(self, linebreak_format_NEWLINE,
					     NULL);
		    else if (strcasecmp(s, "TRIM") == 0)
			linebreak_set_format(self, linebreak_format_TRIM,
					     NULL);
		    else
			croak("_config: Unknown Format option: %s", s);
		}
	    } else if (strcasecmp(key, "Sizing") == 0) {
		if (! SvOK(val))
		    linebreak_set_sizing(self, NULL, NULL);
		else if (sv_derived_from(val, "CODE"))
		    linebreak_set_sizing(self, sizing_func, (void *)val);
		else {
		    char *s = SvPV_nolen(val);

		    if (strcasecmp(s, "DEFAULT") == 0) {
			warn("_config: "
			     "Method name \"DEFAULT\" for Sizing option "
			     "was obsoleted. Use \"UAX11\"");
			linebreak_set_sizing(self, linebreak_sizing_UAX11,
					     NULL);
		    } else if (strcasecmp(s, "UAX11") == 0)
			linebreak_set_sizing(self, linebreak_sizing_UAX11,
					     NULL);
		    else
			croak("_config: Unknown Sizing option: %s", s);
		}
	    } else if (strcasecmp(key, "Urgent") == 0) {
		if (! SvOK(val))
		    linebreak_set_urgent(self, NULL, NULL);
		else if (sv_derived_from(val, "CODE"))
		    linebreak_set_urgent(self, urgent_func, (void *)val);
		else {
		    char *s = SvPV_nolen(val);

		    if (strcasecmp(s, "NONBREAK") == 0) {
			warn("_config: "
			     "Method name \"NONBREAK\" for Urgent "
			     "option was obsoleted. Use undef");
			linebreak_set_urgent(self, NULL, NULL);
		    } else if (strcasecmp(s, "CROAK") == 0)
			linebreak_set_urgent(self, linebreak_urgent_ABORT,
					     NULL);
		    else if (strcasecmp(s, "FORCE") == 0)
			linebreak_set_urgent(self, linebreak_urgent_FORCE,
					     NULL);
		    else
			croak("_config: Unknown Urgent option: %s", s);
		}
	    } else if (strcasecmp(key, "BreakIndent") == 0) {
		if (SVtoboolean(val))
		    self->options |= LINEBREAK_OPTION_BREAK_INDENT;
		else
		    self->options &= ~LINEBREAK_OPTION_BREAK_INDENT;
	    } else if (strcasecmp(key, "CharMax") == 0)
		self->charmax = SvUV(val);
	    else if (strcasecmp(key, "ColMax") == 0)
		self->colmax = (double)SvNV(val);
	    else if (strcasecmp(key, "ColMin") == 0)
		self->colmin = (double)SvNV(val);
	    else if (strcasecmp(key, "ComplexBreaking") == 0) {
		if (SVtoboolean(val))
		    self->options |= LINEBREAK_OPTION_COMPLEX_BREAKING;
		else
		    self->options &= ~LINEBREAK_OPTION_COMPLEX_BREAKING;
	    } else if (strcasecmp(key, "Context") == 0) {
		if (SvOK(val))
		    opt = (char *)SvPV_nolen(val);
		else
		    opt = NULL;
		if (opt && strcasecmp(opt, "EASTASIAN") == 0)
		    self->options |= LINEBREAK_OPTION_EASTASIAN_CONTEXT;
		else
		    self->options &= ~LINEBREAK_OPTION_EASTASIAN_CONTEXT;
	    } else if (strcasecmp(key, "EAWidth") == 0) {
		AV *av, *codes;
		SV *sv;
		propval_t p;
		size_t i;

		if (! SvOK(val))
		    linebreak_clear_eawidth(self);
		else if (SvROK(val) &&
		    SvTYPE(av = (AV *)SvRV(val)) == SVt_PVAV &&
		    av_len(av) + 1 == 2 &&
		    av_fetch(av, 0, 0) != NULL && av_fetch(av, 1, 0) != NULL) {
		    sv = *av_fetch(av, 1, 0);
		    if (SvIOK(sv))
			p = (propval_t) SvIV(sv);
		    else
			croak("_config: Invalid argument");

		    sv = *av_fetch(av, 0, 0);
		    if (SvROK(sv) &&
			SvTYPE(codes = (AV *)SvRV(sv)) == SVt_PVAV) {
			for (i = 0; i < av_len(codes) + 1; i++) {
			    if (av_fetch(codes, i, 0) == NULL)
				continue;
			    if (! SvIOK(sv = *av_fetch(codes, i, 0)))
				croak("_config: Invalid argument");
			    linebreak_update_eawidth(self,
						     (unichar_t) SvUV(sv), p);
			}
		    } else if (SvIOK(sv)) {
			linebreak_update_eawidth(self, (unichar_t) SvUV(sv),
						 p);
		    } else
			croak("_config: Invalid argument");
		} else
		    croak("_config: Invalid argument");
	    } else if (strcasecmp(key, "HangulAsAL") == 0) {
		if (SVtoboolean(val))
		    self->options |= LINEBREAK_OPTION_HANGUL_AS_AL;
		else
		    self->options &= ~LINEBREAK_OPTION_HANGUL_AS_AL;
	    } else if (strcasecmp(key, "LBClass") == 0) {
		AV *av, *codes;
		SV *sv;
		propval_t p;
		size_t i;

		if (! SvOK(val))
		    linebreak_clear_lbclass(self);
		else if (SvROK(val) &&
		    SvTYPE(av = (AV *)SvRV(val)) == SVt_PVAV &&
		    av_len(av) + 1 == 2 &&
		    av_fetch(av, 0, 0) != NULL && av_fetch(av, 1, 0) != NULL) {
		    sv = *av_fetch(av, 1, 0);
		    if (SvIOK(sv))
			p = (propval_t) SvIV(sv);
		    else
			croak("_config: Invalid argument");

		    sv = *av_fetch(av, 0, 0);
		    if (SvROK(sv) &&
			SvTYPE(codes = (AV *)SvRV(sv)) == SVt_PVAV) {
			for (i = 0; i < av_len(codes) + 1; i++) {
			    if (av_fetch(codes, i, 0) == NULL)
				continue;
			    if (! SvIOK(sv = *av_fetch(codes, i, 0)))
				croak("_config: Invalid argument");
			    linebreak_update_lbclass(self,
						     (unichar_t) SvUV(sv), p);
			}
		    } else if (SvIOK(sv)) {
			linebreak_update_lbclass(self, (unichar_t) SvUV(sv),
						 p);
		    } else
			croak("_config: Invalid argument");
		} else
		    croak("_config: Invalid argument");
	    } else if (strcasecmp(key, "LegacyCM") == 0) {
		if (SVtoboolean(val))
		    self->options |= LINEBREAK_OPTION_LEGACY_CM;
		else
		    self->options &= ~LINEBREAK_OPTION_LEGACY_CM;
	    } else if (strcasecmp(key, "Newline") == 0) {
		if (!sv_isobject(val)) {
		    unistr_t unistr = {NULL, 0};
		    SVtounistr(&unistr, val);
		    linebreak_set_newline(self, &unistr);	
		    free(unistr.str);
		} else if (sv_derived_from(val, "Unicode::GCString"))
		    linebreak_set_newline(self,
					  (unistr_t *)PerltoC(gcstring_t *,
							      val));
		else
		    croak("_config: Unknown object %s",
			  HvNAME(SvSTASH(SvRV(val))));
	    } else if (strcasecmp(key, "ViramaAsJoiner") == 0) {
		if (SVtoboolean(val))
		    self->options |= LINEBREAK_OPTION_VIRAMA_AS_JOINER;
		else
		    self->options &= ~LINEBREAK_OPTION_VIRAMA_AS_JOINER;
	    } else
		warn("_config: Setting unknown option %s", key);
	}
    OUTPUT:
	RETVAL

void
as_hashref(self, ...)
	linebreak_t *self;
    CODE:
	if (self->stash == NULL)
	    XSRETURN_UNDEF;
	ST(0) = self->stash; /* should not be mortal */
	XSRETURN(1);

SV*
as_scalarref(self, ...)
	linebreak_t *self;
    PREINIT:
	char buf[64];
    CODE:
	buf[0] = '\0';
	snprintf(buf, 64, "%s(0x%lx)", HvNAME(SvSTASH(SvRV(ST(0)))),
		 (unsigned long)(void *)self);
	RETVAL = newRV_noinc(newSVpv(buf, 0));
    OUTPUT:
	RETVAL

SV *
as_string(self, ...)
	linebreak_t *self;
    PREINIT:
	char buf[64];
    CODE:
	buf[0] = '\0';
	snprintf(buf, 64, "%s(0x%lx)", HvNAME(SvSTASH(SvRV(ST(0)))),
		 (unsigned long)(void *)self);
	RETVAL = newSVpv(buf, 0);
    OUTPUT:
	RETVAL

propval_t
lbrule(self, b_idx, a_idx)
	linebreak_t *self;
	propval_t b_idx;
	propval_t a_idx;
    PROTOTYPE: $$$
    CODE:
	warn("lbrule() is obsoleted.  Use breakingRule()");
	if (!SvOK(ST(1)) || !SvOK(ST(2)))
	    XSRETURN_UNDEF;
	if (self == NULL)
	    XSRETURN_UNDEF;
	RETVAL = linebreak_get_lbrule(self, b_idx, a_idx);
	if (RETVAL == PROP_UNKNOWN)
	    XSRETURN_UNDEF;
    OUTPUT:
	RETVAL

propval_t
breakingRule(lbobj, bgcstr, agcstr)
	linebreak_t *lbobj;
	generic_string bgcstr;
	generic_string agcstr;
    PROTOTYPE: $$$
    PREINIT:
	propval_t blbc, albc;
    CODE:
	if (!SvOK(ST(1)) || !SvOK(ST(2)))
	    XSRETURN_UNDEF;
	if (lbobj == NULL)
	    XSRETURN_UNDEF;
	if ((blbc = gcstring_lbclass_ext(bgcstr, -1)) == PROP_UNKNOWN)
	    XSRETURN_UNDEF;
	if ((albc = gcstring_lbclass(agcstr, 0)) == PROP_UNKNOWN)
	    XSRETURN_UNDEF;
	RETVAL = linebreak_get_lbrule(lbobj, blbc, albc);
	if (RETVAL == PROP_UNKNOWN)
	    XSRETURN_UNDEF;
    OUTPUT:
	RETVAL

void
reset(self)
	linebreak_t *self;
    PROTOTYPE: $
    CODE:
	linebreak_reset(self);

double
strsize(lbobj, len, pre, spc, str, ...)
	linebreak_t *lbobj;
	double len;
	SV *pre;
	generic_string spc;
	generic_string str;
    PROTOTYPE: $$$$$;$
    CODE:
	warn("strsize() is obsoleted.  Use Unicode::GCString::columns");
	if (5 < items)
	     warn("``max'' argument of strsize was obsoleted");

	RETVAL = linebreak_sizing_UAX11(lbobj, len, NULL, spc, str);
	if (RETVAL == -1.0)
	    croak("strsize: %s", strerror(lbobj->errnum));
    OUTPUT:
	RETVAL

void
break(self, input)
	linebreak_t *self;
	unistr_t *input;
    PROTOTYPE: $$
    PREINIT:
	gcstring_t **ret, *r;
	size_t i;
    PPCODE:
	if (input == NULL)
	    XSRETURN_UNDEF;
	ret = linebreak_break(self, input);

	if (ret == NULL) {
	    if (self->errnum == LINEBREAK_EEXTN)
		croak("%s", SvPV_nolen(ERRSV));
	    else if (self->errnum == LINEBREAK_ELONG)
		croak("%s", "Excessive line was found");
	    else if (self->errnum)
		croak("%s", strerror(self->errnum));
	    else
		croak("%s", "Unknown error");
	}

	switch (GIMME_V) {
	case G_SCALAR:
	    r = gcstring_new(NULL, self);
	    for (i = 0; ret[i] != NULL; i++)
		gcstring_append(r, ret[i]);
	    linebreak_free_result(ret, 1);
	    XPUSHs(sv_2mortal(unistrtoSV((unistr_t *)r, 0, r->len)));
	    gcstring_destroy(r);
	    XSRETURN(1);

	case G_ARRAY:
	    for (i = 0; ret[i] != NULL; i++)
		XPUSHs(sv_2mortal(CtoPerl("Unicode::GCString", ret[i])));
	    linebreak_free_result(ret, 0);
	    XSRETURN(i);

	default:
	    linebreak_free_result(ret, 1);
	    XSRETURN_EMPTY;
	}

void
break_partial(self, input)
	linebreak_t *self;
	unistr_t *input;
    PROTOTYPE: $$
    PREINIT:
	gcstring_t **ret, *r;
	size_t i;
    PPCODE:
	ret = linebreak_break_partial(self, input);

	if (ret == NULL) {
	    if (self->errnum == LINEBREAK_EEXTN)
		croak("%s", SvPV_nolen(ERRSV));
	    else if (self->errnum == LINEBREAK_ELONG)
		croak("%s", "Excessive line was found");
	    else if (self->errnum)
		croak("%s", strerror(self->errnum));
	    else
		croak("%s", "Unknown error");
	}

	switch (GIMME_V) {
	case G_SCALAR:
	    r = gcstring_new(NULL, self);
	    for (i = 0; ret[i] != NULL; i++)
		gcstring_append(r, ret[i]);
	    linebreak_free_result(ret, 1);
	    XPUSHs(sv_2mortal(unistrtoSV((unistr_t *)r, 0, r->len)));
	    gcstring_destroy(r);
	    XSRETURN(1);

	case G_ARRAY:
	    for (i = 0; ret[i] != NULL; i++)
		XPUSHs(sv_2mortal(CtoPerl("Unicode::GCString", ret[i])));
	    linebreak_free_result(ret, 0);
	    XSRETURN(i);

	default:
	    linebreak_free_result(ret, 1);
	    XSRETURN_EMPTY;
	}

const char *
UNICODE_VERSION()
    CODE:
	RETVAL = linebreak_unicode_version;
    OUTPUT:
	RETVAL

const char *
SOMBOK_VERSION()
    CODE:
	RETVAL = SOMBOK_VERSION;
    OUTPUT:
	RETVAL


MODULE = Unicode::LineBreak	PACKAGE = Unicode::LineBreak::SouthEastAsian

const char *
supported()
    PROTOTYPE:
    CODE:
	RETVAL = linebreak_southeastasian_supported;
	if (RETVAL == NULL)
	    XSRETURN_UNDEF;
    OUTPUT:
	RETVAL

MODULE = Unicode::LineBreak	PACKAGE = Unicode::GCString	

gcstring_t *
_new(klass, str, lbobj=NULL)
	char *klass;
	unistr_t *str;
	linebreak_t *lbobj;
    PROTOTYPE: $$;$
    CODE:
	if (str == NULL)
	    XSRETURN_UNDEF;
	/* FIXME:buffer is copied twice. */
	if ((RETVAL = gcstring_newcopy(str, lbobj)) == NULL)
	    croak("%s->_new: %s", klass, strerror(errno));
    OUTPUT:
	RETVAL

void
DESTROY(self)
	gcstring_t *self;
    PROTOTYPE: $
    CODE:
	gcstring_destroy(self);

void
as_array(self)
	gcstring_t *self;
    PROTOTYPE: $
    PREINIT:
	size_t i;
    PPCODE:
	if (self != NULL)
	    for (i = 0; i < self->gclen; i++)
		XPUSHs(sv_2mortal(
			   CtoPerl("Unicode::GCString", 
				   gcstring_substr(self, i, 1))));

SV*
as_scalarref(self, ...)
	gcstring_t *self;
    PREINIT:
	char buf[64];
    CODE:
	buf[0] = '\0';
	snprintf(buf, 64, "%s(0x%lx)", HvNAME(SvSTASH(SvRV(ST(0)))),
		 (unsigned long)(void *)self);
	RETVAL = newRV_noinc(newSVpv(buf, 0));
    OUTPUT:
	RETVAL

SV *
as_string(self, ...)
	gcstring_t *self;
    PROTOTYPE: $;$;$
    CODE:
	RETVAL = unistrtoSV((unistr_t *)self, 0, self->len);
    OUTPUT:
	RETVAL

size_t
chars(self)
	gcstring_t *self;
    PROTOTYPE: $
    CODE:
	RETVAL = self->len;
    OUTPUT:
	RETVAL

#define lbobj self->lbobj
int
cmp(self, str, swap=FALSE)
	gcstring_t *self;
	generic_string str;
	swapspec_t swap;
    PROTOTYPE: $$;$
    CODE:
	if (swap == TRUE)
	    RETVAL = gcstring_cmp(str, self);
	else
	    RETVAL = gcstring_cmp(self, str);
    OUTPUT:
	RETVAL

size_t
columns(self)
	gcstring_t *self;
    CODE:
	RETVAL = gcstring_columns(self);
    OUTPUT:
	RETVAL

#define lbobj self->lbobj
gcstring_t *
concat(self, str, swap=FALSE)
	gcstring_t *self;
	generic_string str;
	swapspec_t swap;
    PROTOTYPE: $$;$
    CODE:
	if (swap == TRUE)
	    RETVAL = gcstring_concat(str, self);
	else if (swap == -1) {
	    gcstring_append(self, str);
	    XSRETURN(1);
	} else
	    RETVAL = gcstring_concat(self, str);
    OUTPUT:
	RETVAL

gcstring_t *
copy(self)
	gcstring_t *self;
    PROTOTYPE: $
    CODE:
	RETVAL = gcstring_copy(self);
    OUTPUT:
	RETVAL

int
eos(self)
	gcstring_t *self;
    CODE:
	RETVAL = gcstring_eos(self);
    OUTPUT:
	RETVAL

unsigned int
flag(self, ...)
	gcstring_t *self;
    PROTOTYPE: $;$;$
    PREINIT:
	int i;
	unsigned int flag;
    CODE:
	warn("flag() will be deprecated in near future");
	if (1 < items)
	    i = SvIV(ST(1));
	else
	    i = self->pos;
	if (i < 0 || self == NULL || self->gclen <= i)
	    XSRETURN_UNDEF;
	if (2 < items) {
	    flag = SvUV(ST(2));
	    if (flag == (flag & 255))
		self->gcstr[i].flag = (unsigned char)flag;
	    else
		warn("flag: unknown flag(s)");
	}
	RETVAL = (unsigned int)self->gcstr[i].flag;
    OUTPUT:
	RETVAL

gcstring_t *
item(self, ...)
	gcstring_t *self;
    PROTOTYPE: $;$
    PREINIT:
	int i;
    CODE:
	if (1 < items)
	    i = SvIV(ST(1));
	else
	    i = self->pos;
	if (i < 0 || self == NULL || self->gclen <= i)
	    XSRETURN_UNDEF;

	RETVAL = gcstring_substr(self, i, 1);
    OUTPUT:
	RETVAL

gcstring_t *
join(self, ...)
	gcstring_t *self;
    PREINIT:
	size_t i;
	gcstring_t *str;
    CODE:
	switch (items) {
	case 0:
	    croak("join: Too few arguments");
	case 1:
	    RETVAL = gcstring_new(NULL, self->lbobj);
	    break;
	case 2:
	    RETVAL = SVtogcstring(ST(1), self->lbobj);
	    if (sv_isobject(ST(1)))
		RETVAL = gcstring_copy(RETVAL);
	    break;
	default:
	    RETVAL = SVtogcstring(ST(1), self->lbobj);
	    if (sv_isobject(ST(1)))
		RETVAL = gcstring_copy(RETVAL);
	    for (i = 2; i < items; i++) {
		gcstring_append(RETVAL, self);
		str = SVtogcstring(ST(i), self->lbobj);
		gcstring_append(RETVAL, str);
		if (!sv_isobject(ST(i)))
		    gcstring_destroy(str);
	    }
	    break;
	}
    OUTPUT:
	RETVAL

propval_t
lbc(self)
	gcstring_t *self;
    PROTOTYPE: $
    CODE:
	if ((RETVAL = gcstring_lbclass(self, 0)) == PROP_UNKNOWN)
	    XSRETURN_UNDEF;
    OUTPUT:
	RETVAL

propval_t
lbcext(self)
	gcstring_t *self;
    PROTOTYPE: $
    CODE:
	if ((RETVAL = gcstring_lbclass_ext(self, -1)) == PROP_UNKNOWN)
	    XSRETURN_UNDEF;
    OUTPUT:
	RETVAL

propval_t
lbclass(self, ...)
	gcstring_t *self;
    PROTOTYPE: $;$
    PREINIT:
	int i;
    CODE:
	warn("lbclass() is obsoleted.  Use lbc()");
	if (1 < items)
	    i = SvIV(ST(1));
	else
	    i = self->pos;
	RETVAL = gcstring_lbclass(self, i);
	if (RETVAL == PROP_UNKNOWN)
	    XSRETURN_UNDEF;
    OUTPUT:
	RETVAL

propval_t
lbclass_ext(self, ...)
	gcstring_t *self;
    PROTOTYPE: $;$
    PREINIT:
	int i;
    CODE:
	warn("lbclass_ext() is obsoleted.  Use lbcext()");
	if (1 < items)
	    i = SvIV(ST(1));
	else
	    i = self->pos;
	RETVAL = gcstring_lbclass_ext(self, i);
	if (RETVAL == PROP_UNKNOWN)
	    XSRETURN_UNDEF;
    OUTPUT:
	RETVAL

size_t
length(self)
	gcstring_t *self;
    PROTOTYPE: $
    CODE:
	RETVAL = self->gclen;
    OUTPUT:
	RETVAL

gcstring_t *
next(self, ...)
	gcstring_t *self;
    PROTOTYPE: $;$;$
    PREINIT:
	gcchar_t *gc;
    CODE:
	if (gcstring_eos(self))
	    XSRETURN_UNDEF;
	gc = gcstring_next(self);
	RETVAL = gcstring_substr(self, gc - self->gcstr, 1);
    OUTPUT:
	RETVAL

size_t
pos(self, ...)
	gcstring_t *self;
    PROTOTYPE: $;$
    CODE:
	if (1 < items)
	    gcstring_setpos(self, SvIV(ST(1)));
	RETVAL = self->pos;
    OUTPUT:
	RETVAL

#define lbobj self->lbobj
gcstring_t *
substr(self, offset, length=self->gclen, replacement=NULL)
	gcstring_t *self;
	int offset;
	int length;
	generic_string replacement;
    PROTOTYPE: $$;$;$
    CODE:
	RETVAL = gcstring_substr(self, offset, length);
	if (replacement != NULL)
	    if (gcstring_replace(self, offset, length, replacement) == NULL)
		croak("substr: %s", strerror(errno));
	if (RETVAL == NULL)
	    croak("substr: %s", strerror(errno));
    OUTPUT:
	RETVAL

