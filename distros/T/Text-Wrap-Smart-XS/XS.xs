#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define PRE_PROCESS(text, string, t) do {        \
    char ch;                                     \
    subst_to_spaces (trim (text, &ch), &string); \
    *(char *)(text + strlen (text)) = ch;        \
    spaces_to_space (string);                    \
    t = string;                                  \
} while (0)

#define FINALIZE_STRING() do { \
    *dest = '\0';              \
    *string = buf;             \
    return;                    \
} while (0)

#define IS_WHITESPACE(ws) \
    (ws == ' ' || ws == '\f' || ws == '\n' || ws == '\r' || ws == '\t')

#define SAVE_STRING(str, size, t)        \
    Newx (str, size + 1, char);          \
                                         \
    strncpy (str, t, size);              \
    *(str + size) = '\0';                \
                                         \
    t += size;                           \
                                         \
    EXTEND (SP, 1);                      \
    PUSHs (sv_2mortal(newSVpv(str, 0))); \
                                         \
    Safefree (str);

static const char *
trim (const char *text, char *ch)
{
    char *p;

    p = (char *)text + strlen (text);
    while (p > text && IS_WHITESPACE (*(p - 1)))
      p--;
    *ch = *p;
    *p = '\0';

    p = (char *)text;
    while (IS_WHITESPACE (*p))
      p++;
    return p;
}

static void
subst_to_spaces (const char *text, char **string)
{
  if (strpbrk (text, "\f\n\r\t"))
    {
      const char *src = text;
      char *dest;
      char *buf, *ws;
      const char *eot = text + strlen (text);
      Newx (buf, strlen (text) + 1, char);
      dest = buf;
      while ((ws = strpbrk (src, "\f\n\r\t")))
        {
          char *p = ws;
          strncpy (dest, src, ws - src);
          dest += ws - src;
          src  += ws - src;
          switch (*ws)
            {
              case '\f': p++; break; /* Form Feed */
              case '\n': p++; break; /* LF */
              case '\r': p++; break; /* CR */
              case '\t': p++; break; /* Tab */
              default:     abort (); /* never reached */
            }
          if (*ws == '\r' && *p == '\n') /* CRLF */
            p++;
          src += p - ws;
          if (p < eot)
            *dest++ = ' ';
          else
            FINALIZE_STRING ();
        }
      if (src < eot)
        {
          strncpy (dest, src, eot - src);
          dest += eot - src;
          src  += eot - src;
        }
      FINALIZE_STRING ();
    }
  else
    *string = savepv (text);
}

static void
spaces_to_space (char *string)
{
    char *s, *p;
    s = p = string;

    while (*p)
      {
        while (*p == ' ' && *(p + 1) == ' ')
          p++;
        *s++ = *p++;
      }
    *s = '\0';
}

static unsigned long
calc_average (unsigned long length, unsigned int wrap_at)
{
    unsigned int i;
    i = length / wrap_at;
    if (length % wrap_at != 0)
      i++;
    return ceil ((double)length / (double)i);
}

MODULE = Text::Wrap::Smart::XS                PACKAGE = Text::Wrap::Smart::XS

void
xs_exact_wrap (text, wrap_at)
      const char *text;
      unsigned int wrap_at;
    PROTOTYPE: $$
    INIT:
      unsigned long average, length, offset;
      char *string = NULL;
      char *eot, *t;
    PPCODE:
      PRE_PROCESS (text, string, t);
      length = strlen (t);
      eot = t + length;

      if (length == 0)
        {
          Safefree (string);
          XSRETURN_EMPTY;
        }

      average = calc_average (length, wrap_at);

      for (offset = 0; offset < length && *t; offset += average)
        {
          char *str;
          const unsigned long size = average > (eot - t) ? (eot - t) : average;

          SAVE_STRING (str, size, t);
        }

      Safefree (string);

void
xs_fuzzy_wrap (text, wrap_at)
      const char *text;
      unsigned int wrap_at;
    PROTOTYPE: $$
    INIT:
      unsigned long average, length;
      char *string = NULL;
      char *t;
    PPCODE:
      PRE_PROCESS (text, string, t);
      length = strlen (t);

      if (length == 0)
        {
          Safefree (string);
          XSRETURN_EMPTY;
        }

      average = calc_average (length, wrap_at);

      while (*t)
        {
          unsigned int spaces = 0;
          long remaining = average;
          unsigned long size;
          char *str, *s;

          /* calculate pos and size of each chunk */
          for (s = t; *s;)
            {
              char *ptr = strchr (s, ' ');
              if (ptr)
                {
                  unsigned long next_space;
                  char *n, *p;
                  /* advance pos to space */
                  remaining -= ptr - s;
                  p = s = ptr;
                  /* skip space */
                  p++;
                  /* advance pos after space */
                  remaining -= p - s;
                  /* get distance to next space */
                  n = strchr (p, ' ');
                  next_space = n ? n - p : 0;
                  /* pos and size complete */
                  if (next_space > remaining && spaces >= 1)
                    break;
                  else if (remaining <= 0)
                    break;
                  spaces++;
                  s = p;
                }
              else
                s += strlen (s);
            }
          size = s - t;
          if (!size)
            break;

          SAVE_STRING (str, size, t);

          if (*t)
            t++;
        }

      Safefree (string);
