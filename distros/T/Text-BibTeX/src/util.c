/* ------------------------------------------------------------------------
@NAME       : util.c
@DESCRIPTION: Memory allocation wrappers, the growable string buffer and
              a locale-independent ASCII strcasecmp().
-------------------------------------------------------------------------- */

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "bt_internal.h"

static void
default_oom (void)
{
   fputs ("btparse: out of memory\n", stderr);
   abort ();
}

static void (*oom_handler) (void) = default_oom;

void
bt_set_oom_handler (void (*handler) (void))
{
   oom_handler = handler ? handler : default_oom;
}

static void *
check (void *p)
{
   if (p == NULL)
   {
      oom_handler ();
      default_oom ();                   /* handler must not return */
   }
   return p;
}

void
bt_free (void *p)
{
   free (p);
}

void *
bt_xmalloc (size_t n)
{
   return check (malloc (n ? n : 1));
}

void *
bt_xcalloc (size_t n, size_t size)
{
   return check (calloc (n ? n : 1, size ? size : 1));
}

void *
bt_xrealloc (void *p, size_t n)
{
   return check (realloc (p, n ? n : 1));
}

char *
bt_xstrdup (const char *s)
{
   return s ? bt_xstrndup (s, strlen (s)) : NULL;
}

char *
bt_xstrndup (const char *s, size_t n)
{
   char * d = bt_xmalloc (n + 1);
   memcpy (d, s, n);
   d[n] = 0;
   return d;
}


/* ----------------------------------------------------------------------
 * String buffer
 */

void
bt_sbuf_init (bt_sbuf *b)
{
   b->s = NULL;
   b->len = 0;
   b->cap = 0;
}

void
bt_sbuf_free (bt_sbuf *b)
{
   free (b->s);
   bt_sbuf_init (b);
}

void
bt_sbuf_clear (bt_sbuf *b)
{
   b->len = 0;
   if (b->s)
      b->s[0] = 0;
}

void
bt_sbuf_grow (bt_sbuf *b, size_t extra)
{
   size_t need = b->len + extra + 1;
   size_t cap;

   if (need <= b->cap)
      return;
   cap = b->cap ? b->cap : 64;
   while (cap < need)
      cap *= 2;
   b->s = bt_xrealloc (b->s, cap);
   b->cap = cap;
}

void
bt_sbuf_putn (bt_sbuf *b, const char *s, size_t n)
{
   bt_sbuf_grow (b, n);
   memcpy (b->s + b->len, s, n);
   b->len += n;
   b->s[b->len] = 0;
}

void
bt_sbuf_putc (bt_sbuf *b, char c)
{
   if (b->len + 2 > b->cap)
      bt_sbuf_grow (b, 1);
   b->s[b->len++] = c;
   b->s[b->len] = 0;
}

void
bt_sbuf_puts (bt_sbuf *b, const char *s)
{
   if (s)
      bt_sbuf_putn (b, s, strlen (s));
}

void
bt_sbuf_vprintf (bt_sbuf *b, const char *fmt, va_list ap)
{
   va_list ap2;
   int     n;

   va_copy (ap2, ap);
   n = vsnprintf (NULL, 0, fmt, ap2);
   va_end (ap2);
   if (n < 0)
      return;
   bt_sbuf_grow (b, (size_t) n);
   vsnprintf (b->s + b->len, (size_t) n + 1, fmt, ap);
   b->len += (size_t) n;
}

char *
bt_sbuf_steal (bt_sbuf *b)
{
   char * s;

   if (b->s == NULL)
      bt_sbuf_grow (b, 0);
   s = b->s;
   s[b->len] = 0;
   bt_sbuf_init (b);
   return s;
}


int
bt_ascii_strcasecmp (const char *a, const char *b)
{
   for (;;)
   {
      int ca = BT_TOLOWER ((unsigned char) *a);
      int cb = BT_TOLOWER ((unsigned char) *b);
      if (ca != cb || ca == 0)
         return ca - cb;
      a++;
      b++;
   }
}
