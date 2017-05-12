MP_STATIC XS(XS_APR__Request__Cookie_nil)
{
    dXSARGS;
    (void)items;
    XSRETURN_EMPTY;
}

static char *apreq_xs_cookie_pool_copy(pTHX_ SV *obj, SV *value)
{
    IV iv;
    STRLEN vlen;
    char *v;
    MAGIC *mg;
    apr_pool_t *p;
    SV *parent;

    if (!SvOK(value))
        return NULL;

    v = SvPV(value, vlen);
    mg = mg_find(obj, PERL_MAGIC_ext);
    iv = SvIVX(mg->mg_obj);

    /* The parent of a cookie can be a either handle or a pool.
     * Pool-type parents arise from make(), and are expected to
     * reflect the typical usage for apreq_xs_cookie_pool_copy.
     */
    parent = sv_2mortal(newRV_inc(mg->mg_obj));

    if (sv_derived_from(parent, "APR::Pool"))
        p = INT2PTR(apr_pool_t *, iv);

    else if (sv_derived_from(parent, "APR::Request"))
        p = (INT2PTR(apreq_handle_t *, iv))->pool;

    else
        croak("Pool not found: unrecognized parent class %s",
              HvNAME(SvSTASH(mg->mg_obj)));

    return apr_pstrmemdup(p, v, vlen);
}
