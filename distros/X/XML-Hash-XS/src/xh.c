#include "xh_config.h"
#include "xh_core.h"

xh_bool_t
xh_init_opts(xh_opts_t *opts)
{
    xh_char_t method[XH_PARAM_LEN];
    xh_bool_t use_attr;

    XH_PARAM_READ_INIT

    /* native options */
    XH_PARAM_READ_STRING (opts->root,          "XML::Hash::XS::root",          XH_DEF_ROOT);
    XH_PARAM_READ_STRING (opts->version,       "XML::Hash::XS::version",       XH_DEF_VERSION);
    XH_PARAM_READ_STRING (opts->encoding,      "XML::Hash::XS::encoding",      XH_DEF_ENCODING);
    XH_PARAM_READ_INT    (opts->indent,        "XML::Hash::XS::indent",        XH_DEF_INDENT);
    XH_PARAM_READ_BOOL   (opts->canonical,     "XML::Hash::XS::canonical",     XH_DEF_CANONICAL);
    XH_PARAM_READ_STRING (opts->content,       "XML::Hash::XS::content",       XH_DEF_CONTENT);
    XH_PARAM_READ_BOOL   (opts->utf8,          "XML::Hash::XS::utf8",          XH_DEF_UTF8);
    XH_PARAM_READ_BOOL   (opts->xml_decl,      "XML::Hash::XS::xml_decl",      XH_DEF_XML_DECL);
    XH_PARAM_READ_BOOL   (opts->keep_root,     "XML::Hash::XS::keep_root",     XH_DEF_KEEP_ROOT);
#ifdef XH_HAVE_DOM
    XH_PARAM_READ_BOOL   (opts->doc,           "XML::Hash::XS::doc",           XH_DEF_DOC);
#endif
    XH_PARAM_READ_BOOL   (use_attr,            "XML::Hash::XS::use_attr",      XH_DEF_USE_ATTR);
    XH_PARAM_READ_INT    (opts->max_depth,     "XML::Hash::XS::max_depth",     XH_DEF_MAX_DEPTH);
    XH_PARAM_READ_INT    (opts->buf_size,      "XML::Hash::XS::buf_size",      XH_DEF_BUF_SIZE);
    XH_PARAM_READ_PATTERN(opts->force_array,   "XML::Hash::XS::force_array",   XH_DEF_FORCE_ARRAY);
    XH_PARAM_READ_BOOL   (opts->force_content, "XML::Hash::XS::force_content", XH_DEF_FORCE_CONTENT);
    XH_PARAM_READ_BOOL   (opts->merge_text,    "XML::Hash::XS::merge_text",    XH_DEF_MERGE_TEXT);

    /* XML::Hash::LX options */
    XH_PARAM_READ_STRING (opts->attr,          "XML::Hash::XS::attr",          XH_DEF_ATTR);
    opts->attr_len = xh_strlen(opts->attr);
    XH_PARAM_READ_STRING (opts->text,          "XML::Hash::XS::text",          XH_DEF_TEXT);
    XH_PARAM_READ_BOOL   (opts->trim,          "XML::Hash::XS::trim",          XH_DEF_TRIM);
    XH_PARAM_READ_STRING (opts->cdata,         "XML::Hash::XS::cdata",         XH_DEF_CDATA);
    XH_PARAM_READ_STRING (opts->comm,          "XML::Hash::XS::comm",          XH_DEF_COMM);

    /* method */
    XH_PARAM_READ_STRING (method,              "XML::Hash::XS::method",        XH_DEF_METHOD);
    if (xh_strcmp(method, XH_CHAR_CAST "LX") == 0) {
        opts->method = XH_METHOD_LX;
    }
    else if (use_attr) {
        opts->method = XH_METHOD_NATIVE_ATTR_MODE;
    }
    else {
        opts->method = XH_METHOD_NATIVE;
    }

    /* output, NULL - to string */
    XH_PARAM_READ_REF    (opts->output,        "XML::Hash::XS::output",        XH_DEF_OUTPUT);

    /* suppress empty */
    if ( (sv = get_sv("XML::Hash::XS::suppress_empty", 0)) != NULL ) {
        if ( SvOK(sv) ) {
            if (SvTYPE(sv) == SVt_IV) {
                opts->suppress_empty = SvIV(sv);
            }
            else {
                opts->suppress_empty = XH_SUPPRESS_EMPTY_TO_STRING;
            }
        }
        else {
            opts->suppress_empty = XH_SUPPRESS_EMPTY_TO_UNDEF;
        }
    }
    else {
        opts->suppress_empty = XH_DEF_SUPPRESS_EMPTY;
    }

    return TRUE;
}

xh_opts_t *
xh_create_opts(void)
{
    xh_opts_t *opts;

    if ((opts = malloc(sizeof(xh_opts_t))) == NULL) {
        return NULL;
    }
    memset(opts, 0, sizeof(xh_opts_t));

    if (! xh_init_opts(opts)) {
        xh_destroy_opts(opts);
        return NULL;
    }

    return opts;
}

void
xh_destroy_opts(xh_opts_t *opts)
{
    if (opts->force_array.expr != NULL)
        SvREFCNT_dec(opts->force_array.expr);

    if (opts->filter.expr != NULL)
        SvREFCNT_dec(opts->filter.expr);

    if (opts->cb != NULL)
        SvREFCNT_dec(opts->cb);
}

void
xh_copy_opts(xh_opts_t *dst, xh_opts_t *src)
{
    memcpy(dst, src, sizeof(xh_opts_t));
    if (dst->force_array.expr != NULL) {
        SvREFCNT_inc(dst->force_array.expr);
    }
}

void
xh_parse_param(xh_opts_t *opts, xh_int_t first, I32 ax, I32 items)
{
    xh_int_t   i;
    xh_char_t *p, *cv;
    SV        *v;
    STRLEN     len;
    xh_int_t   use_attr = -1;

    if ((items - first) % 2 != 0) {
        croak("Odd number of parameters in new()");
    }

    for (i = first; i < items; i = i + 2) {
        v = ST(i);
        if (!SvOK(v)) {
            croak("Parameter name is undefined");
        }

        p = XH_CHAR_CAST SvPV(v, len);
        v = ST(i + 1);

        switch (len) {
            case 2:
                if (xh_str_equal2(p, 'c', 'b')) {
                    opts->cb = xh_param_assign_cb("cb", v);
                    break;
                }
                goto error;
#ifdef XH_HAVE_DOM
            case 3:
                if (xh_str_equal3(p, 'd', 'o', 'c')) {
                    opts->doc = xh_param_assign_bool(v);
                    break;
                }
                goto error;
#endif
            case 4:
                if (xh_str_equal4(p, 'a', 't', 't', 'r')) {
                    xh_param_assign_string(opts->attr, v);
                    if (opts->attr[0] == '\0') {
                        opts->attr_len = 0;
                    }
                    else {
                        opts->attr_len = xh_strlen(opts->attr);
                    }
                    break;
                }
                if (xh_str_equal4(p, 'c', 'o', 'm', 'm')) {
                    xh_param_assign_string(opts->comm, v);
                    break;
                }
                if (xh_str_equal4(p, 'r', 'o', 'o', 't')) {
                    xh_param_assign_string(opts->root, v);
                    break;
                }
                if (xh_str_equal4(p, 't', 'r', 'i', 'm')) {
                    opts->trim = xh_param_assign_bool(v);
                    break;
                }
                if (xh_str_equal4(p, 't', 'e', 'x', 't')) {
                    xh_param_assign_string(opts->text, v);
                    break;
                }
                if (xh_str_equal4(p, 'u', 't', 'f', '8')) {
                    opts->utf8 = xh_param_assign_bool(v);
                    break;
                }
                goto error;
            case 5:
                if (xh_str_equal5(p, 'c', 'd', 'a', 't', 'a')) {
                    xh_param_assign_string(opts->cdata, v);
                    break;
                }
                goto error;
            case 6:
                if (xh_str_equal6(p, 'i', 'n', 'd', 'e', 'n', 't')) {
                    xh_param_assign_int(p, &opts->indent, v);
                    break;
                }
                if (xh_str_equal6(p, 'm', 'e', 't', 'h', 'o', 'd')) {
                    if (!SvOK(v)) {
                        croak("Parameter '%s' is undefined", p);
                    }
                    cv = XH_CHAR_CAST SvPV(v, len);
                    switch  (len) {
                        case 6:
                            if (xh_str_equal6(cv, 'N', 'A', 'T', 'I', 'V', 'E')) {
                                opts->method = XH_METHOD_NATIVE;
                                break;
                            }
                            goto error_value;
                        case 2:
                            if (cv[0] == 'L' && cv[1] == 'X') {
                                opts->method = XH_METHOD_LX;
                                break;
                            }
                            goto error_value;
                        default:
                            goto error_value;
                    }
                    break;
                }
                if (xh_str_equal6(p, 'o', 'u', 't', 'p', 'u', 't')) {
                    if ( SvOK(v) && SvROK(v) ) {
                        opts->output = SvRV(v);
                    }
                    else {
                        opts->output = NULL;
                    }
                    break;
                }
                if (xh_str_equal6(p, 'f', 'i', 'l', 't', 'e', 'r')) {
                    xh_param_assign_filter(&opts->filter, v);
                    break;
                }
                goto error;
            case 7:
                if (xh_str_equal7(p, 'c', 'o', 'n', 't', 'e', 'n', 't')) {
                    xh_param_assign_string(opts->content, v);
                    break;
                }
                if (xh_str_equal7(p, 'v', 'e', 'r', 's', 'i', 'o', 'n')) {
                    xh_param_assign_string(opts->version, v);
                    break;
                }
                goto error;
            case 8:
                if (xh_str_equal8(p, 'e', 'n', 'c', 'o', 'd', 'i', 'n', 'g')) {
                    xh_param_assign_string(opts->encoding, v);
                    break;
                }
                if (xh_str_equal8(p, 'u', 's', 'e', '_', 'a', 't', 't', 'r')) {
                    use_attr = xh_param_assign_bool(v);
                    break;
                }
                if (xh_str_equal8(p, 'x', 'm', 'l', '_', 'd', 'e', 'c', 'l')) {
                    opts->xml_decl = xh_param_assign_bool(v);
                    break;
                }
                if (xh_str_equal8(p, 'b', 'u', 'f', '_', 's', 'i', 'z', 'e')) {
                    xh_param_assign_int(p, &opts->buf_size, v);
                    break;
                }
                goto error;
            case 9:
                if (xh_str_equal9(p, 'c', 'a', 'n', 'o', 'n', 'i', 'c', 'a', 'l')) {
                    opts->canonical = xh_param_assign_bool(v);
                    break;
                }
                if (xh_str_equal9(p, 'm', 'a', 'x', '_', 'd', 'e', 'p', 't', 'h')) {
                    xh_param_assign_int(p, &opts->max_depth, v);
                    break;
                }
                if (xh_str_equal9(p, 'k', 'e', 'e', 'p', '_', 'r', 'o', 'o', 't')) {
                    opts->keep_root = xh_param_assign_bool(v);
                    break;
                }
                goto error;
            case 10:
                if (xh_str_equal10(p, 'm', 'e', 'r', 'g', 'e', '_', 't', 'e', 'x', 't')) {
                    opts->merge_text = xh_param_assign_bool(v);
                    break;
                }
                goto error;
            case 11:
                if (xh_str_equal11(p, 'f', 'o', 'r', 'c', 'e', '_', 'a', 'r', 'r', 'a', 'y')) {
                    xh_param_assign_pattern(&opts->force_array, v);
                    break;
                }
                goto error;
            case 13:
                if (xh_str_equal13(p, 'f', 'o', 'r', 'c', 'e', '_', 'c', 'o', 'n', 't', 'e', 'n', 't')) {
                    opts->force_content = xh_param_assign_bool(v);
                    break;
                }
            case 14:
                if (xh_str_equal14(p, 's', 'u', 'p', 'p', 'r', 'e', 's', 's', '_', 'e', 'm', 'p', 't', 'y')) {
                    if (SvOK(v)) {
                        if (SvTYPE(v) == SVt_IV) {
                            opts->suppress_empty = SvIV(v);
                        }
                        else {
                            opts->suppress_empty = XH_SUPPRESS_EMPTY_TO_STRING;
                        }
                    }
                    else {
                        opts->suppress_empty = XH_SUPPRESS_EMPTY_TO_UNDEF;
                    }
                    break;
                }
            default:
                goto error;
        }
    }

    if (use_attr != -1 && (opts->method == XH_METHOD_NATIVE || opts->method == XH_METHOD_NATIVE_ATTR_MODE)) {
        if (use_attr == TRUE) {
            opts->method = XH_METHOD_NATIVE_ATTR_MODE;
        }
        else {
            opts->method = XH_METHOD_NATIVE;
        }
    }

    return;

error_value:
    croak("Invalid parameter value for '%s': %s", p, cv);
    return;

error:
    croak("Invalid parameter '%s'", p);
}

void *
xh_get_obj_param(xh_int_t *nparam, I32 ax, I32 items, char *class)
{
    SV   *param;
    void *obj = NULL;

    if (*nparam >= items)
        croak("Invalid parameters");

    param = ST(*nparam);
    if ( sv_derived_from(param, class) ) {
        if ( sv_isobject(param) ) {
            /* reference to object */
            IV tmp = SvIV((SV *) SvRV(param));
            obj = INT2PTR(xh_opts_t *, tmp);
        }
        (*nparam)++;
    }

    return obj;
}

SV *
xh_get_hash_param(xh_int_t *nparam, I32 ax, I32 items)
{
    SV   *param;

    if (*nparam >= items)
        croak("Invalid parameters");

    param = ST(*nparam);
    if (!SvROK(param) || SvTYPE(SvRV(param)) != SVt_PVHV)
        croak("Parameter is not hash reference");

    (*nparam)++;

    return param;
}

SV *
xh_get_str_param(xh_int_t *nparam, I32 ax, I32 items)
{
    SV   *param;

    if (*nparam >= items)
        croak("Invalid parameters");

    param = ST(*nparam);
    if (SvROK(param))
        param = SvRV(param);

    if (!SvOK(param))
        croak("Invalid parameters");

    if (!SvPOK(param) && SvTYPE(param) != SVt_PVGV)
        croak("Invalid parameters");

    (*nparam)++;

    return param;
}

void
xh_merge_opts(xh_opts_t *ctx_opts, xh_opts_t *opts, xh_int_t nparam, I32 ax, I32 items)
{
    if (opts == NULL) {
        /* read global options */
        xh_init_opts(ctx_opts);
    }
    else {
        /* copy options from object */
        xh_copy_opts(ctx_opts, opts);
    }
    if (nparam < items) {
        xh_parse_param(ctx_opts, nparam, ax, items);
    }
}

