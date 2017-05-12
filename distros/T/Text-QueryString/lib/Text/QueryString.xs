#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "xshelper.h"

STATIC_INLINE
SV *
decode_uri_component(SV *uri){
    SV *result;
    int slen, dlen;
    U8 buf[8], *dst, *src, *bp;
    int i, hi, lo;

    /* because of our usage, suri is guaranteed to be defined */
    /* if (suri == &PL_sv_undef) return newSV(0); */
    /* if (!SvPOK(suri)) return newSV(0); */
    /* because of our usage, it's okay to make possibly destructive calls */
    /*
    uri  = sv_2mortal(newSVsv(suri)); * make a copy to make func($1) work */
    slen = SvPOK(uri) ? SvCUR(uri) : 0;
    dlen = 0;
    result = newSV(slen + 1);
   
    SvPOK_on(result);
    dst  = (U8 *)SvPV_nolen(result);
    src  = (U8 *)SvPV_nolen(uri);

    for (i = 0; i < slen; i++){
    if (src[i] == '+'){
        dst[dlen++] = ' ';
    } else if (src[i] == '%'){
        if (isxdigit(src[i+1]) && isxdigit(src[i+2])){
        strncpy((char *)buf, (char *)(src + i + 1), 2);
        buf[2] = '\0'; /* @kazuho++ */
        hi = strtol((char *)buf, NULL, 16);
        dst[dlen++] = hi;
        i += 2;
        }
        else if(src[i+1] == 'u'
            && isxdigit(src[i+2]) && isxdigit(src[i+3])
            && isxdigit(src[i+4]) && isxdigit(src[i+5])){
        strncpy((char *)buf, (char *)(src + i + 2), 4);
        buf[4] = '\0'; /* RT#39135 */
        hi = strtol((char *)buf, NULL, 16);
        i += 5;
        if (hi < 0xD800  || 0xDFFF < hi){
            bp = uvchr_to_utf8((U8 *)buf, (UV)hi);
            strncpy((char *)(dst+dlen), (char *)buf, bp - buf);
            dlen += bp - buf;
        }else{
            if (0xDC00 <= hi){ /* invalid */
            warn("U+%04X is an invalid surrogate hi\n", hi);
            }else{
            i++;
            if(src[i] == '%' && src[i+1] == 'u'
               && isxdigit(src[i+2]) && isxdigit(src[i+3])
               && isxdigit(src[i+4]) && isxdigit(src[i+5])){
                strncpy((char *)buf, (char *)(src + i + 2), 4);
                lo = strtol((char *)buf, NULL, 16);
                i += 5;
                if (lo < 0xDC00 || 0xDFFF < lo){
                warn("U+%04X is an invalid lo surrogate", lo);
                }else{
                lo += 0x10000
                    + (hi - 0xD800) * 0x400 -  0xDC00;
                bp = uvchr_to_utf8((U8 *)buf, (UV)lo);
                strncpy((char *)(dst+dlen), (char *)buf, bp - buf);
                dlen += bp - buf;
                }
            }else{
                warn("lo surrogate is missing for U+%04X", hi);
            }
            }
        }
        }else{
        dst[dlen++] = '%';
        }
    }
    else{
        dst[dlen++] = src[i];
    }
    }

    dst[dlen] = '\0'; /*  for sure; */
    SvCUR_set(result, dlen);
    return result;
}

/* split on "=".
   *key contains the key, &key_len contains the length,
   *value contains the value, &valye_len contains the length.
   if "=" is not found, key = the string, value = ''
*/
STATIC_INLINE
void
split_kv(char *start, char *end, char **key, size_t *key_len, char **value, size_t *value_len) {
    char *cur = start;
    int found_eq = 0;
    while (cur != end) {
        if (*cur == '=') {
            found_eq = 1;
            *key = start;
            *key_len = cur - start;
            cur++;
            break;
        }
        cur++;
    }
    if (found_eq) {
        *value = cur;
        *value_len = end - cur;
    } else {
        *key = start;
        *key_len = end - start;
        *value_len = 0;
    }
}

MODULE = Text::QueryString     PACKAGE = Text::QueryString

PROTOTYPES: DISABLE

void
parse(self, qs)
        SV *self;
        char *qs;
    PREINIT:
        char *cur = qs;
        char *prev = qs;
        char *key, *value;
        size_t key_len, value_len;
    PPCODE:
        PERL_UNUSED_VAR(self);
        if (qs == NULL) { /* sanity */
            XSRETURN(0);
        }

        /* First, chop chop until end of string or & or ; */
        while (*cur != '\0') {
            if (*cur == '&' || *cur == ';') {
                /* found end of this pair. look for an = sign */
                split_kv(prev, cur, &key, &key_len, &value, &value_len);
                mXPUSHs(decode_uri_component(sv_2mortal(newSVpvn(key, key_len))));
                mXPUSHs(decode_uri_component(sv_2mortal(newSVpvn(value, value_len))));
                cur++;
                prev = cur;
            } else {
                cur++;
            }
        }

        /* do we have something leftover? */
        if (prev != cur) {
            split_kv(prev, cur, &key, &key_len, &value, &value_len);
            mXPUSHs(decode_uri_component(sv_2mortal(newSVpvn(key, key_len))));
            mXPUSHs(decode_uri_component(sv_2mortal(newSVpvn(value, value_len))));
        }


