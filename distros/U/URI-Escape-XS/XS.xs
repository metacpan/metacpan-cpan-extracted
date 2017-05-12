/*
 * $Id: XS.xs,v 0.10 2016/06/09 11:09:38 dankogai Exp dankogai $
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* #include "ppport.h" */
/* #include <URI::Escape::XS> */

# include <stdio.h>
# include <stdlib.h>
# include <string.h>
# include <ctype.h>

#if defined(_MSC_VER) && (_MSC_VER < 1900)
#define inline __inline
#endif

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

static char hex_chars[16] = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'};

#ifdef EBCDIC
static inline int my_hextol(const char *buf) {
    return (int)strtol((char *)buf, NULL, 16);
}
#else
static inline char my_hextoh(const char c) {
    return c <  '0' ? 0 
        :  c <= '9' ? c - '0'
        :  c <= 'F' ? c - 'A' + 10
        :  c <= 'f' ? c - 'a' + 10
        :  0;
}
static inline int my_hextol(const char *buf){
    return (my_hextoh(buf[0]) << 4) + my_hextoh(buf[1]);
}
#endif

SV *encode_uri_component(SV *sstr){
    SV *str, *result;
    int slen, dlen;
    U8 *src, *dst;
    int i;
    if (sstr == &PL_sv_undef) return newSV(0);
    str    = sv_2mortal(newSVsv(sstr)); /* make a copy to make func($1) work */
    if (!SvPOK(str)) sv_catpv(str, "");
    slen   = SvCUR(str);
    dlen   = 0;
    result = newSV(slen * 3 + 1); /* at most 3 times */
    
    SvPOK_on(result);
    src   = (U8 *)SvPV_nolen(str);
    dst   = (U8 *)SvPV_nolen(result);

    for (i = 0; i < slen; i++){
	if (escapes[ src[i] ]){
	    dst[dlen++] = '%';
	    dst[dlen++] = hex_chars[src[i]>>4];
	    dst[dlen++] = hex_chars[src[i]%16];
	}
	else{
	    dst[dlen++] = src[i];
	}
    }
    dst[dlen] = '\0'; /*  for sure; */
    SvCUR_set(result, dlen);
    return result;
}

SV *decode_uri_component(SV *suri){
    SV *uri, *result;
    int slen, dlen;
    U8 buf[8], *dst, *src, *bp;
    int i, hi, lo;
    if (suri == &PL_sv_undef) return newSV(0);
    /* if (!SvPOK(suri)) return newSV(0); */
    uri  = sv_2mortal(newSVsv(suri)); /* make a copy to make func($1) work */
    if (!SvPOK(uri)) sv_catpv(uri, "");
    slen = SvCUR(uri);
    dlen = 0;
    result = newSV(slen + 1);
   
    SvPOK_on(result);
    dst  = (U8 *)SvPV_nolen(result);
    src  = (U8 *)SvPV_nolen(uri);

    for (i = 0; i < slen; i++){
	if (src[i] == '%'){
	    if (isxdigit(src[i+1]) && isxdigit(src[i+2])){
		strncpy((char *)buf, (char *)(src + i + 1), 2);
		buf[2] = '\0'; /* @kazuho++ */
                hi = my_hextol((char *)buf);
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

MODULE = URI::Escape::XS		PACKAGE = URI::Escape::XS
PROTOTYPES: ENABLE

SV *
encodeURIComponent(str)
    SV *str;
CODE:
    RETVAL = encode_uri_component(str);
OUTPUT:
    RETVAL

SV *
decodeURIComponent(str)
    SV *str;
CODE:
    RETVAL = decode_uri_component(str);
OUTPUT:
    RETVAL
