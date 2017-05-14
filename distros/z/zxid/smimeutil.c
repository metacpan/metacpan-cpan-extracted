/* smimeutil.c  -  Utility functions for performing S/MIME signatures
 *                 and encryption.
 *
 * Copyright (c) 1999,2004 Sampo Kellomaki <sampo@iki.fi>, All Rights Reserved.
 * License: This software may be distributed under the same license
 *          terms as openssl (i.e. free, but mandatory attribution).
 *          See file LICENSE for details.
 *
 * 11.9.1999, Created. --Sampo
 * 13.9.1999, 0.1 released. Now adding verify. --Sampo
 * 1.10.1999, improved error handling, fixed decrypt --Sampo
 * 6.10.1999, divided to smime-enc.c, smime-vfy.c, smimemime.c and smimeutil.c
 * 9.10.1999, reviewed for double frees --Sampo
 * 18.10.1999, added CR_PARANOIA ifdefs. THis define is useful on platforms
 *             like Mac that use CR as line termination. OpenSSL PEM
 *             parsing routines do not grog CR so we need to preconvert
 *             CR to CRLF to guarantee easy operation. --Sampo
 * 10.10.2004, fixed long term annoyance where empty password did still encypt. Now
 *             empty password causes no encryption what so ever. --Sampo
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

#include "logprint.h"

#include <openssl/crypto.h>
#include <openssl/buffer.h>
#include <openssl/bio.h>
#include <openssl/x509.h>
#include <openssl/pem.h>
#include <openssl/err.h>
#include <openssl/rand.h>

#define SMIME_INTERNALS  /* we want also our internal helper functions */
#include "smimeutil.h"

/* ======================= U T I L I T I E S ======================= */

char smime_error_buf[256];  /* stores smime library-level error */
char randomfile[256] = "random.txt";

#ifdef DEBUGLOG
FILE* Log = NULL;
#endif

/* initializes EVP algorithm tables and injects randomness into
 * system. If random file existed it is read as well and 0 (for
 * success) is returned. If random file did not exist, it will be
 * created (if permissions allow) and -1 is returned. On that occasion
 * it is advisable to arrange some real randomness (such as movements of
 * mouse, times between key presses, /dev/random, etc.) and call
 * init again.
 */

/* Called by:  main */
int smime_init(const char* random_file, const char* randomness, int randlen)
{
  time_t t;
  OpenSSL_add_all_algorithms();  /* calling this multiple times does not seem to have any negative effect. */
  OpenSSL_add_all_ciphers();  /* Needed to avoid 10069:error:0906B072:PEM routines:PEM_get_EVP_CIPHER_INFO:unsupported encryption:pem_lib.c:481: */
  OpenSSL_add_all_digests();

#ifdef DEBUGLOG
  Log = fopen("smimeutil.log", "w");
  LOG("Log opened");
#endif

  LOG_PRINT("smime_init");
  t = time(NULL);
  RAND_seed(&t,sizeof(t));
  if (randomness) RAND_seed(randomness, randlen);

#ifdef WINDOWS
  LOG_PRINT("RAND_screen...");
  RAND_screen(); /* Loading video display memory into random state */
#endif
  if (random_file) {
    strncpy(randomfile, random_file, sizeof(randomfile));
    randomfile[sizeof(randomfile)-1] = '\0';
  }
  if (RAND_load_file(randomfile,1024L*1024L)) {
    RAND_seed(&t,sizeof(t));
    strcpy(smime_error_buf, SMIME_VERSION " randomness initialized");
    return 0;
  }
  strcpy(smime_error_buf, SMIME_VERSION " no randomfile");
  RAND_seed(&t,sizeof(t));
  RAND_write_file(randomfile);  /* create random file if possible */

  return -1;
}

/* Initialize a memory BIO to have certain content */

/* Called by:  encrypt1, extract_certificate, extract_request, get_pkcs7_from_pem, load_PKCS12, open_private_key, smime_base64, smime_pkcs12_to_pem_generic, smime_sign_engine, smime_verify_signature */
BIO* set_read_BIO_from_buf(const char* buf, int len)
{
  BIO* rbio;  
  BUF_MEM* bm;
  if (!buf) GOTO_ERR("NULL file buffer");
  if (len == -1) len = strlen(buf);
  LOG_PRINT3("set_read_BIO_from_buf %x, len %d", buf, len);
  if (!(rbio = BIO_new(BIO_s_mem()))) GOTO_ERR("no memory?");
  if (!(bm = BUF_MEM_new()))  GOTO_ERR("no memory?");
  if (!BUF_MEM_grow(bm, len)) GOTO_ERR("no memory?");
  memcpy(bm->data, buf, len);
  BIO_set_mem_buf(rbio, bm, 0 /*not used*/);
  LOG_PRINT("ok");
  return rbio;
err:
  return NULL;
}

/* Flushes a write BIO and returns the accumulated data as one malloc'd blob
 * returns length or -1 if error */

/* Called by:  decrypt, get_cert_info, get_req_modulus, save_PKCS12, smime_base64, smime_pkcs12_to_pem_generic x2, smime_verify_signature, write_certificate, write_private_key, write_request */
int get_written_BIO_data(BIO* wbio, char** data)
{
  int n;
  char* p;
  if (!data) GOTO_ERR("NULL arg");
  *data = NULL;
  BIO_flush(wbio);
  n = BIO_get_mem_data(wbio,&p);
  LOG_PRINT3("get_written_BIO_data: %x %d bytes", p, n);
  if (!((*data)=(char*)OPENSSL_malloc(n+1))) GOTO_ERR("no memory?");
  memcpy(*data, p, n);
  (*data)[n] = '\0';
  return n;
err:
  return -1;
}

/* Callback for supplying the pesky password. */

/* Called by: */
int password_callback(char* buf, int buf_size, int x /*not used*/, void* password)
{
  int n;
  if (!password) {
    strcpy(buf, "");
    return 0;
  }
  n = strlen((char*)password);
  if (n >= buf_size) n = buf_size-1;
  memcpy(buf, (char*)password, n);
  buf[n] = '\0';
  return n; 
}

/* Get private key from buffer full of encrypted stuff */

/* Called by:  smime_ca, smime_clear_sign, smime_decrypt, smime_sign */
EVP_PKEY* open_private_key(const char* privatekey_pem, const char* password)
{
  EVP_PKEY* pkey = NULL;
  BIO* rbio = NULL;
  LOG_PRINT3("open_private_key: %x %x", privatekey_pem, password);
#ifdef CR_PARANOIA
  if (!(privatekey_pem = mime_canon(privatekey_pem))) GOTO_ERR("no memory?");
  LOG_PRINT("CR paranoia enabled");
#endif
  if (!(rbio = set_read_BIO_from_buf(privatekey_pem, -1))) goto err;
  if (!(pkey=PEM_read_bio_PrivateKey(rbio,NULL, password_callback,
				     (void*)password)))
    GOTO_ERR("01 bad password or badly formatted private key pem file (PEM_read_bio_PrivateKey)");
  LOG_PRINT("done");
  BIO_free(rbio);
#ifdef CR_PARANOIA
  if (privatekey_pem) Free((void*)privatekey_pem);
#endif
  return pkey;
  
err:
#ifdef CR_PARANOIA
  if (privatekey_pem) Free((void*)privatekey_pem);
#endif
  if (pkey) EVP_PKEY_free(pkey);
  if (rbio) BIO_free(rbio);
  LOG_PRINT("error");
  return NULL;
}

/* Called by:  smime_keygen, smime_pkcs12_to_pem */
int write_private_key(EVP_PKEY* pkey, const char* passwd, char** priv_pem_OUT)
{
  int len = -1;
  BIO* wbio=NULL;
  if (!passwd || !priv_pem_OUT || !pkey) GOTO_ERR("NULL arg(s)");
  *priv_pem_OUT = NULL;
  if (!(wbio = BIO_new(BIO_s_mem()))) GOTO_ERR("no memory?");
  LOG_PRINT("write_private_key");
  if (!PEM_write_bio_PrivateKey(wbio, pkey, *passwd ? EVP_des_ede3_cbc() : 0,
				*passwd ? (unsigned char*)passwd:0, strlen(passwd),
				NULL,NULL))
    GOTO_ERR("PEM_write_bio_PrivateKey (bad passwd, no memory?)");
  len = get_written_BIO_data(wbio, priv_pem_OUT);
err:
  if (wbio) BIO_free_all(wbio);
  return len;
}

/* Extract a certificate from pem encoding */

/* Called by:  smime_ca, smime_clear_sign, smime_decrypt, smime_encrypt, smime_get_cert_info, smime_get_cert_names, smime_sign, smime_verify_cert x2, smime_verify_signature */
X509* extract_certificate(const char* cert_pem)
{
  X509* x509 = NULL;
  BIO* rbio = NULL;
  LOG_PRINT2("extract_certificate %x", cert_pem);
#ifdef CR_PARANOIA
  if (!(cert_pem = mime_canon(cert_pem))) GOTO_ERR("no memory?");
  LOG_PRINT("CR paranoia enabled");
#endif
  if (!(rbio = set_read_BIO_from_buf(cert_pem, -1))) goto err;
  if (!(x509=PEM_read_bio_X509(rbio,NULL,NULL,NULL)))
    GOTO_ERR("10 badly formatted X509 certificate pem file (PEM_read_bio_X509)");
  LOG_PRINT("done");
err:
#ifdef CR_PARANOIA
  if (cert_pem) Free((void*)cert_pem);
#endif
  if (rbio) BIO_free(rbio);
  return x509;
}

/* Called by:  smime_ca, smime_keygen, smime_pkcs12_to_pem */
int write_certificate(X509* x509, char** x509_cert_pem_OUT)
{
  BIO* wbio = NULL;
  int len = -1;
  if (!x509 || !x509_cert_pem_OUT) GOTO_ERR("NULL arg");
  *x509_cert_pem_OUT = NULL;
  if (!(wbio = BIO_new(BIO_s_mem()))) GOTO_ERR("no memory?");
  LOG_PRINT("write_certificate");
  PEM_write_bio_X509(wbio, x509);
  len = get_written_BIO_data(wbio, x509_cert_pem_OUT);
err:
  if (wbio) BIO_free_all(wbio);
  return len;
}

/* Called by:  smime_ca, smime_get_req_attr, smime_get_req_modulus, smime_get_req_name */
X509_REQ* extract_request(const char* req_pem)
{
  X509_REQ* x509_req = NULL;
  BIO* rbio = NULL;
  LOG_PRINT2("extract_request %x", req_pem);
#ifdef CR_PARANOIA
  if (!(req_pem = mime_canon(req_pem))) GOTO_ERR("no memory?");
  LOG_PRINT("CR paranoia enabled");
#endif
  if (!(rbio = set_read_BIO_from_buf(req_pem, -1))) goto err;
  if (!(x509_req = PEM_read_bio_X509_REQ(rbio,NULL,NULL,NULL)))
    GOTO_ERR("04 badly formatted certificate request pem file (PEM_read_bio_x509_REQ)");
  LOG_PRINT("done");  
err:
#ifdef CR_PARANOIA
  if (req_pem) Free((void*)req_pem);
#endif
  if (rbio) BIO_free(rbio);
  return x509_req;
}

/* Called by:  smime_keygen */
int write_request(X509_REQ* x509_req, char** x509_req_pem_OUT)
{
  BIO* wbio = NULL;
  int len = -1;
  if (!x509_req || !x509_req_pem_OUT) GOTO_ERR("NULL arg");
  *x509_req_pem_OUT = NULL;
  if (!(wbio = BIO_new(BIO_s_mem()))) GOTO_ERR("no memory?");
  LOG_PRINT("write_request");
  PEM_write_bio_X509_REQ(wbio, x509_req);
  len = get_written_BIO_data(wbio, x509_req_pem_OUT);  
err:
  if (wbio) BIO_free_all(wbio);
  return len;
}

/* Called by:  smime_pkcs12_to_pem */
PKCS12* load_PKCS12(const char* pkcs12, int pkcs12_len)
{
  BIO* rbio = NULL;
  PKCS12* p12 = NULL;
  if (!(rbio = set_read_BIO_from_buf((char*)pkcs12, pkcs12_len))) goto err;
  if (!(p12 = d2i_PKCS12_bio(rbio, NULL)))
    GOTO_ERR("02 bad PKCS12 file format (d2i_PKCS12_bio)");
err:
  if (rbio) BIO_free(rbio);
  return p12;
  
}

/* Called by: */
int save_PKCS12(PKCS12* p12, char** pkcs12_out)
{
  BIO* wbio = NULL;
  int len = -1;
  if (!p12 || !pkcs12_out) GOTO_ERR("NULL arg(s)");
  *pkcs12_out = NULL;
  if (!(wbio = BIO_new(BIO_s_mem()))) GOTO_ERR("no memory?");
  i2d_PKCS12_bio(wbio, p12);  /* der encode it */
  len = get_written_BIO_data(wbio, pkcs12_out);
err:
  if (wbio) BIO_free_all(wbio);
  return len;
}

/* Called by:  get_cert_info */
char* smime_dotted_hex(const char* data, int len)
{
  int j;
  char* p;
  char* buf;
  if (!data || !len) GOTO_ERR("NULL or bad arg");
  if (!(buf = p = (char*)OPENSSL_malloc(len*3+1))) GOTO_ERR("no memory?");
  for (j=0; j<len; j++) {
    sprintf(p,"%02X:",(unsigned char)data[j]);
    p+=3;
  }
  p[-1] = '\0';  /* change last : to \0 */
  return buf;
err:
  return NULL;
}

/* Called by:  smime_md5 */
char* smime_hex(const char* data, int len)
{
  int j;
  char* p;
  char* buf;
  if (!data || !len) GOTO_ERR("NULL or bad arg");
  if (!(buf = p = (char*)OPENSSL_malloc(len*2+1))) GOTO_ERR("no memory?");
  for (j=0; j<len; j++) {
    sprintf(p,"%02X",(unsigned char)data[j]);
    p+=2;
  }
  return buf;
err:
  return NULL;
}

/* Called by:  main x28 */
char* smime_get_errors()
{
  BIO* wbio;
  char* p;
  if (!(wbio = BIO_new(BIO_s_mem()))) return smime_error_buf;
  BIO_puts(wbio, smime_error_buf);
  ERR_load_crypto_strings();
  ERR_print_errors(wbio);
  BIO_get_mem_data(wbio,&p);
  return p;  /* just leak the wbio */
}

/* EOF  -  smimeutil.c */
