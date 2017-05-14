/* smime-enc.c  -  Utility functions for performing S/MIME signatures
 *                 and encryption.
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
 * 9.10.1999, reviewed for free problems --Sampo
 *
 * This module has adopted ideas and control flow from
 *    openssl-0.9.4/crypto/pkcs7/sign.c
 *    openssl-0.9.4/crypto/pkcs7/verify.c
 *    openssl-0.9.4/crypto/pkcs7/enc.c
 *    openssl-0.9.4/crypto/pkcs7/dec.c
 * which are Copyright (c) 1995-1998 Eric Young (eay@cryptsoft.com),
 * All rights reserved. See file LICENSE for conditions.
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

/* Copyright (C) 1995-1998 Eric Young (eay@cryptsoft.com)
 * All rights reserved.
 *
 * This package is an SSL implementation written
 * by Eric Young (eay@cryptsoft.com).
 * The implementation was written so as to conform with Netscapes SSL.
 * 
 * This library is free for commercial and non-commercial use as long as
 * the following conditions are aheared to.  The following conditions
 * apply to all code found in this distribution, be it the RC4, RSA,
 * lhash, DES, etc., code; not just the SSL code.  The SSL documentation
 * included with this distribution is covered by the same copyright terms
 * except that the holder is Tim Hudson (tjh@cryptsoft.com).
 * 
 * Copyright remains Eric Young's, and as such any Copyright notices in
 * the code are not to be removed.
 * If this package is used in a product, Eric Young should be given attribution
 * as the author of the parts of the library used.
 * This can be in the form of a textual message at program startup or
 * in documentation (online or textual) provided with the package.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *    "This product includes cryptographic software written by
 *     Eric Young (eay@cryptsoft.com)"
 *    The word 'cryptographic' can be left out if the rouines from the library
 *    being used are not cryptographic related :-).
 * 4. If you include any Windows specific code (or a derivative thereof) from 
 *   the apps directory (application code) you must include an acknowledgement:
 *   "This product includes software written by Tim Hudson (tjh@cryptsoft.com)"
 * 
 * THIS SOFTWARE IS PROVIDED BY ERIC YOUNG ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 * 
 * The licence and distribution terms for any publically available version or
 * derivative of this code cannot be changed.  i.e. this code cannot simply be
 * copied and put under another distribution licence
 * [including the GNU Public Licence.]
 */

#include "platform.h"

#include <stdio.h>
#include <string.h>
#include <time.h>

#if defined(macintosh) || defined(__INTEL__)
#include "macglue.h"
#endif

#include "logprint.h"

#include <openssl/buffer.h>
#include <openssl/bio.h>
#include <openssl/x509.h>
#include <openssl/pem.h>
#include <openssl/err.h>
#include <openssl/rand.h>

#define SMIME_INTERNALS  /* we want also our internal helper functions */
#include "smimeutil.h"

/* ============= S I G N I N G   &   E N C R Y P T I O N ============= */

/* Typically signing and encryption involves a sequence of calls like
 *
 *  msg = smime_encrypt(pubkey,
 *           smime_clear_sign(privkey, password,
 *              mime_mk_multipart(text, file1, len1, type1, name1,
 *                                      NULL,  0,    NULL,  NULL,
 *                                      NULL,  0,    NULL,  NULL)));
 */

/* Helper function for signing and signature verification. */

/* Called by:  clear_sign, sign */
static BIO*
smime_sign_engine(X509* x509, EVP_PKEY* pkey,
		  const char* mime_entity, int detach)
{
  int i;
  char buf[4096];
  BIO*  p7bio = NULL;
  BIO*  bio = NULL;
  PKCS7* p7 = NULL;
  PKCS7_SIGNER_INFO* si;

  /* Set up BIOs and PKCS7 machinery */

  LOG_PRINT3("sig engine %x %x", x509, pkey);  
  LOG_PRINT3("           %x %d", mime_entity, detach);
  if (!x509 || !pkey || !mime_entity) GOTO_ERR("NULL arg(s)");
  if (!(bio = set_read_BIO_from_buf(mime_entity, -1))) goto err;
  LOG_PRINT("PKCS7_new");
  /*Log_malloc = Log;*/
  if (!(p7=PKCS7_new())) GOTO_ERR("no memory?");
  LOG_PRINT("PKCS7_set_type");
  PKCS7_set_type(p7,NID_pkcs7_signed);
  /*Log_malloc = NULL;*/
  LOG_PRINT("Adding sig");
  if (!(si=PKCS7_add_signature(p7,x509,pkey,EVP_sha1())))
    GOTO_ERR("PKCS7_add_signature");
  
  LOG_PRINT("Adding signed attribute");
  /* If you do this then you get signing time automatically added */
  PKCS7_add_signed_attribute(si, NID_pkcs9_contentType, V_ASN1_OBJECT,
                             OBJ_nid2obj(NID_pkcs7_data));
  /*PKCS7_add_certificate(p7,x509);*/
  if (detach) PKCS7_set_detached(p7,1);
  
  /* Set the content of the signed to 'data' */
  PKCS7_content_new(p7,NID_pkcs7_data);
  
  if (!(p7bio=PKCS7_dataInit(p7,NULL))) GOTO_ERR("PKCS7_dataInit");
  
  /* pump data from file to special PKCS7 BIO. This hashes it. */

  LOG_PRINT("pumping");
  
  for (;;)    {
    i=BIO_read(bio,buf,sizeof(buf));
    if (i <= 0) break;
    BIO_write(p7bio,buf,i);
  }
  BIO_flush(p7bio);
  
  LOG_PRINT("data final...");
  if (!PKCS7_dataFinal(p7,p7bio)) GOTO_ERR("PKCS7_dataFinal");
  BIO_free_all(p7bio);
  p7bio = NULL;
  BIO_free_all(bio);
  
  if (!(bio = BIO_new(BIO_s_mem()))) GOTO_ERR("no memory?");
  LOG_PRINT("Writing data to bio");
  PEM_write_bio_PKCS7(bio,p7);
  BIO_flush(bio);
  PKCS7_free(p7);
  
  LOG_PRINT2("sig engine done %x", bio);
  return bio;  /* return written memory bio (must be freed by caller)
		* caller will extract the data from buffer. */

err:
  if (p7bio) BIO_free_all(p7bio);
  if (p7)    PKCS7_free(p7);
  if (bio)   BIO_free_all(bio);
  LOG_PRINT("sig engine error");
  return NULL;
}

/* Sign a mime entity, such as produced by mime_mk_multipart(). Signature
 * is stored as separate mime entity so the message proper stays visible.
 * I canonicalize the entity (LF->CRLF) because correct signature
 * verification depends on this.
 */

/*
MIME-Version: 1.0
Content-Type: multipart/signed; protocol="application/x-pkcs7-signature"; micalg
=sha1; boundary=sig42

--sig42
Content-Type: text/plain

message to be signed
--sig42
Content-Type: application/x-pkcs7-signature; name="smime.p7s"
Content-Transfer-Encoding: base64
Content-Disposition: attachment; filename="smime.p7s"
Content-Description: S/MIME Clear Signed Message

MIAGCSqGSIb3DQEHA6CAMIIIZQIBADGCATcwggEzAgEAMIGbMIGVMQswCQYDVQQG
EwJQVDEPMA0GA1UEBxMGTGlzYm9hMRcwFQYDVQQKEw5OZXVyb25pbywgTGRhLjEZ
G0DXAj0zd/4AAAAA==
--sig42--
*/

/* Called by:  smime_clear_sign */
char*  /* returns smime encoded clear signed blob, or NULL if error */
clear_sign(X509* x509, EVP_PKEY* pkey, const char* mime_entity)
{
  char* b;
  char* b64;
  BIO*  wbio = 0;
  int   n;
  
  LOG_PRINT("clear sig, canon entity...");
  if (!(mime_entity = mime_canon(mime_entity))) goto err;
  LOG_PRINT("clear sig, entity canoned. Now sig engine");
  
  /* Run crypto stuff over the mime_entity */
  
  if (!(wbio = smime_sign_engine(x509, pkey, mime_entity, 1))) goto err;
  LOG_PRINT("clear sig: signed, now get data");
  n = BIO_get_mem_data(wbio,&b64);
  LOG_PRINT("clear sig: cut pem markers...");
  if (!(b64 = cut_pem_markers_off(b64, n, "PKCS7"))) goto err;
  
  /* Wrap up the result in multipart/signed object */
  
  if (!(b = smime_mk_multipart_signed(mime_entity, b64))) goto err;
  
  LOG_PRINT("clear sig: done. free bio");
  BIO_free_all(wbio);  /* this will also free b64 because b64 hangs from bio */
  return b;

err:
  if (wbio) BIO_free_all(wbio);
  return NULL;
}

/* Called by:  main x2 */
char*
smime_clear_sign(const char* privkey,
		 const char* password,
		 const char* mime_entity)
{
  char* b = NULL;
  X509* x509 = NULL;
  EVP_PKEY* pkey = NULL;

  /* Get key and certificate (why do we need both?) */
  
  if (!(pkey = open_private_key(privkey, password))) goto err;
  if (!(x509 = extract_certificate(privkey))) goto err;
  if (!(b = clear_sign(x509, pkey, mime_entity))) goto err;

err:
  if (pkey)  EVP_PKEY_free(pkey);
  if (x509)  X509_free(x509);
  return b;
}

/* Sign a mime entity, such as produced by mime_mk_multipart(). Signature
 * and entity are output as one base64 blob so the entity is not trivially
 * visible. */

/*
MIME-Version: 1.0
Content-Type: application/x-pkcs7-mime; smime-type=signed-data; name="smime.p7m"
Content-Transfer-Encoding: base64
Content-Disposition: attachment; filename="smime.p7m"
Content-Description: S/MIME Signed Message

MIAGCSqGSIb3DQEHA6CAMIIIZQIBADGCATcwggEzAgEAMIGbMIGVMQswCQYDVQQG
EwJQVDEPMA0GA1UEBxMGTGlzYm9hMRcwFQYDVQQKEw5OZXVyb25pbywgTGRhLjEZ
G0DXAj0zd/4AAAAA==
 */

/* Called by:  smime_sign */
char*  /* returns smime blob, NULL if error */
sign(X509* x509, EVP_PKEY* pkey, const char* mime_entity)
{
  char* b;
  char* b64;
  BIO*  wbio;
  int   n;

  mime_entity = mime_canon(mime_entity);
  
  /* Run crypto stuff over the mime_entity */
  
  if (!(wbio = smime_sign_engine(x509, pkey, mime_entity, 0))) goto err;
  n = BIO_get_mem_data(wbio,&b64);
  if (!(b64 = cut_pem_markers_off(b64, n, "PKCS7"))) goto err;

  /* Add headers */

  if (!(b = strdup("Content-type: application/x-pkcs7-mime; name=\"smime.p7m\"" CRLF
		   "Content-transfer-encoding: base64" CRLF
		   "Content-Disposition: attachment; filename=\"smime.p7m\"" CRLF
		   CRLF))) GOTO_ERR("no memory?");
  if (!(b = concat(b, b64))) GOTO_ERR("no memory?");
  
  BIO_free_all(wbio);  /* also frees b64 */
  return b;
  
err:
  if (wbio) BIO_free_all(wbio);
  return NULL;
}

/* Called by:  main */
char*
smime_sign(const char* privkey, const char* password, const char* mime_entity)
{
  char* b = NULL;
  X509* x509 = NULL;
  EVP_PKEY* pkey = NULL;

  /* Get key and certificate (why do we need both?) */
  
  if (!(pkey = open_private_key(privkey, password))) goto err;
  if (!(x509 = extract_certificate(privkey))) goto err;
  if (!(b = sign(x509, pkey, mime_entity))) goto err;

err:
  if (pkey)  EVP_PKEY_free(pkey);
  if (x509)  X509_free(x509);
  return b;
}

/* Encrypt a mime entity such as produced by smime_clear_sign(). */

/*
MIME-Version: 1.0
Content-Type: application/x-pkcs7-mime; name="smime.p7m"
Content-Transfer-Encoding: base64
Content-Disposition: attachment; filename="smime.p7m"
Content-Description: S/MIME Encrypted Message

MIAGCSqGSIb3DQEHA6CAMIIIZQIBADGCATcwggEzAgEAMIGbMIGVMQswCQYDVQQG
EwJQVDEPMA0GA1UEBxMGTGlzYm9hMRcwFQYDVQQKEw5OZXVyb25pbywgTGRhLjEZ
G0DXAj0zd/4AAAAA==
 */

/* Called by:  smime_encrypt */
char*
encrypt1(X509* x509, const char* mime_entity)
{
  time_t t;
  char* b;
  char* b64;
  int   i, n;
  char  buf[4096];
  BIO*  p7bio = NULL;
  BIO*  rbio = NULL;
  BIO*  wbio = NULL;
  PKCS7* p7 = NULL;;
  
  t = time(NULL);
  RAND_seed(&t,sizeof(t));
#ifdef WINDOWS
  RAND_screen(); /* Loading video display memory into random state */
#endif

  LOG_PRINT3("encrypt1", x509, mime_entity);

  /* Set up BIOs and PKCS7 machinery */
  
  if (!(rbio = set_read_BIO_from_buf(mime_entity, -1))) goto err;
  
  if (!(p7=PKCS7_new())) GOTO_ERR("no memory?");
  PKCS7_set_type(p7,NID_pkcs7_enveloped);

#if 1
  if (!PKCS7_set_cipher(p7,EVP_des_ede3_cbc()))
    GOTO_ERR("PKCS7_set_cipher des-ede3-cbc");
#else
  /* SECURITY CAVEAT: weak cipher by default */
  if (!PKCS7_set_cipher(p7,EVP_rc2_40_cbc()))
    GOTO_ERR("PKCS7_set_cipher rc2-40-cbc");
#endif

  LOG_PRINT("encrypt1: add recipient");

  if (!PKCS7_add_recipient(p7,x509)) GOTO_ERR("PKCS7_add_recipient");
  
  LOG_PRINT("encrypt1: data init");
  if (!(p7bio=PKCS7_dataInit(p7,NULL))) GOTO_ERR("PKCS7_dataInit");
  
  /* pump data from file to special PKCS7 BIO. This encrypts it. */
  
  LOG_PRINT("encrypt1: pump");
  for (;;)    {
    i=BIO_read(rbio,buf,sizeof(buf));
    if (i <= 0) break;
    BIO_write(p7bio,buf,i);
  }
  BIO_flush(p7bio);
  
  LOG_PRINT("encrypt1: dataFinal");
  if (!PKCS7_dataFinal(p7,p7bio)) GOTO_ERR("PKCS7_dataFinal");
  BIO_free_all(rbio);
  BIO_free_all(p7bio);
  rbio = p7bio = NULL;

  if (!(wbio = BIO_new(BIO_s_mem()))) GOTO_ERR("no memory?");
  LOG_PRINT("encrypt1: write bio");
  PEM_write_bio_PKCS7(wbio,p7);
  BIO_flush(wbio);
  PKCS7_free(p7);
  p7 = NULL;
  
  LOG_PRINT("encrypt1: cutting markers");
  n = BIO_get_mem_data(wbio,&b64);
  b64 = cut_pem_markers_off(b64, n, "PKCS7");
  
  LOG_PRINT("encrypt1: wrapping in headers");
  if (!(b = strdup("Content-type: application/x-pkcs7-mime; name=\"smime.p7m\""
		   CRLF
		   "Content-transfer-encoding: base64" CRLF
		   "Content-Disposition: attachment; filename=\"smime.p7m\""
		   CRLF CRLF)))  GOTO_ERR("no memory?");
  if (!(b = concat(b, b64)))  GOTO_ERR("no memory?");
  
  BIO_free_all(wbio);  /* also frees b64 */
  LOG_PRINT("encrypt1: OK");

  t = time(NULL);
  RAND_seed(&t,sizeof(t));
  RAND_write_file(randomfile);

  return b; /* return value must be freed by caller */
  
err:
  if (rbio)  BIO_free_all(rbio);
  if (p7bio) BIO_free_all(p7bio);
  if (wbio)  BIO_free_all(wbio);
  if (p7)    PKCS7_free(p7);
  return NULL;
}

/* Called by:  main */
char*
smime_encrypt(const char* pubkey, const char* mime_entity)
{
  char* b = NULL;
  X509* x509;
  
  /* Get certificate */
  
  if (!(x509 = extract_certificate(pubkey))) goto err;
  b = encrypt1(x509, mime_entity);
  
err:
  //if (x509) X509_free(x509);
  return b; /* return value must be freed by caller */
}

/* ================= base64 encoding and decoding ================= */

/* Called by:  attach, main x2, mime_base64_entity */
int /* returns number of bytes in result. b64 is NULL terminated */
smime_base64(int encp /* true == encode */, const char* data, int len, char** out)
{
  BIO* b64bio;
  BIO* rbio = NULL;
  BIO* wbio = NULL;
  char buf[4096];
  int  n = -1;
  
  if (out) *out = NULL;
  if (!data || !out) GOTO_ERR("NULL arg");

  /* create two memory buffer BIOs */
  
  if (!(rbio = set_read_BIO_from_buf(data, len))) goto err;
  if (!(wbio = BIO_new(BIO_s_mem()))) GOTO_ERR("no memory?");
  
  /* insert base64 filter */
  
  if (!(b64bio=BIO_new(BIO_f_base64()))) GOTO_ERR("no memory?");
  if (encp)
    wbio=BIO_push(b64bio,wbio);
  else
    rbio=BIO_push(b64bio,rbio);

  /* pump stuff through filter */

  for (;;) {
    if ((n=BIO_read(rbio,buf,sizeof(buf))) <= 0) break;
    if (BIO_write(wbio, buf,n) != n) GOTO_ERR("no memory? (base64 pump)");
  }

  /* free BIOs and return base64 encoded block */
  
  n = get_written_BIO_data(wbio, out); /* if error (-1) will just propagate */

err:
  if (wbio) BIO_free_all(wbio);  /* b64bio is freed as part of the stack */
  if (rbio) BIO_free_all(rbio);
  return n;
}

/* EOF  -  smime-enc.c */
