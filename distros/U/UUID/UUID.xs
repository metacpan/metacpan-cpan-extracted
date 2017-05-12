#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


#ifdef PERL__UUID__UUID_UUID_H
#include <uuid/uuid.h>
#elif PERL__UUID__UUID_H
#include <uuid.h>
#elif PERL__UUID__RPC_H
#include <rpc.h>
#include <rpcdce.h>
#endif

#ifdef __cplusplus
}
#endif


/*
#ifndef SvPV_nolen
# define SvPV_nolen(sv) SvPV(sv, na)
#endif
*/


/* 2 hex digits per byte + 4 separators + 1 trailing null */
#define UUID_BUF_SZ() (2 * PERL__UUID__STRUCT_SZ + 4 + 1)

#ifdef PERL__UUID__E2FS_INT
#define UUID_T uuid_t
#define UUID2SV(u) ((char*)u)
#define SV2UUID(s) ((unsigned char*)SvGROW(s, sizeof(uuid_t)+1))

#elif PERL__UUID__RPC_INT
#define UUID_T uuid_t
#define UUID2SV(u) ((char*)&u)
#define SV2UUID(s) ((uuid_t*)SvGROW(s, sizeof(uuid_t)+1))

#elif PERL__UUID__WIN_INT
#define UUID_T UUID
#define UUID2SV(u) ((char*)&u)
#define SV2UUID(s) ((UUID*)SvGROW(s, sizeof(UUID)+1))

#endif

#define SV2STR(s)  (SvGROW(s, UUID_BUF_SZ()+1))


void do_generate(SV *str) {
    UUID_T uuid;
#ifdef PERL__UUID__E2FS_INT
    uuid_generate( uuid );
#elif PERL__UUID__RPC_INT
    int32_t s;
    uuid_create(&uuid, &s);
#elif PERL__UUID__WIN_INT
    RPC_STATUS st;
    st = UuidCreate(&uuid);
#endif
    sv_setpvn(str, UUID2SV(uuid), sizeof(UUID_T));
}


void do_generate_random(SV *str) {
    UUID_T uuid;
#ifdef PERL__UUID__E2FS_INT
    uuid_generate_random( uuid );
#elif PERL__UUID__RPC_INT
    int32_t s;
    uuid_create(&uuid, &s);
#elif PERL__UUID__WIN_INT
    UuidCreate(&uuid);
#endif
    sv_setpvn(str, UUID2SV(uuid), sizeof(UUID_T));
}


void do_generate_time(SV *str) {
    UUID_T uuid;
#ifdef PERL__UUID__E2FS_INT
    uuid_generate_time( uuid );
#elif PERL__UUID__RPC_INT
    int32_t s;
    uuid_create(&uuid, &s);
#elif PERL__UUID__WIN_INT
    UuidCreateSequential(&uuid);
#endif
    sv_setpvn(str, UUID2SV(uuid), sizeof(UUID_T));
}


void do_unparse(SV *in, SV * out) {
#ifdef PERL__UUID__E2FS_INT
    char str[UUID_BUF_SZ()];
    uuid_unparse(SV2UUID(in), str);
    sv_setpvn(out, str, UUID_BUF_SZ()-1);
#elif PERL__UUID__RPC_INT
    char *str;
    int32_t s;
    uuid_to_string(SV2UUID(in), &str, &s); /* free str */
    sv_setpvn(out, str, UUID_BUF_SZ()-1);
    free(str);
#elif PERL__UUID__WIN_INT
    RPC_CSTR str;
    RPC_STATUS st;
    st = UuidToString(SV2UUID(in), &str); /* free str */
    if( st != RPC_S_OK )
        croak("UuidToString error: %i", st);
    sv_setpvn(out, str, UUID_BUF_SZ()-1);
    RpcStringFree(&str);
#endif
}


void do_unparse_lower(SV *in, SV * out) {
#ifdef PERL__UUID__E2FS_INT
    char *p, str[UUID_BUF_SZ()];
    /* uuid_unparse_lower(SV2UUID(in), str); */ /* not on SunOS */
    uuid_unparse(SV2UUID(in), str);
    for(p=str; *p; ++p) *p = tolower(*p);
    sv_setpvn(out, str, UUID_BUF_SZ()-1);
#elif PERL__UUID__RPC_INT
    char *p, *str;
    int32_t s;
    uuid_to_string(SV2UUID(in), &str, &s); /* free str */
    for(p=str; *p; ++p) *p = tolower(*p);
    sv_setpvn(out, str, UUID_BUF_SZ()-1);
    free(str);
#elif PERL__UUID__WIN_INT
    char *p;
    RPC_CSTR str;
    RPC_STATUS st;
    st = UuidToString(SV2UUID(in), &str); /* free str */
    if( st != RPC_S_OK )
        croak("UuidToString error: %i", st);
    for(p=str; *p; ++p) *p = tolower(*p);
    sv_setpvn(out, str, UUID_BUF_SZ()-1);
    RpcStringFree(&str);
#endif
}


void do_unparse_upper(SV *in, SV * out) {
#ifdef PERL__UUID__E2FS_INT
    char *p, str[UUID_BUF_SZ()];
    /* uuid_unparse_upper(SV2UUID(in), str); */ /* not on SunOS */
    uuid_unparse(SV2UUID(in), str);
    for(p=str; *p; ++p) *p = toupper(*p);
    sv_setpvn(out, str, UUID_BUF_SZ()-1);
#elif PERL__UUID__RPC_INT
    char *p, *str;
    int32_t s;
    uuid_to_string(SV2UUID(in), &str, &s); /* free str */
    for(p=str; *p; ++p) *p = toupper(*p);
    sv_setpvn(out, str, UUID_BUF_SZ()-1);
    free(str);
#elif PERL__UUID__WIN_INT
    char *p;
    RPC_CSTR str;
    RPC_STATUS st;
    st = UuidToString(SV2UUID(in), &str); /* free str */
    if( st != RPC_S_OK )
        croak("UuidToString error: %i", st);
    for(p=str; *p; ++p) *p = toupper(*p);
    sv_setpvn(out, str, UUID_BUF_SZ()-1);
    RpcStringFree(&str);
#endif
}


int do_parse(SV *in, SV * out) {
    UUID_T uuid;
#ifdef PERL__UUID__E2FS_INT
    int rc;
    rc = uuid_parse(SV2STR(in), uuid);
    if( !rc )
        sv_setpvn(out, UUID2SV(uuid), sizeof(UUID_T));
    return rc;
#elif PERL__UUID__RPC_INT
    int rc;
    uuid_from_string(SV2STR(in), &uuid, &rc);
    if( !rc )
        sv_setpvn(out, UUID2SV(uuid), sizeof(UUID_T));
    return rc == uuid_s_ok ? 0 : -1;
#elif PERL__UUID__WIN_INT
    RPC_STATUS rc;
    rc = UuidFromString(SV2STR(in), &uuid);
    if( rc == RPC_S_OK )
        sv_setpvn(out, UUID2SV(uuid), sizeof(UUID_T));
    return rc == RPC_S_OK ? 0 : -1;
#endif
}


void do_clear(SV *in) {
    UUID_T uuid;
#ifdef PERL__UUID__E2FS_INT
    uuid_clear(uuid);
#elif PERL__UUID__RPC_INT
    int32_t s;
    uuid_create_nil(&uuid,&s);
#elif PERL__UUID__WIN_INT
    UuidCreateNil(&uuid);
#endif
    sv_setpvn(in, UUID2SV(uuid), sizeof(UUID_T));
}


int do_is_null(SV *in) {
#ifdef PERL__UUID__E2FS_INT
    if( SvCUR(in) != sizeof(uuid_t) )
        return 0;
    return uuid_is_null(SV2UUID(in));
#elif PERL__UUID__RPC_INT
    int32_t s;
    return uuid_is_nil(SV2UUID(in),&s);
#elif PERL__UUID__WIN_INT
    int rc;
    RPC_STATUS st;
    rc = UuidIsNil(SV2UUID(in), &st);
    return rc == TRUE ? 1 : 0;
#endif
}


int do_compare(SV *uu1, SV *uu2) {
#ifdef PERL__UUID__E2FS_INT
/*
    if( SvCUR(uu1) == sizeof(uuid_t) )
        if( SvCUR(uu2) == sizeof(uuid_t) )
            return uuid_compare(SV2UUID(uu1), SV2UUID(uu2));
*/
#elif PERL__UUID__RPC_INT
/*
    int32_t s;
    if( SvCUR(uu1) == sizeof(uuid_t) )
        if( SvCUR(uu2) == sizeof(uuid_t) )
            return uuid_compare(SV2UUID(uu1), SV2UUID(uu2), &s);
*/
#elif PERL__UUID__WIN_INT
#endif
    return sv_cmp(uu1, uu2);
}


void do_copy(SV *dst, SV *src) {
    UUID_T uuid;
#ifdef PERL__UUID__E2FS_INT
    if( SvCUR(src) != sizeof(uuid_t) )
        uuid_clear(uuid);
    else
        uuid_copy(uuid, SV2UUID(src));
#elif PERL__UUID__RPC_INT
    int32_t s;
    if( SvCUR(src) != sizeof(uuid_t) )
        uuid_create_nil(&uuid, &s);
    else
        memcpy(&uuid, SV2UUID(src), sizeof(uuid_t));
        /* uuid_copy(uuid, SV2UUID(src), &s);  <-- duh, not on bsd */
#elif PERL__UUID__WIN_INT
    if( SvCUR(src) != sizeof(uuid_t) )
        UuidCreateNil(&uuid);
    else
        memcpy(&uuid, SV2UUID(src), sizeof(UUID));
#endif
    sv_setpvn(dst, UUID2SV(uuid), sizeof(UUID_T));
}


SV* do_uuid() {
    UUID_T uuid;
#ifdef PERL__UUID__E2FS_INT
    char str[UUID_BUF_SZ()];
    uuid_generate(uuid);
    uuid_unparse(uuid, str);
    return newSVpvn(str, UUID_BUF_SZ()-1);
#elif PERL__UUID__RPC_INT
    SV *sv;
    char *str;
    int32_t s;
    uuid_create(&uuid, &s);
    uuid_to_string(&uuid, &str, &s); /* free str */
    sv = newSVpvn(str, UUID_BUF_SZ()-1);
    free(str);
    return sv;
#elif PERL__UUID__WIN_INT
    SV *sv;
    RPC_STATUS st;
    RPC_CSTR str;
    UuidCreateSequential(&uuid);
    st = UuidToString(&uuid, &str); /* free str */
    if( st != RPC_S_OK )
        croak("UuidToString error: %i", st);
    sv = newSVpvn(str, UUID_BUF_SZ()-1);
    RpcStringFree(&str);
    return sv;
#endif
}


void do_debug() {
    SV *bmsg, *smsg;
#ifdef PERL__UUID__UUID_UUID_H
    PerlIO_puts(PerlIO_stderr(), "# Header: uuid/uuid.h\n");
#elif PERL__UUID__UUID_H
    PerlIO_puts(PerlIO_stderr(), "# Header: uuid.h\n");
#elif PERL__UUID__RPC_H
    PerlIO_puts(PerlIO_stderr(), "# Header: rpc.h\n");
#endif

#ifdef PERL__UUID__E2FS_INT
    PerlIO_puts(PerlIO_stderr(), "# Interface: e2fs\n");
#elif PERL__UUID__RPC_INT
    PerlIO_puts(PerlIO_stderr(), "# Interface: rpc\n");
#elif PERL__UUID__WIN_INT
    PerlIO_puts(PerlIO_stderr(), "# Interface: win\n");
#endif

    bmsg = mess("# Buffer size: %i\n", UUID_BUF_SZ());
    PerlIO_puts(PerlIO_stderr(), SvPVX(bmsg));
    smsg = mess("# Struct size: %i\n", PERL__UUID__STRUCT_SZ);
    PerlIO_puts(PerlIO_stderr(), SvPVX(smsg));
}



MODULE = UUID		PACKAGE = UUID		


void
generate(str)
    SV * str
    PROTOTYPE: $
    CODE:
    do_generate(str); 

void
generate_random(str)
    SV * str
    PROTOTYPE: $
    CODE:
    do_generate_random(str); 

void
generate_time(str)
    SV * str
    PROTOTYPE: $
    CODE:
    do_generate_time(str); 

void
unparse(in, out)
    SV * in
    SV * out
    PROTOTYPE: $$
    CODE:
    do_unparse(in, out);

void
unparse_lower(in, out)
    SV * in
    SV * out
    PROTOTYPE: $$
    CODE:
    do_unparse_lower(in, out);

void
unparse_upper(in, out)
    SV * in
    SV * out
    PROTOTYPE: $$
    CODE:
    do_unparse_upper(in, out);

int
parse(in, out)
    SV * in
    SV * out
    PROTOTYPE: $$
    CODE: 
    RETVAL = do_parse(in, out);
    OUTPUT:
    RETVAL

void
clear(in)
    SV * in
    PROTOTYPE: $
    CODE:
    do_clear(in);

int
is_null(in)
    SV * in
    PROTOTYPE: $
    CODE:
    RETVAL = do_is_null(in);
    OUTPUT:
    RETVAL

void
copy(dst, src)
    SV * dst
    SV * src
    CODE:
    do_copy(dst, src);

int
compare(uu1, uu2)
    SV * uu1
    SV * uu2
    CODE:
    RETVAL = do_compare(uu1, uu2);
    OUTPUT:
    RETVAL

SV*
uuid()
    PROTOTYPE:
    CODE:
    RETVAL = do_uuid();
    OUTPUT:
    RETVAL

void
debug()
    PROTOTYPE:
    CODE:
    do_debug();

