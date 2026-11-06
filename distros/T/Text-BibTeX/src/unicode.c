/* ------------------------------------------------------------------------
@NAME       : unicode.c
@DESCRIPTION: UTF-8 decoding and the Unicode character classes and case
              mappings btparse needs.  The tables in unidata.h are
              generated at build time from the building perl's Unicode
              database (scripts/gen_unidata.pl).

              Every function here is safe on invalid UTF-8: a byte that
              does not start a valid sequence is treated as a single
              character with no properties, and is copied unchanged by
              the case-mapping functions.  This keeps "bytes" mode (where
              the input may be in any encoding) working.
-------------------------------------------------------------------------- */

#include <string.h>
#include "bt_internal.h"
#include "unidata.h"

#define NELEM(a) (sizeof (a) / sizeof ((a)[0]))

const char *
bt_unicode_version (void)
{
   return BT_UNICODE_VERSION;
}

size_t
bt_utf8_decode (const char *str, size_t n, long *cp)
{
   const unsigned char * s = (const unsigned char *) str;
   unsigned long c;
   size_t        len, i;

   *cp = -1;
   if (n == 0)
      return 0;
   if (s[0] < 0x80)
   {
      *cp = s[0];
      return 1;
   }
   else if (s[0] >= 0xC2 && s[0] <= 0xDF)
   {
      len = 2; c = s[0] & 0x1F;
   }
   else if (s[0] >= 0xE0 && s[0] <= 0xEF)
   {
      len = 3; c = s[0] & 0x0F;
   }
   else if (s[0] >= 0xF0 && s[0] <= 0xF4)
   {
      len = 4; c = s[0] & 0x07;
   }
   else
      return 1;                         /* invalid lead byte */

   if (n < len)
      return 1;
   for (i = 1; i < len; i++)
   {
      if ((s[i] & 0xC0) != 0x80)
         return 1;
      c = (c << 6) | (s[i] & 0x3F);
   }
   /* reject overlong forms, surrogates and values beyond U+10FFFF */
   if ((len == 3 && c < 0x800) || (len == 4 && (c < 0x10000 || c > 0x10FFFF))
       || (c >= 0xD800 && c <= 0xDFFF))
      return 1;
   *cp = (long) c;
   return len;
}

size_t
bt_utf8_encode (unsigned long cp, char *buf)
{
   unsigned char * b = (unsigned char *) buf;

   if (cp < 0x80)
   {
      b[0] = (unsigned char) cp;
      return 1;
   }
   if (cp < 0x800)
   {
      b[0] = 0xC0 | (cp >> 6);
      b[1] = 0x80 | (cp & 0x3F);
      return 2;
   }
   if (cp < 0x10000)
   {
      b[0] = 0xE0 | (cp >> 12);
      b[1] = 0x80 | ((cp >> 6) & 0x3F);
      b[2] = 0x80 | (cp & 0x3F);
      return 3;
   }
   b[0] = 0xF0 | (cp >> 18);
   b[1] = 0x80 | ((cp >> 12) & 0x3F);
   b[2] = 0x80 | ((cp >> 6) & 0x3F);
   b[3] = 0x80 | (cp & 0x3F);
   return 4;
}

/* Decode the character at a NUL-terminated string.  The NUL terminator
 * stops a truncated sequence, so we never read past it. */
static size_t
decode_at (const char *s, long *cp)
{
   size_t n = 0;

   while (n < 4 && s[n])
      n++;
   return bt_utf8_decode (s, n, cp);
}

size_t
bt_utf8_charlen (const char *s)
{
   long cp;

   if (*s == 0)
      return 0;
   return decode_at (s, &cp);
}

size_t
bt_utf8_length (const char *s, size_t n)
{
   size_t i = 0, count = 0;
   long   cp;

   while (i < n)
   {
      i += bt_utf8_decode (s + i, n - i, &cp);
      count++;
   }
   return count;
}


/* ----------------------------------------------------------------------
 * Table lookups
 */

static boolean
in_invlist (const unsigned long *inv, size_t len, long cp)
{
   size_t lo = 0, hi = len;

   if (cp < 0)
      return FALSE;
   /* find the number of list elements <= cp; odd means "in the set" */
   while (lo < hi)
   {
      size_t mid = (lo + hi) / 2;
      if (inv[mid] <= (unsigned long) cp)
         lo = mid + 1;
      else
         hi = mid;
   }
   return (lo & 1) != 0;
}

static const bt_casemap_entry *
find_map (const bt_casemap_entry *map, size_t len, long cp)
{
   size_t lo = 0, hi = len;

   while (lo < hi)
   {
      size_t mid = (lo + hi) / 2;
      if (map[mid].cp == (unsigned long) cp)
         return &map[mid];
      if (map[mid].cp < (unsigned long) cp)
         lo = mid + 1;
      else
         hi = mid;
   }
   return NULL;
}

boolean
bt_uni_islower (const char *s)
{
   long cp;

   if (BT_IS_ASCII (*s))
      return BT_IS_LOWER (*s);
   decode_at (s, &cp);
   return in_invlist (bt_uni_lower_inv, NELEM (bt_uni_lower_inv), cp);
}

boolean
bt_uni_isalpha (const char *s)
{
   long cp;

   if (BT_IS_ASCII (*s))
      return BT_IS_ALPHA (*s);
   decode_at (s, &cp);
   return in_invlist (bt_uni_alpha_inv, NELEM (bt_uni_alpha_inv), cp);
}

boolean
bt_uni_isalnum (const char *s)
{
   long cp;

   if (BT_IS_ASCII (*s))
      return BT_IS_ALNUM (*s);
   decode_at (s, &cp);
   return in_invlist (bt_uni_alnum_inv, NELEM (bt_uni_alnum_inv), cp);
}

boolean
bt_uni_ismark (const char *s)
{
   long cp;

   if (BT_IS_ASCII (*s))
      return FALSE;
   decode_at (s, &cp);
   return in_invlist (bt_uni_extend_inv, NELEM (bt_uni_extend_inv), cp);
}

size_t
bt_uni_grapheme_len (const char *s)
{
   size_t len;

   if (*s == 0)
      return 0;
   len = bt_utf8_charlen (s);
   while (s[len] && bt_uni_ismark (s + len))
      len += bt_utf8_charlen (s + len);
   return len;
}


/* ----------------------------------------------------------------------
 * Case mapping
 */

size_t
bt_uni_map_char (bt_sbuf *out, const char *s, bt_casemap how)
{
   const bt_casemap_entry * e = NULL;
   size_t len;
   long   cp;
   int    i;

   if (BT_IS_ASCII (*s))
   {
      char c = *s;
      bt_sbuf_putc (out, (how == BT_CASE_UPPER || how == BT_CASE_TITLE)
                    ? BT_TOUPPER (c) : BT_TOLOWER (c));
      return 1;
   }

   len = decode_at (s, &cp);
   if (cp >= 0)
   {
      switch (how)
      {
         case BT_CASE_LOWER:
            e = find_map (bt_uni_lc_map, NELEM (bt_uni_lc_map), cp); break;
         case BT_CASE_UPPER:
            e = find_map (bt_uni_uc_map, NELEM (bt_uni_uc_map), cp); break;
         case BT_CASE_TITLE:
            e = find_map (bt_uni_tc_map, NELEM (bt_uni_tc_map), cp); break;
         case BT_CASE_FOLD:
            e = find_map (bt_uni_fc_map, NELEM (bt_uni_fc_map), cp); break;
      }
   }

   if (e == NULL)
   {
      bt_sbuf_putn (out, s, len);
      return len;
   }
   for (i = 0; i < 3 && e->map[i]; i++)
   {
      char buf[4];
      bt_sbuf_putn (out, buf, bt_utf8_encode (e->map[i], buf));
   }
   return len;
}

char *
bt_uni_map_string (const char *s, bt_casemap how)
{
   bt_sbuf out;

   bt_sbuf_init (&out);
   bt_sbuf_grow (&out, strlen (s));
   while (*s)
      s += bt_uni_map_char (&out, s, how);
   return bt_sbuf_steal (&out);
}
