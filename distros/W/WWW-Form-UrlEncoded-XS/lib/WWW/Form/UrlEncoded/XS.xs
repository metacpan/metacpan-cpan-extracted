#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT /* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#ifdef __cplusplus
} /* extern "C" */
#endif

#include "ppport.h"

static char escapes[256] =
/*  0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f */
{
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 1,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1,
    1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0,
    1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
};
static char xdigit[16] = {'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};

static SV *
url_decode(pTHX_ const char *src, int start, int end) {
    int dlen = 0, i = 0;
    char *d;
    char s2, s3;
    SV * dst;
    dst = newSV(0);
    (void)SvUPGRADE(dst, SVt_PV);
    d = SvGROW(dst, (end - start) * 3 + 1);

    for (i = start; i < end; i++ ) {
        if (src[i] == '+'){
            d[dlen++] = ' ';
        }
        else if ( src[i] == '%' && isxdigit(src[i+1]) && isxdigit(src[i+2]) ) {
            s2 = src[i+1];
            s3 = src[i+2];
            s2 -= s2 <= '9' ? '0'
                : s2 <= 'F' ? 'A' - 10
                            : 'a' - 10;
            s3 -= s3 <= '9' ? '0'
                : s3 <= 'F' ? 'A' - 10
                            : 'a' - 10;
            d[dlen++] = s2 * 16 + s3;
            i += 2;
        }
        else {
            d[dlen++] = src[i];
        }
    }
    SvCUR_set(dst, dlen);
    *SvEND(dst) = '\0';
    SvPOK_only(dst);
    return dst;
}

static
void
url_encode_key(const char *src, int src_len, char *d, int *key_len) {
    int i, dlen = 0;
    U8 s;
    for (i=0; i < src_len; i++ ) {
        s = src[i];
        if ( s == ' ' ) {
            d[dlen++] = '+';
        }
        else if ( escapes[s] ) {
            d[dlen++] = '%';
            d[dlen++] = xdigit[s >> 4];
            d[dlen++] = xdigit[s % 16];
        }
        else {
            d[dlen++] = s;
        }
    }
    d[dlen++] = '=';
    *key_len = dlen;
}

static
void
url_encode_val(char * dst, int *dst_len, const char * src, int src_len, char * delim, int delim_len ) {
    int i;
    int dlen = *dst_len;
    U8 s;

    for ( i=0; i<src_len; i++) {
        s = src[i];
        if ( s == ' ' ) {
            dst[dlen++] = '+';
        }
        else if ( escapes[s] ) {
            dst[dlen++] = '%';
            dst[dlen++] = xdigit[s >> 4];
            dst[dlen++] = xdigit[s % 16];
        }
        else {
            dst[dlen++] = s;
        }
    }
    for ( i=0; i<delim_len; i++ ) {
        dst[dlen++] = delim[i];
    }
    *dst_len = dlen;
}

static
void
memcat( char * dst, int *dst_len, const char * src, int src_len ) {
    int i;
    int dlen = *dst_len;
    for ( i=0; i<src_len; i++) {
        dst[dlen++] = src[i];
    }
    *dst_len = dlen;
}

static
void
memcopyset( char * dst, int dst_len, const char * src, int src_len ) {
    int i;
    int dlen = dst_len;
    for ( i=0; i<src_len; i++) {
        dst[dlen++] = src[i];
    }
}

static
char *
svpv2char(pTHX_ SV *string, STRLEN *len, int utf8) {
    char *str;
    STRLEN str_len;
    if ( utf8 == 1 ) {
        SvGETMAGIC(string);
        if (!SvUTF8(string)) {
            string = sv_mortalcopy(string);
            sv_utf8_encode(string);
        }
    }
    str = (char *)SvPV(string,str_len);
    *len = str_len;
    return str;
}

static
void
renewmem(pTHX_ char **d, int *cur, const int req) {
    if ( req > *cur ) {
        *cur = (int) (((req / 256) + 1) * 256);
        Renew(*d, *cur, char);
    }
}

MODULE = WWW::Form::UrlEncoded::XS    PACKAGE = WWW::Form::UrlEncoded::XS

PROTOTYPES: DISABLE

void
parse_urlencoded(qs)
    SV *qs
  PREINIT:
    char *src, *prev, *p;
    int i, prev_s=0, f;
    STRLEN src_len;
  PPCODE:
    if ( SvOK(qs) ) {
        src = (char *)SvPV(qs,src_len);
        prev = src;
        for ( i=0; i<src_len; i++ ) {
            if ( src[i] == '&' || src[i] == ';') {
                if ( prev[0] == ' ' ) {
                    prev++;
                    prev_s++;
                }
                p = memchr(prev, '=', i - prev_s);
                if ( p == NULL ) {
                    f = 0;
                    p = &prev[i-prev_s];
                }
                else {
                    f = 1;
                }
                mPUSHs(url_decode(aTHX_ src, prev_s, p - prev + prev_s ));
                mPUSHs(url_decode(aTHX_ src, p - prev + prev_s + f, i ));
                prev = &src[i+1];
                prev_s = i + 1;
            }
        }

        if ( i > prev_s ) {
            if ( prev[0] == ' ' ) {
                prev++;
                prev_s++;
            }
            p = memchr(prev, '=', i - prev_s);
            if ( p == NULL ) {
                f = 0;
                p = &prev[i-prev_s];
            }
            else {
                f = 1;
            }
            mPUSHs(url_decode(aTHX_ src, prev_s, p - prev + prev_s ));
            mPUSHs(url_decode(aTHX_ src, p - prev + prev_s + f, i ));
        }

        if ( src[src_len-1] == '&' || src[src_len-1] == ';' ) {
            mPUSHs(newSVpv("",0));
            mPUSHs(newSVpv("",0));
        }

    }

void
parse_urlencoded_arrayref(qs)
    SV *qs
  PREINIT:
    char *src, *prev, *p;
    int i, prev_s=0, f;
    AV *av;
    STRLEN src_len;
  PPCODE:
    av = newAV();
    ST(0) = sv_2mortal(newRV_noinc((SV *)av));
    if ( SvOK(qs) ) {
        src = (char *)SvPV(qs,src_len);
        prev = src;
        for ( i=0; i<src_len; i++ ) {
            if ( src[i] == '&' || src[i] == ';') {
                if ( prev[0] == ' ' ) {
                    prev++;
                    prev_s++;
                }
                p = memchr(prev, '=', i - prev_s);
                if ( p == NULL ) {
                    f = 0;
                    p = &prev[i-prev_s];
                }
                else {
                    f = 1;
                }
                av_push(av, url_decode(aTHX_ src, prev_s, p - prev + prev_s ));
                av_push(av, url_decode(aTHX_ src, p - prev + prev_s + f, i ));
                prev = &src[i+1];
                prev_s = i + 1;
            }
        }

        if ( i > prev_s ) {
            if ( prev[0] == ' ' ) {
                prev++;
                prev_s++;
            }
            p = memchr(prev, '=', i - prev_s);
            if ( p == NULL ) {
                f = 0;
                p = &prev[i-prev_s];
            }
            else {
                f = 1;
            }
            av_push(av, url_decode(aTHX_ src, prev_s, p - prev + prev_s ));
            av_push(av, url_decode(aTHX_ src, p - prev + prev_s + f, i ));
        }

        if ( src[src_len-1] == '&' || src[src_len-1] == ';' ) {
            av_push(av, newSVpv("",0));
            av_push(av,newSVpv("",0));
        }
    }
    XSRETURN(1);

SV *
build_urlencoded(...)
  ALIAS:
    WWW::Form::UrlEncoded::XS::build_urlencoded = 0
    WWW::Form::UrlEncoded::XS::build_urlencoded_utf8 = 1
  PREINIT:
    int i, j, dlen = 0, dsize = 1024, key_len, val_len;
    SV *st_key, *st_val, *av_val;
    AV *a_list, *a_val;
    HV *h_list;
    HE *h_key;
    char *d, *key_src, *val_src, *key, *delim, *delim_val;
    STRLEN key_src_len, val_src_len, delim_len;
  CODE:
    Newx(d, dsize, char);
    Newx(delim, 4, char);
    delim[0] = '&';
    delim_len = 1;

    if ( SvOK(ST(0)) && SvROK(ST(0)) && SvTYPE(SvRV(ST(0))) == SVt_PVAV ) {
        /* build_urlencoded([a=>z]) */
       if ( items > 1 && SvOK(ST(1)) ) {
           delim_val = svpv2char(aTHX_ ST(1), &delim_len, ix);
           Renew(delim, delim_len ,char);
           memcopyset(delim, 0, delim_val, delim_len);
       }

       a_list = (AV *)SvRV(ST(0));
       for (i=0; i<=av_len(a_list); i++) {
            st_key = *av_fetch(a_list,i,0);
            if ( !SvOK(st_key) ) {
                Newx(key,1,char);
                key_len = 1;
                key[0] = '=';
            }
            else {
                key_src = svpv2char(aTHX_ st_key, &key_src_len, ix);
                Newx(key,key_src_len * 3 + 1, char);
                url_encode_key(key_src, key_src_len, key, &key_len);
            }
            /* value */
            i++;
            if ( i > av_len(a_list) ) {
                /* key is last  */
                renewmem(aTHX_ &d, &dsize, dlen + key_len + delim_len);
                memcat(d, &dlen, key, key_len);
                memcat(d, &dlen, delim, delim_len);
            }
            else {
                st_val = *av_fetch(a_list,i,0);;
                if ( !SvOK(st_val) ) {
                    /* key but last or value is undef */
                    renewmem(aTHX_ &d, &dsize, dlen + key_len + delim_len);
                    memcat(d, &dlen, key, key_len);
                    memcat(d, &dlen, delim, delim_len);
                }
                else if ( SvROK(st_val) && SvTYPE(SvRV(st_val)) == SVt_PVAV ) {
                    /* array ref */
                    a_val = (AV *)SvRV(st_val);
                    for (j=0; j<=av_len(a_val); j++) {
                        av_val = *av_fetch(a_val,j,0);
                        if ( !SvOK(av_val) ) {
                            renewmem(aTHX_ &d, &dsize, dlen + key_len);
                            memcat(d, &dlen, key, key_len);
                        }
                        else {
                            val_src = svpv2char(aTHX_ av_val, &val_src_len, ix);
                            renewmem(aTHX_ &d, &dsize, dlen + key_len + (val_src_len*3) + delim_len + 1);
                            memcat(d, &dlen, key, key_len);
                            url_encode_val(d, &dlen, val_src, val_src_len, delim, delim_len);
                        }
                    }
                }
                else {
                    /* sv */
                    val_src = svpv2char(aTHX_ st_val, &val_src_len, ix);
                    renewmem(aTHX_ &d, &dsize, dlen + key_len + (val_src_len*3) + delim_len + 1);
                    memcat(d, &dlen, key, key_len);
                    url_encode_val(d, &dlen, val_src, val_src_len, delim, delim_len);
                }
            }
            Safefree(key);
        }
    }
    else if ( SvOK(ST(0)) && SvROK(ST(0)) && SvTYPE(SvRV(ST(0))) == SVt_PVHV ) {
        /* build_urlencoded({a=>z]}) */
       if ( items > 1 && SvOK(ST(1)) ) {
           delim_val = svpv2char(aTHX_ ST(1), &delim_len, ix);
           Renew(delim, delim_len ,char);
           memcopyset(delim, 0, delim_val, delim_len);
       }
       h_list = (HV *)SvRV(ST(0));
       hv_iterinit(h_list);
       while ( (h_key = hv_iternext(h_list)) != NULL ) {
           st_key = hv_iterkeysv(h_key);
            if ( !SvOK(st_key) ) {
                Newx(key,1,char);
                key_len = 1;
                key[0] = '=';
            }
            else {
                key_src = svpv2char(aTHX_ st_key, &key_src_len, ix);
                Newx(key,key_src_len * 3 + 1, char);
                url_encode_key(key_src, key_src_len, key, &key_len);
            }
            /* value */
            st_val = HeVAL(h_key);
            if ( !SvOK(st_val) ) {
                /* key but last or value is undef */
                renewmem(aTHX_ &d, &dsize, dlen + key_len + delim_len);
                memcat(d, &dlen, key, key_len);
                memcat(d, &dlen, delim, delim_len);
            }
            else if ( SvROK(st_val) && SvTYPE(SvRV(st_val)) == SVt_PVAV ) {
                /* array ref */
                a_val = (AV *)SvRV(st_val);
                for (j=0; j<=av_len(a_val); j++) {
                    av_val = *av_fetch(a_val,j,0);
                    if ( !SvOK(av_val) ) {
                        renewmem(aTHX_ &d, &dsize, dlen + key_len);
                        memcat(d, &dlen, key, key_len);
                        memcat(d, &dlen, delim, delim_len);
                    }
                    else {
                        val_src = svpv2char(aTHX_ av_val, &val_src_len, ix);
                        renewmem(aTHX_ &d, &dsize, dlen + key_len + (val_src_len*3) + delim_len + 1);
                        memcat(d, &dlen, key, key_len);
                        url_encode_val(d, &dlen, val_src, val_src_len, delim, delim_len);
                    }
                }
            }
            else {
                /* sv */
                val_src = svpv2char(aTHX_ st_val, &val_src_len, ix);
                renewmem(aTHX_ &d, &dsize, dlen + key_len + (val_src_len*3) + delim_len + 1);
                memcat(d, &dlen, key, key_len);
                url_encode_val(d, &dlen, val_src, val_src_len, delim, delim_len);
            }
            Safefree(key);
        }
    }
    else {
        if ( items > 2 && items % 2 == 1 ) {
           delim_val = svpv2char(aTHX_ ST(items-1), &delim_len, ix);
           Renew(delim, delim_len ,char);
           memcopyset(delim, 0, delim_val, delim_len);
           items--;
        }
        for( i=0; i < items; i++ ) {
            st_key = ST(i);
            if ( !SvOK(st_key) ) {
                Newx(key,1,char);
                key_len = 1;
                key[0] = '=';
            }
            else {
                key_src = svpv2char(aTHX_ st_key, &key_src_len, ix);
                Newx(key,key_src_len * 3 + 1, char);
                url_encode_key(key_src, key_src_len, key, &key_len);
            }
            /* value */
            i++;
            if ( i ==  items ) {
                /* key is last  */
                renewmem(aTHX_ &d, &dsize, dlen + key_len + delim_len);
                memcat(d, &dlen, key, key_len);
                memcat(d, &dlen, delim, delim_len);
            }
            else {
                st_val = ST(i);
                if ( !SvOK(st_val) ) {
                    /* key but last or value is undef */
                    renewmem(aTHX_ &d, &dsize, dlen + key_len + delim_len);
                    memcat(d, &dlen, key, key_len);
                    memcat(d, &dlen, delim, delim_len);
                }
                else if ( SvROK(st_val) && SvTYPE(SvRV(st_val)) == SVt_PVAV ) {
                    /* array ref */
                    a_val = (AV *)SvRV(st_val);
                    for (j=0; j<=av_len(a_val); j++) {
                        av_val = *av_fetch(a_val,j,0);
                        if ( !SvOK(av_val) ) {
                            renewmem(aTHX_ &d, &dsize, dlen + key_len);
                            memcat(d, &dlen, key, key_len);
                        }
                        else {
                            val_src = svpv2char(aTHX_ av_val, &val_src_len, ix);
                            renewmem(aTHX_ &d, &dsize, dlen + key_len + (val_src_len*3) + delim_len + 1);
                            memcat(d, &dlen, key, key_len);
                            url_encode_val(d, &dlen, val_src, val_src_len, delim, delim_len);
                        }
                    }
                }
                else {
                    /* sv */
                    val_src = svpv2char(aTHX_ st_val, &val_src_len, ix);
                    renewmem(aTHX_ &d, &dsize, dlen + key_len + (val_src_len*3) + delim_len + 1);
                    memcat(d, &dlen, key, key_len);
                    url_encode_val(d, &dlen, val_src, val_src_len, delim, delim_len);
                }
            }
            Safefree(key);
        }
    }

    if ( dlen > delim_len ) {
      dlen = dlen - delim_len;
    }

    RETVAL = newSVpvn(d, dlen);
    SvPOK_only(RETVAL);
    Safefree(delim);
    Safefree(d);
  OUTPUT:
    RETVAL
