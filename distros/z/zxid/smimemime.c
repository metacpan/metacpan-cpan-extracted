/* smimemime.c  -  Utility functions for performing MIME assembly and parsing
 *
 * Copyright (c) 1999 Sampo Kellomaki <sampo@iki.fi>, All Rights Reserved.
 * License: This software may be distributed under the same license
 *          terms as openssl (i.e. free, but mandatory attribution).
 *          See file LICENSE for details.
 *
 * 11.9.1999, Created. --Sampo
 * 13.9.1999, 0.1 released. Now adding verify. --Sampo
 * 1.10.1999, improved error handling, fixed decrypt --Sampo
 * 6.10.1999, separated from smimeutil.c --Sampo
 * 9.10.1999, reviewed for double frees --Sampo
 *
 * This module has been developed to support a Lingo XTRA that is supposed
 * to provide crypto functionality. It may, however, be useful for other
 * purposes as well.
 *
 * This is a very simple S/MIME library. For example the multipart
 * boundary separators are hard coded and no effort is made to verify
 * that mime entities are in their canonical form before signing (the
 * caller should make sure they are, canonical form means using CRLF
 * as line termination, among other things). Also the multipart functionality
 * only understands up to 3 attachments. For many tasks this is enough,
 * but if its not, feel free to write more generic utilities.
 *
 * Memory management: most routines malloc the results. Freeing them is
 * application's responsibility. I use libc malloc, but if in doubt
 * it might be safer to just leak the memory (i.e. don't ever free it).
 * This library works entirely in memory, so maximum memory consumption
 * might be more than twice the total size of all files to be encrypted.
 */

#include "platform.h"

#include <stdio.h>
#include <string.h>
#include <time.h>

#if defined(macintosh) || defined(__MWERKS__)
#include "macglue.h"
#endif

#include <openssl/crypto.h>
#include <openssl/buffer.h>
#include <openssl/bio.h>
#include <openssl/x509.h>
#include <openssl/pem.h>
#include <openssl/err.h>

#define SMIME_INTERNALS  /* we want also our internal helper functions */
#include "smimeutil.h"

#include "logprint.h"

/* Called by:  clear_sign, encrypt1, sign */
char*
cut_pem_markers_off(char* b, int n, char* algo) {
  int algolen = strlen(algo);
  if (!b) return NULL;
  b[n-6-algolen-4-5] = '\0'; /* cut off `-----END PKCS7-----\n' */
  b+=5+6+algolen+6;          /* skip `-----BEGIN PKCS7-----\n' */
  return b;  /* WARNING: returned value can not be freed */
}

/* As an additional goodie, this inserts possibly missing newline
 * to the end of pem entity.
 */

/* Called by:  get_pkcs7_from_pem */
char*
wrap_in_pem_markers(const char* b, char* algo) {
  char* bb;
  int n;
  int algolen = strlen(algo);  
  n = strlen(b);
  if (!(bb = (char*)OPENSSL_malloc(5+6+algolen+6+ n +5+4+algolen+6 +1 +1)))
    GOTO_ERR("no memory?");
  strcpy(bb, "-----BEGIN ");
  strcat(bb, algo);
  strcat(bb, "-----\n");
  strcat(bb, b);
  if (b[n-1] != '\012' && b[n-1] != '\015')  /* supply \n if missing */
    strcat(bb, "\n");
  strcat(bb, "-----END ");
  strcat(bb, algo);
  strcat(bb, "-----\n");
  n = strlen(bb);
  return bb;
err:
  return NULL;
}

/* reallocing every time is not exactly the most efficient way, but it
 * is simple and it works */

/* Called by:  attach x9, encrypt1, get_req_attr x3, mime_base64_entity x3, mime_mk_multipart x3, mime_raw_entity x3, sign, smime_mk_multipart_signed x4 */
char*
concat(char* b, const char* s)
{
  if (!(b = (char*)OPENSSL_realloc(b, strlen(b)+strlen(s)+1))) GOTO_ERR("no memory?");
  strcat(b,s);
  return b;
err:
  return NULL;
}

/* Called by:  get_req_attr */
char*
concatmem(char* b, const char* s, int len)
{
  int lb = strlen(b);
  if (!(b = (char*)OPENSSL_realloc(b, lb+len+1))) GOTO_ERR("no memory?");
  memcpy(b+lb, s, len);
  b[lb+len] = '\0';
  return b;
err:
  return NULL;
}

/* Arrange all headers for binary attachment */

/* Called by:  mime_mk_multipart x3 */
static char*
attach(char* b,
       const char* data,
       int len,
       const char* type,
       const char* name)
{
  /*int n;*/
  char* b64;
  
  if (!type) return b;  /* type==NULL */
  if (!*type) return b; /* type=="" */
  if (!data) return b;
  if (!name) return b;
  
  /*n =*/ smime_base64(1, data, len, &b64);
  if (!b64) return b;
  
  if (!(b = concat(b, CRLF "Content-type: "))) goto err;
  if (!(b = concat(b, type))) goto err;
  if (!(b = concat(b, "; name=\""))) goto err;
  if (!(b = concat(b, name))) goto err;
  if (!(b = concat(b, "\"" CRLF
		   "Content-transfer-encoding: base64" CRLF
		   "Content-disposition: inline; filename=\"")))
    goto err;
  if (!(b = concat(b, name))) goto err;
  if (!(b = concat(b, "\"" CRLF CRLF))) goto err;
  if (!(b = concat(b, b64))) goto err;
  if (!(b = concat(b, CRLF "--" SEP))) goto err;
  return b;
err:
  return NULL;
}

/* ======= M I M E   M U L T I P A R T   M A N I P U L A T I O N ======= */

/* Create MIME multipart/mixed entity containing some text and
 * then up to 3 attachmets. All attachments are base64 encoded so they
 * can be binary, if needed. Text itself is assumed 8bit.
 *
 * Note: In MIME multiparts the CRLF before --separator is considered
 * part of the separator. If data ends in CRLF, an empty line will
 * appear.
 */

/*
Content-type: multipart/mixed; boundary=separator_42

--separator_42
Content-type: text/plain
Content-transfer-encoding: 8bit

First part is text.
--separator_42
Content-type: image/gif; name="foo.gif"
Content-transfer-encoding: base64
Content-disposition: attachment; filename="foo.gif"

AQW232ASA232NFKDJFD==
--separator_42--
 */

/* Called by:  mk_multipart */
char*
mime_mk_multipart(const char* text,
	  const char* file1, int len1, const char* type1, const char* name1,
	  const char* file2, int len2, const char* type2, const char* name2,
	  const char* file3, int len3, const char* type3, const char* name3)
{
  char* b;
  
  /* Concatenate all components into one message. This type of stuff
   * is sooo ugly in C. I'm missing perl. */
  
  if (!(b = strdup("Content-type: multipart/mixed; boundary=" SEP CRLF
		   CRLF
		   "--" SEP CRLF
		   "Content-type: text/plain" CRLF
		   "Content-transfer-encoding: 8bit" CRLF
		   CRLF))) GOTO_ERR("no memory?");
  if (!(b = concat(b, text))) goto err;
  if (!(b = concat(b, CRLF "--" SEP))) goto err;

  if (!(b = attach(b, file1, len1, type1, name1))) goto err;
  if (!(b = attach(b, file2, len2, type2, name2))) goto err;
  if (!(b = attach(b, file3, len3, type3, name3))) goto err;
  
  if (!(b = concat(b, "--" CRLF))) goto err;
  return b;
err:
  return NULL;
}

/* Called by:  clear_sign */
char*  /* returns smime encoded clear sig blob, or NULL if error */
smime_mk_multipart_signed(const char* mime_entity, const char* sig_entity)
{
  char* b;
  
  if (!(b = strdup("Content-type: multipart/signed; protocol=\"application/x-pkcs7-signature\"; micalg=sha1; boundary=" SIG CRLF
		   CRLF
		   "--" SIG CRLF))) GOTO_ERR("no memory?");
  if (!(b = concat(b, mime_entity))) goto err;
  if (!(b = concat(b, CRLF "--" SIG CRLF
   "Content-Type: application/x-pkcs7-signature; name=\"smime.p7s\"" CRLF
   "Content-Transfer-Encoding: base64" CRLF
   "Content-Disposition: attachment; filename=\"smime.p7s\"" CRLF CRLF)))
    goto err;
  if (!(b = concat(b, sig_entity))) goto err;
  if (!(b = concat(b, CRLF "--" SIG "--" CRLF))) goto err;
  return b;

err:
  return NULL;
}

/* Finds boundary marker from `Content-type: multipart/...; boundary=sep'
 * header and splits the multiparts into array parts. Lengths of each
 * part go to lengths array. If parts is NULL, just returns the number
 * of parts found. Memory for each part is obtained from OPENSSL_malloc. Only
 * one level of multipart encoding is interpretted, i.e. if one of the
 * contained parts happens to be a multipart, it needs to be separately
 * interpretted on a second pass.
 *
 * *** WARNING: this is not totally robust and mime compliant, improvements
 *              welcome. --Sampo
 */

int  /* returns number of parts, -1 on error */
mime_split_multipart(const char* entity,
		     int max_parts,  /* how big following arrays are */
		     char* parts[],  /* NULL --> just count parts */
		     int lengths[])
{
  char separator[256];
  int nparts = -1;
  int sep_len, len;
  char* p;
  char* pp;
  char* ppp;
  char* start = NULL;  /* start of current sub entity */
  
  if (!entity || (parts && !lengths)) GOTO_ERR("NULL arg(s)");

  if (!(p = strstr(entity, "Content-type: multipart/")))
    GOTO_ERR("16 No `Content-type: multipart/...' header found");
  
  if (!(p = strstr(p, "boundary=")))
    GOTO_ERR("16 Badly formed multipart header. Didn't find `boundary='.");

  p+=9; /* strlen("boundary=") */
  sep_len = strcspn(p, "\015\012 ;");
  if (sep_len <= 0) GOTO_ERR("16 No boundary separator?");
  if (sep_len >= (int)sizeof(separator))
    GOTO_ERR("16 Too long boundary separator. Only 255 chars allowed.");
  
  separator[0] = separator[1] = '-';
  memcpy(separator+2, p, sep_len);
  sep_len+=2;
  separator[sep_len] = '\0';
  p+=sep_len;
  
  while ((p = strstr(p, separator))) {

    ppp = pp = p;
    p+=sep_len;
    if (*p != '\015' && *p != '\012' && *p != '-')
      continue;   /* False positive: separator appeared as line prefix */

    if (pp[-1] == '\012') pp--;  /* walk back and eat the CRLF */
    if (pp[-1] == '\015') pp--;
    if (pp == ppp)
      continue;  /* False positive: separator in middle of line */
    
    if (start && parts && nparts < max_parts) {      
      len = lengths[nparts] = pp-start;
      if (!(parts[nparts] = (char*)OPENSSL_malloc(len+1))) GOTO_ERR("no memory?");
      memcpy(parts[nparts], start, len);
      parts[nparts][len] = '\0';  /* Gratuitous nul termination */
    }
    
    nparts++;
    if (*p == '\015') p++;  /* Skip CRLF */
    if (*p == '\012') p++;  /* This is really mandatory */
    
    start = p;
  }
  return nparts;

/* Called by: */
err:
  if (parts) {
    /* free what we have allocated so far */
    for (sep_len = 0; sep_len < nparts; sep_len++)
      if (parts[sep_len])
	OPENSSL_free(parts[sep_len]);
  }
  return -1;
}

/* Called by:  main */
char*
mime_raw_entity(const char* text, const char* type)
{
  char* b;  
  if (!(b = strdup("Content-type: "))) GOTO_ERR("no memory?");
  if (!(b = concat(b, type))) goto err;
  if (!(b = concat(b, CRLF CRLF))) goto err;
  if (!(b = concat(b, text))) goto err;
  return b;
err:
  return NULL;
}

/* Called by:  main x3 */
char*
mime_base64_entity(const char* data, int len, const char* type)
{
  /*int n;*/
  char* b64;
  char* b;  
  if (!(b = strdup("Content-type: "))) GOTO_ERR("no memory?");
  if (!(b = concat(b, type))) goto err;
  if (!(b = concat(b, CRLF CRLF))) goto err;
  
  /*n =*/ smime_base64(1, data, len, &b64);
  if (!b64) GOTO_ERR("no memory?");
  if (!(b = concat(b, b64))) goto err;
  return b;
err:
  return NULL;
}

/* Canonicalization involves converting LF->CRLF (Unix) and CR->CRLF (Mac).
 * Canonicalization is of prime importance when signing data because
 * verification assumes canonicalized form. This canonicalization is really
 * not mime specific at all so you can use it for fixing PEM blobs
 * on Mac (becaue OpenSSL does not understand lone CR as line termination). */

/* Called by:  clear_sign, extract_certificate, extract_request, main, open_private_key, sign */
char*
mime_canon(const char* s)
{
  char* d;
  char* p;
  int len;
  len = strlen(s);
  p = d = (char*)OPENSSL_malloc(len + len);  /* Reserve spaces for CR's to be inserted. */
  if (!d) GOTO_ERR("no memory?");
  
  /* Scan and copy */

  for (; *s; s++) {
    if (s[0] != '\015' && s[0] != '\012')
      *(p++) = *s; /* pass thru */
    else {
      if (s[0] == '\015' && s[1] == '\012') s++;  /* already CRLF */
      *(p++) = '\015'; *(p++) = '\012';
    }
  }
  *(p++) = '\0';

  /* Shrink the buffer back to actual size (not very likely to fail) */

  return (char*)OPENSSL_realloc(d, (p-d));
err:
  return NULL;
}

/* EOF  -  smimemime.c */
