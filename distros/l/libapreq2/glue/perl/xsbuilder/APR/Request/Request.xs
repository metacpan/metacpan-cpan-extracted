MODULE = APR::Request     PACKAGE = APR::Request

SV*
encode(in)
    SV *in
  PREINIT:
    STRLEN len;
    char *src;
  CODE:
    src = SvPV(in, len);
    RETVAL = newSV(3 * len + 1);
    SvCUR_set(RETVAL, apreq_encode(SvPVX(RETVAL), src, len));
    SvPOK_on(RETVAL);

  OUTPUT:
    RETVAL

SV*
decode(in)
    SV *in
  PREINIT:
    STRLEN len;
    apr_size_t dlen;
    char *src;
  CODE:
    src = SvPV(in, len);
    RETVAL = newSV(len + 1);
    apreq_decode(SvPVX(RETVAL), &dlen, src, len); /*XXX needs error-handling */
    SvCUR_set(RETVAL, dlen);
    SvPOK_on(RETVAL);
  OUTPUT:
    RETVAL

SV*
read_limit(req, val=NULL)
    APR::Request req
    SV *val
  PREINIT:
    /* nada */
  CODE:
    if (items == 1) {
        apr_status_t s;
        apr_uint64_t bytes;
        s = apreq_read_limit_get(req, &bytes);
        if (s != APR_SUCCESS) {
            if (!sv_derived_from(ST(0), ERROR_CLASS)) {
                SV *obj = apreq_xs_sv2object(aTHX_ ST(0), HANDLE_CLASS, 'r');
                apreq_xs_croak(aTHX_ newHV(), obj, s,
                               "APR::Request::read_limit", ERROR_CLASS);
            }
            else
                RETVAL = &PL_sv_undef;
        }
        else {
            RETVAL = newSVuv(bytes);
        }
    }
    else {
        apr_status_t s = apreq_read_limit_set(req, SvUV(val));
        if (s != APR_SUCCESS) {
            if (GIMME_V == G_VOID && !sv_derived_from(ST(0), ERROR_CLASS)) {
                SV *obj = apreq_xs_sv2object(aTHX_ ST(0), HANDLE_CLASS, 'r');
                apreq_xs_croak(aTHX_ newHV(), obj, s,
                               "APR::Request::read_limit", ERROR_CLASS);
            }
            else
                RETVAL = &PL_sv_no;
        }
        else {
            RETVAL = &PL_sv_yes;
        }
    }

  OUTPUT:
    RETVAL

SV*
brigade_limit(req, val=NULL)
    APR::Request req
    SV *val
  PREINIT:
    /* nada */
  CODE:
    if (items == 1) {
        apr_status_t s;
        apr_size_t bytes;
        s = apreq_brigade_limit_get(req, &bytes);
        if (s != APR_SUCCESS) {
            if (!sv_derived_from(ST(0), ERROR_CLASS)) {
                SV *obj = apreq_xs_sv2object(aTHX_ ST(0), HANDLE_CLASS, 'r');
                apreq_xs_croak(aTHX_ newHV(), obj, s,
                               "APR::Request::brigade_limit", ERROR_CLASS);
            }
            else
                RETVAL = &PL_sv_undef;
        }
        else {
            RETVAL = newSVuv(bytes);
        }
    }
    else {
        apr_status_t s = apreq_brigade_limit_set(req, SvUV(val));
        if (s != APR_SUCCESS) {
            if (GIMME_V == G_VOID && !sv_derived_from(ST(0), ERROR_CLASS)) {
                SV *obj = apreq_xs_sv2object(aTHX_ ST(0), HANDLE_CLASS, 'r');
                apreq_xs_croak(aTHX_ newHV(), obj, s,
                               "APR::Request::brigade_limit", ERROR_CLASS);
            }
            else
                RETVAL = &PL_sv_no;
        }
        else {
            RETVAL = &PL_sv_yes;
        }
    }

  OUTPUT:
    RETVAL


SV*
temp_dir(req, val=NULL)
    APR::Request req
    SV *val
  PREINIT:
    /* nada */
  CODE:
    if (items == 1) {
        apr_status_t s;
        const char *path;
        s = apreq_temp_dir_get(req, &path);
        if (s != APR_SUCCESS) {
            if (!sv_derived_from(ST(0), ERROR_CLASS)) {
                SV *obj = apreq_xs_sv2object(aTHX_ ST(0), HANDLE_CLASS, 'r');
                apreq_xs_croak(aTHX_ newHV(), obj, s,
                               "APR::Request::temp_dir", ERROR_CLASS);
            }
            else
                RETVAL = &PL_sv_undef;
        }
        else {
            RETVAL = (path == NULL) ? &PL_sv_undef : newSVpv(path, 0);
        }
    }
    else {
        apr_status_t s = apreq_temp_dir_set(req, SvPV_nolen(val));
        if (s != APR_SUCCESS) {
            if (GIMME_V == G_VOID && !sv_derived_from(ST(0), ERROR_CLASS)) {
                SV *obj = apreq_xs_sv2object(aTHX_ ST(0), HANDLE_CLASS, 'r');
                apreq_xs_croak(aTHX_ newHV(), obj, s,
                               "APR::Request::temp_dir", ERROR_CLASS);
            }
            else
                RETVAL = &PL_sv_no;
        }
        else {
            RETVAL = &PL_sv_yes;
        }
    }

  OUTPUT:
    RETVAL

SV*
jar_status(req)
    APR::Request req
  PREINIT:
    const apr_table_t *t;

  CODE:
    RETVAL = apreq_xs_error2sv(aTHX_ apreq_jar(req, &t));

  OUTPUT:
    RETVAL

SV*
args_status(req)
    APR::Request req
  PREINIT:
    const apr_table_t *t;

  CODE:
    RETVAL = apreq_xs_error2sv(aTHX_ apreq_args(req, &t));

  OUTPUT:
    RETVAL

SV*
body_status(req)
    APR::Request req
  PREINIT:
    const apr_table_t *t;

  CODE:
    RETVAL = apreq_xs_error2sv(aTHX_ apreq_body(req, &t));

  OUTPUT:
    RETVAL

SV*
disable_uploads(req)
    APR::Request req
  PREINIT:
    apreq_hook_t *h;
    apr_status_t s;
  CODE:
    h = apreq_hook_make(req->pool, apreq_hook_disable_uploads, NULL, NULL);
    s = apreq_hook_add(req, h);
    RETVAL = apreq_xs_error2sv(aTHX_ s);

  OUTPUT:
    RETVAL

void
upload_hook(obj, sub)
    SV *obj
    SV *sub
  PREINIT:
    struct hook_ctx *ctx;
    IV iv;
    apreq_handle_t *req;
  CODE:
    obj = apreq_xs_sv2object(aTHX_ obj, "APR::Request", 'r');
    iv = SvIVX(obj);
    req = INT2PTR(apreq_handle_t *, iv);
    ctx = apr_palloc(req->pool, sizeof *ctx);
    ctx->hook = newSVsv(sub);
    ctx->bucket_data = newSV(8000);
    ctx->parent = SvREFCNT_inc(obj);
    SvTAINTED_on(ctx->bucket_data);
#ifdef USE_ITHREADS
    ctx->perl = aTHX;
#endif

    apreq_hook_add(req, apreq_hook_make(req->pool, apreq_xs_upload_hook, NULL, ctx));
    apr_pool_cleanup_register(req->pool, ctx, upload_hook_cleanup, NULL);


APR::Pool
pool(req)
    APR::Request req
  CODE:
    RETVAL = req->pool;
   OUTPUT:
    RETVAL


APR::BucketAlloc
bucket_alloc(req)
    APR::Request req
  CODE:
    RETVAL = req->bucket_alloc;
  OUTPUT:
    RETVAL

MODULE = APR::Request::Param    PACKAGE = APR::Request::Param::Table

SV *
uploads(t, pool)
    APR::Request::Param::Table t
    APR::Pool pool
  PREINIT:
    SV *obj = apreq_xs_sv2object(aTHX_ ST(0), PARAM_TABLE_CLASS, 't');
    SV *parent = apreq_xs_sv2object(aTHX_ ST(0), HANDLE_CLASS, 'r');
    MAGIC *mg = mg_find(obj, PERL_MAGIC_ext);
  CODE:
    RETVAL = apreq_xs_param_table2sv(aTHX_ apreq_uploads(t, pool),
                                     HvNAME(SvSTASH(obj)),
                                     parent, mg->mg_ptr, mg->mg_len);
  OUTPUT:
    RETVAL


MODULE = APR::Request::Param PACKAGE = APR::Request::Param::Table

SV *
param_class(t, subclass=&PL_sv_undef)
    APR::Request::Param::Table t
    SV *subclass

  PREINIT:
    SV *obj = apreq_xs_sv2object(aTHX_ ST(0), PARAM_TABLE_CLASS, 't');
    MAGIC *mg = mg_find(obj, PERL_MAGIC_ext);
    char *curclass = mg->mg_ptr;

  CODE:

    if (items == 2) {
        if (!SvOK(subclass)) {
            mg->mg_ptr = NULL;
            mg->mg_len = 0;
        }
        else if (!sv_derived_from(subclass, PARAM_CLASS)) {
            Perl_croak(aTHX_ "Usage: "
                              PARAM_TABLE_CLASS "::param_class($table, $class): "
                             "class %s is not derived from " PARAM_CLASS,
                              SvPV_nolen(subclass));
        }
        else {
            STRLEN len;
            mg->mg_ptr = savepv(SvPV(subclass, len));
            mg->mg_len = len;

        }
        if (curclass != NULL)
            Safefree(curclass);

        XSRETURN(1);
    }

    RETVAL = (curclass == NULL) ? &PL_sv_undef : newSVpv(curclass, 0);

  OUTPUT:
    RETVAL


MODULE = APR::Request::Cookie PACKAGE = APR::Request::Cookie::Table

SV *
cookie_class(t, subclass=&PL_sv_undef)
    APR::Request::Cookie::Table t
    SV *subclass

  PREINIT:
    SV *obj = apreq_xs_sv2object(aTHX_ ST(0), COOKIE_TABLE_CLASS, 't');
    MAGIC *mg = mg_find(obj, PERL_MAGIC_ext);
    char *curclass = mg->mg_ptr;

  CODE:

    if (items == 2) {
        if (!SvOK(subclass)) {
            mg->mg_ptr = NULL;
            mg->mg_len = 0;
        }
        else if (!sv_derived_from(subclass, COOKIE_CLASS)) {
            Perl_croak(aTHX_ "Usage: "
                             COOKIE_TABLE_CLASS "::cookie_class($table, $class): "
                             "class %s is not derived from " COOKIE_CLASS,
                             SvPV_nolen(subclass));
        }
        else {
            STRLEN len;
            mg->mg_ptr = savepv(SvPV(subclass, len));
            mg->mg_len = len;
        }
        if (curclass != NULL)
            Safefree(curclass);

        XSRETURN(1);
    }

    RETVAL = (curclass == NULL) ? &PL_sv_undef : newSVpv(curclass, 0);

  OUTPUT:
    RETVAL


MODULE = APR::Request  PACKAGE = APR::Request::Custom

APR::Request
handle(class, pool, query_string, cookie, parser, read_limit, in)
    apreq_xs_subclass_t class
    APR::Pool pool
    char *query_string
    char *cookie
    APR::Request::Parser parser
    UV read_limit
    APR::Brigade in
  PREINIT:
    SV *parent = SvRV(ST(1));
  CODE:
    RETVAL = apreq_handle_custom(pool, query_string, cookie,
                                 parser, read_limit, in);
  OUTPUT:
    RETVAL


BOOT:
    {
        apr_version_t version;
        apr_version(&version);
        if (version.major != APR_MAJOR_VERSION)
            Perl_croak(aTHX_ "Can't load module APR::Request : "
                             "wrong libapr major version "
                             "(expected %d, saw %d)",
                              APR_MAJOR_VERSION, version.major);
    }
