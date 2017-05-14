/* smime-vfy.c  -  Utility functions for performing S/MIME signature
 *                 verification and decryption.
 *
 * Copyright (c) 1999 Sampo Kellomaki <sampo@iki.fi>, All Rights Reserved.
 * License: This software may be distributed under the same license
 *          terms as openssl (i.e. free, but mandatory attribution).
 *          See file LICENSE for details.
 *
 * 11.9.1999,  Created. --Sampo
 * 13.9.1999,  0.1 released. Now adding verify. --Sampo
 * 1.10.1999,  improved error handling, fixed decrypt --Sampo
 * 6.10.1999,  separated from smimeutil.c --Sampo
 * 9.10.1999,  fixed double free in decryption --Sampo
 * 14.11.1999, added verification of detached sigs, i.e. clear sigs --Sampo
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

#include <stdlib.h>
#include <string.h>
#include <time.h>

#if defined(macintosh) || defined(__INTEL__)
#include "macglue.h"
#endif

#include "logprint.h"

#include <openssl/crypto.h>
#include <openssl/buffer.h>
#include <openssl/stack.h>
#include <openssl/bio.h>
#include <openssl/x509.h>
#include <openssl/pem.h>
#include <openssl/err.h>

#define SMIME_INTERNALS  /* we want also our internal helper functions */
#include "smimeutil.h"

/* ============= S I G N A T U R E   V E R I F I C A T I O N ============== */
/* ==================== A N D   D E C R Y P T I O N ======================= */

/* Called by:  decrypt, smime_get_signer_info, smime_verify_signature */
static PKCS7*
get_pkcs7_from_pem(const char* enc_entity)
{
  const char* p;
  char*  wrapped_enc_entity = NULL;
  BIO*   rbio = NULL;
  PKCS7* p7 = NULL;
 
  /* Check if encrypted entity is composed of raw data or if it has some
   * headers. In the latter case, just skip the headers. Headers are
   * separated from data by an empty line (hence sequence CRLF CRLF).*/
  
  if ((p = strstr(enc_entity, CRLF CRLF))) {
    enc_entity = p+4;
  } else if ((p = strstr(enc_entity, LF LF))) {
    enc_entity = p+2;
  } else if ((p = strstr(enc_entity, CR CR))) {
    enc_entity = p+2;
  }
  
  /* Make sure the pem markers are there */
  
  LOG_PRINT("get_pkcs7_from_pem: wrapping in pem markers");

  if (!(wrapped_enc_entity = wrap_in_pem_markers(enc_entity, "PKCS7")))
    GOTO_ERR("no memory?");
  LOG_PRINT("get_pkcs7_from_pem: wrapped.");
  
  /* Set up BIO so encrypted/signed data can be read from pem file */
  
  if (!(rbio = set_read_BIO_from_buf(wrapped_enc_entity, -1))) goto err;
  
  LOG_PRINT("get_pkcs7_from_pem: ready to read PKCS7 bio...");

  /* Load the PKCS7 object from a pem file to internal representation.
   * this reads all of the data file. */
  
  if (!(p7=PEM_read_bio_PKCS7(rbio,NULL/*&x*/,NULL/*callback*/,NULL/*arg*/)))
    GOTO_ERR("11 corrupt PEM PKCS7 file? (PEM_read_bio_PKCS7)");

  LOG_PRINT("get_pkcs7_from_pem: bio read");

  BIO_free_all(rbio);
  OPENSSL_free(wrapped_enc_entity);
  return p7;
err:
  if (rbio) BIO_free_all(rbio);
  if (wrapped_enc_entity) OPENSSL_free(wrapped_enc_entity);
  return NULL;
}

/* Typically receiver has to know in what order the signature and encryption
 * were applied (usually encryption is outermost) and then call these
 * functions in right order, e.g:
 */

/* Called by:  smime_decrypt */
int  /* return size of data, -1 on failure */
decrypt(X509* x509, EVP_PKEY* pkey, const char* enc_entity, char** data_out)
{
  char buf[4096];
  int  i,n;
  BIO* wbio = NULL;
  BIO* p7bio = NULL;
  PKCS7 *p7 = NULL;

  if (data_out) *data_out = NULL;
  if (!x509 || !pkey || !enc_entity || !data_out) GOTO_ERR("NULL arg(s)");
  LOG_PRINT("decrypt: get_pkcs7_from_pem");
  if (!(p7 = get_pkcs7_from_pem(enc_entity))) goto err;
  
  /* Decrypt the symmetric key with private key and obtain symmetric
   * cipher stream (BIO). The cert is needed here to look up one of
   * possibly multiple recipient infos present in PKCS7 object. Issuer
   * and serial number must match (these two fields form unique ID for
   * cert). Actual public key part of the X509 cert is not used for
   * anything here.  */

  LOG_PRINT("decrypt: dataDecode");
  if (!(p7bio=PKCS7_dataDecode(p7,pkey,NULL/*detached*/,x509)))
    GOTO_ERR("12 no recipient matches cert or private key could not decrypt, i.e. wrong key (PKCS7_dataDecode)");
  LOG_PRINT("decrypt: ready to pump");

  /* Pump data from p7bio to decrypt symmetric cipher */
  
  if (!(wbio = BIO_new(BIO_s_mem()))) GOTO_ERR("no memory?");

  for (;;) {
    if ((i=BIO_read(p7bio,buf,sizeof(buf))) <= 0) break;
    BIO_write(wbio,buf,i);
  }  
  BIO_flush(wbio);
  BIO_free_all(p7bio);
  p7bio = NULL;
  PKCS7_free(p7);
  p7 = NULL;

  LOG_PRINT("decrypt: pump done");

  /* Return data (this should now be easier because we just freed
   * some memory) */

  n = get_written_BIO_data(wbio, data_out);
  BIO_free_all(wbio);
  return n;  
  
err:  
  if (p7)    PKCS7_free(p7);
  if (wbio)  BIO_free_all(wbio);
  if (p7bio) BIO_free_all(p7bio);
  return -1;
}

/* Called by:  main */
int  /* return size of data, -1 on failure */
smime_decrypt(const char* privkey,
	      const char* passwd,
	      const char* enc_entity,
	      char** data_out)
{
  int  n = -1;
  EVP_PKEY *pkey = NULL;
  X509  *x509 = NULL;
  
  if (data_out) *data_out = NULL;
  if (!privkey || !passwd || !enc_entity || !data_out) GOTO_ERR("NULL arg(s)");
  if (!(pkey = open_private_key(privkey, passwd))) goto err;
  if (!(x509 = extract_certificate(privkey)))      goto err;
  n = decrypt(x509, pkey, enc_entity, data_out);
    
err:  
  if (pkey)  EVP_PKEY_free(pkey);
  if (x509)  X509_free(x509);
  return n;
}

/* ------------------------------------------------ */

#if 0
/* copied from verify.c */
/* should be X509* but we can just have them as char*. (??? --Sampo) */
/* Called by: */
static int
verify_callback(int ok, X509_STORE_CTX *ctx) {
  char buf[256];
  X509 *err_cert;
  int err,depth;

  err_cert=X509_STORE_CTX_get_current_cert(ctx);
  err=	 X509_STORE_CTX_get_error(ctx);
  depth= X509_STORE_CTX_get_error_depth(ctx);

  X509_NAME_oneline(X509_get_subject_name(err_cert),buf,sizeof(buf));
  fprintf(stderr,"depth=%d %s\n",depth,buf);
  if (!ok) {
    fprintf(stderr,"verify error:num=%d:%s\n",err,
	    X509_verify_cert_error_string(err));
    if (depth < 6) {
      ok=1;
      X509_STORE_CTX_set_error(ctx,X509_V_OK);
    } else {
      ok=0;
      X509_STORE_CTX_set_error(ctx,X509_V_ERR_CERT_CHAIN_TOO_LONG);
    }
  }
  switch (ctx->error) {
  case X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT:
    X509_NAME_oneline(X509_get_issuer_name(ctx->current_cert),buf,sizeof(buf));
    fprintf(stderr,"issuer= %s\n",buf);
    break;
#if 1
  case X509_V_ERR_CERT_NOT_YET_VALID:
  case X509_V_ERR_ERROR_IN_CERT_NOT_BEFORE_FIELD:
    fprintf(stderr,"notBefore=");
    /*ASN1_UTCTIME_print(bio_err,X509_get_notBefore(ctx->current_cert));
      BIO_printf(bio_err,"\n");*/
    break;
  case X509_V_ERR_CERT_HAS_EXPIRED:
  case X509_V_ERR_ERROR_IN_CERT_NOT_AFTER_FIELD:
    fprintf(stderr,"notAfter=");
    /*ASN1_UTCTIME_print(bio_err,X509_get_notAfter(ctx->current_cert));
      BIO_printf(bio_err,"\n"); */
    break;
#endif
  }
  fprintf(stderr,"verify return:%d\n",ok);
  return(ok);
}

static int signed_seq2string_nid= -1;
/* For this case, I will malloc the return strings */
/* Called by:  smime_verify_signature */
static int
get_signed_seq2string(PKCS7_SIGNER_INFO *si, char **str1, char **str2) {
#if 0
  ASN1_TYPE *so;
  if (signed_seq2string_nid == -1)
    signed_seq2string_nid=
      OBJ_create("1.9.9999","OID_example","Our example OID");
  /* To retrieve */
  so=PKCS7_get_signed_attribute(si,signed_seq2string_nid);
  if (so && (so->type == V_ASN1_SEQUENCE))
    {
      ASN1_CTX c;
      ASN1_STRING *s;
      long length;
      ASN1_OCTET_STRING *os1,*os2;
      
      s=so->value.sequence;
      c.p=ASN1_STRING_data(s);
      c.max=c.p+ASN1_STRING_length(s);
      if (!asn1_GetSequence(&c,&length)) GOTO_ERR("") err;
      /* Length is the length of the seqence */
      
      c.q=c.p;
      if ((os1=d2i_ASN1_OCTET_STRING(NULL,&c.p,c.slen)) == NULL) 
	GOTO_ERR("");
      c.slen-=(c.p-c.q);
      
      c.q=c.p;
      if ((os2=d2i_ASN1_OCTET_STRING(NULL,&c.p,c.slen)) == NULL) 
	GOTO_ERR("");
      c.slen-=(c.p-c.q);
      
      if (!asn1_Finish(&c)) GOTO_ERR("") err;
      *str1=Malloc(os1->length+1);
      *str2=Malloc(os2->length+1);
      memcpy(*str1,os1->data,os1->length);
      memcpy(*str2,os2->data,os2->length);
      (*str1)[os1->length]='\0';
      (*str2)[os2->length]='\0';
      ASN1_OCTET_STRING_free(os1);
      ASN1_OCTET_STRING_free(os2);
      return(1);
    }
 err:
#endif
  return(0);
}
#endif

/* Called by:  main */
long  /* return serial on success, -1 on failure */
smime_get_signer_info(const char* signed_entity,
		      int info_ix,     /* 0 = first signer */
		      char** issuer)   /* DN of the issuer */
{
  int serial = -1;
  PKCS7* p7 = NULL;
  STACK_OF(PKCS7_SIGNER_INFO)* sigs = NULL;
  PKCS7_SIGNER_INFO* si;
  
  if (!signed_entity || !issuer) GOTO_ERR("NULL arg(s)");
  *issuer = NULL;
  
  if (!(p7 = get_pkcs7_from_pem(signed_entity))) goto err;
  if (!(sigs=PKCS7_get_signer_info(p7)))
    GOTO_ERR("13 no sigs? (PKCS7_get_signer_info)");

  if (info_ix >= sk_PKCS7_SIGNER_INFO_num(sigs))
    GOTO_ERR("No more signers. info_ix too large.");

  if (!(si=sk_PKCS7_SIGNER_INFO_value(sigs,info_ix)))
    GOTO_ERR("NULL signer info");
  
  *issuer = X509_NAME_oneline(si->issuer_and_serial->issuer, NULL,0);
  serial = ASN1_INTEGER_get(si->issuer_and_serial->serial);
  
err:
  if (p7) PKCS7_free(p7);
  return serial;
}

/* Called by:  main x3 */
char* /* returns contents of the signed message, NULL if error */
smime_verify_signature(const char* pubkey,
		       const char* sig_entity,     /* signed entity
						      or just the sigature */
		       const char* detached_data,  /* possibly NULL */
		       int detached_data_len)
{
  X509*  x509 = NULL;
  PKCS7* p7 = NULL;
  STACK_OF(PKCS7_SIGNER_INFO)* sigs = NULL;
  X509_STORE* certs=NULL;
  BIO*   detached = NULL;
  BIO*   p7bio = NULL;
  BIO*   wbio = NULL;
  char*  data = NULL;
  char   buf[4096];
  int    i,x;
  
  if (!sig_entity || !pubkey) GOTO_ERR("NULL arg(s)");
  if (!(p7 = get_pkcs7_from_pem(sig_entity))) goto err;

  /* Hmm, if its clear signed, we already provided the detached sig, but
   * if its one sig blob, may be PKCS7_get_detached() provides BIO connected
   * to the detached part. Go figure.
   */

  if (detached_data && detached_data_len) {
    if (!(detached = set_read_BIO_from_buf(detached_data, detached_data_len)))
      goto err;
  } else {
    if (!PKCS7_get_detached(p7))
      GOTO_ERR("15 cant extract signed data from signed entity (PKCS7_get_detached)");
  }
  if (!(p7bio=PKCS7_dataInit(p7,detached))) GOTO_ERR("PKCS7_dataInit");
  
  if (!(wbio = BIO_new(BIO_s_mem()))) GOTO_ERR("no memory?");
  
  /* We now have to 'read' from p7bio to calculate message digest(s).
   * I also take the opportunity to save the signed data. */
  for (;;) {
    i = BIO_read(p7bio,buf,sizeof(buf));
    if (i <= 0) break;
    BIO_write(wbio, buf, i);
  }
  
  if (get_written_BIO_data(wbio, &data)==-1) goto err;
  BIO_free_all(wbio);
  wbio = NULL;
  
  /* We can now verify signatures */
  if (!(sigs=PKCS7_get_signer_info(p7)))
    GOTO_ERR("13 no sigs? (PKCS7_get_signer_info)");
  
  /* Ok, first we need to, for each subject entry, see if we can verify */
  for (i=0; i<sk_PKCS7_SIGNER_INFO_num(sigs); i++) {
    PKCS7_SIGNER_INFO *si;
    
    si=sk_PKCS7_SIGNER_INFO_value(sigs,i);
    
    /* The bio is needed here only to lookup the message digest context
     * which presumably now contains the message digest. It will not be
     * read, and hence its good for any number of iterations. This is so
     * because MD bios pass the data right thru so they can be stacked
     * to calculate multiple message digests simultaneously. Clever, eh?
     */

#if 0
    /* *** this is currently broken and thus disabled. --Sampo */
    /* verifies by looking up the certificate from certs database,
     * verifying the validity of the certificate, and finally
     * validity of the signature */

    X509_STORE_CTX cert_ctx;
    x=PKCS7_dataVerify(certs, &cert_ctx, p7bio, p7, si);
#else
    /* just verify the signature, given that we already have certificate
     * candidate (see crypto/pk7_doit.c around line 675) */

    if (!(x509 = extract_certificate(pubkey))) goto err;
    x=PKCS7_signatureVerify(p7bio, p7, si, x509);
#endif
    if (x <= 0) GOTO_ERR("14 sig verify failed");
    
#if 0
    ASN1_UTCTIME *tm;
    if ((tm=get_signed_time(si)) != NULL) {
      //fprintf(stderr,"Signed time:");
      //ASN1_UTCTIME_print(bio_out,tm);
      ASN1_UTCTIME_free(tm);
      //BIO_printf(bio_out,"\n");
    }
#endif
#if 0
    char *str1,*str2;
    if (get_signed_seq2string(si,&str1,&str2)) {
      fprintf(stderr,"String 1 is %s\n",str1);
      fprintf(stderr,"String 2 is %s\n",str2);
    }
#endif
  }
  
  BIO_free_all(p7bio);
  PKCS7_free(p7);
  X509_STORE_free(certs);
  return data;    /* return the signed plain text */

err:
  if (wbio) BIO_free_all(wbio);
  if (p7bio) BIO_free_all(p7bio);
  if (p7) PKCS7_free(p7);
  if (certs) X509_STORE_free(certs);
  if (data) OPENSSL_free(data);
  return NULL;
}

/* =========== C E R T   V E R I F I C A T I O N =========== */

/* Called by:  smime_verify_cert */
int  /* returns -1 if error, 0 if verfy fail, and 1 if verify OK */
verify_cert(X509* ca_cert, X509* cert)
{
  EVP_PKEY* pkey = NULL;
  if (!ca_cert || !cert) GOTO_ERR("NULL arg(s)");
  if (!(pkey=X509_get_pubkey(ca_cert))) GOTO_ERR("no memory?");
  return X509_verify(cert, pkey);
err:
  return -1;
}

/* Called by:  main */
int  /* returns -1 if error, 0 if verfy fail, and 1 if verify OK */
smime_verify_cert(const char* ca_cert_pem, const char* cert_pem)
{
  X509* ca_cert = NULL;
  X509* cert = NULL;
  int ret = -1;
  if (!ca_cert_pem || !cert_pem) GOTO_ERR("NULL arg(s)");
  if (!(ca_cert = extract_certificate(ca_cert_pem))) goto err;
  if (!(cert = extract_certificate(cert_pem))) goto err;
  ret = verify_cert(ca_cert, cert);
err:
  if (ca_cert) X509_free(ca_cert);
  if (cert) X509_free(cert);
  return ret;
}

/* EOF  -  smime-vfy.c */
