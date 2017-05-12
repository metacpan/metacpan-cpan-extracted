/*
 * Copyright 1998, Gisle Aas.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the same terms as Perl itself.
 */


#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "patchlevel.h"
#if PATCHLEVEL <= 4 && !defined(PL_dowarn)
   #define PL_dowarn dowarn
#endif

#include "map8.h"

/* Some renaming that helps avoiding name class with the Perl versions
 * of the constructors
 */
#define map8__new          map8_new
#define map8__new_txtfile  map8_new_txtfile
#define map8__new_binfile  map8_new_binfile


/* Callbacks are always on and will invoke methods on the
 * Unicode::Map8 object.
 */

static U16*
to16_cb(U8 u, Map8* m, STRLEN *len)
{
    dSP;
    int n;
    SV* sv;
    U16* buf;
    STRLEN buflen;

    PUSHMARK(sp);
    XPUSHs(sv_2mortal(newRV_inc(m->obj)));
    XPUSHs(sv_2mortal(newSViv(u)));
    PUTBACK;

    n = perl_call_method("unmapped_to16", G_SCALAR);
    assert(n == 1);

    SPAGAIN;
    sv = POPs;
    PUTBACK;

    buf = (U16*)SvPV(sv, buflen);
    *len = buflen / sizeof(U16);
    return buf;
}

static U8*
to8_cb(U16 u, Map8* m, STRLEN *len)
{
    dSP;
    int n;
    SV* sv;

    PUSHMARK(sp);
    XPUSHs(sv_2mortal(newRV_inc(m->obj)));
    XPUSHs(sv_2mortal(newSViv(u)));
    PUTBACK;

    n = perl_call_method("unmapped_to8", G_SCALAR);
    assert(n == 1);

    SPAGAIN;
    sv = POPs;
    PUTBACK;

    return SvPV(sv, *len);
}



/* We use '~' magic to attach the Map8* objects to Unicode::Map8
 * objects.  The pointer to the attached Map8* object is stored in
 * the mg_obj fields of struct magic.  The attached Map8* object
 * is also automatically freed when the magic is freed.
 */
static int
map8_magic_free(pTHX_ SV* sv, MAGIC* mg)
{
    map8_free((Map8*)mg->mg_obj);
    return 1;
}

static MGVTBL magic_cleanup = { 0, 0, 0, 0, map8_magic_free };

static Map8*
find_map8(SV* obj)
{
    MAGIC *m;
    if (!sv_derived_from(obj, "Unicode::Map8"))
	croak("Not an Unicode::Map8 object");
    m = mg_find(SvRV(obj), '~');
    if (!m) croak("No magic attached");
    if (m->mg_len != 666) croak("Bad magic in ~-magic");
    return (Map8*) m->mg_obj;
}

static void
attach_map8(SV* obj, Map8* map8)
{
   SV* hv = SvRV(obj);
   MAGIC *m;
   sv_magic(hv, NULL, '~', 0, 666);
   m = mg_find(hv, '~');
   if (!m) croak("Can't find back ~ magic");
   m->mg_virtual = &magic_cleanup;
   m->mg_obj = (SV*)map8;

   /* register callbacks */
   map8->cb_to8  = to8_cb;
   map8->cb_to16 = to16_cb;
   map8->obj = (void*)hv;  /* so callbacks can find the object again */
}



MODULE = Unicode::Map8		PACKAGE = Unicode::Map8   PREFIX=map8_

PROTOTYPES: DISABLE

Map8*
map8__new()

Map8*
map8__new_txtfile(filename)
	char*filename

Map8*
map8__new_binfile(filename)
	char*filename

void
map8_addpair(map, u8, u16)
	Map8* map
	U8 u8
	U16 u16

U16
map8_default_to8(map,...)
	Map8* map
	ALIAS:
	   default_to16 = 1
	CODE:
	   RETVAL = ix ? map8_get_def_to16(map) : map8_get_def_to8(map);
	   if (items > 1) {
		if (ix)
		    map8_set_def_to16(map, SvIV(ST(1)));
		else
		    map8_set_def_to8(map, SvIV(ST(1)));
	   }
	OUTPUT:
	   RETVAL

void
map8_nostrict(map)
	Map8* map

U16
MAP8_BINFILE_MAGIC_HI()
	CODE:
	    RETVAL = MAP8_BINFILE_MAGIC_HI;
	OUTPUT:
	    RETVAL

U16
MAP8_BINFILE_MAGIC_LO()
	CODE:
	    RETVAL = MAP8_BINFILE_MAGIC_LO;
	OUTPUT:
	    RETVAL

U16
NOCHAR()
	CODE:
	    RETVAL = NOCHAR;
	OUTPUT:
	    RETVAL

SV*
_empty_block(map, block)
	Map8* map
	U8 block
	CODE:
	    if (block > 0xFF)
		croak("Only 256 blocks exists");
	    RETVAL = boolSV(map8_empty_block(map, block));
	OUTPUT:
	    RETVAL

U16
map8_to_char16(map, c)
	Map8* map
	U8 c
	CODE:
	    RETVAL = ntohs(map8_to_char16(map, c));
	OUTPUT:
	    RETVAL

U16
map8_to_char8(map, uc)
	Map8* map
	U16 uc

SV*
to8(map, str16)
	Map8* map
	PREINIT:
	    STRLEN len;
	    STRLEN origlen;
	    char* str;
	    char* cur;
	INPUT:
	    U16* str16 = (U16*)SvPV(ST(1), len);
	CODE:
	    if (PL_dowarn && (len % 2) != 0)
		warn("Uneven length of wide string");
	    len /= 2;
            origlen = len;
	    RETVAL = newSV(len + 1);
	    SvPOK_on(RETVAL);
	    str = SvPVX(RETVAL);

	    for (cur = str; len--; str16++) {
                U16 c16 = ntohs(*str16);
		U16 c = map8_to_char8(map, c16);
		if (c != NOCHAR) {
		    *cur++ = (U8)c;
		} else if (map->def_to8 != NOCHAR) {
		    *cur++ = (U8)map->def_to8;
		} else if (map->cb_to8) {
		    U8* buf;
		    STRLEN blen;
                    buf = map->cb_to8(c16, map, &blen);
		    if (buf && blen > 0) {
			if (blen == 1) {
			    *cur++ = *buf;
			} else {
			    /* we might need to grow the string buffer.
                             * Find out the minimum requirement and a
                             * guess that avoids growing each time if
                             * several char map longer strings
                             */
			    STRLEN curlen = cur - str;
			    STRLEN guess = origlen * (curlen + blen) /
                                           (origlen - len);
			    STRLEN min = curlen + blen + len + 1;

			    if (guess < min)
				guess = min;
                            else if (curlen <= 1 && guess > min*4)
				guess = min*4;

			    str = SvGROW(RETVAL, guess);
		            cur = str + curlen;
                            while (blen--)
				*cur++ = *buf++;
			}
		    }
		}
            }

	    SvCUR_set(RETVAL, cur - str);
	    *cur = '\0';

	OUTPUT:
	    RETVAL

SV*
to16(map, str8)
	Map8* map
	PREINIT:
	    STRLEN len;
	    STRLEN origlen;
	    U16* str;
	    U16* cur;
	INPUT:
	    U8* str8 = SvPV(ST(1), len);
	CODE:
            origlen = len;
	    RETVAL = newSV(sizeof(U16)*len + 1);
	    SvPOK_on(RETVAL);
	    str = (U16*)SvPVX(RETVAL);

	    for (cur = str; len--; str8++) {
		U16 c = map8_to_char16(map, *str8);
		if (c != NOCHAR) {
		    *cur++ = c;
		} else if (map->def_to16 != NOCHAR) {
		    *cur++ = map->def_to16;
		} else if (map->cb_to16) {
		    U16* buf;
		    STRLEN blen;
                    buf = map->cb_to16(*str8, map, &blen);
		    if (buf && blen > 0) {
			if (blen == 1) {
			    *cur++ = *buf;
			} else {
			    /* we might need to grow the string buffer.
                             * Find out the minimum requirement and a
                             * guess that avoids growing each time if
                             * several char map longer strings
                             */
			    STRLEN curlen = cur - str;
			    STRLEN guess = origlen * (curlen + blen) /
                                           (origlen - len);
			    STRLEN min = curlen + blen + len + 1;

			    if (guess < min)
				guess = min;
                            else if (curlen <= 1 && guess > min*4)
				guess = min*4;

			    str = (U16*)SvGROW(RETVAL, sizeof(U16)*guess);
		            cur = str + curlen;
                            while (blen--)
				*cur++ = *buf++;
			}
		    }
		}
            }

	    SvCUR_set(RETVAL, (cur - str)*sizeof(U16));
	    *cur = '\0';

	OUTPUT:
	    RETVAL

SV*
recode8(m1, m2, str)
	Map8* m1
	Map8* m2
	PREINIT:
	    STRLEN len;
	    STRLEN rlen;
	    char*  res;
	INPUT:
	    char* str = SvPV(ST(2), len);
	CODE:
	    RETVAL = newSV(len + 1);
	    SvPOK_on(RETVAL);
	    res = SvPVX(RETVAL);
	    map8_recode8(m1, m2, str, res, len, &rlen);
	    res[rlen] = '\0';
	    SvCUR_set(RETVAL, rlen);
	OUTPUT:
	    RETVAL
