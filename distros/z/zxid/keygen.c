/* keygen.c  -  Key generation utilities. See smime.c for user interface.
 *
 * Copyright (c) 1999 Sampo Kellomaki <sampo@iki.fi>, All Rights Reserved.
 * License: This software may be distributed under the same license
 *          terms as openssl (i.e. free, but mandatory attribution).
 *
 * This borrows quite heavily ideas and control flow from openssl/apps/req.c
 * by Eric A. Young. You could say this file is destillation of Eric's
 * work with many of the parameters hard wired:
 *
 *   - 1024 bit RSA only
 *   - 3DES for private key
 *   - MD5 hash
 *
 * 27.9.1999, Created. --Sampo
 * 30.9.1999, added PKCS12 stuff, --Sampo
 * 1.10.1999, improved error reporting, --Sampo
 * 6.10.1999, divided into keygen.c, pkcs12.c, and smime-qry.c --Sampo
 * 9.10.1999, reviewed for double frees, --Sampo
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
#include <openssl/stack.h>
#include <openssl/objects.h>
#include <openssl/asn1.h>
#include <openssl/pem.h>
#include <openssl/evp.h>
#include <openssl/x509.h>
#include <openssl/x509v3.h>
#include <openssl/pkcs12.h>

#define SMIME_INTERNALS  /* we want also our internal helper functions */
#include "smimeutil.h"

/* Enforce some rules about possible characters for different attributes */

static int req_fix_data(int nid, int *type /*IN-OUT*/)
{
  switch (nid) {
  case NID_pkcs9_emailAddress: *type=V_ASN1_IA5STRING; break;
  case NID_commonName:
  case NID_pkcs9_challengePassword:
    if (*type == V_ASN1_IA5STRING)
      *type=V_ASN1_T61STRING;
    break;
  case NID_pkcs9_unstructuredName:
    if (*type == V_ASN1_T61STRING) {
      GOTO_ERR("08 invalid characters in attribute value string");
    } else
      *type=V_ASN1_IA5STRING;
    break;
  }
  
  return 1;
err:
  return 0;
}

/* Add an entry to distinguished name */

/* Called by:  populate_request */
static int add_DN_object(X509_NAME *n, int nid, unsigned char *val)
{
  X509_NAME_ENTRY *ne=NULL;
  int type = ASN1_PRINTABLE_type(val,-1 /* uses strlen() */);
  
  if (req_fix_data(nid, &type) == 0) goto err;
  
  if (!(ne=X509_NAME_ENTRY_create_by_NID(NULL, nid, type,
					 val, strlen((char*)val))))
    GOTO_ERR("X509_NAME_ENTRY_create_by_NID");
  if (!X509_NAME_add_entry(n,ne,X509_NAME_entry_count(n),0))
    GOTO_ERR("X509_NAME_add_entry");
  
  X509_NAME_ENTRY_free(ne);
  return 1;
err:
  if (ne != NULL) X509_NAME_ENTRY_free(ne);
  return 0;
}

/* attribute objects are more complicated because they can be multivalued */

/* Called by: */
static int add_attribute_object(STACK_OF(X509_ATTRIBUTE) *n, int nid, unsigned char *val)
{
  X509_ATTRIBUTE *xa=NULL;
  ASN1_BIT_STRING *bs=NULL;
  ASN1_TYPE *at=NULL;
  
  /* add object plus value */
  if ((xa=X509_ATTRIBUTE_new()) == NULL) GOTO_ERR("no memory?");
  if ((xa->value.set=sk_ASN1_TYPE_new_null()) == NULL) GOTO_ERR("no memory?");
  /*xa->single = 1; **** this may also be set on some versions */
  
  if (xa->object != NULL) ASN1_OBJECT_free(xa->object);
  xa->object=OBJ_nid2obj(nid);
  
  if ((bs=ASN1_BIT_STRING_new()) == NULL) GOTO_ERR("no memory?");  
  bs->type=ASN1_PRINTABLE_type(val,-1 /* use strlen() */);
  
  if (!req_fix_data(nid,&bs->type)) goto err;
  
  if (!ASN1_STRING_set(bs,val,strlen((char*)val)+1)) GOTO_ERR("no memory?");
  if ((at=ASN1_TYPE_new()) == NULL) GOTO_ERR("no memory?");

  ASN1_TYPE_set(at,bs->type,(char *)bs);
  sk_ASN1_TYPE_push(xa->value.set,at);
  bs=NULL;
  at=NULL;
  /* only one item per attribute */

  if (!sk_X509_ATTRIBUTE_push(n,xa))
    GOTO_ERR("sk_X509_ATTRIBUTE_push (no memory?)");
  return 1;
err:
  if (xa != NULL) X509_ATTRIBUTE_free(xa);
  if (at != NULL) ASN1_TYPE_free(at);
  if (bs != NULL) ASN1_BIT_STRING_free(bs);
  return 0;
}

/* Construct req structure. Basically we expect dn and attr to
 * be new line separated attribute lists, each line containing
 * attribute=value pair (i.e. separated by first `='. Parse
 * the strings and add items one by one.
 */

#define LINESEP "|\015\012"

/* Called by:  keygen */
static X509_REQ* populate_request(const unsigned char* dn, const unsigned char* attr)
{
  char* p = NULL;
  char* t;  /* type, see objects.h LN macros for possibilities */
  char* v;  /* value */  
  int nid;
  X509_REQ* req = NULL;
  X509_REQ_INFO* ri;
  
  LOG_PRINT("populate");
  if (!dn) goto err;
  if (!(req=X509_REQ_new())) GOTO_ERR("no memory?");
  ri=req->req_info;

  LOG_PRINT("populate: set version");
  /* setup version number */
  if (!ASN1_INTEGER_set(ri->version,0L /*version 1*/))
    GOTO_ERR("ASN1_INTEGER_set");
  
  /* Add fields of distinguished name. strtok() alters the buffer,
   * and so do I, so lets get some fresh memory to play with. */
  
  if (!(p = strdup((const char*)dn))) GOTO_ERR("no memory?");
  
  /*Log_malloc = Log2;*/
  LOG_PRINT("populate: distinguished name");
  
  for (t = strtok(p, LINESEP); t; t = strtok(NULL, LINESEP)) {
    LOG_PRINT2("populate strtok returned '%s'",t);
    if (!(v = strchr(t, '='))) GOTO_ERR("09 missing `=' in DN attribute spec");
    /* *** assumes strtok() has already scanned past this char */
    *(v++)='\0';
    LOG_PRINT3("DN: %s=%s",t,v);
    /* If OBJ not recognised ignore it */
    if ((nid=OBJ_txt2nid(t)) == NID_undef)
      GOTO_ERR("06 Unregistered DN attribute name (OBJ_txt2nid)");
    LOG_PRINT2("NID %x",nid);
    if (!add_DN_object(ri->subject,nid,(unsigned char*)v)) goto err;
    LOG_PRINT("DN object added");
  }
  OPENSSL_free(p);
  p = NULL;
  if (!attr) return req;
  
  LOG_PRINT("populate: attributes");
  
  /* Add attribute fields */
  
  if (!(p = strdup((const char*)attr))) goto err;
  for (t = strtok(p, LINESEP); t; t = strtok(NULL, LINESEP)) {
    if (!(v = strchr(t, '='))) GOTO_ERR("09 missing `=' in attribute spec");
    /* *** assumes strtok() has already scanned past this char */
    *(v++)='\0';
    /* If OBJ not recognised ignore it */
    if ((nid=OBJ_txt2nid(t)) == NID_undef)
      GOTO_ERR("07 Unregistered attribute name (OBJ_txt2nid)");
    LOG_PRINT3("attr: %s=%s",t,v);
    if (!add_attribute_object(ri->attributes, nid, (unsigned char*)v))
      goto err;
  }
  OPENSSL_free(p);
  LOG_PRINT("populate: done");
  return req;
err:
  if (p) OPENSSL_free(p);
  if (req) X509_REQ_free(req);
  LOG_PRINT("populate: error");
  return NULL;
}

/* ============= K E Y   G E N E R A T I O N ==============*/

/* char** values are out parameters. They return malloced values.
 * passowrd is the password used
 * to encrypt the private key. identifiaction is a newline separated list
 * of attributes to include in certification request. Each line has
 * format: `name=value\n'
 */

/* Called by:  smime_keygen */
int keygen(const char* dn, const char* attr, const char* comment,
       EVP_PKEY** pkey_out,
       X509** x509ss_out,
       X509_REQ** req_out)
{
  time_t t;
  X509*     x509ss=NULL;
  X509_REQ* req=NULL;
  EVP_PKEY* pkey=NULL;
  EVP_PKEY* tmp_pkey=NULL;
  RSA*      rsa=NULL;
  int ret = -1;
  
  if (pkey_out) *pkey_out = NULL;
  if (x509ss_out) *x509ss_out = NULL;
  if (req_out) *req_out = NULL;
  X509V3_add_standard_extensions();
  
  LOG_PRINT("keygen start");
  
  t = time(NULL);
  RAND_seed(&t,sizeof(t));
#ifdef WINDOWS
  RAND_screen(); /* Loading video display memory into random state */
#endif
  
  /* Here's the beef */
  
  if (!(pkey=EVP_PKEY_new())) GOTO_ERR("no memory?");
  LOG_PRINT("keygen preparing rsa key");
  if (!(rsa = RSA_generate_key(1024 /*bits*/, 0x10001 /*65537*/,
			       NULL /*req_cb*/, NULL /*arg*/)))
     GOTO_ERR("RSA_generate_key");
  LOG_PRINT("keygen rsa key generated");
  if (!EVP_PKEY_assign_RSA(pkey, rsa)) GOTO_ERR("EVP_PKEY_assign_RSA");
  if (pkey_out) *pkey_out = pkey;
  
  t = time(NULL);
  RAND_seed(&t,sizeof(t));
  RAND_write_file(randomfile);  /* Key generation is a big operation. Write
				   in the new random state. */
  
  /* ============================================================
   * Now handle the public key part, i.e. create self signed and
   * certificate request. This starts by making a request that
   * contains all relevant fields.
   */
  
  LOG_PRINT3("keygen populating request '%s' '%s'", dn, attr);
  if (!(req=populate_request((const unsigned char*)dn,
			     (const unsigned char*)attr))) goto err;
  LOG_PRINT("keygen request populated");
  X509_REQ_set_pubkey(req,pkey);
  /*req->req_info->req_kludge=0;    / * no asn1 kludge *** filed deleted as of 0.9.7b?!? */
  
  if (req_out) {
    LOG_PRINT("keygen signing request");
#if 0
  if (!(X509_REQ_sign(req, pkey, EVP_md5()))) GOTO_ERR("X509_REQ_sign");
#else
  if (!(X509_REQ_sign(req, pkey, EVP_sha256()))) GOTO_ERR("X509_REQ_sign");
#endif
    LOG_PRINT("keygen request signed");
    *req_out = req;
  }
  
#if 1
  /* -- X509 create self signed certificate */
  
  if (x509ss_out) {
    LOG_PRINT("keygen making x509");
    if (!(x509ss=X509_new())) GOTO_ERR("no memory?");
    
    /* Set version to V3 and serial number to zero */
    if(!X509_set_version(x509ss, 2)) GOTO_ERR("X509_set_version");
    ASN1_INTEGER_set(X509_get_serialNumber(x509ss),0L);
    LOG_PRINT("keygen setting various x509 fields");
    
    X509_set_issuer_name(x509ss,
			 X509_REQ_get_subject_name(req));
    X509_gmtime_adj(X509_get_notBefore(x509ss),0);
    X509_gmtime_adj(X509_get_notAfter(x509ss),
		    (long)60*60*24*365 /*days*/);
    X509_set_subject_name(x509ss,
			  X509_REQ_get_subject_name(req));
    
    LOG_PRINT("keygen setting x509 attributes");
    if (!(tmp_pkey =X509_REQ_get_pubkey(req))) GOTO_ERR("X509_REQ_get_pubkey");
    X509_set_pubkey(x509ss,tmp_pkey);
    EVP_PKEY_free(tmp_pkey);
    tmp_pkey = NULL;
    
    /* Set up V3 context struct and add certificate extensions. Note
     * that we need to add (full) suite of CA extensions, otherwise
     * our cert is not valid for signing itself.
     */
    
    if (add_some_X509v3_extensions(x509ss,
				   "CA:TRUE,pathlen:3", /*basic_constraints*/
				   "client,server,email,objsign,sslCA,emailCA,objCA", /*cert_type*/
				   "digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment,keyAgreement,keyCertSign,cRLSign", /*key_usage*/
				   comment)==-1) goto err;
    
    LOG_PRINT("keygen signing x509");
#if 0
    if (!(X509_sign(x509ss, pkey, EVP_md5()))) GOTO_ERR("X509_sign");
#else
    if (!(X509_sign(x509ss, pkey, EVP_sha256()))) GOTO_ERR("X509_sign");
#endif
    LOG_PRINT("keygen x509 ready");
    *x509ss_out = x509ss;
  }
#endif
  
  ret = 0;
  
err:
  /*if (tmp_pkey)            EVP_PKEY_free(tmp_pkey); never happens */
  if (pkey   && !pkey_out)   EVP_PKEY_free(pkey);
  if (req    && !req_out)    X509_REQ_free(req);
  if (x509ss && !x509ss_out) X509_free(x509ss);
  X509V3_EXT_cleanup();
  OBJ_cleanup();
  LOG_PRINT("keygen done.");
  return ret;
}

/* Called by:  main */
int smime_keygen(const char* dn, const char* attr, const char* passwd, const char* comment, char** priv_out, char** x509ss_out, char** request_out)
{
  X509*     x509ss=NULL;
  X509_REQ* req=NULL;
  EVP_PKEY* pkey=NULL;
  int ret = -1;

  if (priv_out) *priv_out = NULL;
  if (x509ss_out) *x509ss_out = NULL;
  if (request_out) *request_out = NULL;
  
  if (keygen(dn, attr, comment, &pkey, &x509ss, &req) == -1) goto err;
  
  /* Write private key to file. While its being
   * written, it will also get encrypted. */
  
  if (passwd && priv_out) {
    if (write_private_key(pkey, passwd, priv_out) == -1) goto err;
    EVP_PKEY_free(pkey);  /* free early so memory can be reused */
    pkey = NULL;
  }
  
  if (request_out) {
    if (write_request(req, request_out) == -1) goto err;
    X509_REQ_free(req);  /* free early so memory can be reused */
    req = NULL;
  }
  
  if (x509ss_out) {    
    if (write_certificate(x509ss, x509ss_out)==-1) goto err;
  }
  
  ret = 0;
  
err:
  if (pkey)   EVP_PKEY_free(pkey);
  if (req)    X509_REQ_free(req);
  if (x509ss) X509_free(x509ss);
  return ret;
}

/* EOF  -  keygen.c */
