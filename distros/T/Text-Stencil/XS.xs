
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef av_count
#define av_count(av) (av_top_index(av) + 1)
#endif

#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <time.h>
#include <math.h>
#include <limits.h>
#include <stdarg.h>

/* ---- escape/format helpers ---- */

/* any byte >= 0x80? word-at-a-time; the mask is 0x80 in every byte of a UV */
#define TS_HIGH_MASK ((UV)~(UV)0 / 255 * 128)
static int has_high_byte(const char *s, STRLEN len) {
    const unsigned char *p = (const unsigned char *)s;
    STRLEN i = 0;
    while (i + sizeof(UV) <= len) {
        UV w;
        memcpy(&w, p + i, sizeof(UV));
        if (w & TS_HIGH_MASK) return 1;
        i += sizeof(UV);
    }
    for (; i < len; i++) if (p[i] & 0x80) return 1;
    return 0;
}

/* gmtime_r is not everywhere: perl leaves HAS_GMTIME_R undefined on plenty of
   builds, MSVC has no such function, and under a strict -std= glibc hides it
   (an error, not a warning, since gcc 14). Plain gmtime() is C89 and perl's
   reentr.h already redirects it to the reentrant form on threaded builds, so
   copy out of it straight away. */
static int ts_gmtime(const time_t *epoch, struct tm *out) {
#ifdef HAS_GMTIME_R
    return gmtime_r(epoch, out) != NULL;
#else
    struct tm *r = gmtime(epoch);
    if (!r) return 0;
    *out = *r;
    return 1;
#endif
}

/* The digit-takers accept a sign anywhere in the text, not just in front. */
PERL_STATIC_INLINE int ts_has_minus(const char *s, STRLEN len) {
    STRLEN i;
    for (i = 0; i < len; i++) if (s[i] == '-') return 1;
    return 0;
}

/* Take a decimal out of text, saturating at the IV range. The magnitude is
   accumulated in a UV because IV_MIN is one larger in magnitude than IV_MAX:
   saturating an IV and negating afterwards lands one short of the most
   negative value. `neg` is decided by the caller, since the transforms differ
   on whether a '-' counts anywhere or only in front. */
static IV ts_scan_iv(const char *s, STRLEN len, int neg) {
    const UV lim = (UV)IV_MAX + 1;
    UV uv = 0;
    STRLEN i;
    for (i = 0; i < len; i++) {
        UV d;
        if (s[i] < '0' || s[i] > '9') continue;
        d = (UV)(s[i] - '0');
        /* bound against the digit in hand, not a worst-case 9: that saturated
           the top eight magnitudes although they fit */
        if (uv > (lim - d) / 10) { uv = lim; break; }
        uv = uv * 10 + d;
    }
    if (neg) return (uv >= lim) ? IV_MIN : -(IV)uv;
    return (uv > (UV)IV_MAX) ? IV_MAX : (IV)uv;
}

PERL_STATIC_INLINE int itoa_fast(char *buf, IV val) {
    char tmp[20];
    int len = 0, neg = 0;
    UV uval;
    if (val < 0) { neg = 1; uval = -(UV)val; } else { uval = (UV)val; }
    do { tmp[len++] = '0' + (uval % 10); uval /= 10; } while (uval);
    if (neg) tmp[len++] = '-';
    for (int i = 0; i < len; i++) buf[i] = tmp[len - 1 - i];
    return len;
}

static int itoa_comma(char *buf, IV val) {
    char digits[20];
    int dlen = 0, neg = 0;
    UV uval;
    if (val < 0) { neg = 1; uval = -(UV)val; } else { uval = (UV)val; }
    do { digits[dlen++] = '0' + (uval % 10); uval /= 10; } while (uval);
    int pos = 0;
    if (neg) buf[pos++] = '-';
    for (int i = dlen - 1; i >= 0; i--) {
        buf[pos++] = digits[i];
        if (i > 0 && i % 3 == 0) buf[pos++] = ',';
    }
    return pos;
}

/* Which bytes each escaper has to stop on. Compile-time constants: building
   them at BOOT meant two interpreters could race on the first require, and a
   reader that saw the "done" flag before the stores landed would escape
   nothing. There is no initialisation left to get wrong. */
static const char html_special[256] = {
    ['&']=1, ['<']=1, ['>']=1, ['"']=1, ['\'']=1
};
static const char html_br_special[256] = {
    ['&']=1, ['<']=1, ['>']=1, ['"']=1, ['\'']=1, ['\n']=1
};
/* JSON must escape every control character, plus the quote and backslash */
static const char json_special[256] = {
    [0x00]=1, [0x01]=1, [0x02]=1, [0x03]=1, [0x04]=1, [0x05]=1, [0x06]=1, [0x07]=1, [0x08]=1, [0x09]=1, [0x0a]=1, [0x0b]=1, [0x0c]=1, [0x0d]=1, [0x0e]=1, [0x0f]=1, [0x10]=1, [0x11]=1, [0x12]=1, [0x13]=1, [0x14]=1, [0x15]=1, [0x16]=1, [0x17]=1, [0x18]=1, [0x19]=1, [0x1a]=1, [0x1b]=1, [0x1c]=1, [0x1d]=1, [0x1e]=1, [0x1f]=1,
    ['"']=1, ['\\']=1
};

static STRLEN html_escape(char *dst, const char *src, STRLEN slen) {
    char *out = dst;
    STRLEN i = 0;
    while (i < slen) {
        /* scan for run of non-special bytes */
        STRLEN run = i;
        while (run < slen && !html_special[(unsigned char)src[run]]) run++;
        if (run > i) {
            memcpy(out, src + i, run - i);
            out += run - i;
            i = run;
        }
        if (i >= slen) break;
        switch (src[i]) {
            case '&':  memcpy(out, "&amp;",  5); out += 5; break;
            case '<':  memcpy(out, "&lt;",   4); out += 4; break;
            case '>':  memcpy(out, "&gt;",   4); out += 4; break;
            case '"':  memcpy(out, "&quot;", 6); out += 6; break;
            case '\'': memcpy(out, "&#39;",  5); out += 5; break;
        }
        i++;
    }
    return (STRLEN)(out - dst);
}

static STRLEN html_br_escape(char *dst, const char *src, STRLEN slen) {
    char *out = dst;
    STRLEN i = 0;
    while (i < slen) {
        STRLEN run = i;
        while (run < slen && !html_br_special[(unsigned char)src[run]]) run++;
        if (run > i) {
            memcpy(out, src + i, run - i);
            out += run - i;
            i = run;
        }
        if (i >= slen) break;
        switch (src[i]) {
            case '&':  memcpy(out, "&amp;",  5); out += 5; break;
            case '<':  memcpy(out, "&lt;",   4); out += 4; break;
            case '>':  memcpy(out, "&gt;",   4); out += 4; break;
            case '"':  memcpy(out, "&quot;", 6); out += 6; break;
            case '\'': memcpy(out, "&#39;",  5); out += 5; break;
            case '\n': memcpy(out, "<br>",   4); out += 4; break;
        }
        i++;
    }
    return (STRLEN)(out - dst);
}

static STRLEN url_escape(char *dst, const char *src, STRLEN slen) {
    static const char hex[] = "0123456789ABCDEF";
    char *out = dst;
    for (STRLEN i = 0; i < slen; i++) {
        unsigned char c = (unsigned char)src[i];
        if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') ||
            (c >= '0' && c <= '9') || c == '-' || c == '_' || c == '.' || c == '~')
            *out++ = c;
        else { *out++ = '%'; *out++ = hex[c >> 4]; *out++ = hex[c & 0xf]; }
    }
    return (STRLEN)(out - dst);
}

static STRLEN json_escape(char *dst, const char *src, STRLEN slen) {
    static const char hex[] = "0123456789abcdef";
    char *out = dst;
    for (STRLEN i = 0; i < slen; i++) {
        unsigned char c = (unsigned char)src[i];
        switch (c) {
            case '"':  *out++ = '\\'; *out++ = '"'; break;
            case '\\': *out++ = '\\'; *out++ = '\\'; break;
            case '\b': *out++ = '\\'; *out++ = 'b'; break;
            case '\f': *out++ = '\\'; *out++ = 'f'; break;
            case '\n': *out++ = '\\'; *out++ = 'n'; break;
            case '\r': *out++ = '\\'; *out++ = 'r'; break;
            case '\t': *out++ = '\\'; *out++ = 't'; break;
            default:
                if (c < 0x20) {
                    *out++ = '\\'; *out++ = 'u'; *out++ = '0'; *out++ = '0';
                    *out++ = hex[c >> 4]; *out++ = hex[c & 0xf];
                } else *out++ = c;
        }
    }
    return (STRLEN)(out - dst);
}

static STRLEN hex_encode(char *dst, const char *src, STRLEN slen) {
    static const char hex[] = "0123456789abcdef";
    for (STRLEN i = 0; i < slen; i++) {
        unsigned char c = (unsigned char)src[i];
        dst[i*2] = hex[c >> 4]; dst[i*2+1] = hex[c & 0xf];
    }
    return slen * 2;
}

static const char b64[]    = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static const char b64url[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

static STRLEN base64_encode_with(char *dst, const unsigned char *src, STRLEN slen, const char *alpha, int pad) {
    char *out = dst;
    STRLEN i;
    for (i = 0; i + 2 < slen; i += 3) {
        *out++ = alpha[src[i] >> 2];
        *out++ = alpha[((src[i] & 3) << 4) | (src[i+1] >> 4)];
        *out++ = alpha[((src[i+1] & 0xf) << 2) | (src[i+2] >> 6)];
        *out++ = alpha[src[i+2] & 0x3f];
    }
    if (i < slen) {
        *out++ = alpha[src[i] >> 2];
        if (i + 1 < slen) {
            *out++ = alpha[((src[i] & 3) << 4) | (src[i+1] >> 4)];
            *out++ = alpha[((src[i+1] & 0xf) << 2)];
        } else {
            *out++ = alpha[((src[i] & 3) << 4)];
            if (pad) *out++ = '=';
        }
        if (pad) *out++ = '=';
    }
    return (STRLEN)(out - dst);
}
#define base64_encode(d,s,l)    base64_encode_with(d,s,l,b64,1)
#define base64url_encode(d,s,l) base64_encode_with(d,s,l,b64url,0)

/* ---- compiled template structures ---- */

enum xform_type {
    XF_INT, XF_INT_COMMA, XF_FLOAT, XF_HTML, XF_HTML_BR,
    XF_RAW, XF_URL, XF_JSON, XF_TRIM, XF_UC, XF_LC,
    XF_PAD, XF_RPAD, XF_TRUNC, XF_DEFAULT,
    XF_HEX, XF_BASE64, XF_BASE64URL, XF_COUNT, XF_BOOL, XF_DATE,
    XF_SPRINTF, XF_REPLACE, XF_SUBSTR, XF_PLURAL,
    XF_IF, XF_UNLESS, XF_MAP, XF_WRAP,
    XF_NUMBER_SI, XF_BYTES_SI, XF_ELAPSED, XF_AGO,
    XF_MASK, XF_COALESCE, XF_LENGTH
};
enum row_mode { ROW_ARRAY, ROW_HASH };

typedef struct {
    enum xform_type type;
    int param_int;
    char *param_str;
    STRLEN param_str_len;
    char *param_str2;       /* bool falsy, replace new, plural plural-form, wrap suffix */
    STRLEN param_str2_len;
    int param_int2;         /* substr length, map entry count */
    /* map entries: stored as parallel arrays of keys and values */
    char **map_keys;   STRLEN *map_key_lens;
    char **map_vals;   STRLEN *map_val_lens;
    int map_count;
} tpl_xform;

/* a bare field reference with no transform; a named constant rather than a
   compound literal, which MSVC only accepted from VS2019 */
static const tpl_xform ts_raw_xform =
    { XF_RAW, 0, NULL, 0, NULL, 0, 0, NULL, NULL, NULL, NULL, 0 };

typedef struct {
    /* static text (if chain is NULL) */
    char *static_data;  STRLEN static_len;
    /* field ref */
    int col;
    char *key;  STRLEN key_len;  int key_utf8;
    /* transform chain */
    tpl_xform *chain;
    int chain_len;
    int is_rownum;
} tpl_op;

typedef struct {
    char *header;   STRLEN header_len;
    char *footer;   STRLEN footer_len;
    char *sep;      STRLEN sep_len;
    tpl_op *ops;    int nops;
    enum row_mode mode;
    /* the template really contained a numeric {0} ref, as opposed to mode
       defaulting to ROW_ARRAY because it contained no field refs at all */
    int saw_num_ref;
    SSize_t last_row_count;
    char escape_char;   /* delimiter char, default '{' */
    char *render_buf;   STRLEN render_buf_alloc;
    /* skip_if / skip_unless */
    int skip_if_col;    char *skip_if_key;    STRLEN skip_if_key_len;    int has_skip_if;    int skip_if_utf8;
    int skip_unless_col; char *skip_unless_key; STRLEN skip_unless_key_len; int has_skip_unless; int skip_unless_utf8;
    /* encoding: tpl_* fixed at compile time, r_* per render; see tpl_out_sv.
       A mid-character slice is noticed where it happens (TS_NOTE_CUT).
       tpl_utf8 is a bitmask of which pieces arrived flagged, so a flagged
       separator cannot vouch for a row that came in as bytes. */
    int tpl_utf8, tpl_high;
    int r_utf8, r_high, r_skipped;
    /* owner: the one SV allowed to reach this struct, so a deep copy that
       duplicates the blessed IV cannot become a second owner and free it
       twice.  in_use/doomed: a DESTROY that lands while a method is running
       defers the free instead of pulling the struct out from under it. */
    SV *owner;
    int in_use, doomed;
    /* the buffer a render is filling right now; BUF_ENSURE keeps it current so
       a croak out of user code can free it instead of leaking it */
    char *inflight;
} tpl_compiled;

#define TS_TPL_HDR 1
#define TS_TPL_ROW 2
#define TS_TPL_FTR 4
#define TS_TPL_SEP 8

static void tpl_free(tpl_compiled *t);

/* Our own magic is the proof that a blessed IV really is one of ours: reading
   an arbitrary integer as a tpl_compiled * segfaults, and a deep copier that
   duplicates the IV (Clone, and anything else that copies an SV verbatim)
   would otherwise produce a second owner that frees the same struct.  The
   vtable is all-zero -- we free in DESTROY, not from magic. */
static MGVTBL ts_vtbl = { 0, 0, 0, 0, 0, 0, 0, 0 };

/* Only a PVMG or richer body has a magic chain; mg_findext does not check, so
   on anything smaller it walks whatever the union holds instead. A blessed
   referent is always upgraded by sv_bless, which is why every method call is
   safe -- but the function-call form, Text::Stencil::render(\"str", ...),
   hands us an unblessed low-type referent and segfaulted once the heap was
   warm enough for the garbage to be non-NULL. */
#define TS_HAS_OUR_MAGIC(sv) \
    (SvROK(sv) && SvTYPE(SvRV(sv)) >= SVt_PVMG \
     ? mg_findext(SvRV(sv), PERL_MAGIC_ext, &ts_vtbl) : NULL)

static tpl_compiled *ts_self(pTHX_ SV *sv) {
    MAGIC *mg = TS_HAS_OUR_MAGIC(sv);
    tpl_compiled *t = mg ? (tpl_compiled *)mg->mg_ptr : NULL;
    /* the owner test rejects a copy that carried the magic along with it */
    if (!t || t->owner != SvRV(sv))
        croak("Text::Stencil: not a Text::Stencil object");
    return t;
}

/* Frees whatever buffer the render was filling when it croaked. */
static void ts_free_inflight(pTHX_ void *p) {
    tpl_compiled *t = (tpl_compiled *)p;
    if (t->inflight) { free(t->inflight); t->inflight = NULL; }
}

/* Released on scope exit, croak included. */
static void ts_unuse(pTHX_ void *p) {
    tpl_compiled *t = (tpl_compiled *)p;
    if (--t->in_use <= 0 && t->doomed) tpl_free(t);
}

/* Validate before pinning: a comma expression would run SvRV and the refcount
   bump first, and on a non-reference invocant -- Text::Stencil::render(undef,
   ...) or an instance method called on the class -- SvRV hands back the IV or
   the PV buffer, so we would increment and later decrement whatever that
   address points at.  Pinning the SV is not enough either: an explicit
   ->DESTROY from inside a callback frees the struct while we hold it, so the
   struct is marked in use for the duration of the call. */
static tpl_compiled *ts_pin_self(pTHX_ SV *sv) {
    tpl_compiled *t = ts_self(aTHX_ sv);
    sv_2mortal(SvREFCNT_inc_simple_NN(SvRV(sv)));
    t->in_use++;
    SAVEDESTRUCTOR_X(ts_unuse, t);
    return t;
}
#define TS_PIN_SELF(sv) ts_pin_self(aTHX_ (sv))

/* The rows AV arrives from the typemap with no reference held, and the same
   mid-render Perl can drop the caller's last one -- then av_fetch reads a
   freed body. */
#define TS_PIN_AV(av) sv_2mortal(SvREFCNT_inc_simple_NN((SV *)(av)))

/* Compile errors travel in a caller-supplied buffer: croaking inside the
   parser would abandon the half-built tpl_compiled. */
#define TS_ERRSZ 192
#define TS_REFSZ 32
/* DBL_MAX at 30 decimals is 341 bytes; sizing short truncated it into a
   different number */
#define TS_FLTSZ 384

/* Scratch for handing a field to strtod. At 64 it truncated a longer numeric
   to 63 digits -- a wrong magnitude, not a rounding nit. A double overflows
   past ~1.8e308, so 309 integer digits covers everything it can represent.
   Stack only: no cost on the sort comparator, which runs this per compare. */
#define TS_NUMBUF 512

PERL_STATIC_INLINE double ts_atof(const char *s, STRLEN len) {
    char b[TS_NUMBUF];
    STRLEN n = len < TS_NUMBUF - 1 ? len : TS_NUMBUF - 1;
    if (n) memcpy(b, s, n);
    b[n] = 0;
    return atof(b);
}
/* __attribute__ format so the compiler checks every call site too */
#ifdef __GNUC__
static void tpl_err(char *err, const char *fmt, ...) __attribute__((format(printf, 2, 3)));
#endif
static void tpl_err(char *err, const char *fmt, ...) {
    va_list ap;
    if (err[0]) return;              /* keep the first error */
    va_start(ap, fmt);
    vsnprintf(err, TS_ERRSZ, fmt, ap);
    va_end(ap);
    /* a truncating vsnprintf does not terminate on every libc */
    err[TS_ERRSZ - 1] = 0;
}

/* strict unsigned decimal; TS_NUM_BAD on a non-digit, TS_NUM_BIG if too big */
#define TS_NUM_BAD (-1)
#define TS_NUM_BIG (-2)
#define TS_NUM_MAX 100000000L
static int parse_uint_param(const char *p, int len) {
    long v = 0;
    if (len <= 0) return TS_NUM_BAD;
    for (int i = 0; i < len; i++) {
        if (p[i] < '0' || p[i] > '9') return TS_NUM_BAD;
        v = v * 10 + (p[i] - '0');
        if (v > TS_NUM_MAX) return TS_NUM_BIG;
    }
    return (int)v;
}

static void tpl_free(tpl_compiled *t) {
    if (t->header) free(t->header);
    if (t->footer) free(t->footer);
    if (t->sep) free(t->sep);
    if (t->render_buf) free(t->render_buf);
    if (t->skip_if_key) free(t->skip_if_key);
    if (t->skip_unless_key) free(t->skip_unless_key);
    for (int i = 0; i < t->nops; i++) {
        if (t->ops[i].static_data) free(t->ops[i].static_data);
        if (t->ops[i].key) free(t->ops[i].key);
        if (t->ops[i].chain) {
            for (int j = 0; j < t->ops[i].chain_len; j++) {
                tpl_xform *x = &t->ops[i].chain[j];
                if (x->param_str) free(x->param_str);
                if (x->param_str2) free(x->param_str2);
                /* Only the entry walk needs map_keys. Gating the four frees on
                   it too assumed the group is all-or-nothing: parse_xform
                   allocates them one at a time, so a failure on the FIRST left
                   the other three unreachable. free(NULL) is a no-op. */
                if (x->map_keys) {
                    for (int k = 0; k < x->map_count; k++) { free(x->map_keys[k]); free(x->map_vals[k]); }
                }
                free(x->map_keys); free(x->map_vals); free(x->map_key_lens); free(x->map_val_lens);
            }
            free(t->ops[i].chain);
        }
    }
    if (t->ops) free(t->ops);
    free(t);
}

/* malloc + copy + NUL, the shape repeated all through the compile path.
   Returns NULL and sets err on failure; every caller bails on NULL. Unchecked,
   each of these was a memcpy through NULL, so a failed allocation while
   compiling was a SIGSEGV. Compiling runs once per object, so the branch is
   not on any path that matters. */
static char *ts_dup_n(const char *src, STRLEN n, char *err) {
    char *p = (char *)malloc(n + 1);
    if (!p) { tpl_err(err, "out of memory"); return NULL; }
    if (n) memcpy(p, src, n);
    p[n] = '\0';
    return p;
}

/* parse "type" or "type:param" or "type:param1:param2" */
static tpl_xform parse_xform(const char *s, int len, char *err, char *soft) {
    int known = 1;   /* cleared below if the name matches no transform */
    tpl_xform x = {XF_RAW, 0, NULL, 0, NULL, 0, 0, NULL, NULL, NULL, NULL, 0};
    const char *colon = memchr(s, ':', len);
    int tlen = colon ? (int)(colon - s) : len;
    const char *param = colon ? colon + 1 : NULL;
    int plen = colon ? len - tlen - 1 : 0;

    if (tlen == 3 && memcmp(s, "int", 3) == 0) x.type = XF_INT;
    else if (tlen == 9 && memcmp(s, "int_comma", 9) == 0) x.type = XF_INT_COMMA;
    else if (tlen == 5 && memcmp(s, "float", 5) == 0) { x.type = XF_FLOAT; x.param_int = 2; }
    else if (tlen == 4 && memcmp(s, "html", 4) == 0) x.type = XF_HTML;
    else if (tlen == 7 && memcmp(s, "html_br", 7) == 0) x.type = XF_HTML_BR;
    else if (tlen == 3 && memcmp(s, "raw", 3) == 0) x.type = XF_RAW;
    else if (tlen == 3 && memcmp(s, "url", 3) == 0) x.type = XF_URL;
    else if (tlen == 4 && memcmp(s, "json", 4) == 0) x.type = XF_JSON;
    else if (tlen == 4 && memcmp(s, "trim", 4) == 0) x.type = XF_TRIM;
    else if (tlen == 2 && memcmp(s, "uc", 2) == 0) x.type = XF_UC;
    else if (tlen == 2 && memcmp(s, "lc", 2) == 0) x.type = XF_LC;
    else if (tlen == 3 && memcmp(s, "pad", 3) == 0) x.type = XF_PAD;
    else if (tlen == 4 && memcmp(s, "rpad", 4) == 0) x.type = XF_RPAD;
    else if (tlen == 5 && memcmp(s, "trunc", 5) == 0) x.type = XF_TRUNC;
    else if (tlen == 7 && memcmp(s, "default", 7) == 0) x.type = XF_DEFAULT;
    else if (tlen == 3 && memcmp(s, "hex", 3) == 0) x.type = XF_HEX;
    else if (tlen == 9 && memcmp(s, "base64url", 9) == 0) x.type = XF_BASE64URL;
    else if (tlen == 6 && memcmp(s, "base64", 6) == 0) x.type = XF_BASE64;
    else if (tlen == 5 && memcmp(s, "count", 5) == 0) x.type = XF_COUNT;
    else if (tlen == 4 && memcmp(s, "bool", 4) == 0) x.type = XF_BOOL;
    else if (tlen == 4 && memcmp(s, "date", 4) == 0) x.type = XF_DATE;
    else if (tlen == 7 && memcmp(s, "sprintf", 7) == 0) x.type = XF_SPRINTF;
    else if (tlen == 7 && memcmp(s, "replace", 7) == 0) x.type = XF_REPLACE;
    /* -1 length means "to the end", so a bare "substr" is the whole value */
    else if (tlen == 6 && memcmp(s, "substr", 6) == 0) { x.type = XF_SUBSTR; x.param_int2 = -1; }
    else if (tlen == 6 && memcmp(s, "plural", 6) == 0) x.type = XF_PLURAL;
    else if (tlen == 2 && memcmp(s, "if", 2) == 0) x.type = XF_IF;
    else if (tlen == 6 && memcmp(s, "unless", 6) == 0) x.type = XF_UNLESS;
    else if (tlen == 3 && memcmp(s, "map", 3) == 0) x.type = XF_MAP;
    else if (tlen == 4 && memcmp(s, "wrap", 4) == 0) x.type = XF_WRAP;
    else if (tlen == 9 && memcmp(s, "number_si", 9) == 0) x.type = XF_NUMBER_SI;
    else if (tlen == 8 && memcmp(s, "bytes_si", 8) == 0) x.type = XF_BYTES_SI;
    else if (tlen == 7 && memcmp(s, "elapsed", 7) == 0) x.type = XF_ELAPSED;
    else if (tlen == 3 && memcmp(s, "ago", 3) == 0) x.type = XF_AGO;
    else if (tlen == 4 && memcmp(s, "mask", 4) == 0) { x.type = XF_MASK; x.param_int = 4; }
    else if (tlen == 6 && memcmp(s, "length", 6) == 0) x.type = XF_LENGTH;
    else if (tlen == 8 && memcmp(s, "coalesce", 8) == 0) x.type = XF_COALESCE;
    /* An unknown name used to fall through as XF_RAW, so a typo in an escaping
       transform ("{0:hmtl}") silently emitted the value unescaped. */
    else {
        /* Deferred: a stray literal brace (".cls { color: red }") also lands here,
           and the mixed-mode check downstream explains that far better, so only
           surface this if nothing more specific goes wrong. */
        known = 0;
        if (tlen == 0) tpl_err(soft, "empty transform in chain (stray '|' or ':')");
        else tpl_err(soft, "unknown transform '%.*s'", tlen > TS_REFSZ ? TS_REFSZ : tlen, s);
    }

    if (param && plen == 0 && x.type == XF_DEFAULT) {
        x.param_str = ts_dup_n("", 0, err);
        if (!x.param_str) return x;
        x.param_str_len = 0;
    } else if (param && plen > 0) {
        if (x.type == XF_FLOAT || x.type == XF_PAD || x.type == XF_RPAD || x.type == XF_TRUNC || x.type == XF_MASK) {
            int v = parse_uint_param(param, plen);
            if (v == TS_NUM_BAD) {
                tpl_err(err, "'%.*s' takes a non-negative integer, got '%.*s'", tlen, s, plen, param);
                return x;
            }
            if (v == TS_NUM_BIG) {
                tpl_err(err, "'%.*s' parameter is too large (max %ld)", tlen, s, TS_NUM_MAX);
                return x;
            }
            /* an absurd precision only makes snprintf build a string to truncate */
            if (x.type == XF_FLOAT && v > 30) v = 30;
            x.param_int = v;
        } else if (x.type == XF_SPRINTF) {
            x.param_str = ts_dup_n(param, plen, err);
            if (!x.param_str) return x;
            x.param_str_len = plen;
        } else if (x.type == XF_REPLACE) {
            const char *c2 = memchr(param, ':', plen);
            /* "replace:OLD" deletes OLD; it used to set no needle and no-op */
            if (!c2) {
                x.param_str = ts_dup_n(param, plen, err);
                if (!x.param_str) return x;
                x.param_str_len = plen;
                x.param_str2 = ts_dup_n("", 0, err);
                if (!x.param_str2) return x;
                x.param_str2_len = 0;
            } else {
                int p1len = (int)(c2 - param);
                int p2len = plen - p1len - 1;
                if (p1len > 0) {
                    x.param_str = ts_dup_n(param, p1len, err);
                    if (!x.param_str) return x;
                    x.param_str_len = p1len;
                    x.param_str2 = ts_dup_n(c2 + 1, p2len, err);
                    if (!x.param_str2) return x;
                    x.param_str2_len = p2len;
                }
            }
        } else if (x.type == XF_SUBSTR) {
            const char *c2 = memchr(param, ':', plen);
            int p1len = c2 ? (int)(c2 - param) : plen;
            int v = 0;
            if (p1len > 0) {          /* "substr::N" means offset 0 */
                v = parse_uint_param(param, p1len);
                if (v == TS_NUM_BIG) {
                    tpl_err(err, "'substr' offset is too large (max %ld)", TS_NUM_MAX);
                    return x;
                }
                if (v < 0) {
                    tpl_err(err, "'substr' offset must be a non-negative integer, got '%.*s'", p1len, param);
                    return x;
                }
            }
            x.param_int = v;
            x.param_int2 = -1;
            if (c2) {
                int p2len = plen - p1len - 1;
                if (p2len > 0) {
                    v = parse_uint_param(c2 + 1, p2len);
                    if (v == TS_NUM_BIG) {
                        tpl_err(err, "'substr' length is too large (max %ld)", TS_NUM_MAX);
                        return x;
                    }
                    if (v < 0) {
                        tpl_err(err, "'substr' length must be a non-negative integer, got '%.*s'", p2len, c2 + 1);
                        return x;
                    }
                    x.param_int2 = v;
                }
            }
        } else if (x.type == XF_PLURAL) {
            const char *c2 = memchr(param, ':', plen);
            int p1len = c2 ? (int)(c2 - param) : plen;
            int p2len = c2 ? plen - p1len - 1 : -1;
            x.param_str = ts_dup_n(param, p1len, err);
            if (!x.param_str) return x;
            x.param_str_len = p1len;
            if (c2) {
                x.param_str2 = ts_dup_n(c2 + 1, p2len, err);
                if (!x.param_str2) return x;
                x.param_str2_len = p2len;
            } else {
                /* one form given: plural is that form plus "s" */
                x.param_str2 = (char *)malloc(p1len + 2);
                if (!x.param_str2) { tpl_err(err, "out of memory"); return x; }
                memcpy(x.param_str2, param, p1len);
                x.param_str2[p1len] = 's';
                x.param_str2[p1len + 1] = '\0';
                x.param_str2_len = p1len + 1;
            }
        } else if (x.type == XF_IF || x.type == XF_UNLESS) {
            x.param_str = ts_dup_n(param, plen, err);
            if (!x.param_str) return x;
            x.param_str_len = plen;
        } else if (x.type == XF_WRAP) {
            const char *c2 = memchr(param, ':', plen);
            if (c2) {
                int p1len = (int)(c2 - param);
                int p2len = plen - p1len - 1;
                x.param_str = ts_dup_n(param, p1len, err);
                if (!x.param_str) return x;
                x.param_str_len = p1len;
                x.param_str2 = ts_dup_n(c2 + 1, p2len, err);
                if (!x.param_str2) return x;
                x.param_str2_len = p2len;
            } else {
                x.param_str = ts_dup_n(param, plen, err);
                if (!x.param_str) return x;
                x.param_str_len = plen;
            }
        } else if (x.type == XF_MAP) {
            int cnt = 1;
            for (int i = 0; i < plen; i++) if (param[i] == ':') cnt++;
            x.map_keys = (char **)calloc(cnt, sizeof(char *));
            x.map_vals = (char **)calloc(cnt, sizeof(char *));
            x.map_key_lens = (STRLEN *)calloc(cnt, sizeof(STRLEN));
            x.map_val_lens = (STRLEN *)calloc(cnt, sizeof(STRLEN));
            /* all four or none: the loop below indexes them in lockstep, and
               tpl_free only walks them when map_count says there is something
               to walk, so leaving map_count at 0 here is safe to free */
            if (!x.map_keys || !x.map_vals || !x.map_key_lens || !x.map_val_lens) {
                tpl_err(err, "out of memory");
                return x;
            }
            x.map_count = 0;
            const char *p2 = param, *pe = param + plen;
            while (p2 < pe) {
                const char *next = memchr(p2, ':', pe - p2);
                if (!next) next = pe;
                const char *eq = memchr(p2, '=', next - p2);
                if (eq) {
                    int kl = (int)(eq - p2), vl = (int)(next - eq - 1);
                    int idx = x.map_count;
                    x.map_keys[idx] = ts_dup_n(p2, kl, err);
                    if (!x.map_keys[idx]) return x;
                    x.map_key_lens[idx] = kl;
                    x.map_vals[idx] = ts_dup_n(eq + 1, vl, err);
                    if (!x.map_vals[idx]) { free(x.map_keys[idx]); x.map_keys[idx] = NULL; return x; }
                    x.map_val_lens[idx] = vl;
                    /* bumped only once the pair is complete, so a half-built
                       entry is never handed to tpl_free */
                    x.map_count++;
                }
                p2 = next + 1;
            }
        } else if (x.type == XF_COALESCE) {
            x.param_str = ts_dup_n(param, plen, err);
            if (!x.param_str) return x;
            x.param_str_len = plen;
        } else if (x.type == XF_DEFAULT || x.type == XF_DATE) {
            x.param_str = ts_dup_n(param, plen, err);
            if (!x.param_str) return x;
            x.param_str_len = plen;
        } else if (x.type == XF_BOOL) {
            const char *c2 = memchr(param, ':', plen);
            if (c2) {
                int p1len = (int)(c2 - param);
                int p2len = plen - p1len - 1;
                x.param_str = ts_dup_n(param, p1len, err);
                if (!x.param_str) return x;
                x.param_str_len = p1len;
                x.param_str2 = ts_dup_n(c2 + 1, p2len, err);
                if (!x.param_str2) return x;
                x.param_str2_len = p2len;
            } else {
                x.param_str = ts_dup_n(param, plen, err);
                if (!x.param_str) return x;
                x.param_str_len = plen;
            }
        }
        /* Nothing above claimed the parameter, so this transform does not take
           one and it was about to be dropped on the floor -- the same silent
           no-op an unknown transform name and an unknown option are rejected
           for. Only for a name we recognise, though: an unknown one already has
           a better message waiting in `soft`, and a hard error here would
           preempt it and blame a transform that does not exist. */
        else if (known) {
            tpl_err(err, "'%.*s' takes no parameter, got '%.*s'",
                    tlen, s, plen, param);
            return x;
        }
    }
    return x;
}

/* Parse "{field:type1:p1|type2:p2}" into chain */
static void parse_field_spec(const char *spec, int spec_len,
                              tpl_op *op, enum row_mode *mode,
                              char *num_ref, char *key_ref, char *err, char *soft_err,
                              int tpl_key_utf8) {
    /* split field name from transform chain at first : or | */
    const char *sep = NULL;
    for (int i = 0; i < spec_len; i++) {
        if (spec[i] == ':' || spec[i] == '|') { sep = spec + i; break; }
    }

    const char *field = spec;
    int field_len = sep ? (int)(sep - spec) : spec_len;

    /* check for row number placeholder {#} */
    if (field_len == 1 && field[0] == '#') {
        op->is_rownum = 1;
        /* parse transform chain if any */
        if (!sep) {
            op->chain = (tpl_xform *)malloc(sizeof(tpl_xform));
            if (!op->chain) { tpl_err(err, "out of memory"); return; }
            op->chain[0] = ts_raw_xform;
            op->chain_len = 1;
            return;
        }
        goto parse_chain;
    }

    /* an empty name would otherwise become a "" hash key */
    if (field_len == 0) {
        tpl_err(err, "empty field reference in template");
        return;
    }

    /* detect array vs hash mode */
    int is_num = 1, is_neg = 0, start_idx = 0;
    if (field[0] == '-') { is_neg = 1; start_idx = 1; }
    for (int i = start_idx; i < field_len; i++)
        if (field[i] < '0' || field[i] > '9') { is_num = 0; break; }

    if (is_num && field_len > start_idx) {
        /* Check before multiplying, and in int: testing `long col > INT_MAX`
           afterwards never fires where long is 32 bits (ILP32, and Win64's
           LLP64), so the accumulation just wrapped to a wrong column. */
        /* Accumulate the magnitude unsigned: a negative index reaches one
           further than a positive one, and bounding both at INT_MAX rejected
           exactly INT_MIN -- which skip_if and the sort spec accept, so the
           same index was valid in one place and not another. */
        unsigned lim = (unsigned)INT_MAX + (is_neg ? 1u : 0u);
        unsigned col = 0;
        for (int i = start_idx; i < field_len; i++) {
            unsigned d = (unsigned)(field[i] - '0');
            if (col > (lim - d) / 10) {
                tpl_err(err, "column index '%.*s' is out of range", field_len, field);
                return;
            }
            col = col * 10 + d;
        }
        /* negate as unsigned, then convert: -(int)2147483648 would be UB */
        op->col = is_neg ? (int)(0u - col) : (int)col;
        if (!num_ref[0]) snprintf(num_ref, TS_REFSZ, "%.*s", field_len, field);
    } else {
        *mode = ROW_HASH;
        if (!key_ref[0]) snprintf(key_ref, TS_REFSZ, "%.*s", field_len, field);
        op->key = ts_dup_n(field, field_len, err);
        if (!op->key) return;
        op->key_len = field_len;
        op->key_utf8 = tpl_key_utf8;
    }

    /* parse transform chain */
    if (!sep) {
        op->chain = (tpl_xform *)malloc(sizeof(tpl_xform));
        if (!op->chain) { tpl_err(err, "out of memory"); return; }
        op->chain[0] = ts_raw_xform;
        op->chain_len = 1;
        return;
    }

parse_chain:;
    const char *xforms_start = spec + field_len;
    if (*xforms_start == ':' || *xforms_start == '|') xforms_start++;
    int xforms_len = spec_len - (int)(xforms_start - spec);

    /* count pipes to size the chain */
    int nxforms = 1;
    for (int i = 0; i < xforms_len; i++) if (xforms_start[i] == '|') nxforms++;

    op->chain = (tpl_xform *)malloc(nxforms * sizeof(tpl_xform));
    if (!op->chain) { tpl_err(err, "out of memory"); return; }
    op->chain_len = 0;

    const char *p = xforms_start;
    const char *xend = xforms_start + xforms_len;
    while (p < xend) {
        const char *pipe = memchr(p, '|', xend - p);
        if (!pipe) pipe = xend;
        /* stored even on error so tpl_free reclaims it */
        op->chain[op->chain_len++] = parse_xform(p, (int)(pipe - p), err, soft_err);
        if (err[0]) return;
        p = pipe + 1;
    }

    /* count/coalesce operate on the raw field value (array/hash size, or the
       first truthy field), so they are only meaningful as the first transform.
       Mid-chain they would silently emit "0"/nothing; reject at compile time. */
    for (int i = 1; i < op->chain_len; i++) {
        if (op->chain[i].type == XF_COUNT) {
            tpl_err(err, "'count' must be the first transform in a chain");
            return;
        }
        if (op->chain[i].type == XF_COALESCE) {
            tpl_err(err, "'coalesce' must be the first transform in a chain");
            return;
        }
    }
}

static tpl_compiled *tpl_compile(pTHX_ const char *header, STRLEN hlen,
                                  const char *row, STRLEN rlen,
                                  const char *footer, STRLEN flen,
                                  const char *sep, STRLEN slen,
                                  char esc_char, int tpl_utf8, char *err) {
    tpl_compiled *t = (tpl_compiled *)calloc(1, sizeof(tpl_compiled));
    if (!t) { tpl_err(err, "out of memory"); return NULL; }
    char soft_err[TS_ERRSZ]; soft_err[0] = '\0';
    /* these three are length-counted, not NUL-terminated, so they allocate
       exactly hlen/flen/slen rather than going through ts_dup_n */
    if (hlen) { t->header = (char *)malloc(hlen);
                if (!t->header) { tpl_err(err, "out of memory"); return t; }
                memcpy(t->header, header, hlen); } t->header_len = hlen;
    if (flen) { t->footer = (char *)malloc(flen);
                if (!t->footer) { tpl_err(err, "out of memory"); return t; }
                memcpy(t->footer, footer, flen); } t->footer_len = flen;
    if (slen) { t->sep = (char *)malloc(slen);
                if (!t->sep) { tpl_err(err, "out of memory"); return t; }
                memcpy(t->sep, sep, slen); t->sep_len = slen; }
    t->mode = ROW_ARRAY;
    t->escape_char = esc_char ? esc_char : '{';

    /* The row is split on raw bytes, so a delimiter above 0x7F cuts inside a
       multi-byte character of a decoded template -- from_file always decodes --
       and every piece stays flagged: render() and columns() then return SvUTF8
       strings whose bytes are not UTF-8, and uc() on them dies. Flagging the
       output as bytes would still leave columns() broken, so refuse instead.
       Byte templates are unaffected. */
    if ((unsigned char)t->escape_char >= 0x80 && (tpl_utf8 & TS_TPL_ROW)) {
        tpl_err(err, "escape_char must be an ASCII byte when the row template "
                     "is a character string");
        return t;
    }

    int cap = 16;
    t->ops = (tpl_op *)calloc(cap, sizeof(tpl_op));
    if (!t->ops) { tpl_err(err, "out of memory"); return t; }
    t->nops = 0;

    char close_char = (t->escape_char == '{') ? '}' : t->escape_char;
    if (t->escape_char == '[') close_char = ']';
    if (t->escape_char == '(') close_char = ')';
    if (t->escape_char == '<') close_char = '>';

    /* on failure t still owns everything built so far; the caller frees it */
    #define GROW_OPS() do { \
        if (t->nops >= cap) { \
            tpl_op *no = (tpl_op *)realloc(t->ops, (size_t)cap * 2 * sizeof(tpl_op)); \
            if (!no) { tpl_err(err, "out of memory"); return t; } \
            t->ops = no; memset(&t->ops[cap], 0, (size_t)cap * sizeof(tpl_op)); cap *= 2; \
        } \
    } while(0)

    char num_ref[TS_REFSZ] = "", key_ref[TS_REFSZ] = "";
    const char *p = row, *end = row + rlen;
    while (p < end) {
        const char *brace = memchr(p, t->escape_char, end - p);
        if (!brace) brace = end;
        if (brace > p) {
            GROW_OPS();
            tpl_op *op = &t->ops[t->nops++];
            memset(op, 0, sizeof(*op));
            op->static_data = (char *)malloc(brace - p);
            if (!op->static_data) { tpl_err(err, "out of memory"); return t; }
            memcpy(op->static_data, p, brace - p);
            op->static_len = brace - p;
        }
        if (brace >= end) break;

        /* doubled escape char (e.g. {{ ) = literal */
        if (brace + 1 < end && brace[1] == t->escape_char) {
            GROW_OPS();
            tpl_op *op = &t->ops[t->nops++];
            memset(op, 0, sizeof(*op));
            op->static_data = (char *)malloc(1);
            if (!op->static_data) { tpl_err(err, "out of memory"); return t; }
            op->static_data[0] = t->escape_char;
            op->static_len = 1;
            p = brace + 2;
            continue;
        }

        const char *close = memchr(brace + 1, close_char, end - brace - 1);
        if (!close) {
            tpl_err(err, "unclosed '%c' in row template"
                         " (offset %d; use '%c%c' for a literal delimiter)",
                    t->escape_char, (int)(brace - row),
                    t->escape_char, t->escape_char);
            return t;
        }

        GROW_OPS();
        tpl_op *op = &t->ops[t->nops++];
        memset(op, 0, sizeof(*op));
        parse_field_spec(brace + 1, (int)(close - brace - 1), op, &t->mode,
                         num_ref, key_ref, err, soft_err,
                         (tpl_utf8 & TS_TPL_ROW) ? 1 : 0);
        if (err[0]) return t;
        p = close + 1;
    }
    #undef GROW_OPS

    /* A flagged piece's high bytes are its own encoding, so only the pieces
       that arrived as bytes can rule out a character result */
    t->tpl_utf8 = tpl_utf8;
    t->tpl_high =
        (!(tpl_utf8 & TS_TPL_HDR) && t->header && has_high_byte(t->header, t->header_len))
     || (!(tpl_utf8 & TS_TPL_FTR) && t->footer && has_high_byte(t->footer, t->footer_len))
     || (!(tpl_utf8 & TS_TPL_SEP) && t->sep    && has_high_byte(t->sep,    t->sep_len))
     || (!(tpl_utf8 & TS_TPL_ROW) && has_high_byte(row, rlen));

    t->saw_num_ref = num_ref[0] ? 1 : 0;

    /* one row mode per template; name both offenders, since a stray literal
       delimiter in the text lands here */
    if (num_ref[0] && key_ref[0]) {
        tpl_err(err, "template mixes numeric {%s} and named {%s} field references"
                     " (use '%c%c' for a literal delimiter)",
                num_ref, key_ref, t->escape_char, t->escape_char);
        return t;
    }

    /* nothing more specific went wrong, so an unknown transform name stands */
    if (!err[0] && soft_err[0]) tpl_err(err, "%s", soft_err);
    return t;
}

/* ---- render ---- */

/* clamp rather than double past the top: where STRLEN is 32 bits the
   doubling wraps and under-reserves the buffer it is meant to grow */
#define TS_GROW(want) ((want) <= (STRLEN)-1 / 2 ? (want) * 2 : (STRLEN)-1)
#define BUF_ENSURE(need) do { if (pos + (need) > alloc) { alloc = TS_GROW(pos + (need)); buf = (char *)realloc(buf, alloc); if (!buf) croak("Text::Stencil: out of memory"); t->inflight = buf; } } while(0)
/* Say so rather than drop rows on a full disk or closed pipe; both callers
   keep the render buffer in `buf` */
#define FH_WRITE(fh, b, n) do { \
    SSize_t wrote_ = PerlIO_write(fh, (b), (n)); \
    if (wrote_ < 0 || (STRLEN)wrote_ != (STRLEN)(n) || PerlIO_error(fh)) { \
        int err_ = errno; \
        TS_INFLIGHT_DISARM(t); \
        free(buf); \
        croak("Text::Stencil: write failed: %s", Strerror(err_)); \
    } \
} while(0)

/* the length guard keeps memcpy(dst, NULL, 0) out of the empty header/footer paths */
#define BUF_WRITE(s, l) do { if (l) { BUF_ENSURE(l); memcpy(buf + pos, s, l); pos += l; } } while(0)

/* Pin a row for the duration of its render: skip tests and field rendering both
   run Perl (tie, overload, DESTROY) that can clear the slot, realloc AvARRAY or
   drop the caller's last reference. PL_sv_undef is exempt -- it is immortal, so
   it needs no pin, and sv_2mortal returns early for an immortal without
   registering it, which left the increment unmatched and leaked a reference per
   undef row. */
#define TS_PIN_ROW(sv) STMT_START { \
    if (LIKELY((sv) != &PL_sv_undef)) sv_2mortal(SvREFCNT_inc_simple_NN(sv)); \
} STMT_END

/* reusable buffer macros for render_buf */
#define TS_INFLIGHT_ARM(t) do { \
    SAVEPPTR((t)->inflight); \
    (t)->inflight = buf; \
    SAVEDESTRUCTOR_X(ts_free_inflight, (t)); \
} while(0)
/* the buffer is ours again (re-attached or already freed): stop tracking it */
#define TS_INFLIGHT_DISARM(t) ((t)->inflight = NULL)

#define RBUF_INIT(t, est) do { \
    if (t->render_buf && t->render_buf_alloc >= (est)) { \
        buf = t->render_buf; alloc = t->render_buf_alloc; \
    } else { \
        alloc = (est); buf = (char *)realloc(t->render_buf, alloc); \
        if (!buf) croak("Text::Stencil: out of memory"); \
        t->render_buf = buf; t->render_buf_alloc = alloc; \
    } \
    /* Detach the reusable buffer for the render's duration. The live buffer \
       lives only in the local `buf`; a BUF_ENSURE/render_field realloc can \
       move it, and a render path can croak (e.g. a row callback dies). \
       Leaving t->render_buf NULL until RBUF_FINISH guarantees DESTROY and the \
       next render never free/realloc a stale pointer. The detached buffer is \
       not orphaned by a croak: TS_INFLIGHT_ARM tracks it on the savestack, so \
       a tie, overload or callback that dies frees it on the way out. */ \
    t->render_buf = NULL; t->render_buf_alloc = 0; \
    pos = 0; \
} while(0)
/* a nested render may have re-attached its own buffer; free it, do not orphan it */
/* Hold on to the buffer for the next render, but not at any size: a one-off
   huge render would otherwise park hundreds of MB on the object for the life
   of the process. Give back anything wildly larger than the render actually
   used; a failed shrink is not an error, we simply keep what we have. */
#define TS_RBUF_KEEP (1u << 20)

/* An up-front guess, not a commitment: 300 bytes a row overshoots badly on
   short rows (a 7.5MB render reserved 294MB), and BUF_ENSURE grows the buffer
   anyway. Cap the guess and let it grow into whatever the render really needs. */
static STRLEN ts_est(STRLEN fixed, SSize_t nrows) {
    STRLEN est = nrows > 0 ? (STRLEN)nrows * 300 : 0;
    if (nrows > 0 && est / 300 != (STRLEN)nrows) est = TS_RBUF_KEEP;   /* overflowed */
    if (est > TS_RBUF_KEEP) est = TS_RBUF_KEEP;
    return fixed + est + 1;
}
#define RBUF_FINISH(t) do { \
    if (t->render_buf) free(t->render_buf); \
    if (alloc > TS_RBUF_KEEP && alloc / 4 > pos + 1) { \
        STRLEN want_ = (pos + 1) < TS_RBUF_KEEP ? TS_RBUF_KEEP : (pos + 1); \
        char *small_ = (char *)realloc(buf, want_); \
        if (small_) { buf = small_; alloc = want_; } \
    } \
    t->render_buf = buf; t->render_buf_alloc = alloc; \
} while(0)

/* AvARRAY is NULL on a magical AV (tied, @-/@+) even though av_top_index() is
   the real length, so those must go through av_fetch. */
PERL_STATIC_INLINE SV *av_element(pTHX_ AV *av, int col) {
    SSize_t top = av_top_index(av);
    if (col < 0) col = (int)(top + 1) + col;
    if (col < 0 || col > (int)top) return NULL;
    if (UNLIKELY(SvRMAGICAL((SV *)av))) {
        /* a tied array hands back an unmaterialised PVLV */
        SV **s = av_fetch(av, col, 0);
        if (!s || !*s) return NULL;
        SvGETMAGIC(*s);
        return *s;
    }
    {
        /* the AV can be plain while an element is not: `tie $row[0], ...` puts
           the magic on the element, and reading it raw skips FETCH */
        SV **ary = AvARRAY(av);
        SV *e = ary ? ary[col] : NULL;
        if (e) SvGETMAGIC(e);
        return e;
    }
}

/* Buffer the format is assembled in; a format that will not fit is one we do
   not handle, so the size belongs with the check that rejects it. */
#define TS_FMTBUF 64

/* The conversion character of a sprintf format we actually support, or 0 for
   anything else. Both the formatter and the caller that decides how to numify
   the value ask this, so they can never disagree about what a format means.
   Walk %[flags][width][.precision]<conv>, insisting the conversion is last: the
   pushed argument is chosen from that character, so "%sx" or "%d_s" would hand
   printf the wrong type. '$', '*' and length modifiers fail the same test. */
static char ts_sprintf_conv(const char *f) {
    STRLEN fi, flen;
    int wdigits = 0, pdigits = 0;
    char last;
    if (!f) return 0;
    /* measure it the way the formatter does -- it builds the format with
       snprintf("%s"), so the NUL is what bounds it, not any stored length */
    flen = strlen(f);
    if (flen < 1) return 0;
    /* a format that will not fit in the assembly buffer is one we do not
       handle; the .%. is added when absent, so count it either way */
    if ((f[0] == '%' ? flen : flen + 1) + 3 > (STRLEN)TS_FMTBUF) return 0;
    fi = (f[0] == '%') ? 1 : 0;
    while (fi < flen && (f[fi] == '-' || f[fi] == '+' ||
                         f[fi] == ' ' || f[fi] == '#' || f[fi] == '0')) fi++;
    while (fi < flen && f[fi] >= '0' && f[fi] <= '9') { fi++; wdigits++; }
    if (fi < flen && f[fi] == '.') {
        fi++;
        while (fi < flen && f[fi] >= '0' && f[fi] <= '9') { fi++; pdigits++; }
    }
    if (fi != flen - 1 || wdigits > 8 || pdigits > 8) return 0;
    last = f[fi];
    if (last == 'd' || last == 'i' || last == 'x' || last == 'X' ||
        last == 'o' || last == 'u' || last == 'f' || last == 'e' ||
        last == 'g' || last == 's') return last;
    return 0;
}

/* Own the bytes of a template piece. Pinning the argument SV keeps it alive
   but not its buffer: stringifying a later argument can run an overload that
   grows an earlier one in place, freeing the PV we were still holding. */
static const char *ts_own_pv(pTHX_ SV *sv, STRLEN *lenp, int *utf8p) {
    STRLEN l;
    const char *p = SvPV(sv, l);
    /* take the encoding from the same call that produced the bytes: an overload
       returns its own string, whose flag has nothing to do with the RV's */
    if (utf8p) *utf8p = SvUTF8(sv) ? 1 : 0;
    SV *owned = sv_2mortal(newSVpvn(p, l));
    *lenp = l;
    return SvPVX(owned);
}

/* Install a skip-condition key on a template that no SV owns yet: the croak
   has to reclaim it, or a failed allocation strands the whole thing. All four
   call sites -- new's two and clone's two -- were this same sequence. */
static void ts_set_skip_key(pTHX_ tpl_compiled *t, char **dst, STRLEN *lenp,
                            int *utf8p, const char *src, STRLEN len, int utf8) {
    char *p = (char *)malloc(len + 1);
    if (!p) { tpl_free(t); croak("Text::Stencil: out of memory"); }
    if (len) memcpy(p, src, len);
    p[len] = '\0';
    *dst = p; *lenp = len; *utf8p = utf8;
}

/* Column indices are ints. A wider IV would narrow onto some unrelated valid
   column, so reject it the way an out-of-range template index is rejected.
   Every caller resolves its columns before tpl_compile runs, so there is never
   a half-built template for the croak to strand. */
static int ts_col_iv(pTHX_ IV v, const char *what) {
    if (v > INT_MAX || v < INT_MIN) {
        croak("Text::Stencil: %s column index %" IVdf " is out of range", what, v);
    }
    return (int)v;
}

/* Same check, but from the SV: SvIV has already saturated or wrapped by the
   time we see it, so "99999999999999999999" arrives as -1 and would quietly
   become the last column. The NV still knows how big the value really was. */
static int ts_col_sv(pTHX_ SV *sv, const char *what) {
    NV nv = SvNV(sv);
    if (!(nv >= (NV)INT_MIN && nv <= (NV)INT_MAX)) {   /* false for NaN too */
        croak("Text::Stencil: %s column index '%s' is out of range",
              what, SvPV_nolen(sv));
    }
    return ts_col_iv(aTHX_ SvIV(sv), what);
}

PERL_STATIC_INLINE SV *fetch_field(pTHX_ SV *row_sv, tpl_op *op, enum row_mode mode) {
    SvGETMAGIC(row_sv);          /* the row itself may come from a magical array */
    if (!SvROK(row_sv)) return NULL;
    if (mode == ROW_HASH) {
        if (SvTYPE(SvRV(row_sv)) != SVt_PVHV || !op->key) return NULL;
        /* a positive klen only matches non-UTF8 HEKs, so a key taken from a
           flagged template never matched a flagged hash key */
        SV **sv = hv_fetch((HV *)SvRV(row_sv), op->key,
                           op->key_utf8 ? -(I32)op->key_len : (I32)op->key_len, 0);
        if (!sv || !*sv) return NULL;
        SvGETMAGIC(*sv);
        return *sv;
    } else {
        if (SvTYPE(SvRV(row_sv)) != SVt_PVAV) return NULL;
        return av_element(aTHX_ (AV *)SvRV(row_sv), op->col);
    }
}

/* Apply a single transform, writing result to buf+pos or tmp */
/* a slice at byte offset `at` splits a character if a continuation byte lands
   there -- O(1), and pure-ASCII values can never trip it */
#define TS_NOTE_CUT(t, s, len, at) do { \
    STRLEN a_ = (STRLEN)(at); \
    if (a_ < (len) && ((unsigned char)(s)[a_] & 0xC0) == 0x80) (t)->r_high = 1; \
} while(0)

/* SI tiers, index 0 the bare unit.  Choosing by magnitude alone let rounding
   spill out of the tier: "999.6" printed 1000 with no suffix */
static const double si_dec[] = {1.0, 1e3, 1e6, 1e9, 1e12, 1e15};
static const char  *si_dec_suf[] = {"", "K", "M", "G", "T", "P"};
static const double si_bin[] = {1.0, 1024.0, 1048576.0, 1073741824.0,
                                1099511627776.0, 1125899906842624.0,
                                1152921504606846976.0};
static const char  *si_bin_suf[] = {"B", "KB", "MB", "GB", "TB", "PB", "EB"};

static int si_tier(double v, const double *div, int top) {
    double av = v < 0 ? -v : v;
    int ti = 0;
    while (ti < top && av >= div[ti + 1]) ti++;
    if (ti < top) {
        /* tier 0 prints %.0f, the rest %.1f, so they round at different edges */
        double ratio = div[ti + 1] / div[ti];
        if (av / div[ti] >= ratio - (ti ? 0.05 : 0.5)) ti++;
    }
    return ti;
}

static void apply_xform(tpl_compiled *t, tpl_xform *xf, const char *src, STRLEN slen,
                         char **bufp, STRLEN *posp, STRLEN *allocp,
                         char **tmpp, STRLEN *tmp_lenp, STRLEN *tmp_allocp,
                         int to_output) {
    char *buf = *bufp; STRLEN pos = *posp; STRLEN alloc = *allocp;
    char *tmp = *tmpp; STRLEN tmp_len = *tmp_lenp; STRLEN tmp_alloc = *tmp_allocp;

    /* macro to write to either output or temp */
    #define OUT_ENSURE(n) do { \
        if (to_output) { BUF_ENSURE(n); } \
        else { if ((STRLEN)(n) > tmp_alloc || !tmp) { tmp_alloc = (n) < 1 ? 1 : TS_GROW((STRLEN)(n)); tmp = (char *)realloc(tmp, tmp_alloc); if (!tmp) croak("Text::Stencil: out of memory"); } } \
    } while(0)
    /* A transform whose output is a multiple of its input must reserve that
       multiple. Where STRLEN is 32 bits the product can wrap while the input
       is still under the 2GB passthrough limit, which would under-reserve the
       buffer and let the transform write past it -- so refuse instead. */
    #define TS_OUT_ENSURE_MUL(n, m) do { \
        STRLEN n_ = (STRLEN)(n), m_ = (STRLEN)(m); \
        if (m_ && n_ > (STRLEN)-1 / m_) croak("Text::Stencil: value too large to transform"); \
        OUT_ENSURE(n_ * m_); \
    } while(0)
    #define OUT_PTR (to_output ? buf + pos : tmp)
    /* Every transform ends by publishing how much it wrote, to whichever of the
       two destinations OUT_PTR selected. It was spelled out 46 times. */
    #define OUT_COMMIT(n) do { if (to_output) pos += (n); else tmp_len = (n); } while (0)
    /* and nine of them are exactly "emit the input unchanged" */
    #define OUT_PASSTHRU() do { OUT_ENSURE(slen); memcpy(OUT_PTR, src, slen); OUT_COMMIT(slen); } while (0)

    /* the widths below are ints; past INT_MAX one wraps negative and corrupts
       the write offset, and no transform has a useful answer for 2GB anyway */
    if (UNLIKELY(slen > (STRLEN)INT_MAX)) {
        OUT_PASSTHRU();
        goto done;
    }

    switch (xf->type) {
    case XF_INT: {
        OUT_ENSURE(20);
        int neg = ts_has_minus(src, slen);
        IV v = ts_scan_iv(src, slen, neg);
        int w = itoa_fast(OUT_PTR, v);
        OUT_COMMIT(w);
        break;
    }
    case XF_INT_COMMA: {
        OUT_ENSURE(28);
        int neg = ts_has_minus(src, slen);
        IV v = ts_scan_iv(src, slen, neg);
        int w = itoa_comma(OUT_PTR, v);
        OUT_COMMIT(w);
        break;
    }
    case XF_FLOAT: {
        OUT_ENSURE(TS_FLTSZ);
        double fv = ts_atof(src, slen);
        int w = snprintf(OUT_PTR, TS_FLTSZ, "%.*f", xf->param_int, fv);
        if (w > TS_FLTSZ - 1) w = TS_FLTSZ - 1;
        OUT_COMMIT(w);
        break;
    }
    case XF_HTML: {
        TS_OUT_ENSURE_MUL(slen, 6);
        int needs_escape = 0;
        for (STRLEN i = 0; i < slen; i++)
            if (html_special[(unsigned char)src[i]]) { needs_escape = 1; break; }
        if (!needs_escape) {
            memcpy(OUT_PTR, src, slen);
            OUT_COMMIT(slen);
        } else {
            STRLEN w = html_escape(OUT_PTR, src, slen);
            OUT_COMMIT(w);
        }
        break;
    }
    case XF_HTML_BR: {
        TS_OUT_ENSURE_MUL(slen, 6);
        int needs_escape = 0;
        for (STRLEN i = 0; i < slen; i++)
            if (html_br_special[(unsigned char)src[i]]) { needs_escape = 1; break; }
        if (!needs_escape) {
            memcpy(OUT_PTR, src, slen);
            OUT_COMMIT(slen);
        } else {
            STRLEN w = html_br_escape(OUT_PTR, src, slen);
            OUT_COMMIT(w);
        }
        break;
    }
    case XF_URL: {
        TS_OUT_ENSURE_MUL(slen, 3);
        STRLEN w = url_escape(OUT_PTR, src, slen);
        OUT_COMMIT(w);
        break;
    }
    case XF_JSON: {
        TS_OUT_ENSURE_MUL(slen, 6);
        int needs_escape = 0;
        for (STRLEN i = 0; i < slen; i++)
            if (json_special[(unsigned char)src[i]]) { needs_escape = 1; break; }
        if (!needs_escape) {
            memcpy(OUT_PTR, src, slen);
            OUT_COMMIT(slen);
        } else {
            STRLEN w = json_escape(OUT_PTR, src, slen);
            OUT_COMMIT(w);
        }
        break;
    }
    case XF_TRIM: {
        const char *s = src; STRLEN l = slen;
        while (l > 0 && (*s == ' ' || *s == '\t' || *s == '\n' || *s == '\r')) { s++; l--; }
        while (l > 0 && (s[l-1] == ' ' || s[l-1] == '\t' || s[l-1] == '\n' || s[l-1] == '\r')) l--;
        OUT_ENSURE(l);
        memcpy(OUT_PTR, s, l);
        OUT_COMMIT(l);
        break;
    }
    /* ASCII-only by hand: toupper/tolower follow LC_CTYPE, and in an 8-bit
       locale glibc maps 0xE0-0xFE onto 0xC0-0xDE -- UTF-8 lead bytes -- which
       turned a flagged value into malformed UTF-8 */
    case XF_UC: {
        OUT_ENSURE(slen);
        for (STRLEN i = 0; i < slen; i++) {
            unsigned char c = (unsigned char)src[i];
            OUT_PTR[i] = (c >= 'a' && c <= 'z') ? (char)(c - 32) : (char)c;
        }
        OUT_COMMIT(slen);
        break;
    }
    case XF_LC: {
        OUT_ENSURE(slen);
        for (STRLEN i = 0; i < slen; i++) {
            unsigned char c = (unsigned char)src[i];
            OUT_PTR[i] = (c >= 'A' && c <= 'Z') ? (char)(c + 32) : (char)c;
        }
        OUT_COMMIT(slen);
        break;
    }
    case XF_PAD: {
        int w = xf->param_int;   /* compile-time validated non-negative */
        OUT_ENSURE((STRLEN)(w > (int)slen ? w : (int)slen));
        int pad = w - (int)slen;
        if (pad > 0) { memset(OUT_PTR, ' ', pad); memcpy(OUT_PTR + pad, src, slen); }
        else memcpy(OUT_PTR, src, slen);
        int total = pad > 0 ? w : (int)slen;
        OUT_COMMIT(total);
        break;
    }
    case XF_RPAD: {
        int w = xf->param_int;   /* compile-time validated non-negative */
        OUT_ENSURE((STRLEN)(w > (int)slen ? w : (int)slen));
        memcpy(OUT_PTR, src, slen);
        int pad = w - (int)slen;
        if (pad > 0) memset(OUT_PTR + slen, ' ', pad);
        int total = pad > 0 ? w : (int)slen;
        OUT_COMMIT(total);
        break;
    }
    case XF_TRUNC: {
        int mx = xf->param_int;
        if (mx < 0) mx = 0;
        if ((int)slen <= mx) {
            OUT_PASSTHRU();
        } else if (mx <= 3) {
            /* no room for the ellipsis: hard cut, never longer than asked */
            TS_NOTE_CUT(t, src, slen, mx);
            OUT_ENSURE(mx); memcpy(OUT_PTR, src, mx);
            OUT_COMMIT(mx);
        } else {
            int tl = mx - 3;
            TS_NOTE_CUT(t, src, slen, tl);
            OUT_ENSURE(tl + 3);
            memcpy(OUT_PTR, src, tl);
            memcpy(OUT_PTR + tl, "...", 3);
            OUT_COMMIT(tl + 3);
        }
        break;
    }
    case XF_HEX: {
        TS_OUT_ENSURE_MUL(slen, 2);
        STRLEN w = hex_encode(OUT_PTR, src, slen);
        OUT_COMMIT(w);
        break;
    }
    case XF_BASE64: {
        OUT_ENSURE(((slen + 2) / 3) * 4);
        STRLEN w = base64_encode(OUT_PTR, (const unsigned char *)src, slen);
        OUT_COMMIT(w);
        break;
    }
    case XF_BASE64URL: {
        OUT_ENSURE(((slen + 2) / 3) * 4);
        STRLEN w = base64url_encode(OUT_PTR, (const unsigned char *)src, slen);
        OUT_COMMIT(w);
        break;
    }
    case XF_COUNT: {
        /* Reached by {#:count}: render_field handles count itself, but that
           handler is gated on !is_rownum, and param_int is 0 -- which is what
           count documents for a scalar, so the row number lands right. An
           undef field used to arrive here too, via use_default, and printed 0
           over whatever default had supplied; render_field now drops the
           count stage in that case instead. */
        OUT_ENSURE(12);
        int w = itoa_fast(OUT_PTR, xf->param_int);
        OUT_COMMIT(w);
        break;
    }
    case XF_BOOL: {
        int truthy = (slen > 0);
        if (slen == 1 && src[0] == '0') truthy = 0;
        const char *val; STRLEN vlen;
        if (truthy) {
            val = xf->param_str ? xf->param_str : "true";
            vlen = xf->param_str ? xf->param_str_len : 4;
        } else {
            val = xf->param_str2 ? xf->param_str2 : "false";
            vlen = xf->param_str2 ? xf->param_str2_len : 5;
        }
        OUT_ENSURE(vlen); memcpy(OUT_PTR, val, vlen);
        OUT_COMMIT(vlen);
        break;
    }
    case XF_DATE: {
        /* gmtime_r leaves tm untouched when it fails, so bound the epoch and
           check the result before strftime reads it */
        long long e = 0; int bad = 0;
        for (STRLEN i = 0; i < slen; i++) {
            if (src[i] >= '0' && src[i] <= '9') {
                if (e > (LLONG_MAX - 9) / 10) { bad = 1; break; }
                e = e * 10 + (src[i] - '0');
            }
        }
        struct tm tm;
        time_t epoch = (time_t)e;
        if (bad || (long long)epoch != e || !ts_gmtime(&epoch, &tm)) {
            if (!to_output) tmp_len = 0;
            break;
        }
        const char *fmt = xf->param_str ? xf->param_str : "%Y-%m-%d %H:%M:%S";
        /* strftime reports "too big" as 0, which is also a legitimately empty
           result, so grow rather than render nothing */
        STRLEN cap = 256;
        size_t w = 0;
        while (1) {
            OUT_ENSURE(cap);
            w = strftime(OUT_PTR, cap, fmt, &tm);
            if (w || cap >= 8192) break;
            cap *= 4;
        }
        /* %B/%A/%c/%p emit locale text, which in an 8-bit LC_TIME is not UTF-8;
           we cannot judge it here, so make the final validation settle it */
        if (w) t->r_skipped = 1;
        OUT_COMMIT(w);
        break;
    }
    case XF_SPRINTF: {

        if (!xf->param_str || xf->param_str_len == 0) {   /* no format: passthrough */
            OUT_PASSTHRU();
        } else {
            /* One definition decides what a format means. render_field asks the
               same question before numifying the value, and if the two answers
               ever differed the value it passes through here would arrive
               already converted. */
            char last = ts_sprintf_conv(xf->param_str);
            if (!last) {
                OUT_PASSTHRU();
                break;
            }
            char fmtbuf[TS_FMTBUF];
            int fmtlen = snprintf(fmtbuf, sizeof(fmtbuf), "%s%s",
                xf->param_str[0] == '%' ? "" : "%", xf->param_str);
            if (fmtlen < 0 || fmtlen + 2 > (int)sizeof(fmtbuf)) {
                OUT_PASSTHRU();
                break;
            }
            int is_int = (last == 'd' || last == 'i' || last == 'x' ||
                          last == 'X' || last == 'o' || last == 'u');
            if (is_int) {
                /* Use perl's own length modifier rather than a bare 'l': an IV
                   is not always a C long (Win64, ILP32 with 64-bit ints), and
                   there %ld would print half the value we pass. */
                const char *conv = (last == 'd' || last == 'i') ? IVdf
                                 : (last == 'u') ? UVuf
                                 : (last == 'o') ? UVof
                                 : (last == 'X') ? UVXf : UVxf;
                size_t clen = strlen(conv);
                if ((size_t)fmtlen + clen >= sizeof(fmtbuf)) {
                    OUT_PASSTHRU();
                    break;
                }
                memcpy(fmtbuf + fmtlen - 1, conv, clen);
                fmtlen = fmtlen - 1 + (int)clen;
                fmtbuf[fmtlen] = '\0';
            }
            /* %s needs a NUL-terminated copy; only a long value takes the heap */
            char stackbuf[256];
            IV lv = 0; double dv = 0;
            char *sv_heap = NULL; const char *sv_tb = NULL;
            if (is_int) {
                int neg = ts_has_minus(src, slen);
                lv = ts_scan_iv(src, slen, neg);
            } else if (last == 'f' || last == 'e' || last == 'g') {
                dv = ts_atof(src, slen);
            } else if (slen < sizeof(stackbuf)) {
                /* a precision on %s cuts bytes, and the padded output width is
                   not the cut offset, so leave it to the final validation */
                t->r_skipped = 1;
                memcpy(stackbuf, src, slen); stackbuf[slen] = 0;
                sv_tb = stackbuf;
            } else {
                t->r_skipped = 1;
                sv_heap = (char *)malloc(slen + 1);
                if (!sv_heap) croak("Text::Stencil: out of memory");
                memcpy(sv_heap, src, slen); sv_heap[slen] = 0;
                sv_tb = sv_heap;
            }
            /* size the output from the formatted length */
            #define TS_SPRINTF(dst, cap) (is_int ? snprintf(dst, cap, fmtbuf, lv) \
                : sv_tb ? snprintf(dst, cap, fmtbuf, sv_tb) : snprintf(dst, cap, fmtbuf, dv))
            int w = TS_SPRINTF((char *)NULL, 0);
            if (w < 0) w = 0;
            OUT_ENSURE((STRLEN)w + 1);
            w = TS_SPRINTF(OUT_PTR, (size_t)w + 1);
            if (w < 0) w = 0;
            #undef TS_SPRINTF
            if (sv_heap) free(sv_heap);
            OUT_COMMIT(w);
        }
        break;
    }
    case XF_REPLACE: {
        if (!xf->param_str) {
            OUT_PASSTHRU();
            break;
        }
        const char *needle = xf->param_str;
        STRLEN nlen = xf->param_str_len;
        const char *repl = xf->param_str2 ? xf->param_str2 : "";
        STRLEN rlen = xf->param_str2 ? xf->param_str2_len : 0;
        TS_OUT_ENSURE_MUL(slen, rlen + 1);
        char *out = OUT_PTR;
        STRLEN opos = 0;
        STRLEN i = 0;
        while (i < slen) {
            if (i + nlen <= slen && memcmp(src + i, needle, nlen) == 0) {
                memcpy(out + opos, repl, rlen); opos += rlen;
                i += nlen;
            } else {
                out[opos++] = src[i++];
            }
        }
        OUT_COMMIT(opos);
        break;
    }
    case XF_SUBSTR: {
        int start = xf->param_int;
        int maxlen = xf->param_int2;
        if (start < 0 || start >= (int)slen) {
            if (!to_output) tmp_len = 0;
            break;
        }
        const char *s = src + start;
        STRLEN l = slen - start;
        if (maxlen >= 0 && (int)l > maxlen) l = maxlen;
        if (l) {                                   /* nothing emitted, nothing cut */
            TS_NOTE_CUT(t, src, slen, start);      /* starts mid-character? */
            TS_NOTE_CUT(t, src, slen, start + l);  /* ends mid-character? */
        }
        OUT_ENSURE(l); memcpy(OUT_PTR, s, l);
        OUT_COMMIT(l);
        break;
    }
    case XF_PLURAL: {
        /* a leading .-. is the sign; -1 is plural, and itoa keeps the .-. */
        STRLEN pi = (slen > 0 && src[0] == '-') ? 1 : 0;
        IV v = ts_scan_iv(src + pi, slen - pi, pi ? 1 : 0);
        const char *form; STRLEN flen;
        if (v == 1) {
            form = xf->param_str ? xf->param_str : ""; flen = xf->param_str_len;
        } else {
            form = xf->param_str2 ? xf->param_str2 : "s"; flen = xf->param_str2 ? xf->param_str2_len : 1;
        }
        OUT_ENSURE(20 + 1 + flen);
        int nw = itoa_fast(OUT_PTR, v);
        OUT_PTR[nw] = ' ';
        memcpy(OUT_PTR + nw + 1, form, flen);
        STRLEN total = (STRLEN)nw + 1 + flen;
        OUT_COMMIT(total);
        break;
    }
    case XF_IF: {
        int truthy = (slen > 0 && !(slen == 1 && src[0] == '0'));
        if (truthy && xf->param_str) {
            OUT_ENSURE(xf->param_str_len);
            memcpy(OUT_PTR, xf->param_str, xf->param_str_len);
            OUT_COMMIT(xf->param_str_len);
        } else {
            if (!to_output) tmp_len = 0;
        }
        break;
    }
    case XF_UNLESS: {
        int truthy = (slen > 0 && !(slen == 1 && src[0] == '0'));
        if (!truthy && xf->param_str) {
            OUT_ENSURE(xf->param_str_len);
            memcpy(OUT_PTR, xf->param_str, xf->param_str_len);
            OUT_COMMIT(xf->param_str_len);
        } else {
            if (!to_output) tmp_len = 0;
        }
        break;
    }
    case XF_MAP: {
        const char *val = src; STRLEN vlen = slen;
        for (int mi = 0; mi < xf->map_count; mi++) {
            if ((xf->map_key_lens[mi] == slen && memcmp(xf->map_keys[mi], src, slen) == 0) ||
                (xf->map_key_lens[mi] == 1 && xf->map_keys[mi][0] == '*')) {
                val = xf->map_vals[mi]; vlen = xf->map_val_lens[mi];
                if (xf->map_key_lens[mi] != 1 || xf->map_keys[mi][0] != '*') break;
            }
        }
        OUT_ENSURE(vlen); memcpy(OUT_PTR, val, vlen);
        OUT_COMMIT(vlen);
        break;
    }
    case XF_WRAP: {
        if (slen > 0 && !xf->param_str) {
            /* no prefix/suffix given: pass the value through */
            OUT_PASSTHRU();
        } else if (slen > 0 && xf->param_str) {
            STRLEN plen2 = xf->param_str_len + slen + (xf->param_str2 ? xf->param_str2_len : 0);
            OUT_ENSURE(plen2);
            memcpy(OUT_PTR, xf->param_str, xf->param_str_len);
            /* STRLEN, not int: the guard above caps slen at INT_MAX, but this
               is the one accumulator that ADDS to slen, so a prefix on a value
               near the cap overflowed to negative and turned the length into
               ~SIZE_MAX. Reachable without a 2GB scalar in hand: hex doubles a
               1GB field to just under INT_MAX before wrap ever sees it. */
            STRLEN wpos = xf->param_str_len;
            memcpy(OUT_PTR + wpos, src, slen); wpos += slen;
            if (xf->param_str2) { memcpy(OUT_PTR + wpos, xf->param_str2, xf->param_str2_len); wpos += xf->param_str2_len; }
            OUT_COMMIT(wpos);
        } else {
            if (!to_output) tmp_len = 0;
        }
        break;
    }
    case XF_NUMBER_SI: {
        double v = ts_atof(src, slen);
        {   /* a 32-byte cap chopped huge values mid-digit and dropped the suffix */
            int ti = si_tier(v, si_dec, 5);
            int w = ti ? snprintf(NULL, 0, "%.1f%s", v / si_dec[ti], si_dec_suf[ti])
                       : snprintf(NULL, 0, "%.0f", v);
            if (w < 0) w = 0;
            OUT_ENSURE((STRLEN)w + 1);
            w = ti ? snprintf(OUT_PTR, (size_t)w + 1, "%.1f%s", v / si_dec[ti], si_dec_suf[ti])
                   : snprintf(OUT_PTR, (size_t)w + 1, "%.0f", v);
            if (w < 0) w = 0;
            OUT_COMMIT(w);
        }
        break;
    }
    case XF_BYTES_SI: {
        double v = ts_atof(src, slen);
        {
            int ti = si_tier(v, si_bin, 6);
            int w = ti ? snprintf(NULL, 0, "%.1f %s", v / si_bin[ti], si_bin_suf[ti])
                       : snprintf(NULL, 0, "%.0f B", v);
            if (w < 0) w = 0;
            OUT_ENSURE((STRLEN)w + 1);
            w = ti ? snprintf(OUT_PTR, (size_t)w + 1, "%.1f %s", v / si_bin[ti], si_bin_suf[ti])
                   : snprintf(OUT_PTR, (size_t)w + 1, "%.0f B", v);
            if (w < 0) w = 0;
            OUT_COMMIT(w);
        }
        break;
    }
    case XF_ELAPSED: {
        /* junk in, but not negative out */
        IV v = ts_scan_iv(src, slen, 0);
        OUT_ENSURE(64);
        int w = 0;
        if (v >= 86400 && w < 63) { int n = snprintf(OUT_PTR + w, 64 - w, "%" IVdf "d ", v / 86400); if (n > 0) w += n; v %= 86400; }
        if (v >= 3600 && w < 63)  { int n = snprintf(OUT_PTR + w, 64 - w, "%" IVdf "h ", v / 3600);  if (n > 0) w += n; v %= 3600; }
        if (v >= 60 && w < 63)    { int n = snprintf(OUT_PTR + w, 64 - w, "%" IVdf "m ", v / 60);    if (n > 0) w += n; v %= 60; }
        if (w < 63) { int n = snprintf(OUT_PTR + w, 64 - w, "%" IVdf "s", v); if (n > 0) w += n; }
        if (w > 63) w = 63;
        OUT_COMMIT(w);
        break;
    }
    case XF_AGO: {
        time_t now = time(NULL);
        long long e = 0;
        for (STRLEN i = 0; i < slen; i++)
            if (src[i] >= '0' && src[i] <= '9') {
                if (e > (LLONG_MAX - 9) / 10) break;
                e = e * 10 + (src[i] - '0');
            }
        time_t epoch = (time_t)e;
        /* the same round-trip date does: where time_t is 32 bits an epoch past
           2038 silently wraps negative, and "124y ago" is a worse answer than
           admitting the value is out of range */
        if ((long long)epoch != e) {
            if (!to_output) tmp_len = 0;
            break;
        }
        IV diff = (IV)(now - epoch);
        OUT_ENSURE(32);
        int w;
        if (diff < 0) w = snprintf(OUT_PTR, 32, "in the future");
        else if (diff < 60) w = snprintf(OUT_PTR, 32, "%" IVdf "s ago", diff);
        else if (diff < 3600) w = snprintf(OUT_PTR, 32, "%" IVdf "m ago", diff / 60);
        else if (diff < 86400) w = snprintf(OUT_PTR, 32, "%" IVdf "h ago", diff / 3600);
        else if (diff < 2592000) w = snprintf(OUT_PTR, 32, "%" IVdf "d ago", diff / 86400);
        else if (diff < 31536000) w = snprintf(OUT_PTR, 32, "%" IVdf "mo ago", diff / 2592000);
        else w = snprintf(OUT_PTR, 32, "%" IVdf "y ago", diff / 31536000);
        if (w > 31) w = 31;
        OUT_COMMIT(w);
        break;
    }
    case XF_MASK: {
        /* clamp so the memset can never exceed the slen bytes reserved above */
        int keep = xf->param_int;
        if (keep < 0) keep = 0;
        if (keep > (int)slen) keep = (int)slen;
        OUT_ENSURE(slen);
        int mask_len = (int)slen - keep;
        if (mask_len > 0) {
            TS_NOTE_CUT(t, src, slen, mask_len);
            memset(OUT_PTR, '*', mask_len);
        }
        if (keep > 0) memcpy(OUT_PTR + mask_len, src + slen - keep, keep);
        int total = (int)slen;
        OUT_COMMIT(total);
        break;
    }
    case XF_LENGTH: {
        OUT_ENSURE(20);
        int w = itoa_fast(OUT_PTR, (IV)slen);
        OUT_COMMIT(w);
        break;
    }
    case XF_COALESCE: /* handled in render_field, fallthrough to raw */
    case XF_DEFAULT:
    case XF_RAW: {
        OUT_PASSTHRU();
        break;
    }
    }

done:
    #undef OUT_ENSURE
    #undef OUT_PTR
    *bufp = buf; *posp = pos; *allocp = alloc;
    *tmpp = tmp; *tmp_lenp = tmp_len; *tmp_allocp = tmp_alloc;
}

/* How a field value constrains the output encoding.  Scanning an unflagged
   value only tells us anything once something character-ish is in play, so
   until then just note that one went by; tpl_out_sv settles the remainder. */
#define TS_NOTE_SV(t, sv, s, l) do { \
    if (SvUTF8(sv)) (t)->r_utf8 = 1; \
    else if (!(t)->r_high && (l) && has_high_byte(s, l)) { \
        /* an all-ASCII value cannot make the output malformed, so only a high \
           byte is worth remembering -- deferring on every value instead cost a \
           whole-output is_utf8_string scan per render on mixed data */ \
        if ((t)->r_utf8 || (t)->tpl_utf8) (t)->r_high = 1; \
        else (t)->r_skipped = 1; \
    } \
} while(0)

/* r_utf8/r_high/r_skipped describe one render, but they live on the object, so
   a nested render -- an overloaded "", a tied FETCH, a callback that renders
   again on the same object -- used to zero the outer render's evidence and let
   it flag malformed output.  Stack the state on the C frame instead. */
/* On the savestack, not the C frame: a nested render that croaks and is caught
   by the Perl that called it would otherwise leave the outer render looking at
   the inner one's zeroed state, and flag malformed output as characters. */
#define TS_ENC_ENTER(t) do { \
    ENTER; \
    SAVEINT((t)->r_utf8); SAVEINT((t)->r_high); SAVEINT((t)->r_skipped); \
    (t)->r_utf8 = 0; (t)->r_high = 0; (t)->r_skipped = 0; \
} while(0)
#define TS_ENC_LEAVE(t) LEAVE

/* Flag the result UTF-8 only if something character-ish contributed and the
   assembled bytes really are well-formed: byte-level trunc/substr/mask can cut
   a sequence in half, and byte-string fields must survive a render unchanged. */
static SV *tpl_out_sv(pTHX_ tpl_compiled *t, const char *buf, STRLEN len) {
    /* r_high means something ruled a character result out: a high byte from an
       unflagged value, or a transform that sliced a character in half */
    int utf8 = (t->r_utf8 || t->tpl_utf8) && !(t->r_high || t->tpl_high);
    /* values went past unexamined; settle it once here.  The length guard is
       load-bearing: is_utf8_string() reads len == 0 as "call strlen()", and
       the buffer is not terminated at pos. */
    if (utf8 && t->r_skipped && len) utf8 = is_utf8_string((const U8 *)buf, len);
    return newSVpvn_utf8(buf, len, utf8);
}

/* A field selector of the wrong kind for the template fetches nothing from any
   row: the sort comes back in input order, skip_if never fires, and
   skip_unless drops everything and returns "". saw_num_ref distinguishes
   "ROW_ARRAY because {0} was seen" from "ROW_ARRAY because there are no field
   references at all", where either kind is meaningless and neither is refused.
   `own` is the template when nothing owns it yet: new() and clone() check after
   tpl_compile built it, so croaking without freeing would strand it.
   render_sorted passes NULL -- by then the object owns it. */
#define TS_CHECK_KIND(own, what, by_name) STMT_START { \
    if ((by_name) && t->saw_num_ref) { \
        if (own) tpl_free(own); \
        croak("Text::Stencil: %s was given a field name but the template uses" \
              " numeric field references", (what)); \
    } \
    if (!(by_name) && t->mode == ROW_HASH) { \
        if (own) tpl_free(own); \
        croak("Text::Stencil: %s was given a column index but the template uses" \
              " named field references", (what)); \
    } \
} STMT_END
#define TS_CHECK_SORT_KIND(by_name) TS_CHECK_KIND(NULL, "render_sorted", (by_name))

/* Fetch row i, or decide why the slot is empty. A slot past the end means
   user code shrank the array mid-render, so the caller stops; within the
   array it is a hole, which Perl reads as undef and which renders as an empty
   row like any other non-arrayref. Only consulted when the slot is empty, so
   the common path is free. Returns 0 to tell the caller to stop. */
PERL_STATIC_INLINE int ts_row_at(pTHX_ AV *rows, SSize_t i, SV **out) {
    SV **rowref = av_fetch(rows, i, 0);
    if (LIKELY(rowref && *rowref)) { *out = *rowref; return 1; }
    if (i > av_top_index(rows)) return 0;
    *out = &PL_sv_undef;
    return 1;
}

/* Emit one row through the compiled ops. */
#define TS_EMIT_OPS(row_sv, idx) do { \
    for (int j_ = 0; j_ < t->nops; j_++) { \
        tpl_op *op_ = &t->ops[j_]; \
        if (op_->static_data) BUF_WRITE(op_->static_data, op_->static_len); \
        else render_field(aTHX_ t, op_, (row_sv), &buf, &pos, &alloc, (idx)); \
    } \
} while (0)

/* Write straight to the render buffer and hand the moved pointers back. The
   four fast-path exits in render_field all did this by hand. */
#define EMIT_DIRECT(s, n) do { \
    char *buf = *bufp; STRLEN pos = *posp; STRLEN alloc = *allocp; \
    BUF_ENSURE(n); memcpy(buf + pos, (s), (n)); pos += (n); \
    *bufp = buf; *posp = pos; *allocp = alloc; \
} while (0)

static void render_field(pTHX_ tpl_compiled *t, tpl_op *op, SV *row_sv,
                          char **bufp, STRLEN *posp, STRLEN *allocp,
                          SSize_t row_idx) {
    enum row_mode mode = t->mode;
    const char *src = NULL; STRLEN slen = 0;
    int use_default = 0;
    /* src is read after the blocks that fill these, so they need whole-function
       scope -- declared inline they were a use-after-scope */
    char rownum_buf[20]; int rownum_len = 0;
    char cbuf[12];
    char ibuf[28];   /* itoa_comma needs up to 26 ("-9,223,372,036,854,775,808") */
    char fbuf[TS_FLTSZ];

    if (op->is_rownum) {
        rownum_len = itoa_fast(rownum_buf, (IV)row_idx);
        src = rownum_buf; slen = rownum_len;
        use_default = 1; /* skip fetch_field path, go straight to chain */
    }

    SV *sv = NULL;
    if (!op->is_rownum) {
        sv = fetch_field(aTHX_ row_sv, op, mode);

        /* handle default transform */
        if (!sv || !SvOK(sv)) {
            for (int i = 0; i < op->chain_len; i++) {
                if (op->chain[i].type == XF_DEFAULT && op->chain[i].param_str) {
                    src = op->chain[i].param_str;
                    slen = op->chain[i].param_str_len;
                    use_default = 1;
                    break;
                }
                if (op->chain[i].type == XF_COALESCE) {
                    use_default = 1; /* coalesce will handle it */
                    break;
                }
                if (op->chain[i].type == XF_BOOL || op->chain[i].type == XF_IF ||
                    op->chain[i].type == XF_UNLESS || op->chain[i].type == XF_MAP ||
                    op->chain[i].type == XF_WRAP) {
                    src = ""; slen = 0;
                    use_default = 1;
                    break;
                }
            }
            if (!use_default) return;
        }
    }

    /* handle coalesce: try fallback fields, then literal default */
    if (!op->is_rownum && op->chain_len > 0 && op->chain[0].type == XF_COALESCE) {
        int primary_ok = 0;
        if (sv && SvOK(sv)) {
            STRLEN plen;
            const char *pstr = SvPV_nomg(sv, plen);
            if (plen > 0) { primary_ok = 1; src = pstr; slen = plen; use_default = 0;
                            TS_NOTE_SV(t, sv, src, slen); }
        }
        if (!primary_ok && !op->chain[0].param_str) return;
        if (!primary_ok && op->chain[0].param_str) {
            const char *params = op->chain[0].param_str;
            STRLEN params_len = op->chain[0].param_str_len;
            const char *p = params, *pe = params + params_len;
            const char *last_param = NULL; STRLEN last_param_len = 0;
            /* The literal default is whatever follows the final ':', including
               nothing. Walking forwards never visited the empty tail of
               `coalesce:FIELD:`, so it stopped on FIELD and emitted that
               field's NAME. Scanning back makes the tail empty by
               construction. */
            {   const char *q = pe;
                while (q > params && q[-1] != ':') q--;
                last_param = q; last_param_len = (STRLEN)(pe - q);
            }
            /* try each fallback field (all params except the last) */
            int found = 0;
            p = params;
            while (p < pe) {
                const char *next = memchr(p, ':', pe - p);
                STRLEN seg_len = next ? (STRLEN)(next - p) : (STRLEN)(pe - p);
                if (!next && p == last_param) break; /* this is the literal default */
                /* try to fetch this field from the row */
                tpl_op tmp_op = {0};
                if (mode == ROW_HASH) {
                    tmp_op.key = (char *)p; tmp_op.key_len = seg_len;
                    /* the fallback name is a slice of the template, so it
                       carries the template's own encoding */
                    tmp_op.key_utf8 = op->key_utf8;
                } else {
                    int is_neg = 0, si = 0;
                    if (seg_len > 0 && p[0] == '-') { is_neg = 1; si = 1; }
                    int is_num = 1;
                    for (STRLEN fi = si; fi < seg_len; fi++)
                        if (p[fi] < '0' || p[fi] > '9') { is_num = 0; break; }
                    if (is_num && seg_len > (STRLEN)si) {
                        tmp_op.col = 0;
                        {   /* bound it like parse_field_spec does: an unchecked
                               accumulate wrapped 2**32 onto a valid column */
                            int ovf = 0;
                            for (STRLEN fi = si; fi < seg_len; fi++) {
                                int d = p[fi] - '0';
                                if (tmp_op.col > (INT_MAX - d) / 10) { ovf = 1; break; }
                                tmp_op.col = tmp_op.col * 10 + d;
                            }
                            if (ovf) { if (!next) break; p = next + 1; continue; }
                        }
                        if (is_neg) tmp_op.col = -tmp_op.col;
                    } else {
                        if (!next) break; /* non-numeric in array mode = treat as literal default */
                        p = next + 1; continue;
                    }
                }
                SV *fallback = fetch_field(aTHX_ row_sv, &tmp_op, mode);
                if (fallback && SvOK(fallback)) {
                    STRLEN flen;
                    const char *fstr = SvPV_nomg(fallback, flen);
                    if (flen > 0) { sv = fallback; src = fstr; slen = flen; use_default = 0; found = 1;
                                    TS_NOTE_SV(t, fallback, src, slen); break; }
                }
                if (!next) break;
                p = next + 1;
            }
            if (!found) {
                src = last_param; slen = last_param_len;
                use_default = 1;
            }
        }
    }

    /* handle count type: count elements of array/hash ref */
    if (!use_default && !op->is_rownum && op->chain_len > 0 && op->chain[0].type == XF_COUNT) {
        int cnt = 0;
        if (sv && SvROK(sv)) {
            SV *inner = SvRV(sv);
            if (SvTYPE(inner) == SVt_PVAV) cnt = (int)av_count((AV *)inner);
            else if (SvTYPE(inner) == SVt_PVHV) {
                HV *hv = (HV *)inner;
                /* HvUSEDKEYS reads the backing store, empty for a tied hash */
                if (UNLIKELY(SvRMAGICAL(inner))) {
                    hv_iterinit(hv);
                    while (hv_iternext(hv)) cnt++;
                } else cnt = (int)HvUSEDKEYS(hv);
            }
        }
        int clen = itoa_fast(cbuf, cnt);
        if (op->chain_len == 1) {
            EMIT_DIRECT(cbuf, clen);
            return;
        }
        src = cbuf; slen = clen;
    }

    /* get initial string value */
    if (!use_default && !op->is_rownum && !(op->chain_len > 0 &&
        (op->chain[0].type == XF_COUNT || op->chain[0].type == XF_COALESCE))) {
        /* for int/float types as first transform, use numeric conversion */
        if (op->chain_len > 0 && (op->chain[0].type == XF_INT || op->chain[0].type == XF_INT_COMMA)) {
            int ilen = (op->chain[0].type == XF_INT) ? itoa_fast(ibuf, SvIV_nomg(sv)) : itoa_comma(ibuf, SvIV_nomg(sv));
            if (op->chain_len == 1) {
                EMIT_DIRECT(ibuf, ilen);
                return;
            }
            src = ibuf; slen = ilen;
        } else if (op->chain_len > 0 && op->chain[0].type == XF_FLOAT) {
            /* the cast is load-bearing: NV is long double under -Duselongdouble */
            int flen = snprintf(fbuf, TS_FLTSZ, "%.*f",
                                op->chain[0].param_int, (double)SvNV_nomg(sv));
            if (flen > TS_FLTSZ - 1) flen = TS_FLTSZ - 1;
            if (op->chain_len == 1) {
                EMIT_DIRECT(fbuf, flen);
                return;
            }
            src = fbuf; slen = flen;
        } else if (op->chain_len > 0 && op->chain[0].type == XF_SPRINTF &&
                   ts_sprintf_conv(op->chain[0].param_str)) {
            /* Numify first, like int and float do. The formatter itself only
               scrapes digits out of text, so handing it the raw string made
               sprintf:%d on 3.9 print 39 -- and disagree with int on the same
               value. Mid-chain there is no SV left to numify, which is why the
               two still part company there. A format the formatter will reject
               must not be numified at all, or the value it passes through
               unchanged would arrive already mangled. */
            char conv = ts_sprintf_conv(op->chain[0].param_str);
            if (conv == 'd' || conv == 'i' || conv == 'x' ||
                conv == 'X' || conv == 'o' || conv == 'u') {
                slen = (STRLEN)itoa_fast(ibuf, SvIV_nomg(sv));
                src = ibuf;
            } else if (conv == 'f' || conv == 'e' || conv == 'g') {
                int nlen = snprintf(fbuf, TS_FLTSZ, "%.17g", (double)SvNV_nomg(sv));
                if (nlen < 0) nlen = 0;
                if (nlen > TS_FLTSZ - 1) nlen = TS_FLTSZ - 1;
                src = fbuf; slen = (STRLEN)nlen;
            } else {
                src = SvPV_nomg(sv, slen);
                TS_NOTE_SV(t, sv, src, slen);
            }
        } else {
            src = SvPV_nomg(sv, slen);
            TS_NOTE_SV(t, sv, src, slen);
        }
    }

    /* single transform fast path (most common) */
    int start = 0;
    if (!use_default && !op->is_rownum && op->chain_len > 0 &&
        (op->chain[0].type == XF_INT || op->chain[0].type == XF_INT_COMMA ||
         op->chain[0].type == XF_FLOAT || op->chain[0].type == XF_COUNT ||
         op->chain[0].type == XF_COALESCE))
        start = 1;
    /* use_default skipped the count handler, and apply_xform then wrote 0 over
       the value default had supplied: {items:count|default:none} on a missing
       field printed 0. count on undef is empty, so drop the stage. The rownum
       is a scalar, where 0 is right, so leave {#:count} alone. */
    if (use_default && !op->is_rownum && op->chain_len > 0 &&
        op->chain[0].type == XF_COUNT)
        start = 1;

    /* the overwhelmingly common shape: one transform, and it emits */
    if (op->chain_len - start == 1 && op->chain[start].type != XF_DEFAULT) {
        char *tmp = NULL; STRLEN tmp_len = 0, tmp_alloc = 0;
        apply_xform(t, &op->chain[start], src, slen, bufp, posp, allocp,
                    &tmp, &tmp_len, &tmp_alloc, 1);
        if (tmp) free(tmp);
        return;
    }

    /* DEFAULT only supplies a fallback value, it emits nothing itself, so count
       the transforms that actually produce output */
    int effective = 0;
    tpl_xform *only = NULL;
    for (int i = start; i < op->chain_len; i++)
        if (op->chain[i].type != XF_DEFAULT) { if (!effective) only = &op->chain[i]; effective++; }

    if (effective == 0) {
        EMIT_DIRECT(src, slen);
        return;
    }

    if (effective == 1) {
        char *tmp = NULL; STRLEN tmp_len = 0, tmp_alloc = 0;
        apply_xform(t, only, src, slen, bufp, posp, allocp, &tmp, &tmp_len, &tmp_alloc, 1);
        if (tmp) free(tmp);
        return;
    }

    /* chain: apply transforms with ping-pong buffers.
       Deliberate gap: plain malloc, not savestack-tracked, so a croak before
       the free below leaks the block apply_xform is growing -- likewise
       sprintf's sv_heap. Only the "out of memory" croaks reach either window
       on 64-bit and no user code runs there; plugging it costs a signature
       change plus stores in the per-stage loop. Revisit if a transform ever
       grows a croak of its own. */
    char *tmp_a = NULL, *tmp_b = NULL;
    STRLEN tmp_a_len = 0, tmp_a_alloc = 0, tmp_b_len = 0, tmp_b_alloc = 0;
    const char *cur = src; STRLEN cur_len = slen;
    int use_a = 1;

    /* which stage emits: found once here rather than rescanned per stage */
    int last_eff = -1;
    for (int i = start; i < op->chain_len; i++)
        if (op->chain[i].type != XF_DEFAULT) last_eff = i;

    for (int i = start; i < op->chain_len; i++) {
        if (op->chain[i].type == XF_DEFAULT) continue;
        int is_last = (i == last_eff);

        if (is_last) {
            char *dummy = NULL; STRLEN dummy_len = 0, dummy_alloc = 0;
            apply_xform(t, &op->chain[i], cur, cur_len, bufp, posp, allocp, &dummy, &dummy_len, &dummy_alloc, 1);
            if (dummy) free(dummy);
        } else {
            if (use_a) {
                tmp_a_len = 0;
                apply_xform(t, &op->chain[i], cur, cur_len, bufp, posp, allocp, &tmp_a, &tmp_a_len, &tmp_a_alloc, 0);
                /* a stage that emitted nothing leaves the buffer NULL; keep NULL
                   out of the next stage's memcpy */
                cur = tmp_a ? tmp_a : ""; cur_len = tmp_a_len;
                use_a = 0;
            } else {
                tmp_b_len = 0;
                apply_xform(t, &op->chain[i], cur, cur_len, bufp, posp, allocp, &tmp_b, &tmp_b_len, &tmp_b_alloc, 0);
                cur = tmp_b ? tmp_b : ""; cur_len = tmp_b_len;
                use_a = 1;
            }
        }
    }
    if (tmp_a) free(tmp_a);
    if (tmp_b) free(tmp_b);
}

/* check if a field value in a row is truthy */
static int is_field_truthy(pTHX_ SV *row_sv, tpl_compiled *t, int is_skip_if) {
    int col; char *key; STRLEN key_len; int key_utf8;
    if (is_skip_if) { col = t->skip_if_col; key = t->skip_if_key;
                      key_len = t->skip_if_key_len; key_utf8 = t->skip_if_utf8; }
    else { col = t->skip_unless_col; key = t->skip_unless_key;
           key_len = t->skip_unless_key_len; key_utf8 = t->skip_unless_utf8; }

    SV *field = NULL;
    SvGETMAGIC(row_sv);
    if (key) {
        if (SvROK(row_sv) && SvTYPE(SvRV(row_sv)) == SVt_PVHV) {
            SV **sv = hv_fetch((HV *)SvRV(row_sv), key,
                               key_utf8 ? -(I32)key_len : (I32)key_len, 0);
            /* a tied hash yields an unmaterialised PVLV, and SvOK is false on it
               until get-magic runs -- the row looked untruthy without FETCH */
            if (sv && *sv) { SvGETMAGIC(*sv); field = *sv; }
        }
    } else {
        if (SvROK(row_sv) && SvTYPE(SvRV(row_sv)) == SVt_PVAV)
            field = av_element(aTHX_ (AV *)SvRV(row_sv), col);
    }
    if (!field || !SvOK(field)) return 0;
    STRLEN flen;
    /* get-magic already ran above, on both branches. Plain SvPV re-ran it, and
       a tied element's second FETCH can differ -- the skip decision was taken
       on a value nothing else in the render sees. fetch_field is spelled the
       same way. */
    const char *fstr = SvPV_nomg(field, flen);
    if (flen == 0) return 0;
    if (flen == 1 && fstr[0] == '0') return 0;
    return 1;
}

static int should_skip_row(pTHX_ SV *row_sv, tpl_compiled *t) {
    if (t->has_skip_if && is_field_truthy(aTHX_ row_sv, t, 1)) return 1;
    if (t->has_skip_unless && !is_field_truthy(aTHX_ row_sv, t, 0)) return 1;
    return 0;
}

static SV *tpl_render(pTHX_ tpl_compiled *t, AV *rows) {
    TS_ENC_ENTER(t);
    TS_PIN_AV(rows);
    SSize_t nrows = av_count(rows);
    t->last_row_count = nrows;
    STRLEN alloc, pos;
    char *buf;
    RBUF_INIT(t, ts_est(t->header_len + t->footer_len, nrows));
    TS_INFLIGHT_ARM(t);

    BUF_WRITE(t->header, t->header_len);
    int first = 1;
    for (SSize_t i = 0; i < nrows; i++) {
        SV *row_sv;
        if (!ts_row_at(aTHX_ rows, i, &row_sv)) break;
        TS_PIN_ROW(row_sv);
        if (should_skip_row(aTHX_ row_sv, t)) continue;
        if (!first && t->sep_len) BUF_WRITE(t->sep, t->sep_len);
        first = 0;
        TS_EMIT_OPS(row_sv, i);
    }
    t->last_row_count = nrows;
    BUF_WRITE(t->footer, t->footer_len);
    TS_INFLIGHT_DISARM(t);
    RBUF_FINISH(t);
    { SV *res_ = tpl_out_sv(aTHX_ t, buf, pos); TS_ENC_LEAVE(t); return res_; }
}

/* ---- sorted render ---- */

/* Stringifying this SV would run Perl -- get-magic, an overload, or a
   reference whose stringification could be overloaded. Nothing here is a
   guess: for a plain scalar all three are false and SvPV is a pure read. */
/* Any magic at all means stringifying this SV may re-enter perl. Testing the
   individual flavours got it wrong three times: get-magic missed a magical
   row slot, then undef reaching report_uninit, then PERL_MAGIC_uvar -- which
   hv_fetch dispatches on SvSMAGICAL && SvGMAGICAL and which is not RMAGICAL,
   so a fieldhash or a Variable::Magic fetch wizard slipped straight past.
   One predicate, no flavours: it costs the same test and cannot drift. */
#define TS_RUNS_PERL(sv) (SvMAGICAL(sv) || SvROK(sv))

/* Take ownership of the first `n` collected sort keys, which until now pointed
   into the fields themselves. Called the first time something appears that
   could move those buffers, while they are all still valid. */
static void ts_own_keys(pTHX_ const char **keys, STRLEN *lens, SSize_t n) {
    SSize_t i;
    for (i = 0; i < n; i++) {
        if (!lens[i]) continue;
        keys[i] = SvPVX(sv_2mortal(newSVpvn(keys[i], lens[i])));
    }
}

/* The comparator gets no context argument from qsort, so what it needs to
   know travels in the entries themselves. Holding it in file-scope statics
   instead meant two interpreters sorting at once could each see the other.s
   key count and read past its own key arrays. */
typedef struct {
    SV *sv; const char **keys; STRLEN *key_lens;
    int nsort; int numeric;
} sort_entry;

static int sort_cmp_multi(const sort_entry *ea, const sort_entry *eb) {
    for (int k = 0; k < ea->nsort; k++) {
        if (ea->numeric) {
            double da = ts_atof(ea->keys[k], ea->key_lens[k]);
            double db = ts_atof(eb->keys[k], eb->key_lens[k]);
            /* NaN is neither < nor > anything, so it compared equal to every
               key and the comparator stopped being a weak ordering: garbage
               order, plus an out-of-bounds read in glibc qsort before 2.39.
               Treat it as the zero other unparseable values become. */
            if (UNLIKELY(da != da)) da = 0;
            if (UNLIKELY(db != db)) db = 0;
            if (da < db) return -1;
            if (da > db) return 1;
        } else {
            STRLEN minlen = ea->key_lens[k] < eb->key_lens[k] ? ea->key_lens[k] : eb->key_lens[k];
            int r = memcmp(ea->keys[k], eb->keys[k], minlen);
            if (r) return r;
            if (ea->key_lens[k] != eb->key_lens[k])
                return ea->key_lens[k] < eb->key_lens[k] ? -1 : 1;
        }
    }
    return 0;
}

static int sort_cmp_asc(const void *a, const void *b) {
    return sort_cmp_multi((const sort_entry *)a, (const sort_entry *)b);
}

static int sort_cmp_desc(const void *a, const void *b) {
    return sort_cmp_multi((const sort_entry *)b, (const sort_entry *)a);
}

/* libc free() as a SAVEDESTRUCTOR_X callback. The sort scratch is malloc'd,
   not Newx'd, so SAVEFREEPV/Safefree would mismatch on DEBUGGING perls. */
static void ts_free(pTHX_ void *p) { free(p); }

static SV *tpl_render_sorted(pTHX_ tpl_compiled *t, AV *rows,
                              int *sort_cols, const char **sort_keys, STRLEN *sort_key_lens,
                              const int *sort_key_utf8,
                              int nsort, int descending, int numeric) {
    TS_ENC_ENTER(t);
    TS_PIN_AV(rows);
    SSize_t nrows = av_count(rows);
    t->last_row_count = nrows;

    sort_entry *entries = nrows > 0 ? (sort_entry *)malloc(nrows * sizeof(sort_entry)) : NULL;
    if (nrows > 0 && !entries) croak("Text::Stencil: out of memory");
    const char **all_keys = nrows > 0 ? (const char **)calloc(nrows * nsort, sizeof(char *)) : NULL;
    STRLEN *all_lens = nrows > 0 ? (STRLEN *)calloc(nrows * nsort, sizeof(STRLEN)) : NULL;
    /* Free the sort scratch on scope exit, so a croak mid-render (e.g. an OOM
       realloc in BUF_ENSURE) frees it on the unwind instead of leaking it;
       LEAVE frees it on the normal path. */
    ENTER;
    if (entries)  SAVEDESTRUCTOR_X(ts_free, entries);
    if (all_keys) SAVEDESTRUCTOR_X(ts_free, all_keys);
    if (all_lens) SAVEDESTRUCTOR_X(ts_free, all_lens);
    /* checked after the SAVEDESTRUCTORs so the unwind frees entries; an
       unchecked NULL here would segfault at entries[i].keys below */
    if (nrows > 0 && (!all_keys || !all_lens)) croak("Text::Stencil: out of memory");
    /* a magical rows array runs Perl on every fetch, so never borrow there */
    int borrow = !SvMAGICAL((SV *)rows);
    for (SSize_t i = 0; i < nrows; i++) {
        SV **rowref = av_fetch(rows, i, 0);
        /* A plain rows array can still hold a magical element -- tie $rows[1] --
           and materialising it runs Perl just as a tied container would. Give
           up borrowing before that happens, not after. (Only get-magic matters
           here: the row is a reference we never stringify, so SvROK/SvAMAGIC
           would disqualify every ordinary row for nothing.) */
        if (borrow && rowref && *rowref && SvMAGICAL(*rowref)) {
            ts_own_keys(aTHX_ all_keys, all_lens, i * nsort);
            borrow = 0;
        }
        /* a magical rows array yields unmaterialised PVLVs, and the SvROK test
           below would leave every sort key empty */
        if (rowref) SvGETMAGIC(*rowref);
        /* the comparator reads these PVs long after collection, so the key SVs
               below must outlive it too -- that was a use-after-free in qsort */
        SV *row_sv = (rowref && *rowref) ? *rowref : &PL_sv_undef;
        TS_PIN_ROW(row_sv);
        entries[i].sv = row_sv;
        entries[i].keys = all_keys + i * nsort;
        entries[i].key_lens = all_lens + i * nsort;
        entries[i].nsort = nsort;
        entries[i].numeric = numeric;
        if (borrow && SvROK(row_sv) && SvMAGICAL(SvRV(row_sv))) {
            ts_own_keys(aTHX_ all_keys, all_lens, i * nsort);
            borrow = 0;
        }
        for (int k = 0; k < nsort; k++) {
            entries[i].keys[k] = ""; entries[i].key_lens[k] = 0;
            if (SvROK(row_sv)) {
                SV *field = NULL;
                if (sort_keys) {
                    if (SvTYPE(SvRV(row_sv)) == SVt_PVHV) {
                        SV **sv = hv_fetch((HV *)SvRV(row_sv), sort_keys[k],
                                           sort_key_utf8[k] ? -(I32)sort_key_lens[k]
                                                            : (I32)sort_key_lens[k], 0);
                        if (sv) field = *sv;
                    }
                } else {
                    if (SvTYPE(SvRV(row_sv)) == SVt_PVAV) {
                        SV **sv = av_fetch((AV *)SvRV(row_sv), sort_cols[k], 0);
                        if (sv) field = *sv;
                    }
                }
                if (field) {
                    /* Borrowing the field's own buffer is only safe while
                       nothing in this loop can run Perl -- a later key that
                       stringifies through an overload could grow an earlier one
                       in place and free the PV the comparator still points at.
                       For plain scalars nothing can, which is the common case
                       and the one worth keeping fast; the moment something
                       could, take ownership of this key and of every key
                       already borrowed (still valid: no Perl has run yet). */
                    if (borrow && TS_RUNS_PERL(field)) {
                        ts_own_keys(aTHX_ all_keys, all_lens, i * nsort + k);
                        borrow = 0;
                    }
                    /* Stringifying undef is not free: perl reports it, and a
                       __WARN__ handler is Perl running inside the borrow
                       window. The other render paths already skip undef rather
                       than warn, so match them and leave the key empty. */
                    if (!borrow) SvGETMAGIC(field);
                    if (!SvOK(field)) continue;
                    STRLEN flen;
                    const char *fp = SvPV_nomg(field, flen);
                    if (!borrow) {
                        SV *owned = sv_2mortal(newSVpvn(fp, flen));
                        fp = SvPVX(owned);
                    }
                    entries[i].keys[k] = fp;
                    entries[i].key_lens[k] = flen;
                }
            }
        }
    }

    int (*cmp)(const void *, const void *) = descending ? sort_cmp_desc : sort_cmp_asc;
    if (nrows > 1) qsort(entries, nrows, sizeof(sort_entry), cmp);

    STRLEN alloc, pos;
    char *buf;
    RBUF_INIT(t, ts_est(t->header_len + t->footer_len, nrows));
    TS_INFLIGHT_ARM(t);

    BUF_WRITE(t->header, t->header_len);
    int first = 1;
    for (SSize_t i = 0; i < nrows; i++) {
        SV *row_sv = entries[i].sv;
        if (should_skip_row(aTHX_ row_sv, t)) continue;
        if (!first && t->sep_len) BUF_WRITE(t->sep, t->sep_len);
        first = 0;
        TS_EMIT_OPS(row_sv, i);
    }
    t->last_row_count = nrows;
    BUF_WRITE(t->footer, t->footer_len);
    TS_INFLIGHT_DISARM(t);
    RBUF_FINISH(t);
    SV *result = tpl_out_sv(aTHX_ t, buf, pos);
    LEAVE;             /* the sort scratch: entries/all_keys/all_lens */
    TS_ENC_LEAVE(t);   /* then the encoding state this render saved */
    return result;
}

static SV *tpl_render_one(pTHX_ tpl_compiled *t, SV *row_sv) {
    TS_ENC_ENTER(t);
    TS_PIN_ROW(row_sv);
    if (should_skip_row(aTHX_ row_sv, t)) {
        TS_ENC_LEAVE(t);   /* a skipped row must not eat an outer render's state */
        return newSVpvn("", 0);
    }
    STRLEN alloc, pos;
    char *buf;
    RBUF_INIT(t, t->header_len + t->footer_len + 512);
    TS_INFLIGHT_ARM(t);
    BUF_WRITE(t->header, t->header_len);
    TS_EMIT_OPS(row_sv, 0);
    BUF_WRITE(t->footer, t->footer_len);
    TS_INFLIGHT_DISARM(t);
    RBUF_FINISH(t);
    { SV *res_ = tpl_out_sv(aTHX_ t, buf, pos); TS_ENC_LEAVE(t); return res_; }
}

static void tpl_render_to_fh(pTHX_ tpl_compiled *t, AV *rows, PerlIO *fh) {
    TS_ENC_ENTER(t);
    TS_PIN_AV(rows);
    SSize_t nrows = av_count(rows);
    t->last_row_count = nrows;
    /* This streams, flushing every 64KB, so it never needs the whole output
       resident -- sizing it from the row count made a million-row render
       reserve hundreds of MB and hit an address-space limit that render_cb,
       which uses a fixed buffer, sails through. */
    STRLEN est = ts_est(t->header_len + t->footer_len, nrows);
    STRLEN cap = t->header_len + t->footer_len + 65536 + 1;
    STRLEN alloc = est < cap ? est : cap;
    char *buf = (char *)malloc(alloc);
    if (!buf) croak("Text::Stencil: out of memory");
    TS_INFLIGHT_ARM(t);
    STRLEN pos = 0;
    BUF_WRITE(t->header, t->header_len);
    int first = 1;
    for (SSize_t i = 0; i < nrows; i++) {
        SV *row_sv;
        if (!ts_row_at(aTHX_ rows, i, &row_sv)) break;
        TS_PIN_ROW(row_sv);
        if (should_skip_row(aTHX_ row_sv, t)) continue;
        if (!first && t->sep_len) BUF_WRITE(t->sep, t->sep_len);
        first = 0;
        TS_EMIT_OPS(row_sv, i);
        if (pos > 65536) { FH_WRITE(fh, buf, pos); pos = 0; }
    }
    t->last_row_count = nrows;
    BUF_WRITE(t->footer, t->footer_len);
    if (pos) FH_WRITE(fh, buf, pos);
    TS_INFLIGHT_DISARM(t);
    free(buf);
    TS_ENC_LEAVE(t);
}

static SV *tpl_render_cb(pTHX_ tpl_compiled *t, SV *cb, PerlIO *fh) {
    TS_ENC_ENTER(t);
    STRLEN alloc, pos;
    char *buf;
    int use_fh = (fh != NULL);

    if (use_fh) {
        alloc = 65536;
        buf = (char *)malloc(alloc);
        if (!buf) croak("Text::Stencil: out of memory");
    } else {
        RBUF_INIT(t, 4096);
    }
    TS_INFLIGHT_ARM(t);
    /* Where our savestack frame starts.  Nothing should reach it now that the
       callback runs on its own stackinfo, but a mis-guessed unwind here costs
       a heap corruption, so the check stays as a backstop. */
    I32 ts_floor = PL_savestack_ix;
    pos = 0;

    BUF_WRITE(t->header, t->header_len);
    SSize_t row_idx = 0;
    int first = 1;
    t->last_row_count = 0;

    /* Run the callback on a stackinfo of its own. last/next/goto out of a sub
       unwinds by scanning the current stackinfo's context stack; without this
       it walks straight through our C frame, panicking in pp_iter or resuming
       in our caller with the render half-done. A fresh stackinfo has no context
       to find, so the jump becomes a "Label not found" die that G_EVAL catches.
       Core contains a user sub called from C the same way (magic_methcall,
       amagic_call, the warn hook). Hoisted out of the loop: per-iteration it
       costs ~5%, here one push per render_cb call. */
    dSP;
    PUSHSTACKi(PERLSI_MAGIC);

    while (1) {
        SPAGAIN;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        PUTBACK;
        int count = call_sv(cb, G_SCALAR | G_EVAL);
        SPAGAIN;
        /* Backstop: the stackinfo above contains the jumps that used to get
           here. If it ever fires our frame is already gone and `buf` dangles,
           so touching it -- or running LEAVE -- would corrupt the heap. Return
           and let perl finish its unwind; the stackinfo is left for die_unwind,
           since getting here means perl is already mid-longjmp. */
        if (UNLIKELY(PL_savestack_ix < ts_floor)) return &PL_sv_undef;
        if (SvTRUE(ERRSV)) {
            /* The row callback died: free our render buffer (the fh path's
               own malloc, or the detached render_buf) before propagating, so
               a dying callback can't leak it. */
            SV *err = newSVsv(ERRSV);
            PUTBACK; FREETMPS; LEAVE;
            POPSTACK;
            TS_INFLIGHT_DISARM(t);
            free(buf);
            croak_sv(sv_2mortal(err));
        }
        SV *row_sv = NULL;
        if (count > 0) row_sv = POPs;
        /* only an arrayref or hashref is a row; accepting any reference let a
           stray scalarref render an empty row forever */
        if (!row_sv || !SvOK(row_sv) || !SvROK(row_sv) ||
            (SvTYPE(SvRV(row_sv)) != SVt_PVAV && SvTYPE(SvRV(row_sv)) != SVt_PVHV)) {
            PUTBACK; FREETMPS; LEAVE;
            break;
        }
        SvREFCNT_inc_simple_void_NN(row_sv);
        PUTBACK; FREETMPS; LEAVE;

        /* Own the row for exactly this iteration.  A bare inc/dec pair leaked
           the whole row structure whenever rendering it croaked; SAVEFREESV is
           released by the unwind too, and unlike a mortal it does not pile up
           across a long callback stream. */
        ENTER;
        SAVEFREESV(row_sv);
        if (!should_skip_row(aTHX_ row_sv, t)) {
            if (!first && t->sep_len) BUF_WRITE(t->sep, t->sep_len);
            first = 0;
            TS_EMIT_OPS(row_sv, row_idx);
            if (use_fh && pos > 65536) { FH_WRITE(fh, buf, pos); pos = 0; }
        }
        LEAVE;
        row_idx++;
        t->last_row_count = row_idx;
    }

    POPSTACK;

    t->last_row_count = row_idx;
    BUF_WRITE(t->footer, t->footer_len);

    if (use_fh) {
        if (pos) FH_WRITE(fh, buf, pos);
        TS_INFLIGHT_DISARM(t);
        free(buf);
        TS_ENC_LEAVE(t);
        return &PL_sv_undef;
    } else {
        TS_INFLIGHT_DISARM(t);
        RBUF_FINISH(t);
        { SV *res_ = tpl_out_sv(aTHX_ t, buf, pos); TS_ENC_LEAVE(t); return res_; }
    }
}

/* columns introspection; returns an owning RV, since the AV* OUTPUT typemap
   would wrap RETVAL with the refcount-incrementing newRV() and leak the AV */
static SV *tpl_columns(pTHX_ tpl_compiled *t) {
    AV *cols = newAV();
    /* each field once, in first-appearance order */
    for (int i = 0; i < t->nops; i++) {
        tpl_op *op = &t->ops[i];
        if (!op->chain || op->is_rownum) continue;
        int seen = 0;
        for (int j = 0; j < i && !seen; j++) {
            tpl_op *p = &t->ops[j];
            if (!p->chain || p->is_rownum) continue;
            if (op->key)
                seen = p->key && p->key_len == op->key_len &&
                       memcmp(p->key, op->key, op->key_len) == 0;
            else
                seen = !p->key && p->col == op->col;
        }
        if (seen) continue;
        /* the flag matters: callers index their own rows with these, and a
           flagged key and its bytes are not the same hash key */
        if (op->key) av_push(cols, newSVpvn_utf8(op->key, op->key_len, op->key_utf8));
        else         av_push(cols, newSViv(op->col));
    }
    return newRV_noinc((SV *)cols);
}


MODULE = Text::Stencil  PACKAGE = Text::Stencil

SV *
new(class, ...)
    const char *class
CODE:
{
    const char *header = "", *row = "", *footer = "", *sep = "";
    STRLEN hlen = 0, rlen = 0, flen = 0, slen = 0;
    char esc = 0;
    int tpl_utf8 = 0;
    /* `class` is a raw PV borrowed from ST(0); an overloaded "" among the
       arguments can free it before we get here, so resolve the stash now */
    /* called as an instance method, `class` stringifies to
       "Text::Stencil=SCALAR(0x...)" and gv_stashpv would mint that stash */
    HV *class_stash = (SvROK(ST(0)) && SvOBJECT(SvRV(ST(0))))
                    ? SvSTASH(SvRV(ST(0))) : gv_stashpv(class, GV_ADD);
    char err[TS_ERRSZ]; err[0] = '\0';
    SV *skip_if_sv = NULL, *skip_unless_sv = NULL;
    /* shorthand: Text::Stencil->new($row_template) */
    if (items == 2 && SvOK(ST(1)) && !SvROK(ST(1))) {
        row = ts_own_pv(aTHX_ ST(1), &rlen, NULL);
        if (SvUTF8(ST(1))) tpl_utf8 |= TS_TPL_ROW;
    } else {
    /* one argument that is not a plain string is neither shorthand nor an
       option list; "odd number of arguments" described the wrong mistake */
    if (items == 2) croak("Text::Stencil: new takes a template string or an"
                          " option list");
    if (items % 2 == 0) croak("Text::Stencil: odd number of arguments");
    for (int i = 1; i < items; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);
        /* an overloaded "" on a later argument can free an earlier one, and we
           keep raw PVs until tpl_compile copies them */
        sv_2mortal(SvREFCNT_inc_simple_NN(val));
        if (strcmp(key, "header") == 0) { int u_; header = ts_own_pv(aTHX_ val, &hlen, &u_); if (u_) tpl_utf8 |= TS_TPL_HDR; }
        else if (strcmp(key, "row") == 0) { int u_; row = ts_own_pv(aTHX_ val, &rlen, &u_); if (u_) tpl_utf8 |= TS_TPL_ROW; }
        else if (strcmp(key, "footer") == 0) { int u_; footer = ts_own_pv(aTHX_ val, &flen, &u_); if (u_) tpl_utf8 |= TS_TPL_FTR; }
        else if (strcmp(key, "separator") == 0) { int u_; sep = ts_own_pv(aTHX_ val, &slen, &u_); if (u_) tpl_utf8 |= TS_TPL_SEP; }
        else if (strcmp(key, "escape_char") == 0) {
            /* one byte, or the template silently stops substituting entirely */
            STRLEN el; const char *ev = SvPV(val, el);
            if (el != 1)
                croak("Text::Stencil: escape_char must be a single byte, got %" UVuf,
                      (UV)el);
            /* a NUL fell through the `esc_char ? esc_char : '{'` default below
               and silently meant '{', which is the quiet no-op this option's
               single-byte check exists to prevent */
            if (ev[0] == '\0')
                croak("Text::Stencil: escape_char must not be NUL");
            esc = ev[0];
        }
        else if (strcmp(key, "skip_if") == 0) skip_if_sv = val;
        else if (strcmp(key, "skip_unless") == 0) skip_unless_sv = val;
        /* a silently dropped option is how a typo becomes an empty table */
        else croak("Text::Stencil: unknown option '%s'", key);
    }
    }
    /* Resolve the skip conditions before compiling anything. Deciding whether
       one is a column or a key, and stringifying it, both run user Perl that
       can die -- and a die after tpl_compile strands the whole template, which
       is not yet owned by any SV that could free it. */
    int skip_if_isnum = 0, skip_if_u = 0, skip_unless_isnum = 0, skip_unless_u = 0;
    int skip_if_col = 0, skip_unless_col = 0;
    const char *skip_if_ks = NULL, *skip_unless_ks = NULL;
    STRLEN skip_if_kl = 0, skip_unless_kl = 0;
    if (skip_if_sv) {
        if (SvIOK(skip_if_sv) || looks_like_number(skip_if_sv)) {
            skip_if_isnum = 1;
            skip_if_col = ts_col_sv(aTHX_ skip_if_sv, "skip_if");
        } else skip_if_ks = ts_own_pv(aTHX_ skip_if_sv, &skip_if_kl, &skip_if_u);
    }
    if (skip_unless_sv) {
        if (SvIOK(skip_unless_sv) || looks_like_number(skip_unless_sv)) {
            skip_unless_isnum = 1;
            skip_unless_col = ts_col_sv(aTHX_ skip_unless_sv, "skip_unless");
        } else skip_unless_ks = ts_own_pv(aTHX_ skip_unless_sv, &skip_unless_kl, &skip_unless_u);
    }

    tpl_compiled *t = tpl_compile(aTHX_ header, hlen, row, rlen, footer, flen, sep, slen, esc, tpl_utf8, err);
    if (!t || err[0]) { if (t) tpl_free(t); croak("Text::Stencil: %s", err); }
    if (skip_if_sv) {
        TS_CHECK_KIND(t, "skip_if", !skip_if_isnum);
        t->has_skip_if = 1;
        if (skip_if_isnum) t->skip_if_col = skip_if_col;
        else {
            ts_set_skip_key(aTHX_ t, &t->skip_if_key, &t->skip_if_key_len,
                            &t->skip_if_utf8, skip_if_ks, skip_if_kl, skip_if_u);
        }
    }
    if (skip_unless_sv) {
        TS_CHECK_KIND(t, "skip_unless", !skip_unless_isnum);
        t->has_skip_unless = 1;
        if (skip_unless_isnum) t->skip_unless_col = skip_unless_col;
        else {
            ts_set_skip_key(aTHX_ t, &t->skip_unless_key, &t->skip_unless_key_len,
                            &t->skip_unless_utf8, skip_unless_ks, skip_unless_kl,
                            skip_unless_u);
        }
    }
    SV *obj = newSViv(PTR2IV(t));
    t->owner = obj;
    sv_magicext(obj, NULL, PERL_MAGIC_ext, &ts_vtbl, (const char *)t, 0);
    SV *ref = newRV_noinc(obj);
    sv_bless(ref, class_stash);
    RETVAL = ref;
}
OUTPUT:
    RETVAL

SV *
render(self, rows)
    SV *self
    AV *rows
CODE:
{
    tpl_compiled *t = TS_PIN_SELF(self);
    RETVAL = tpl_render(aTHX_ t, rows);
}
OUTPUT:
    RETVAL

SV *
render_sorted(self, rows, sort_by, ...)
    SV *self
    AV *rows
    SV *sort_by
CODE:
{
    tpl_compiled *t = TS_PIN_SELF(self);
    int descending = 0, numeric = 0;
    if (items > 4) croak("Text::Stencil: render_sorted takes at most three arguments");
    if (items > 3 && SvOK(ST(3))) {
        if (!SvROK(ST(3)) || SvTYPE(SvRV(ST(3))) != SVt_PVHV)
            croak("Text::Stencil: render_sorted options must be a hashref");
        HV *opts = (HV *)SvRV(ST(3));
        SV **sv;
        sv = hv_fetchs(opts, "descending", 0);
        if (sv && SvTRUE(*sv)) descending = 1;
        sv = hv_fetchs(opts, "numeric", 0);
        if (sv && SvTRUE(*sv)) numeric = 1;
        /* a dropped 'decending' would just sort the other way with nothing to
           explain it, the same trap new() and clone() already refuse */
        {
            char *k; I32 klen; HE *he;
            hv_iterinit(opts);
            while ((he = hv_iternext(opts))) {
                k = hv_iterkey(he, &klen);
                if (strcmp(k, "descending") && strcmp(k, "numeric"))
                    croak("Text::Stencil: unknown render_sorted option '%s'", k);
            }
        }
    }
    /* Anything else would be stringified into a field name like "HASH(0x...)",
       match nothing, and come back unsorted with no complaint -- and a hashref
       is an easy mistake to make when the *third* argument really is one. */
    if (!SvOK(sort_by))
        croak("Text::Stencil: render_sorted needs a column index, a field name, "
              "or an arrayref of them");
    if (SvROK(sort_by) && !SvAMAGIC(sort_by) && SvTYPE(SvRV(sort_by)) != SVt_PVAV)
        croak("Text::Stencil: render_sorted sort spec must be an arrayref, "
              "not a %s reference", sv_reftype(SvRV(sort_by), 0));
    if (SvROK(sort_by) && SvTYPE(SvRV(sort_by)) == SVt_PVAV) {
        AV *sort_av = (AV *)SvRV(sort_by);
        SSize_t nsort_ = av_count(sort_av);
        /* bound it so the element-count arithmetic below cannot wrap */
        if (nsort_ < 0 || nsort_ > 1024)
            croak("Text::Stencil: render_sorted sort spec has too many fields");
        int nsort = (int)nsort_;
        if (nsort == 0) {
            RETVAL = tpl_render(aTHX_ t, rows);
        } else {
            /* Each element has to be usable on its own. Rejecting only the
               scalar form left [undef] and [{}] to be stringified into a field
               name nothing matches, coming back unsorted with no complaint --
               the very thing the scalar check exists to prevent. */
            {
                int i_;
                for (i_ = 0; i_ < nsort; i_++) {
                    SV **el_ = av_fetch(sort_av, i_, 0);
                    if (!el_ || !*el_ || !SvOK(*el_))
                        croak("Text::Stencil: render_sorted sort spec element %d "
                              "is undef", i_);
                    /* an overloaded object stringifies to a real name, so it is
                       fine; a plain ref would become "HASH(0x...)" */
                    if (SvROK(*el_) && !SvAMAGIC(*el_))
                        croak("Text::Stencil: render_sorted sort spec element %d "
                              "is a %s reference, not a column or field name",
                              i_, sv_reftype(SvRV(*el_), 0));
                }
            }
            SV **first = av_fetch(sort_av, 0, 0);
            int use_keys = first && !SvIOK(*first) && !looks_like_number(*first);
            /* The whole spec is read one way or the other, decided by its first
               element. A mixed spec used to push the odd one through the other
               path and quietly sort by the wrong field. */
            {
                int i_;
                for (i_ = 1; i_ < nsort; i_++) {
                    SV **el_ = av_fetch(sort_av, i_, 0);
                    int k_ = el_ && !SvIOK(*el_) && !looks_like_number(*el_);
                    if (k_ != use_keys)
                        croak("Text::Stencil: render_sorted sort spec mixes column "
                              "indices and field names");
                }
            }
            TS_CHECK_SORT_KIND(use_keys);
            if (use_keys) {
                const char **skeys = (const char **)malloc(nsort * sizeof(char *));
                STRLEN *sklens = (STRLEN *)malloc(nsort * sizeof(STRLEN));
                int *skutf8 = (int *)malloc(nsort * sizeof(int));
                if (!skeys || !sklens || !skutf8) { free(skeys); free(sklens); free(skutf8);
                    croak("Text::Stencil: out of memory"); }
                /* a dying overload during key collection would otherwise leak these */
                SAVEDESTRUCTOR_X(ts_free, skeys);
                SAVEDESTRUCTOR_X(ts_free, sklens);
                SAVEDESTRUCTOR_X(ts_free, skutf8);
                for (int i = 0; i < nsort; i++) {
                    SV **el = av_fetch(sort_av, i, 0);
                    skeys[i] = ""; sklens[i] = 0; skutf8[i] = 0;
                    if (el && *el) {
                        /* Pin the element and read it once. Stringifying it can
                           run an overload that pushes to this very array, and
                           av_extend would then realloc AvARRAY out from under
                           `el` -- so nothing may dereference the slot again. */
                        SV *e = *el;
                        sv_2mortal(SvREFCNT_inc_simple_NN(e));
                        skeys[i] = ts_own_pv(aTHX_ e, &sklens[i], &skutf8[i]);
                    }
                    /* same '-' shorthand the scalar form takes; direction is a
                       property of the whole sort, so any '-' turns it around */
                    if (sklens[i] > 1 && skeys[i][0] == '-') {
                        skeys[i]++; sklens[i]--; descending = 1;
                    }
                }
                RETVAL = tpl_render_sorted(aTHX_ t, rows, NULL, skeys, sklens, skutf8, nsort, descending, numeric);
            } else {
                int *scols = (int *)malloc(nsort * sizeof(int));
                if (!scols) croak("Text::Stencil: out of memory");
                SAVEDESTRUCTOR_X(ts_free, scols);
                for (int i = 0; i < nsort; i++) {
                    SV **el = av_fetch(sort_av, i, 0);
                    scols[i] = el ? ts_col_sv(aTHX_ *el, "sort") : 0;
                }
                RETVAL = tpl_render_sorted(aTHX_ t, rows, scols, NULL, NULL, NULL, nsort, descending, numeric);
            }
        }
    } else if (SvIOK(sort_by) || looks_like_number(sort_by)) {
        TS_CHECK_SORT_KIND(0);
        int col = ts_col_sv(aTHX_ sort_by, "sort");
        RETVAL = tpl_render_sorted(aTHX_ t, rows, &col, NULL, NULL, NULL, 1, descending, numeric);
    } else {
        STRLEN klen;
        int kutf8;
        TS_CHECK_SORT_KIND(1);
        const char *key = ts_own_pv(aTHX_ sort_by, &klen, &kutf8);
        if (klen > 1 && key[0] == '-') { key++; klen--; descending = 1; }
        RETVAL = tpl_render_sorted(aTHX_ t, rows, NULL, &key, &klen, &kutf8, 1, descending, numeric);
    }
}
OUTPUT:
    RETVAL

SV *
render_one(self, row)
    SV *self
    SV *row
CODE:
{
    tpl_compiled *t = TS_PIN_SELF(self);
    RETVAL = tpl_render_one(aTHX_ t, row);
}
OUTPUT:
    RETVAL

void
render_to_fh(self, fh, rows)
    SV *self
    PerlIO *fh
    AV *rows
CODE:
{
    tpl_compiled *t = TS_PIN_SELF(self);
    tpl_render_to_fh(aTHX_ t, rows, fh);
}

SV *
render_cb(self, cb, ...)
    SV *self
    SV *cb
CODE:
{
    tpl_compiled *t = TS_PIN_SELF(self);
    /* like render_sorted: a silently swallowed extra argument is how a typo
       becomes output nobody can explain */
    if (items > 3) croak("Text::Stencil: render_cb takes at most two arguments");
    if (!SvROK(cb) || SvTYPE(SvRV(cb)) != SVt_PVCV)
        croak("Text::Stencil: render_cb second argument must be a coderef");
    PerlIO *fh = NULL;
    if (items > 2) {
        /* a closed handle yields a NULL IoIFP; silently buffering to a string the
           caller then discards loses the output */
        fh = IoIFP(sv_2io(ST(2)));
        if (!fh) croak("Text::Stencil: render_cb: filehandle is not open for writing");
    }
    RETVAL = tpl_render_cb(aTHX_ t, cb, fh);
}
OUTPUT:
    RETVAL

SV *
columns(self)
    SV *self
CODE:
{
    tpl_compiled *t = ts_self(aTHX_ self);
    RETVAL = tpl_columns(aTHX_ t);
}
OUTPUT:
    RETVAL

IV
row_count(self)
    SV *self
CODE:
{
    tpl_compiled *t = ts_self(aTHX_ self);
    RETVAL = (IV)t->last_row_count;
}
OUTPUT:
    RETVAL

SV *
clone(self, ...)
    SV *self
CODE:
{
    /* An overloaded "" among the arguments can DESTROY us mid-call, and it can
       clear the caller's reference too -- so grab the stash while self is
       still one. */
    tpl_compiled *orig = TS_PIN_SELF(self);
    HV *self_stash = SvSTASH(SvRV(self));
    if (items % 2 == 0) croak("Text::Stencil: odd number of arguments");
    const char *row = NULL; STRLEN rlen = 0;
    const char *sep = NULL; STRLEN slen = 0;
    int tpl_utf8 = orig->tpl_utf8;
    char err[TS_ERRSZ]; err[0] = '\0';
    for (int i = 1; i < items; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);
        /* an overloaded "" on a later argument can free an earlier one, and we
           keep raw PVs until tpl_compile copies them */
        sv_2mortal(SvREFCNT_inc_simple_NN(val));
        /* a replaced piece re-decides its own bit; it must not inherit one */
        if (strcmp(key, "row") == 0) { row = ts_own_pv(aTHX_ val, &rlen, NULL);
            if (SvUTF8(val)) tpl_utf8 |= TS_TPL_ROW; else tpl_utf8 &= ~TS_TPL_ROW; }
        else if (strcmp(key, "separator") == 0) { sep = ts_own_pv(aTHX_ val, &slen, NULL);
            if (SvUTF8(val)) tpl_utf8 |= TS_TPL_SEP; else tpl_utf8 &= ~TS_TPL_SEP; }
        /* everything else is inherited, so taking it here would throw
           the caller's value silently away */
        else croak("Text::Stencil: clone does not take a '%s' option"
                   " (only 'row' and 'separator'; the rest is inherited)", key);
    }
    if (!row) croak("Text::Stencil: clone requires a 'row' argument");
    tpl_compiled *t = tpl_compile(aTHX_
        orig->header, orig->header_len,
        row, rlen,
        orig->footer, orig->footer_len,
        sep ? sep : orig->sep, sep ? slen : orig->sep_len,
        orig->escape_char, tpl_utf8, err);
    if (!t || err[0]) { if (t) tpl_free(t); croak("Text::Stencil: %s", err); }
    /* Copy the skip conditions -- but a replacement row can change the row
       mode, leaving an inherited skip of the wrong kind fetching nothing from
       any row. Re-check against the template we just built, as new() does. */
    if (orig->has_skip_if)     TS_CHECK_KIND(t, "skip_if", orig->skip_if_key != NULL);
    if (orig->has_skip_unless) TS_CHECK_KIND(t, "skip_unless", orig->skip_unless_key != NULL);
    t->has_skip_if = orig->has_skip_if;
    t->skip_if_col = orig->skip_if_col;
    if (orig->skip_if_key) {
        ts_set_skip_key(aTHX_ t, &t->skip_if_key, &t->skip_if_key_len,
                        &t->skip_if_utf8, orig->skip_if_key,
                        orig->skip_if_key_len, orig->skip_if_utf8);
    }
    t->has_skip_unless = orig->has_skip_unless;
    t->skip_unless_col = orig->skip_unless_col;
    if (orig->skip_unless_key) {
        ts_set_skip_key(aTHX_ t, &t->skip_unless_key, &t->skip_unless_key_len,
                        &t->skip_unless_utf8, orig->skip_unless_key,
                        orig->skip_unless_key_len, orig->skip_unless_utf8);
    }
    SV *obj = newSViv(PTR2IV(t));
    t->owner = obj;
    sv_magicext(obj, NULL, PERL_MAGIC_ext, &ts_vtbl, (const char *)t, 0);
    SV *ref = newRV_noinc(obj);
    sv_bless(ref, self_stash);
    RETVAL = ref;
}
OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
CODE:
{
    MAGIC *mg = TS_HAS_OUR_MAGIC(self);
    tpl_compiled *t = mg ? (tpl_compiled *)mg->mg_ptr : NULL;
    /* only the owner frees, and only once nothing is still inside a call */
    if (t && t->owner == SvRV(self)) {
        mg->mg_ptr = NULL;
        t->owner = NULL;
        if (t->in_use > 0) t->doomed = 1; else tpl_free(t);
    }
}
