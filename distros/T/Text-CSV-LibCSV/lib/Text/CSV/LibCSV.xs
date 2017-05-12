#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_newCONSTSUB
#define NEED_newRV_noinc
#define NEED_sv_2pv_nolen
#include "ppport.h"
#include "csv.h"

struct callback_data {
    AV *fields;
    SV *callback;
};

static void
field_callback(char *field, size_t len, void *data)
{
    struct callback_data *cb_data;
    cb_data = (struct callback_data *) data;
    av_push(cb_data->fields, newSVpv(field, len));
}

static void
row_callback(char c, void *data)
{
    struct callback_data *cb_data;
    I32 len;
    int i;
    SV **field;
    cb_data = (struct callback_data *) data;
    len = av_len(cb_data->fields);
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    for (i = 0; i <= len; i++) {
        field = av_fetch(cb_data->fields, i, 0);
        XPUSHs(*field);
    }
    PUTBACK;
    perl_call_sv(cb_data->callback, G_DISCARD);
    FREETMPS;
    LEAVE;
    av_clear(cb_data->fields);
}

static void
init_constants()
{
    HV *stash;
    stash = gv_stashpv("Text::CSV::LibCSV", 1);
    newCONSTSUB(stash, "CSV_STRICT",    newSViv(CSV_STRICT));
    newCONSTSUB(stash, "CSV_REPALL_NL", newSViv(CSV_REPALL_NL));
}

MODULE = Text::CSV::LibCSV		PACKAGE = Text::CSV::LibCSV

PROTOTYPES: ENABLE

BOOT:
    init_constants();

SV *
new(class, opts = 0)
        SV *class;
        int opts;
    PREINIT:
        struct csv_parser *parser;
        SV *self;
    CODE:
        if (csv_init(&parser, opts) != 0)
            croak("failed to initialize csv parser");
        self = newSViv(PTR2IV(parser));
        self = newRV_noinc(self);
        sv_bless(self, gv_stashpv(SvPV_nolen(class), 1));
        RETVAL = self;
    OUTPUT:
        RETVAL

SV *
xs_parse(self, sv_data, callback)
        SV *self;
        SV *sv_data;
        SV *callback;
    PREINIT:
        struct callback_data cb_data;
        struct csv_parser *parser;
        char *data;
        size_t len, ret;
    CODE:
        parser = INT2PTR(struct csv_parser *, SvIV(SvRV(self)));
        cb_data.fields = newAV();
        cb_data.callback = callback;
        data = SvPVX(sv_data);
        len = SvCUR(sv_data);
        ret = csv_parse(parser, data, len, field_callback, row_callback, &cb_data);
        (void) csv_fini(parser, field_callback, row_callback, &cb_data);
        RETVAL = newSViv(len == ret);
    OUTPUT:
        RETVAL

SV *
opts(self, opts)
        SV *self;
        int opts;
    PREINIT:
        struct csv_parser *parser;
    CODE:
        parser = INT2PTR(struct csv_parser *, SvIV(SvRV(self)));
        RETVAL = newSViv(csv_opts(parser, opts));
    OUTPUT:
        RETVAL

SV *
strerror(self)
        SV *self;
    PREINIT:
        struct csv_parser *parser;
    CODE:
        parser = INT2PTR(struct csv_parser *, SvIV(SvRV(self)));
        RETVAL = newSVpv(csv_strerror(csv_error(parser)), 0);
    OUTPUT:
        RETVAL

void
DESTROY(self)
        SV *self;
    PREINIT:
        struct csv_parser *parser;
    CODE:
        parser = INT2PTR(struct csv_parser *, SvIV(SvRV(self)));
        csv_free(parser);


