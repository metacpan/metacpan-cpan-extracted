#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <kdl/kdl.h>

#include <string.h>
#include <stdlib.h>

/* ------------------------------------------------------------------------- */
/* Wrapper structs                                                           */
/* ------------------------------------------------------------------------- */

typedef struct {
    kdl_parser* parser;
    SV*         read_cb;   /* Perl coderef, or NULL */
    SV*         keepalive; /* string SV holding the input buffer, or NULL */
} ptkx_parser;

typedef struct {
    kdl_emitter* emitter;
} ptkx_emitter;

/* ------------------------------------------------------------------------- */
/* Helpers: build a Text::KDL::XS::Value SV from a kdl_value                 */
/* ------------------------------------------------------------------------- */

static SV*
ptkx_make_value_sv(pTHX_ const kdl_value* v)
{
    HV* hv = newHV();

    /* type_annotation: string or undef */
    if (v->type_annotation.data != NULL) {
        SV* ann = newSVpvn(v->type_annotation.data, v->type_annotation.len);
        SvUTF8_on(ann);
        (void) hv_stores(hv, "type_annotation", ann);
    }
    else {
        (void) hv_stores(hv, "type_annotation", &PL_sv_undef);
    }

    switch (v->type) {
    case KDL_TYPE_NULL:
        (void) hv_stores(hv, "type", newSVpvs("null"));
        (void) hv_stores(hv, "value", &PL_sv_undef);
        break;
    case KDL_TYPE_BOOLEAN:
        (void) hv_stores(hv, "type", newSVpvs("bool"));
        (void) hv_stores(hv, "value", newSViv(v->boolean ? 1 : 0));
        break;
    case KDL_TYPE_STRING: {
        SV* sv = newSVpvn(v->string.data, v->string.len);
        SvUTF8_on(sv);
        (void) hv_stores(hv, "type", newSVpvs("string"));
        (void) hv_stores(hv, "value", sv);
        break;
    }
    case KDL_TYPE_NUMBER: {
        (void) hv_stores(hv, "type", newSVpvs("number"));
        switch (v->number.type) {
        case KDL_NUMBER_TYPE_INTEGER:
            (void) hv_stores(hv, "kind", newSVpvs("integer"));
            (void) hv_stores(hv, "value", newSViv((IV) v->number.integer));
            break;
        case KDL_NUMBER_TYPE_FLOATING_POINT:
            (void) hv_stores(hv, "kind", newSVpvs("float"));
            (void) hv_stores(hv, "value", newSVnv(v->number.floating_point));
            break;
        case KDL_NUMBER_TYPE_STRING_ENCODED: {
            SV* sv = newSVpvn(v->number.string.data, v->number.string.len);
            (void) hv_stores(hv, "kind", newSVpvs("string"));
            (void) hv_stores(hv, "value", sv);
            break;
        }
        }
        break;
    }
    }

    SV* rv = newRV_noinc((SV*) hv);
    HV* stash = gv_stashpv("Text::KDL::XS::Value", GV_ADD);
    sv_bless(rv, stash);
    return rv;
}

/* ------------------------------------------------------------------------- */
/* Stream-source trampoline: invoke a Perl coderef returning chunks          */
/* ------------------------------------------------------------------------- */

static size_t
ptkx_read_thunk(void* user_data, char* buf, size_t bufsize)
{
    dTHX;
    ptkx_parser* self = (ptkx_parser*) user_data;
    SV* cb = self->read_cb;
    if (!cb) return 0;

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVuv((UV) bufsize)));
    PUTBACK;

    int n = call_sv(cb, G_SCALAR | G_EVAL);

    SPAGAIN;
    size_t got = 0;
    if (SvTRUE(ERRSV)) {
        /* Swallow the error to a zero-byte read; the parser will treat it
         * as EOF. The original error is preserved on $@ for the caller. */
        (void) POPs;
    }
    else if (n >= 1) {
        SV* chunk = POPs;
        if (SvOK(chunk)) {
            STRLEN len;
            const char* data = SvPVbyte(chunk, len);
            if (len > bufsize) len = bufsize;
            if (len > 0) memcpy(buf, data, len);
            got = len;
        }
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
    return got;
}

/* ------------------------------------------------------------------------- */
/* Parser construction helper                                                */
/* ------------------------------------------------------------------------- */

static SV*
ptkx_bless_parser(pTHX_ ptkx_parser* p)
{
    SV* obj = newSV(0);
    HV* stash = gv_stashpv("Text::KDL::XS::Parser", GV_ADD);
    sv_setref_pv(obj, "Text::KDL::XS::Parser", (void*) p);
    (void) stash;
    return obj;
}

/* ------------------------------------------------------------------------- */
/* XS bindings                                                               */
/* ------------------------------------------------------------------------- */

MODULE = Text::KDL::XS    PACKAGE = Text::KDL::XS

PROTOTYPES: DISABLE

BOOT:
    /* Export option constants as package globals for Perl to consume. */
    HV* opt_stash = gv_stashpv("Text::KDL::XS", GV_ADD);
    (void) opt_stash;

# --- Constants -------------------------------------------------------------

int
_OPT_DETECT()
    CODE:
        RETVAL = (int) KDL_DETECT_VERSION;
    OUTPUT:
        RETVAL

int
_OPT_V1()
    CODE:
        RETVAL = (int) KDL_READ_VERSION_1;
    OUTPUT:
        RETVAL

int
_OPT_V2()
    CODE:
        RETVAL = (int) KDL_READ_VERSION_2;
    OUTPUT:
        RETVAL

int
_OPT_EMIT_COMMENTS()
    CODE:
        RETVAL = (int) KDL_EMIT_COMMENTS;
    OUTPUT:
        RETVAL


MODULE = Text::KDL::XS    PACKAGE = Text::KDL::XS::Parser

# --- Parser construction ---------------------------------------------------

SV*
_new_string_parser(klass, doc_sv, opts)
        SV* klass
        SV* doc_sv
        int opts
    PREINIT:
        STRLEN len;
        const char* data;
        ptkx_parser* p;
        kdl_str doc;
    CODE:
        (void) klass;
        if (!SvOK(doc_sv))
            croak("Text::KDL::XS::Parser: document must be a defined string");
        data = SvPVbyte(doc_sv, len);

        Newxz(p, 1, ptkx_parser);
        /* Keep a reference to the input SV alive - ckdl's string parser
         * holds onto the buffer until kdl_destroy_parser. */
        p->keepalive = newSVsv(doc_sv);
        SvPV_force_nomg(p->keepalive, len);
        data = SvPVbyte_nolen(p->keepalive);
        len  = SvCUR(p->keepalive);

        doc.data = data;
        doc.len  = len;
        p->parser = kdl_create_string_parser(doc, (kdl_parse_option) opts);
        if (!p->parser) {
            SvREFCNT_dec(p->keepalive);
            Safefree(p);
            croak("kdl_create_string_parser failed");
        }
        RETVAL = sv_newmortal();
        sv_setref_pv(RETVAL, "Text::KDL::XS::Parser", (void*) p);
        SvREFCNT_inc(RETVAL);
    OUTPUT:
        RETVAL

SV*
_new_stream_parser(klass, cb_sv, opts)
        SV* klass
        SV* cb_sv
        int opts
    PREINIT:
        ptkx_parser* p;
    CODE:
        (void) klass;
        if (!SvROK(cb_sv) || SvTYPE(SvRV(cb_sv)) != SVt_PVCV)
            croak("Text::KDL::XS::Parser: stream source must be a CODE ref");

        Newxz(p, 1, ptkx_parser);
        p->read_cb = newSVsv(cb_sv);
        p->parser = kdl_create_stream_parser(ptkx_read_thunk, (void*) p,
                                             (kdl_parse_option) opts);
        if (!p->parser) {
            SvREFCNT_dec(p->read_cb);
            Safefree(p);
            croak("kdl_create_stream_parser failed");
        }
        RETVAL = sv_newmortal();
        sv_setref_pv(RETVAL, "Text::KDL::XS::Parser", (void*) p);
        SvREFCNT_inc(RETVAL);
    OUTPUT:
        RETVAL

# --- Parser events ---------------------------------------------------------

SV*
_next_event(self_sv)
        SV* self_sv
    PREINIT:
        ptkx_parser* p;
        kdl_event_data* ev;
        int real_event;
        int commented;
    CODE:
        if (!sv_isa(self_sv, "Text::KDL::XS::Parser"))
            croak("not a Text::KDL::XS::Parser");
        p = INT2PTR(ptkx_parser*, SvIV(SvRV(self_sv)));

        ev = kdl_parser_next_event(p->parser);
        if (!ev) croak("kdl_parser_next_event returned NULL");

        if (ev->event == KDL_EVENT_EOF) {
            RETVAL = &PL_sv_undef;
        }
        else if (ev->event == KDL_EVENT_PARSE_ERROR) {
            croak("KDL parse error");
        }
        else {
            HV* h = newHV();
            real_event = (int)(ev->event & ~KDL_EVENT_COMMENT);
            commented  = (ev->event & KDL_EVENT_COMMENT) ? 1 : 0;

            const char* name;
            switch (real_event) {
                case KDL_EVENT_START_NODE: name = "start_node"; break;
                case KDL_EVENT_END_NODE:   name = "end_node";   break;
                case KDL_EVENT_ARGUMENT:   name = "argument";   break;
                case KDL_EVENT_PROPERTY:   name = "property";   break;
                case 0:                    name = "comment";    break;
                default:                   name = "unknown";    break;
            }
            (void) hv_stores(h, "event", newSVpv(name, 0));
            (void) hv_stores(h, "commented", newSViv(commented));

            if (ev->name.data != NULL) {
                SV* nm = newSVpvn(ev->name.data, ev->name.len);
                SvUTF8_on(nm);
                (void) hv_stores(h, "name", nm);
            }

            if (real_event == KDL_EVENT_START_NODE) {
                /* type annotation lives on the value for nodes */
                if (ev->value.type_annotation.data != NULL) {
                    SV* ann = newSVpvn(ev->value.type_annotation.data,
                                       ev->value.type_annotation.len);
                    SvUTF8_on(ann);
                    (void) hv_stores(h, "type", ann);
                }
            }
            else if (real_event == KDL_EVENT_ARGUMENT
                     || real_event == KDL_EVENT_PROPERTY) {
                (void) hv_stores(h, "value",
                                 ptkx_make_value_sv(aTHX_ &ev->value));
            }

            RETVAL = newRV_noinc((SV*) h);
        }
    OUTPUT:
        RETVAL

void
DESTROY(self_sv)
        SV* self_sv
    PREINIT:
        ptkx_parser* p;
    CODE:
        if (!sv_isa(self_sv, "Text::KDL::XS::Parser")) return;
        p = INT2PTR(ptkx_parser*, SvIV(SvRV(self_sv)));
        if (!p) return;
        if (p->parser)    kdl_destroy_parser(p->parser);
        if (p->read_cb)   SvREFCNT_dec(p->read_cb);
        if (p->keepalive) SvREFCNT_dec(p->keepalive);
        Safefree(p);


MODULE = Text::KDL::XS    PACKAGE = Text::KDL::XS::Emitter

# --- Emitter ---------------------------------------------------------------

SV*
_new(klass, version_int, indent, escape_mode, identifier_mode)
        SV* klass
        int version_int
        int indent
        int escape_mode
        int identifier_mode
    PREINIT:
        ptkx_emitter* e;
        kdl_emitter_options opts;
    CODE:
        (void) klass;
        opts = KDL_DEFAULT_EMITTER_OPTIONS;
        if (version_int == 1) opts.version = KDL_VERSION_1;
        else if (version_int == 2) opts.version = KDL_VERSION_2;
        if (indent >= 0) opts.indent = indent;
        if (escape_mode >= 0) opts.escape_mode = (kdl_escape_mode) escape_mode;
        if (identifier_mode >= 0)
            opts.identifier_mode = (kdl_identifier_emission_mode) identifier_mode;

        Newxz(e, 1, ptkx_emitter);
        e->emitter = kdl_create_buffering_emitter(&opts);
        if (!e->emitter) {
            Safefree(e);
            croak("kdl_create_buffering_emitter failed");
        }
        RETVAL = sv_newmortal();
        sv_setref_pv(RETVAL, "Text::KDL::XS::Emitter", (void*) e);
        SvREFCNT_inc(RETVAL);
    OUTPUT:
        RETVAL

bool
_emit_node(self_sv, name_sv, type_sv)
        SV* self_sv
        SV* name_sv
        SV* type_sv
    PREINIT:
        ptkx_emitter* e;
        kdl_str name;
        kdl_str type;
        STRLEN len;
        const char* data;
    CODE:
        if (!sv_isa(self_sv, "Text::KDL::XS::Emitter"))
            croak("not a Text::KDL::XS::Emitter");
        e = INT2PTR(ptkx_emitter*, SvIV(SvRV(self_sv)));

        data = SvPVutf8(name_sv, len);
        name.data = data; name.len = len;

        if (SvOK(type_sv)) {
            data = SvPVutf8(type_sv, len);
            type.data = data; type.len = len;
            RETVAL = kdl_emit_node_with_type(e->emitter, type, name);
        }
        else {
            RETVAL = kdl_emit_node(e->emitter, name);
        }
    OUTPUT:
        RETVAL

bool
_emit_arg(self_sv, value_hv_ref)
        SV* self_sv
        SV* value_hv_ref
    PREINIT:
        ptkx_emitter* e;
        kdl_value v;
    CODE:
        if (!sv_isa(self_sv, "Text::KDL::XS::Emitter"))
            croak("not a Text::KDL::XS::Emitter");
        e = INT2PTR(ptkx_emitter*, SvIV(SvRV(self_sv)));

        /* Caller has already populated kdl_value-ish hash with C-friendly
         * values. We translate here to keep the hot path tight. */
        if (!SvROK(value_hv_ref) || SvTYPE(SvRV(value_hv_ref)) != SVt_PVHV)
            croak("emit_arg: expected HASH ref");

        memset(&v, 0, sizeof(v));
        HV* hv = (HV*) SvRV(value_hv_ref);

        SV** sv_type = hv_fetchs(hv, "type", 0);
        SV** sv_ann  = hv_fetchs(hv, "type_annotation", 0);
        SV** sv_val  = hv_fetchs(hv, "value", 0);
        SV** sv_kind = hv_fetchs(hv, "kind", 0);

        STRLEN slen = 0;
        const char* sdata;

        if (sv_ann && *sv_ann && SvOK(*sv_ann)) {
            sdata = SvPVutf8(*sv_ann, slen);
            v.type_annotation.data = sdata;
            v.type_annotation.len  = slen;
        }

        if (!sv_type || !*sv_type) croak("emit_arg: missing 'type'");
        const char* type_str = SvPV_nolen(*sv_type);

        if (strEQ(type_str, "null")) {
            v.type = KDL_TYPE_NULL;
        }
        else if (strEQ(type_str, "bool")) {
            v.type = KDL_TYPE_BOOLEAN;
            v.boolean = (sv_val && SvTRUE(*sv_val));
        }
        else if (strEQ(type_str, "string")) {
            v.type = KDL_TYPE_STRING;
            sdata = SvPVutf8(*sv_val, slen);
            v.string.data = sdata; v.string.len = slen;
        }
        else if (strEQ(type_str, "number")) {
            v.type = KDL_TYPE_NUMBER;
            const char* kind = sv_kind && *sv_kind ? SvPV_nolen(*sv_kind)
                                                   : "integer";
            if (strEQ(kind, "integer")) {
                v.number.type    = KDL_NUMBER_TYPE_INTEGER;
                v.number.integer = (long long) SvIV(*sv_val);
            }
            else if (strEQ(kind, "float")) {
                v.number.type           = KDL_NUMBER_TYPE_FLOATING_POINT;
                v.number.floating_point = SvNV(*sv_val);
            }
            else {
                v.number.type        = KDL_NUMBER_TYPE_STRING_ENCODED;
                sdata = SvPVbyte(*sv_val, slen);
                v.number.string.data = sdata;
                v.number.string.len  = slen;
            }
        }
        else {
            croak("emit_arg: unknown value type '%s'", type_str);
        }

        RETVAL = kdl_emit_arg(e->emitter, &v);
    OUTPUT:
        RETVAL

bool
_emit_property(self_sv, key_sv, value_hv_ref)
        SV* self_sv
        SV* key_sv
        SV* value_hv_ref
    PREINIT:
        ptkx_emitter* e;
        kdl_value v;
        kdl_str key;
        STRLEN slen = 0;
        const char* sdata;
    CODE:
        if (!sv_isa(self_sv, "Text::KDL::XS::Emitter"))
            croak("not a Text::KDL::XS::Emitter");
        e = INT2PTR(ptkx_emitter*, SvIV(SvRV(self_sv)));

        sdata = SvPVutf8(key_sv, slen);
        key.data = sdata; key.len = slen;

        if (!SvROK(value_hv_ref) || SvTYPE(SvRV(value_hv_ref)) != SVt_PVHV)
            croak("emit_property: expected HASH ref");

        memset(&v, 0, sizeof(v));
        HV* hv = (HV*) SvRV(value_hv_ref);

        SV** sv_type = hv_fetchs(hv, "type", 0);
        SV** sv_ann  = hv_fetchs(hv, "type_annotation", 0);
        SV** sv_val  = hv_fetchs(hv, "value", 0);
        SV** sv_kind = hv_fetchs(hv, "kind", 0);

        if (sv_ann && *sv_ann && SvOK(*sv_ann)) {
            sdata = SvPVutf8(*sv_ann, slen);
            v.type_annotation.data = sdata;
            v.type_annotation.len  = slen;
        }

        if (!sv_type || !*sv_type) croak("emit_property: missing 'type'");
        const char* type_str = SvPV_nolen(*sv_type);

        if (strEQ(type_str, "null")) {
            v.type = KDL_TYPE_NULL;
        }
        else if (strEQ(type_str, "bool")) {
            v.type = KDL_TYPE_BOOLEAN;
            v.boolean = (sv_val && SvTRUE(*sv_val));
        }
        else if (strEQ(type_str, "string")) {
            v.type = KDL_TYPE_STRING;
            sdata = SvPVutf8(*sv_val, slen);
            v.string.data = sdata; v.string.len = slen;
        }
        else if (strEQ(type_str, "number")) {
            v.type = KDL_TYPE_NUMBER;
            const char* kind = sv_kind && *sv_kind ? SvPV_nolen(*sv_kind)
                                                   : "integer";
            if (strEQ(kind, "integer")) {
                v.number.type    = KDL_NUMBER_TYPE_INTEGER;
                v.number.integer = (long long) SvIV(*sv_val);
            }
            else if (strEQ(kind, "float")) {
                v.number.type           = KDL_NUMBER_TYPE_FLOATING_POINT;
                v.number.floating_point = SvNV(*sv_val);
            }
            else {
                v.number.type        = KDL_NUMBER_TYPE_STRING_ENCODED;
                sdata = SvPVbyte(*sv_val, slen);
                v.number.string.data = sdata;
                v.number.string.len  = slen;
            }
        }
        else {
            croak("emit_property: unknown value type '%s'", type_str);
        }

        RETVAL = kdl_emit_property(e->emitter, key, &v);
    OUTPUT:
        RETVAL

bool
_start_children(self_sv)
        SV* self_sv
    PREINIT:
        ptkx_emitter* e;
    CODE:
        if (!sv_isa(self_sv, "Text::KDL::XS::Emitter"))
            croak("not a Text::KDL::XS::Emitter");
        e = INT2PTR(ptkx_emitter*, SvIV(SvRV(self_sv)));
        RETVAL = kdl_start_emitting_children(e->emitter);
    OUTPUT:
        RETVAL

bool
_finish_children(self_sv)
        SV* self_sv
    PREINIT:
        ptkx_emitter* e;
    CODE:
        if (!sv_isa(self_sv, "Text::KDL::XS::Emitter"))
            croak("not a Text::KDL::XS::Emitter");
        e = INT2PTR(ptkx_emitter*, SvIV(SvRV(self_sv)));
        RETVAL = kdl_finish_emitting_children(e->emitter);
    OUTPUT:
        RETVAL

bool
_emit_end(self_sv)
        SV* self_sv
    PREINIT:
        ptkx_emitter* e;
    CODE:
        if (!sv_isa(self_sv, "Text::KDL::XS::Emitter"))
            croak("not a Text::KDL::XS::Emitter");
        e = INT2PTR(ptkx_emitter*, SvIV(SvRV(self_sv)));
        RETVAL = kdl_emit_end(e->emitter);
    OUTPUT:
        RETVAL

SV*
_get_buffer(self_sv)
        SV* self_sv
    PREINIT:
        ptkx_emitter* e;
        kdl_str buf;
    CODE:
        if (!sv_isa(self_sv, "Text::KDL::XS::Emitter"))
            croak("not a Text::KDL::XS::Emitter");
        e = INT2PTR(ptkx_emitter*, SvIV(SvRV(self_sv)));
        buf = kdl_get_emitter_buffer(e->emitter);
        RETVAL = newSVpvn(buf.data ? buf.data : "", buf.len);
        SvUTF8_on(RETVAL);
    OUTPUT:
        RETVAL

void
DESTROY(self_sv)
        SV* self_sv
    PREINIT:
        ptkx_emitter* e;
    CODE:
        if (!sv_isa(self_sv, "Text::KDL::XS::Emitter")) return;
        e = INT2PTR(ptkx_emitter*, SvIV(SvRV(self_sv)));
        if (!e) return;
        if (e->emitter) kdl_destroy_emitter(e->emitter);
        Safefree(e);
