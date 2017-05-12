/* Copyright 2000-2004  The Apache Software Foundation
**
** Licensed under the Apache License, Version 2.0 (the "License");
** you may not use this file except in compliance with the License.
** You may obtain a copy of the License at
**
**     http://www.apache.org/licenses/LICENSE-2.0
**
** Unless required by applicable law or agreed to in writing, software
** distributed under the License is distributed on an "AS IS" BASIS,
** WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
** See the License for the specific language governing permissions and
** limitations under the License.
*/

#define PERL_NO_GET_CONTEXT     /* we want efficiency */

#ifdef WIN32

#ifdef uid_t
#define apache_uid_t uid_t
#undef uid_t
#endif
#define uid_t apache_uid_t

#ifdef gid_t
#define apache_gid_t gid_t
#undef gid_t
#endif
#define gid_t apache_gid_t

#ifdef stat
#define apache_stat stat
#undef stat
#endif

#ifdef lstat
#define apache_lstat lstat
#undef lstat
#endif

#ifdef isnan
#define apache_isnan isnan
#undef isnan
#endif

#ifdef sleep
#define apache_sleep sleep
#undef sleep
#endif

#endif /* WIN32 */

#undef __attribute__
#include "mod_perl.h"
#include "apache_cookie.h"

#ifdef WIN32

#undef uid_t
#ifdef apache_uid_t
#define uid_t apache_uid_t
#undef apache_uid_t
#endif

#undef gid_t
#ifdef apache_gid_t
#define gid_t apache_gid_t
#undef apache_gid_t
#endif

#ifdef apache_isnan
#undef isnan
#define isnan apache_isnan
#undef apache_isnan
#endif
 
#ifdef apache_lstat
#undef lstat
#define lstat apache_lstat
#undef apache_lstat
#endif

#ifdef apache_stat
#undef stat
#define stat apache_stat
#undef apache_stat
#endif

#ifdef apache_sleep
#undef sleep
#define sleep apache_sleep
#undef apache_sleep
#endif

#endif /* WIN32 */

typedef ApacheCookie * Apache__Cookie;

static SV *cookie_bless(pTHX_ ApacheCookie *c)
{
    SV *sv = newSV(0); 
    sv_setref_pv(sv, "Apache::Cookie", (void*)c); 
    return sv;
}

static ApacheCookie *sv_2cookie(pTHX_ SV *sv)
{
    if (SvROK(sv) && sv_derived_from(sv, "Apache::Cookie")) { 
	return (ApacheCookie *)SvIV((SV*)SvRV(sv)); 
    } 
    else {
	return ApacheCookie_new(perl_request_rec(NULL), NULL);
    }
}

#define cookie_push(c) \
    XPUSHs(sv_2mortal(newSVpv(c->name,0))); \
    XPUSHs(sv_2mortal(cookie_bless(aTHX_ c)))

#define ApacheCookie_name(c, val) \
ApacheCookie_attr(c, "name", val)

#define ApacheCookie_domain(c, val) \
ApacheCookie_attr(c, "domain", val)

#define ApacheCookie_path(c, val) \
ApacheCookie_attr(c, "path", val)

#define ApacheCookie_secure(c, val) \
ApacheCookie_attr(c, "secure", val)

MODULE = Apache::Cookie    PACKAGE = Apache::Cookie   PREFIX = ApacheCookie_

PROTOTYPES: DISABLE 

Apache::Cookie
ApacheCookie_new(class, r, ...)
    SV *class
    Apache r

    PREINIT:
    I32 i;

    CODE:
    class = class; /* -Wall */ 
    RETVAL = ApacheCookie_new(r, NULL);
    for (i=2; i<items; i+=2) {
	char *key = SvPV(ST(i),na);
	SV *val = ST(i+1);

	if (SvROK(val)) {
	    if (SvTYPE(SvRV(val)) == SVt_PVAV) {
		I32 n;
		AV *av = (AV*)SvRV(val);

		for (n=0; n<=AvFILL(av); n++) {
		    (void)ApacheCookie_attr(RETVAL, key, 
					   SvPV(*av_fetch(av, n, FALSE),na));
		}
	    }
	    else if (SvTYPE(SvRV(val)) == SVt_PVHV) {
		HV *hv = (HV*)SvRV(val);
		SV *sv; 
		char *value; 
		I32 len; 

		(void)hv_iterinit(hv); 
		while ((sv = hv_iternextsv(hv, &value, &len))) { 
		    (void)ApacheCookie_attr(RETVAL, key, value);
		    (void)ApacheCookie_attr(RETVAL, key, 
					    sv == &PL_sv_undef ? 
					    "" : SvPV(sv,na));
		}
	    }
	    else {
		croak("not an ARRAY or HASH reference!");
	    }
	}
	else {
	    (void)ApacheCookie_attr(RETVAL, key, SvPV(val,na));
	}
    }

    OUTPUT:
    RETVAL

char *
ApacheCookie_as_string(c)
    Apache::Cookie c

void
ApacheCookie_parse(sv, string=NULL)
    SV *sv
    char *string

    ALIAS:
    Apache::Cookie::fetch = 1

    PREINIT:
    ApacheCookieJar *cookies;
    ApacheCookie *c;
    int i;

    PPCODE:
    if ((ix = XSANY.any_i32) == 1) {
	request_rec *r = perl_request_rec(NULL);
	c = ApacheCookie_new(r, NULL);
    }
    else {
	c = sv_2cookie(aTHX_ sv);
    }

    cookies = ApacheCookie_parse(c->r, string);
    if (!ApacheCookieJarItems(cookies)) {
	XSRETURN_EMPTY;
    }
    if (GIMME == G_SCALAR) {
	HV *hv = newHV();
	SV *sv;

	for (i=0; i<ApacheCookieJarItems(cookies); i++) {
	    ApacheCookie *c = ApacheCookieJarFetch(cookies, i);

	    if (c && c->name) {
		hv_store(hv, c->name, strlen(c->name),
                         cookie_bless(aTHX_ c), FALSE);
	    }
	}
        sv = newRV_noinc((SV*)hv); 
        XPUSHs(sv_2mortal(sv)); 
    }
    else {
	for (i=0; i<cookies->nelts; i++) {
	    cookie_push(ApacheCookieJarFetch(cookies, i));
	}
    }

void
ApacheCookie_value(c, val=Nullsv)
    Apache::Cookie c
    SV *val

    PREINIT:
    int i;
    I32 gimmes = (GIMME == G_SCALAR);

    PPCODE:
    for (i = 0; i<ApacheCookieItems(c); i++) {
	XPUSHs(sv_2mortal(newSVpv(ApacheCookieFetch(c,i),0)));
	if (gimmes) {
	    break;
	}
    }

    if (val) {
	STRLEN len;
	char *value;

	ApacheCookieItems(c) = 0;
	if (SvROK(val)) {
	    AV *av = (AV*)SvRV(val);
	    for (i=0; i<=AvFILL(av); i++) {
		SV *sv = *av_fetch(av, i, FALSE);    
		value = SvPV(sv,len);
		ApacheCookieAddLen(c, value, len);
	    }
	} 
	else {
	    value = SvPV(val,len);
	    ApacheCookieAddLen(c, value, len);
	}
    }

char *
ApacheCookie_name(c, val=NULL)
    Apache::Cookie c
    char *val

char *
ApacheCookie_domain(c, val=NULL)
    Apache::Cookie c
    char *val

char *
ApacheCookie_path(c, val=NULL)
    Apache::Cookie c
    char *val

char *
ApacheCookie_expires(c, val=NULL)
    Apache::Cookie c
    char *val

char *
ApacheCookie_secure(c, val=NULL)
    Apache::Cookie c
    char *val

void
ApacheCookie_bake(c)
    Apache::Cookie c

