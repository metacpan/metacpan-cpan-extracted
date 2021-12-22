#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <string.h>
#include "src/yuarel.c"

#define ERR_PREFIX        "[URL_ERROR]"
#define MAX_URL_LENGTH    1024
#define MAX_PATH_ELEMENTS 256
#define MAX_QUERY_PARAMS  256


MODULE = URL::XS		PACKAGE = URL::XS
PROTOTYPES: DISABLE

SV* parse_url(SV *src_url)
PREINIT:
    struct yuarel y;
    unsigned long url_len;
    char url[MAX_URL_LENGTH];
CODE:
    HV *result = newHV();
    char *_url = SvPV(src_url, url_len);

    if (url_len > MAX_URL_LENGTH)
        Perl_croak(aTHX_ "%s: url too long (max %d symbols)", ERR_PREFIX, MAX_URL_LENGTH);

    strcpy(url, _url);

    if (yuarel_parse(&y, url) == -1)
        Perl_croak(aTHX_ "%s: Could not parse url: %s", ERR_PREFIX, url);

    hv_store(result, "scheme", 6, newSVpv(y.scheme, strlen(y.scheme)), 0);
    hv_store(result, "host",   4, newSVpv(y.host,   strlen(y.host)  ), 0);
    hv_store(result, "port",   4, newSViv(y.port),                     0);

    if (y.username == NULL) {
        hv_store(result, "username", 8, &PL_sv_undef, 0);
    } else {
        hv_store(result, "username", 8, newSVpv(y.username, strlen(y.username)), 0);
    }

    if (y.password == NULL) {
        hv_store(result, "password", 8, &PL_sv_undef, 0);
    } else {
        hv_store(result, "password", 8, newSVpv(y.password, strlen(y.password)), 0);
    }

    if (y.path == NULL) {
        hv_store(result, "path", 4, &PL_sv_undef, 0);
    } else {
        hv_store(result, "path", 4, newSVpv(y.path, strlen(y.path)), 0);
    }

    if (y.query == NULL) {
        hv_store(result, "query", 5, &PL_sv_undef, 0);
    } else {
        hv_store(result, "query", 5, newSVpv(y.query, strlen(y.query)), 0);
    }

    if (y.fragment == NULL) {
        hv_store(result, "fragment", 8, &PL_sv_undef, 0);
    } else {
        hv_store(result, "fragment", 8, newSVpv(y.fragment, strlen(y.fragment)), 0);
    }

    RETVAL = newRV_noinc((SV*) result);
OUTPUT:
    RETVAL


SV* split_url_path(url_path, max_paths)
    char *url_path
    unsigned short max_paths
INIT:
    if (max_paths > MAX_PATH_ELEMENTS)
        Perl_croak(aTHX_ "%s: max_paths too much (max 256)", ERR_PREFIX);
    if (max_paths == 0)
        Perl_croak(aTHX_ "%s: max_paths must be a positive integer (from 1 to 256)", ERR_PREFIX);
CODE:
    AV *result = newAV();
    char *paths[max_paths];
    unsigned short int p = yuarel_split_path(url_path, paths, max_paths);

    if (p > 0)
        p--;

    for(int i=0; i <= p; i++)
        av_push(result, newSVpv(paths[i], strlen(paths[i])));

    RETVAL = newRV_noinc((SV*) result);
OUTPUT:
    RETVAL


SV* parse_url_query(url_query, ...)
    char *url_query
PREINIT:
    char *sep = "&";
    unsigned short q;
    struct yuarel_param params[MAX_QUERY_PARAMS];
CODE:
    HV *result = newHV();

    if (items > 1)
        sep = (char*)SvPV_nolen(ST(1));

    q = yuarel_parse_query(url_query, *sep, params, MAX_QUERY_PARAMS);

    if (q > 0)
        q--;

    char *k, *v;

    for (int i=0; i <= q; i++) {
        k = params[i].key;
        v = params[i].val;
        hv_store(result, k, strlen(k), newSVpv(v, strlen(v)), 0);
    }

    RETVAL = newRV_noinc((SV*) result);
OUTPUT:
    RETVAL
