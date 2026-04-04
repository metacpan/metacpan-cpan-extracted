
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

/* ---- escape/format helpers ---- */

static inline int itoa_fast(char *buf, long val) {
    char tmp[20];
    int len = 0, neg = 0;
    unsigned long uval;
    if (val < 0) { neg = 1; uval = -(unsigned long)val; } else { uval = (unsigned long)val; }
    do { tmp[len++] = '0' + (uval % 10); uval /= 10; } while (uval);
    if (neg) tmp[len++] = '-';
    for (int i = 0; i < len; i++) buf[i] = tmp[len - 1 - i];
    return len;
}

static int itoa_comma(char *buf, long val) {
    char digits[20];
    int dlen = 0, neg = 0;
    unsigned long uval;
    if (val < 0) { neg = 1; uval = -(unsigned long)val; } else { uval = (unsigned long)val; }
    do { digits[dlen++] = '0' + (uval % 10); uval /= 10; } while (uval);
    int pos = 0;
    if (neg) buf[pos++] = '-';
    for (int i = dlen - 1; i >= 0; i--) {
        buf[pos++] = digits[i];
        if (i > 0 && i % 3 == 0) buf[pos++] = ',';
    }
    return pos;
}

/* lookup table for html_escape: 1 = special char */
static char html_special[256];
static char html_br_special[256];
static char json_special[256];
static int html_tables_inited = 0;

static void init_html_tables(void) {
    if (html_tables_inited) return;
    memset(html_special, 0, 256);
    html_special[(unsigned char)'&'] = 1;
    html_special[(unsigned char)'<'] = 1;
    html_special[(unsigned char)'>'] = 1;
    html_special[(unsigned char)'"'] = 1;
    html_special[(unsigned char)'\''] = 1;
    memcpy(html_br_special, html_special, 256);
    html_br_special[(unsigned char)'\n'] = 1;
    memset(json_special, 0, 256);
    json_special[(unsigned char)'"'] = 1;
    json_special[(unsigned char)'\\'] = 1;
    json_special[(unsigned char)'\b'] = 1;
    json_special[(unsigned char)'\f'] = 1;
    json_special[(unsigned char)'\n'] = 1;
    json_special[(unsigned char)'\r'] = 1;
    json_special[(unsigned char)'\t'] = 1;
    for (int i = 0; i < 0x20; i++) json_special[i] = 1;
    html_tables_inited = 1;
}

static int html_escape(char *dst, const char *src, STRLEN slen) {
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
    return (int)(out - dst);
}

static int html_br_escape(char *dst, const char *src, STRLEN slen) {
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
    return (int)(out - dst);
}

static int url_escape(char *dst, const char *src, STRLEN slen) {
    static const char hex[] = "0123456789ABCDEF";
    char *out = dst;
    for (STRLEN i = 0; i < slen; i++) {
        unsigned char c = (unsigned char)src[i];
        if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') ||
            (c >= '0' && c <= '9') || c == '-' || c == '_' || c == '.' || c == '~')
            *out++ = c;
        else { *out++ = '%'; *out++ = hex[c >> 4]; *out++ = hex[c & 0xf]; }
    }
    return (int)(out - dst);
}

static int json_escape(char *dst, const char *src, STRLEN slen) {
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
    return (int)(out - dst);
}

static int hex_encode(char *dst, const char *src, STRLEN slen) {
    static const char hex[] = "0123456789abcdef";
    for (STRLEN i = 0; i < slen; i++) {
        unsigned char c = (unsigned char)src[i];
        dst[i*2] = hex[c >> 4]; dst[i*2+1] = hex[c & 0xf];
    }
    return (int)(slen * 2);
}

static const char b64[]    = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static const char b64url[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

static int base64_encode_with(char *dst, const unsigned char *src, STRLEN slen, const char *alpha, int pad) {
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
    return (int)(out - dst);
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
    XF_MASK, XF_ROWNUM, XF_COALESCE, XF_LENGTH
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

typedef struct {
    /* static text (if chain is NULL) */
    char *static_data;  STRLEN static_len;
    /* field ref */
    int col;
    char *key;  STRLEN key_len;
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
    SSize_t last_row_count;
    char escape_char;   /* delimiter char, default '{' */
    char *render_buf;   STRLEN render_buf_alloc;
    /* skip_if / skip_unless */
    int skip_if_col;    char *skip_if_key;    STRLEN skip_if_key_len;    int has_skip_if;
    int skip_unless_col; char *skip_unless_key; STRLEN skip_unless_key_len; int has_skip_unless;
} tpl_compiled;

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
                if (x->map_keys) {
                    for (int k = 0; k < x->map_count; k++) { free(x->map_keys[k]); free(x->map_vals[k]); }
                    free(x->map_keys); free(x->map_vals); free(x->map_key_lens); free(x->map_val_lens);
                }
            }
            free(t->ops[i].chain);
        }
    }
    if (t->ops) free(t->ops);
    free(t);
}

/* parse "type" or "type:param" or "type:param1:param2" */
static tpl_xform parse_xform(const char *s, int len) {
    tpl_xform x = {XF_RAW, 0, NULL, 0, NULL, 0};
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
    else if (tlen == 6 && memcmp(s, "substr", 6) == 0) x.type = XF_SUBSTR;
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

    if (param && plen == 0 && x.type == XF_DEFAULT) {
        x.param_str = (char *)malloc(1);
        x.param_str[0] = '\0';
        x.param_str_len = 0;
    } else if (param && plen > 0) {
        if (x.type == XF_FLOAT || x.type == XF_PAD || x.type == XF_RPAD || x.type == XF_TRUNC || x.type == XF_MASK) {
            x.param_int = 0;
            for (int i = 0; i < plen; i++) x.param_int = x.param_int * 10 + (param[i] - '0');
        } else if (x.type == XF_SPRINTF) {
            x.param_str = (char *)malloc(plen + 1);
            memcpy(x.param_str, param, plen);
            x.param_str[plen] = '\0';
            x.param_str_len = plen;
        } else if (x.type == XF_REPLACE) {
            const char *c2 = memchr(param, ':', plen);
            if (c2) {
                int p1len = (int)(c2 - param);
                int p2len = plen - p1len - 1;
                if (p1len > 0) {
                    x.param_str = (char *)malloc(p1len + 1);
                    memcpy(x.param_str, param, p1len);
                    x.param_str_len = p1len;
                    x.param_str2 = (char *)malloc(p2len + 1);
                    memcpy(x.param_str2, c2 + 1, p2len);
                    x.param_str2_len = p2len;
                }
            }
        } else if (x.type == XF_SUBSTR) {
            const char *c2 = memchr(param, ':', plen);
            x.param_int = 0;
            int p1len = c2 ? (int)(c2 - param) : plen;
            for (int i = 0; i < p1len; i++) x.param_int = x.param_int * 10 + (param[i] - '0');
            x.param_int2 = -1;
            if (c2) {
                x.param_int2 = 0;
                int p2len = plen - p1len - 1;
                for (int i = 0; i < p2len; i++) x.param_int2 = x.param_int2 * 10 + (c2[1+i] - '0');
            }
        } else if (x.type == XF_PLURAL) {
            const char *c2 = memchr(param, ':', plen);
            if (c2) {
                int p1len = (int)(c2 - param);
                int p2len = plen - p1len - 1;
                x.param_str = (char *)malloc(p1len + 1);
                memcpy(x.param_str, param, p1len);
                x.param_str_len = p1len;
                x.param_str2 = (char *)malloc(p2len + 1);
                memcpy(x.param_str2, c2 + 1, p2len);
                x.param_str2_len = p2len;
            }
        } else if (x.type == XF_IF || x.type == XF_UNLESS) {
            x.param_str = (char *)malloc(plen + 1);
            memcpy(x.param_str, param, plen);
            x.param_str_len = plen;
        } else if (x.type == XF_WRAP) {
            const char *c2 = memchr(param, ':', plen);
            if (c2) {
                int p1len = (int)(c2 - param);
                int p2len = plen - p1len - 1;
                x.param_str = (char *)malloc(p1len + 1);
                memcpy(x.param_str, param, p1len);
                x.param_str_len = p1len;
                x.param_str2 = (char *)malloc(p2len + 1);
                memcpy(x.param_str2, c2 + 1, p2len);
                x.param_str2_len = p2len;
            } else {
                x.param_str = (char *)malloc(plen + 1);
                memcpy(x.param_str, param, plen);
                x.param_str_len = plen;
            }
        } else if (x.type == XF_MAP) {
            int cnt = 1;
            for (int i = 0; i < plen; i++) if (param[i] == ':') cnt++;
            x.map_keys = (char **)calloc(cnt, sizeof(char *));
            x.map_vals = (char **)calloc(cnt, sizeof(char *));
            x.map_key_lens = (STRLEN *)calloc(cnt, sizeof(STRLEN));
            x.map_val_lens = (STRLEN *)calloc(cnt, sizeof(STRLEN));
            x.map_count = 0;
            const char *p2 = param, *pe = param + plen;
            while (p2 < pe) {
                const char *next = memchr(p2, ':', pe - p2);
                if (!next) next = pe;
                const char *eq = memchr(p2, '=', next - p2);
                if (eq) {
                    int kl = (int)(eq - p2), vl = (int)(next - eq - 1);
                    int idx = x.map_count++;
                    x.map_keys[idx] = (char *)malloc(kl + 1); memcpy(x.map_keys[idx], p2, kl); x.map_key_lens[idx] = kl;
                    x.map_vals[idx] = (char *)malloc(vl + 1); memcpy(x.map_vals[idx], eq + 1, vl); x.map_val_lens[idx] = vl;
                }
                p2 = next + 1;
            }
        } else if (x.type == XF_COALESCE) {
            x.param_str = (char *)malloc(plen + 1);
            memcpy(x.param_str, param, plen);
            x.param_str[plen] = '\0';
            x.param_str_len = plen;
        } else if (x.type == XF_DEFAULT || x.type == XF_DATE) {
            x.param_str = (char *)malloc(plen + 1);
            memcpy(x.param_str, param, plen);
            x.param_str[plen] = '\0';
            x.param_str_len = plen;
        } else if (x.type == XF_BOOL) {
            const char *c2 = memchr(param, ':', plen);
            if (c2) {
                int p1len = (int)(c2 - param);
                int p2len = plen - p1len - 1;
                x.param_str = (char *)malloc(p1len + 1);
                memcpy(x.param_str, param, p1len);
                x.param_str_len = p1len;
                x.param_str2 = (char *)malloc(p2len + 1);
                memcpy(x.param_str2, c2 + 1, p2len);
                x.param_str2_len = p2len;
            } else {
                x.param_str = (char *)malloc(plen + 1);
                memcpy(x.param_str, param, plen);
                x.param_str_len = plen;
                x.param_str2 = NULL; x.param_str2_len = 0;
            }
        }
    }
    return x;
}

/* Parse "{field:type1:p1|type2:p2}" into chain */
static void parse_field_spec(const char *spec, int spec_len,
                              tpl_op *op, enum row_mode *mode) {
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
            op->chain[0] = (tpl_xform){XF_RAW, 0, NULL, 0};
            op->chain_len = 1;
            return;
        }
        goto parse_chain;
    }

    /* detect array vs hash mode */
    int is_num = 1, is_neg = 0, start_idx = 0;
    if (field_len > 0 && field[0] == '-') { is_neg = 1; start_idx = 1; }
    for (int i = start_idx; i < field_len; i++)
        if (field[i] < '0' || field[i] > '9') { is_num = 0; break; }

    if (is_num && field_len > start_idx) {
        op->col = 0;
        for (int i = start_idx; i < field_len; i++) op->col = op->col * 10 + (field[i] - '0');
        if (is_neg) op->col = -op->col;
    } else {
        *mode = ROW_HASH;
        op->key = (char *)malloc(field_len + 1);
        memcpy(op->key, field, field_len);
        op->key[field_len] = '\0';
        op->key_len = field_len;
    }

    /* parse transform chain */
    if (!sep) {
        op->chain = (tpl_xform *)malloc(sizeof(tpl_xform));
        op->chain[0] = (tpl_xform){XF_RAW, 0, NULL, 0};
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
    op->chain_len = 0;

    const char *p = xforms_start;
    const char *xend = xforms_start + xforms_len;
    while (p < xend) {
        const char *pipe = memchr(p, '|', xend - p);
        if (!pipe) pipe = xend;
        op->chain[op->chain_len++] = parse_xform(p, (int)(pipe - p));
        p = pipe + 1;
    }
}

static tpl_compiled *tpl_compile(pTHX_ const char *header, STRLEN hlen,
                                  const char *row, STRLEN rlen,
                                  const char *footer, STRLEN flen,
                                  const char *sep, STRLEN slen,
                                  char esc_char) {
    tpl_compiled *t = (tpl_compiled *)calloc(1, sizeof(tpl_compiled));
    if (hlen) { t->header = (char *)malloc(hlen); memcpy(t->header, header, hlen); } t->header_len = hlen;
    if (flen) { t->footer = (char *)malloc(flen); memcpy(t->footer, footer, flen); } t->footer_len = flen;
    if (slen) { t->sep = (char *)malloc(slen); memcpy(t->sep, sep, slen); t->sep_len = slen; }
    t->mode = ROW_ARRAY;
    t->escape_char = esc_char ? esc_char : '{';

    int cap = 16;
    t->ops = (tpl_op *)calloc(cap, sizeof(tpl_op));
    t->nops = 0;

    char close_char = (t->escape_char == '{') ? '}' : t->escape_char;
    if (t->escape_char == '[') close_char = ']';
    if (t->escape_char == '(') close_char = ')';
    if (t->escape_char == '<') close_char = '>';

    const char *p = row, *end = row + rlen;
    while (p < end) {
        const char *brace = memchr(p, t->escape_char, end - p);
        if (!brace) brace = end;
        if (brace > p) {
            if (t->nops >= cap) { cap *= 2; t->ops = (tpl_op *)realloc(t->ops, cap * sizeof(tpl_op)); if (!t->ops) croak("realloc"); memset(&t->ops[cap/2], 0, (cap/2)*sizeof(tpl_op)); }
            tpl_op *op = &t->ops[t->nops++];
            memset(op, 0, sizeof(*op));
            op->static_data = (char *)malloc(brace - p);
            memcpy(op->static_data, p, brace - p);
            op->static_len = brace - p;
        }
        if (brace >= end) break;

        /* doubled escape char (e.g. {{ ) = literal */
        if (brace + 1 < end && brace[1] == t->escape_char) {
            if (t->nops >= cap) { cap *= 2; t->ops = (tpl_op *)realloc(t->ops, cap * sizeof(tpl_op)); if (!t->ops) croak("realloc"); memset(&t->ops[cap/2], 0, (cap/2)*sizeof(tpl_op)); }
            tpl_op *op = &t->ops[t->nops++];
            memset(op, 0, sizeof(*op));
            op->static_data = (char *)malloc(1);
            op->static_data[0] = t->escape_char;
            op->static_len = 1;
            p = brace + 2;
            continue;
        }

        const char *close = memchr(brace + 1, close_char, end - brace - 1);
        if (!close) break;

        if (t->nops >= cap) { cap *= 2; t->ops = (tpl_op *)realloc(t->ops, cap * sizeof(tpl_op)); if (!t->ops) croak("realloc"); memset(&t->ops[cap/2], 0, (cap/2)*sizeof(tpl_op)); }
        tpl_op *op = &t->ops[t->nops++];
        memset(op, 0, sizeof(*op));
        parse_field_spec(brace + 1, (int)(close - brace - 1), op, &t->mode);
        p = close + 1;
    }
    return t;
}

/* ---- render ---- */

#define BUF_ENSURE(need) do { if (pos + (need) > alloc) { alloc = (pos + (need)) * 2; buf = (char *)realloc(buf, alloc); if (!buf) croak("realloc"); } } while(0)
#define BUF_WRITE(s, l) do { BUF_ENSURE(l); memcpy(buf + pos, s, l); pos += l; } while(0)

/* reusable buffer macros for render_buf */
#define RBUF_INIT(t, est) do { \
    if (t->render_buf && t->render_buf_alloc >= (est)) { \
        buf = t->render_buf; alloc = t->render_buf_alloc; \
    } else { \
        alloc = (est); buf = (char *)realloc(t->render_buf, alloc); \
        if (!buf) croak("realloc"); \
        t->render_buf = buf; t->render_buf_alloc = alloc; \
    } \
    pos = 0; \
} while(0)
#define RBUF_FINISH(t) do { t->render_buf = buf; t->render_buf_alloc = alloc; } while(0)

static inline SV *fetch_field(pTHX_ SV *row_sv, tpl_op *op, enum row_mode mode) {
    if (mode == ROW_HASH) {
        if (!SvROK(row_sv) || SvTYPE(SvRV(row_sv)) != SVt_PVHV) return NULL;
        SV **sv = hv_fetch((HV *)SvRV(row_sv), op->key, op->key_len, 0);
        return sv ? *sv : NULL;
    } else {
        if (!SvROK(row_sv) || SvTYPE(SvRV(row_sv)) != SVt_PVAV) return NULL;
        AV *av = (AV *)SvRV(row_sv);
        SV **ary = AvARRAY(av);
        SSize_t top = av_top_index(av);
        int col = op->col;
        if (col < 0) col = (int)(top + 1) + col;
        if (col >= 0 && col <= (int)top) return ary[col];
        return NULL;
    }
}

/* Apply a single transform, writing result to buf+pos or tmp */
static void apply_xform(tpl_xform *xf, const char *src, STRLEN slen,
                         char **bufp, STRLEN *posp, STRLEN *allocp,
                         char **tmpp, STRLEN *tmp_lenp, STRLEN *tmp_allocp,
                         int to_output) {
    char *buf = *bufp; STRLEN pos = *posp; STRLEN alloc = *allocp;
    char *tmp = *tmpp; STRLEN tmp_len = *tmp_lenp; STRLEN tmp_alloc = *tmp_allocp;

    /* macro to write to either output or temp */
    #define OUT_ENSURE(n) do { \
        if (to_output) { BUF_ENSURE(n); } \
        else { if ((n) > tmp_alloc || !tmp) { tmp_alloc = (n) < 1 ? 1 : (STRLEN)(n) * 2; tmp = (char *)realloc(tmp, tmp_alloc); if (!tmp) croak("realloc"); } } \
    } while(0)
    #define OUT_PTR (to_output ? buf + pos : tmp)

    switch (xf->type) {
    case XF_INT: {
        OUT_ENSURE(20);
        long v = 0; int neg = 0;
        for (STRLEN i = 0; i < slen; i++) {
            if (src[i] == '-') neg = 1;
            else if (src[i] >= '0' && src[i] <= '9') v = v * 10 + (src[i] - '0');
        }
        if (neg) v = -v;
        int w = itoa_fast(OUT_PTR, v);
        if (to_output) pos += w; else tmp_len = w;
        break;
    }
    case XF_INT_COMMA: {
        OUT_ENSURE(28);
        long v = 0; int neg = 0;
        for (STRLEN i = 0; i < slen; i++) {
            if (src[i] == '-') neg = 1;
            else if (src[i] >= '0' && src[i] <= '9') v = v * 10 + (src[i] - '0');
        }
        if (neg) v = -v;
        int w = itoa_comma(OUT_PTR, v);
        if (to_output) pos += w; else tmp_len = w;
        break;
    }
    case XF_FLOAT: {
        OUT_ENSURE(64);
        double fv = 0;
        { char tb[64]; int tl = slen < 63 ? (int)slen : 63; memcpy(tb, src, tl); tb[tl] = 0; fv = atof(tb); }
        int w = snprintf(OUT_PTR, 64, "%.*f", xf->param_int, fv);
        if (w > 63) w = 63;
        if (to_output) pos += w; else tmp_len = w;
        break;
    }
    case XF_HTML: {
        OUT_ENSURE(slen * 6);
        int needs_escape = 0;
        for (STRLEN i = 0; i < slen; i++)
            if (html_special[(unsigned char)src[i]]) { needs_escape = 1; break; }
        if (!needs_escape) {
            memcpy(OUT_PTR, src, slen);
            if (to_output) pos += slen; else tmp_len = slen;
        } else {
            int w = html_escape(OUT_PTR, src, slen);
            if (to_output) pos += w; else tmp_len = w;
        }
        break;
    }
    case XF_HTML_BR: {
        OUT_ENSURE(slen * 6);
        int needs_escape = 0;
        for (STRLEN i = 0; i < slen; i++)
            if (html_br_special[(unsigned char)src[i]]) { needs_escape = 1; break; }
        if (!needs_escape) {
            memcpy(OUT_PTR, src, slen);
            if (to_output) pos += slen; else tmp_len = slen;
        } else {
            int w = html_br_escape(OUT_PTR, src, slen);
            if (to_output) pos += w; else tmp_len = w;
        }
        break;
    }
    case XF_URL: {
        OUT_ENSURE(slen * 3);
        int w = url_escape(OUT_PTR, src, slen);
        if (to_output) pos += w; else tmp_len = w;
        break;
    }
    case XF_JSON: {
        OUT_ENSURE(slen * 6);
        int needs_escape = 0;
        for (STRLEN i = 0; i < slen; i++)
            if (json_special[(unsigned char)src[i]]) { needs_escape = 1; break; }
        if (!needs_escape) {
            memcpy(OUT_PTR, src, slen);
            if (to_output) pos += slen; else tmp_len = slen;
        } else {
            int w = json_escape(OUT_PTR, src, slen);
            if (to_output) pos += w; else tmp_len = w;
        }
        break;
    }
    case XF_TRIM: {
        const char *s = src; STRLEN l = slen;
        while (l > 0 && (*s == ' ' || *s == '\t' || *s == '\n' || *s == '\r')) { s++; l--; }
        while (l > 0 && (s[l-1] == ' ' || s[l-1] == '\t' || s[l-1] == '\n' || s[l-1] == '\r')) l--;
        OUT_ENSURE(l);
        memcpy(OUT_PTR, s, l);
        if (to_output) pos += l; else tmp_len = l;
        break;
    }
    case XF_UC: {
        OUT_ENSURE(slen);
        for (STRLEN i = 0; i < slen; i++) OUT_PTR[i] = toupper((unsigned char)src[i]);
        if (to_output) pos += slen; else tmp_len = slen;
        break;
    }
    case XF_LC: {
        OUT_ENSURE(slen);
        for (STRLEN i = 0; i < slen; i++) OUT_PTR[i] = tolower((unsigned char)src[i]);
        if (to_output) pos += slen; else tmp_len = slen;
        break;
    }
    case XF_PAD: {
        int w = xf->param_int;
        OUT_ENSURE(w > (int)slen ? w : slen);
        int pad = w - (int)slen;
        if (pad > 0) { memset(OUT_PTR, ' ', pad); memcpy(OUT_PTR + pad, src, slen); }
        else memcpy(OUT_PTR, src, slen);
        int total = pad > 0 ? w : (int)slen;
        if (to_output) pos += total; else tmp_len = total;
        break;
    }
    case XF_RPAD: {
        int w = xf->param_int;
        OUT_ENSURE(w > (int)slen ? w : slen);
        memcpy(OUT_PTR, src, slen);
        int pad = w - (int)slen;
        if (pad > 0) memset(OUT_PTR + slen, ' ', pad);
        int total = pad > 0 ? w : (int)slen;
        if (to_output) pos += total; else tmp_len = total;
        break;
    }
    case XF_TRUNC: {
        int mx = xf->param_int;
        if ((int)slen <= mx) {
            OUT_ENSURE(slen); memcpy(OUT_PTR, src, slen);
            if (to_output) pos += slen; else tmp_len = slen;
        } else {
            int tl = mx > 3 ? mx - 3 : 0;
            OUT_ENSURE(tl + 3);
            memcpy(OUT_PTR, src, tl);
            memcpy(OUT_PTR + tl, "...", 3);
            if (to_output) pos += tl + 3; else tmp_len = tl + 3;
        }
        break;
    }
    case XF_HEX: {
        OUT_ENSURE(slen * 2);
        int w = hex_encode(OUT_PTR, src, slen);
        if (to_output) pos += w; else tmp_len = w;
        break;
    }
    case XF_BASE64: {
        OUT_ENSURE(((slen + 2) / 3) * 4);
        int w = base64_encode(OUT_PTR, (const unsigned char *)src, slen);
        if (to_output) pos += w; else tmp_len = w;
        break;
    }
    case XF_BASE64URL: {
        OUT_ENSURE(((slen + 2) / 3) * 4);
        int w = base64url_encode(OUT_PTR, (const unsigned char *)src, slen);
        if (to_output) pos += w; else tmp_len = w;
        break;
    }
    case XF_COUNT: {
        OUT_ENSURE(12);
        int w = itoa_fast(OUT_PTR, xf->param_int);
        if (to_output) pos += w; else tmp_len = w;
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
        if (to_output) pos += vlen; else tmp_len = vlen;
        break;
    }
    case XF_DATE: {
        time_t epoch = 0;
        for (STRLEN i = 0; i < slen; i++) {
            if (src[i] >= '0' && src[i] <= '9') epoch = epoch * 10 + (src[i] - '0');
        }
        struct tm tm;
        gmtime_r(&epoch, &tm);
        const char *fmt = xf->param_str ? xf->param_str : "%Y-%m-%d %H:%M:%S";
        OUT_ENSURE(256);
        int w = (int)strftime(OUT_PTR, 256, fmt, &tm);
        if (to_output) pos += w; else tmp_len = w;
        break;
    }
    case XF_SPRINTF: {
        OUT_ENSURE(256);
        if (xf->param_str && xf->param_str_len > 0) {
            char last = xf->param_str[xf->param_str_len - 1];
            if (last != 'd' && last != 'i' && last != 'x' && last != 'X' &&
                last != 'o' && last != 'u' && last != 'f' && last != 'e' &&
                last != 'g' && last != 's') {
                OUT_ENSURE(slen); memcpy(OUT_PTR, src, slen);
                if (to_output) pos += slen; else tmp_len = slen;
                break;
            }
            char fmtbuf[64];
            int fmtlen = snprintf(fmtbuf, sizeof(fmtbuf), "%s%s",
                xf->param_str[0] == '%' ? "" : "%", xf->param_str);
            if (fmtlen >= (int)sizeof(fmtbuf)) {
                OUT_ENSURE(slen); memcpy(OUT_PTR, src, slen);
                if (to_output) pos += slen; else tmp_len = slen;
                break;
            }
            int pct_count = 0; int has_star = 0;
            for (int fi = 0; fi < fmtlen && fmtbuf[fi]; fi++) {
                if (fmtbuf[fi] == '%') { if (fi + 1 < fmtlen && fmtbuf[fi+1] == '%') fi++; else pct_count++; }
                else if (fmtbuf[fi] == '*') has_star = 1;
            }
            if (pct_count != 1 || has_star) {
                OUT_ENSURE(slen); memcpy(OUT_PTR, src, slen);
                if (to_output) pos += slen; else tmp_len = slen;
                break;
            }
            int w;
            if (last == 'd' || last == 'i' || last == 'x' || last == 'X' || last == 'o' || last == 'u') {
                long lv = 0; int neg = 0;
                for (STRLEN i = 0; i < slen; i++) {
                    if (src[i] == '-') neg = 1;
                    else if (src[i] >= '0' && src[i] <= '9') lv = lv * 10 + (src[i] - '0');
                }
                if (neg) lv = -lv;
                w = snprintf(OUT_PTR, 256, fmtbuf, lv);
            } else if (last == 'f' || last == 'e' || last == 'g') {
                char tb[64]; int tl = slen < 63 ? (int)slen : 63;
                memcpy(tb, src, tl); tb[tl] = 0;
                w = snprintf(OUT_PTR, 256, fmtbuf, atof(tb));
            } else {
                char tb[256]; int tl = slen < 255 ? (int)slen : 255;
                memcpy(tb, src, tl); tb[tl] = 0;
                w = snprintf(OUT_PTR, 256, fmtbuf, tb);
            }
            if (w > 255) w = 255;
            if (to_output) pos += w; else tmp_len = w;
        }
        break;
    }
    case XF_REPLACE: {
        if (!xf->param_str) {
            OUT_ENSURE(slen); memcpy(OUT_PTR, src, slen);
            if (to_output) pos += slen; else tmp_len = slen;
            break;
        }
        const char *needle = xf->param_str;
        STRLEN nlen = xf->param_str_len;
        const char *repl = xf->param_str2 ? xf->param_str2 : "";
        STRLEN rlen = xf->param_str2 ? xf->param_str2_len : 0;
        OUT_ENSURE(slen * (rlen + 1));
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
        if (to_output) pos += opos; else tmp_len = opos;
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
        OUT_ENSURE(l); memcpy(OUT_PTR, s, l);
        if (to_output) pos += l; else tmp_len = l;
        break;
    }
    case XF_PLURAL: {
        long v = 0;
        for (STRLEN i = 0; i < slen; i++)
            if (src[i] >= '0' && src[i] <= '9') v = v * 10 + (src[i] - '0');
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
        int total = nw + 1 + (int)flen;
        if (to_output) pos += total; else tmp_len = total;
        break;
    }
    case XF_IF: {
        int truthy = (slen > 0 && !(slen == 1 && src[0] == '0'));
        if (truthy && xf->param_str) {
            OUT_ENSURE(xf->param_str_len);
            memcpy(OUT_PTR, xf->param_str, xf->param_str_len);
            if (to_output) pos += xf->param_str_len; else tmp_len = xf->param_str_len;
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
            if (to_output) pos += xf->param_str_len; else tmp_len = xf->param_str_len;
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
        if (to_output) pos += vlen; else tmp_len = vlen;
        break;
    }
    case XF_WRAP: {
        if (slen > 0 && xf->param_str) {
            STRLEN plen2 = xf->param_str_len + slen + (xf->param_str2 ? xf->param_str2_len : 0);
            OUT_ENSURE(plen2);
            memcpy(OUT_PTR, xf->param_str, xf->param_str_len);
            int wpos = (int)xf->param_str_len;
            memcpy(OUT_PTR + wpos, src, slen); wpos += slen;
            if (xf->param_str2) { memcpy(OUT_PTR + wpos, xf->param_str2, xf->param_str2_len); wpos += xf->param_str2_len; }
            if (to_output) pos += wpos; else tmp_len = wpos;
        } else {
            if (!to_output) tmp_len = 0;
        }
        break;
    }
    case XF_NUMBER_SI: {
        double v = 0;
        { char tb[64]; int tl = slen < 63 ? (int)slen : 63; memcpy(tb, src, tl); tb[tl] = 0; v = atof(tb); }
        OUT_ENSURE(32);
        int w;
        if (v >= 1e15 || v <= -1e15) w = snprintf(OUT_PTR, 32, "%.1fP", v / 1e15);
        else if (v >= 1e12 || v <= -1e12) w = snprintf(OUT_PTR, 32, "%.1fT", v / 1e12);
        else if (v >= 1e9 || v <= -1e9) w = snprintf(OUT_PTR, 32, "%.1fG", v / 1e9);
        else if (v >= 1e6 || v <= -1e6) w = snprintf(OUT_PTR, 32, "%.1fM", v / 1e6);
        else if (v >= 1e3 || v <= -1e3) w = snprintf(OUT_PTR, 32, "%.1fK", v / 1e3);
        else w = snprintf(OUT_PTR, 32, "%.0f", v);
        if (w > 31) w = 31;
        if (to_output) pos += w; else tmp_len = w;
        break;
    }
    case XF_BYTES_SI: {
        double v = 0;
        { char tb[64]; int tl = slen < 63 ? (int)slen : 63; memcpy(tb, src, tl); tb[tl] = 0; v = atof(tb); }
        OUT_ENSURE(32);
        int w;
        if (v >= 1099511627776.0) w = snprintf(OUT_PTR, 32, "%.1f TB", v / 1099511627776.0);
        else if (v >= 1073741824.0) w = snprintf(OUT_PTR, 32, "%.1f GB", v / 1073741824.0);
        else if (v >= 1048576.0) w = snprintf(OUT_PTR, 32, "%.1f MB", v / 1048576.0);
        else if (v >= 1024.0) w = snprintf(OUT_PTR, 32, "%.1f KB", v / 1024.0);
        else w = snprintf(OUT_PTR, 32, "%.0f B", v);
        if (w > 31) w = 31;
        if (to_output) pos += w; else tmp_len = w;
        break;
    }
    case XF_ELAPSED: {
        long v = 0;
        for (STRLEN i = 0; i < slen; i++)
            if (src[i] >= '0' && src[i] <= '9') v = v * 10 + (src[i] - '0');
        OUT_ENSURE(64);
        int w = 0;
        if (v >= 86400 && w < 63) { int n = snprintf(OUT_PTR + w, 64 - w, "%ldd ", v / 86400); if (n > 0) w += n; v %= 86400; }
        if (v >= 3600 && w < 63)  { int n = snprintf(OUT_PTR + w, 64 - w, "%ldh ", v / 3600);  if (n > 0) w += n; v %= 3600; }
        if (v >= 60 && w < 63)    { int n = snprintf(OUT_PTR + w, 64 - w, "%ldm ", v / 60);    if (n > 0) w += n; v %= 60; }
        if (w < 63) { int n = snprintf(OUT_PTR + w, 64 - w, "%lds", v); if (n > 0) w += n; }
        if (w > 63) w = 63;
        if (to_output) pos += w; else tmp_len = w;
        break;
    }
    case XF_AGO: {
        time_t now = time(NULL);
        time_t epoch = 0;
        for (STRLEN i = 0; i < slen; i++)
            if (src[i] >= '0' && src[i] <= '9') epoch = epoch * 10 + (src[i] - '0');
        long diff = (long)(now - epoch);
        OUT_ENSURE(32);
        int w;
        if (diff < 0) w = snprintf(OUT_PTR, 32, "in the future");
        else if (diff < 60) w = snprintf(OUT_PTR, 32, "%lds ago", diff);
        else if (diff < 3600) w = snprintf(OUT_PTR, 32, "%ldm ago", diff / 60);
        else if (diff < 86400) w = snprintf(OUT_PTR, 32, "%ldh ago", diff / 3600);
        else if (diff < 2592000) w = snprintf(OUT_PTR, 32, "%ldd ago", diff / 86400);
        else if (diff < 31536000) w = snprintf(OUT_PTR, 32, "%ldmo ago", diff / 2592000);
        else w = snprintf(OUT_PTR, 32, "%ldy ago", diff / 31536000);
        if (w > 31) w = 31;
        if (to_output) pos += w; else tmp_len = w;
        break;
    }
    case XF_MASK: {
        int keep = xf->param_int;
        OUT_ENSURE(slen);
        int mask_len = (int)slen - keep;
        if (mask_len > 0) memset(OUT_PTR, '*', mask_len);
        if (keep > 0) {
            int start = mask_len > 0 ? mask_len : 0;
            int copy = keep > (int)slen ? (int)slen : keep;
            memcpy(OUT_PTR + start, src + slen - copy, copy);
        }
        int total = (int)slen;
        if (to_output) pos += total; else tmp_len = total;
        break;
    }
    case XF_LENGTH: {
        OUT_ENSURE(20);
        int w = itoa_fast(OUT_PTR, (long)slen);
        if (to_output) pos += w; else tmp_len = w;
        break;
    }
    case XF_COALESCE: /* handled in render_field, fallthrough to raw */
    case XF_ROWNUM: /* should not appear in chain; rownum is handled by render_field */
    case XF_DEFAULT:
    case XF_RAW: {
        OUT_ENSURE(slen); memcpy(OUT_PTR, src, slen);
        if (to_output) pos += slen; else tmp_len = slen;
        break;
    }
    }

    #undef OUT_ENSURE
    #undef OUT_PTR
    *bufp = buf; *posp = pos; *allocp = alloc;
    *tmpp = tmp; *tmp_lenp = tmp_len; *tmp_allocp = tmp_alloc;
}

static void render_field(pTHX_ tpl_op *op, SV *row_sv, enum row_mode mode,
                          char **bufp, STRLEN *posp, STRLEN *allocp,
                          SSize_t row_idx) {
    const char *src = NULL; STRLEN slen = 0;
    int use_default = 0;
    char rownum_buf[20]; int rownum_len = 0;

    if (op->is_rownum) {
        rownum_len = itoa_fast(rownum_buf, (long)row_idx);
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
            if (plen > 0) { primary_ok = 1; src = pstr; slen = plen; use_default = 0; }
        }
        if (!primary_ok && !op->chain[0].param_str) return;
        if (!primary_ok && op->chain[0].param_str) {
            const char *params = op->chain[0].param_str;
            STRLEN params_len = op->chain[0].param_str_len;
            const char *p = params, *pe = params + params_len;
            const char *last_param = NULL; STRLEN last_param_len = 0;
            /* find last param (the literal default) */
            const char *tp = params;
            while (tp < pe) {
                const char *next = memchr(tp, ':', pe - tp);
                if (!next) { last_param = tp; last_param_len = pe - tp; break; }
                last_param = tp; last_param_len = next - tp;
                tp = next + 1;
            }
            /* try each fallback field (all params except the last) */
            int found = 0;
            p = params;
            while (p < pe) {
                const char *next = memchr(p, ':', pe - p);
                STRLEN seg_len = next ? (STRLEN)(next - p) : (STRLEN)(pe - p);
                if (!next && p == last_param) break; /* this is the literal default */
                if (next && next + 1 >= pe) { /* second-to-last could be last_param if no more colons */ }
                /* check if this is not the last param */
                if (p != last_param || next) {
                    /* try to fetch this field from the row */
                    tpl_op tmp_op = {0};
                    if (mode == ROW_HASH) {
                        tmp_op.key = (char *)p; tmp_op.key_len = seg_len;
                    } else {
                        int is_neg = 0, si = 0;
                        if (seg_len > 0 && p[0] == '-') { is_neg = 1; si = 1; }
                        int is_num = 1;
                        for (STRLEN fi = si; fi < seg_len; fi++)
                            if (p[fi] < '0' || p[fi] > '9') { is_num = 0; break; }
                        if (is_num && seg_len > (STRLEN)si) {
                            tmp_op.col = 0;
                            for (STRLEN fi = si; fi < seg_len; fi++) tmp_op.col = tmp_op.col * 10 + (p[fi] - '0');
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
                        if (flen > 0) { sv = fallback; src = fstr; slen = flen; use_default = 0; found = 1; break; }
                    }
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
            else if (SvTYPE(inner) == SVt_PVHV) cnt = (int)HvUSEDKEYS((HV *)inner);
        }
        char cbuf[12];
        int clen = itoa_fast(cbuf, cnt);
        if (op->chain_len == 1) {
            char *buf = *bufp; STRLEN pos = *posp; STRLEN alloc = *allocp;
            BUF_ENSURE(clen); memcpy(buf + pos, cbuf, clen); pos += clen;
            *bufp = buf; *posp = pos; *allocp = alloc;
            return;
        }
        src = cbuf; slen = clen;
    }

    /* get initial string value */
    if (!use_default && !op->is_rownum && !(op->chain_len > 0 &&
        (op->chain[0].type == XF_COUNT || op->chain[0].type == XF_COALESCE))) {
        /* for int/float types as first transform, use numeric conversion */
        if (op->chain_len > 0 && (op->chain[0].type == XF_INT || op->chain[0].type == XF_INT_COMMA)) {
            char ibuf[20];
            int ilen = (op->chain[0].type == XF_INT) ? itoa_fast(ibuf, SvIV_nomg(sv)) : itoa_comma(ibuf, SvIV_nomg(sv));
            if (op->chain_len == 1) {
                char *buf = *bufp; STRLEN pos = *posp; STRLEN alloc = *allocp;
                BUF_ENSURE(ilen); memcpy(buf + pos, ibuf, ilen); pos += ilen;
                *bufp = buf; *posp = pos; *allocp = alloc;
                return;
            }
            src = ibuf; slen = ilen;
        } else if (op->chain_len > 0 && op->chain[0].type == XF_FLOAT) {
            char fbuf[64];
            int flen = snprintf(fbuf, 64, "%.*f", op->chain[0].param_int, SvNV_nomg(sv));
            if (flen > 63) flen = 63;
            if (op->chain_len == 1) {
                char *buf = *bufp; STRLEN pos = *posp; STRLEN alloc = *allocp;
                BUF_ENSURE(flen); memcpy(buf + pos, fbuf, flen); pos += flen;
                *bufp = buf; *posp = pos; *allocp = alloc;
                return;
            }
            src = fbuf; slen = flen;
        } else {
            src = SvPV_nomg(sv, slen);
        }
    }

    /* single transform fast path (most common) */
    int start = 0;
    if (!use_default && !op->is_rownum && op->chain_len > 0 &&
        (op->chain[0].type == XF_INT || op->chain[0].type == XF_INT_COMMA ||
         op->chain[0].type == XF_FLOAT || op->chain[0].type == XF_COUNT ||
         op->chain[0].type == XF_COALESCE))
        start = 1;

    if (op->chain_len - start == 0) {
        char *buf = *bufp; STRLEN pos = *posp; STRLEN alloc = *allocp;
        BUF_ENSURE(slen); memcpy(buf + pos, src, slen); pos += slen;
        *bufp = buf; *posp = pos; *allocp = alloc;
        return;
    }

    if (op->chain_len - start == 1) {
        tpl_xform *xf = &op->chain[start];
        if (xf->type == XF_DEFAULT) {
            char *buf = *bufp; STRLEN pos = *posp; STRLEN alloc = *allocp;
            BUF_ENSURE(slen); memcpy(buf + pos, src, slen); pos += slen;
            *bufp = buf; *posp = pos; *allocp = alloc;
        } else {
            char *tmp = NULL; STRLEN tmp_len = 0, tmp_alloc = 0;
            apply_xform(xf, src, slen, bufp, posp, allocp, &tmp, &tmp_len, &tmp_alloc, 1);
            if (tmp) free(tmp);
        }
        return;
    }

    /* chain: apply transforms with ping-pong buffers */
    char *tmp_a = NULL, *tmp_b = NULL;
    STRLEN tmp_a_len = 0, tmp_a_alloc = 0, tmp_b_len = 0, tmp_b_alloc = 0;
    const char *cur = src; STRLEN cur_len = slen;
    int use_a = 1;

    for (int i = start; i < op->chain_len; i++) {
        if (op->chain[i].type == XF_DEFAULT) continue;
        int is_last = 1;
        for (int k = i + 1; k < op->chain_len; k++)
            if (op->chain[k].type != XF_DEFAULT) { is_last = 0; break; }

        if (is_last) {
            char *dummy = NULL; STRLEN dummy_len = 0, dummy_alloc = 0;
            apply_xform(&op->chain[i], cur, cur_len, bufp, posp, allocp, &dummy, &dummy_len, &dummy_alloc, 1);
            if (dummy) free(dummy);
        } else {
            if (use_a) {
                tmp_a_len = 0;
                apply_xform(&op->chain[i], cur, cur_len, bufp, posp, allocp, &tmp_a, &tmp_a_len, &tmp_a_alloc, 0);
                cur = tmp_a; cur_len = tmp_a_len;
                use_a = 0;
            } else {
                tmp_b_len = 0;
                apply_xform(&op->chain[i], cur, cur_len, bufp, posp, allocp, &tmp_b, &tmp_b_len, &tmp_b_alloc, 0);
                cur = tmp_b; cur_len = tmp_b_len;
                use_a = 1;
            }
        }
    }
    if (tmp_a) free(tmp_a);
    if (tmp_b) free(tmp_b);
}

/* check if a field value in a row is truthy */
static int is_field_truthy(pTHX_ SV *row_sv, tpl_compiled *t, int is_skip_if) {
    int col; char *key; STRLEN key_len;
    if (is_skip_if) { col = t->skip_if_col; key = t->skip_if_key; key_len = t->skip_if_key_len; }
    else { col = t->skip_unless_col; key = t->skip_unless_key; key_len = t->skip_unless_key_len; }

    SV *field = NULL;
    if (key) {
        if (SvROK(row_sv) && SvTYPE(SvRV(row_sv)) == SVt_PVHV) {
            SV **sv = hv_fetch((HV *)SvRV(row_sv), key, key_len, 0);
            if (sv) field = *sv;
        }
    } else {
        if (SvROK(row_sv) && SvTYPE(SvRV(row_sv)) == SVt_PVAV) {
            AV *av = (AV *)SvRV(row_sv);
            SV **ary = AvARRAY(av);
            SSize_t top = av_top_index(av);
            if (col < 0) col = (int)(top + 1) + col;
            if (col >= 0 && col <= (int)top) field = ary[col];
        }
    }
    if (!field || !SvOK(field)) return 0;
    STRLEN flen;
    const char *fstr = SvPV(field, flen);
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
    SSize_t nrows = av_count(rows);
    t->last_row_count = nrows;
    STRLEN alloc, pos;
    char *buf;
    RBUF_INIT(t, t->header_len + t->footer_len + nrows * 300 + 1);

    BUF_WRITE(t->header, t->header_len);
    int first = 1;
    for (SSize_t i = 0; i < nrows; i++) {
        SV **rowref = av_fetch(rows, i, 0);
        if (!rowref) continue;
        if (should_skip_row(aTHX_ *rowref, t)) continue;
        if (!first && t->sep_len) BUF_WRITE(t->sep, t->sep_len);
        first = 0;
        for (int j = 0; j < t->nops; j++) {
            tpl_op *op = &t->ops[j];
            if (op->static_data)
                BUF_WRITE(op->static_data, op->static_len);
            else
                render_field(aTHX_ op, *rowref, t->mode, &buf, &pos, &alloc, i);
        }
    }
    BUF_WRITE(t->footer, t->footer_len);
    RBUF_FINISH(t);
    return newSVpvn_utf8(buf, pos, 1);
}

/* ---- sorted render ---- */

typedef struct { SV *sv; const char **keys; STRLEN *key_lens; } sort_entry;

static int sort_nsort;
static int sort_numeric;

static int sort_cmp_multi(const sort_entry *ea, const sort_entry *eb) {
    for (int k = 0; k < sort_nsort; k++) {
        if (sort_numeric) {
            char ba[64], bb[64];
            int la = ea->key_lens[k] < 63 ? (int)ea->key_lens[k] : 63;
            int lb = eb->key_lens[k] < 63 ? (int)eb->key_lens[k] : 63;
            memcpy(ba, ea->keys[k], la); ba[la] = 0;
            memcpy(bb, eb->keys[k], lb); bb[lb] = 0;
            double da = atof(ba), db = atof(bb);
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

static SV *tpl_render_sorted(pTHX_ tpl_compiled *t, AV *rows,
                              int *sort_cols, const char **sort_keys, STRLEN *sort_key_lens,
                              int nsort, int descending, int numeric) {
    SSize_t nrows = av_count(rows);
    t->last_row_count = nrows;

    sort_entry *entries = nrows > 0 ? (sort_entry *)malloc(nrows * sizeof(sort_entry)) : NULL;
    if (nrows > 0 && !entries) croak("malloc");
    const char **all_keys = nrows > 0 ? (const char **)calloc(nrows * nsort, sizeof(char *)) : NULL;
    STRLEN *all_lens = nrows > 0 ? (STRLEN *)calloc(nrows * nsort, sizeof(STRLEN)) : NULL;
    for (SSize_t i = 0; i < nrows; i++) {
        SV **rowref = av_fetch(rows, i, 0);
        entries[i].sv = rowref ? *rowref : &PL_sv_undef;
        entries[i].keys = all_keys + i * nsort;
        entries[i].key_lens = all_lens + i * nsort;
        for (int k = 0; k < nsort; k++) {
            entries[i].keys[k] = ""; entries[i].key_lens[k] = 0;
            if (rowref && SvROK(*rowref)) {
                SV *field = NULL;
                if (sort_keys) {
                    if (SvTYPE(SvRV(*rowref)) == SVt_PVHV) {
                        SV **sv = hv_fetch((HV *)SvRV(*rowref), sort_keys[k], sort_key_lens[k], 0);
                        if (sv) field = *sv;
                    }
                } else {
                    if (SvTYPE(SvRV(*rowref)) == SVt_PVAV) {
                        SV **sv = av_fetch((AV *)SvRV(*rowref), sort_cols[k], 0);
                        if (sv) field = *sv;
                    }
                }
                if (field) entries[i].keys[k] = SvPV(field, entries[i].key_lens[k]);
            }
        }
    }

    sort_nsort = nsort;
    sort_numeric = numeric;
    int (*cmp)(const void *, const void *) = descending ? sort_cmp_desc : sort_cmp_asc;
    qsort(entries, nrows, sizeof(sort_entry), cmp);

    STRLEN alloc, pos;
    char *buf;
    RBUF_INIT(t, t->header_len + t->footer_len + nrows * 300 + 1);

    BUF_WRITE(t->header, t->header_len);
    int first = 1;
    for (SSize_t i = 0; i < nrows; i++) {
        SV *row_sv = entries[i].sv;
        if (should_skip_row(aTHX_ row_sv, t)) continue;
        if (!first && t->sep_len) BUF_WRITE(t->sep, t->sep_len);
        first = 0;
        for (int j = 0; j < t->nops; j++) {
            tpl_op *op = &t->ops[j];
            if (op->static_data) BUF_WRITE(op->static_data, op->static_len);
            else render_field(aTHX_ op, row_sv, t->mode, &buf, &pos, &alloc, i);
        }
    }
    BUF_WRITE(t->footer, t->footer_len);
    if (all_keys) free(all_keys);
    if (all_lens) free(all_lens);
    free(entries);
    RBUF_FINISH(t);
    return newSVpvn_utf8(buf, pos, 1);
}

static SV *tpl_render_one(pTHX_ tpl_compiled *t, SV *row_sv) {
    if (should_skip_row(aTHX_ row_sv, t))
        return newSVpvn_utf8("", 0, 1);
    STRLEN alloc, pos;
    char *buf;
    RBUF_INIT(t, t->header_len + t->footer_len + 512);
    BUF_WRITE(t->header, t->header_len);
    for (int j = 0; j < t->nops; j++) {
        tpl_op *op = &t->ops[j];
        if (op->static_data) BUF_WRITE(op->static_data, op->static_len);
        else render_field(aTHX_ op, row_sv, t->mode, &buf, &pos, &alloc, 0);
    }
    BUF_WRITE(t->footer, t->footer_len);
    RBUF_FINISH(t);
    return newSVpvn_utf8(buf, pos, 1);
}

static void tpl_render_to_fh(pTHX_ tpl_compiled *t, AV *rows, PerlIO *fh) {
    SSize_t nrows = av_count(rows);
    t->last_row_count = nrows;
    STRLEN alloc = t->header_len + t->footer_len + nrows * 300 + 1;
    char *buf = (char *)malloc(alloc);
    if (!buf) croak("malloc");
    STRLEN pos = 0;
    BUF_WRITE(t->header, t->header_len);
    int first = 1;
    for (SSize_t i = 0; i < nrows; i++) {
        SV **rowref = av_fetch(rows, i, 0);
        if (!rowref) continue;
        if (should_skip_row(aTHX_ *rowref, t)) continue;
        if (!first && t->sep_len) BUF_WRITE(t->sep, t->sep_len);
        first = 0;
        for (int j = 0; j < t->nops; j++) {
            tpl_op *op = &t->ops[j];
            if (op->static_data) BUF_WRITE(op->static_data, op->static_len);
            else render_field(aTHX_ op, *rowref, t->mode, &buf, &pos, &alloc, i);
        }
        if (pos > 65536) { PerlIO_write(fh, buf, pos); pos = 0; }
    }
    BUF_WRITE(t->footer, t->footer_len);
    if (pos) PerlIO_write(fh, buf, pos);
    free(buf);
}

static SV *tpl_render_cb(pTHX_ tpl_compiled *t, SV *cb, PerlIO *fh) {
    STRLEN alloc, pos;
    char *buf;
    int use_fh = (fh != NULL);

    if (use_fh) {
        alloc = 65536;
        buf = (char *)malloc(alloc);
        if (!buf) croak("malloc");
    } else {
        RBUF_INIT(t, 4096);
    }
    pos = 0;

    BUF_WRITE(t->header, t->header_len);
    SSize_t row_idx = 0;
    int first = 1;
    t->last_row_count = 0;

    while (1) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        PUTBACK;
        int count = call_sv(cb, G_SCALAR);
        SPAGAIN;
        SV *row_sv = NULL;
        if (count > 0) row_sv = POPs;
        if (!row_sv || !SvOK(row_sv) || !SvROK(row_sv)) {
            PUTBACK; FREETMPS; LEAVE;
            break;
        }
        SvREFCNT_inc_simple_void_NN(row_sv);
        PUTBACK; FREETMPS; LEAVE;

        if (!should_skip_row(aTHX_ row_sv, t)) {
            if (!first && t->sep_len) BUF_WRITE(t->sep, t->sep_len);
            first = 0;
            for (int j = 0; j < t->nops; j++) {
                tpl_op *op = &t->ops[j];
                if (op->static_data) BUF_WRITE(op->static_data, op->static_len);
                else render_field(aTHX_ op, row_sv, t->mode, &buf, &pos, &alloc, row_idx);
            }
            if (use_fh && pos > 65536) { PerlIO_write(fh, buf, pos); pos = 0; }
        }
        SvREFCNT_dec(row_sv);
        row_idx++;
        t->last_row_count = row_idx;
    }

    BUF_WRITE(t->footer, t->footer_len);

    if (use_fh) {
        if (pos) PerlIO_write(fh, buf, pos);
        free(buf);
        return &PL_sv_undef;
    } else {
        RBUF_FINISH(t);
        return newSVpvn_utf8(buf, pos, 1);
    }
}

/* columns introspection */
static AV *tpl_columns(pTHX_ tpl_compiled *t) {
    AV *cols = newAV();
    for (int i = 0; i < t->nops; i++) {
        tpl_op *op = &t->ops[i];
        if (op->chain && !op->is_rownum) {
            if (op->key)
                av_push(cols, newSVpvn(op->key, op->key_len));
            else
                av_push(cols, newSViv(op->col));
        }
    }
    return cols;
}


MODULE = Text::Stencil  PACKAGE = Text::Stencil

BOOT:
    init_html_tables();

SV *
new(class, ...)
    const char *class
CODE:
{
    const char *header = "", *row = "", *footer = "", *sep = "";
    STRLEN hlen = 0, rlen = 0, flen = 0, slen = 0;
    char esc = 0;
    SV *skip_if_sv = NULL, *skip_unless_sv = NULL;
    /* shorthand: Text::Stencil->new($row_template) */
    if (items == 2 && SvPOK(ST(1))) {
        row = SvPV(ST(1), rlen);
    } else {
    if (items % 2 == 0) croak("Odd number of arguments");
    for (int i = 1; i < items; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);
        if (strcmp(key, "header") == 0) header = SvPV(val, hlen);
        else if (strcmp(key, "row") == 0) row = SvPV(val, rlen);
        else if (strcmp(key, "footer") == 0) footer = SvPV(val, flen);
        else if (strcmp(key, "separator") == 0) sep = SvPV(val, slen);
        else if (strcmp(key, "escape_char") == 0) { STRLEN el; const char *ev = SvPV(val, el); if (el) esc = ev[0]; }
        else if (strcmp(key, "skip_if") == 0) skip_if_sv = val;
        else if (strcmp(key, "skip_unless") == 0) skip_unless_sv = val;
    }
    }
    tpl_compiled *t = tpl_compile(aTHX_ header, hlen, row, rlen, footer, flen, sep, slen, esc);
    if (skip_if_sv) {
        t->has_skip_if = 1;
        if (SvIOK(skip_if_sv) || looks_like_number(skip_if_sv)) {
            t->skip_if_col = SvIV(skip_if_sv);
        } else {
            STRLEN kl;
            const char *ks = SvPV(skip_if_sv, kl);
            t->skip_if_key = (char *)malloc(kl + 1);
            memcpy(t->skip_if_key, ks, kl);
            t->skip_if_key[kl] = '\0';
            t->skip_if_key_len = kl;
        }
    }
    if (skip_unless_sv) {
        t->has_skip_unless = 1;
        if (SvIOK(skip_unless_sv) || looks_like_number(skip_unless_sv)) {
            t->skip_unless_col = SvIV(skip_unless_sv);
        } else {
            STRLEN kl;
            const char *ks = SvPV(skip_unless_sv, kl);
            t->skip_unless_key = (char *)malloc(kl + 1);
            memcpy(t->skip_unless_key, ks, kl);
            t->skip_unless_key[kl] = '\0';
            t->skip_unless_key_len = kl;
        }
    }
    SV *obj = newSViv(PTR2IV(t));
    SV *ref = newRV_noinc(obj);
    sv_bless(ref, gv_stashpv(class, GV_ADD));
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
    tpl_compiled *t = INT2PTR(tpl_compiled *, SvIV(SvRV(self)));
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
    tpl_compiled *t = INT2PTR(tpl_compiled *, SvIV(SvRV(self)));
    int descending = 0, numeric = 0;
    if (items > 3 && SvROK(ST(3)) && SvTYPE(SvRV(ST(3))) == SVt_PVHV) {
        HV *opts = (HV *)SvRV(ST(3));
        SV **sv;
        sv = hv_fetchs(opts, "descending", 0);
        if (sv && SvTRUE(*sv)) descending = 1;
        sv = hv_fetchs(opts, "numeric", 0);
        if (sv && SvTRUE(*sv)) numeric = 1;
    }
    if (SvROK(sort_by) && SvTYPE(SvRV(sort_by)) == SVt_PVAV) {
        AV *sort_av = (AV *)SvRV(sort_by);
        int nsort = (int)av_count(sort_av);
        if (nsort == 0) {
            RETVAL = tpl_render(aTHX_ t, rows);
        } else {
            SV **first = av_fetch(sort_av, 0, 0);
            int use_keys = first && !SvIOK(*first) && !looks_like_number(*first);
            if (use_keys) {
                const char **skeys = (const char **)malloc(nsort * sizeof(char *));
                STRLEN *sklens = (STRLEN *)malloc(nsort * sizeof(STRLEN));
                for (int i = 0; i < nsort; i++) {
                    SV **el = av_fetch(sort_av, i, 0);
                    skeys[i] = el ? SvPV(*el, sklens[i]) : "";
                    if (!el) sklens[i] = 0;
                }
                RETVAL = tpl_render_sorted(aTHX_ t, rows, NULL, skeys, sklens, nsort, descending, numeric);
                free(skeys); free(sklens);
            } else {
                int *scols = (int *)malloc(nsort * sizeof(int));
                for (int i = 0; i < nsort; i++) {
                    SV **el = av_fetch(sort_av, i, 0);
                    scols[i] = el ? (int)SvIV(*el) : 0;
                }
                RETVAL = tpl_render_sorted(aTHX_ t, rows, scols, NULL, NULL, nsort, descending, numeric);
                free(scols);
            }
        }
    } else if (SvIOK(sort_by) || looks_like_number(sort_by)) {
        int col = (int)SvIV(sort_by);
        RETVAL = tpl_render_sorted(aTHX_ t, rows, &col, NULL, NULL, 1, descending, numeric);
    } else {
        STRLEN klen;
        const char *key = SvPV(sort_by, klen);
        if (klen > 1 && key[0] == '-') { key++; klen--; descending = 1; }
        RETVAL = tpl_render_sorted(aTHX_ t, rows, NULL, &key, &klen, 1, descending, numeric);
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
    tpl_compiled *t = INT2PTR(tpl_compiled *, SvIV(SvRV(self)));
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
    tpl_compiled *t = INT2PTR(tpl_compiled *, SvIV(SvRV(self)));
    tpl_render_to_fh(aTHX_ t, rows, fh);
}

SV *
render_cb(self, cb, ...)
    SV *self
    SV *cb
CODE:
{
    tpl_compiled *t = INT2PTR(tpl_compiled *, SvIV(SvRV(self)));
    if (!SvROK(cb) || SvTYPE(SvRV(cb)) != SVt_PVCV)
        croak("render_cb: second argument must be a coderef");
    PerlIO *fh = NULL;
    if (items > 2) {
        fh = IoIFP(sv_2io(ST(2)));
    }
    RETVAL = tpl_render_cb(aTHX_ t, cb, fh);
}
OUTPUT:
    RETVAL

AV *
columns(self)
    SV *self
CODE:
{
    tpl_compiled *t = INT2PTR(tpl_compiled *, SvIV(SvRV(self)));
    RETVAL = tpl_columns(aTHX_ t);
}
OUTPUT:
    RETVAL

IV
row_count(self)
    SV *self
CODE:
{
    tpl_compiled *t = INT2PTR(tpl_compiled *, SvIV(SvRV(self)));
    RETVAL = (IV)t->last_row_count;
}
OUTPUT:
    RETVAL

SV *
clone(self, ...)
    SV *self
CODE:
{
    tpl_compiled *orig = INT2PTR(tpl_compiled *, SvIV(SvRV(self)));
    if (items % 2 == 0) croak("Odd number of arguments");
    const char *row = NULL; STRLEN rlen = 0;
    const char *sep = NULL; STRLEN slen = 0;
    for (int i = 1; i < items; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);
        if (strcmp(key, "row") == 0) row = SvPV(val, rlen);
        else if (strcmp(key, "separator") == 0) sep = SvPV(val, slen);
    }
    if (!row) croak("clone requires 'row' argument");
    tpl_compiled *t = tpl_compile(aTHX_
        orig->header, orig->header_len,
        row, rlen,
        orig->footer, orig->footer_len,
        sep ? sep : orig->sep, sep ? slen : orig->sep_len,
        orig->escape_char);
    /* copy skip conditions from original */
    t->has_skip_if = orig->has_skip_if;
    t->skip_if_col = orig->skip_if_col;
    if (orig->skip_if_key) {
        t->skip_if_key = (char *)malloc(orig->skip_if_key_len + 1);
        memcpy(t->skip_if_key, orig->skip_if_key, orig->skip_if_key_len + 1);
        t->skip_if_key_len = orig->skip_if_key_len;
    }
    t->has_skip_unless = orig->has_skip_unless;
    t->skip_unless_col = orig->skip_unless_col;
    if (orig->skip_unless_key) {
        t->skip_unless_key = (char *)malloc(orig->skip_unless_key_len + 1);
        memcpy(t->skip_unless_key, orig->skip_unless_key, orig->skip_unless_key_len + 1);
        t->skip_unless_key_len = orig->skip_unless_key_len;
    }
    SV *obj = newSViv(PTR2IV(t));
    SV *ref = newRV_noinc(obj);
    sv_bless(ref, SvSTASH(SvRV(self)));
    RETVAL = ref;
}
OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
CODE:
{
    tpl_compiled *t = INT2PTR(tpl_compiled *, SvIV(SvRV(self)));
    tpl_free(t);
}
