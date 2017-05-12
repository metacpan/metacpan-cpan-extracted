#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

static UV
octet_to_uvuni(const U8 *s, STRLEN *retlen)
{
    *retlen = 1;
    return (UV) *s;
}

static UV
f_utf8_to_uvuni(const U8 *s, STRLEN *retlen)
{
    return utf8_to_uvuni(s, retlen);
}

MODULE = XML::Char    PACKAGE = XML::Char

void
_valid_xml_string(string)
    SV* string;

    PREINIT:
        STRLEN len;
        U8 * bytes;
        int in_range;
        int range_index;

        STRLEN ret_len;
        UV     uniuv;
        UV     (*next_chr)(const U8 *s, STRLEN *retlen);

    PPCODE:
        bytes    = (U8*)SvPV(string, len);
        next_chr = SvUTF8(string) ? &f_utf8_to_uvuni : &octet_to_uvuni;

        while (len > 0) {
            uniuv = (*next_chr)(bytes, &ret_len);
            bytes += ret_len;
            len   -= ret_len;

            if (
                (uniuv < 0x20) && (uniuv != 0x9) && (uniuv != 0xA) && (uniuv != 0xD)
                || (uniuv >  0xD7FF) && (uniuv <  0xE000)
                || (uniuv >  0xFFFD) && (uniuv < 0x10000)
                || (uniuv > 0x1FFFF)
            ) XSRETURN_NO;
        }

        XSRETURN_YES;
