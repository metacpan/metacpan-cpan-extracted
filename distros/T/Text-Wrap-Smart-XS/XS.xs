#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define PRE_PROCESS(text, string, t) \
    subst_newlines (text, &string);  \
    if (string)                      \
      t = string;                    \
    else                             \
      t = (char *)text;              \

void
subst_newlines (const char *text, char **string)
{
  if (strpbrk (text, "\n\r"))
    {
      const char *src = text;
      char *dest;
      char *buf, *nl;
      const char *eot = text + strlen (text);
      buf = dest = malloc (strlen (text) + 1);
      while ((nl = strpbrk (src, "\n\r")))
        {
          char *p = nl;
          strncpy (dest, src, nl - src);
          dest += nl - src;
          src  += nl - src;
          switch (*nl)
            {
              case '\n': p++; break; /* LF */
              case '\r': p++; break; /* CR */
              default:        break; /* never reached */
            }
          if (*nl == '\r' && *p == '\n') /* CRLF */
            p++;
          src += p - nl;
          if (p < eot)
            *dest++ = ' ';
          else
            goto end_of_text;
        }
      if (src < eot)
        {
          strncpy (dest, src, eot - src);
          dest += eot - src;
          src  += eot - src;
        }
      end_of_text:
      *dest = '\0';
      *string = buf;
    }
}

MODULE = Text::Wrap::Smart::XS                PACKAGE = Text::Wrap::Smart::XS

void
xs_exact_wrap (text, wrap_at)
      const char *text;
      unsigned int wrap_at;
    PROTOTYPE: $$
    INIT:
      unsigned int i;
      unsigned long average, length, offset;
      char *string = NULL;
      char *eot, *t;
    PPCODE:
      PRE_PROCESS (text, string, t);
      length = strlen (t);
      eot = t + length;

      i = length / wrap_at;
      if (length % wrap_at != 0)
        i++;
      average = ceil ((float)length / (float)i);

      for (offset = 0; offset < length && *t; offset += average)
        {
          char *str;
          unsigned long size = average > (eot - t) ? (eot - t) : average;

          Newx (str, size + 1, char);

          strncpy (str, t, size);
          *(str + size) = '\0';

          t += size;

          EXTEND (SP, 1);
          PUSHs (sv_2mortal(newSVpv(str, 0)));

          Safefree (str);
        }

      Safefree (string);

void
xs_fuzzy_wrap (text, wrap_at)
      const char *text;
      unsigned int wrap_at;
    PROTOTYPE: $$
    INIT:
      unsigned int i;
      unsigned long average, length;
      char *string = NULL;
      char *t;
    PPCODE:
      PRE_PROCESS (text, string, t);
      length = strlen (t);

      i = length / wrap_at;
      if (length % wrap_at != 0)
        i++;
      average = ceil ((float)length / (float)i);

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
                  /* skip spaces */
                  while (*p == ' ')
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

          Newx (str, size + 1, char);

          strncpy (str, t, size);
          *(str + size) = '\0';

          t += size;

          EXTEND (SP, 1);
          PUSHs (sv_2mortal(newSVpv(str, 0)));

          Safefree (str);

          if (*t)
            t++;
          while (*t == ' ')
            t++;
        }

      Safefree (string);
