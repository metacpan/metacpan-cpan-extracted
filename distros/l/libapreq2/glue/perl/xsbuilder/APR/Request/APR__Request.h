#include "apreq_xs_tables.h"

MP_STATIC XS(apreq_xs_jar)
{
    dXSARGS;
    apreq_handle_t *req;
    SV *obj;
    IV iv;

    if (items == 0 || items > 2 || !SvROK(ST(0))
        || !sv_derived_from(ST(0), "APR::Request"))
        Perl_croak(aTHX_ "Usage: APR::Request::jar($req [,$name])");

    obj = apreq_xs_sv2object(aTHX_ ST(0), HANDLE_CLASS, 'r');
    iv = SvIVX(obj);
    req = INT2PTR(apreq_handle_t *, iv);

    if (items == 2 && GIMME_V == G_SCALAR) {
        apreq_cookie_t *c = apreq_jar_get(req, SvPV_nolen(ST(1)));
        if (c != NULL) {
            ST(0) = apreq_xs_cookie2sv(aTHX_ c, NULL, obj);
            sv_2mortal(ST(0));
            XSRETURN(1);
        }
        else {
            const apr_table_t *t;
            apr_status_t s;

            s = apreq_jar(req, &t);
            if (apreq_module_status_is_error(s)
                && !sv_derived_from(ST(0), ERROR_CLASS))
                apreq_xs_croak(aTHX_ newHV(), obj, s,
                               "APR::Request::jar", ERROR_CLASS);

            XSRETURN_UNDEF;
        }
    }
    else {
        struct apreq_xs_do_arg d = {NULL, NULL, NULL, aTHX};
        const apr_table_t *t;
        apr_status_t s;

        s = apreq_jar(req, &t);

        if (apreq_module_status_is_error(s)
            && !sv_derived_from(ST(0), ERROR_CLASS))
                apreq_xs_croak(aTHX_ newHV(), obj, s,
                               "APR::Request::jar", ERROR_CLASS);

        if (t == NULL)
            XSRETURN_EMPTY;

        d.pkg = NULL;
        d.parent = obj;

        switch (GIMME_V) {

        case G_ARRAY:
            XSprePUSH;
            PUTBACK;
            if (items == 1)
                apr_table_do(apreq_xs_cookie_table_keys, &d, t, NULL);
            else
                apr_table_do(apreq_xs_cookie_table_values, &d, t,
                             SvPV_nolen(ST(1)), NULL);
            return;

        case G_SCALAR:
            ST(0) = apreq_xs_cookie_table2sv(aTHX_ t,
                                             COOKIE_TABLE_CLASS,
                                             obj, NULL, 0);
            sv_2mortal(ST(0));
            XSRETURN(1);

        default:
           XSRETURN(0);
        }
    }
}


MP_STATIC XS(apreq_xs_args)
{
    dXSARGS;
    apreq_handle_t *req;
    SV *obj;
    IV iv;

    if (items == 0 || items > 2 || !SvROK(ST(0))
        || !sv_derived_from(ST(0), HANDLE_CLASS))
        Perl_croak(aTHX_ "Usage: APR::Request::args($req [,$name])");

    obj = apreq_xs_sv2object(aTHX_ ST(0), HANDLE_CLASS, 'r');
    iv = SvIVX(obj);
    req = INT2PTR(apreq_handle_t *, iv);


    if (items == 2 && GIMME_V == G_SCALAR) {
        apreq_param_t *p = apreq_args_get(req, SvPV_nolen(ST(1)));

        if (p != NULL) {
            ST(0) = apreq_xs_param2sv(aTHX_ p, NULL, obj);
            sv_2mortal(ST(0));
            XSRETURN(1);
        }
        else {
            const apr_table_t *t;
            apr_status_t s;
            s = apreq_args(req, &t);

            if (apreq_module_status_is_error(s) &&
                !sv_derived_from(ST(0), ERROR_CLASS))
                apreq_xs_croak(aTHX_ newHV(), obj, s,
                               "APR::Request::args", ERROR_CLASS);

            XSRETURN_UNDEF;
        }
    }
    else {
        struct apreq_xs_do_arg d = {NULL, NULL, NULL, aTHX};
        const apr_table_t *t;
        apr_status_t s;

        s = apreq_args(req, &t);

        if (apreq_module_status_is_error(s) &&
            !sv_derived_from(ST(0), ERROR_CLASS))
            apreq_xs_croak(aTHX_ newHV(), obj, s,
                           "APR::Request::args", ERROR_CLASS);

        if (t == NULL)
            XSRETURN_EMPTY;

        d.pkg = NULL;
        d.parent = obj;

        switch (GIMME_V) {

        case G_ARRAY:
            XSprePUSH;
            PUTBACK;
            if (items == 1)
                apr_table_do(apreq_xs_param_table_keys, &d, t, NULL);
            else
                apr_table_do(apreq_xs_param_table_values, &d, t,
                             SvPV_nolen(ST(1)), NULL);
            return;

        case G_SCALAR:
            ST(0) = apreq_xs_param_table2sv(aTHX_ t,
                                            PARAM_TABLE_CLASS,
                                            obj, NULL, 0);
            sv_2mortal(ST(0));
            XSRETURN(1);

        default:
           XSRETURN(0);
        }
    }
}

MP_STATIC XS(apreq_xs_body)
{
    dXSARGS;
    apreq_handle_t *req;
    SV *obj;
    IV iv;

    if (items == 0 || items > 2 || !SvROK(ST(0))
        || !sv_derived_from(ST(0),HANDLE_CLASS))
        Perl_croak(aTHX_ "Usage: APR::Request::body($req [,$name])");

    obj = apreq_xs_sv2object(aTHX_ ST(0), HANDLE_CLASS, 'r');
    iv = SvIVX(obj);
    req = INT2PTR(apreq_handle_t *, iv);


    if (items == 2 && GIMME_V == G_SCALAR) {
        apreq_param_t *p = apreq_body_get(req, SvPV_nolen(ST(1)));

        if (p != NULL) {
            ST(0) = apreq_xs_param2sv(aTHX_ p, NULL, obj);
            sv_2mortal(ST(0));
            XSRETURN(1);
        }
        else {
            const apr_table_t *t;
            apr_status_t s;
            s = apreq_body(req, &t);

            if (apreq_module_status_is_error(s) &&
                !sv_derived_from(ST(0), ERROR_CLASS))
                apreq_xs_croak(aTHX_ newHV(), obj, s,
                               "APR::Request::body", ERROR_CLASS);

            XSRETURN_UNDEF;
        }
    }
    else {
        struct apreq_xs_do_arg d = {NULL, NULL, NULL, aTHX};
        const apr_table_t *t;
        apr_status_t s;

        s = apreq_body(req, &t);

        if (apreq_module_status_is_error(s) &&
            !sv_derived_from(ST(0), ERROR_CLASS))
            apreq_xs_croak(aTHX_ newHV(), obj, s,
                           "APR::Request::body", ERROR_CLASS);

        if (t == NULL)
            XSRETURN_EMPTY;

        d.pkg = NULL;
        d.parent = obj;

        switch (GIMME_V) {

        case G_ARRAY:
            XSprePUSH;
            PUTBACK;
            if (items == 1)
                apr_table_do(apreq_xs_param_table_keys, &d, t, NULL);
            else
                apr_table_do(apreq_xs_param_table_values, &d, t,
                             SvPV_nolen(ST(1)), NULL);
            return;

        case G_SCALAR:
            ST(0) = apreq_xs_param_table2sv(aTHX_ t,
                                            PARAM_TABLE_CLASS,
                                            obj, NULL, 0);
            sv_2mortal(ST(0));
            XSRETURN(1);

        default:
           XSRETURN(0);
        }
    }
}


MP_STATIC XS(apreq_xs_param)
{
    dXSARGS;
    apreq_handle_t *req;
    SV *obj;
    IV iv;

    if (items == 0 || items > 2 || !SvROK(ST(0))
        || !sv_derived_from(ST(0), "APR::Request"))
        Perl_croak(aTHX_ "Usage: APR::Request::param($req [,$name])");

    obj = apreq_xs_sv2object(aTHX_ ST(0), HANDLE_CLASS, 'r');
    iv = SvIVX(obj);
    req = INT2PTR(apreq_handle_t *, iv);

    if (items == 2 && GIMME_V == G_SCALAR) {
        apreq_param_t *p = apreq_param(req, SvPV_nolen(ST(1)));

        if (p != NULL) {
            ST(0) = apreq_xs_param2sv(aTHX_ p, NULL, obj);
            sv_2mortal(ST(0));
            XSRETURN(1);
        }
        else {
            XSRETURN_UNDEF;
        }
    }
    else {
        struct apreq_xs_do_arg d = {NULL, NULL, NULL, aTHX};
        const apr_table_t *t;

        d.pkg = NULL;
        d.parent = obj;

        switch (GIMME_V) {

        case G_ARRAY:
            XSprePUSH;
            PUTBACK;
            if (items == 1) {
                apreq_args(req, &t);
                if (t != NULL)
                    apr_table_do(apreq_xs_param_table_keys, &d, t, NULL);
                apreq_body(req, &t);
                if (t != NULL)
                    apr_table_do(apreq_xs_param_table_keys, &d, t, NULL);

            }
            else {
                char *val = SvPV_nolen(ST(1));
                apreq_args(req, &t);
                if (t != NULL)
                    apr_table_do(apreq_xs_param_table_values, &d, t, val, NULL);
                apreq_body(req, &t);
                if (t != NULL)
                    apr_table_do(apreq_xs_param_table_values, &d, t, val, NULL);
            }
            return;

        case G_SCALAR:
            t = apreq_params(req, req->pool);
            if (t == NULL)
                XSRETURN_UNDEF;

            ST(0) = apreq_xs_param_table2sv(aTHX_ t,
                                            PARAM_TABLE_CLASS,
                                            obj, NULL, 0);
            sv_2mortal(ST(0));
            XSRETURN(1);

        default:
            XSRETURN(0);
        }
    }
}


MP_STATIC XS(apreq_xs_parse)
{
    dXSARGS;
    apreq_handle_t *req;
    apr_status_t s;
    const apr_table_t *t;

    if (items != 1 || !SvROK(ST(0)))
        Perl_croak(aTHX_ "Usage: APR::Request::parse($req)");

    req = apreq_xs_sv2handle(aTHX_ ST(0));

    XSprePUSH;
    EXTEND(SP, 3);
    s = apreq_jar(req, &t);
    PUSHs(sv_2mortal(apreq_xs_error2sv(aTHX_ s)));
    s = apreq_args(req, &t);
    PUSHs(sv_2mortal(apreq_xs_error2sv(aTHX_ s)));
    s = apreq_body(req, &t);
    PUSHs(sv_2mortal(apreq_xs_error2sv(aTHX_ s)));
    PUTBACK;
}

struct hook_ctx {
    SV                  *hook;
    SV                  *bucket_data;
    SV                  *parent;
    PerlInterpreter     *perl;
};


#define DEREF(slot) if (ctx->slot) SvREFCNT_dec(ctx->slot)

static apr_status_t upload_hook_cleanup(void *ctx_)
{
    struct hook_ctx *ctx = ctx_;

#ifdef USE_ITHREADS
    dTHXa(ctx->perl);
#endif

    DEREF(hook);
    DEREF(bucket_data);
    DEREF(parent);
    return APR_SUCCESS;
}

APR_INLINE
static apr_status_t eval_upload_hook(pTHX_ apreq_param_t *upload,
                                     struct hook_ctx *ctx)
{
    dSP;
    SV *sv = ctx->bucket_data;

    PUSHMARK(SP);
    EXTEND(SP, 2);
    ENTER;
    SAVETMPS;

    sv = apreq_xs_param2sv(aTHX_ upload, PARAM_CLASS, ctx->parent);
    PUSHs(sv_2mortal(sv));
    PUSHs(ctx->bucket_data);
    PUTBACK;
    perl_call_sv(ctx->hook, G_EVAL|G_DISCARD);
    FREETMPS;
    LEAVE;

    if (SvTRUE(ERRSV)) {
        Perl_warn(aTHX_ "Upload hook failed: %s", SvPV_nolen(ERRSV));
        return APREQ_ERROR_GENERAL;
    }
    return APR_SUCCESS;
}


static apr_status_t apreq_xs_upload_hook(APREQ_HOOK_ARGS)
{
    struct hook_ctx *ctx = hook->ctx; /* ctx set during $req->config */
    apr_bucket *e;
    apr_status_t s = APR_SUCCESS;
#ifdef USE_ITHREADS
    dTHXa(ctx->perl);
#endif

    if (bb == NULL) {
        if (hook->next)
            return apreq_hook_run(hook->next, param, bb);
        return APR_SUCCESS;
    }

    for (e = APR_BRIGADE_FIRST(bb); e!= APR_BRIGADE_SENTINEL(bb);
         e = APR_BUCKET_NEXT(e))
    {
        apr_size_t len;
        const char *data;

        if (APR_BUCKET_IS_EOS(e)) {  /*last call on this upload */
            SV *sv = ctx->bucket_data;
            ctx->bucket_data = &PL_sv_undef;
            s = eval_upload_hook(aTHX_ param, ctx);
            ctx->bucket_data = sv;
            if (s != APR_SUCCESS)
                return s;

            break;
        }

        s = apr_bucket_read(e, &data, &len, APR_BLOCK_READ);
        if (s != APR_SUCCESS) {
            s = APR_SUCCESS;
            continue;
        }
        sv_setpvn(ctx->bucket_data, data, (STRLEN)len);
        s = eval_upload_hook(aTHX_ param, ctx);

        if (s != APR_SUCCESS)
            return s;

    }

    if (hook->next)
        s = apreq_hook_run(hook->next, param, bb);

    return s;
}


static int apreq_xs_cookie_table_do_sub(void *data, const char *key,
                                       const char *val)
{
    struct apreq_xs_do_arg *d = data;
    apreq_cookie_t *c = apreq_value_to_cookie(val);
    dTHXa(d->perl);
    dSP;
    SV *sv = apreq_xs_cookie2sv(aTHX_ c, d->pkg, d->parent);
    int rv;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP,2);

    PUSHs(sv_2mortal(newSVpvn(c->v.name, c->v.nlen)));
    PUSHs(sv_2mortal(sv));

    PUTBACK;
    rv = call_sv(d->sub, G_SCALAR);
    SPAGAIN;
    rv = (1 == rv) ? POPi : 1;
    PUTBACK;
    FREETMPS;
    LEAVE;

    return rv;
}

MP_STATIC XS(apreq_xs_cookie_table_do)
{
    dXSARGS;
    struct apreq_xs_do_arg d = { NULL, NULL, NULL, aTHX };
    const apr_table_t *t;
    int i, rv = 1;
    SV *sv, *t_obj;
    IV iv;
    MAGIC *mg;

    if (items < 2 || !SvROK(ST(0)) || !SvROK(ST(1)))
        Perl_croak(aTHX_ "Usage: $object->do(\\&callback, @keys)");
    sv = ST(0);

    t_obj = apreq_xs_sv2object(aTHX_ sv, COOKIE_TABLE_CLASS, 't');
    iv = SvIVX(t_obj);
    t = INT2PTR(const apr_table_t *, iv);
    mg = mg_find(t_obj, PERL_MAGIC_ext);
    d.parent = mg->mg_obj;
    d.pkg = mg->mg_ptr;
    d.sub = ST(1);

    if (items == 2) {
        rv = apr_table_do(apreq_xs_cookie_table_do_sub, &d, t, NULL);
        XSRETURN_IV(rv);
    }

    for (i = 2; i < items; ++i) {
        const char *key = SvPV_nolen(ST(i));
        rv = apr_table_do(apreq_xs_cookie_table_do_sub, &d, t, key, NULL);
        if (rv == 0)
            break;
    }
    XSRETURN_IV(rv);
}

MP_STATIC XS(apreq_xs_cookie_table_FETCH)
{
    dXSARGS;
    const apr_table_t *t;
    const char *cookie_class;
    SV *sv, *obj, *parent;
    IV iv;
    MAGIC *mg;

    if (items != 2 || !SvROK(ST(0))
        || !sv_derived_from(ST(0), COOKIE_TABLE_CLASS))
        Perl_croak(aTHX_ "Usage: " COOKIE_TABLE_CLASS "::FETCH($table, $key)");

    sv = ST(0);

    obj = apreq_xs_sv2object(aTHX_ sv, COOKIE_TABLE_CLASS, 't');
    iv = SvIVX(obj);
    t = INT2PTR(const apr_table_t *, iv);

    mg = mg_find(obj, PERL_MAGIC_ext);
    cookie_class = mg->mg_ptr;
    parent = mg->mg_obj;

    if (GIMME_V == G_SCALAR) {
        IV idx;
        const char *key, *val;
        const apr_array_header_t *arr;
        apr_table_entry_t *te;
        key = SvPV_nolen(ST(1));

        idx = SvCUR(obj);
        arr = apr_table_elts(t);
        te  = (apr_table_entry_t *)arr->elts;

        if (idx > 0 && idx <= arr->nelts
            && !strcasecmp(key, te[idx-1].key))
            val = te[idx-1].val;
        else
            val = apr_table_get(t, key);

        if (val != NULL) {
            apreq_cookie_t *c = apreq_value_to_cookie(val);
            ST(0) = apreq_xs_cookie2sv(aTHX_ c, cookie_class, parent);
            sv_2mortal(ST(0));
            XSRETURN(1);
        }
        else {
            XSRETURN_UNDEF;
        }
    }
    else if (GIMME_V == G_ARRAY) {
        struct apreq_xs_do_arg d = {NULL, NULL, NULL, aTHX};
        d.pkg = cookie_class;
        d.parent = parent;
        XSprePUSH;
        PUTBACK;
        apr_table_do(apreq_xs_cookie_table_values, &d, t, SvPV_nolen(ST(1)), NULL);
    }
    else
        XSRETURN(0);
}

MP_STATIC XS(apreq_xs_cookie_table_NEXTKEY)
{
    dXSARGS;
    SV *sv, *obj;
    IV iv, idx;
    const apr_table_t *t;
    const apr_array_header_t *arr;
    apr_table_entry_t *te;

    if (!SvROK(ST(0)))
        Perl_croak(aTHX_ "Usage: $table->NEXTKEY($prev)");

    sv  = ST(0);
    obj = apreq_xs_sv2object(aTHX_ sv, COOKIE_TABLE_CLASS, 't');

    iv = SvIVX(obj);
    t = INT2PTR(const apr_table_t *, iv);
    arr = apr_table_elts(t);
    te  = (apr_table_entry_t *)arr->elts;

    if (items == 1)
        SvCUR(obj) = 0;

    if (SvCUR(obj) >= arr->nelts) {
        SvCUR(obj) = 0;
        XSRETURN_UNDEF;
    }
    idx = SvCUR(obj)++;
    sv = newSVpv(te[idx].key, 0);
    ST(0) = sv_2mortal(sv);
    XSRETURN(1);
}


static int apreq_xs_param_table_do_sub(void *data, const char *key,
                                       const char *val)
{
    struct apreq_xs_do_arg *d = data;
    apreq_param_t *p = apreq_value_to_param(val);
    dTHXa(d->perl);
    dSP;
    SV *sv = apreq_xs_param2sv(aTHX_ p, d->pkg, d->parent);
    int rv;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP,2);

    PUSHs(sv_2mortal(newSVpvn(p->v.name, p->v.nlen)));
    PUSHs(sv_2mortal(sv));

    PUTBACK;
    rv = call_sv(d->sub, G_SCALAR);
    SPAGAIN;
    rv = (1 == rv) ? POPi : 1;
    PUTBACK;
    FREETMPS;
    LEAVE;

    return rv;
}

MP_STATIC XS(apreq_xs_param_table_do)
{
    dXSARGS;
    struct apreq_xs_do_arg d = { NULL, NULL, NULL, aTHX };
    const apr_table_t *t;
    int i, rv = 1;
    SV *sv, *t_obj;
    IV iv;
    MAGIC *mg;

    if (items < 2 || !SvROK(ST(0)) || !SvROK(ST(1)))
        Perl_croak(aTHX_ "Usage: $object->do(\\&callback, @keys)");
    sv = ST(0);

    t_obj = apreq_xs_sv2object(aTHX_ sv, PARAM_TABLE_CLASS, 't');
    iv = SvIVX(t_obj);
    t = INT2PTR(const apr_table_t *, iv);
    mg = mg_find(t_obj, PERL_MAGIC_ext);
    d.parent = mg->mg_obj;
    d.pkg = mg->mg_ptr;
    d.sub = ST(1);

    if (items == 2) {
        rv = apr_table_do(apreq_xs_param_table_do_sub, &d, t, NULL);
        XSRETURN_IV(rv);
    }

    for (i = 2; i < items; ++i) {
        const char *key = SvPV_nolen(ST(i));
        rv = apr_table_do(apreq_xs_param_table_do_sub, &d, t, key, NULL);
        if (rv == 0)
            break;
    }
    XSRETURN_IV(rv);
}

MP_STATIC XS(apreq_xs_param_table_FETCH)
{
    dXSARGS;
    const apr_table_t *t;
    const char *param_class;
    SV *sv, *t_obj, *parent;
    IV iv;
    MAGIC *mg;

    if (items != 2 || !SvROK(ST(0))
        || !sv_derived_from(ST(0), PARAM_TABLE_CLASS))
        Perl_croak(aTHX_ "Usage: " PARAM_TABLE_CLASS "::FETCH($table, $key)");

    sv = ST(0);

    t_obj = apreq_xs_sv2object(aTHX_ sv, PARAM_TABLE_CLASS, 't');
    iv = SvIVX(t_obj);
    t = INT2PTR(const apr_table_t *, iv);

    mg = mg_find(t_obj, PERL_MAGIC_ext);
    param_class = mg->mg_ptr;
    parent = mg->mg_obj;


    if (GIMME_V == G_SCALAR) {
        IV idx;
        const char *key, *val;
        const apr_array_header_t *arr;
        apr_table_entry_t *te;
        key = SvPV_nolen(ST(1));

        idx = SvCUR(t_obj);
        arr = apr_table_elts(t);
        te  = (apr_table_entry_t *)arr->elts;

        if (idx > 0 && idx <= arr->nelts
            && !strcasecmp(key, te[idx-1].key))
            val = te[idx-1].val;
        else
            val = apr_table_get(t, key);

        if (val != NULL) {
            apreq_param_t *p = apreq_value_to_param(val);
            ST(0) = apreq_xs_param2sv(aTHX_ p, param_class, parent);
            sv_2mortal(ST(0));
            XSRETURN(1);
        }
        else {
            XSRETURN_UNDEF;
        }
    }
    else if (GIMME_V == G_ARRAY) {
        struct apreq_xs_do_arg d = {NULL, NULL, NULL, aTHX};
        d.pkg = param_class;
        d.parent = parent;
        XSprePUSH;
        PUTBACK;
        apr_table_do(apreq_xs_param_table_values, &d, t, SvPV_nolen(ST(1)), NULL);
    }
    else
        XSRETURN(0);
}

MP_STATIC XS(apreq_xs_param_table_NEXTKEY)
{
    dXSARGS;
    SV *sv, *obj;
    IV iv, idx;
    const apr_table_t *t;
    const apr_array_header_t *arr;
    apr_table_entry_t *te;

    if (!SvROK(ST(0)) || !sv_derived_from(ST(0), PARAM_TABLE_CLASS))
        Perl_croak(aTHX_ "Usage: " PARAM_TABLE_CLASS "::NEXTKEY($table, $key)");

    sv  = ST(0);
    obj = apreq_xs_sv2object(aTHX_ sv, PARAM_TABLE_CLASS,'t');

    iv = SvIVX(obj);
    t = INT2PTR(const apr_table_t *, iv);
    arr = apr_table_elts(t);
    te  = (apr_table_entry_t *)arr->elts;

    if (items == 1)
        SvCUR(obj) = 0;

    if (SvCUR(obj) >= arr->nelts) {
        SvCUR(obj) = 0;
        XSRETURN_UNDEF;
    }
    idx = SvCUR(obj)++;
    sv = newSVpv(te[idx].key, 0);
    ST(0) = sv_2mortal(sv);
    XSRETURN(1);
}


