#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <EUMM.h>
#include <config.h>
#include <uuid/uuid.h>
#include <uuid/uuidP.h>

#ifdef __cplusplus
}
#endif


/* 2 hex digits per byte + 4 separators + 1 trailing null */
#define UUID_BUF_SZ 37

/* test code at top of CODE section of generate() and friends */
/*
    sv_setpvn(str, foo, 1);
    SvPV_force_nomg(str, len);
    sv_grow(str,17);
*/

MODULE = UUID		PACKAGE = UUID


void
generate(str)
    SV * str
    PROTOTYPE: $
    INIT:
    myuuid_t uu;
    CODE:
    myuuid_generate(uu);
    sv_setpvn(str, (char*)uu, sizeof(myuuid_t));

void
generate_random(str)
    SV * str
    PROTOTYPE: $
    INIT:
    myuuid_t uu;
    CODE:
    myuuid_generate_random(uu);
    sv_setpvn(str, (char*)uu, sizeof(myuuid_t));

void
generate_time(str)
    SV * str
    PROTOTYPE: $
    INIT:
    myuuid_t uu;
    CODE:
    myuuid_generate_time(uu);
    sv_setpvn(str, (char*)uu, sizeof(myuuid_t));

void
unparse(in, out)
    SV * in
    SV * out
    PROTOTYPE: $$
    INIT:
    char str[UUID_BUF_SZ];
    CODE:
    myuuid_unparse((unsigned char*)sv_grow(in, sizeof(myuuid_t)+1), str);
    sv_setpvn(out, str, UUID_BUF_SZ-1);

void
unparse_lower(in, out)
    SV * in
    SV * out
    PROTOTYPE: $$
    INIT:
    char str[UUID_BUF_SZ];
    CODE:
    myuuid_unparse_lower((unsigned char*)sv_grow(in, sizeof(myuuid_t)+1), str);
    sv_setpvn(out, str, UUID_BUF_SZ-1);

void
unparse_upper(in, out)
    SV * in
    SV * out
    PROTOTYPE: $$
    INIT:
    char str[UUID_BUF_SZ];
    CODE:
    myuuid_unparse_upper((unsigned char*)sv_grow(in, sizeof(myuuid_t)+1), str);
    sv_setpvn(out, str, UUID_BUF_SZ-1);

int
parse(in, out)
    SV * in
    SV * out
    PROTOTYPE: $$
    INIT:
    myuuid_t uu;
    CODE:
    RETVAL = myuuid_parse(sv_grow(in, UUID_BUF_SZ+1), uu);
    if( !RETVAL )
        sv_setpvn(out, (char*)uu, sizeof(myuuid_t));
    OUTPUT:
    RETVAL

void
clear(in)
    SV * in
    PROTOTYPE: $
    INIT:
    myuuid_t uu;
    CODE:
    myuuid_clear(uu);
    sv_setpvn(in, (char*)uu, sizeof(myuuid_t));

int
is_null(in)
    SV * in
    PROTOTYPE: $
    CODE:
    if( SvCUR(in) != sizeof(myuuid_t) )
        RETVAL = 0;
    else
        RETVAL = myuuid_is_null((unsigned char*)sv_grow(in, sizeof(myuuid_t)+1));
    OUTPUT:
    RETVAL

void
copy(dst, src)
    SV * dst
    SV * src
    PROTOTYPE: $$
    INIT:
    myuuid_t uu;
    CODE:
    if( SvCUR(src) != sizeof(myuuid_t) )
        myuuid_clear(uu);
    else
        myuuid_copy(uu, (unsigned char*)sv_grow(src, sizeof(myuuid_t)+1));
    sv_setpvn(dst, (char*)uu, sizeof(myuuid_t));

int
compare(uu1, uu2)
    SV * uu1
    SV * uu2
    PROTOTYPE: $$
    INIT:
    unsigned char *p1;
    unsigned char *p2;
    CODE:
    p1 = (unsigned char*)sv_grow(uu1, sizeof(myuuid_t)+1);
    p2 = (unsigned char*)sv_grow(uu2, sizeof(myuuid_t)+1);
    RETVAL = myuuid_compare(p1, p2);
    OUTPUT:
    RETVAL

int
type(in)
    SV * in
    PROTOTYPE: $
    CODE:
    RETVAL = myuuid_type((unsigned char*)sv_grow(in, sizeof(myuuid_t)+1));
    OUTPUT:
    RETVAL

time_t
time(in)
    SV * in
    PROTOTYPE: $
    INIT:
    struct timeval tv;
    CODE:
    RETVAL = myuuid_time((unsigned char*)sv_grow(in, sizeof(myuuid_t)+1), &tv);
    OUTPUT:
    RETVAL

int
variant(in)
    SV * in
    PROTOTYPE: $
    CODE:
    RETVAL = myuuid_variant((unsigned char*)sv_grow(in, sizeof(myuuid_t)+1));
    OUTPUT:
    RETVAL

SV*
uuid()
    PROTOTYPE:
    INIT:
    myuuid_t uu;
    char str[UUID_BUF_SZ];
    CODE:
    myuuid_generate(uu);
    myuuid_unparse(uu, str);
    RETVAL = newSVpvn(str, UUID_BUF_SZ-1);
    OUTPUT:
    RETVAL
