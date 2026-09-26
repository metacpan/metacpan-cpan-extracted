#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <kdl/kdl.h>

#include <stdlib.h>
#include <string.h>

#if IVSIZE < 8
#  error "Text::KDL::XS needs a perl with 64-bit integers (ivsize >= 8)"
#endif

#define PTKX_PARSER_CLASS   "Text::KDL::XS::Parser"
#define PTKX_EMITTER_CLASS  "Text::KDL::XS::Emitter"
#define PTKX_VALUE_CLASS    "Text::KDL::XS::Value"

/* Room for any number this module formats: "%.17g" of a double plus ".0". */
#define PTKX_NUMBER_BUFSIZE 64

#define PTKX_MAX_INDENT     64

#define PTKX_V1_NON_FINITE  "emit_kdl: KDL v1 has no representation for inf/nan"

/* Keeps the object behind the reference self alive until the caller's next
 * FREETMPS, for XSUBs that run Perl code (source callbacks, overloaded
 * operators) while they hold the object's C handle. */
#define PTKX_KEEP_ALIVE(self) sv_2mortal(SvREFCNT_inc_simple_NN(SvRV(self)))

/* KDL numbers always use '.' as the radix, so they are formatted and read
 * back with LC_NUMERIC in the C locale whatever the program's locale is. */
#if defined(STORE_LC_NUMERIC_SET_STANDARD)
#  define PTKX_DECLARE_NUMERIC_STATE  DECLARATION_FOR_LC_NUMERIC_MANIPULATION
#  define PTKX_NUMERIC_STANDARD()     STORE_LC_NUMERIC_SET_STANDARD()
#  define PTKX_NUMERIC_RESTORE()      RESTORE_LC_NUMERIC()
#elif defined(STORE_LC_NUMERIC_SET_TO_NEEDED)
#  define PTKX_DECLARE_NUMERIC_STATE  DECLARATION_FOR_LC_NUMERIC_MANIPULATION
#  define PTKX_NUMERIC_STANDARD()     STORE_LC_NUMERIC_SET_TO_NEEDED()
#  define PTKX_NUMERIC_RESTORE()      RESTORE_LC_NUMERIC()
#else
#  define PTKX_DECLARE_NUMERIC_STATE  dNOOP
#  define PTKX_NUMERIC_STANDARD()     NOOP
#  define PTKX_NUMERIC_RESTORE()      NOOP
#endif

/* ------------------------------------------------------------------------- */
/* Types                                                                     */
/* ------------------------------------------------------------------------- */

typedef enum {
    PTKX_ACTIVE,    /* events can be read */
    PTKX_FINISHED,  /* end of input reached: every further call returns undef */
    PTKX_FAILED     /* an error occurred: every further call raises it again */
} ptkx_parser_state;

/* Progress of the UTF-8 validator through a multi-byte sequence. */
typedef struct {
    U8 continuation_bytes;  /* continuation bytes still expected */
    UV code_point;          /* bits collected so far */
    UV minimum;             /* smallest code point this sequence length may encode */
} ptkx_utf8_state;

typedef struct {
    kdl_parser*       parser;           /* NULL once finished or failed */
    HV*               value_stash;      /* Text::KDL::XS::Value, for parsed values */
    SV*               read_cb;          /* source callback, or NULL */
    SV*               source_copy;      /* private copy of a string source; ckdl reads its buffer */
    SV*               pending_chunk;    /* callback bytes not yet handed to ckdl */
    STRLEN            pending_offset;   /* bytes of pending_chunk already handed over */
    SV*               error;            /* exception to raise, or NULL */
    ptkx_parser_state state;
    bool              in_callback;      /* the source callback is running */
    bool              source_exhausted; /* the source callback signalled end of input */
    ptkx_utf8_state   utf8;             /* validation of callback bytes across chunks */
    IV                depth;            /* nodes currently open */
    IV                max_depth;        /* deepest nesting allowed, 0 for unlimited */
} ptkx_parser;

typedef struct {
    kdl_emitter* emitter;
    kdl_version  version;               /* syntax of the output */
    bool         writes_bare;           /* identifiers may be written without quotes */
    bool         needs_quoting;         /* some bare text would read back as a keyword or number */
} ptkx_emitter;

typedef enum {
    PTKX_NOT_A_NUMBER,
    PTKX_INTEGER,
    PTKX_FLOAT
} ptkx_number_kind;

/* ------------------------------------------------------------------------- */
/* Scalars                                                                   */
/* ------------------------------------------------------------------------- */

/* sv itself, or a mortal copy when sv has get-magic, so that a tied or
 * otherwise magical value is fetched exactly once. */
static SV*
ptkx_plain(pTHX_ SV* sv)
{
    return SvGMAGICAL(sv) ? sv_mortalcopy(sv) : sv;
}

/* Drops the reference held in *slot and clears the slot first, so that code
 * run by a destructor never sees a dangling pointer. */
static void
ptkx_clear_sv(pTHX_ SV** slot)
{
    SV* sv = *slot;
    *slot = NULL;
    SvREFCNT_dec(sv);
}

/* ------------------------------------------------------------------------- */
/* UTF-8                                                                     */
/* ------------------------------------------------------------------------- */

static bool
ptkx_is_unicode_scalar(UV code_point, UV minimum)
{
    return code_point >= minimum
        && code_point <= 0x10FFFF
        && (code_point < 0xD800 || code_point > 0xDFFF);
}

static void
ptkx_utf8_begin(ptkx_utf8_state* state, U8 continuation_bytes, UV lead_bits, UV minimum)
{
    state->continuation_bytes = continuation_bytes;
    state->code_point         = lead_bits;
    state->minimum            = minimum;
}

/* Feeds bytes to an incremental validator. Returns FALSE at the first byte
 * that makes the input anything but RFC 3629 UTF-8: a malformed or overlong
 * sequence, a surrogate or a code point above U+10FFFF. A sequence may be
 * split across calls; state->continuation_bytes is non-zero while one is
 * incomplete. */
static bool
ptkx_utf8_feed(ptkx_utf8_state* state, const U8* bytes, STRLEN len)
{
    const U8* end = bytes + len;

    for (; bytes < end; ++bytes) {
        U8 byte = *bytes;

        if (state->continuation_bytes > 0) {
            if ((byte & 0xC0) != 0x80) return FALSE;
            state->code_point = (state->code_point << 6) | (byte & 0x3F);
            if (--state->continuation_bytes == 0
                && !ptkx_is_unicode_scalar(state->code_point, state->minimum))
                return FALSE;
            continue;
        }
        if (byte < 0x80) continue;

        if ((byte & 0xE0) == 0xC0)      ptkx_utf8_begin(state, 1, byte & 0x1F, 0x80);
        else if ((byte & 0xF0) == 0xE0) ptkx_utf8_begin(state, 2, byte & 0x0F, 0x800);
        else if ((byte & 0xF8) == 0xF0) ptkx_utf8_begin(state, 3, byte & 0x07, 0x10000);
        else return FALSE;
    }
    return TRUE;
}

/* True if text[0..len) is complete RFC 3629 UTF-8 (see ptkx_utf8_feed). */
static bool
ptkx_is_unicode_utf8(const char* text, STRLEN len)
{
    ptkx_utf8_state state = { 0, 0, 0 };
    return ptkx_utf8_feed(&state, (const U8*) text, len)
        && state.continuation_bytes == 0;
}

/* True for a missing string (NULL data) and for valid Unicode text. */
static bool
ptkx_is_text(kdl_str text)
{
    return text.data == NULL || ptkx_is_unicode_utf8(text.data, text.len);
}

static bool
ptkx_is_ascii(const char* text, STRLEN len)
{
    const char* end = text + len;
    for (; text < end; ++text)
        if ((U8) *text >= 0x80) return FALSE;
    return TRUE;
}

/* ------------------------------------------------------------------------- */
/* Numbers                                                                   */
/* ------------------------------------------------------------------------- */

static STRLEN
ptkx_copy_text(char* buf, const char* text)
{
    STRLEN len = strlen(text);
    Copy(text, buf, len + 1, char);
    return len;
}

/* Writes d as a KDL number into buf (PTKX_NUMBER_BUFSIZE bytes): the
 * shortest of %.15g, %.16g and %.17g that strtod() reads back as d, with
 * ".0" appended when the text would otherwise read back as an integer;
 * #inf, #-inf or #nan when d is not finite. Returns the length. */
static STRLEN
ptkx_format_double(pTHX_ double d, char* buf)
{
    STRLEN len = 0;
    int precision;
    PTKX_DECLARE_NUMERIC_STATE;
    PERL_UNUSED_CONTEXT;

    if (Perl_isnan(d)) return ptkx_copy_text(buf, "#nan");
    if (Perl_isinf(d)) return ptkx_copy_text(buf, d < 0 ? "#-inf" : "#inf");

    PTKX_NUMERIC_STANDARD();
    for (precision = 15; precision <= 17; ++precision) {
        len = (STRLEN) my_snprintf(buf, PTKX_NUMBER_BUFSIZE, "%.*g", precision, d);
        if (strtod(buf, NULL) == d) break;
    }
    PTKX_NUMERIC_RESTORE();

    if (!strpbrk(buf, ".e")) len += ptkx_copy_text(buf + len, ".0");
    return len;
}

/* ckdl reports a floating point number only for literals with at most 15
 * significant digits, but computes it as mantissa / pow(10, k), which can be
 * an ulp off. Reading the 15-digit rendering back with strtod() restores the
 * correctly rounded value of the literal. */
static double
ptkx_correctly_rounded(pTHX_ double d)
{
    char buf[PTKX_NUMBER_BUFSIZE];
    double rounded;
    PTKX_DECLARE_NUMERIC_STATE;
    PERL_UNUSED_CONTEXT;

    if (Perl_isnan(d) || Perl_isinf(d)) return d;

    PTKX_NUMERIC_STANDARD();
    my_snprintf(buf, sizeof buf, "%.15g", d);
    rounded = strtod(buf, NULL);
    PTKX_NUMERIC_RESTORE();
    return rounded;
}

static bool
ptkx_is_digit(char c, int radix)
{
    switch (radix) {
    case 2:  return c == '0' || c == '1';
    case 8:  return c >= '0' && c <= '7';
    case 10: return isDIGIT(c);
    default: return isXDIGIT(c);
    }
}

/* Advances *p over a digit of the given radix followed by digits and '_'
 * separators. Returns FALSE when *p does not start with a digit. */
static bool
ptkx_skip_digits(const char** p, const char* end, int radix)
{
    if (*p == end || !ptkx_is_digit(**p, radix)) return FALSE;
    for (++*p; *p < end && (**p == '_' || ptkx_is_digit(**p, radix)); ++*p)
        ;
    return TRUE;
}

static bool
ptkx_is_keyword_number(const char* text, STRLEN len)
{
    return memEQs(text, len, "#inf")
        || memEQs(text, len, "#-inf")
        || memEQs(text, len, "#nan");
}

/* True if text is a KDL number literal: an optional sign followed by 0x, 0o
 * or 0b digits or by a decimal with optional fraction and exponent, digits
 * separated by '_' after the first; or one of #inf, #-inf and #nan. */
static bool
ptkx_is_number_literal(const char* text, STRLEN len)
{
    const char* p   = text;
    const char* end = text + len;

    if (ptkx_is_keyword_number(text, len)) return TRUE;

    if (p < end && (*p == '+' || *p == '-')) ++p;
    if (end - p > 2 && p[0] == '0' && (p[1] == 'x' || p[1] == 'o' || p[1] == 'b')) {
        int radix = p[1] == 'x' ? 16 : p[1] == 'o' ? 8 : 2;
        p += 2;
        return ptkx_skip_digits(&p, end, radix) && p == end;
    }

    if (!ptkx_skip_digits(&p, end, 10)) return FALSE;
    if (p < end && *p == '.') {
        ++p;
        if (!ptkx_skip_digits(&p, end, 10)) return FALSE;
    }
    if (p < end && (*p == 'e' || *p == 'E')) {
        ++p;
        if (p < end && (*p == '+' || *p == '-')) ++p;
        if (!ptkx_skip_digits(&p, end, 10)) return FALSE;
    }
    return p == end;
}

/* True if text is an optional sign followed by decimal digits only. */
static bool
ptkx_is_decimal_integer(const char* text, STRLEN len)
{
    const char* end = text + len;
    if (text < end && (*text == '+' || *text == '-')) ++text;
    if (text == end) return FALSE;
    for (; text < end; ++text)
        if (!isDIGIT(*text)) return FALSE;
    return TRUE;
}

/* Writes the integer held by sv as decimal digits into buf
 * (PTKX_NUMBER_BUFSIZE bytes): the IV or UV of an integer scalar, or the
 * value of a string of decimal digits with an optional sign that lies in
 * the native range IV_MIN .. UV_MAX. Returns FALSE for anything else.
 * sv must not have get-magic. */
static bool
ptkx_format_integer(pTHX_ SV* sv, char* buf, STRLEN* len)
{
    const char* text;
    STRLEN text_len;
    UV magnitude;
    int flags;
    bool negative;

    if (SvIOK(sv)) {
        *len = SvIsUV(sv)
            ? (STRLEN) my_snprintf(buf, PTKX_NUMBER_BUFSIZE, "%" UVuf, SvUVX(sv))
            : (STRLEN) my_snprintf(buf, PTKX_NUMBER_BUFSIZE, "%" IVdf, SvIVX(sv));
        return TRUE;
    }

    text = SvPV_nomg(sv, text_len);
    if (!ptkx_is_decimal_integer(text, text_len)) return FALSE;

    flags = grok_number(text, text_len, &magnitude);
    if ((flags & ~IS_NUMBER_NEG) != IS_NUMBER_IN_UV) return FALSE;
    negative = (flags & IS_NUMBER_NEG) && magnitude > 0;
    if (negative && magnitude > (UV) IV_MAX + 1) return FALSE;

    *len = (STRLEN) my_snprintf(buf, PTKX_NUMBER_BUFSIZE,
                                negative ? "-%" UVuf : "%" UVuf, magnitude);
    return TRUE;
}

/* True if the string value of sv (POK) is exactly Perl's own rendering of
 * its numeric value (IOK or NOK). */
static bool
ptkx_has_canonical_number_text(pTHX_ SV* sv)
{
    char buf[PTKX_NUMBER_BUFSIZE];
    const char* canonical = buf;
    STRLEN canonical_len;

    if (SvIOK(sv)) {
        canonical_len = SvIsUV(sv)
            ? (STRLEN) my_snprintf(buf, sizeof buf, "%" UVuf, SvUVX(sv))
            : (STRLEN) my_snprintf(buf, sizeof buf, "%" IVdf, SvIVX(sv));
    }
    else {
        SV* rendering = sv_2mortal(newSVnv(SvNVX(sv)));
        canonical = SvPV(rendering, canonical_len);
    }
    return canonical_len == SvCUR(sv) && memEQ(canonical, SvPVX_const(sv), canonical_len);
}

/* How a plain scalar is written by data mode: a number when it has a
 * numeric value and its string value, if any, is exactly Perl's rendering
 * of that number; otherwise a string. So "42" used in arithmetic is the
 * integer 42, while "007", "1.50" and dualvars stay strings. sv must not
 * have get-magic. */
static ptkx_number_kind
ptkx_scalar_number_kind(pTHX_ SV* sv)
{
    if (!SvIOK(sv) && !SvNOK(sv)) return PTKX_NOT_A_NUMBER;
    if (SvPOK(sv) && !ptkx_has_canonical_number_text(aTHX_ sv)) return PTKX_NOT_A_NUMBER;
    return SvIOK(sv) ? PTKX_INTEGER : PTKX_FLOAT;
}

/* ------------------------------------------------------------------------- */
/* Object handles: the C struct hangs off the referent as ext magic and is   */
/* freed with it. Forged or reblessed scalars have no such magic.            */
/* ------------------------------------------------------------------------- */

static void ptkx_parser_free(pTHX_ ptkx_parser* p);

static int
ptkx_parser_mg_free(pTHX_ SV* sv, MAGIC* mg)
{
    PERL_UNUSED_ARG(sv);
    if (mg->mg_ptr) ptkx_parser_free(aTHX_ (ptkx_parser*) mg->mg_ptr);
    mg->mg_ptr = NULL;
    return 0;
}

static int
ptkx_emitter_mg_free(pTHX_ SV* sv, MAGIC* mg)
{
    ptkx_emitter* e = (ptkx_emitter*) mg->mg_ptr;
    PERL_UNUSED_CONTEXT;
    PERL_UNUSED_ARG(sv);
    if (e) {
        kdl_destroy_emitter(e->emitter);
        Safefree(e);
    }
    mg->mg_ptr = NULL;
    return 0;
}

static MGVTBL ptkx_parser_vtbl  = { NULL, NULL, NULL, NULL, ptkx_parser_mg_free,  NULL, NULL, NULL };
static MGVTBL ptkx_emitter_vtbl = { NULL, NULL, NULL, NULL, ptkx_emitter_mg_free, NULL, NULL, NULL };

/* The stash of klass, a class name or object that must be class_name or a
 * subclass of it. */
static HV*
ptkx_class_stash(pTHX_ SV* klass, const char* class_name)
{
    if (!SvOK(klass) || !sv_derived_from(klass, class_name))
        croak("%s: '%" SVf "' is not %s or a subclass of it",
              class_name, SVfARG(klass), class_name);
    return SvROK(klass) ? SvSTASH(SvRV(klass)) : gv_stashsv(klass, GV_ADD);
}

/* A new object blessed into stash whose referent carries handle as ext
 * magic with the given vtable. */
static SV*
ptkx_wrap(pTHX_ HV* stash, void* handle, MGVTBL* vtbl)
{
    SV* body   = newSV(0);
    SV* object = newRV_noinc(body);
    sv_magicext(body, NULL, PERL_MAGIC_ext, vtbl, (const char*) handle, 0);
    return sv_bless(object, stash);
}

/* The C handle of an object made by ptkx_wrap with vtbl. */
static void*
ptkx_unwrap(pTHX_ SV* object, MGVTBL* vtbl, const char* class_name)
{
    MAGIC* mg;
    SvGETMAGIC(object);
    mg = SvROK(object) ? mg_findext(SvRV(object), PERL_MAGIC_ext, vtbl) : NULL;
    if (!mg || !mg->mg_ptr) croak("not a valid %s object", class_name);
    return mg->mg_ptr;
}

/* ------------------------------------------------------------------------- */
/* Parser lifecycle                                                          */
/* ------------------------------------------------------------------------- */

static void
ptkx_check_parse_options(pTHX_ IV options, IV max_depth)
{
    IV version = options & (IV) KDL_DETECT_VERSION;

    if ((options & ~(IV) (KDL_DETECT_VERSION | KDL_EMIT_COMMENTS)) != 0
        || (version != (IV) KDL_READ_VERSION_1
            && version != (IV) KDL_READ_VERSION_2
            && version != (IV) KDL_DETECT_VERSION))
        croak(PTKX_PARSER_CLASS ": invalid parse options 0x%" UVxf, (UV) options);
    if (max_depth < 0)
        croak(PTKX_PARSER_CLASS ": max_depth must be a non-negative integer");
}

static ptkx_parser*
ptkx_parser_new(pTHX_ IV max_depth)
{
    ptkx_parser* p;
    Newxz(p, 1, ptkx_parser);
    p->value_stash = (HV*) SvREFCNT_inc_simple_NN((SV*) gv_stashpvs(PTKX_VALUE_CLASS, GV_ADD));
    p->max_depth   = max_depth;
    p->state       = PTKX_ACTIVE;
    return p;
}

/* Frees what a finished or failed parser no longer needs: the ckdl parser,
 * the source and any pending input. The recorded error stays. Never called
 * while ckdl is running. */
static void
ptkx_parser_release(pTHX_ ptkx_parser* p)
{
    if (p->parser) {
        kdl_parser* parser = p->parser;
        p->parser = NULL;
        kdl_destroy_parser(parser);
    }
    ptkx_clear_sv(aTHX_ &p->read_cb);
    ptkx_clear_sv(aTHX_ &p->source_copy);
    ptkx_clear_sv(aTHX_ &p->pending_chunk);
}

static void
ptkx_parser_free(pTHX_ ptkx_parser* p)
{
    ptkx_parser_release(aTHX_ p);
    ptkx_clear_sv(aTHX_ &p->error);
    SvREFCNT_dec((SV*) p->value_stash);
    Safefree(p);
}

static void
ptkx_parser_finish(pTHX_ ptkx_parser* p)
{
    p->state = PTKX_FINISHED;
    ptkx_parser_release(aTHX_ p);
}

/* Puts the parser into the FAILED state and raises its error; every later
 * call raises the same error again. A non-NULL error (ownership passes to
 * the parser) replaces the recorded one. */
static void ptkx_parser_fail(pTHX_ ptkx_parser* p, SV* error) __attribute__noreturn__;

static void
ptkx_parser_fail(pTHX_ ptkx_parser* p, SV* error)
{
    if (error) {
        SV* previous = p->error;
        p->error = error;
        SvREFCNT_dec(previous);
    }
    p->state = PTKX_FAILED;
    ptkx_parser_release(aTHX_ p);
    croak_sv(p->error);
}

/* Records an error from code that runs inside ckdl and must not croak. The
 * first error wins; ownership of error passes to the parser. */
static void
ptkx_parser_record_error(pTHX_ ptkx_parser* p, SV* error)
{
    if (p->error) {
        SvREFCNT_dec(error);
        return;
    }
    p->error = error;
}

/* ------------------------------------------------------------------------- */
/* Callback sources                                                          */
/* ------------------------------------------------------------------------- */

static void
ptkx_source_ended(pTHX_ ptkx_parser* p)
{
    p->source_exhausted = TRUE;
    if (p->utf8.continuation_bytes > 0)
        ptkx_parser_record_error(aTHX_ p, newSVpvs("KDL parse error: input is not valid UTF-8"));
}

/* Takes a chunk returned by the source callback into p->pending_chunk.
 * Chunks are UTF-8 bytes: the buffer of a scalar is used as it is, which for
 * a character string (UTF-8 flag on) is its UTF-8 encoding. Returns TRUE if
 * a non-empty chunk is pending. */
static bool
ptkx_accept_chunk(pTHX_ ptkx_parser* p, SV* chunk)
{
    const char* bytes;
    STRLEN len;

    if (SvROK(chunk) || SvGMAGICAL(chunk)) {
        ptkx_parser_record_error(aTHX_ p, newSVpvs(PTKX_PARSER_CLASS
            ": the source callback must return a string or undef, not a reference"));
        return FALSE;
    }
    if (!SvOK(chunk)) {
        ptkx_source_ended(aTHX_ p);
        return FALSE;
    }

    bytes = SvPV_nomg(chunk, len);
    if (len == 0) {
        ptkx_source_ended(aTHX_ p);
        return FALSE;
    }
    if (!ptkx_utf8_feed(&p->utf8, (const U8*) bytes, len)) {
        ptkx_parser_record_error(aTHX_ p, newSVpvs("KDL parse error: input is not valid UTF-8"));
        return FALSE;
    }

    if (!p->pending_chunk) p->pending_chunk = newSV(len);
    sv_setpvn(p->pending_chunk, bytes, len);
    p->pending_offset = 0;
    return TRUE;
}

/* Calls the source callback once. Runs inside ckdl, so it never croaks: an
 * exception from the callback is recorded in p->error and raised by the
 * XSUB after ckdl has returned. Returns TRUE if a non-empty chunk is
 * pending. */
static bool
ptkx_fetch_chunk(pTHX_ ptkx_parser* p, size_t wanted)
{
    dSP;
    SV* chunk;
    SV* error;
    int count;
    bool fetched = FALSE;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    mXPUSHu((UV) wanted);
    PUTBACK;

    p->in_callback = TRUE;
    count = call_sv(p->read_cb, G_SCALAR | G_EVAL);
    p->in_callback = FALSE;

    SPAGAIN;
    chunk = count > 0 ? POPs : &PL_sv_undef;
    PUTBACK;

    error = ERRSV;
    if (SvROK(error) || SvTRUE_nomg(error))
        ptkx_parser_record_error(aTHX_ p, newSVsv(error));
    else
        fetched = ptkx_accept_chunk(aTHX_ p, chunk);

    FREETMPS;
    LEAVE;
    return fetched;
}

/* kdl_read_func for callback sources: hands ckdl up to bufsize bytes of the
 * pending chunk and fetches the next chunk once it is used up. Returns 0 at
 * end of input and after an error. */
static size_t
ptkx_read_thunk(void* user_data, char* buf, size_t bufsize)
{
    dTHX;
    ptkx_parser* p = (ptkx_parser*) user_data;
    STRLEN available;
    size_t delivered;

    if (bufsize == 0 || !p->read_cb || p->error || p->source_exhausted) return 0;

    if (!p->pending_chunk || p->pending_offset >= SvCUR(p->pending_chunk)) {
        if (!ptkx_fetch_chunk(aTHX_ p, bufsize)) return 0;
    }

    available = SvCUR(p->pending_chunk) - p->pending_offset;
    delivered = available < bufsize ? available : bufsize;
    Copy(SvPVX_const(p->pending_chunk) + p->pending_offset, buf, delivered, char);
    p->pending_offset += delivered;
    return delivered;
}

/* ------------------------------------------------------------------------- */
/* Parser events                                                             */
/* ------------------------------------------------------------------------- */

static SV*
ptkx_parse_error(pTHX_ const kdl_event_data* ev)
{
    const kdl_str* message = &ev->value.string;
    if (ev->value.type != KDL_TYPE_STRING || message->data == NULL)
        return newSVpvs("KDL parse error");
    return newSVpvf("KDL parse error: %.*s", (int) message->len, message->data);
}

/* Counts open nodes and fails the parser when they exceed max_depth. */
static void
ptkx_track_depth(pTHX_ ptkx_parser* p, kdl_event base)
{
    if (base == KDL_EVENT_END_NODE) {
        --p->depth;
        return;
    }
    if (base != KDL_EVENT_START_NODE) return;
    if (++p->depth > p->max_depth && p->max_depth > 0)
        ptkx_parser_fail(aTHX_ p, newSVpvf(
            "KDL parse error: nesting depth exceeds max_depth (%" IVdf ")", p->max_depth));
}

/* The first text field of ev that is not valid Unicode, or NULL. ckdl can
 * produce surrogates and code points above U+10FFFF from \u{...} escapes. */
static const char*
ptkx_invalid_text_field(const kdl_event_data* ev, kdl_event base)
{
    const kdl_value* value = &ev->value;

    if (!ptkx_is_text(ev->name))
        return base == KDL_EVENT_PROPERTY ? "property key" : "node name";
    if (!ptkx_is_text(value->type_annotation)) return "type annotation";
    if (value->type == KDL_TYPE_STRING && !ptkx_is_text(value->string))
        return ev->event == KDL_EVENT_COMMENT ? "comment" : "string";
    return NULL;
}

static const char*
ptkx_event_name(const kdl_event_data* ev, kdl_event base)
{
    if (ev->event == KDL_EVENT_COMMENT) return "comment";
    switch (base) {
    case KDL_EVENT_START_NODE: return "start_node";
    case KDL_EVENT_END_NODE:   return "end_node";
    case KDL_EVENT_ARGUMENT:   return "argument";
    case KDL_EVENT_PROPERTY:   return "property";
    default:                   return NULL;
    }
}

/* A character string SV holding validated UTF-8 text. */
static SV*
ptkx_text_sv(pTHX_ kdl_str text)
{
    return newSVpvn_flags(text.data, text.len, SVf_UTF8);
}

/* The Perl value of a parsed number and its kind. Integer text that ckdl
 * leaves string-encoded but that fits IV or UV becomes an integer. */
static SV*
ptkx_number_sv(pTHX_ const kdl_number* number, const char** kind)
{
    UV magnitude;
    int flags;

    switch (number->type) {
    case KDL_NUMBER_TYPE_INTEGER:
        *kind = "integer";
        return newSViv((IV) number->integer);
    case KDL_NUMBER_TYPE_FLOATING_POINT:
        *kind = "float";
        return newSVnv(ptkx_correctly_rounded(aTHX_ number->floating_point));
    case KDL_NUMBER_TYPE_STRING_ENCODED:
        break;
    }

    flags = grok_number(number->string.data, number->string.len, &magnitude);
    if (flags == IS_NUMBER_IN_UV) {
        *kind = "integer";
        return magnitude <= (UV) IV_MAX ? newSViv((IV) magnitude) : newSVuv(magnitude);
    }
    if (flags == (IS_NUMBER_IN_UV | IS_NUMBER_NEG) && magnitude <= (UV) IV_MAX + 1) {
        *kind = "integer";
        return newSViv(magnitude == (UV) IV_MAX + 1 ? IV_MIN : -(IV) magnitude);
    }
    *kind = "string";
    return newSVpvn(number->string.data, number->string.len);
}

/* A Text::KDL::XS::Value object. Every slot holds a fresh SV, so callers may
 * modify the hash. */
static SV*
ptkx_value_sv(pTHX_ HV* stash, const kdl_value* value)
{
    HV* fields = newHV();
    SV* object = newRV_noinc((SV*) fields);
    SV* kind   = NULL;
    SV* content;
    const char* type;

    switch (value->type) {
    case KDL_TYPE_NULL:
        type    = "null";
        content = newSV(0);
        break;
    case KDL_TYPE_BOOLEAN:
        type    = "bool";
        content = newSViv(value->boolean ? 1 : 0);
        break;
    case KDL_TYPE_STRING:
        type    = "string";
        content = ptkx_text_sv(aTHX_ value->string);
        break;
    case KDL_TYPE_NUMBER:
    default: {
        const char* kind_name = NULL;
        type    = "number";
        content = ptkx_number_sv(aTHX_ &value->number, &kind_name);
        kind    = newSVpv(kind_name, 0);
        break;
    }
    }

    (void) hv_stores(fields, "type",  newSVpv(type, 0));
    (void) hv_stores(fields, "kind",  kind ? kind : newSV(0));
    (void) hv_stores(fields, "value", content);
    (void) hv_stores(fields, "type_annotation", value->type_annotation.data
                                                ? ptkx_text_sv(aTHX_ value->type_annotation)
                                                : newSV(0));
    return sv_bless(object, stash);
}

/* The next event of an active parser as a hash reference, or NULL at the
 * end of input. Failures put the parser into the FAILED state and croak. */
static SV*
ptkx_next_event(pTHX_ ptkx_parser* p)
{
    const kdl_event_data* ev = kdl_parser_next_event(p->parser);
    kdl_event base;
    const char* name;
    const char* invalid_field;
    HV* fields;

    if (p->error) ptkx_parser_fail(aTHX_ p, NULL);
    if (ev == NULL)
        ptkx_parser_fail(aTHX_ p, newSVpvs(PTKX_PARSER_CLASS ": ckdl returned no event"));

    if (ev->event == KDL_EVENT_EOF) {
        ptkx_parser_finish(aTHX_ p);
        return NULL;
    }
    if (ev->event == KDL_EVENT_PARSE_ERROR) ptkx_parser_fail(aTHX_ p, ptkx_parse_error(aTHX_ ev));

    base = (kdl_event) (ev->event & ~KDL_EVENT_COMMENT);
    name = ptkx_event_name(ev, base);
    if (name == NULL)
        ptkx_parser_fail(aTHX_ p, newSVpvf(PTKX_PARSER_CLASS ": unexpected ckdl event 0x%x",
                                           (unsigned) ev->event));
    ptkx_track_depth(aTHX_ p, base);
    invalid_field = ptkx_invalid_text_field(ev, base);
    if (invalid_field)
        ptkx_parser_fail(aTHX_ p, newSVpvf(
            "KDL parse error: %s contains a surrogate or a code point above U+10FFFF", invalid_field));

    fields = newHV();
    (void) hv_stores(fields, "event", newSVpv(name, 0));
    (void) hv_stores(fields, "commented", newSViv((ev->event & KDL_EVENT_COMMENT) ? 1 : 0));

    if (ev->event == KDL_EVENT_COMMENT) {
        (void) hv_stores(fields, "text", ptkx_text_sv(aTHX_ ev->value.string));
    }
    else if (base == KDL_EVENT_START_NODE) {
        (void) hv_stores(fields, "name", ptkx_text_sv(aTHX_ ev->name));
        if (ev->value.type_annotation.data)
            (void) hv_stores(fields, "type", ptkx_text_sv(aTHX_ ev->value.type_annotation));
    }
    else if (base == KDL_EVENT_ARGUMENT) {
        (void) hv_stores(fields, "value", ptkx_value_sv(aTHX_ p->value_stash, &ev->value));
    }
    else if (base == KDL_EVENT_PROPERTY) {
        (void) hv_stores(fields, "name",  ptkx_text_sv(aTHX_ ev->name));
        (void) hv_stores(fields, "value", ptkx_value_sv(aTHX_ p->value_stash, &ev->value));
    }
    return newRV_noinc((SV*) fields);
}

/* ------------------------------------------------------------------------- */
/* Emitter input                                                             */
/* ------------------------------------------------------------------------- */

/* True if a KDL parser reads text, written without quotes, as a keyword or a
 * number rather than as a string: true, false and null (and in v2 inf, -inf
 * and nan), or text starting like a number (+1, -1, .5, -.5). ckdl checks
 * only the characters and would write such text bare. */
static bool
ptkx_is_ambiguous_bare(kdl_version version, const char* text, STRLEN len)
{
    const char* p   = text;
    const char* end = text + len;

    if (memEQs(text, len, "true") || memEQs(text, len, "false") || memEQs(text, len, "null"))
        return TRUE;
    if (version == KDL_VERSION_2
        && (memEQs(text, len, "inf") || memEQs(text, len, "-inf") || memEQs(text, len, "nan")))
        return TRUE;

    if (p < end && (*p == '+' || *p == '-')) {
        ++p;
        if (p < end && *p == '.') ++p;
    }
    else if (p < end && *p == '.') {
        ++p;
    }
    else {
        return FALSE;
    }
    return p < end && isDIGIT(*p);
}

/* Notes when text that the emitter may write bare (a node name, property
 * key, type annotation, or a v2 string value) would not read back as a
 * string, so that the caller can emit the document again in quote-all mode. */
static void
ptkx_note_bare_text(ptkx_emitter* e, kdl_str text)
{
    if (e->writes_bare && !e->needs_quoting
        && ptkx_is_ambiguous_bare(e->version, text.data, text.len))
        e->needs_quoting = TRUE;
}

/* The UTF-8 text of a string argument for ckdl. Croaks when sv is undef or
 * holds a surrogate or a code point above U+10FFFF. A byte string is taken
 * as Latin-1 characters and encoded in a temporary copy. */
static kdl_str
ptkx_text_arg(pTHX_ SV* sv, const char* what)
{
    kdl_str text;
    STRLEN len;

    sv = ptkx_plain(aTHX_ sv);
    if (!SvOK(sv)) croak("emit_kdl: %s must be defined", what);

    text.data = SvPV_nomg(sv, len);
    if (!SvUTF8(sv) && !ptkx_is_ascii(text.data, len)) {
        SV* encoded = sv_2mortal(newSVpvn(text.data, len));
        sv_utf8_upgrade(encoded);
        text.data = SvPV_nomg(encoded, len);
    }
    text.len = len;

    if (!ptkx_is_unicode_utf8(text.data, text.len))
        croak("emit_kdl: %s contains a surrogate or a code point above U+10FFFF", what);
    return text;
}

#define PTKX_FIELD(fields, key) ptkx_field(aTHX_ (fields), STR_WITH_LEN(key))

/* A field of a value payload hash; undef when missing. */
static SV*
ptkx_field(pTHX_ HV* fields, const char* key, I32 key_len)
{
    SV** slot = hv_fetch(fields, key, key_len, 0);
    return slot ? ptkx_plain(aTHX_ *slot) : &PL_sv_undef;
}

/* Fills number with the text of a payload number: integers and floats are
 * formatted into text_buf (PTKX_NUMBER_BUFSIZE bytes), string-encoded
 * numbers are validated and used verbatim. ckdl always receives
 * KDL_NUMBER_TYPE_STRING_ENCODED and writes the text as it is. */
static void
ptkx_number_from_payload(pTHX_ const ptkx_emitter* e, SV* kind, SV* content,
                         char* text_buf, kdl_number* number)
{
    const char* kind_name;
    STRLEN kind_len;
    STRLEN len;

    if (!SvOK(kind))
        croak("emit_kdl: number has no kind (expected integer, float or string)");
    if (!SvOK(content))
        croak("emit_kdl: number value must be defined");

    kind_name    = SvPV_nomg(kind, kind_len);
    number->type = KDL_NUMBER_TYPE_STRING_ENCODED;

    if (memEQs(kind_name, kind_len, "integer")) {
        if (!ptkx_format_integer(aTHX_ content, text_buf, &len))
            croak("emit_kdl: integer value '%" SVf "' is not an integer from %" IVdf " to %" UVuf,
                  SVfARG(content), IV_MIN, UV_MAX);
        number->string.data = text_buf;
        number->string.len  = len;
        return;
    }

    if (memEQs(kind_name, kind_len, "float")) {
        NV nv;
        if (!SvNIOK(content) && !looks_like_number(content))
            croak("emit_kdl: float value '%" SVf "' is not a number", SVfARG(content));
        nv = SvNV_nomg(content);
        if (e->version == KDL_VERSION_1 && (Perl_isnan(nv) || Perl_isinf(nv)))
            croak(PTKX_V1_NON_FINITE);
        number->string.data = text_buf;
        number->string.len  = ptkx_format_double(aTHX_ (double) nv, text_buf);
        return;
    }

    if (memEQs(kind_name, kind_len, "string")) {
        const char* literal = SvPV_nomg(content, len);
        if (!ptkx_is_number_literal(literal, len))
            croak("emit_kdl: '%" SVf "' is not a KDL number", SVfARG(content));
        if (e->version == KDL_VERSION_1 && ptkx_is_keyword_number(literal, len))
            croak(PTKX_V1_NON_FINITE);
        number->string.data = literal;
        number->string.len  = len;
        return;
    }

    croak("emit_kdl: unknown number kind '%" SVf "' (expected integer, float or string)",
          SVfARG(kind));
}

/* Fills value from a payload: a hash reference with the keys type, kind,
 * value and type_annotation (a Text::KDL::XS::Value is one). Text pointers
 * refer to SV buffers and to text_buf, valid until the calling XSUB
 * returns. */
static void
ptkx_value_from_payload(pTHX_ ptkx_emitter* e, SV* payload, char* text_buf, kdl_value* value)
{
    HV* fields;
    SV* type;
    SV* annotation;
    SV* content;
    const char* type_name;
    STRLEN type_len;

    payload = ptkx_plain(aTHX_ payload);
    if (!SvROK(payload) || SvTYPE(SvRV(payload)) != SVt_PVHV)
        croak("emit_kdl: a value payload must be a HASH reference");

    fields     = (HV*) SvRV(payload);
    type       = PTKX_FIELD(fields, "type");
    annotation = PTKX_FIELD(fields, "type_annotation");
    content    = PTKX_FIELD(fields, "value");

    Zero(value, 1, kdl_value);
    if (SvOK(annotation)) {
        value->type_annotation = ptkx_text_arg(aTHX_ annotation, "type annotation");
        ptkx_note_bare_text(e, value->type_annotation);
    }

    if (!SvOK(type))
        croak("emit_kdl: value has no type (expected null, bool, number or string)");
    type_name = SvPV_nomg(type, type_len);

    if (memEQs(type_name, type_len, "null")) {
        value->type = KDL_TYPE_NULL;
    }
    else if (memEQs(type_name, type_len, "bool")) {
        value->type    = KDL_TYPE_BOOLEAN;
        value->boolean = SvTRUE_nomg(content) ? true : false;
    }
    else if (memEQs(type_name, type_len, "string")) {
        value->type   = KDL_TYPE_STRING;
        value->string = ptkx_text_arg(aTHX_ content, "string value");
        if (e->version == KDL_VERSION_2) ptkx_note_bare_text(e, value->string);
    }
    else if (memEQs(type_name, type_len, "number")) {
        value->type = KDL_TYPE_NUMBER;
        ptkx_number_from_payload(aTHX_ e, PTKX_FIELD(fields, "kind"), content, text_buf, &value->number);
    }
    else {
        croak("emit_kdl: unknown value type '%" SVf "' (expected null, bool, number or string)",
              SVfARG(type));
    }
}

/* ckdl emitter options from the private constructor's arguments. -1 keeps
 * ckdl's default for indent, escape_mode and identifier_mode; version 0
 * (detect) writes KDL v2. v2 output always escapes newlines, which KDL v2
 * does not allow literally inside a quoted string. */
static kdl_emitter_options
ptkx_emitter_options(pTHX_ IV version, IV indent, IV escape_mode, IV identifier_mode)
{
    kdl_emitter_options options = KDL_DEFAULT_EMITTER_OPTIONS;

    switch (version) {
    case 0:
    case 2:  options.version = KDL_VERSION_2; break;
    case 1:  options.version = KDL_VERSION_1; break;
    default: croak("emit_kdl: version must be 0 (detect), 1 or 2");
    }

    if (indent != -1) {
        if (indent < 0 || indent > PTKX_MAX_INDENT)
            croak("emit_kdl: indent must be an integer from 0 to %d", PTKX_MAX_INDENT);
        options.indent = (int) indent;
    }
    if (escape_mode != -1) {
        if (escape_mode < 0 || (escape_mode & ~(IV) KDL_ESCAPE_ASCII_MODE) != 0)
            croak("emit_kdl: escape_mode must be a combination of 0x10, 0x20, 0x40 and 0x170");
        options.escape_mode = (kdl_escape_mode) escape_mode;
    }
    if (identifier_mode != -1) {
        if (identifier_mode < 0 || identifier_mode > 2)
            croak("emit_kdl: identifier_mode must be 0, 1 or 2");
        options.identifier_mode = (kdl_identifier_emission_mode) identifier_mode;
    }

    if (options.version == KDL_VERSION_2)
        options.escape_mode = (kdl_escape_mode) (options.escape_mode | KDL_ESCAPE_NEWLINE);
    return options;
}

static void
ptkx_check_emit(pTHX_ bool succeeded, const char* operation)
{
    if (!succeeded) croak("emit_kdl: %s failed", operation);
}

/* ------------------------------------------------------------------------- */
/* XS bindings                                                               */
/* ------------------------------------------------------------------------- */

MODULE = Text::KDL::XS    PACKAGE = Text::KDL::XS

PROTOTYPES: DISABLE

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

SV*
_float_text(number)
        NV number
    PREINIT:
        char text[PTKX_NUMBER_BUFSIZE];
        STRLEN len;
    CODE:
        len    = ptkx_format_double(aTHX_ (double) number, text);
        RETVAL = newSVpvn(text, len);
    OUTPUT:
        RETVAL

bool
_is_number_literal(text)
        SV* text
    PREINIT:
        const char* literal;
        STRLEN len;
    CODE:
        text = ptkx_plain(aTHX_ text);
        RETVAL = FALSE;
        if (SvOK(text) && !SvROK(text)) {
            literal = SvPV_nomg(text, len);
            RETVAL  = ptkx_is_number_literal(literal, len);
        }
    OUTPUT:
        RETVAL

bool
_is_native_integer(value)
        SV* value
    PREINIT:
        char digits[PTKX_NUMBER_BUFSIZE];
        STRLEN len;
    CODE:
        value  = ptkx_plain(aTHX_ value);
        RETVAL = SvOK(value) && !SvROK(value) && ptkx_format_integer(aTHX_ value, digits, &len);
    OUTPUT:
        RETVAL

SV*
_number_kind_of(value)
        SV* value
    CODE:
        value = ptkx_plain(aTHX_ value);
        if (SvROK(value)) XSRETURN_UNDEF;
        switch (ptkx_scalar_number_kind(aTHX_ value)) {
        case PTKX_INTEGER:      RETVAL = newSVpvs("integer"); break;
        case PTKX_FLOAT:        RETVAL = newSVpvs("float");   break;
        case PTKX_NOT_A_NUMBER:
        default:                XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL


MODULE = Text::KDL::XS    PACKAGE = Text::KDL::XS::Parser

int
CLONE_SKIP(...)
    CODE:
        PERL_UNUSED_VAR(items);
        RETVAL = 1;
    OUTPUT:
        RETVAL

SV*
_new_string_parser(klass, document, options, max_depth)
        SV* klass
        SV* document
        IV options
        IV max_depth
    PREINIT:
        HV* stash;
        SV* source_copy;
        kdl_str text;
        STRLEN len;
        ptkx_parser* parser;
    CODE:
        stash = ptkx_class_stash(aTHX_ klass, PTKX_PARSER_CLASS);
        ptkx_check_parse_options(aTHX_ options, max_depth);

        /* ckdl keeps pointers into the source: read it once into a private
         * copy and encode only the copy */
        source_copy = sv_2mortal(newSVsv(document));
        if (!SvOK(source_copy) || SvROK(source_copy))
            croak(PTKX_PARSER_CLASS ": a string source must be a defined string");
        text.data = SvPVutf8(source_copy, len);
        text.len  = len;
        if (!ptkx_is_unicode_utf8(text.data, text.len))
            croak("KDL parse error: input is not valid UTF-8");

        parser = ptkx_parser_new(aTHX_ max_depth);
        parser->source_copy = SvREFCNT_inc_simple_NN(source_copy);
        parser->parser = kdl_create_string_parser(text, (kdl_parse_option) options);
        if (!parser->parser) {
            ptkx_parser_free(aTHX_ parser);
            croak(PTKX_PARSER_CLASS ": kdl_create_string_parser failed");
        }
        RETVAL = ptkx_wrap(aTHX_ stash, parser, &ptkx_parser_vtbl);
    OUTPUT:
        RETVAL

SV*
_new_stream_parser(klass, callback, options, max_depth)
        SV* klass
        SV* callback
        IV options
        IV max_depth
    PREINIT:
        HV* stash;
        ptkx_parser* parser;
    CODE:
        stash = ptkx_class_stash(aTHX_ klass, PTKX_PARSER_CLASS);
        ptkx_check_parse_options(aTHX_ options, max_depth);
        callback = ptkx_plain(aTHX_ callback);
        if (!SvROK(callback) || SvTYPE(SvRV(callback)) != SVt_PVCV)
            croak(PTKX_PARSER_CLASS ": a stream source must be a CODE reference");

        parser = ptkx_parser_new(aTHX_ max_depth);
        parser->read_cb = newSVsv(callback);
        /* ckdl calls the source once here, looking for a byte order mark */
        parser->parser = kdl_create_stream_parser(ptkx_read_thunk, (void*) parser,
                                                  (kdl_parse_option) options);
        if (!parser->parser || parser->error) {
            SV* error = parser->error ? sv_2mortal(SvREFCNT_inc_simple_NN(parser->error)) : NULL;
            ptkx_parser_free(aTHX_ parser);
            if (error) croak_sv(error);
            croak(PTKX_PARSER_CLASS ": kdl_create_stream_parser failed");
        }
        RETVAL = ptkx_wrap(aTHX_ stash, parser, &ptkx_parser_vtbl);
    OUTPUT:
        RETVAL

SV*
_next_event(parser)
        ptkx_parser* parser
    CODE:
        if (parser->in_callback)
            croak(PTKX_PARSER_CLASS ": next_event called from inside the parser's own source callback");
        if (parser->state == PTKX_FAILED) croak_sv(parser->error);
        if (parser->state == PTKX_FINISHED) XSRETURN_UNDEF;

        PTKX_KEEP_ALIVE(ST(0));
        RETVAL = ptkx_next_event(aTHX_ parser);
        if (!RETVAL) XSRETURN_UNDEF;
    OUTPUT:
        RETVAL


MODULE = Text::KDL::XS    PACKAGE = Text::KDL::XS::Emitter

int
CLONE_SKIP(...)
    CODE:
        PERL_UNUSED_VAR(items);
        RETVAL = 1;
    OUTPUT:
        RETVAL

SV*
_new(klass, version, indent, escape_mode, identifier_mode)
        SV* klass
        IV version
        IV indent
        IV escape_mode
        IV identifier_mode
    PREINIT:
        HV* stash;
        kdl_emitter_options options;
        ptkx_emitter* emitter;
    CODE:
        stash   = ptkx_class_stash(aTHX_ klass, PTKX_EMITTER_CLASS);
        options = ptkx_emitter_options(aTHX_ version, indent, escape_mode, identifier_mode);

        Newxz(emitter, 1, ptkx_emitter);
        emitter->version     = options.version;
        emitter->writes_bare = options.identifier_mode != KDL_QUOTE_ALL_IDENTIFIERS;
        emitter->emitter = kdl_create_buffering_emitter(&options);
        if (!emitter->emitter) {
            Safefree(emitter);
            croak("emit_kdl: kdl_create_buffering_emitter failed");
        }
        RETVAL = ptkx_wrap(aTHX_ stash, emitter, &ptkx_emitter_vtbl);
    OUTPUT:
        RETVAL

void
_emit_node(emitter, name, type_annotation)
        ptkx_emitter* emitter
        SV* name
        SV* type_annotation
    PREINIT:
        kdl_str name_text;
    CODE:
        PTKX_KEEP_ALIVE(ST(0));
        name_text       = ptkx_text_arg(aTHX_ name, "node name");
        type_annotation = ptkx_plain(aTHX_ type_annotation);
        ptkx_note_bare_text(emitter, name_text);
        if (SvOK(type_annotation)) {
            kdl_str type_text = ptkx_text_arg(aTHX_ type_annotation, "type annotation");
            ptkx_note_bare_text(emitter, type_text);
            ptkx_check_emit(aTHX_ kdl_emit_node_with_type(emitter->emitter, type_text, name_text),
                            "kdl_emit_node_with_type");
        }
        else {
            ptkx_check_emit(aTHX_ kdl_emit_node(emitter->emitter, name_text), "kdl_emit_node");
        }

void
_emit_arg(emitter, payload)
        ptkx_emitter* emitter
        SV* payload
    PREINIT:
        kdl_value value;
        char number_text[PTKX_NUMBER_BUFSIZE];
    CODE:
        PTKX_KEEP_ALIVE(ST(0));
        ptkx_value_from_payload(aTHX_ emitter, payload, number_text, &value);
        ptkx_check_emit(aTHX_ kdl_emit_arg(emitter->emitter, &value), "kdl_emit_arg");

void
_emit_property(emitter, key, payload)
        ptkx_emitter* emitter
        SV* key
        SV* payload
    PREINIT:
        kdl_str key_text;
        kdl_value value;
        char number_text[PTKX_NUMBER_BUFSIZE];
    CODE:
        PTKX_KEEP_ALIVE(ST(0));
        key_text = ptkx_text_arg(aTHX_ key, "property key");
        ptkx_note_bare_text(emitter, key_text);
        ptkx_value_from_payload(aTHX_ emitter, payload, number_text, &value);
        ptkx_check_emit(aTHX_ kdl_emit_property(emitter->emitter, key_text, &value),
                        "kdl_emit_property");

void
_start_children(emitter)
        ptkx_emitter* emitter
    CODE:
        ptkx_check_emit(aTHX_ kdl_start_emitting_children(emitter->emitter),
                        "kdl_start_emitting_children");

void
_finish_children(emitter)
        ptkx_emitter* emitter
    CODE:
        ptkx_check_emit(aTHX_ kdl_finish_emitting_children(emitter->emitter),
                        "kdl_finish_emitting_children");

void
_emit_end(emitter)
        ptkx_emitter* emitter
    CODE:
        ptkx_check_emit(aTHX_ kdl_emit_end(emitter->emitter), "kdl_emit_end");

bool
_needs_quoting(emitter)
        ptkx_emitter* emitter
    CODE:
        RETVAL = emitter->needs_quoting;
    OUTPUT:
        RETVAL

SV*
_get_buffer(emitter)
        ptkx_emitter* emitter
    PREINIT:
        kdl_str buffer;
    CODE:
        buffer = kdl_get_emitter_buffer(emitter->emitter);
        RETVAL = newSVpvn_flags(buffer.data ? buffer.data : "", buffer.len, SVf_UTF8);
    OUTPUT:
        RETVAL
