MODULE = APR::Request::Cookie      PACKAGE = APR::Request::Cookie

SV *
value(obj, p1=NULL, p2=NULL)
    APR::Request::Cookie obj
    SV *p1
    SV *p2
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = newSVpvn(obj->v.data, obj->v.dlen);
    if (apreq_cookie_is_tainted(obj))
        SvTAINTED_on(RETVAL);

  OUTPUT:
    RETVAL



BOOT:
    {
        apr_version_t version;
        apr_version(&version);
        if (version.major != APR_MAJOR_VERSION)
            Perl_croak(aTHX_ "Can't load module APR::Request::Cookie : "
                             "wrong libapr major version "
                             "(expected %d, saw %d)",
                              APR_MAJOR_VERSION, version.major);
    }

    /* register the overloading (type 'A') magic */
    PL_amagic_generation++;
    /* The magic for overload gets a GV* via gv_fetchmeth as */
    /* mentioned above, and looks in the SV* slot of it for */
    /* the "fallback" status. */
    sv_setsv(
        get_sv( "APR::Request::Cookie::()", TRUE ),
        &PL_sv_yes
    );
    newXS("APR::Request::Cookie::()", XS_APR__Request__Cookie_nil, file);
    newXS("APR::Request::Cookie::(\"\"", XS_APR__Request__Cookie_value, file);


MODULE = APR::Request::Cookie   PACKAGE = APR::Request::Cookie

SV *
name(obj)
    APR::Request::Cookie obj

  CODE:
    RETVAL = newSVpvn(obj->v.name, obj->v.nlen);
    if (apreq_cookie_is_tainted(obj))
        SvTAINTED_on(RETVAL);

  OUTPUT:
    RETVAL

UV
secure(obj, val=NULL)
    APR::Request::Cookie obj
    SV *val

  CODE:
    RETVAL = apreq_cookie_is_secure(obj);
    if (items == 2) {
        if (SvTRUE(val))
            apreq_cookie_secure_on(obj);
        else
            apreq_cookie_secure_off(obj);
    }

  OUTPUT:
    RETVAL

UV
httponly(obj, val=NULL)
    APR::Request::Cookie obj
    SV *val

  CODE:
    RETVAL = apreq_cookie_is_httponly(obj);
    if (items == 2) {
        if (SvTRUE(val))
            apreq_cookie_httponly_on(obj);
        else
            apreq_cookie_httponly_off(obj);
    }

  OUTPUT:
    RETVAL

UV
version(obj, val=0)
    APR::Request::Cookie obj
    UV val

  CODE:
    RETVAL = apreq_cookie_version(obj);
    if (items == 2)
        apreq_cookie_version_set(obj, val);

  OUTPUT:
    RETVAL

IV
is_tainted(obj, val=NULL)
    APR::Request::Cookie obj
    SV *val
  PREINIT:
    /*nada*/

  CODE:
    RETVAL = apreq_cookie_is_tainted(obj);

    if (items == 2) {
        if (SvTRUE(val))
           apreq_cookie_tainted_on(obj);
        else
           apreq_cookie_tainted_off(obj);
    }

  OUTPUT:
    RETVAL

char *
path(cookie, path=NULL)
    SV *cookie
    SV *path

  PREINIT:
    apreq_cookie_t *c;
    SV *obj;
    IV iv;

  CODE:
    obj = apreq_xs_sv2object(aTHX_ cookie, COOKIE_CLASS, 'c');
    iv = SvIVX(obj);
    c = INT2PTR(apreq_cookie_t *, iv);

    RETVAL = c->path;
    if (items == 2)
        c->path = apreq_xs_cookie_pool_copy(aTHX_ obj, path);
    if (RETVAL == NULL)
        XSRETURN_UNDEF;

  OUTPUT:
    RETVAL

char *
domain(cookie, domain=NULL)
    SV *cookie
    SV *domain

  PREINIT:
    apreq_cookie_t *c;
    SV *obj;
    IV iv;

  CODE:
    obj = apreq_xs_sv2object(aTHX_ cookie, COOKIE_CLASS, 'c');
    iv = SvIVX(obj);
    c = INT2PTR(apreq_cookie_t *, iv);

    RETVAL = c->domain;
    if (items == 2)
        c->domain = apreq_xs_cookie_pool_copy(aTHX_ obj, domain);
    if (RETVAL == NULL)
        XSRETURN_UNDEF;

  OUTPUT:
    RETVAL

char *
port(cookie, port=NULL)
    SV *cookie
    SV *port

  PREINIT:
    apreq_cookie_t *c;
    SV *obj;
    IV iv;

  CODE:
    obj = apreq_xs_sv2object(aTHX_ cookie, COOKIE_CLASS, 'c');
    iv = SvIVX(obj);
    c = INT2PTR(apreq_cookie_t *, iv);

    RETVAL = c->port;
    if (items == 2)
        c->port = apreq_xs_cookie_pool_copy(aTHX_ obj, port);
    if (RETVAL == NULL)
        XSRETURN_UNDEF;

  OUTPUT:
    RETVAL

char *
comment(cookie, comment=NULL)
    SV *cookie
    SV *comment

  PREINIT:
    apreq_cookie_t *c;
    SV *obj;
    IV iv;

  CODE:
    obj = apreq_xs_sv2object(aTHX_ cookie, COOKIE_CLASS, 'c');
    iv = SvIVX(obj);
    c = INT2PTR(apreq_cookie_t *, iv);

    RETVAL = c->comment;
    if (items == 2)
        c->comment = apreq_xs_cookie_pool_copy(aTHX_ obj, comment);
    if (RETVAL == NULL)
        XSRETURN_UNDEF;

  OUTPUT:
    RETVAL

char *
commentURL(cookie, commentURL=NULL)
    SV *cookie
    SV *commentURL

  PREINIT:
    apreq_cookie_t *c;
    SV *obj;
    IV iv;

  CODE:
    obj = apreq_xs_sv2object(aTHX_ cookie, COOKIE_CLASS, 'c');
    iv = SvIVX(obj);
    c = INT2PTR(apreq_cookie_t *, iv);

    RETVAL = c->commentURL;
    if (items == 2)
        c->commentURL = apreq_xs_cookie_pool_copy(aTHX_ obj, commentURL);
    if (RETVAL == NULL)
        XSRETURN_UNDEF;

  OUTPUT:
    RETVAL



APR::Request::Cookie
make(class, pool, name, val)
    apreq_xs_subclass_t class
    APR::Pool pool
    SV *name
    SV *val
  PREINIT:
    STRLEN nlen, vlen;
    const char *n, *v;
    SV *parent = SvRV(ST(1));

  CODE:
    n = SvPV(name, nlen);
    v = SvPV(val, vlen);
    RETVAL = apreq_cookie_make(pool, n, nlen, v, vlen);
    if (SvTAINTED(name) || SvTAINTED(val))
        apreq_cookie_tainted_on(RETVAL);

  OUTPUT:
    RETVAL

SV *
as_string(c)
    APR::Request::Cookie c
  PREINIT:
    STRLEN len;

  CODE:
    len = apreq_cookie_serialize(c, NULL, 0);
    RETVAL = newSV(len);
    SvCUR_set(RETVAL, apreq_cookie_serialize(c, SvPVX(RETVAL), len + 1));
    SvPOK_on(RETVAL);
    if (apreq_cookie_is_tainted(c))
        SvTAINTED_on(RETVAL);

  OUTPUT:
    RETVAL

