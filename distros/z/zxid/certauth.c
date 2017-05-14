/* certauth.c  -  Certification authority functions
 *
 * Copyright (c) 1999 Sampo Kellomaki <sampo@iki.fi>, All Rights Reserved.
 * License: This software may be distributed under the same license
 *          terms as openssl (i.e. free, but mandatory attribution).
 *
 * This borrows quite heavily ideas and control flow from openssl/apps/ca.c
 * by Eric A. Young. You could say this file is destillation of Eric's
 * work with many of the parameters hard wired
 *
 * 25.10.1999, Created. --Sampo
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

#ifdef __MWERKS__
# include "macglue.h"
#endif

#include "logprint.h"

#include <openssl/crypto.h>
#include <openssl/buffer.h>
#include <openssl/err.h>
#include <openssl/rand.h>
#include <openssl/conf.h>
#include <openssl/bio.h>
#include <openssl/objects.h>
#include <openssl/asn1.h>
#include <openssl/pem.h>
#include <openssl/evp.h>
#include <openssl/x509.h>
#include <openssl/x509v3.h>
#include <openssl/pkcs12.h>

#define SMIME_INTERNALS  /* we want also our internal helper functions */
#include "smimeutil.h"

/* Adds some of the most commonly wanted extensions
 *
 * Examples:
 *   basic_constraints: CA:TRUE,pathlen:3
 *   cert_type: client,server,email,objsign,sslCA,emailCA,objCA
 *   key_usage: digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment,keyAgreement,keyCertSign,cRLSign
 *   comment: dont trust me ;-)
 */

/* Called by:  certification_authority, keygen */
int
add_some_X509v3_extensions(X509* cert,
			   const char* basic_constraints,
			   const char* cert_type,
			   const char* key_usage,
			   const char* comment)
{
  X509_EXTENSION* ext;
  
  if (!cert) GOTO_ERR("NULL arg");
  
  if (basic_constraints) {
    if (!(ext = X509V3_EXT_conf_nid(NULL, NULL, NID_basic_constraints,
				    (char*)basic_constraints)))
      GOTO_ERR("X509V3_EXT_conf_nid");
    X509_add_ext(cert, ext, -1);
  }
  
  if (cert_type) {
    if (!(ext = X509V3_EXT_conf_nid(NULL, NULL, NID_netscape_cert_type,
				    (char*)cert_type)))
      GOTO_ERR("X509V3_EXT_conf_nid");
    X509_add_ext(cert, ext, -1);
  }
  
  if (key_usage) {
    if (!(ext = X509V3_EXT_conf_nid(NULL, NULL, NID_key_usage,
				    (char*)key_usage)))
      GOTO_ERR("X509V3_EXT_conf_nid");
    X509_add_ext(cert, ext, -1);
  }
  
  if (comment) {
    if (!(ext = X509V3_EXT_conf_nid(NULL, NULL, NID_netscape_comment,
				    (char*)comment)))
      GOTO_ERR("X509V3_EXT_conf_nid");
    X509_add_ext(cert, ext, -1);
  }
  return 0;
err:
  return -1;
}

/* Perform certificate construction and signing functionality of
 * a CA. Note that there is much more to it than that: you need
 * to ensure uniqueness of serial numbers, you need to keep database
 * of issued certificates, you need to enforce your policy wrt DNs, etc.
 * Last four args correspond to x509v3 extensions. If you pass NULL
 * the extension will not be included. Examples:
 *
 *   basic_constraints: CA:TRUE,pathlen:3
 *   cert_type: client,server,email,objsign,sslCA,emailCA,objCA
 *   key_usage: digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment,keyAgreement,keyCertSign,cRLSign
 *   comment: dont trust me ;-)
 *
 * Start date is either "today" or xxx
 * End date is either "days:123" or xxx
 */

/* Called by:  smime_ca */
X509*  /* returns signed certificate, or NULL if error */
certification_authority(X509* ca_cert,
			EVP_PKEY* ca_pkey,
			X509_REQ* req,
			const char* start_date,  /* today or yymmddhhmmss */
			const char* end_date, /* days:123 or yymmddhhmmss */
			long serial,
			const char* basic_constraints,
			const char* cert_type,
			const char* key_usage,
			const char* comment)
{
  X509* cert = NULL;  /* This will be the new born certificate! */
  X509_NAME* name = NULL;
  EVP_PKEY* req_pkey = NULL;
  int days;
  
  if (!ca_cert || !ca_pkey || !req || !start_date || !end_date)
    GOTO_ERR("NULL arg(s)");
  X509V3_add_standard_extensions();
  
  /* alloc */
  
  if (!(cert = X509_new())) GOTO_ERR("no memory?");

  if (basic_constraints || cert_type || key_usage || comment) {
    if (!X509_set_version(cert,2)) GOTO_ERR("cant set cert version 3");
  }
  
  /* set names */

  if (!ASN1_INTEGER_set(cert->cert_info->serialNumber, serial))
    GOTO_ERR("cant set serial number");
  if (!(name = X509_get_subject_name(ca_cert)))
    GOTO_ERR("cant get issuer name");
  if (!X509_set_issuer_name(cert,name)) GOTO_ERR("cant set issuer name");
  
  if (!(name = X509_REQ_get_subject_name(req)))
    GOTO_ERR("cant get request subject name");
  if (!X509_set_subject_name(cert,name)) GOTO_ERR("cant set subject name");

  /* set dates */
  
  if (strcmp(start_date,"today") == 0)
    X509_gmtime_adj(X509_get_notBefore(cert),0);
  else
    ASN1_UTCTIME_set_string(X509_get_notBefore(cert),(char*)start_date);

  if (!memcmp(end_date, "days:", 5)) {
    days = atoi(end_date + 5);
    X509_gmtime_adj(X509_get_notAfter(cert),(long)60*60*24*days);
  } else
    ASN1_UTCTIME_set_string(X509_get_notAfter(cert),(char*)end_date);

  /* Copy the public key from the request */
  
  if (!(req_pkey=X509_REQ_get_pubkey(req)))
    GOTO_ERR("cant get public key from request");
  if (!X509_set_pubkey(cert, req_pkey)) GOTO_ERR("cant set public key");
  EVP_PKEY_free(req_pkey);
  req_pkey = NULL;

  /* Set extensions */
  
  if (add_some_X509v3_extensions(cert,basic_constraints, cert_type,
				 key_usage, comment)==-1) goto err;
  
  /* Sign it into a certificate */
  
  LOG_PRINT("ca signing x509");
#if 0
  if (!(X509_sign(cert, ca_pkey, EVP_md5()))) GOTO_ERR("X509_sign");
#else
  if (!(X509_sign(cert, ca_pkey, EVP_sha256()))) GOTO_ERR("X509_sign");
#endif

  X509V3_EXT_cleanup();
  OBJ_cleanup();
  return cert;

err:
  X509V3_EXT_cleanup();
  OBJ_cleanup();
  if (req_pkey) EVP_PKEY_free(req_pkey);
  if (cert) X509_free(cert);
  return NULL;
}

/* Called by:  main */
char*  /* returns pem encoded certificate, or NULL if error */
smime_ca(const char* ca_id_pem,
	 const char* passwd,
	 const char* req_pem,
	 const char* start_date,
	 const char* end_date,
	 long serial,
	 const char* basic_constraints,
	 const char* cert_type,
	 const char* key_usage,
	 const char* comment)
{
  X509* ca_cert = NULL;
  X509* new_cert = NULL;
  X509_REQ* req = NULL;
  EVP_PKEY* ca_pkey = NULL;
  char* ret = NULL;
  
  if (!ca_id_pem || !passwd || !req_pem) GOTO_ERR("NULL arg(s)");

  if (!(ca_pkey = open_private_key(ca_id_pem, passwd))) goto err;
  if (!(ca_cert = extract_certificate(ca_id_pem))) goto err;
  if (!(req = extract_request(req_pem))) goto err;
  
  if (!(new_cert = certification_authority(ca_cert, ca_pkey, req,
					   start_date, end_date, serial,
					   basic_constraints, cert_type,
					   key_usage, comment))) goto err;
  write_certificate(new_cert, &ret);
  
err:
  if (ca_cert)  X509_free(ca_cert);
  if (req)      X509_REQ_free(req);
  if (ca_pkey)  EVP_PKEY_free(ca_pkey);
  if (new_cert) X509_free(new_cert);
  return ret;
}

/* EOF  -  certauth.c */
