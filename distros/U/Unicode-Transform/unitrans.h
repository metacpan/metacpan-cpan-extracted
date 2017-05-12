#ifndef UNITRANS_H
#define UNITRANS_H

/* Perl 5.6.1 ? */
#ifndef uvuni_to_utf8
#define uvuni_to_utf8   uv_to_utf8
#endif /* uvuni_to_utf8 */

/* Perl 5.6.1 ? */
#ifndef utf8n_to_uvuni
#define utf8n_to_uvuni   utf8_to_uv
#endif /* utf8n_to_uvuni */

/* Perl 5.6.1 ? */
#ifndef UTF8_IS_INVARIANT
#define UTF8_IS_INVARIANT   UTF8_IS_ASCII
#endif /* UTF8_IS_INVARIANT */

/* UTF8_ALLOW_BOM is used before Perl 5.8.0 */
#ifndef UTF8_ALLOW_BOM
#define UTF8_ALLOW_BOM  (0)
#endif /* UTF8_ALLOW_BOM */

#ifndef UTF8_ALLOW_SURROGATE
#define UTF8_ALLOW_SURROGATE  (0)
#endif /* UTF8_ALLOW_SURROGATE */

#ifndef UTF8_ALLOW_FE_FF
#define UTF8_ALLOW_FE_FF  (0)
#endif /* UTF8_ALLOW_FE_FF */

#ifndef UTF8_ALLOW_FFFF
#define UTF8_ALLOW_FFFF  (0)
#endif /* UTF8_ALLOW_FFFF */

#define AllowAnyUTF (UTF8_ALLOW_SURROGATE|UTF8_ALLOW_BOM|UTF8_ALLOW_FE_FF|UTF8_ALLOW_FFFF)


static UV
ord_in_unicode(U8 *s, STRLEN curlen, STRLEN *retlen)
{

    UV uv; STRLEN ret;
    uv = utf8n_to_uvuni(s, curlen, &ret, AllowAnyUTF|UTF8_CHECK_ONLY);

    if (retlen) {
    /* in old Perl (<= 5.7.2), falsely UTF8_ALLOW_LONG == UTF8_CHECK_ONLY */
	if (ret == (STRLEN)-1 || ret > (STRLEN) UNISKIP(uv))
	    *retlen = 0;
	else
	    *retlen = ret;
    }
    return uv;
}

static U8*
app_in_unicode(U8* s, UV uv)
{
    return uvuni_to_utf8(s, uv);
}


/***************************************

All UTFs are limited in 0..D7FF and E000..10FFFF for roundtrip.

(i) on ASCII platform

          UTF-8 Bit pattern            1st Byte  2nd Byte  3rd Byte  4th Byte

                           0xxxxxxx    0xxxxxxx
                  00000yyy yyxxxxxx    110yyyyy  10xxxxxx
                  zzzzyyyy yyxxxxxx    1110zzzz  10yyyyyy  10xxxxxx
         000wwwzz zzzzyyyy yyxxxxxx    11110www  10zzzzzz  10yyyyyy  10xxxxxx

        UCS              UTF-8
   00000000-0000007F       1
   00000080-000007FF       2
   00000800-0000FFFF       3
   00010000-001FFFFF       4
   00200000-03FFFFFF       5
   04000000-7FFFFFFF       6

(ii) on EBCDIC platform

   UTF-8-Mod Bit pattern      1st Byte  2nd Byte  3rd Byte  4th Byte  5th Byte
          00000000 0xxxxxxx   0xxxxxxx
          00000000 100xxxxx   100xxxxx
          000000yy yyyxxxxx   110yyyyy  101xxxxx
          00zzzzyy yyyxxxxx   1110zzzz  101yyyyy  101xxxxx
 000000ww wzzzzzyy yyyxxxxx   11110www  101zzzzz  101yyyyy  101xxxxx
 00vvwwww wzzzzzyy yyyxxxxx   111110vv  101wwwww  101zzzzz  101yyyyy  101xxxxx

        UCS            UTF-EBCDIC
   00000000-0000009F       1
   000000A0-000003FF       2
   00000400-00003FFF       3
   00004000-0003FFFF       4
   00040000-003FFFFF       5
   00400000-03FFFFFF       6
   04000000-7FFFFFFF       7

(iii) length distribution

                      UTF-8  UTF8MOD  UTF-16  UTF-32
     0000..    007F     1       1       2       4
     0080..    009F     2       1       2       4
     00A0..    03FF     2       2       2       4
     0400..    07FF     2       3       2       4
     0800..    3FFF     3       3       2       4
     4000..    FFFF     3       4       2       4
    10000..   3FFFF     4       4       4       4
    40000..  10FFFF     4       5       4       4
   110000..  1FFFFF     4       5      N/A      4
   200000..  3FFFFF     5       5      N/A      4
   400000.. 3FFFFFF     5       6      N/A      4
  4000000..7FFFFFFF     6       7      N/A      4

  * UTF-8  to UTF-8M : Max 1.5    * UTF-16 to UTF-8  : Max 1.5
  * UTF-8  to UTF-16 : Max 2      * UTF-16 to UTF-8M : Max 2
  * UTF-8  to UTF-32 : Max 4      * UTF-16 to UTF-32 : Max 2
  * UTF-8M to UTF-8  : Max 2      * UTF-32 to UTF-8  : Max 1 (or 1.5)
  * UTF-8M to UTF-16 : Max 2      * UTF-32 to UTF-8M : Max 1.25 (or 1.75)
  * UTF-8M to UTF-32 : Max 4      * UTF-32 to UTF-16 : Max 1

 ***************************************/

#define UV_Max_UTF16		(0x10FFFF)
#define UV_Max_UTF		(0x7FFFFFFF)
#define UV_Max_UTF32		(0xFFFFFFFF)

#define UTF16_IS_SURROG(uv)	(0xD800 <= (uv) && (uv) <= 0xDFFF)
#define UTF16_HI_SURROG(uv)	(0xD800 <= (uv) && (uv) <= 0xDBFF)
#define UTF16_LO_SURROG(uv)	(0xDC00 <= (uv) && (uv) <= 0xDFFF)

#define Is_VALID_UTF(uv)	((uv) <= UV_Max_UTF16 && !UTF16_IS_SURROG(uv))

#define UTF8A_SKIP(uv)	\
	( (uv) < 0x80           ? 1 : \
	  (uv) < 0x800          ? 2 : \
	  (uv) < 0x10000        ? 3 : \
	  (uv) < 0x200000       ? 4 : \
	  (uv) < 0x4000000      ? 5 : \
	  (uv) < 0x80000000     ? 6 : 7 )

#define UTF8A_TRAIL(c)	(((c) & 0xC0) == 0x80)

#define UTF8M_SKIP(uv)	\
	( (uv) < 0xA0           ? 1 : \
	  (uv) < 0x400          ? 2 : \
	  (uv) < 0x4000         ? 3 : \
	  (uv) < 0x40000        ? 4 : \
	  (uv) < 0x400000       ? 5 : \
	  (uv) < 0x4000000      ? 6 : 7 )

#define UTF8M_TRAIL(c)	(((c) & 0xE0) == 0xA0)

#define UTF8A_LEN(b)		\
	( (b) < 0x80 ? 1 :	\
	  (b) < 0xC0 ? 0 :	\
	  (b) < 0xE0 ? 2 :	\
	  (b) < 0xF0 ? 3 :	\
	  (b) < 0xF8 ? 4 :	\
	  (b) < 0xFC ? 5 :	\
	  (b) < 0xFE ? 6 : 0)

#define UTF8M_LEN(b)		\
	( (b) < 0xA0 ? 1 :	\
	  (b) < 0xC0 ? 0 :	\
	  (b) < 0xE0 ? 2 :	\
	  (b) < 0xF0 ? 3 :	\
	  (b) < 0xF8 ? 4 :	\
	  (b) < 0xFC ? 5 :	\
	  (b) < 0xFE ? 6 :	\
		       7) /* ((b) == 0xFF) */

#define UTF8M_MaxLEN	(8)

static UV
ord_in_utf16le(U8 *s, STRLEN curlen, STRLEN *retlen)
{
    UV uv, luv;
    U8 *p = s;

    if (curlen < 2) {
	if (retlen)
	    *retlen = 0;
	return 0;
    }

    uv = (UV)((p[1] << 8) | p[0]);
    p += 2;

    if (UTF16_HI_SURROG(uv) && (4 <= curlen)) {
	luv = (UV)((p[1] << 8) | p[0]);

	if (UTF16_LO_SURROG(luv)) {
	    uv = 0x10000 + ((uv-0xD800) * 0x400) + (luv-0xDC00);
	    p += 2;
	}
    }

    if (retlen)
	*retlen = p - s;
    return uv;
}


static UV
ord_in_utf16be(U8 *s, STRLEN curlen, STRLEN *retlen)
{
    UV uv, luv;
    U8 *p = s;

    if (curlen < 2) {
	if (retlen)
	    *retlen = 0;
	return 0;
    }

    uv = (UV)((p[0] << 8) | p[1]);
    p += 2;

    if (UTF16_HI_SURROG(uv) && (4 <= curlen)) {
	luv = (UV)((p[0] << 8) | p[1]);

	if (UTF16_LO_SURROG(luv)) {
	    uv = 0x10000 + ((uv-0xD800) * 0x400) + (luv-0xDC00);
	    p += 2;
	}
    }

    if (retlen)
	*retlen = p - s;
    return uv;
}


static UV
ord_in_utf32le(U8 *s, STRLEN curlen, STRLEN *retlen)
{
    UV uv; int i;
    if (curlen < 4) {
	if (retlen)
	    *retlen = 0;
	return 0;
    }

    if (retlen)
	*retlen = 4;

    uv = s[3];
    for (i = 2; i >= 0; --i) {
	uv <<= 8;
	uv |= s[i];
    }
    return uv;
}


static UV
ord_in_utf32be(U8 *s, STRLEN curlen, STRLEN *retlen)
{
    UV uv; U8* e;
    if (curlen < 4) {
	if (retlen)
	    *retlen = 0;
	return 0;
    }

    if (retlen)
	*retlen = 4;

    e = s + 4;
    uv = *s++;
    while (s < e) {
	uv <<= 8;
	uv |= *s++;
    }
    return uv;
}


static UV
ord_in_utf8(U8 *s, STRLEN curlen, STRLEN *retlen)
{
    UV uv = 0;
    STRLEN len, i;

    if (curlen == 0) {
	if (retlen)
	    *retlen = 0;
	return 0;
    }

    len = (STRLEN) UTF8A_LEN(*s);

    if (curlen < len || len == 0) {
	if (retlen)
	    *retlen = 0;
	return 0;
    }

    if (*s < 0x80) {
	uv = (UV)*s;
    }
    else if (*s < 0xE0) {
	uv = (UV)(((s[0] & 0x1f) << 6) | (s[1] & 0x3f));
    }
    else if (*s < 0xF0) {
	uv = (UV)(((s[0] & 0x0f) << 12) |
		  ((s[1] & 0x3f) <<  6) | (s[2] & 0x3f));
    }
    else if (*s < 0xF8) {
	uv = (UV)(((s[0] & 0x07) << 18) | ((s[1] & 0x3f) << 12) |
		  ((s[2] & 0x3f) <<  6) |  (s[3] & 0x3f));
    }
    else if (*s < 0xFC) {
	uv = (UV)(((s[0] & 0x03) << 24) | ((s[1] & 0x3f) << 18) |
		  ((s[2] & 0x3f) << 12) | ((s[3] & 0x3f) <<  6) |
		   (s[4] & 0x3f));
    }
    else if (*s < 0xFE) {
	uv = (UV)(((s[0] & 0x01) << 30) | ((s[1] & 0x3f) << 24) |
		  ((s[2] & 0x3f) << 18) | ((s[3] & 0x3f) << 12) |
		  ((s[4] & 0x3f) <<  6) |  (s[5] & 0x3f));
    }

    for (i = 1; i < len; i++) {
	if (!UTF8A_TRAIL(s[i])) {
	    len = 0;
	    break;
	}
    }

    if (len != (STRLEN) UTF8A_SKIP(uv))
	len = 0;

    if (retlen)
	*retlen = len;
    return uv;
}


static UV
ord_in_utfebcdic(U8 *s, STRLEN curlen, STRLEN *retlen, U8* table)
{
    UV uv = 0;
    U8 ini, *p, *d, buff[UTF8M_MaxLEN];
    STRLEN len, i;

    if (curlen == 0) {
	if (retlen)
	    *retlen = 0;
	return 0;
    }

    ini = table ? table[*s] : *s;
    len = (STRLEN) UTF8M_LEN(ini);

    if (curlen < len || len == 0) {
	if (retlen)
	    *retlen = 0;
	return 0;
    }

    if (table) {
	for (p = s, d = buff; (STRLEN)(p - s) < len; d++, p++)
	    *d = table[*p];
	s = buff;
    }

    if (*s < 0xA0) {
	uv = (UV)*s;
    }
    else if (*s < 0xE0) {
	uv = (UV)(((s[0] & 0x1f) << 5) | (s[1] & 0x1f));
    }
    else if (*s < 0xF0) {
	uv = (UV)(((s[0] & 0x0f) << 10) |
		  ((s[1] & 0x1f) <<  5) | (s[2] & 0x1f));
    }
    else if (*s < 0xF8) {
	uv = (UV)(((s[0] & 0x07) << 15) | ((s[1] & 0x1f) << 10) |
		  ((s[2] & 0x1f) <<  5) |  (s[3] & 0x1f));
    }
    else if (*s < 0xFC) {
	uv = (UV)(((s[0] & 0x03) << 20) | ((s[1] & 0x1f) << 15) |
		  ((s[2] & 0x1f) << 10) | ((s[3] & 0x1f) <<  5) |
		   (s[4] & 0x1f));
    }
    else if (*s < 0xFE) {
	uv = (UV)(((s[0] & 0x01) << 25) | ((s[1] & 0x1f) << 20) |
		  ((s[2] & 0x1f) << 15) | ((s[3] & 0x1f) << 10) |
		  ((s[4] & 0x1f) <<  5) |  (s[5] & 0x1f));
    }
    else { /* (*s == 0xFF) */
	uv = (UV)(((s[0] & 0x01) << 30) | ((s[1] & 0x1f) << 25) |
		  ((s[2] & 0x1f) << 20) | ((s[3] & 0x1f) << 15) |
		  ((s[4] & 0x1f) << 10) | ((s[5] & 0x1f) <<  5) |
		   (s[6] & 0x1f));
    }

    for (i = 1; i < len; i++)
	if (!UTF8M_TRAIL(s[i])) {
	    len = 0;
	    break;
	}

    if (len != (STRLEN) UTF8M_SKIP(uv))
	len = 0;

    if (retlen)
	*retlen = len;
    return uv;
}


static UV
ord_in_utf8mod(U8 *s, STRLEN curlen, STRLEN *retlen)
{
    return ord_in_utfebcdic(s, curlen, retlen, NULL);
}


static U8*
app_in_utf16le(U8* s, UV uv)
{
    if (uv <= 0xFFFF) {
	*s++ = (U8)(uv & 0xff);
	*s++ = (U8)(uv >> 8);
    }
    else if (uv <= UV_Max_UTF16) {
	int hi, lo;
	uv -= 0x10000;
	hi = (0xD800 | (uv >> 10));
	lo = (0xDC00 | (uv & 0x3FF));
	*s++ = (U8)(hi & 0xff);
	*s++ = (U8)(hi >> 8);
	*s++ = (U8)(lo & 0xff);
	*s++ = (U8)(lo >> 8);
    }
    return s;
}


static U8*
app_in_utf16be(U8* s, UV uv)
{
    if (uv <= 0xFFFF) {
	*s++ = (U8)(uv >> 8);
	*s++ = (U8)(uv & 0xff);
    }
    else if (uv <= UV_Max_UTF16) {
	int hi, lo;
	uv -= 0x10000;
	hi = (0xD800 | (uv >> 10));
	lo = (0xDC00 | (uv & 0x3FF));
	*s++ = (U8)(hi >> 8);
	*s++ = (U8)(hi & 0xff);
	*s++ = (U8)(lo >> 8);
	*s++ = (U8)(lo & 0xff);
    }
    return s;
}


static U8*
app_in_utf32le(U8* s, UV uv)
{
    if (uv <= UV_Max_UTF32) {
	*s++ = (U8)((uv      ) & 0xff);
	*s++ = (U8)((uv >>  8) & 0xff);
	*s++ = (U8)((uv >> 16) & 0xff);
	*s++ = (U8)((uv >> 24) & 0xff);
    }
    return s;
}


static U8*
app_in_utf32be(U8* s, UV uv)
{
    if (uv <= UV_Max_UTF32) {
	*s++ = (U8)((uv >> 24) & 0xff);
	*s++ = (U8)((uv >> 16) & 0xff);
	*s++ = (U8)((uv >>  8) & 0xff);
	*s++ = (U8)((uv      ) & 0xff);
    }
    return s;
}


static U8*
app_in_utf8(U8* s, UV uv)
{
    if (uv < 0x80) {
	*s++ = (U8)(uv & 0xff);
    }
    else if (uv < 0x800) {
	*s++ = (U8)(( uv >>  6)         | 0xc0);
	*s++ = (U8)(( uv        & 0x3f) | 0x80);
    }
    else if (uv < 0x10000) {
	*s++ = (U8)(( uv >> 12)         | 0xe0);
	*s++ = (U8)(((uv >>  6) & 0x3f) | 0x80);
	*s++ = (U8)(( uv        & 0x3f) | 0x80);
    }
    else if (uv < 0x200000) {
	*s++ = (U8)(( uv >> 18)         | 0xf0);
	*s++ = (U8)(((uv >> 12) & 0x3f) | 0x80);
	*s++ = (U8)(((uv >>  6) & 0x3f) | 0x80);
	*s++ = (U8)(( uv        & 0x3f) | 0x80);
    }
    else if (uv < 0x4000000) {
	*s++ = (U8)(( uv >> 24)         | 0xf8);
	*s++ = (U8)(((uv >> 18) & 0x3f) | 0x80);
	*s++ = (U8)(((uv >> 12) & 0x3f) | 0x80);
	*s++ = (U8)(((uv >>  6) & 0x3f) | 0x80);
	*s++ = (U8)(( uv        & 0x3f) | 0x80);
    }
    else if (uv < 0x80000000) {
	*s++ = (U8)(( uv >> 30)         | 0xfc);
	*s++ = (U8)(((uv >> 24) & 0x3f) | 0x80);
	*s++ = (U8)(((uv >> 18) & 0x3f) | 0x80);
	*s++ = (U8)(((uv >> 12) & 0x3f) | 0x80);
	*s++ = (U8)(((uv >>  6) & 0x3f) | 0x80);
	*s++ = (U8)(( uv        & 0x3f) | 0x80);
    }
    return s;
}


static U8*
app_in_utfebcdic(U8* s, UV uv, U8* table)
{
    U8* p = s;

    if (uv < 0xa0) {
	*s++ = (U8)(uv & 0xff);
    }
    else if (uv < 0x400) {
	*s++ = (U8)(( uv >>  5)         | 0xc0);
	*s++ = (U8)(( uv        & 0x1f) | 0xa0);
    }
    else if (uv < 0x4000) {
	*s++ = (U8)(( uv >> 10)         | 0xe0);
	*s++ = (U8)(((uv >>  5) & 0x1f) | 0xa0);
	*s++ = (U8)(( uv        & 0x1f) | 0xa0);
    }
    else if (uv < 0x40000) {
	*s++ = (U8)(( uv >> 15)         | 0xf0);
	*s++ = (U8)(((uv >> 10) & 0x1f) | 0xa0);
	*s++ = (U8)(((uv >>  5) & 0x1f) | 0xa0);
	*s++ = (U8)(( uv        & 0x1f) | 0xa0);
    }
    else if (uv < 0x400000) {
	*s++ = (U8)(( uv >> 20)         | 0xf8);
	*s++ = (U8)(((uv >> 15) & 0x1f) | 0xa0);
	*s++ = (U8)(((uv >> 10) & 0x1f) | 0xa0);
	*s++ = (U8)(((uv >>  5) & 0x1f) | 0xa0);
	*s++ = (U8)(( uv        & 0x1f) | 0xa0);
    }
    else if (uv < 0x4000000) {
	*s++ = (U8)(( uv >> 25)         | 0xfc);
	*s++ = (U8)(((uv >> 20) & 0x1f) | 0xa0);
	*s++ = (U8)(((uv >> 15) & 0x1f) | 0xa0);
	*s++ = (U8)(((uv >> 10) & 0x1f) | 0xa0);
	*s++ = (U8)(((uv >>  5) & 0x1f) | 0xa0);
	*s++ = (U8)(( uv        & 0x1f) | 0xa0);
    }
    else if (uv < 0x80000000) {
	*s++ = (U8)(( uv >> 30)         | 0xfe);
	*s++ = (U8)(((uv >> 25) & 0x1f) | 0xa0);
	*s++ = (U8)(((uv >> 20) & 0x1f) | 0xa0);
	*s++ = (U8)(((uv >> 15) & 0x1f) | 0xa0);
	*s++ = (U8)(((uv >> 10) & 0x1f) | 0xa0);
	*s++ = (U8)(((uv >>  5) & 0x1f) | 0xa0);
	*s++ = (U8)(( uv        & 0x1f) | 0xa0);
    }

    if (table) {
	for ( ; p < s; p++)
	    *p = table[*p];
    }

    return s;
}


static U8*
app_in_utf8mod(U8* s, UV uv)
{
    return app_in_utfebcdic(s, uv, NULL);
}


static U8 e2i_cp1047[] = {
  0x00, 0x01, 0x02, 0x03, 0x9C, 0x09, 0x86, 0x7F,
  0x97, 0x8D, 0x8E, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
  0x10, 0x11, 0x12, 0x13, 0x9D, 0x0A, 0x08, 0x87,
  0x18, 0x19, 0x92, 0x8F, 0x1C, 0x1D, 0x1E, 0x1F,
  0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x17, 0x1B,
  0x88, 0x89, 0x8A, 0x8B, 0x8C, 0x05, 0x06, 0x07,
  0x90, 0x91, 0x16, 0x93, 0x94, 0x95, 0x96, 0x04,
  0x98, 0x99, 0x9A, 0x9B, 0x14, 0x15, 0x9E, 0x1A,

  0x20, 0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6,
  0xA7, 0xA8, 0xA9, 0x2E, 0x3C, 0x28, 0x2B, 0x7C,
  0x26, 0xAA, 0xAB, 0xAC, 0xAD, 0xAE, 0xAF, 0xB0,
  0xB1, 0xB2, 0x21, 0x24, 0x2A, 0x29, 0x3B, 0x5E,
  0x2D, 0x2F, 0xB3, 0xB4, 0xB5, 0xB6, 0xB7, 0xB8,
  0xB9, 0xBA, 0xBB, 0x2C, 0x25, 0x5F, 0x3E, 0x3F,
  0xBC, 0xBD, 0xBE, 0xBF, 0xC0, 0xC1, 0xC2, 0xC3,
  0xC4, 0x60, 0x3A, 0x23, 0x40, 0x27, 0x3D, 0x22,

  0xC5, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67,
  0x68, 0x69, 0xC6, 0xC7, 0xC8, 0xC9, 0xCA, 0xCB,
  0xCC, 0x6A, 0x6B, 0x6C, 0x6D, 0x6E, 0x6F, 0x70,
  0x71, 0x72, 0xCD, 0xCE, 0xCF, 0xD0, 0xD1, 0xD2,
  0xD3, 0x7E, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78,
  0x79, 0x7A, 0xD4, 0xD5, 0xD6, 0x5B, 0xD7, 0xD8,
  0xD9, 0xDA, 0xDB, 0xDC, 0xDD, 0xDE, 0xDF, 0xE0,
  0xE1, 0xE2, 0xE3, 0xE4, 0xE5, 0x5D, 0xE6, 0xE7,

  0x7B, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47,
  0x48, 0x49, 0xE8, 0xE9, 0xEA, 0xEB, 0xEC, 0xED,
  0x7D, 0x4A, 0x4B, 0x4C, 0x4D, 0x4E, 0x4F, 0x50,
  0x51, 0x52, 0xEE, 0xEF, 0xF0, 0xF1, 0xF2, 0xF3,
  0x5C, 0xF4, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58,
  0x59, 0x5A, 0xF5, 0xF6, 0xF7, 0xF8, 0xF9, 0xFA,
  0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
  0x38, 0x39, 0xFB, 0xFC, 0xFD, 0xFE, 0xFF, 0x9F,
};

static UV
ord_in_utfcp1047(U8 *s, STRLEN curlen, STRLEN *retlen)
{
    return ord_in_utfebcdic(s, curlen, retlen, e2i_cp1047);
}


static U8 i2e_cp1047[] = {
  0x00, 0x01, 0x02, 0x03, 0x37, 0x2D, 0x2E, 0x2F,
  0x16, 0x05, 0x15, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
  0x10, 0x11, 0x12, 0x13, 0x3C, 0x3D, 0x32, 0x26,
  0x18, 0x19, 0x3F, 0x27, 0x1C, 0x1D, 0x1E, 0x1F,
  0x40, 0x5A, 0x7F, 0x7B, 0x5B, 0x6C, 0x50, 0x7D,
  0x4D, 0x5D, 0x5C, 0x4E, 0x6B, 0x60, 0x4B, 0x61,
  0xF0, 0xF1, 0xF2, 0xF3, 0xF4, 0xF5, 0xF6, 0xF7,
  0xF8, 0xF9, 0x7A, 0x5E, 0x4C, 0x7E, 0x6E, 0x6F,

  0x7C, 0xC1, 0xC2, 0xC3, 0xC4, 0xC5, 0xC6, 0xC7,
  0xC8, 0xC9, 0xD1, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6,
  0xD7, 0xD8, 0xD9, 0xE2, 0xE3, 0xE4, 0xE5, 0xE6,
  0xE7, 0xE8, 0xE9, 0xAD, 0xE0, 0xBD, 0x5F, 0x6D,
  0x79, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87,
  0x88, 0x89, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96,
  0x97, 0x98, 0x99, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6,
  0xA7, 0xA8, 0xA9, 0xC0, 0x4F, 0xD0, 0xA1, 0x07,

  0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x06, 0x17,
  0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x09, 0x0A, 0x1B,
  0x30, 0x31, 0x1A, 0x33, 0x34, 0x35, 0x36, 0x08,
  0x38, 0x39, 0x3A, 0x3B, 0x04, 0x14, 0x3E, 0xFF,
  0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48,
  0x49, 0x4A, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56,
  0x57, 0x58, 0x59, 0x62, 0x63, 0x64, 0x65, 0x66,
  0x67, 0x68, 0x69, 0x6A, 0x70, 0x71, 0x72, 0x73,

  0x74, 0x75, 0x76, 0x77, 0x78, 0x80, 0x8A, 0x8B,
  0x8C, 0x8D, 0x8E, 0x8F, 0x90, 0x9A, 0x9B, 0x9C,
  0x9D, 0x9E, 0x9F, 0xA0, 0xAA, 0xAB, 0xAC, 0xAE,
  0xAF, 0xB0, 0xB1, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6,
  0xB7, 0xB8, 0xB9, 0xBA, 0xBB, 0xBC, 0xBE, 0xBF,
  0xCA, 0xCB, 0xCC, 0xCD, 0xCE, 0xCF, 0xDA, 0xDB,
  0xDC, 0xDD, 0xDE, 0xDF, 0xE1, 0xEA, 0xEB, 0xEC,
  0xED, 0xEE, 0xEF, 0xFA, 0xFB, 0xFC, 0xFD, 0xFE,
};

static U8*
app_in_utfcp1047(U8* s, UV uv)
{
    return app_in_utfebcdic(s, uv, i2e_cp1047);
}

#endif /* UNITRANS_H */
