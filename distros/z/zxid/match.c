/* match.c - simple shell-style filename matcher
**
** Only does ? * and **, and multiple patterns separated by |.  Returns 1 or 0.
**
** Copyright © 1995,2000 by Jef Poskanzer <jef@acme.com>.
** All rights reserved.
**
** Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions
** are met:
** 1. Redistributions of source code must retain the above copyright
**    notice, this list of conditions and the following disclaimer.
** 2. Redistributions in binary form must reproduce the above copyright
**    notice, this list of conditions and the following disclaimer in the
**    documentation and/or other materials provided with the distribution.
**
** THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
** ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
** IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
** ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
** FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
** DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
** OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
** HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
** LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
** OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
** SUCH DAMAGE.
*/
/* 20131121 slightly modified by Sampo Kellomaki (sampo@zxid.org) for zxid project.
 * See also fnmatch(1). */

#include <zx/errmac.h>
#include <string.h>

/* Called by:  zx_match x2, zx_match_one */
static int zx_match_one(const char* pat, int patlen, const char* str)
{
  const char* p;
  int i, pl;
  
  for ( p = pat; p - pat < patlen; ++p, ++str ) {
    if ( *p == '?' && *str != '\0' )
      continue;
    if ( *p == '*' ) {
      ++p;
      if ( *p == '*' ) {
	/* Double-wildcard matches anything. */
	++p;
	i = strlen( str );
      } else
	/* Single-wildcard matches anything but slash. */
	i = strcspn( str, "/" );
      pl = patlen - ( p - pat );
      for ( ; i >= 0; --i )  /* try the rest of the pat to tails of str */
	if ( zx_match_one( p, pl, &(str[i]) ) )
	  return 1;
      return 0;
    }
    if ( *p != *str )
      return 0;
  }
  if ( *str == '\0' )
    return 1;
  return 0;
}

/*() Check if simple path glob wild card pattern matches.
 * Returns 0 on failure and 1 on match.
 * Only does ?, * and **, and multiple patterns separated by |.
 * Exact match, suffix match (*.wsp) and prefix match
 * (/foo/bar*) are supported. The double asterisk (**) matches
 * also slash (/). */

/* Called by:  chkuid, do_file, really_check_referer x3, send_error_and_exit, zxid_mini_httpd_filter x2 */
int zx_match(const char* pat, const char* str)
{
  const char* or_clause;
  DD("pat(%s) str(%s)", pat, str);
  for (;;) {
    or_clause = strchr( pat, '|' );
    if (!or_clause)
      return zx_match_one( pat, strlen( pat ), str );
    if ( zx_match_one( pat, or_clause - pat, str ) )
      return 1;
    pat = or_clause + 1;
  }
}

/* EOF */
