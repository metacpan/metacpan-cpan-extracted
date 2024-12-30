#include "xh_config.h"
#include "xh_core.h"

static const char DEF_CONTENT_KEY[] = "content";

void
xh_x2h_destroy_ctx(xh_x2h_ctx_t *ctx)
{
    if (ctx->nodes != NULL) free(ctx->nodes);
    if (ctx->tmp   != NULL) free(ctx->tmp);

    xh_destroy_opts(&ctx->opts);
}

void
xh_x2h_init_ctx(xh_x2h_ctx_t *ctx, I32 ax, I32 items)
{
    xh_opts_t *opts = NULL;
    xh_int_t   nparam = 0;

    memset(ctx, 0, sizeof(xh_x2h_ctx_t));

    opts = (xh_opts_t *) xh_get_obj_param(&nparam, ax, items, "XML::Hash::XS");
    ctx->input = xh_get_str_param(&nparam, ax, items);
    xh_merge_opts(&ctx->opts, opts, nparam, ax, items);

    if ((ctx->nodes = malloc(sizeof(xh_x2h_node_t) * ctx->opts.max_depth)) == NULL) {
        croak("Memory allocation error");
    }
    memset(ctx->nodes, 0, sizeof(xh_x2h_node_t) * ctx->opts.max_depth);
}

XH_INLINE void
xh_x2h_xpath_update(xh_char_t *xpath, xh_char_t *name, size_t name_len)
{
    size_t len;

    len = xh_strlen(xpath);
    if (name != NULL) {
        if ((len + name_len + 1) > XH_X2H_XPATH_MAX_LEN)
            croak("XPath too long");

        xpath[len++] = '/';
        for (;name_len--;) xpath[len++] = *name++;
    }
    else if (len == 0) {
        croak("Can't update xpath, something wrong!");
    }
    else {
        for (;--len && xpath[len] != '/';) {/* void */}
    }
    xpath[len] = '\0';

    xh_log_trace1("xpath: [%s]", xpath);
}

XH_INLINE xh_bool_t
xh_x2h_match_node(xh_char_t *name, size_t name_len, SV *expr)
{
    SSize_t    i, l;
    AV        *av;
    SV        *fake_str;
    xh_char_t *expr_str;
    STRLEN     expr_len;
    REGEXP    *re;
    xh_bool_t  matched;

    xh_log_trace2("match node: [%.*s]", name_len, name);

    fake_str = newSV(0);
    matched  = TRUE;

    if ( SvRXOK(expr) ) {
        re = (REGEXP *) SvRX(expr);
        if (re != NULL && pregexec(re, (char *) name, (char *) (name + name_len),
            (char *) name, name_len, fake_str, 0)
        ) {
            goto MATCHED;
        }
    }
    else if ( SvROK(expr) && SvTYPE(SvRV(expr)) == SVt_PVAV ) {
        av = (AV *) SvRV(expr);
        l  = av_len(av);
        for(i = 0; i <= l; i++) {
            expr = *av_fetch(av, i, 0);
            if ( SvRXOK(expr) ) {
                re = (REGEXP *) SvRX(expr);
                if (re != NULL && pregexec(re, (char *) name, (char *) (name + name_len),
                    (char *) name, name_len, fake_str, 0)
                ) {
                    goto MATCHED;
                }
            }
            else {
                expr_str = (xh_char_t *) SvPVutf8(expr, expr_len);
                if (name_len == expr_len && !xh_strncmp(name, expr_str, name_len)) {
                    goto MATCHED;
                }
            }
        }
    } else {
        expr_str = (xh_char_t *) SvPVutf8(expr, expr_len);
        if (name_len == expr_len && !xh_strncmp(name, expr_str, name_len)) {
            goto MATCHED;
        }
    }

    matched = FALSE;

MATCHED:
    SvREFCNT_dec(fake_str);

    return matched;
}

XH_INLINE void
xh_x2h_pass_matched_node(SV *cb, SV *val)
{
    dSP;

    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(val);
    PUTBACK;

    (void) call_sv(cb, G_DISCARD);

    FREETMPS;
    LEAVE;
}

#define NEW_STRING(s, l, f)                                             \
    (                                                                   \
        !((f) & XH_X2H_IS_NOT_BLANK) && ctx->opts.suppress_empty == XH_SUPPRESS_EMPTY_TO_UNDEF\
            ? newSV(0)                                                  \
            : !((f) & XH_X2H_IS_NOT_BLANK) && ctx->opts.suppress_empty == XH_SUPPRESS_EMPTY_TO_STRING\
                ? newSVpvn_utf8("", 0, ctx->opts.utf8)                  \
                : newSVpvn_utf8((const char *) (s), (l), ctx->opts.utf8)\
    )

#define SET_STRING(v, s, l, f)                                             \
    if (!((f) & XH_X2H_IS_NOT_BLANK) && ctx->opts.suppress_empty == XH_SUPPRESS_EMPTY_TO_UNDEF) {\
        sv_setsv((v), &PL_sv_undef);                                    \
    }                                                                   \
    else if (!((f) & XH_X2H_IS_NOT_BLANK) && ctx->opts.suppress_empty == XH_SUPPRESS_EMPTY_TO_STRING) {\
        sv_setpvn((v), "", 0);                                          \
        if (ctx->opts.utf8) SvUTF8_on(v);                               \
    }                                                                   \
    else {                                                              \
        sv_setpvn((v), (const char *) (s), (l));                        \
        if (ctx->opts.utf8) SvUTF8_on(v);                               \
    }

#define CAT_STRING(v, s, l, f)                                          \
    if (((f) & XH_X2H_IS_NOT_BLANK) || ctx->opts.suppress_empty == XH_SUPPRESS_EMPTY_NONE) {\
        if ( SvOK(v) ) {                                                \
            sv_catpvn((v), (const char *) (s), (l));                    \
        }                                                               \
        else {                                                          \
            sv_setpvn((v), (const char *) (s), (l));                    \
        }                                                               \
        if (ctx->opts.utf8) SvUTF8_on(v);                               \
    }

#define SAVE_VALUE(lv, v , s, l, f)                                     \
    xh_log_trace2("save value: [%.*s]", l, s);                          \
    if ( ((f) & XH_X2H_TAG_EXISTS) || SvOK(v) ) {                       \
        xh_log_trace0("add to array");                                  \
        /* get array if value is reference to array */                  \
        if ( SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVAV) {                 \
            av = (AV *) SvRV(v);                                        \
        }                                                               \
        /* create a new array and move value to array */                \
        else {                                                          \
            av = newAV();                                               \
            *(lv) = newRV_noinc((SV *) av);                             \
            av_store(av, 0, v);                                         \
            (v) = *(lv);                                                \
        }                                                               \
        /* add value to array */                                        \
        (lv) = av_store(av, av_len(av) + 1, NEW_STRING((s), (l), f));   \
    }                                                                   \
    else {                                                              \
        xh_log_trace0("set string");                                    \
        SET_STRING((v), (s), (l), f);                                   \
    }                                                                   \

#define _OPEN_TAG(s, l)                                                 \
    val = *lval;                                                        \
    /* if content exists that move to hash with 'content' key */        \
    if ( !SvROK(val) || SvTYPE(SvRV(val)) == SVt_PVAV ) {               \
        *lval = newRV_noinc((SV *) newHV());                            \
        if (SvROK(val) || (SvOK(val) && SvCUR(val))) {                  \
            (void) hv_store((HV *) SvRV(*lval), (const char *) content_key, (I32) content_key_len, val, 0);\
        }                                                               \
        else {                                                          \
            SvREFCNT_dec(val);                                          \
        }                                                               \
        val = *lval;                                                    \
    }                                                                   \
    extra_flags = 0;                                                    \
    if (ctx->opts.suppress_empty == XH_SUPPRESS_EMPTY_TO_UNDEF &&       \
        hv_exists((HV *) SvRV(val), (const char *) (s), ctx->opts.utf8 ? -(l) : (l))) {\
        extra_flags = XH_X2H_TAG_EXISTS;                                \
    }                                                                   \
    /* fetch existen or create empty hash entry */                      \
    lval = hv_fetch((HV *) SvRV(val), (const char *) (s), ctx->opts.utf8 ? -(l) : (l), 1);\
    /* save as empty string */                                          \
    val = *lval;                                                        \
    SAVE_VALUE(lval, val, "", 0, extra_flags)                           \
    if (++depth >= ctx->opts.max_depth) goto MAX_DEPTH_EXCEEDED;        \
    nodes[depth].lval = lval;                                           \
    nodes[depth].flags = XH_X2H_NODE_FLAG_NONE;                         \
    if (depth > 1 && ctx->opts.force_array.enable && (!SvROK(val) || SvTYPE(SvRV(val)) != SVt_PVAV) \
        && (ctx->opts.force_array.always || xh_x2h_match_node(s, l, ctx->opts.force_array.expr))\
    ) {                                                                 \
        nodes[depth].flags |= XH_X2H_NODE_FLAG_FORCE_ARRAY;             \
    }                                                                   \
    (s) = NULL;

#define OPEN_TAG(s, l)                                                  \
    xh_log_trace2("new tag: [%.*s]", l, s);                             \
    flags |= XH_X2H_TEXT_NODE;                                          \
    if (real_depth == 0) {                                              \
        if (flags & XH_X2H_ROOT_FOUND) goto INVALID_XML;                \
        flags |= XH_X2H_ROOT_FOUND;                                     \
    }                                                                   \
    if (XH_X2H_FILTER_SEARCH(flags)) {                                  \
        xh_x2h_xpath_update(ctx->xpath, s, l);                          \
        if (xh_x2h_match_node(ctx->xpath, xh_strlen(ctx->xpath), ctx->opts.filter.expr)) {\
            xh_log_trace2("match node: [%.*s]", l, s);                  \
            ctx->hash = newRV_noinc((SV *) newHV());                    \
            nodes[0].lval = lval = &ctx->hash;                          \
            depth = 0;                                                  \
            flags |= XH_X2H_FILTER_MATCHED;                             \
        }                                                               \
    }                                                                   \
    if (!XH_X2H_FILTER_SEARCH(flags)) {                                 \
        _OPEN_TAG(s, l)                                                 \
    }                                                                   \
    real_depth++;

#define _CLOSE_TAG                                                      \
    val = *nodes[depth].lval;                                           \
    if (ctx->opts.force_content && !SvROK(val)) {                       \
        lval = nodes[depth].lval;                                       \
        *lval = newRV_noinc((SV *) newHV());                            \
        (void) hv_store((HV *) SvRV(*lval), (const char *) content_key, (I32) content_key_len, val, 0);\
        val = *lval;                                                    \
    }                                                                   \
    if ((nodes[depth].flags & XH_X2H_NODE_FLAG_FORCE_ARRAY)             \
        && (!SvROK(val) || SvTYPE(SvRV(val)) != SVt_PVAV)               \
    ) {                                                                 \
        lval = nodes[depth].lval;                                       \
        av = newAV();                                                   \
        *lval = newRV_noinc((SV *) av);                                 \
        av_store(av, 0, val);                                           \
    }                                                                   \
    lval = nodes[--depth].lval;

#define CLOSE_TAG                                                       \
    xh_log_trace0("close tag");                                         \
    flags &= ~XH_X2H_TEXT_NODE;                                         \
    if (real_depth == 0) goto INVALID_XML;                              \
    if (!XH_X2H_FILTER_SEARCH(flags)) {                                 \
        _CLOSE_TAG                                                      \
    }                                                                   \
    if ((flags & XH_X2H_FILTER_MATCHED) && depth == 0) {                \
        xh_log_trace0("match node finished");                           \
        val = *nodes[0].lval;                                           \
        if (!ctx->opts.keep_root) {                                     \
            val = SvRV(val);                                            \
            hv_iterinit((HV *) val);                                    \
            val = hv_iterval((HV *) val, hv_iternext((HV *) val));      \
            SvREFCNT_inc(val);                                          \
            SvREFCNT_dec(*nodes[0].lval);                               \
        }                                                               \
        if (ctx->opts.cb == NULL) {                                     \
            av_push((AV *) SvRV(ctx->result), val);                     \
        }                                                               \
        else {                                                          \
            xh_x2h_pass_matched_node(ctx->opts.cb, val);                \
            SvREFCNT_dec(val);                                          \
        }                                                               \
        flags ^= XH_X2H_FILTER_MATCHED;                                 \
    }                                                                   \
    if ((flags & (XH_X2H_FILTER_ENABLED | XH_X2H_FILTER_MATCHED)) == XH_X2H_FILTER_ENABLED) {\
        xh_x2h_xpath_update(ctx->xpath, NULL, 0);                       \
    }                                                                   \
    real_depth--;

#define NEW_NODE_ATTRIBUTE(k, kl, v, vl)                                \
    if (!XH_X2H_FILTER_SEARCH(flags)) {                                 \
        _OPEN_TAG(k, kl)                                                \
        _NEW_TEXT(v, vl)                                                \
        _CLOSE_TAG                                                      \
    }

#define _NEW_NODE_ATTRIBUTE(k, kl, v, vl)                               \
    xh_log_trace4("new attr name: [%.*s] value: [%.*s]", kl, k, vl, v); \
    /* create hash if not created already */                            \
    if ( !SvROK(*lval) ) {                                              \
        /* destroy empty old scalar (empty string) */                   \
        SvREFCNT_dec(*lval);                                            \
        *lval = newRV_noinc((SV *) newHV());                            \
    }                                                                   \
    /* save key/value */                                                \
    (void) hv_store((HV *) SvRV(*lval), (const char *) (k), ctx->opts.utf8 ? -(kl) : (kl),\
        NEW_STRING(v, vl, flags), 0);                                          \
    (k) = (v) = NULL;

#define NEW_XML_DECL_ATTRIBUTE(k, kl, v, vl)                            \
    xh_log_trace4("new xml decl attr name: [%.*s] value: [%.*s]", kl, k, vl, v);\
    /* save encoding parameter to converter context if param found */   \
    if ((kl) == (sizeof("encoding") - 1) &&                             \
        xh_strncmp((k), XH_CHAR_CAST "encoding", sizeof("encoding") - 1) == 0) {\
        xh_str_range_copy(ctx->encoding, XH_CHAR_CAST (v), vl, XH_PARAM_LEN);\
    }                                                                   \
    (k) = (v) = NULL;

#define NEW_PI_ATTRIBUTE(k, kl, v, vl)                                  \
    xh_log_trace4("new PI attr name: [%.*s] value: [%.*s]", kl, k, vl, v);

#define NEW_ATTRIBUTE(k, kl, v, vl) NEW_NODE_ATTRIBUTE(k, kl, v, vl)

#define _NEW_TEXT(s, l)                                                 \
    val = *lval;                                                        \
    if ( SvROK(val) ) {                                                 \
        xh_log_trace0("add to array");                                  \
        /* add content to array*/                                       \
        if (SvTYPE(SvRV(val)) == SVt_PVAV) {                            \
            av = (AV *) SvRV(val);                                      \
            av_store(av, av_len(av) + 1, NEW_STRING(s, l, flags));      \
        }                                                               \
        /* save content to hash with "content" key */                   \
        else {                                                          \
            extra_flags = 0;                                            \
            if (ctx->opts.suppress_empty == XH_SUPPRESS_EMPTY_TO_UNDEF &&\
                hv_exists((HV *) SvRV(val), (const char *) content_key, (I32) content_key_len)) {\
                extra_flags = XH_X2H_TAG_EXISTS;                        \
            }                                                           \
            xh_log_trace0("save to hash");                              \
            lval = hv_fetch((HV *) SvRV(val), (const char *) content_key, (I32) content_key_len, 1);\
            val = *lval;                                                \
            SAVE_VALUE(lval, val, s, l, flags | extra_flags)            \
            lval = nodes[depth].lval;                                   \
        }                                                               \
    }                                                                   \
    else if (SvOK(val) && SvCUR(val) && !ctx->opts.merge_text) {        \
        xh_log_trace0("create a new array");                            \
        xh_log_trace1("create a new array val: %s", SvPV_nolen(val));   \
        xh_log_trace3("create a new array svrok: %d type: %d rtype: %d", SvROK(val), SvTYPE(val), SvTYPE(SvRV(val)));\
        /* content already exists, create a new array and move*/        \
        /* old and new content to array */                              \
        av = newAV();                                                   \
        *lval = newRV_noinc((SV *) av);                                 \
        av_store(av, 0, val);                                           \
        av_store(av, av_len(av) + 1, NEW_STRING(s, l, flags));          \
    }                                                                   \
    else {                                                              \
        xh_log_trace0("concat");                                        \
        /* concatenate with previous string */                          \
        CAT_STRING(val, s, l, flags)                                    \
    }                                                                   \

#define NEW_TEXT(s, l)                                                  \
    xh_log_trace2("new text: [%.*s]", l, s);                            \
    if (real_depth == 0) goto INVALID_XML;                              \
    if (!XH_X2H_FILTER_SEARCH(flags)) {                                 \
        _NEW_TEXT(s, l)                                                 \
    }

#define NEW_COMMENT(s, l) (s) = NULL;

#define NEW_CDATA(s, l) NEW_TEXT(s, l)

#define CHECK_EOF_WITH_CHUNK(loop)                                      \
    if (cur >= eof || *cur == '\0') {                                   \
        eof = cur;                                                      \
        if (terminate) goto PPCAT(loop, _FINISH);                       \
        ctx->state = PPCAT(loop, _START);                               \
        goto CHUNK_FINISH;                                              \
    }                                                                   \

#define CHECK_EOF_WITHOUT_CHUNK(loop)                                   \
    if (cur >= eof || *cur == '\0') goto PPCAT(loop, _FINISH);          \

#define CHECK_EOF(loop) CHECK_EOF_WITH_CHUNK(loop)

#define DO(loop)                                                        \
PPCAT(loop, _START):                                                    \
    CHECK_EOF(loop)                                                     \
    c = *cur++;                                                         \
    xh_log_trace3("'%c'=[0x%X] %s start", c, c, STRINGIZE(loop));       \
    switch (c) {

#define _DO(loop)                                                       \
PPCAT(loop, _START):                                                    \
    CHECK_EOF_WITHOUT_CHUNK(loop)                                       \
    c = *cur++;                                                         \
    xh_log_trace3("'%c'=[0x%X] %s start", c, c, STRINGIZE(loop));       \
    switch (c) {

#define END(loop)                                                       \
    }                                                                   \
    xh_log_trace1("           %s end", STRINGIZE(loop));                \
    goto PPCAT(loop, _START);                                           \
PPCAT(loop, _FINISH):

#define EXPECT_ANY(desc)                                                \
    default: xh_log_trace3("'%c'=[0x%X] - %s expected", c, c, desc);

#define EXPECT_CHAR(desc, c1)                                           \
    case c1: xh_log_trace3("'%c'=[0x%X] - %s expected", c, c, desc);

#define EXPECT_BLANK_WO_CR(desc)                                        \
    case ' ': case '\t': case '\n':                                     \
        xh_log_trace3("'%c'=[0x%X] - %s expected", c, c, desc);

#define EXPECT_BLANK(desc)                                              \
    case ' ': case '\t': case '\n': case '\r':                          \
        xh_log_trace3("'%c'=[0x%X] - %s expected", c, c, desc);

#define EXPECT_DIGIT(desc)                                              \
    case '0': case '1': case '2': case '3': case '4':                   \
    case '5': case '6': case '7': case '8': case '9':                   \
        xh_log_trace3("'%c'=[0x%X] - %s expected", c, c, desc);

#define EXPECT_HEX_CHAR_LC(desc)                                        \
    case 'a': case 'b': case 'c': case 'd': case 'e': case 'f':         \
        xh_log_trace3("'%c'=[0x%X] - %s expected", c, c, desc);

#define EXPECT_HEX_CHAR_UC(desc)                                        \
    case 'A': case 'B': case 'C': case 'D': case 'E': case 'F':         \
        xh_log_trace3("'%c'=[0x%X] - %s expected", c, c, desc);

#define SKIP_BLANK                                                      \
    EXPECT_BLANK("skip blank") break;

#define SCAN2(loop, c1, c2)                                             \
    DO(PPCAT(loop, _1)) EXPECT_CHAR(STRINGIZE(c1), c1)                  \
    DO(PPCAT(loop, _2)) EXPECT_CHAR(STRINGIZE(c2), c2)

#define END2(loop, stop)                                                \
    EXPECT_ANY("wrong character") goto stop;                            \
    END(PPCAT(loop, _2))          goto stop;                            \
    EXPECT_ANY("wrong character") goto stop;                            \
    END(PPCAT(loop, _1))

#define SCAN3(loop, c1, c2, c3)                                         \
    DO(PPCAT(loop, _1)) EXPECT_CHAR(STRINGIZE(c1), c1)                  \
    DO(PPCAT(loop, _2)) EXPECT_CHAR(STRINGIZE(c2), c2)                  \
    DO(PPCAT(loop, _3)) EXPECT_CHAR(STRINGIZE(c3), c3)

#define END3(loop, stop)                                                \
    EXPECT_ANY("wrong character") goto stop;                            \
    END(PPCAT(loop, _3))          goto stop;                            \
    EXPECT_ANY("wrong character") goto stop;                            \
    END(PPCAT(loop, _2))          goto stop;                            \
    EXPECT_ANY("wrong character") goto stop;                            \
    END(PPCAT(loop, _1))

#define SCAN5(loop, c1, c2, c3, c4, c5)                                 \
    SCAN3(PPCAT(loop, _1), c1, c2, c3)                                  \
    SCAN2(PPCAT(loop, _2), c4, c5)

#define END5(loop, stop)                                                \
    END2(PPCAT(loop, _2), stop)                                         \
    END3(PPCAT(loop, _1), stop)

#define SCAN6(loop, c1, c2, c3, c4, c5, c6)                             \
    SCAN3(PPCAT(loop, _1), c1, c2, c3)                                  \
    SCAN3(PPCAT(loop, _2), c4, c5, c6)

#define END6(loop, stop)                                                \
    END3(PPCAT(loop, _2), stop)                                         \
    END3(PPCAT(loop, _1), stop)

#define SCAN10(loop, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10)           \
    SCAN5(PPCAT(loop, _1), c1, c2, c3, c4, c5)                          \
    SCAN5(PPCAT(loop, _2), c6, c7, c8, c9, c10)

#define END10(loop, stop)                                               \
    END5(PPCAT(loop, _2), stop)                                         \
    END5(PPCAT(loop, _1), stop)

#define SEARCH_END_TAG                                                  \
    EXPECT_CHAR("end tag", '>')                                         \
        goto PARSE_CONTENT;                                             \
    EXPECT_CHAR("self closing tag", '/')                                \
        CLOSE_TAG                                                       \
        DO(SEARCH_END_TAG)                                              \
            EXPECT_CHAR("end tag", '>')                                 \
                goto PARSE_CONTENT;                                     \
            EXPECT_ANY("wrong character")                               \
                goto INVALID_XML;                                       \
        END(SEARCH_END_TAG)                                             \
        goto INVALID_XML;

#define SEARCH_NODE_ATTRIBUTE_VALUE(loop, top_loop, quot)               \
    EXPECT_CHAR("start attr value", quot)                               \
        content = NULL;                                                 \
        end_of_attr_value = NULL;                                       \
        flags &= ~(XH_X2H_NEED_NORMALIZE | XH_X2H_IS_NOT_BLANK);        \
        DO(PPCAT(loop, _END_ATTR_VALUE))                                \
            EXPECT_CHAR("attr value end", quot)                         \
                if (flags & XH_X2H_NEED_NORMALIZE) {                    \
                    NORMALIZE_TEXT(loop, content, end_of_attr_value - content)\
                    NEW_ATTRIBUTE(node, end - node, enc, enc_len)       \
                }                                                       \
                else if (content != NULL) {                             \
                    NEW_ATTRIBUTE(node, end - node, content, end_of_attr_value - content)\
                }                                                       \
                else {                                                  \
                    NEW_ATTRIBUTE(node, end - node, "", 0)              \
                }                                                       \
                goto top_loop;                                          \
            EXPECT_BLANK_WO_CR("blank")                                 \
                if (!ctx->opts.trim)                                    \
                    goto PPCAT(loop, _START_ATTR_VALUE);                \
                break;                                                  \
            EXPECT_CHAR("CR", '\r')                                     \
                if (content != NULL) {                                  \
                    flags |= XH_X2H_NORMALIZE_LINE_FEED;                \
                }                                                       \
                if (!ctx->opts.trim)                                    \
                    goto PPCAT(loop, _START_ATTR_VALUE);                \
                break;                                                  \
            EXPECT_CHAR("reference", '&')                               \
                flags |= (XH_X2H_NORMALIZE_REF | XH_X2H_IS_NOT_BLANK);  \
                goto PPCAT(loop, _START_ATTR_VALUE);                    \
            EXPECT_ANY("any char")                                      \
                flags |= XH_X2H_IS_NOT_BLANK;                           \
                PPCAT(loop, _START_ATTR_VALUE):                         \
                if (content == NULL) content = cur - 1;                 \
                end_of_attr_value = cur;                                \
        END(PPCAT(loop, _END_ATTR_VALUE))                               \
        goto INVALID_XML;

#define SEARCH_XML_DECL_ATTRIBUTE_VALUE(loop, top_loop, quot)           \
    EXPECT_CHAR("start attr value", quot)                               \
        content = cur;                                                  \
        DO(PPCAT(loop, _END_ATTR_VALUE))                                \
            EXPECT_CHAR("attr value end", quot)                         \
                NEW_ATTRIBUTE(node, end - node, content, cur - content - 1)\
                goto top_loop;                                          \
        END(PPCAT(loop, _END_ATTR_VALUE))                               \
        goto INVALID_XML;

#define SEARCH_ATTRIBUTE_VALUE(loop, top_loop, quot) SEARCH_NODE_ATTRIBUTE_VALUE(loop, top_loop, quot)

#define SEARCH_ATTRIBUTES(loop, search_end_tag)                         \
PPCAT(loop, _SEARCH_ATTRIBUTES_LOOP):                                   \
    DO(PPCAT(loop, _SEARCH_ATTR))                                       \
        search_end_tag                                                  \
                                                                        \
        SKIP_BLANK                                                      \
                                                                        \
        EXPECT_ANY("start attr name")                                   \
            node = cur - 1;                                             \
                                                                        \
            DO(PPCAT(loop, _PARSE_ATTR_NAME))                           \
                EXPECT_BLANK("end attr name")                           \
                    end = cur - 1;                                      \
                    xh_log_trace2("attr name: [%.*s]", end - node, node);\
                                                                        \
                    DO(PPCAT(loop, _ATTR_SKIP_BLANK))                   \
                        EXPECT_CHAR("search attr value", '=')           \
                            goto PPCAT(loop, _SEARCH_ATTRIBUTE_VALUE);  \
                        SKIP_BLANK                                      \
                        EXPECT_ANY("wrong character")                   \
                            goto INVALID_XML;                           \
                    END(PPCAT(loop, _ATTR_SKIP_BLANK))                  \
                    goto INVALID_XML;                                   \
                EXPECT_CHAR("end attr name", '=')                       \
                    end = cur - 1;                                      \
                    xh_log_trace2("attr name: [%.*s]", end - node, node);\
                                                                        \
PPCAT(loop, _SEARCH_ATTRIBUTE_VALUE):                                   \
                    DO(PPCAT(loop, _PARSE_ATTR_VALUE))                  \
                        SEARCH_ATTRIBUTE_VALUE(PPCAT(loop, _1), PPCAT(loop, _SEARCH_ATTRIBUTES_LOOP), '"')\
                        SEARCH_ATTRIBUTE_VALUE(PPCAT(loop, _2), PPCAT(loop, _SEARCH_ATTRIBUTES_LOOP), '\'')\
                        SKIP_BLANK                                      \
                        EXPECT_ANY("wrong character")                   \
                            goto INVALID_XML;                           \
                    END(PPCAT(loop, _PARSE_ATTR_VALUE))                 \
                    goto INVALID_XML;                                   \
            END(PPCAT(loop, _PARSE_ATTR_NAME))                          \
            goto INVALID_XML;                                           \
    END(PPCAT(loop, _SEARCH_ATTR))                                      \
    goto INVALID_XML;

#define SEARCH_END_XML_DECLARATION                                      \
    EXPECT_CHAR("end tag", '?')                                         \
        DO(XML_DECL_SEARCH_END_TAG2)                                    \
            EXPECT_CHAR("end tag", '>')                                 \
                goto XML_DECL_FOUND;                                    \
            EXPECT_ANY("wrong character")                               \
                goto INVALID_XML;                                       \
        END(XML_DECL_SEARCH_END_TAG2)                                   \
        goto INVALID_XML;

#define SEARCH_END_PI                                                   \
    EXPECT_CHAR("end tag", '?')                                         \
        DO(PI_SEARCH_END_TAG2)                                          \
            EXPECT_CHAR("end tag", '>')                                 \
                goto PARSE_CONTENT;                                     \
            EXPECT_ANY("wrong character")                               \
                goto INVALID_XML;                                       \
        END(PI_SEARCH_END_TAG2)                                         \
        goto INVALID_XML;

#define PARSE_DOCTYPE_END                                               \
    goto PARSE_DOCTYPE_INTSUBSET_START;

#define PARSE_DOCTYPE_LITERAL(loop, next, quot)                         \
    EXPECT_CHAR("start of literal", quot)                               \
        DO(PPCAT(loop, _END_OF_LITERAL))                                \
            EXPECT_CHAR("end of literal", quot)                         \
                next                                                    \
        END(PPCAT(loop, _END_OF_LITERAL))                               \
        goto INVALID_XML;

#define PARSE_DOCTYPE_LITERALS(prefix, next)                            \
    PARSE_DOCTYPE_LITERAL(PPCAT(prefix, _1), next, '"')\
    PARSE_DOCTYPE_LITERAL(PPCAT(prefix, _2), next, '\'')

#define PARSE_DOCTYPE_DELIM(prefix, next)                               \
    DO(PPCAT(prefix, _DOCTYPE_DELIM))                                   \
        EXPECT_BLANK("delimiter")                                       \
            DO(PPCAT(prefix, _DOCTYPE_DELIM_SKIP_BLANK))                \
                SKIP_BLANK                                              \
                next                                                    \
                EXPECT_ANY("wrong character")                           \
                    goto INVALID_XML;                                   \
            END(PPCAT(prefix, _DOCTYPE_DELIM_SKIP_BLANK))               \
            goto INVALID_XML;                                           \
        EXPECT_ANY("wrong character")                                   \
            goto INVALID_XML;                                           \
    END(PPCAT(prefix, _DOCTYPE_DELIM))                                  \
    goto INVALID_XML;

#define PARSE_DOCTYPE_SYSTEM                                            \
    SCAN5(DOCTYPE_SYSTEM, 'Y', 'S', 'T', 'E', 'M')                      \
        PARSE_DOCTYPE_DELIM(DOCTYPE_SYSTEM_LOCATION, PARSE_DOCTYPE_LITERALS(DOCTYPE_SYSTEM, PARSE_DOCTYPE_END))\
    END5(DOCTYPE_SYSTEM, INVALID_XML)                                   \
    goto INVALID_XML;

#define PARSE_DOCTYPE_PUBLIC_ID(prefix)                                 \
    PARSE_DOCTYPE_LITERAL(                                              \
        PPCAT(prefix, _1),                                              \
        PARSE_DOCTYPE_DELIM(DOCTYPE_PUBLIC_LOCATION_1, PARSE_DOCTYPE_LITERALS(DOCTYPE_PUBLIC_LOCATION_1, PARSE_DOCTYPE_END)),\
        '"'                                                             \
    )                                                                   \
    PARSE_DOCTYPE_LITERAL(                                              \
        PPCAT(prefix, _2),                                              \
        PARSE_DOCTYPE_DELIM(DOCTYPE_PUBLIC_LOCATION_2, PARSE_DOCTYPE_LITERALS(DOCTYPE_PUBLIC_LOCATION_2, PARSE_DOCTYPE_END)),\
        '\''                                                            \
    )

#define PARSE_DOCTYPE_PUBLIC                                            \
    SCAN5(DOCTYPE_PUBLIC, 'U', 'B', 'L', 'I', 'C')                      \
        PARSE_DOCTYPE_DELIM(DOCTYPE_PUBLIC_ID, PARSE_DOCTYPE_PUBLIC_ID(DOCTYPE_PUBLIC))\
    END5(DOCTYPE_PUBLIC, INVALID_XML)                                   \
    goto INVALID_XML;

#define PARSE_DOCTYPE                                                   \
    SCAN6(DOCTYPE, 'O', 'C', 'T', 'Y', 'P', 'E')                        \
        if (flags & (XH_X2H_ROOT_FOUND | XH_X2H_DOCTYPE_FOUND)) goto INVALID_XML;\
        flags |= XH_X2H_DOCTYPE_FOUND;                                  \
        DO(DOCTYPE_NAME)                                                \
            EXPECT_BLANK("delimiter")                                   \
                DO(DOCTYPE_NAME_START)                                  \
                    SKIP_BLANK                                          \
                    EXPECT_ANY("start name")                            \
                        DO(DOCTYPE_NAME_END)                            \
                            EXPECT_BLANK("end name")                    \
                                DO(DOCTYPE_NAME_BLANK)                  \
                                    SKIP_BLANK                          \
                                    EXPECT_CHAR("end doctype", '>')     \
                                        goto PARSE_CONTENT;             \
                                    EXPECT_CHAR("SYSTEM", 'S')          \
                                        PARSE_DOCTYPE_SYSTEM            \
                                    EXPECT_CHAR("PUBLIC", 'P')          \
                                        PARSE_DOCTYPE_PUBLIC            \
                                    EXPECT_CHAR("internal subset", '[') \
                                        goto PARSE_DOCTYPE_INTSUBSET;   \
                                    EXPECT_ANY("wrong character")       \
                                        goto INVALID_XML;               \
                                END(DOCTYPE_NAME_BLANK)                 \
                                goto INVALID_XML;                       \
                            EXPECT_CHAR("end doctype", '>')             \
                                goto PARSE_CONTENT;                     \
                        END(DOCTYPE_NAME_END)                           \
                        goto INVALID_XML;                               \
                END(DOCTYPE_NAME_START)                                 \
                goto INVALID_XML;                                       \
            EXPECT_ANY("wrong character")                               \
                goto INVALID_XML;                                       \
        END(DOCTYPE_NAME)                                               \
        goto INVALID_XML;                                               \
    END6(DOCTYPE, INVALID_XML)                                          \
    goto INVALID_XML;

#define PARSE_COMMENT                                                   \
    DO(COMMENT1)                                                        \
        EXPECT_CHAR("-", '-')                                           \
            content = NULL;                                             \
            DO(END_COMMENT1)                                            \
                SKIP_BLANK                                              \
                EXPECT_CHAR("1st -", '-')                               \
                    if (content == NULL) content = end = cur - 1;       \
                    DO(END_COMMENT2)                                    \
                        EXPECT_CHAR("2nd -", '-')                       \
                            DO(END_COMMENT3)                            \
                                EXPECT_CHAR(">", '>')                   \
                                    NEW_COMMENT(content, end - content) \
                                    goto PARSE_CONTENT;                 \
                                EXPECT_CHAR("2nd -", '-')               \
                                    end = cur - 2;                      \
                                    goto END_COMMENT3_START;            \
                                EXPECT_ANY("any character")             \
                                    end = cur - 1;                      \
                                    goto END_COMMENT1_START;            \
                            END(END_COMMENT3)                           \
                        EXPECT_BLANK("skip blank")                      \
                            end = cur - 1;                              \
                            goto END_COMMENT1_START;                    \
                        EXPECT_ANY("any character")                     \
                            end = cur;                                  \
                            goto END_COMMENT1_START;                    \
                    END(END_COMMENT2)                                   \
                EXPECT_ANY("any char")                                  \
                    if (content == NULL) content = cur - 1;             \
                    end = cur;                                          \
            END(END_COMMENT1)                                           \
            goto INVALID_XML;                                           \
                                                                        \
        EXPECT_ANY("wrong character")                                   \
            goto INVALID_XML;                                           \
                                                                        \
    END(COMMENT1)                                                       \
    goto INVALID_XML;

#define PARSE_CDATA                                                     \
    SCAN6(CDATA, 'C', 'D', 'A', 'T', 'A', '[')                          \
        content = end = cur;                                            \
        DO(END_CDATA1)                                                  \
            EXPECT_CHAR("1st ]", ']')                                   \
                DO(END_CDATA2)                                          \
                    EXPECT_CHAR("2nd ]", ']')                           \
                        DO(END_CDATA3)                                  \
                            EXPECT_CHAR(">", '>')                       \
                                end = cur - 3;                          \
                                NEW_CDATA(content, end - content)       \
                                goto PARSE_CONTENT;                     \
                            EXPECT_CHAR("2nd ]", ']')                   \
                                goto END_CDATA3_START;                  \
                            EXPECT_ANY("any character")                 \
                                goto END_CDATA1_START;                  \
                        END(END_CDATA3)                                 \
                    EXPECT_ANY("any character")                         \
                        goto END_CDATA1_START;                          \
                END(END_CDATA2)                                         \
                ;                                                       \
        END(END_CDATA1)                                                 \
        goto INVALID_XML;                                               \
    END6(CDATA, INVALID_XML)

#define PARSE_CDATA_WITH_TRIM                                           \
    SCAN6(CDATA_WITH_TRIM, 'C', 'D', 'A', 'T', 'A', '[')                \
        content = NULL;                                                 \
        DO(END_CDATA_WITH_TRIM1)                                        \
            SKIP_BLANK                                                  \
            EXPECT_CHAR("1st ]", ']')                                   \
                if (content == NULL) content = end = cur - 1;           \
                DO(END_CDATA_WITH_TRIM2)                                \
                    EXPECT_CHAR("2nd ]", ']')                           \
                        DO(END_CDATA_WITH_TRIM3)                        \
                            EXPECT_CHAR(">", '>')                       \
                                NEW_CDATA(content, end - content)       \
                                goto PARSE_CONTENT;                     \
                            EXPECT_CHAR("2nd ]", ']')                   \
                                end = cur - 2;                          \
                                goto END_CDATA_WITH_TRIM3_START;        \
                            EXPECT_ANY("any character")                 \
                                end = cur - 1;                          \
                                goto END_CDATA_WITH_TRIM1_START;        \
                        END(END_CDATA_WITH_TRIM3)                       \
                    EXPECT_BLANK("skip blank")                          \
                        end = cur - 1;                                  \
                        goto END_CDATA_WITH_TRIM1_START;                \
                    EXPECT_ANY("any character")                         \
                        end = cur;                                      \
                        goto END_CDATA_WITH_TRIM1_START;                \
                END(END_CDATA_WITH_TRIM2)                               \
            EXPECT_ANY("any char")                                      \
                if (content == NULL) content = cur - 1;                 \
                end = cur;                                              \
        END(END_CDATA_WITH_TRIM1)                                       \
        goto INVALID_XML;                                               \
    END6(CDATA_WITH_TRIM, INVALID_XML)

#define NORMALIZE_REFERENCE(loop)                                       \
    _DO(PPCAT(loop, _REFERENCE))                                        \
        EXPECT_CHAR("char reference", '#')                              \
            _DO(PPCAT(loop, _CHAR_REFERENCE))                           \
                EXPECT_CHAR("hex", 'x')                                 \
                    code = 0;                                           \
                    _DO(PPCAT(loop, _HEX_CHAR_REFERENCE_LOOP))          \
                        EXPECT_DIGIT("hex digit")                       \
                            code = code * 16 + (c - '0');               \
                            break;                                      \
                        EXPECT_HEX_CHAR_LC("hex a-f")                   \
                            code = code * 16 + (c - 'a') + 10;          \
                            break;                                      \
                        EXPECT_HEX_CHAR_UC("hex A-F")                   \
                            code = code * 16 + (c - 'A') + 10;          \
                            break;                                      \
                        EXPECT_CHAR("reference end", ';')               \
                            goto PPCAT(loop, _REFEFENCE_VALUE);         \
                    END(PPCAT(loop, _HEX_CHAR_REFERENCE_LOOP))          \
                    goto INVALID_REF;                                   \
                EXPECT_DIGIT("digit")                                   \
                    code = (c - '0');                                   \
                    _DO(PPCAT(loop, _CHAR_REFERENCE_LOOP))              \
                        EXPECT_DIGIT("digit")                           \
                            code = code * 10 + (c - '0');               \
                            break;                                      \
                        EXPECT_CHAR("reference end", ';')               \
                            goto PPCAT(loop, _REFEFENCE_VALUE);         \
                    END(PPCAT(loop, _CHAR_REFERENCE_LOOP))              \
                    goto INVALID_REF;                                   \
                EXPECT_ANY("any char")                                  \
                    goto INVALID_REF;                                   \
            END(PPCAT(loop, _CHAR_REFERENCE))                           \
            goto INVALID_REF;                                           \
        EXPECT_CHAR("amp or apos", 'a')                                 \
            if (xh_str_equal3(cur, 'm', 'p', ';')) {                    \
                code = '&';                                             \
                cur += 3;                                               \
                goto PPCAT(loop, _REFEFENCE_VALUE);                     \
            }                                                           \
            if (xh_str_equal4(cur, 'p', 'o', 's', ';')) {               \
                code = '\'';                                            \
                cur += 4;                                               \
                goto PPCAT(loop, _REFEFENCE_VALUE);                     \
            }                                                           \
            goto INVALID_REF;                                           \
        EXPECT_CHAR("lt", 'l')                                          \
            if (xh_str_equal2(cur, 't', ';')) {                         \
                code = '<';                                             \
                cur += 2;                                               \
                goto PPCAT(loop, _REFEFENCE_VALUE);                     \
            }                                                           \
            goto INVALID_REF;                                           \
        EXPECT_CHAR("gt", 'g')                                          \
            if (xh_str_equal2(cur, 't', ';')) {                         \
                code = '>';                                             \
                cur += 2;                                               \
                goto PPCAT(loop, _REFEFENCE_VALUE);                     \
            }                                                           \
            goto INVALID_REF;                                           \
        EXPECT_CHAR("quot", 'q')                                        \
            if (xh_str_equal4(cur, 'u', 'o', 't', ';')) {               \
                code = '"';                                             \
                cur += 4;                                               \
                goto PPCAT(loop, _REFEFENCE_VALUE);                     \
            }                                                           \
            goto INVALID_REF;                                           \
        EXPECT_ANY("any char")                                          \
            goto INVALID_REF;                                           \
    END(PPCAT(loop, _REFERENCE))                                        \
    goto INVALID_REF;                                                   \
PPCAT(loop, _REFEFENCE_VALUE):                                          \
    xh_log_trace1("parse reference value: %lu", code);                  \
    if (code == 0 || code > 0x10FFFF) goto INVALID_REF;                 \
    if (code >= 0x80) {                                                 \
        if (code < 0x800) {                                             \
            *enc_cur++ = (code >>  6) | 0xC0;  bits =  0;               \
        }                                                               \
        else if (code < 0x10000) {                                      \
            *enc_cur++ = (code >> 12) | 0xE0;  bits =  6;               \
        }                                                               \
        else if (code < 0x110000) {                                     \
            *enc_cur++ = (code >> 18) | 0xF0;  bits =  12;              \
        }                                                               \
        else {                                                          \
            goto INVALID_REF;                                           \
        }                                                               \
        for (; bits >= 0; bits-= 6) {                                   \
            *enc_cur++ = ((code >> bits) & 0x3F) | 0x80;                \
        }                                                               \
    }                                                                   \
    else {                                                              \
        *enc_cur++ = (xh_char_t) code;                                  \
    }

#define NORMALIZE_LINE_FEED(loop)                                       \
    _DO(PPCAT(loop, _NORMALIZE_LINE_FEED))                              \
        EXPECT_CHAR("LF", '\n')                                         \
            goto PPCAT(loop, _NORMALIZE_LINE_FEED_END);                 \
        EXPECT_ANY("any char")                                          \
            cur--;                                                      \
            goto PPCAT(loop, _NORMALIZE_LINE_FEED_END);                 \
    END(PPCAT(loop, _NORMALIZE_LINE_FEED))                              \
PPCAT(loop, _NORMALIZE_LINE_FEED_END):                                  \
    *enc_cur++ = '\n';

#define NORMALIZE_TEXT(loop, s, l)                                      \
    enc_len = l;                                                        \
    if (enc_len) {                                                      \
        old_cur = cur;                                                  \
        old_eof = eof;                                                  \
        cur     = s;                                                    \
        eof     = cur + enc_len;                                        \
        if (ctx->tmp == NULL) {                                         \
            xh_log_trace1("malloc() %lu", enc_len);                     \
            if ((ctx->tmp = malloc(enc_len)) == NULL) goto MALLOC;      \
            ctx->tmp_size = enc_len;                                    \
        }                                                               \
        else if (enc_len > ctx->tmp_size) {                             \
            xh_log_trace1("realloc() %lu", enc_len);                    \
            if ((enc = realloc(ctx->tmp, enc_len)) == NULL) goto MALLOC;\
            ctx->tmp = enc;                                             \
            ctx->tmp_size = enc_len;                                    \
        }                                                               \
        enc = enc_cur = ctx->tmp;                                       \
        memcpy(enc, cur, enc_len);                                      \
        _DO(PPCAT(loop, _NORMALIZE_TEXT))                               \
            EXPECT_CHAR("reference", '&')                               \
                NORMALIZE_REFERENCE(loop)                               \
                break;                                                  \
            EXPECT_CHAR("CR", '\r')                                     \
                NORMALIZE_LINE_FEED(loop)                               \
                break;                                                  \
            EXPECT_ANY("any char")                                      \
                *enc_cur++ = c;                                         \
        END(PPCAT(loop, _NORMALIZE_TEXT))                               \
        enc_len = enc_cur - enc;                                        \
        cur = old_cur;                                                  \
        eof = old_eof;                                                  \
    }                                                                   \
    else {                                                              \
        enc = s;                                                        \
    }

#define END_OF_TEXT(loop, s, l)                                         \
    if (s != NULL) {                                                    \
        if (flags & (XH_X2H_IS_NOT_BLANK | XH_X2H_TEXT_NODE)) {         \
            if (flags & XH_X2H_NEED_NORMALIZE) {                        \
                NORMALIZE_TEXT(loop, s, (l))                            \
                NEW_TEXT(enc, enc_len)                                  \
            }                                                           \
            else {                                                      \
                NEW_TEXT(s, (l))                                        \
            }                                                           \
        }                                                               \
        s = NULL;                                                       \
    }

static void
xh_x2h_parse_chunk(xh_x2h_ctx_t *ctx, xh_char_t **buf, size_t *bytesleft, xh_bool_t terminate)
{
    xh_char_t          c, *cur, *node, *end, *content, *eof, *enc,
                      *enc_cur, *old_cur, *old_eof, *content_key,
                      *end_of_attr_value;
    unsigned int       depth, real_depth, code, flags, extra_flags;
    int                bits;
    SV               **lval, *val;
    xh_x2h_node_t     *nodes;
    AV                *av;
    size_t             enc_len, content_key_len;

    cur               = *buf;
    eof               = cur + *bytesleft;
    nodes             = ctx->nodes;
    depth             = ctx->depth;
    real_depth        = ctx->real_depth;
    flags             = ctx->flags;
    node              = ctx->node;
    end               = ctx->end;
    end_of_attr_value = ctx->end_of_attr_value;
    content           = ctx->content;
    code              = ctx->code;
    lval              = ctx->lval;
    enc               = enc_cur = old_eof = old_cur = NULL;
    c                 = '\0';

    if (ctx->opts.content[0] == '\0') {
        content_key = (xh_char_t *) DEF_CONTENT_KEY;
        content_key_len = sizeof(DEF_CONTENT_KEY) - 1;
    }
    else {
        content_key = ctx->opts.content;
        content_key_len = xh_strlen(ctx->opts.content);
    }

#define XH_X2H_PROCESS_STATE(st) case st: goto st;
    switch (ctx->state) {
        case PARSER_ST_NONE: break;
        XH_X2H_PARSER_STATE_LIST
        case XML_DECL_FOUND: break;
        case PARSER_ST_DONE: goto DONE;
    }
#undef XH_X2H_PROCESS_STATE

PARSE_CONTENT:
    content = NULL;
    flags &= ~(XH_X2H_NEED_NORMALIZE | XH_X2H_IS_NOT_BLANK);
    DO(CONTENT)
        EXPECT_CHAR("new element", '<')
            DO(PARSE_ELEMENT)
                EXPECT_CHAR("xml declaration", '?')
                    if (real_depth != 0) goto INVALID_XML;
                    END_OF_TEXT(TEXT_BEFORE_XML_DECL, content, end - content)
                    SCAN3(XML_DECL, 'x', 'm', 'l')
                        DO(XML_DECL_ATTR)
                            EXPECT_BLANK("blank")
#undef  NEW_ATTRIBUTE
#define NEW_ATTRIBUTE(k, kl, v, vl) NEW_XML_DECL_ATTRIBUTE(k, kl, v, vl)
#undef  SEARCH_ATTRIBUTE_VALUE
#define SEARCH_ATTRIBUTE_VALUE(loop, top_loop, quot) SEARCH_XML_DECL_ATTRIBUTE_VALUE(loop, top_loop, quot)
                                SEARCH_ATTRIBUTES(XML_DECL_ATTR, SEARCH_END_XML_DECLARATION)
#undef  NEW_ATTRIBUTE
#define NEW_ATTRIBUTE(k, kl, v, vl) NEW_NODE_ATTRIBUTE(k, kl, v, vl)
#undef  SEARCH_ATTRIBUTE_VALUE
#define SEARCH_ATTRIBUTE_VALUE(loop, top_loop, quot) SEARCH_NODE_ATTRIBUTE_VALUE(loop, top_loop, quot)
                                goto INVALID_XML;
                            EXPECT_CHAR("PI", '-')
                                SCAN10(STYLESHEET_PI, 's', 't', 'y', 'l', 'e', 's', 'h', 'e', 'e', 't')
                                    DO(STYLESHEET_PI_ATTR)
                                        EXPECT_BLANK("blank")
#undef  NEW_ATTRIBUTE
#define NEW_ATTRIBUTE(k, kl, v, vl) NEW_PI_ATTRIBUTE(k, kl, v, vl)
#undef  SEARCH_ATTRIBUTE_VALUE
#define SEARCH_ATTRIBUTE_VALUE(loop, top_loop, quot) SEARCH_XML_DECL_ATTRIBUTE_VALUE(loop, top_loop, quot)
                                            SEARCH_ATTRIBUTES(STYLESHEET_PI_ATTR, SEARCH_END_PI)
#undef  NEW_ATTRIBUTE
#define NEW_ATTRIBUTE(k, kl, v, vl) NEW_NODE_ATTRIBUTE(k, kl, v, vl)
#undef  SEARCH_ATTRIBUTE_VALUE
#define SEARCH_ATTRIBUTE_VALUE(loop, top_loop, quot) SEARCH_NODE_ATTRIBUTE_VALUE(loop, top_loop, quot)
                                            goto INVALID_XML;
                                    EXPECT_ANY("wrong character")
                                        goto INVALID_XML;
                                    END(STYLESHEET_PI_ATTR)
                                    goto INVALID_XML;
                                END10(STYLESHEET_PI, INVALID_XML)
                                goto INVALID_XML;
                            EXPECT_ANY("wrong character")
                                goto INVALID_XML;
                        END(XML_DECL_ATTR)
                        goto INVALID_XML;
                    END3(XML_DECL, INVALID_XML)
                    goto INVALID_XML;
                EXPECT_CHAR("comment or cdata or doctype", '!')
                    flags &= ~XH_X2H_TEXT_NODE;
                    END_OF_TEXT(TEXT_BEFORE_COMMENT, content, end - content)
                    DO(XML_COMMENT_NODE_OR_CDATA)
                        EXPECT_CHAR("comment", '-')
                            PARSE_COMMENT
                        EXPECT_CHAR("cdata", '[')
                            if (ctx->opts.trim) {
                                PARSE_CDATA_WITH_TRIM
                                ;
                            }
                            else {
                                PARSE_CDATA
                                ;
                            }
                        EXPECT_CHAR("doctype", 'D')
                            PARSE_DOCTYPE
                        EXPECT_ANY("wrong character")
                            goto INVALID_XML;
                    END(XML_COMMENT_NODE_OR_CDATA)
                    goto INVALID_XML;
                EXPECT_CHAR("closing tag", '/')
                    END_OF_TEXT(TEXT_BEFORE_CLOSING_TAG, content, end - content)
                    //node = cur;
                    DO(PARSE_CLOSING_TAG)
                        EXPECT_CHAR("end tag name", '>')
                            CLOSE_TAG
                            goto PARSE_CONTENT;
                        EXPECT_BLANK("end tag name")
                            DO(SEARCH_CLOSING_END_TAG)
                                EXPECT_CHAR("end tag", '>')
                                    CLOSE_TAG
                                    goto PARSE_CONTENT;
                                SKIP_BLANK
                                EXPECT_ANY("wrong character")
                                    goto INVALID_XML;
                            END(SEARCH_CLOSING_END_TAG)
                            goto INVALID_XML;
                    END(PARSE_CLOSING_TAG)
                    goto INVALID_XML;
                EXPECT_ANY("opening tag")
                    flags &= ~XH_X2H_TEXT_NODE;
                    END_OF_TEXT(TEXT_BEFORE_OPENING_TAG, content, end - content)
                    node = cur - 1;
                    DO(PARSE_OPENING_TAG)
                        EXPECT_CHAR("end tag", '>')
                            OPEN_TAG(node, cur - node - 1)
                            goto PARSE_CONTENT;
                        EXPECT_CHAR("self closing tag", '/')
                            OPEN_TAG(node, cur - node - 1)
                            CLOSE_TAG

                            DO(SEARCH_OPENING_END_TAG)
                                EXPECT_CHAR("end tag", '>')
                                    goto PARSE_CONTENT;
                                EXPECT_ANY("wrong character")
                                    goto INVALID_XML;
                            END(SEARCH_OPENING_END_TAG)
                            goto INVALID_XML;
                        EXPECT_BLANK("end tag name")
                            OPEN_TAG(node, cur - node - 1)

                            SEARCH_ATTRIBUTES(NODE, SEARCH_END_TAG)

                            goto PARSE_CONTENT;
                    END(PARSE_OPENING_TAG);
                    goto INVALID_XML;
            END(PARSE_ELEMENT)

        EXPECT_CHAR("wrong symbol", '>')
            goto INVALID_XML;
        EXPECT_BLANK_WO_CR("blank")
            if (!ctx->opts.trim)
                goto START_CONTENT;
            break;
        EXPECT_CHAR("CR", '\r')
            if (content != NULL) {
                flags |= XH_X2H_NORMALIZE_LINE_FEED;
            }
            if (!ctx->opts.trim)
                goto START_CONTENT;
            break;
        EXPECT_CHAR("reference", '&')
            flags |= (XH_X2H_NORMALIZE_REF | XH_X2H_IS_NOT_BLANK);
            goto START_CONTENT;
        EXPECT_ANY("any char")
            flags |= XH_X2H_IS_NOT_BLANK;
            START_CONTENT:
            if (content == NULL) content = cur - 1;
            end = cur;
    END(CONTENT)

    if (
        ((content != NULL) && (flags & XH_X2H_IS_NOT_BLANK)) ||
        (real_depth != 0) ||
        !(flags & XH_X2H_ROOT_FOUND)
    ) goto INVALID_XML;

    ctx->state          = PARSER_ST_DONE;
    *bytesleft          = eof - cur;
    *buf                = cur;
    return;

PARSE_DOCTYPE_INTSUBSET:
    DO(DOCTYPE_INTSUBSET)
        EXPECT_CHAR("end of internal subset", ']')
            DO(DOCTYPE_END)
                SKIP_BLANK
                EXPECT_CHAR("end doctype", '>')
                    goto PARSE_CONTENT;
                EXPECT_ANY("wrong character")
                    goto INVALID_XML;
            END(DOCTYPE_END)
            goto INVALID_XML;
    END(DOCTYPE_INTSUBSET)
    goto INVALID_XML;

PARSE_DOCTYPE_INTSUBSET_START:
    DO(DOCTYPE_INTSUBSET_START)
        SKIP_BLANK
        EXPECT_CHAR("end doctype", '>')
            goto PARSE_CONTENT;
        EXPECT_CHAR("start of internal subset", '[')
            goto PARSE_DOCTYPE_INTSUBSET;
        EXPECT_ANY("wrong character")
            goto INVALID_XML;
    END(DOCTYPE_INTSUBSET_START)
    goto INVALID_XML;

XML_DECL_FOUND:
    ctx->state = XML_DECL_FOUND;
CHUNK_FINISH:
    ctx->content = content;
    ctx->node = node;
    ctx->end = end;
    ctx->end_of_attr_value = end_of_attr_value;
    ctx->depth = depth;
    ctx->real_depth = real_depth;
    ctx->flags = flags;
    ctx->code = code;
    ctx->lval = lval;
    *bytesleft = eof - cur;
    *buf = cur;
    return;

MAX_DEPTH_EXCEEDED:
    croak("Maximum depth exceeded");
INVALID_XML:
    croak("Invalid XML");
INVALID_REF:
    croak("Invalid reference");
MALLOC:
    croak("Memory allocation error");
DONE:
    croak("Parsing is done");
}

static void
xh_x2h_parse(xh_x2h_ctx_t *ctx, xh_reader_t *reader)
{
    xh_char_t  *buf, *preserve;
    size_t     len, off;
    xh_bool_t  eof;

    do {
        preserve = ctx->node != NULL ? ctx->node : ctx->content;

        len = reader->read(reader, &buf, preserve, &off);
        eof = (len == 0);
        if (off) {
            if (ctx->node != NULL) ctx->node -= off;
            if (ctx->content != NULL) ctx->content -= off;
            if (ctx->end != NULL) ctx->end -= off;
            if (ctx->end_of_attr_value != NULL) ctx->end_of_attr_value -= off;
        }

        xh_log_trace2("read buf: %.*s", len, buf);

        do {
            xh_log_trace2("parse buf: %.*s", len, buf);

            xh_x2h_parse_chunk(ctx, &buf, &len, eof);

            if (ctx->state == XML_DECL_FOUND && ctx->opts.encoding[0] == '\0' && ctx->encoding[0] != '\0') {
                reader->switch_encoding(reader, ctx->encoding, &buf, &len);
            }
        } while (len > 0);
    } while (!eof);

    if (ctx->state != PARSER_ST_DONE)
        croak("Invalid XML");
}

SV *
xh_x2h(xh_x2h_ctx_t *ctx)
{
    HV *hv;
    HE *he;
    SV *result;

    dXCPT;
    XCPT_TRY_START
    {
        if (ctx->opts.filter.enable) {
            ctx->flags |= XH_X2H_FILTER_ENABLED;
            if (ctx->opts.cb == NULL)
                ctx->result = newRV_noinc((SV *) newAV());
        }
        else {
            ctx->result = newRV_noinc((SV *) newHV());
            ctx->nodes[0].lval = ctx->lval = &ctx->result;
        }

        xh_reader_init(&ctx->reader, ctx->input, ctx->opts.encoding, ctx->opts.buf_size);

        xh_x2h_parse(ctx, &ctx->reader);
    } XCPT_TRY_END

    XCPT_CATCH
    {
        if (ctx->result != NULL) SvREFCNT_dec(ctx->result);
        xh_reader_destroy(&ctx->reader);
        XCPT_RETHROW;
    }

    xh_reader_destroy(&ctx->reader);

    result = ctx->result;
    if (ctx->opts.filter.enable) {
        if (ctx->opts.cb != NULL) result = NULL;
    }
    else if (!ctx->opts.keep_root) {
        hv = (HV *) SvRV(result);
        hv_iterinit(hv);
        if ((he = hv_iternext(hv))) {
            result = hv_iterval(hv, he);
            SvREFCNT_inc(result);
        }
        else {
            result = NULL;
        }
        SvREFCNT_dec(ctx->result);
    }

    return result;
}
