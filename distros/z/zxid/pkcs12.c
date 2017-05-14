/* pkcs12.c  -  Key conversion utilities. See smime.c for user interface.
 *
 * Copyright (c) 1999 Sampo Kellomaki <sampo@iki.fi>, All Rights Reserved.
 * License: This software may be distributed under the same license
 *          terms as openssl (i.e. free, but mandatory attribution).
 *
 * pkcs12 conversion was "destilled" from apps/pkcs12.c by Dr Stephen N
 * Henson (shenson@bigfoot.com)
 *
 * 27.9.1999, Created. --Sampo
 * 30.9.1999, added PKCS12 stuff, --Sampo
 * 1.10.1999, improved error reporting, --Sampo
 * 6.10.1999, forked from keygen.c --Sampo
 * 9.10.1999, fixed pkcs12_to_pem, fixed several double frees --Sampo
 *
 */

/* Written by Dr Stephen N Henson (shenson@bigfoot.com) for the OpenSSL
 * project 1999.
 */
/* ====================================================================
 * Copyright (c) 1999 The OpenSSL Project.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer. 
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *
 * 3. All advertising materials mentioning features or use of this
 *    software must display the following acknowledgment:
 *    "This product includes software developed by the OpenSSL Project
 *    for use in the OpenSSL Toolkit. (http://www.OpenSSL.org/)"
 *
 * 4. The names "OpenSSL Toolkit" and "OpenSSL Project" must not be used to
 *    endorse or promote products derived from this software without
 *    prior written permission. For written permission, please contact
 *    licensing@OpenSSL.org.
 *
 * 5. Products derived from this software may not be called "OpenSSL"
 *    nor may "OpenSSL" appear in their names without prior written
 *    permission of the OpenSSL Project.
 *
 * 6. Redistributions of any form whatsoever must retain the following
 *    acknowledgment:
 *    "This product includes software developed by the OpenSSL Project
 *    for use in the OpenSSL Toolkit (http://www.OpenSSL.org/)"
 *
 * THIS SOFTWARE IS PROVIDED BY THE OpenSSL PROJECT ``AS IS'' AND ANY
 * EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE OpenSSL PROJECT OR
 * ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 * ====================================================================
 *
 * This product includes cryptographic software written by Eric Young
 * (eay@cryptsoft.com).  This product includes software written by Tim
 * Hudson (tjh@cryptsoft.com).
 *
 */

#include "platform.h"

#include <stdio.h>
#include <string.h>
#include <time.h>

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

#if SSLEAY_VERSION_NUMBER < 0x010000000L
#define _STACK STACK
#endif

/* ================= P K C S 1 2    C O N V E R S I O N S ================ */
/* Convert pem formatted certificate and private key into PKCS12
 * object suitable for importing to browsers.
 *
 * openssl pkcs12 -name "friendly@name.com" -info -in cert.pem -inkey priv.pem -chain -export >pkcs12
 */

PKCS12*
x509_and_pkey_to_pkcs12(const char* friendly_name,  /* e.g. foo@bar.com */
	      X509*       x509,           /* cert that goes with the pkey */
	      EVP_PKEY*   pkey,           /* private key */
	      const char* pkcs12_passwd)  /* used to encrypt pkcs12 */
{
  PKCS12* p12 = NULL;
  STACK_OF(PKCS12_SAFEBAG)* bags = NULL;
  STACK_OF(PKCS7)* safes = NULL;
  PKCS12_SAFEBAG* bag;
  PKCS8_PRIV_KEY_INFO* p8;
  PKCS7* authsafe;
  unsigned char keyid[EVP_MAX_MD_SIZE];
  unsigned int keyidlen = 0;
  
  if (!x509 || !pkey || !pkcs12_passwd) GOTO_ERR("NULL arg(s)");
  
  /* Figure out if cert goes with our private key */

  if(X509_check_private_key(x509, pkey)) {
    X509_digest(x509, EVP_sha1(), keyid, &keyidlen);
  } else
    GOTO_ERR("05 x509 cert does not match private key. Wrong files?");
  if(!keyidlen) GOTO_ERR("05 No certificate matches private key");
  
  /* Include the cert */
  
  if (!(bags = (STACK_OF(PKCS12_SAFEBAG)*)sk_new(NULL))) GOTO_ERR("no memory?");  
  if (!(bag = M_PKCS12_x5092certbag(x509))) GOTO_ERR("M_PKCS12_x5092certbag");
  
  if (friendly_name) PKCS12_add_friendlyname(bag, friendly_name, -1);
  PKCS12_add_localkeyid(bag, keyid, keyidlen);
  sk_push((_STACK*)bags, (char*)bag);
  
  /* Turn certbags into encrypted (why?) authsafe */
  
  if (!(authsafe = PKCS12_pack_p7encdata(NID_pbe_WithSHA1And40BitRC2_CBC,
					 pkcs12_passwd, -1 /* use strlen */,
					 NULL /*salt*/, 0 /*saltlen*/,
					 PKCS12_DEFAULT_ITER, bags)))
    GOTO_ERR("PKCS12_pack_p7encdata");
  sk_pop_free((_STACK*)bags, (void (*)(void *))PKCS12_SAFEBAG_free);
  bags = NULL;

  if (!(safes = (STACK_OF(PKCS7)*)sk_new(NULL))) GOTO_ERR("no memory?");
  sk_push((_STACK*)safes, (char*)authsafe);
  
  /* Make a shrouded key bag */

  p8 = EVP_PKEY2PKCS8 (pkey);
  /*PKCS8_add_keyusage(p8, KEY_EX|KEY_SIG);  / * MS needs this? */

  if (!(bag = PKCS12_MAKE_SHKEYBAG(NID_pbe_WithSHA1And3_Key_TripleDES_CBC,
				   pkcs12_passwd, -1 /*strlen*/,
				   NULL, 0, PKCS12_DEFAULT_ITER, p8)))
    GOTO_ERR("PKCS12_MAKE_SHKEYBAG");
  PKCS8_PRIV_KEY_INFO_free(p8);
  if (friendly_name) PKCS12_add_friendlyname (bag, friendly_name, -1);
  PKCS12_add_localkeyid (bag, keyid, keyidlen);
  if (!(bags = (STACK_OF(PKCS12_SAFEBAG)*)sk_new(NULL))) GOTO_ERR("no memory?");
  sk_push((_STACK*)bags, (char *)bag);
  
  /* *** is this code storing private key in unencrypted bag and public
   *    key in encrypted bag? SECURITY ALERT! See also generic and
   *    verify.c from openssl. --Sampo
   */
  
  /* Turn it into unencrypted safe bag */

  authsafe = PKCS12_pack_p7data (bags);
  sk_pop_free((_STACK*)bags, (void (*)(void *))PKCS12_SAFEBAG_free);
  bags = NULL;
  sk_push((_STACK*)safes, (char *)authsafe);
  
  if (!(p12 = PKCS12_init(NID_pkcs7_data))) GOTO_ERR("no memory?");
  
  M_PKCS12_pack_authsafes (p12, safes);
  sk_pop_free((_STACK*)safes, (void (*)(void *))PKCS7_free);
  safes = NULL;
  PKCS12_set_mac (p12, pkcs12_passwd, -1 /*strlen*/,
		  NULL /*salt*/, 0, 1 /*maciter*/,
		  NULL /*md type = default (SHA1)*/);
  return p12;
err:
  if (bags)  sk_pop_free((_STACK*)bags, (void (*)(void *))PKCS12_SAFEBAG_free);
  if (safes) sk_pop_free((_STACK*)safes, (void (*)(void *))PKCS7_free);
  return NULL;
}

int
smime_pem_to_pkcs12(const char* friendly_name,  /* e.g. foo@bar.com */
		    const char* x509_cert_pem,
		    const char* priv_key_pem,
		    const char* priv_passwd,    /* used to open private key */
		    const char* pkcs12_passwd,  /* used to encrypt pkcs12 */
		    char** pkcs12_out)
{
  EVP_PKEY* pkey = NULL;
  X509*     ucert = NULL;
  PKCS12*   p12 = NULL;
  int len = -1;
  
  if (!x509_cert_pem || !priv_key_pem || !priv_passwd
      || !pkcs12_passwd || !pkcs12_out) GOTO_ERR("NULL arg(s)");
  
  if (!(pkey = open_private_key(priv_key_pem, priv_passwd))) goto err;
  if (!(ucert = extract_certificate(x509_cert_pem))) goto err;
  if (!(p12 = x509_and_pkey_to_pkcs12(friendly_name, ucert, pkey,
			    pkcs12_passwd))) goto err;
  len = save_PKCS12(p12, pkcs12_out);
  
err:
  if (p12)   PKCS12_free(p12);
  if (ucert) X509_free(ucert);
  if (pkey)  EVP_PKEY_free(pkey);
  return len;
}

/* more generic version that allows inclusion of multiple certificates */

int
smime_pem_to_pkcs12_generic(const char* friendly_name,  /* e.g. foo@bar.com */
		    const char* x509_cert_pem,
		    const char* priv_key_pem,
		    const char* priv_passwd,    /* used to open private key */
		    const char* pkcs12_passwd,  /* used to encrypt pkcs12 */
		    char** pkcs12)
{
  BIO* rbio = NULL;
  BIO* wbio = NULL;
  PKCS12* p12 = NULL;
  /*STACK *canames = NULL;
  char* catmp; */
  EVP_PKEY* pkey;
  STACK_OF(PKCS12_SAFEBAG)* bags;
  STACK_OF(PKCS7)* safes;
  PKCS12_SAFEBAG* bag;
  PKCS8_PRIV_KEY_INFO* p8;
  PKCS7* authsafe;
  X509*  cert = NULL;
  X509*  ucert = NULL;
  STACK_OF(X509) *certs;
  int i;
  unsigned char keyid[EVP_MAX_MD_SIZE];
  unsigned int keyidlen = 0;
  
  if (!x509_cert_pem || !priv_key_pem || !priv_passwd
      || !pkcs12_passwd || !pkcs12) GOTO_ERR("NULL arg(s)");
  
  /* Read private key */

  if (!(rbio = set_read_BIO_from_buf((char*)priv_key_pem,
				     strlen(priv_key_pem)))) goto err;
  if (!(pkey = PEM_read_bio_PrivateKey(rbio, NULL, password_callback,
				       (void*)priv_passwd)))
    GOTO_ERR("01 bad private key file or password (PEM_read_bio_PrivateKey)");
  BIO_free(rbio);
  
  /* Load certificate(s) */
  
  if (!(certs = sk_X509_new(NULL))) GOTO_ERR("no memory?");
  if (!(rbio = set_read_BIO_from_buf((char*)x509_cert_pem,
				     strlen(x509_cert_pem)))) goto err;
  while((cert = PEM_read_bio_X509(rbio, NULL, NULL, NULL))) {
    sk_X509_push(certs, cert);
  }
  BIO_free(rbio);
  
  /* Figure out which cert goes with our private key */

  for(i = 0; i < sk_X509_num(certs); i++) {
    ucert = sk_X509_value(certs, i);
    if(X509_check_private_key(ucert, pkey)) {
      X509_digest(cert, EVP_sha1(), keyid, &keyidlen);
      break;
    }
  }

  if(!keyidlen) GOTO_ERR("05 No certificate matches private key");
  
  /* If chaining get chain from user cert */
#if 0
  {
    int vret;
    STACK_OF(X509) *chain2;
    vret = get_cert_chain (ucert, &chain2);
    if (vret) {
      /*BIO_printf (bio_err, "Error %s getting chain.\n",
	X509_verify_cert_error_string(vret));*/
      goto err;
    }
    /* Exclude verified certificate */
    for (i = 1; i < sk_X509_num (chain2) ; i++) 
      sk_X509_push(certs, sk_X509_value (chain2, i));
    sk_X509_free(chain2);    
  }
#endif

  /* We now have loads of certificates: include them all */

  if (!(bags = (STACK_OF(PKCS12_SAFEBAG)*)sk_new(NULL))) GOTO_ERR("no memory?");
  
  for(i = 0; i < sk_X509_num(certs); i++) {
    cert = sk_X509_value(certs, i);
    if (!(bag = M_PKCS12_x5092certbag(cert)))
      GOTO_ERR("M_PKCS12_x5092certbag");

    if(cert == ucert) {      /* If it matches private key set id */
      if (friendly_name) PKCS12_add_friendlyname(bag, friendly_name, -1);
      PKCS12_add_localkeyid(bag, keyid, keyidlen);
    } /*else if(canames && (catmp = sk_shift(canames))) 
	PKCS12_add_friendlyname(bag, catmp, -1);*/
    sk_push((_STACK*)bags, (char *)bag);
  }
  
  /*if (canames) sk_free(canames);*/
  
  /* Turn certbags into encrypted authsafe */

  if (!(authsafe = PKCS12_pack_p7encdata(NID_pbe_WithSHA1And40BitRC2_CBC,
					 pkcs12_passwd, -1 /* use strlen */,
					 NULL /*salt*/, 0 /*saltlen*/,
					 PKCS12_DEFAULT_ITER, bags)))
    GOTO_ERR("PKCS12_pack_p7encdata");
  sk_pop_free((_STACK*)bags, (void (*)(void *))PKCS12_SAFEBAG_free);
	
  if (!(safes = (STACK_OF(PKCS7)*)sk_new(NULL))) GOTO_ERR("no memory?");
  sk_push((_STACK*)safes, (char *)authsafe);
  
  /* Make a shrouded key bag */

  p8 = EVP_PKEY2PKCS8 (pkey);
  EVP_PKEY_free(pkey);
  /*PKCS8_add_keyusage(p8, KEY_EX|KEY_SIG);  / * MS needs this? */

  if (!(bag = PKCS12_MAKE_SHKEYBAG(NID_pbe_WithSHA1And3_Key_TripleDES_CBC,
				   pkcs12_passwd, -1 /*strlen*/,
				   NULL, 0, PKCS12_DEFAULT_ITER, p8)))
    GOTO_ERR("PKCS12_MAKE_SHKEYBAG");
  PKCS8_PRIV_KEY_INFO_free(p8);
  if (friendly_name) PKCS12_add_friendlyname (bag, friendly_name, -1);
  PKCS12_add_localkeyid (bag, keyid, keyidlen);
  if (!(bags = (STACK_OF(PKCS12_SAFEBAG)*)sk_new(NULL))) GOTO_ERR("no memory?");
  sk_push((_STACK*)bags, (char *)bag);
  
  /* Turn it into unencrypted safe bag */

  authsafe = PKCS12_pack_p7data (bags);
  sk_pop_free((_STACK*)bags, (void (*)(void *))PKCS12_SAFEBAG_free);
  sk_push((_STACK*)safes, (char *)authsafe);
  
  if (!(p12 = PKCS12_init(NID_pkcs7_data))) GOTO_ERR("no memory?");
  
  M_PKCS12_pack_authsafes (p12, safes);  
  sk_pop_free((_STACK*)safes, (void (*)(void *))PKCS7_free);  
  PKCS12_set_mac (p12, pkcs12_passwd, -1 /*strlen*/,
		  NULL /*salt*/, 0, 1 /*maciter*/,
		  NULL /*md type = default (SHA1)*/);

  if (!(wbio = BIO_new(BIO_s_mem()))) GOTO_ERR("no memory?");
  i2d_PKCS12_bio (wbio, p12);
  i = get_written_BIO_data(wbio, pkcs12);
  
  PKCS12_free(p12);
  BIO_free_all(wbio);
  
  return i;
err:
  /* *** free stuff */
  return -1;
}

/* -------------------------------------- */
/* Extract certificate(s) and public key(s) from PKCS12 structure.
 * Can be used to extract only one or the other by passing NULL
 * to appropriate OUT parameter.
 */

/* Called by:  smime_pkcs12_to_pem */
int
pkcs12_to_x509_and_pkey(PKCS12* p12,
	      const char* pkcs12_passwd,  /* used to decrypt pkcs12 */
	      X509**      x509_out,       /* cert that goes with the pkey */
	      EVP_PKEY**  pkey_out)       /* private key */
{
  int i, j;
  STACK_OF(PKCS12_SAFEBAG)* bags = NULL;
  STACK_OF(PKCS7)* authsafes = NULL;
  PKCS8_PRIV_KEY_INFO* p8 = NULL;

  if (!p12) GOTO_ERR("NULL arg");
  
  if (!PKCS12_verify_mac(p12, pkcs12_passwd, -1))
    GOTO_ERR("03 bad PKCS12 import password? (PKCS12_verify_mac)");

  if (!(authsafes = M_PKCS12_unpack_authsafes(p12)))
    GOTO_ERR("02 M_PKCS12_unpack_authsafes");
  
  /* Go through all bags. As we see cert bags, write them to cbio,
   * as we see shrouded keybags decrypt and re-encrypt them and
   * write them to pkbio */
  
  for (i = 0; i < sk_num((_STACK*)authsafes); i++) {
    PKCS7* authsafe = (PKCS7*)sk_value((_STACK*)authsafes, i);
    int bagnid = OBJ_obj2nid(authsafe->type);
    
    if (bagnid == NID_pkcs7_data) {
      bags = M_PKCS12_unpack_p7data(authsafe);
    } else if (bagnid == NID_pkcs7_encrypted) {
      /* undo transport armour encryption */
      bags = M_PKCS12_unpack_p7encdata(authsafe, pkcs12_passwd, -1);
    } else continue; /* unrecognized bag type */    
    if (!bags) GOTO_ERR("02 no bags found (is this a PKCS12 file?)");
    
    /* Now iterate over all bags found */
    
    for (j = 0; j < sk_num((_STACK*)bags); j++) {
      PKCS12_SAFEBAG* bag = (PKCS12_SAFEBAG*)sk_value((_STACK*)bags, j);
      
      switch (M_PKCS12_bag_type(bag)) {
      case NID_keyBag:
	/* this clause should never happen, because that would imply
	 * unencrypted private key */
	
	if (!pkey_out) break; /*skip*/
	if (!(*pkey_out = EVP_PKCS82PKEY (bag->value.keybag /*p8*/)))
	  GOTO_ERR("EVP_PKCS82PKEY");
	break;
	
      case NID_pkcs8ShroudedKeyBag:
	if (!pkey_out) break; /*skip*/
	if (!(p8 = M_PKCS12_decrypt_skey(bag, pkcs12_passwd,
					 strlen(pkcs12_passwd))))
	  GOTO_ERR("03 bad PKCS12 import password? (M_PKCS12_decrypt_skey)");
	if (!(*pkey_out = EVP_PKCS82PKEY (p8))) GOTO_ERR("EVP_PKCS82PKEY");
	PKCS8_PRIV_KEY_INFO_free(p8);
	p8 = NULL;
	break;

      case NID_certBag:
	if (!x509_out) break; /*skip*/
	
	/*if (PKCS12_get_attr(bag, NID_localKeyID)) {
	  if (options & CACERTS) return 1;
	  } else if (options & CLCERTS) return 1;*/
	
	if (M_PKCS12_cert_bag_type(bag) != NID_x509Certificate ) break;
	if (!(*x509_out = M_PKCS12_certbag2x509(bag)))
	  GOTO_ERR("M_PKCS12_certbag2x509");
	break;

      case NID_safeContentsBag:
	/*return dump_certs_pkeys_bags (out, bag->value.safes, pass,
	  passlen, options);*/
					
      default:
	strcpy(smime_error_buf, "Warning unsupported bag type");
	/* i2a_ASN1_OBJECT (bio_err, bag->type); */
	break;
      } /* switch bag_type */
    }
    sk_pop_free((_STACK*)bags, (void (*)(void *))PKCS12_SAFEBAG_free);
    bags = NULL;
  }
  sk_pop_free((_STACK*)authsafes, (void (*)(void *))PKCS7_free);  
  return 0;

err:
  if (bags)      sk_pop_free((_STACK*)bags, (void (*)(void *))PKCS12_SAFEBAG_free);
  if (p8)        PKCS8_PRIV_KEY_INFO_free(p8);
  if (authsafes) sk_pop_free((_STACK*)authsafes, (void (*)(void *))PKCS7_free);  
  return -1;
}

/* Called by:  main */
int
smime_pkcs12_to_pem(const char* pkcs12, int pkcs12_len,
		    const char* pkcs12_passwd,  /* used to decrypt pkcs12 */
		    const char* priv_passwd,    /* used to enc. private key */
		    char** priv_key_pem, char** x509_cert_pem)
{
  PKCS12*   p12 = NULL;
  X509*     x509 = NULL;
  EVP_PKEY* pkey = NULL;
  int ret = -1;

  if (!pkcs12_passwd || !pkcs12) GOTO_ERR("NULL arg(s)");
  
  /* Read pkcs12 structure (but do not decrypt private key yet) */
  
  if (!(p12 = load_PKCS12(pkcs12, pkcs12_len))) goto err;

  if (pkcs12_to_x509_and_pkey(p12, pkcs12_passwd,
			      (x509_cert_pem) ? &x509 : NULL,
			      (priv_passwd && priv_key_pem) ? &pkey : NULL)
      == -1) goto err;
    
  if (write_private_key(pkey, priv_passwd, priv_key_pem)==-1) goto err;
  ret = write_certificate(x509, x509_cert_pem);
  
err:
  if (p12) PKCS12_free(p12);
  if (x509) X509_free(x509);
  if (pkey) EVP_PKEY_free(pkey);
  return ret;
}

/* more generic because handles multiple certificates and private keys
   in key bags */

/* Called by: */
int
smime_pkcs12_to_pem_generic(const char* pkcs12, int pkcs12_len,
		    const char* pkcs12_passwd,  /* used to decrypt pkcs12 */
		    const char* priv_passwd,    /* used to enc. private key */
		    char** priv_key_pem, char** x509_cert_pem)
{
  BIO* rbio = NULL;
  BIO* pkbio = NULL;
  BIO* cbio = NULL;
  PKCS12* p12 = NULL;
  X509*  x509;
  int i, j;
  STACK_OF(PKCS12_SAFEBAG)* bags;
  STACK_OF(PKCS7)* authsafes;

  if (!pkcs12_passwd || !pkcs12) GOTO_ERR("NULL arg(s)");
  
  /* Read pkcs12 structure (but do not decrypt private key yet) */
  
  if (!(rbio = set_read_BIO_from_buf((char*)pkcs12, pkcs12_len))) goto err;
  if (!(p12 = d2i_PKCS12_bio(rbio, NULL)))
    GOTO_ERR("02 bad PKCS12 file format (d2i_PKCS12_bio)");
  if (!PKCS12_verify_mac(p12, pkcs12_passwd, -1))
    GOTO_ERR("03 bad import password? (PKCS12_verify_mac)");
  BIO_free(rbio);

  if (!(authsafes = M_PKCS12_unpack_authsafes(p12)))
    GOTO_ERR("02 M_PKCS12_unpack_authsafes");
  
  /* Go through all bags. As we see cert bags, write them to cbio,
   * as we see shrouded keybags decrypt and re-encrypt them and
   * write them to pkbio */
  
  if (!(pkbio = BIO_new(BIO_s_mem()))) GOTO_ERR("no memory?");
  if (!(cbio = BIO_new(BIO_s_mem()))) GOTO_ERR("no memory?");
  
  for (i = 0; i < sk_num ((_STACK*)authsafes); i++) {
    PKCS7* authsafe = (PKCS7*)sk_value((_STACK*)authsafes, i);
    int bagnid = OBJ_obj2nid(authsafe->type);
    
    if (bagnid == NID_pkcs7_data) {
      bags = M_PKCS12_unpack_p7data(authsafe);
    } else if (bagnid == NID_pkcs7_encrypted) {
      /* undo transport armour encryption */
      bags = M_PKCS12_unpack_p7encdata(authsafe, pkcs12_passwd, -1);
    } else continue; /* unrecognized bag type */    
    if (!bags) GOTO_ERR("02 no bags found (is this a PKCS12 file?)");
    
    /* Now iterate over all bags found */
    
    for (j = 0; j < sk_num((_STACK*)bags); j++) {
      EVP_PKEY* pkey;
      PKCS8_PRIV_KEY_INFO *p8;
      PKCS12_SAFEBAG* bag = (PKCS12_SAFEBAG*)sk_value((_STACK*)bags, j);
      
      switch (M_PKCS12_bag_type(bag)) {
      case NID_keyBag:
	if (!priv_passwd || !priv_key_pem) break; /*skip*/
	if (!(pkey = EVP_PKCS82PKEY (bag->value.keybag /*p8*/)))
	  GOTO_ERR("EVP_PKCS82PKEY");
	if (!PEM_write_bio_PrivateKey(pkbio, pkey, EVP_des_ede3_cbc(),
				      (unsigned char*)priv_passwd, strlen(priv_passwd),
				      NULL,NULL))
	  GOTO_ERR("PEM_write_bio_PrivateKey");
	EVP_PKEY_free(pkey);
	break;

      case NID_pkcs8ShroudedKeyBag:
	if (!priv_passwd || !priv_key_pem) break; /*skip*/
	if (!(p8 = M_PKCS12_decrypt_skey (bag, pkcs12_passwd,
					  strlen(pkcs12_passwd))))
	  GOTO_ERR("03 bad password? (M_PKCS12_decrypt_skey)");
	if (!(pkey = EVP_PKCS82PKEY (p8))) GOTO_ERR("EVP_PKCS82PKEY");
	PKCS8_PRIV_KEY_INFO_free(p8);
	if (!PEM_write_bio_PrivateKey(pkbio, pkey, EVP_des_ede3_cbc(),
				      (unsigned char*)priv_passwd, strlen(priv_passwd),
				      NULL,NULL))
	  GOTO_ERR("PEM_write_bio_PrivateKey");
	EVP_PKEY_free(pkey);
	break;

      case NID_certBag:
	if (!x509_cert_pem) break; /*skip*/
	
	/*if (PKCS12_get_attr(bag, NID_localKeyID)) {
	  if (options & CACERTS) return 1;
	  } else if (options & CLCERTS) return 1;*/
	
	if (M_PKCS12_cert_bag_type(bag) != NID_x509Certificate ) break;
	if (!(x509 = M_PKCS12_certbag2x509(bag)))
	  GOTO_ERR("M_PKCS12_certbag2x509");
	PEM_write_bio_X509 (cbio, x509);
	X509_free(x509);
	break;

      case NID_safeContentsBag:
	/*return dump_certs_pkeys_bags (out, bag->value.safes, pass,
	  passlen, options);*/
					
      default:
	/* "Warning unsupported bag type: "
	   i2a_ASN1_OBJECT (bio_err, bag->type); */
	break;
      } /* switch bag_type */
    }
    sk_pop_free((_STACK*)bags, (void (*)(void *))PKCS12_SAFEBAG_free);
  }
  sk_pop_free((_STACK*)authsafes, (void (*)(void *))PKCS7_free);  
  PKCS12_free(p12);
  
  if (priv_key_pem)  get_written_BIO_data(pkbio, priv_key_pem);  
  BIO_free_all(pkbio);
  if (x509_cert_pem) get_written_BIO_data(cbio,  x509_cert_pem);  
  BIO_free_all(cbio);
  
  return 0;
err:
  return -1;
}

/* EOF  -  pkcs12.c */
