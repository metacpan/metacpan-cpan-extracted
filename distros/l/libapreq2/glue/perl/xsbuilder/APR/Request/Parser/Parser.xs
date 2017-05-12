MODULE = APR::Request::Parser    PACKAGE = APR::Request::Parser

APR::Request::Parser
make(class, pool, ba, ct, parser, blim=APREQ_DEFAULT_BRIGADE_LIMIT, tdir=NULL, hook=NULL)
    apreq_xs_subclass_t class
    APR::Pool pool
    APR::BucketAlloc ba
    char *ct
    apreq_parser_function_t parser
    apr_size_t blim
    char *tdir
    APR::Request::Hook hook

  CODE:
    RETVAL = apreq_parser_make(pool, ba, ct, parser, blim, tdir, hook, NULL);

  OUTPUT:
    RETVAL

APR::Request::Parser
generic(class, pool, ba, ct, blim=APREQ_DEFAULT_BRIGADE_LIMIT, tdir=NULL, hook=NULL)
    apreq_xs_subclass_t class
    APR::Pool pool
    APR::BucketAlloc ba
    char *ct
    apr_size_t blim
    char *tdir
    APR::Request::Hook hook

  CODE:
    RETVAL = apreq_parser_make(pool, ba, ct, apreq_parse_generic,
                               blim, tdir, hook, NULL);

  OUTPUT:
    RETVAL

APR::Request::Parser
headers(class, pool, ba, ct, blim=APREQ_DEFAULT_BRIGADE_LIMIT, tdir=NULL, hook=NULL)
    apreq_xs_subclass_t class
    APR::Pool pool
    APR::BucketAlloc ba
    char *ct
    apr_size_t blim
    char *tdir
    APR::Request::Hook hook

  CODE:
    RETVAL = apreq_parser_make(pool, ba, ct, apreq_parse_headers,
                               blim, tdir, hook, NULL);

  OUTPUT:
    RETVAL

APR::Request::Parser
urlencoded(class, pool, ba, ct, blim=APREQ_DEFAULT_BRIGADE_LIMIT, tdir=NULL, hook=NULL)
    apreq_xs_subclass_t class
    APR::Pool pool
    APR::BucketAlloc ba
    char *ct
    apr_size_t blim
    char *tdir
    APR::Request::Hook hook

  CODE:
    RETVAL = apreq_parser_make(pool, ba, ct, apreq_parse_urlencoded,
                               blim, tdir, hook, NULL);

  OUTPUT:
    RETVAL


APR::Request::Parser
multipart(class, pool, ba, ct, blim=APREQ_DEFAULT_BRIGADE_LIMIT, tdir=NULL, hook=NULL)
    apreq_xs_subclass_t class
    APR::Pool pool
    APR::BucketAlloc ba
    char *ct
    apr_size_t blim
    char *tdir
    APR::Request::Hook hook

  CODE:
    RETVAL = apreq_parser_make(pool, ba, ct, apreq_parse_multipart,
                               blim, tdir, hook, NULL);

  OUTPUT:
    RETVAL

APR::Request::Parser
default(class, pool, ba, ct, blim=APREQ_DEFAULT_BRIGADE_LIMIT, tdir=NULL, hook=NULL)
    apreq_xs_subclass_t class
    APR::Pool pool
    APR::BucketAlloc ba
    char *ct
    apr_size_t blim
    char *tdir
    APR::Request::Hook hook
  PREINIT:
    apreq_parser_function_t parser;


  CODE:
    parser = apreq_parser(ct);
    if (parser == NULL)
        XSRETURN_UNDEF;

    RETVAL = apreq_parser_make(pool, ba, ct, parser,
                               blim, tdir, hook, NULL);

  OUTPUT:
    RETVAL
