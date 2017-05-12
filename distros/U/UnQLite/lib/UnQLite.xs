#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT /* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#ifdef __cplusplus
} /* extern "C" */
#endif

#define NEED_newSVpvn_flags
#include "ppport.h"
#include <unqlite.h>

#define XS_STATE(type, x)     (INT2PTR(type, SvROK(x) ? SvIV(SvRV(x)) : SvIV(x)))

#define XS_STRUCT2OBJ(sv, class, obj) \
    sv = newSViv(PTR2IV(obj));  \
    sv_magic(sv, sv_2mortal(newSViv(UNQLITE_OK)), PERL_MAGIC_ext, NULL, 0); \
    sv = newRV_noinc(sv); \
    sv_bless(sv, gv_stashpv(class, 1)); \
    SvREADONLY_on(sv);

#define SETRC(rc, self) \
    { \
        SV * i = get_sv("UnQLite::rc", GV_ADD); \
        SvIV_set(i, rc); \
        if (SvROK(self)) { \
            MAGIC *_mg = mg_find(SvRV(self), PERL_MAGIC_ext); \
            if (_mg) { \
                SvIV_set(_mg->mg_obj, rc); \
            } \
        } \
    }

MODULE = UnQLite    PACKAGE = UnQLite

PROTOTYPES: DISABLE

BOOT:
    HV* stash = gv_stashpvn("UnQLite", strlen("UnQLite"), TRUE);
#define _XSTR(s) _STR(s)
#define _STR(s)  #s
#define UnConst(c) newCONSTSUB(stash, "UNQ"_XSTR(c), newSViv(UNQ##c))
    UnConst(LITE_OK);
    UnConst(LITE_NOMEM);
    UnConst(LITE_ABORT);
    UnConst(LITE_IOERR);
    UnConst(LITE_CORRUPT);
    UnConst(LITE_LOCKED);
    UnConst(LITE_BUSY);
    UnConst(LITE_DONE);
    UnConst(LITE_PERM);
    UnConst(LITE_NOTIMPLEMENTED);
    UnConst(LITE_NOTFOUND);
    UnConst(LITE_NOOP);
    UnConst(LITE_INVALID);
    UnConst(LITE_EOF);
    UnConst(LITE_UNKNOWN);
    UnConst(LITE_LIMIT);
    UnConst(LITE_EXISTS);
    UnConst(LITE_EMPTY);
    UnConst(LITE_COMPILE_ERR);
    UnConst(LITE_VM_ERR);
    UnConst(LITE_FULL);
    UnConst(LITE_CANTOPEN);
    UnConst(LITE_READ_ONLY);
    UnConst(LITE_LOCKERR);
    UnConst(LITE_OPEN_READONLY);
    UnConst(LITE_OPEN_READWRITE);
    UnConst(LITE_OPEN_CREATE);
    UnConst(LITE_OPEN_EXCLUSIVE);
    UnConst(LITE_OPEN_TEMP_DB);
    UnConst(LITE_OPEN_OMIT_JOURNALING);
    UnConst(LITE_OPEN_IN_MEMORY);
    UnConst(LITE_OPEN_MMAP);
    UnConst(LITE_CURSOR_MATCH_EXACT);
    UnConst(LITE_CURSOR_MATCH_LE);
    UnConst(LITE_CURSOR_MATCH_GE);

SV*
open(klass, filename, mode=UNQLITE_OPEN_CREATE)
    const char *klass;
    const char *filename;
    int mode;
PREINIT:
    SV *sv;
    unqlite *pdb;
    int rc;
CODE:
    rc = unqlite_open(&pdb, filename, mode);
    if (rc == UNQLITE_OK) {
        XS_STRUCT2OBJ(sv, klass, pdb);
        SETRC(rc, sv);
        RETVAL = sv;
    } else {
        SETRC(rc, &PL_sv_undef);
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

SV* _rc(self)
    SV *self
PREINIT:
    MAGIC *mg;
CODE:
    if (SvROK(self)) {
        mg = mg_find(SvRV(self), PERL_MAGIC_ext);
        if (mg) {
            RETVAL = newSVsv(mg->mg_obj);
        } else {
            RETVAL = &PL_sv_undef;
        }
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

SV*
kv_store(self, key_sv, data_sv)
    SV *self;
    SV *key_sv;
    SV *data_sv;
PREINIT:
    char *key_c;
    STRLEN key_l;
    char *data_c;
    STRLEN data_l;
    int rc;
CODE:
    unqlite *pdb = XS_STATE(unqlite*, self);
    key_c = SvPV(key_sv, key_l);
    data_c = SvPV(data_sv, data_l);
    rc = unqlite_kv_store(pdb, key_c, key_l, data_c, data_l);
    SETRC(rc, self);
    if (rc==UNQLITE_OK) {
        RETVAL = &PL_sv_yes;
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

SV*
kv_append(self, key_sv, data_sv)
    SV *self;
    SV *key_sv;
    SV *data_sv;
PREINIT:
    char *key_c;
    STRLEN key_l;
    char *data_c;
    STRLEN data_l;
    int rc;
CODE:
    unqlite *pdb = XS_STATE(unqlite*, self);
    key_c = SvPV(key_sv, key_l);
    data_c = SvPV(data_sv, data_l);
    rc = unqlite_kv_append(pdb, key_c, key_l, data_c, data_l);
    SETRC(rc, self);
    if (rc==UNQLITE_OK) {
        RETVAL = &PL_sv_yes;
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

SV*
kv_delete(self, key_sv)
    SV *self;
    SV *key_sv;
PREINIT:
    char *key_c;
    STRLEN key_l;
    int rc;
CODE:
    unqlite *pdb = XS_STATE(unqlite*, self);
    key_c = SvPV(key_sv, key_l);
    rc = unqlite_kv_delete(pdb, key_c, key_l);
    SETRC(rc, self);
    if (rc==UNQLITE_OK) {
        RETVAL = &PL_sv_yes;
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

SV*
kv_fetch(self, key_sv)
    SV *self;
    SV *key_sv;
PREINIT:
    char *key_c;
    STRLEN key_l;
    char *buf;
    int rc;
    unqlite_int64 nbytes;
    SV *sv;
CODE:
    unqlite *pdb = XS_STATE(unqlite*, self);
    key_c = SvPV(key_sv, key_l);

    /* Allocate a buffer big enough to hold the record content */
    rc = unqlite_kv_fetch(pdb, key_c, key_l, NULL, &nbytes);
    SETRC(rc, self);
    if (rc!=UNQLITE_OK) {
        RETVAL = &PL_sv_undef;
        goto last;
    }
    Newxz(buf, nbytes, char);
    rc = unqlite_kv_fetch(pdb, key_c, key_l, buf, &nbytes);
    SETRC(rc, self);
    sv = newSVpv(buf, nbytes);
    Safefree(buf);
    RETVAL = sv;
    last:
OUTPUT:
    RETVAL

void
DESTROY(self)
    SV * self;
PREINIT:
    int rc;
CODE:
    unqlite *pdb = XS_STATE(unqlite*, self);
    rc = unqlite_close(pdb);
    SETRC(rc, &PL_sv_undef);

SV*
_cursor_init(self)
    SV * self;
PREINIT:
    SV * sv;
    int rc;
    unqlite_kv_cursor* cursor;
CODE:
    unqlite *pdb = XS_STATE(unqlite*, self);
    rc = unqlite_kv_cursor_init(pdb, &cursor);
    SETRC(rc, self);
    if (rc == UNQLITE_OK) {
        sv = newSViv(PTR2IV(cursor));
        sv_magic(sv, sv_2mortal(newSViv(UNQLITE_OK)), PERL_MAGIC_ext, NULL, 0);
        sv = newRV_noinc(sv);
        SvREADONLY_on(sv);
        RETVAL = sv;
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL


MODULE = UnQLite    PACKAGE = UnQLite::Cursor

SV* _rc(self)
    SV *self
PREINIT:
    MAGIC *mg;
CODE:
    if (SvROK(self)) {
        mg = mg_find(SvRV(self), PERL_MAGIC_ext);
        if (mg) {
            RETVAL = newSVsv(mg->mg_obj);
        } else {
            RETVAL = &PL_sv_undef;
        }
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

SV*
_first_entry(self)
    SV * self;
PREINIT:
    SV * sv;
    int rc;
CODE:
    unqlite_kv_cursor *cursor = XS_STATE(unqlite_kv_cursor*, self);
    rc = unqlite_kv_cursor_first_entry(cursor);
    SETRC(rc, self);
    if (rc == UNQLITE_OK) {
        RETVAL = &PL_sv_yes;
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

int
_valid_entry(self)
    SV * self;
PREINIT:
    SV * sv;
    int rc;
CODE:
    unqlite_kv_cursor *cursor = XS_STATE(unqlite_kv_cursor*, self);
    /* This will return 1 when valid. 0 otherwise */
    rc = unqlite_kv_cursor_valid_entry(cursor);
    RETVAL = rc;
OUTPUT:
    RETVAL

SV*
_next_entry(self)
    SV * self;
PREINIT:
    SV * sv;
    int rc;
CODE:
    unqlite_kv_cursor *cursor = XS_STATE(unqlite_kv_cursor*, self);
    rc = unqlite_kv_cursor_next_entry(cursor);
    SETRC(rc, self);
    if (rc == UNQLITE_OK) {
        RETVAL = &PL_sv_yes;
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

SV*
_last_entry(self)
    SV * self;
PREINIT:
    SV * sv;
    int rc;
CODE:
    unqlite_kv_cursor *cursor = XS_STATE(unqlite_kv_cursor*, self);
    rc = unqlite_kv_cursor_last_entry(cursor);
    SETRC(rc, self);
    if (rc == UNQLITE_OK) {
        RETVAL = &PL_sv_yes;
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

SV*
_prev_entry(self)
    SV * self;
PREINIT:
    SV * sv;
    int rc;
CODE:
    unqlite_kv_cursor *cursor = XS_STATE(unqlite_kv_cursor*, self);
    rc = unqlite_kv_cursor_prev_entry(cursor);
    SETRC(rc, self);
    if (rc == UNQLITE_OK) {
        RETVAL = &PL_sv_yes;
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

SV*
_key(self)
    SV * self;
PREINIT:
    SV * sv;
    int rc;
    int nbytes;
    char*buf;
CODE:
    unqlite_kv_cursor *cursor = XS_STATE(unqlite_kv_cursor*, self);
    rc = unqlite_kv_cursor_key(cursor, NULL, &nbytes);
    SETRC(rc, self);
    if (rc!=UNQLITE_OK) {
        RETVAL = &PL_sv_undef;
        goto last;
    }
    Newxz(buf, nbytes, char);
    rc = unqlite_kv_cursor_key(cursor, buf, &nbytes);
    SETRC(rc, self);
    sv = newSVpv(buf, nbytes);
    Safefree(buf);
    RETVAL = sv;
    last:
OUTPUT:
    RETVAL

SV*
_data(self)
    SV * self;
PREINIT:
    SV * sv;
    int rc;
    unqlite_int64 nbytes;
    char*buf;
CODE:
    unqlite_kv_cursor *cursor = XS_STATE(unqlite_kv_cursor*, self);
    rc = unqlite_kv_cursor_data(cursor, NULL, &nbytes);
    SETRC(rc, self);
    if (rc!=UNQLITE_OK) {
        RETVAL = &PL_sv_undef;
        goto last;
    }
    Newxz(buf, nbytes, char);
    rc = unqlite_kv_cursor_data(cursor, buf, &nbytes);
    SETRC(rc, self);
    sv = newSVpv(buf, nbytes);
    Safefree(buf);
    RETVAL = sv;
    last:
OUTPUT:
    RETVAL

void
_release(self, db)
    SV * self;
    SV * db;
CODE:
    unqlite *pdb = XS_STATE(unqlite*, db);
    unqlite_kv_cursor *cursor = XS_STATE(unqlite_kv_cursor*, self);
    unqlite_kv_cursor_release(pdb, cursor);

SV*
_seek(self, key_s, opt=UNQLITE_CURSOR_MATCH_EXACT)
    SV * self;
    SV * key_s;
    int opt;
PREINIT:
    STRLEN len;
    char * key;
    int rc;
CODE:
    unqlite_kv_cursor *cursor = XS_STATE(unqlite_kv_cursor*, self);
    key = SvPV(key_s, len);
    rc = unqlite_kv_cursor_seek(cursor, key, len, opt);
    SETRC(rc, self);
    if (rc == UNQLITE_OK) {
        RETVAL = &PL_sv_yes;
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

SV*
_delete_entry(self)
    SV * self;
PREINIT:
    int rc;
CODE:
    unqlite_kv_cursor *cursor = XS_STATE(unqlite_kv_cursor*, self);
    rc = unqlite_kv_cursor_delete_entry(cursor);
    SETRC(rc, self);
    if (rc == UNQLITE_OK) {
        RETVAL = &PL_sv_yes;
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL
