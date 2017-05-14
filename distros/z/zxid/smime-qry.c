/* smime-qry.c  -  Get string representations of various certificate parameters
 *
 * Copyright (c) 1999 Sampo Kellomaki <sampo@iki.fi>, All Rights Reserved.
 * License: This software may be distributed under the same license
 *          terms as openssl (i.e. free, but mandatory attribution).
 *
 * 27.9.1999, Created. --Sampo
 * 30.9.1999, added PKCS12 stuff, --Sampo
 * 1.10.1999, improved error reporting, --Sampo
 * 6.10.1999, forked from keygen.c --Sampo
 * 9.10.1999, reviewed for double frees --Sampo
 * 18.10.1999, fixed 256 limit in calls to X509_NAME_oneline() --Sampo
 */

#include "platform.h"

#include <stdio.h>
#include <string.h>
#include <time.h>

#ifdef __MWERKS__
# include "macglue.h"
#endif

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

/* ----------------------- get info ----------------------- */

/* Obtain some human readable descriptions of the certificate. This is
 * important, for example, to verify if two certificates have the same
 * public key modulus.
 */

/* Called by:  smime_get_cert_info */
long  /* return serial number, -1 on failure */
get_cert_info(X509* x509,
		    char** modulus,      /* public key modulus */
		    char** fingerprint)  /* finger print that identifies */
{
  BIO* wbio = NULL;
  if (modulus) *modulus = NULL;
  if (fingerprint) *fingerprint = NULL;
  if (!x509) GOTO_ERR("NULL arg");

  /* Extract the public key part to be printed on paper */
  
  if (modulus) {
    EVP_PKEY* pubkey;
    if (!(wbio = BIO_new(BIO_s_mem()))) GOTO_ERR("no memory?");
    
    pubkey = X509_get_pubkey(x509);
    BN_print(wbio,pubkey->pkey.rsa->n);
    if (get_written_BIO_data(wbio, modulus) == -1) goto err;
    BIO_free_all(wbio);
    wbio = NULL;
  }
  
  /* Extract conventional message digest */
  
  if (fingerprint) {
    unsigned int  md_size;
    unsigned char md[EVP_MAX_MD_SIZE];
    if (!X509_digest(x509,EVP_md5(),md,&md_size)) GOTO_ERR("X509_digest");
    if (!md_size) goto err;
    if (!(*fingerprint = smime_dotted_hex((char*)md,md_size))) goto err;
  }  
  return ASN1_INTEGER_get(x509->cert_info->serialNumber);
err:
  if (wbio) BIO_free_all(wbio);
  return -1;
}

/* Called by:  main */
long  /* return serial number, -1 on failure */
smime_get_cert_info(const char* x509_cert_pem,
		    char** modulus,      /* public key modulus */
		    char** fingerprint)  /* finger print that identifies */
{
  long serial = -1;
  X509* x509 = NULL;
  if (modulus) *modulus = NULL;
  if (fingerprint) *fingerprint = NULL;
  if (!(x509 = extract_certificate(x509_cert_pem))) goto err;
  serial = get_cert_info(x509, modulus, fingerprint);
  
err:
  if (x509) X509_free(x509);
  return serial;
}

/* -------------------------------------- */

/* Called by:  get_req_hash, smime_get_req_modulus */
char* /* public key modulus */
get_req_modulus(X509_REQ* req)
{
  char* modulus = NULL;
  BIO* wbio = NULL;  
  EVP_PKEY* pubkey;

  if (!req) GOTO_ERR("NULL arg");
  if (!(wbio = BIO_new(BIO_s_mem()))) GOTO_ERR("no memory?");
  
  /* Extract the public key part to be printed on paper */
  
  pubkey = X509_REQ_get_pubkey(req);
  BN_print(wbio,pubkey->pkey.rsa->n);
  if (get_written_BIO_data(wbio, &modulus) == -1) goto err;
  BIO_free_all(wbio);
  return modulus;

err:
  if (wbio) BIO_free_all(wbio);
  return NULL;
}

/* Called by:  main */
char* /* public key modulus */
smime_get_req_modulus(const char* request_pem)
{
  char* modulus = NULL;
  X509_REQ* req = NULL;;
  if (!(req = extract_request(request_pem))) goto err;
  modulus = get_req_modulus(req);
  
err:
  if (req) X509_REQ_free(req);
  return modulus;
}

/* -------------------------------------- */

/* Calculate a hash over any string (I use it for modulus) */

/* Called by:  main x2 */
char*  /* returns the md5 hash as hex dump */
smime_md5(const char* data)
{
  EVP_MD_CTX ctx;
  unsigned int  md_size;
  unsigned char md[EVP_MAX_MD_SIZE];
  
  EVP_DigestInit(&ctx,EVP_md5());
  EVP_DigestUpdate(&ctx,data,strlen(data));
  EVP_DigestFinal(&ctx,md,&md_size);
  return smime_hex((char*)md, md_size);
}

/* ---------- req hash ----------- */

/* request hash is a 25 bit hash used for fast (but not necessarily
 * collision free) identification and database queries. It has so few
 * bits because it must fit on coarse 3 of 9 bar code. Basically
 * 25 bits are encoded in 5 characters from alphabet of 32.

Hashing scheme:
  MD5(subject_DN . attributes . public_key_modulus) --> produces
  128 bits (16 bytes). Take first three bytes plus LSB of fourth
  byte and encode them in base 32.

  On second thought, if we use two bar codes of 13+2 characters, we can
  represent full 128 bits of information. This should be considered
  sufficient even on security grounds. So, take 128 bit MD5 hash, divide
  it in two blocks of 64 bits (8 bytes). Now, 13*5 = 65, so it takes
  13 characters to encode each block. Last bit is padded with zero.

Base 32 encoding:
  work from LSB to MSB and left to right in groups of 5 bits (5 groups),
  encode each 5 bit number using

                     1         2         3
           01234567890123456789012345678901
  key ==> "ZY234.6789ABCDEFGHWJKLMNXPQR-TUV" <==


  Note: Difficult-to-distinguish characters in the sequence have
        been replaced by less ambiguous ones: 0O1I5S --> ZXYW.-

  Note: LSB of first 5 bit number is LSB of byte 0. LSB of second 5 bit
  number is bit 5 of byte 0 and MSB of second number is bit 1 of byte 1.

  <-- MSB  LSB -->

Char                                                                       Pad
 |   byte 0   byte 1   byte 2   byte 3   byte 4   byte 5   byte 6   byte 7   |
 V   AAAAAAAA BBBBBBBB CCCCCCCC DDDDDDDD EEEEEEEE FFFFFFFF GGGGGGGG HHHHHHHH V
 0:     43210                          
 1:  210            43                 
 2:            43210                   
 3:           0            4321        
 4:                    3210     4
 5:                              43210
 6:                                   01      423
 7:                                      43210
 8:                                                  43210
 9:                                               210            43
10:                                                         43210
11:                                                        0            4321
12:                                                                 3210     4

*/

static char req_hash_key[] = "ZY234.6789ABCDEFGHWJKLMNXPQR-TUV";

/* Called by:  get_req_hash x2 */
static void
encode_64bits(unsigned char* md, char*p)
{
  p[0]  = req_hash_key[ md[0] & 0x1f ];
  p[1]  = req_hash_key[ ((md[0] >> 5) & 0x07) | ((md[1] & 0x03) << 3) ];
  p[2]  = req_hash_key[ (md[1] >> 2) & 0x1f ];
  p[3]  = req_hash_key[ ((md[1] >> 7) & 0x01) | ((md[2] & 0x0f) << 1) ];
  p[4]  = req_hash_key[ ((md[2] >> 4) & 0x0f) | ((md[3] & 0x01) << 4) ];
  p[5]  = req_hash_key[ (md[3] >> 1) & 0x1f ];
  p[6]  = req_hash_key[ ((md[3] >> 6) & 0x03) | ((md[4] & 0x07) << 2) ];
  p[7]  = req_hash_key[ (md[4] >> 3) & 0x1f ];
  p[8]  = req_hash_key[ md[5] & 0x1f ];
  p[9]  = req_hash_key[ ((md[5] >> 5) & 0x07) | ((md[6] & 0x03) << 3) ];
  p[10] = req_hash_key[ (md[6] >> 2) & 0x1f ];
  p[11] = req_hash_key[ ((md[6] >> 7) & 0x01) | ((md[7] & 0x0f) << 1) ];
  p[12] = req_hash_key[ ((md[7] >> 4) & 0x0f) /* | bit4 is zero pad */  ];
  p[13] = '\0';
}

/* Called by: */
char*  /* hash, ready to print, or NULL if error */
get_req_hash(X509_REQ* req)
{
  EVP_MD_CTX ctx;
  unsigned int  md_size;
  unsigned char md[EVP_MAX_MD_SIZE];
  char* p;

  if (!req) GOTO_ERR("NULL arg");
  
  EVP_DigestInit(&ctx,EVP_md5());
  
  if (!(p = get_req_name(req))) goto err;
  EVP_DigestUpdate(&ctx,p,strlen(p));
  OPENSSL_free(p);
  
  if (!(p = get_req_attr(req))) goto err;
  EVP_DigestUpdate(&ctx,p,strlen(p));
  OPENSSL_free(p);
  
  if (!(p = get_req_modulus(req))) goto err;
  EVP_DigestUpdate(&ctx,p,strlen(p));
  OPENSSL_free(p);
  
  EVP_DigestFinal(&ctx,md,&md_size);

  if (md_size < 16) goto err;
  if (!(p = (char*)OPENSSL_malloc(13+13+1))) GOTO_ERR("no memory?");

  encode_64bits(md, p);       /* block 1, first 13 chars */
  encode_64bits(md+8, p+13);  /* block 2, second 13 chars */
  return p;

err:
  return NULL;
}

char* /* 25 bit hash as string like `*Z4K67W*' or NULL if error */
smime_get_req_hash(const char* request_pem)
{
  char* n = NULL;
  X509_REQ* req = NULL;
  if (!(req = extract_request(request_pem))) goto err;
  n = get_req_hash(req);
  
err:
  if (req) X509_REQ_free(req);
  return n;
}

/* -------------------------------------- */

/* Get distinguished name information from the certificate */

/* Called by:  smime_get_cert_names */
long  /* return serial number, -1 on failure */
get_cert_names(X509* x509,
	       char** subject_DN,   /* who the certificate belongs to */
	       char** issuer_DN)    /* who signed the certificate */
{
  long serial = -1;

  if (subject_DN) *subject_DN = NULL;
  if (issuer_DN) *issuer_DN = NULL;
  if (!x509) GOTO_ERR("NULL arg");
  
  if (subject_DN) {  /* if you don't want to know subject, pass this as NULL */
    if (!(*subject_DN = X509_NAME_oneline(X509_get_subject_name(x509),NULL,0)))
      GOTO_ERR("no memory?");
  }
  
  if (issuer_DN) {   /* if you don't want to know issuer, pass NULL here */    
    if (!(*issuer_DN = X509_NAME_oneline(X509_get_issuer_name(x509),NULL,0)))
      GOTO_ERR("no memory?");
  }

  /* extract serial number */

  serial = ASN1_INTEGER_get(x509->cert_info->serialNumber);
err:
  return serial;
}

/* Called by:  main */
long  /* return serial number, -1 on failure */
smime_get_cert_names(const char* x509_cert_pem,
		     char** subject_DN,   /* who the certificate belongs to */
		     char** issuer_DN)    /* who signed the certificate */
{
  long serial = -1;
  X509* x509 = NULL;
  if (subject_DN) *subject_DN = NULL;
  if (issuer_DN) *issuer_DN = NULL;
  if (!(x509 = extract_certificate(x509_cert_pem))) goto err;
  serial = get_cert_names(x509, subject_DN, issuer_DN);
  
err:
  if (x509) X509_free(x509);
  return serial;
}

/* -------------------------------------- */

/* Getting the attributes does not appear to be too well supported, i.e.
 * there is no easy way. You just have to walk the data structure yourself.
 * This function only understands sets of one value and single values.
 * See crypto/asn1/asn1_par.c for similar code. */

/* Called by:  get_req_hash, smime_get_req_attr */
char* /* new line separated list of attribute value pairs */
get_req_attr(X509_REQ* req)
{
  int i;
  STACK_OF(X509_ATTRIBUTE)* xas = NULL;
  X509_ATTRIBUTE* xa;
  ASN1_TYPE* val;
  STACK_OF(ASN1_TYPE)* vals = NULL;
  char* buf = NULL;
  
  if (!req) GOTO_ERR("NULL arg");
  if (!(buf = strdup(""))) GOTO_ERR("no memory?");
  if ((xas = req->req_info->attributes) == NULL) goto err; /* no attributes */

  for (i = 0; i < sk_X509_ATTRIBUTE_num(xas); i++) {
    xa = sk_X509_ATTRIBUTE_value(xas, i);
    
    /* print the (long)name of the attribute */

    if (!(buf = concat(buf, OBJ_nid2ln(OBJ_obj2nid(xa->object))))) goto err;
    if (!(buf = concat(buf, "="))) goto err;
    
    /* Obtain either the single value or the first value in the set */
    
    if (1 /*|| xa->single  **** this is called set on some versions */) {
      if ((vals = xa->value.set) && sk_ASN1_TYPE_num(vals)) {
	val = sk_ASN1_TYPE_value(vals,0);
      } else
	val = NULL;
    } else {
      val = xa->value.single;
    }
    if (val) {
      /* print the value. *** for now this only works for various string
         types */
      if (!(buf = concatmem(buf, (char*)(val->value.asn1_string->data),
			    val->value.asn1_string->length))) goto err;
    }
    
    if (!(buf = concat(buf,"\n"))) goto err;
  }
  return buf;
err:
  return NULL;
}

/* Called by:  main */
char* /* public key modulus */
smime_get_req_attr(const char* request_pem)
{
  char* name = NULL;
  X509_REQ* req = NULL;
  if (!(req = extract_request(request_pem))) goto err;
  name = get_req_attr(req);
  
err:
  if (req) X509_REQ_free(req);
  return name;
}

/* Called by:  get_req_hash, smime_get_req_name */
char* /* subject_DN - who the request belongs to */
get_req_name(X509_REQ* req)
{  
  if (!req) GOTO_ERR("NULL arg");
  return X509_NAME_oneline(X509_REQ_get_subject_name(req),NULL,0);
err:
  return NULL;
}

/* Called by:  main */
char* /* public key modulus */
smime_get_req_name(const char* request_pem)
{
  char* name = NULL;
  X509_REQ* req = NULL;
  if (!(req = extract_request(request_pem))) goto err;
  name = get_req_name(req);
  
err:
  if (req) X509_REQ_free(req);
  return name;
}

/* EOF  -  smime-qry.c */
