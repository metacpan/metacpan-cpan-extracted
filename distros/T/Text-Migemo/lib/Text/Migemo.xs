#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_newCONSTSUB
#define NEED_newRV_noinc
#define NEED_sv_2pv_nolen
#include "ppport.h"
#include "migemo.h"

static void
init_constants()
{
    HV *stash;
    stash = gv_stashpv("Text::Migemo", 1);
    newCONSTSUB(stash, "MIGEMO_DICTID_MIGEMO",      newSViv(MIGEMO_DICTID_MIGEMO));
    newCONSTSUB(stash, "MIGEMO_DICTID_ROMA2HIRA",   newSViv(MIGEMO_DICTID_ROMA2HIRA));
    newCONSTSUB(stash, "MIGEMO_DICTID_HIRA2KATA",   newSViv(MIGEMO_DICTID_HIRA2KATA));
    newCONSTSUB(stash, "MIGEMO_DICTID_HAN2ZEN",     newSViv(MIGEMO_DICTID_HAN2ZEN));
    newCONSTSUB(stash, "MIGEMO_DICTID_INVALID",     newSViv(MIGEMO_DICTID_INVALID));
    newCONSTSUB(stash, "MIGEMO_OPINDEX_OR",         newSViv(MIGEMO_OPINDEX_OR));
    newCONSTSUB(stash, "MIGEMO_OPINDEX_NEST_IN",    newSViv(MIGEMO_OPINDEX_NEST_IN));
    newCONSTSUB(stash, "MIGEMO_OPINDEX_NEST_OUT",   newSViv(MIGEMO_OPINDEX_NEST_OUT));
    newCONSTSUB(stash, "MIGEMO_OPINDEX_SELECT_IN",  newSViv(MIGEMO_OPINDEX_SELECT_IN));
    newCONSTSUB(stash, "MIGEMO_OPINDEX_SELECT_OUT", newSViv(MIGEMO_OPINDEX_SELECT_OUT));
    newCONSTSUB(stash, "MIGEMO_OPINDEX_NEWLINE",    newSViv(MIGEMO_OPINDEX_NEWLINE));
}

MODULE = Text::Migemo		PACKAGE = Text::Migemo

PROTOTYPES: ENABLE

BOOT:
    init_constants();

SV *
new(class, dict = NULL)
        SV *class;
        char *dict;
    PREINIT:
        SV *sv;
        migemo *m;
    CODE:
        m = migemo_open(dict);
        if (m == NULL) {
            croak("cannot create Migemo object.");
        }
        sv = newSViv(PTR2IV(m));
        sv = newRV_noinc(sv);
        sv_bless(sv, gv_stashpv(SvPV_nolen(class), 1));
        RETVAL = sv;
    OUTPUT:
        RETVAL

SV *
load(self, dict_id, dict)
        SV *self;
        int dict_id;
        char *dict;
    PREINIT:
        migemo *m;
        int ret;
    CODE:
        m = INT2PTR(migemo *, SvIV(SvRV(self)));
        ret = migemo_load(m, dict_id, dict);
        if (ret == MIGEMO_DICTID_INVALID) {
            croak("cannot load dictionary file.");
        }
        RETVAL = newSViv(ret);
    OUTPUT:
        RETVAL

SV *
query(self, query)
        SV *self;
        unsigned char *query;
    PREINIT:
        migemo *m;
        unsigned char *ret;
        SV *sv;
    CODE:
        m = INT2PTR(migemo *, SvIV(SvRV(self)));
        ret = migemo_query(m, query);
        sv = newSVpv(ret, 0);
        migemo_release(m, ret);
        RETVAL = sv;
    OUTPUT:
        RETVAL

SV *
is_enable(self)
        SV *self;
    PREINIT:
        migemo *m;
        int ret;
    CODE:
        m = INT2PTR(migemo *, SvIV(SvRV(self)));
        ret = migemo_is_enable(m);
        RETVAL = newSViv(ret);
    OUTPUT:
        RETVAL

SV*
set_operator(self, index, op)
        SV *self;
        int index;
        unsigned char *op;
    PREINIT:
        migemo *m;
        int ret;
    CODE:
        m = INT2PTR(migemo *, SvIV(SvRV(self)));
        ret = migemo_set_operator(m, index, op);
        if (!ret) {
            croak("invalid arguments.");
        }
        RETVAL = newSViv(ret);
    OUTPUT:
        RETVAL

SV*
get_operator(self, index)
        SV *self;
        int index;
    PREINIT:
        migemo *m;
        const unsigned char *ret;
    CODE:
        m = INT2PTR(migemo *, SvIV(SvRV(self)));
        ret = migemo_get_operator(m, index);
        if (ret == NULL) {
            croak("invalid arguments.");
        }
        RETVAL = newSVpv(ret , 0);
    OUTPUT:
        RETVAL

void
DESTROY(self)
        SV *self;
    PREINIT:
        migemo *m;
    CODE:
        m = INT2PTR(migemo *, SvIV(SvRV(self)));
        migemo_close(m);

