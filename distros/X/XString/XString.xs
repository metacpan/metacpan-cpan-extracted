/*
*
* Copyright (c) 2019, cPanel, LLC.
* All rights reserved.
* http://cpanel.net
*
* This is free software; you can redistribute it and/or modify it under the
* same terms as Perl itself.
*
*/

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <embed.h>
#include <string.h>
#include "ppport.h"

/* stolen from B::cstring */
static SV *
cstring(pTHX_ SV *sv, bool perlstyle)
{
    SV *sstr;

    if (!SvOK(sv))
  return newSVpvs_flags("0", SVs_TEMP);

    sstr = newSVpvs_flags("\"", SVs_TEMP);

    if (perlstyle && SvUTF8(sv)) {
  SV *tmpsv = sv_newmortal(); /* Temporary SV to feed sv_uni_display */
  const STRLEN len = SvCUR(sv);
  const char *s = sv_uni_display(tmpsv, sv, 8*len, UNI_DISPLAY_QQ);
  while (*s)
  {
      if (*s == '"')
    sv_catpvs(sstr, "\\\"");
      else if (*s == '$')
    sv_catpvs(sstr, "\\$");
      else if (*s == '@')
    sv_catpvs(sstr, "\\@");
      else if (*s == '\\')
      {
    if (memCHRs("nrftaebx\\",*(s+1)))
        sv_catpvn(sstr, s++, 2);
    else
        sv_catpvs(sstr, "\\\\");
      }
      else /* should always be printable */
    sv_catpvn(sstr, s, 1);
      ++s;
  }
    }
    else
    {
  /* XXX Optimise? */
  STRLEN len;
  const char *s = SvPV(sv, len);
  for (; len; len--, s++)
  {
      /* At least try a little for readability */
      if (*s == '"')
    sv_catpvs(sstr, "\\\"");
      else if (*s == '\\')
    sv_catpvs(sstr, "\\\\");
            /* trigraphs - bleagh */
            else if (!perlstyle && *s == '?' && len>=3 && s[1] == '?') {
                Perl_sv_catpvf(aTHX_ sstr, "\\%03o", '?');
            }
      else if (perlstyle && *s == '$')
    sv_catpvs(sstr, "\\$");
      else if (perlstyle && *s == '@')
    sv_catpvs(sstr, "\\@");
      else if (isPRINT(*s))
    sv_catpvn(sstr, s, 1);
      else if (*s == '\n')
    sv_catpvs(sstr, "\\n");
      else if (*s == '\r')
    sv_catpvs(sstr, "\\r");
      else if (*s == '\t')
    sv_catpvs(sstr, "\\t");
      else if (*s == '\a')
    sv_catpvs(sstr, "\\a");
      else if (*s == '\b')
    sv_catpvs(sstr, "\\b");
      else if (*s == '\f')
    sv_catpvs(sstr, "\\f");
      else if (!perlstyle && *s == '\v')
    sv_catpvs(sstr, "\\v");
      else
      {
    /* Don't want promotion of a signed -1 char in sprintf args */
    const unsigned char c = (unsigned char) *s;
    Perl_sv_catpvf(aTHX_ sstr, "\\%03o", c);
      }
      /* XXX Add line breaks if string is long */
  }
    }
    sv_catpvs(sstr, "\"");
    return sstr;
}

MODULE = XString       PACKAGE = XString

void
cstring(sv)
  SV *  sv
    ALIAS:
  perlstring = 1
    PPCODE:
  PUSHs( cstring(aTHX_ sv, (bool)ix) );
