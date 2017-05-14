/* zxid/zxcrypto.c  -  Glue for cryptographical functions
 * Copyright (c) 2015-2016 Synergetics NV (sampo@synergetics.be), All Rights Reserved.
 * Copyright (c) 2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2006-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxcrypto.c,v 1.10 2009-11-24 23:53:40 sampo Exp $
 *
 * 7.10.2008, added documentation --Sampo
 * 29.8.2009, added zxid_mk_self_signed_cert() --Sampo
 * 12.12.2011, added HMAC SHA-256 as needed by JWT/JWS --Sampo
 * 6.6.2015,   added aes-256-gcm --Sampo
 * 16.10.2015, upgraded sha256 support, eliminated MD5 from certs --Sampo
 *
 * See paper: Tibor Jager, Kenneth G. Paterson, Juraj Somorovsky: "One Bad Apple: Backwards Compatibility Attacks on State-of-the-Art Cryptography", 2013 http://www.nds.ruhr-uni-bochum.de/research/publications/backwards-compatibility/ /t/BackwardsCompatibilityAttacks.pdf
 *
 * http://wiki.openssl.org/index.php/EVP_Authenticated_Encryption_and_Decryption
 * https://www.openssl.org/docs/crypto/EVP_EncryptInit.html#gcm_and_ocb_modes
 */

#include "platform.h"  /* needed on Win32 for snprintf() et al. */

#include <zx/errmac.h>
#include <zx/zx.h>
#include <zx/zxid.h>
#include <zx/zxidutil.h>
#include <zx/c/zx-sa-data.h>
#include <string.h>
#include <sys/stat.h>  /* umask(2) */

#ifdef USE_OPENSSL
#include <openssl/evp.h>
#include <openssl/md5.h>
#include <openssl/sha.h>
#include <openssl/hmac.h>
#include <openssl/rand.h>
#include <openssl/x509.h>
#include <openssl/x509v3.h>
#include <openssl/rsa.h>
#include <openssl/pem.h>
#endif

/* Called by:  zxid_mk_jwt x2 */
char* zx_hmac_sha256(struct zx_ctx* c, int key_len, const char* key, int data_len, const char* data, char* md, int* md_len) {
  return (char*)HMAC(EVP_sha256(), key, key_len, (unsigned char*)data, data_len, (unsigned char*)md, (unsigned int*)md_len);
}

#if 0
/* Called by: */
struct zx_str* zx_hmac_sha1(struct zx_ctx* c, struct zx_str* key, struct zx_str* ss) {
  HMAC(EVP_sha1(), key->s, key->len, ss->s, ss->len, md, mdlen);

  EVP_CIPHER_CTX *ctx;
  EVP_CIPHER *type = EVP_des_cbc();

  int EVP_SealInit(ctx, type, char **ek, int *ekl, char *iv, EVP_PKEY **pubk, int npubk);
  int EVP_SealUpdate(ctx, unsigned char *out, int *outl, unsigned char *in, int inl);
  int EVP_SealFinal(ctx, unsigned char *out, int *outl);  
}

/* Following are macros in openssl headers so we need to define wrapper functions. */

/* Called by: */
int zx_EVP_CIPHER_key_length(const EVP_CIPHER* cipher) { return EVP_CIPHER_key_length(cipher); }
int zx_EVP_CIPHER_iv_length(const EVP_CIPHER* cipher)  { return EVP_CIPHER_iv_length(cipher); }
int zx_EVP_CIPHER_block_size(const EVP_CIPHER* cipher) { return EVP_CIPHER_block_size(cipher); }
#endif

/*() Get certificate signature algorithm string. This reads the
 * signature algorithm from certificate itself.
 * Returns something like "SHA1" or "SHA256" or "" on error.
 */

/* Called by:  */
const char* zxid_get_cert_signature_algo(X509* cert)
{
    if (!cert)
       return "";
    return OBJ_nid2ln(OBJ_obj2nid(cert->sig_alg->algorithm));
}

/*() zx_raw_digest2() computes a message digest over two items. The result
 * is placed in buffer md, which must already be of length sufficient for
 * the digest. md will not be nul terminated (and will usually have binary
 * data). Possible algos: "SHA1", "SHA256", "SHA512", etc.
 * zx_raw_raw_digest() expects an algorithm object instead of a string.
 * Returns 0 on failure or length of the digest on success.  */

int zx_raw_raw_digest2(struct zx_ctx* c, char* md, const EVP_MD* evp_digest, int len, const char* s, int len2, const char* s2)
{
  char* where = "a";
  EVP_MD_CTX* mdctx;
  unsigned int mdlen;
  mdctx = EVP_MD_CTX_create();
    
  if (!EVP_DigestInit_ex(mdctx, evp_digest, 0 /* engine */)) {
    where = "EVP_DigestInit_ex()";
    goto sslerr;
  }
  
  if (len && s) {
    if (!EVP_DigestUpdate(mdctx, s, len)) {
      where = "EVP_DigestUpdate()";
      goto sslerr;
    }
  }
  
  if (len2 && s2) {
    if (!EVP_DigestUpdate(mdctx, s2, len2)) {
      where = "EVP_DigestUpdate() 2";
      goto sslerr;
    }
  }
  
  if(!EVP_DigestFinal_ex(mdctx, (unsigned char*)md, &mdlen)) {
    where = "EVP_DigestFinal_ex()";
    goto sslerr;
  }
  EVP_MD_CTX_destroy(mdctx);
  return mdlen;

 sslerr:
  zx_report_openssl_err(where);
  EVP_MD_CTX_destroy(mdctx);
  return 0;
}

int zx_raw_digest2(struct zx_ctx* c, char* md, const char* algo, int len, const char* s, int len2, const char* s2)
{
  const EVP_MD* evp_digest;
  OpenSSL_add_all_digests();
  evp_digest = EVP_get_digestbyname(algo);
  return zx_raw_raw_digest2(c, md, evp_digest, len, s, len2, s2);
}

/*() zx_EVP_DecryptFinal_ex() is a drop-in replacement for OpenSSL EVP_DecryptFinal_ex.
 * It performs XML Enc compatible padding check.  See OpenSSL bug 1067
 * http://rt.openssl.org/Ticket/Display.html?user=guest&;pass=guest&id=1067 */

/* Called by:  zx_raw_cipher */
int zx_EVP_DecryptFinal_ex(EVP_CIPHER_CTX *ctx, unsigned char *out, int *outl) {
  int i,n;
  unsigned int b;
  
  *outl=0;
  b=ctx->cipher->block_size;
  if (b > 1) {
    if (ctx->buf_len || !ctx->final_used) {
      //EVPerr(EVP_F_EVP_DECRYPTFINAL_EX,EVP_R_WRONG_FINAL_BLOCK_LENGTH);
      return(0);
    }
    ASSERTOPI(b, <=, sizeof ctx->final);
    n=ctx->final[b-1];
    if (n == 0 || n > (int)b) {
      //EVPerr(EVP_F_EVP_DECRYPTFINAL_EX,EVP_R_BAD_DECRYPT);
      return(0);
    }
      
    /* The padding used in XML Enc does not follow RFC 1423
     * and is not supported by OpenSSL. The last padding byte
     * is checked, but all other padding bytes are ignored
     * and trimmed.
     *
     * [XMLENC] D. Eastlake, ed., XML Encryption Syntax and
     * Processing, W3C Recommendation 10. Dec. 2002,
     * www.w3.org/TR/2002/REC-xmlenc-core-20021210">http://www.w3.org/TR/2002/REC-xmlenc-core-20021210 */
    if (ctx->final[b-1] != n) {
      //EVPerr(EVP_F_EVP_DECRYPTFINAL_EX,EVP_R_BAD_DECRYPT);
      return(0);
    }
    n=ctx->cipher->block_size-n;
    for (i=0; i<n; i++)
      out[i]=ctx->final[i];
    *outl=n;
  } else
    *outl=0;
  return 1;
}

//#define ZX_DEFAULT_IV "012345678901234567890123456789012345678901234567890123456789" /* 60 */
#define ZX_DEFAULT_IV   "ZX_DEFAULT_IV ZXID.ORG SAML 2.0 and Liberty ID-WSF by Sampo." /* 60 */

/*() zx_raw_cipher() can encrypt and decrypt, based on encflag, using symmetic cipher algo.
 * If encflag (==1) indicates encryption, the initialization vector will be prepended. */

/* Called by:  zxenc_symkey_dec x4, zxenc_symkey_enc, zxid_psobj_dec, zxid_psobj_enc */
struct zx_str* zx_raw_cipher(struct zx_ctx* c, const char* algo, int encflag, struct zx_str* key, int len, const char* s, int iv_len, const char* iv)
{
  const char* ivv;
  char* where = "start";
  struct zx_str* out;
  int outlen=0, tmplen, alloclen;
  const EVP_CIPHER* evp_cipher;
  EVP_CIPHER_CTX ctx;
  OpenSSL_add_all_algorithms();
  if ((errmac_debug&ERRMAC_DEBUG_MASK) > 2) hexdmp("plain  ", s, len, 256);  
  D("len=%d s=%p", len, s);
  EVP_CIPHER_CTX_init(&ctx);
  evp_cipher = EVP_get_cipherbyname(algo);
  if (!evp_cipher) {
    ERR("Cipher algo name(%s) not recognized by the crypto library (OpenSSL)", algo);
    return 0;
  }
  
  tmplen = EVP_CIPHER_iv_length(evp_cipher);
  if (tmplen) {
    if (iv) {
      if (iv_len != tmplen) {
	ERR("iv len=%d does not match one required by cipher=%d", iv_len, tmplen);
	goto clean;
      }
      ivv = iv;
    } else {
      iv_len = tmplen;
      ivv = ZX_DEFAULT_IV;
      ASSERTOPI(EVP_MAX_IV_LENGTH, <=, sizeof(ZX_DEFAULT_IV));
    }
    if ((errmac_debug&ERRMAC_DEBUG_MASK) > 2) hexdmp("iv     ", ivv, iv_len, 1024);
  } else
    ivv = 0;
  if ((errmac_debug&ERRMAC_DEBUG_MASK) > 2) hexdmp("symkey ", key->s, key->len, 1024);
  
#if 0
  alloclen = EVP_CIPHER_block_size(evp_cipher);
  alloclen = len + alloclen + alloclen;  /* bit pessimistic, but man EVP_CipherInit is ambiguous about the actual size needed. */
#else
  /* 20150606, it appears aes-256-gcm reports too short block size, thus we impose a minimum. */
  alloclen = EVP_CIPHER_block_size(evp_cipher);
  D("block_size=%d", alloclen);
  alloclen = MAX(alloclen, 256);
  alloclen = len + alloclen + alloclen;  /* bit pessimistic, but man EVP_CipherInit is ambiguous about the actual size needed. */
#endif
  if (encflag)
    alloclen += iv_len;
  
  out = zx_new_len_str(c, alloclen);
  D("alloclen=%d iv_len=%d encflag=%d out=%p iv=%p", alloclen, iv_len, encflag, out, iv);
  if (!out) goto clean;
  if (encflag)
    memcpy(out->s, ivv, iv_len);
  else
    iv_len = 0;  /* When decrypting, the iv has already been stripped. */
    
  if (!EVP_CipherInit_ex(&ctx, evp_cipher, 0 /* engine */, (unsigned char*)key->s, (unsigned char*)ivv, encflag)) {
    where = "EVP_CipherInit_ex()";
    goto sslerr;
  }
  
  if (!EVP_CIPHER_CTX_set_key_length(&ctx, key->len)) {
    D("key->len=%d", key->len);
    where = "wrong key length for algorithm (block ciphers only accept keys of determined length)";
    goto sslerr;
  }
  
  if (!EVP_CipherUpdate(&ctx, (unsigned char*)out->s + iv_len, &outlen, (unsigned char*)s, len)) { /* Actual crypto happens here */
    D("len=%d s=%p iv_len=%d outlen=%d out->s=%p", len, s, iv_len, outlen, out->s);
    where = "EVP_CipherUpdate()";
    goto sslerr;
  }
  
  ASSERTOPI(outlen + iv_len, <=, alloclen);

#if 0  
  if(!EVP_CipherFinal_ex(&ctx, (unsigned char*)out->s + iv_len + outlen, &tmplen)) {  /* Append final block */
    where = "EVP_CipherFinal_ex()";
    goto sslerr;
  }
#else
  /* Patch from Eric Rybski <rybskej@yahoo.com> */
  if (encflag) {
    if(!EVP_CipherFinal_ex(&ctx, (unsigned char*)out->s + iv_len + outlen, &tmplen)) { /* Append final block */
      where = "EVP_CipherFinal_ex()";
      goto sslerr;
    }
  } else {
    /* Perform our own padding check, as XML Enc is not guaranteed compatible
     * with OpenSSL & RFC 1423. See OpenSSL bug 1067
     * http://rt.openssl.org/Ticket/Display.html?user=guest&;pass=guest&id=1067 */
    EVP_CIPHER_CTX_set_padding(&ctx, 0);
    if(!zx_EVP_DecryptFinal_ex(&ctx, (unsigned char*)out->s + iv_len + outlen, &tmplen)) { /* Append final block */
      where = "zx_EVP_DecryptFinal_ex()";
      goto sslerr;
    }
  }
#endif
  EVP_CIPHER_CTX_cleanup(&ctx);
  
  outlen += tmplen;
  ASSERTOPI(outlen + iv_len, <=, alloclen);
  out->len = outlen + iv_len;
  out->s[outlen + iv_len] = 0;  /* nul term */
  if ((errmac_debug&ERRMAC_DEBUG_MASK) > 2) hexdmp("cipher ", out->s, out->len, 256);  
  return out;

 sslerr:
  D("where(%s)", where);
  zx_report_openssl_err(where);
 clean:
  EVP_CIPHER_CTX_cleanup(&ctx);
  return 0;
}

/*() RSA public key encryption. See zx_get_rsa_pub_from_cert() for
 * a way to obtain public key data structure.
 * N.B. This function +only+ does the public key part. It does not
 * perform combined enc-session-key-with-pub-key-and-then-data-with-session-key
 * operation, though this function could be used as a component to implement
 * such a system.
 *
 * This is considered a low level function. See zxenc_pubkey_enc() for a higher level solution. */

/* Called by:  zxenc_pubkey_enc x2 */
struct zx_str* zx_rsa_pub_enc(struct zx_ctx* c, struct zx_str* plain, RSA* rsa_pkey, int pad)
{
  struct zx_str* ciphered;
  int ret, siz = RSA_size(rsa_pkey);

  if ((errmac_debug&ERRMAC_DEBUG_MASK) > 2) {
    D("pad=%d, RSA public key follows...", pad);
    RSA_print_fp(ERRMAC_DEBUG_LOG, rsa_pkey, 0);
  }

  switch (pad) {
  case RSA_PKCS1_PADDING:
  case RSA_SSLV23_PADDING:
    if (plain->len > (siz-11))
      ERR("Too much data for RSA key: can=%d, you have %d bytes.\n", siz-11, plain->len);
    WARN("RSA_PKCS1_PADDING %d v1.5: WARNING: This padding is vulnearable to attacks. Use OAEP instead.", pad);
    /* See paper: Tibor Jager, Kenneth G. Paterson, Juraj Somorovsky: "One Bad Apple: Backwards Compatibility Attacks on State-of-the-Art Cryptography", 2013 http://www.nds.ruhr-uni-bochum.de/research/publications/backwards-compatibility/ /t/BackwardsCompatibilityAttacks.pdf */
    break;
  case RSA_NO_PADDING:
    if (plain->len > siz)
      ERR("Too much data for RSA key: can=%d, you have %d bytes.\n", siz, plain->len);
    break;
  case RSA_PKCS1_OAEP_PADDING:
    if (plain->len > (siz-41))
      ERR("Too much data for RSA key: can=%d, you have %d bytes.\n", siz-41, plain->len);
    break;
  default: D("Illegal padding(%d). See `man 3 rsa'\n",pad);
  }

  ciphered = zx_new_len_str(c, siz);
  if (!ciphered)
    return 0;
  ret = RSA_public_encrypt(plain->len, (unsigned char*)plain->s, (unsigned char*)ciphered->s, rsa_pkey, pad);
  if (siz != ret) {
    D("RSA pub enc wrong ret=%d siz=%d\n",ret,siz);
    zx_report_openssl_err("zx_pub_encrypt_rsa fail (${ret})");
    return 0;
  }
  ASSERTOPI(ret, <=, siz);
  ciphered->len = ret;
  ciphered->s[ret] = 0;
  return ciphered;
}

/*() RSA public key decryption. See zx_get_rsa_pub_from_cert() for
 * a way to obtain public key data structure. */

/* Called by: */
struct zx_str* zx_rsa_pub_dec(struct zx_ctx* c, struct zx_str* ciphered, RSA* rsa_pkey, int pad)
{
  struct zx_str* plain;
  int ret, siz = RSA_size(rsa_pkey);
  plain = zx_new_len_str(c, siz);
  if (!plain)
    return 0;
  if ((errmac_debug&ERRMAC_DEBUG_MASK) > 2) {
    D("pad=%d, RSA public key follows...", pad);
    RSA_print_fp(ERRMAC_DEBUG_LOG, rsa_pkey, 0);
  }
  ret = RSA_public_decrypt(ciphered->len, (unsigned char*)ciphered->s, (unsigned char*)plain->s, rsa_pkey, pad);
  if (ret == -1) {
    D("RSA public decrypt failed ret=%d len_cipher_data=%d",ret,ciphered->len);
    zx_report_openssl_err("zx_public_decrypt_rsa fail");
    return 0;
  }
  ASSERTOPI(ret, <=, siz);
  plain->len = ret;
  plain->s[ret] = 0;
  return plain;
}

/*() RSA private key decryption. See zxid_read_private_key() and zxid_extract_private_key()
 * for ways to read in the private key data structure.
 * N.B. This function +only+ does the private key part. It does not
 * perform combined dec-session-key-with-priv-key-and-then-data-with-session-key
 * operation, though this function could be used as a component to implement
 * such a system.
 *
 * This is considered a low level function. See zxenc_privkey_dec() for a higher level solution. */

/* Called by:  zxenc_privkey_dec x2 */
struct zx_str* zx_rsa_priv_dec(struct zx_ctx* c, struct zx_str* ciphered, RSA* rsa_pkey, int pad)
{
  struct zx_str* plain;
  int ret, siz = RSA_size(rsa_pkey);
  plain = zx_new_len_str(c, siz);
  if (!plain)
    return 0;
  if ((errmac_debug&ERRMAC_DEBUG_MASK) > 2) {
    D("pad=%d, RSA private key follows...", pad);
    RSA_print_fp(ERRMAC_DEBUG_LOG, rsa_pkey, 0);
  }
  ret = RSA_private_decrypt(ciphered->len, (unsigned char*)ciphered->s, (unsigned char*)plain->s, rsa_pkey, pad);
  if (ret == -1) {
    D("RSA private decrypt failed ret=%d len_cipher_data=%d",ret,ciphered->len);
    zx_report_openssl_err("zx_priv_decrypt_rsa fail");
    return 0;
  }
  ASSERTOPI(ret, <=, siz);
  plain->len = ret;
  plain->s[ret] = 0;
  return plain;
}

/*() RSA private key encryption. See zxid_read_private_key() and zxid_extract_private_key()
 * for ways to read in the private key data structure. */

/* Called by: */
struct zx_str* zx_rsa_priv_enc(struct zx_ctx* c, struct zx_str* plain, RSA* rsa_pkey, int pad)
{
  struct zx_str* ciphered;
  int ret, siz = RSA_size(rsa_pkey);
  ciphered = zx_new_len_str(c, siz);
  if (!ciphered)
    return 0;
  if ((errmac_debug&ERRMAC_DEBUG_MASK) > 2) {
    D("pad=%d, RSA private key follows...", pad);
    RSA_print_fp(ERRMAC_DEBUG_LOG, rsa_pkey, 0);
  }
  ret = RSA_private_encrypt(plain->len, (unsigned char*)plain->s, (unsigned char*)ciphered->s, rsa_pkey, pad);
  if (ret == -1) {
    D("RSA private encrypt failed ret=%d len_plain=%d", ret, plain->len);
    zx_report_openssl_err("zx_priv_encrypt_rsa fail");
    return 0;
  }
  ASSERTOPI(ret, <=, siz);
  ciphered->len = ret;
  ciphered->s[ret] = 0;
  return ciphered;
}

/*() Obtain RSA public key from X509 certificate. The certificate must have been
 * previously read into a data structure. See zxid_read_cert() and zxid_extract_cert() */

/* Called by:  zxenc_pubkey_enc, zxlog_write_line */
RSA* zx_get_rsa_pub_from_cert(X509* cert, char* logkey)
{
  EVP_PKEY* evp_pkey;
  struct rsa_st* rsa_pkey;
  evp_pkey = X509_get_pubkey(cert);
  if (!evp_pkey) {
    ERR("RSA enc: failed to get public key from certificate (perhaps you have not supplied any certificate, or it is corrupt or of wrong type) %s", logkey);
    zx_report_openssl_err("zx_get_rsa_pub_from_cert");
    return 0;
  }
  rsa_pkey = EVP_PKEY_get1_RSA(evp_pkey);
  if (!rsa_pkey) {
    ERR("RSA enc: failed to extract RSA get public key from certificate (perhaps you have not supplied any certificate, or it is corrupt or of wrong type) %s", logkey);
    zx_report_openssl_err("zx_get_rsa_pub_from_cert");
    return 0;
  }
  return rsa_pkey;
}

/*() ZXID centralized hook for obtaning random numbers. This backends to
 * OpenSSL random number gnerator and seeds from /dev/urandom where
 * available. If you want to use /dev/random, which may block, you need
 * to recompile with ZXID_TRUE_RAND set to true. */

/* Called by: */
void zx_rand(char* buf, int n_bytes)
{
#ifdef USE_OPENSSL
#if ZXID_TRUE_RAND
  RAND_bytes(buf, n_bytes);
#else
  RAND_pseudo_bytes((unsigned char*)buf, n_bytes);
#endif
#else
  ERR("ZXID was compiled without USE_OPENSSL. This means random number generation facilities are unavailable. Recompile ZXID or acknowledge that there is no security. n_rand_bytes=%d", n);
#endif
}

/* Called by:  zxid_mk_at_cert x10, zxid_mk_self_sig_cert x7 */
static void zxid_add_name_field(X509_NAME* subj, int typ, int nid, char* val)
{
  X509_NAME_ENTRY* ne;
  if (!val || !*val)
    return;
  ne = X509_NAME_ENTRY_create_by_NID(0, nid, typ, (unsigned char*)val, strlen(val));
  X509_NAME_add_entry(subj, ne, X509_NAME_entry_count(subj), 0);
}

/*() Create Self-Signed Certificate-Private Key pair and Certificate Signing Request
 * This function is invoked when AUTO_CERT is set and a certificate is missing.
 * As this is not expected to be frequent, we are cavalier about releasing
 * the memory needed for each intermediate step.
 *
 * cf:: zxid configuration object, of which cf->ctx will be used for memory allocation
 * buflen:: sizeof(buf)
 * buf:: Buffer used for rendering pem representations of the certificate
 * log key:: Who and why is calling
 * name:: Name of the certificate file to be created
 * returns:: 0 on failure, 1 on success
 *
 * See also: keygen() in keygen.c */

/* Called by: */
int zxid_mk_self_sig_cert(zxid_conf* cf, int buflen, char* buf, const char* lk, const char* name)
{
#ifdef USE_OPENSSL
  BIO* wbio_cert;
  BIO* wbio_pkey;
  BIO* wbio_csr;
  int len, lenq, um;
  long cert_ser;
  char*     p;
  char*     q;
  time_t    ts;
  X509*     x509ss;
  X509_REQ* req;
  X509_REQ_INFO* ri;
  EVP_PKEY* pkey;
  EVP_PKEY* tmp_pkey;
  RSA*      rsa;
  X509_EXTENSION*  ext;
  char      cn[256];
  char      ou[256];

  X509V3_add_standard_extensions();
  
  D("keygen start lk(%s) name(%s)", lk, name);

  p = strstr(cf->burl, "://");
  if (p) {
    p += sizeof("://")-1;
    len = strcspn(p, ":/");
    if (len > sizeof(cn)-2)
      len = sizeof(cn)-2;
    memcpy(cn, p, len);
    cn[len] = 0;
  } else {
    strcpy(cn, "Unknown server cn. Misconfiguration.");
  }

#if 0
  /* On some CAs the OU can not exceed 30 chars  2         3
   *                          123456789012345678901234567890 */
  snprintf(ou, sizeof(ou)-1, "SSO Dept ZXID Auto-Cert %s", cf->burl);
#else
  snprintf(ou, sizeof(ou)-1, "SSO Dept ZXID Auto-Cert");
#endif
  ou[sizeof(ou)-1] = 0;  /* must terminate manually as on win32 termination is not guaranteed */

  ts = time(0);
  RAND_seed(&ts,sizeof(ts));
#ifdef WINDOWS
  RAND_screen(); /* Loading video display memory into random state */
#endif
  
  /* Here's the beef: Generate keypair */
  
  pkey=EVP_PKEY_new();
  DD("keygen preparing rsa key %s", lk);
#if 0
  rsa = RSA_generate_key(1024 /*bits*/, 0x10001 /*65537*/, 0 /*req_cb*/, 0 /*arg*/);
#else
  /* Crypto analysis (2015) suggests 1024bit key is too weak. */
  rsa = RSA_generate_key(2048 /*bits*/, 0x10001 /*65537*/, 0 /*req_cb*/, 0 /*arg*/);
#endif
  DD("keygen rsa key generated %s", name);
  EVP_PKEY_assign_RSA(pkey, rsa);

#if 0
  /* Key generation is a big operation. Write in the new random state. */
  t = time(0);
  RAND_seed(&t,sizeof(t));
  RAND_write_file(randomfile);
#endif

  /* Now handle the public key part, i.e. create self signed and
   * certificate request. This starts by making a request that
   * contains all relevant fields.   */
  
  req=X509_REQ_new();
  ri=req->req_info;

  DD("keygen populate: set version %d (real vers is one higher)", 2);
  ASN1_INTEGER_set(ri->version, 2L /* version 3 (binary value is one less) */);

#if 0 /* See cn code above */
  /* Parse domain name out of the URL: skip https:// and then scan name without port or path */
  
  for (p = cf->burl; !ONE_OF_2(*p, '/', 0); ++p) ;
  if (*p != '/') goto badurl;
  ++p;
  if (*p != '/') {
badurl:
    ERR("Malformed URL: does not start by https:// or http:// -- URL(%s)", cf->burl);
    return 0;
  }
  ++p;
  for (q = cn; !ONE_OF_3(*p, ':', '/', 0) && q < cn + sizeof(cn)-1; ++q, ++p) *q = *p;
  *q = 0;

  D("keygen populate DN: cn(%s) org(%s) c(%s) url=%p cn=%p p=%p q=%p", cn, cf->org_name, cf->country, cf->burl, cn, p, q);
#endif

  /* Note on string types and allowable char sets:
   * V_ASN1_PRINTABLESTRING  [A-Za-z0-9 '()+,-./:=?]   -- Any domain name, but not query string
   * V_ASN1_IA5STRING        Any 7bit string
   * V_ASN1_T61STRING        8bit string   */

  /* Construct DN part by part. We want cn=www.site.com,o=ZXID Auto-Cert */

  if (cf->contact_email)
    zxid_add_name_field(ri->subject, V_ASN1_IA5STRING, NID_pkcs9_emailAddress, cf->contact_email);
  zxid_add_name_field(ri->subject, V_ASN1_PRINTABLESTRING, NID_commonName, cn);
  zxid_add_name_field(ri->subject, V_ASN1_T61STRING, NID_organizationalUnitName, ou);
  zxid_add_name_field(ri->subject, V_ASN1_T61STRING, NID_organizationName, cf->org_name);

  zxid_add_name_field(ri->subject, V_ASN1_T61STRING, NID_localityName, cf->locality);
  zxid_add_name_field(ri->subject, V_ASN1_T61STRING, NID_stateOrProvinceName, cf->state);
  zxid_add_name_field(ri->subject, V_ASN1_T61STRING, NID_countryName, cf->country);

#if 0
  X509_ATTRIBUTE*  xa;
  ASN1_BIT_STRING* bs;
  ASN1_TYPE* at;

  /* It seems this gives indigestion to the default CA */
  DD("keygen populate attributes %s", lk);  /* Add attributes: we really only need cn */
  
  xa = X509_ATTRIBUTE_new();
  xa->value.set = sk_ASN1_TYPE_new_null();
  /*xa->single = 1; **** this may also be set on some versions */
  xa->object=OBJ_nid2obj(NID_commonName);

  bs = ASN1_BIT_STRING_new();
  bs->type = V_ASN1_PRINTABLESTRING;
  ASN1_STRING_set(bs, cn, strlen(cn)+1);  /* *** +1 why? Some archaic bug work-around? */

  at = ASN1_TYPE_new();
  ASN1_TYPE_set(at, bs->type, (char*)bs);
  sk_ASN1_TYPE_push(xa->value.set, at);
  sk_X509_ATTRIBUTE_push(ri->attributes, xa);
#endif

  DD("keygen request populated %s", lk);
  X509_REQ_set_pubkey(req, pkey);
  /*req->req_info->req_kludge=0;    / * no asn1 kludge *** filed deleted as of 0.9.7b?!? */
  
  DD("keygen signing request %s", lk);
#if 0
  X509_REQ_sign(req, pkey, EVP_md5());
#else
  /* Due to recent (2013) progress in crypto analysis, MD5 and SHA1 are considered
   * weak and support is likely to be discontinued in browsers and operating systems. */
  X509_REQ_sign(req, pkey, EVP_sha256());
#endif

  /* ----- X509 create self signed certificate ----- */
  
  DD("keygen making x509ss %s", lk);
  x509ss = X509_new();
  X509_set_version(x509ss, 2); /* Set version to V3 and serial number to zero */
  zx_rand((char*)&cert_ser, 4);
  ASN1_INTEGER_set(X509_get_serialNumber(x509ss), cert_ser);
  DD("keygen setting various x509ss fields %s", lk);
    
  X509_set_issuer_name(x509ss, X509_REQ_get_subject_name(req));
#if 1
  ASN1_TIME_set(X509_get_notBefore(x509ss),0);
  ASN1_TIME_set(X509_get_notAfter(x509ss), 0x7fffffffL); /* The end of the 32 bit Unix epoch */
#else
  X509_gmtime_adj(X509_get_notBefore(x509ss),0);
  X509_gmtime_adj(X509_get_notAfter(x509ss), 0x7fffffffL); /* The end of the 32 bit Unix epoch */
#endif
  X509_set_subject_name(x509ss,	X509_REQ_get_subject_name(req));
  
  DD("keygen setting x509ss pubkey %s", lk);
  tmp_pkey =X509_REQ_get_pubkey(req);
  X509_set_pubkey(x509ss, tmp_pkey);
  EVP_PKEY_free(tmp_pkey);
  
  /* Set up V3 context struct and add certificate extensions. Note
   * that we need to add (full) suite of CA extensions, otherwise
   * our cert is not valid for signing itself. */
  
  ext = X509V3_EXT_conf_nid(0, 0, NID_basic_constraints, "CA:TRUE,pathlen:3");
  X509_add_ext(x509ss, ext, -1);
  
  ext = X509V3_EXT_conf_nid(0, 0, NID_netscape_cert_type, "client,server,email,objsign,sslCA,emailCA,objCA");
  X509_add_ext(x509ss, ext, -1);
  
  ext = X509V3_EXT_conf_nid(0, 0, NID_key_usage, "digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment,keyAgreement,keyCertSign,cRLSign");
  X509_add_ext(x509ss, ext, -1);

  ext = X509V3_EXT_conf_nid(0, 0, NID_netscape_comment, "Auto-Cert, see zxid.org");
  X509_add_ext(x509ss, ext, -1);
  
  DD("keygen signing x509ss %s", lk);
#if 0
  if (!(X509_sign(x509ss, pkey, EVP_md5())))
#else
  if (!(X509_sign(x509ss, pkey, EVP_sha256())))
#endif
  {
    ERR("Failed to sign x509ss %s", lk);
    zx_report_openssl_err("X509_sign");
    return 0;
  }
  DD("keygen x509ss ready %s", lk);

  /* ----- Output phase ----- */

  um = umask(0077);  /* Key material should be readable only by owner */

  wbio_csr = BIO_new(BIO_s_mem());
  DD("write_csr %s", lk);
  if (!PEM_write_bio_X509_REQ(wbio_csr, req)) {
    ERR("write_csr %s", lk);
    zx_report_openssl_err("write_csr");
    return 0;
  }
  len = BIO_get_mem_data(wbio_csr, &p);

  write_all_path("auto_cert csr", "%s" ZXID_PEM_DIR "csr-%s", cf->cpath, name, len, p);
  BIO_free_all(wbio_csr);

  /* Output combined self signed plus private key file. It is important
   * that this happens after csr so that buf is left with this data
   * so that the caller can then parse it. */

  wbio_cert = BIO_new(BIO_s_mem());
  DD("write_cert %s", lk);
  if (!PEM_write_bio_X509(wbio_cert, x509ss)) {
    ERR("write_cert %s", lk);
    zx_report_openssl_err("write_cert");
    return 0;
  }
  len = BIO_get_mem_data(wbio_cert, &p);

  wbio_pkey = BIO_new(BIO_s_mem());
  DD("write_private_key %s", lk);
  if (!PEM_write_bio_PrivateKey(wbio_pkey, pkey, 0,0,0,0,0)) {
    ERR("write_private_key %s", lk);
    zx_report_openssl_err("write_private_key");
    return 0;
  }
  lenq = BIO_get_mem_data(wbio_pkey, &q);

  write_all_path_fmt("auto_cert ss", buflen, buf,
		     "%s" ZXID_PEM_DIR "%s", cf->cpath, name,
		     "%.*s%.*s", len, p, lenq, q);

  BIO_free_all(wbio_cert);
  BIO_free_all(wbio_pkey);

  umask(um);

  EVP_PKEY_free(pkey);
  X509_REQ_free(req);
  X509_free(x509ss);
  X509V3_EXT_cleanup();
  OBJ_cleanup();

  zxlog(cf, 0, 0, 0, 0, 0, 0, 0, 0, "K", "KEYGEN", name, 0);
  D("keygen done. %s", lk);
  return 1;
#else
  ERR("ZXID was compiled without USE_OPENSSL. This means self signed certificate generation facility is unavailable. Recompile ZXID. %s", lk);
  return 0;
#endif
}

#if 0
/* use PEM_write_X509(fp, cert) instead! */
/* Called by: */
void zx_print_X509(FILE* fp, X509* cert)
{
  int len;
  char* p;
  BIO* wbio_cert = BIO_new(BIO_s_mem());
  if (!PEM_write_bio_X509(wbio_cert, peer_cert)) {
    ERR("write_cert %p", peer_cert);
    zx_report_openssl_err("write_cert");
    return;
  }
  len = BIO_get_mem_data(wbio_cert, &p);
  fprintf(fp, "%.*s", len, p);
}
#endif

/*

A Practical Approach of X.509 Attribute Certificate Framework as Support to Obtain Privilege Delegation
Jose A. Montenegro and Fernando Moya
Computer Science Department, E.T.S. Ingenieria Informatica, Universidad de Malage, Spain
Lecture Notes in Computer Science, 2004, Volume 3093/2004, 624, DOI: 10.1007/978-3-540-25980-0_13 

 Abstract This work introduces a particular implementation of the
X.509 Attribute Certificate framework (Xac), presented in the ITU-T
Recommendation. The implementation is based on the use of the Openssl
library, that we have chosen for its advantages in comparison with
other libraries. The paper also describes how the implementation is
middleware-oriented, focusing on the delegation model specified by
ITU-T proposal, and taking into consideration the ETSI report about
Xac.

RFC3281
http://tools.ietf.org/html/draft-ietf-pkix-3281update-05

*/

/*() Create X509 attribute certificate for one attribute and user specified by nameid (pseudonym)
 *
 * cf:: zxid configuration object, of which cf->ctx will be used for memory allocation
 * buflen:: sizeof(buf)
 * buf:: Buffer used for rendering pem representation of the certificate
 * log key:: Who and why is calling
 * nameid:: Name of the subject
 * name:: Name of the attribute in certificate
 * val:: Value of the attribute in certificate
 * returns:: 0 on failure, 1 on success
 */

/* Called by:  x509_test, zxid_map_val_ss */
int zxid_mk_at_cert(zxid_conf* cf, int buflen, char* buf, const char* lk, zxid_nid* nameid, const char* name, struct zx_str* val)
{
#ifdef USE_OPENSSL
  BIO*   wbio_cert;
  int    len;
  long   cert_ser;
  char*  p;
  time_t ts;
  X509*  x509ss;
  X509_NAME* issuer;
  X509_NAME* subject;
  X509_EXTENSION*  ext;
  X509*  sign_cert;
  EVP_PKEY* sign_pkey;
  char   cn[256];
  char   ou[256];

  X509V3_add_standard_extensions();
  
  D("keygen start lk(%s) name(%s)", lk, name);

  p = strstr(cf->burl, "://");
  if (p) {
    p += sizeof("://")-1;
    len = strcspn(p, ":/");
    if (len > sizeof(cn)-2)
      len = sizeof(cn)-2;
    memcpy(cn, p, len);
    cn[len] = 0;
  } else {
    strcpy(cn, "Unknown server cn. Misconfiguration.");
  }
  
  snprintf(ou, sizeof(ou)-1, "SSO Dept ZXID Auto-Cert %s", cf->burl);
  ou[sizeof(ou)-1] = 0;  /* must terminate manually as on win32 termination is not guaranteed */

  ts = time(0);
  RAND_seed(&ts,sizeof(ts));
#ifdef WINDOWS
  RAND_screen(); /* Loading video display memory into random state */
#endif
  
  //ASN1_INTEGER_set(ri->version, 2L /* version 3 (binary value is one less) */);
  
  /* Note on string types and allowable char sets:
   * V_ASN1_PRINTABLESTRING  [A-Za-z0-9 '()+,-./:=?]   -- Any domain name, but not query string
   * V_ASN1_IA5STRING        Any 7bit string
   * V_ASN1_T61STRING        8bit string   */

  issuer = X509_NAME_new();
  subject = X509_NAME_new();  

  /* Construct DN part by part. We want cn=www.site.com,o=ZXID Auto-Cert */

  zxid_add_name_field(issuer, V_ASN1_PRINTABLESTRING, NID_commonName, cn);
  zxid_add_name_field(issuer, V_ASN1_T61STRING, NID_organizationalUnitName, ou);
  zxid_add_name_field(issuer, V_ASN1_T61STRING, NID_organizationName, cf->org_name);

  zxid_add_name_field(issuer, V_ASN1_T61STRING, NID_localityName, cf->locality);
  zxid_add_name_field(issuer, V_ASN1_T61STRING, NID_stateOrProvinceName, cf->state);
  zxid_add_name_field(issuer, V_ASN1_T61STRING, NID_countryName, cf->country);

  /* Construct Subject part by part. */

  if (nameid) {
    zxid_add_name_field(subject, V_ASN1_PRINTABLESTRING, NID_commonName,
			zx_str_to_c(cf->ctx, ZX_GET_CONTENT(nameid)));
    zxid_add_name_field(subject, V_ASN1_T61STRING, NID_organizationalUnitName,
			zx_str_to_c(cf->ctx, &nameid->SPNameQualifier->g));  /* SP */
    zxid_add_name_field(subject, V_ASN1_T61STRING, NID_organizationName,
			zx_str_to_c(cf->ctx, &nameid->NameQualifier->g));    /* IdP */
  } else {
    zxid_add_name_field(subject, V_ASN1_PRINTABLESTRING, NID_commonName, "unspecified-see-zxid_mk_at_cert");
  }

  /* ----- Create X509 certificate ----- */
  
  x509ss = X509_new();
  X509_set_version(x509ss, 2); /* Set version to V3 and serial number to zero */
  zx_rand((char*)&cert_ser, 4);
  ASN1_INTEGER_set(X509_get_serialNumber(x509ss), cert_ser);
  
  X509_set_issuer_name(x509ss, issuer);
#if 1
  ASN1_TIME_set(X509_get_notBefore(x509ss),0);
  ASN1_TIME_set(X509_get_notAfter(x509ss), 0x7fffffffL); /* The end of the 32 bit Unix epoch */
#else
  X509_gmtime_adj(X509_get_notBefore(x509ss),0);
  X509_gmtime_adj(X509_get_notAfter(x509ss), 0x7fffffffL); /* The end of the 32 bit Unix epoch */
#endif
  X509_set_subject_name(x509ss,	subject);
  
#if 0 /* *** schedule to remove */  
  /* Set up V3 context struct and add certificate extensions. */
  
  ext = X509V3_EXT_conf_nid(0, 0, NID_basic_constraints, "CA:TRUE,pathlen:3");
  X509_add_ext(x509ss, ext, -1);
  
  ext = X509V3_EXT_conf_nid(0, 0, NID_netscape_cert_type, "client,server,email,objsign,sslCA,emailCA,objCA");
  X509_add_ext(x509ss, ext, -1);
  
  ext = X509V3_EXT_conf_nid(0, 0, NID_key_usage, "digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment,keyAgreement,keyCertSign,cRLSign");
  X509_add_ext(x509ss, ext, -1);
#endif

  ext = X509V3_EXT_conf_nid(0, 0, NID_netscape_comment, "Attribute cert, see zxid.org");
  X509_add_ext(x509ss, ext, -1);

#if 0
  X509_ATTRIBUTE*  xa;
  ASN1_BIT_STRING* bs;
  ASN1_TYPE* at;

  /* It seems this gives indigestion to the default CA */
  DD("keygen populate attributes %s", lk);  /* Add attributes: we really only need cn */
  
  xa = X509_ATTRIBUTE_new();
  xa->value.set = sk_ASN1_TYPE_new_null();
  /*xa->single = 1; **** this may also be set on some versions */
  xa->object=OBJ_nid2obj(NID_commonName);

  bs = ASN1_BIT_STRING_new();
  bs->type = V_ASN1_PRINTABLESTRING;
  ASN1_STRING_set(bs, cn, strlen(cn)+1);  /* *** +1 why? Some archaic bug work-around? */

  at = ASN1_TYPE_new();
  ASN1_TYPE_set(at, bs->type, (char*)bs);
  sk_ASN1_TYPE_push(xa->value.set, at);
  sk_X509_ATTRIBUTE_push(ri->attributes, xa);
  STACK_OF(X509_ATTRIBUTE) *X509at_add1_attr(STACK_OF(X509_ATTRIBUTE) **x, X509_ATTRIBUTE *attr);

  /* *** Exactly where on x509ss are the attributes supposed to attach?!? */
#endif
  
  zxid_lazy_load_sign_cert_and_pkey(cf, &sign_cert, &sign_pkey, "mk_at_cert");

  DD("keygen signing x509ss %s", lk);
#if 0
  if (!(X509_sign(x509ss, sign_pkey, EVP_md5())))
#else
  if (!(X509_sign(x509ss, sign_pkey, EVP_sha256())))
#endif
  {
    ERR("Failed to sign x509ss %s", lk);
    zx_report_openssl_err("X509_sign");
    return 0;
  }
  DD("keygen x509ss ready %s", lk);

  /* ----- Output phase ----- */

  wbio_cert = BIO_new(BIO_s_mem());
  DD("write_cert %s", lk);
  if (!PEM_write_bio_X509(wbio_cert, x509ss)) {
    ERR("write_cert %s", lk);
    zx_report_openssl_err("write_cert");
    return 0;
  }
  len = BIO_get_mem_data(wbio_cert, &p);
  memcpy(buf, p, MIN(len, buflen-1));
  buf[MIN(len, buflen-1)] = 0;

  //***write_all_path("auto_cert ss", "%s" ZXID_PEM_DIR "%s", cf->cpath, name, len, p);

  BIO_free_all(wbio_cert);

  X509_free(x509ss);
  X509V3_EXT_cleanup();
  OBJ_cleanup();

  zxlog(cf, 0, 0, 0, 0, 0, 0, 0, 0, "K", "X509ATCERT", name, 0);
  D("at cert done. %s", lk);
  return 1;
#else
  ERR("ZXID was compiled without USE_OPENSSL. This means X509 attribute certificate generation facility is unavailable. Recompile ZXID. %s", lk);
  return 0;
#endif
}

/* Adapted by Sampo from FreeBSD md5_crypt.c, which is licensed as follows
 * ----------------------------------------------------------------------------
 * "THE BEER-WARE LICENSE" (Revision 42):
 * <phk@login.dknet.dk> wrote this file.  As long as you retain this notice you
 * can do whatever you want with this stuff. If we meet some day, and you think
 * this stuff is worth it, you can buy me a beer in return.   Poul-Henning Kamp
 * ----------------------------------------------------------------------------
 */

extern char pw_basis_64[64];

/* Called by:  add_password, zx_md5_crypt x6 */
static void to64(char *s, unsigned long v, int n) {
  while (--n >= 0) {
    *s++ = pw_basis_64[v & 0x3f];
    v >>= 6;
  }
}

/*() Compute MD5-Crypt password hash (starts by \$1\$)
 * 
 * pw:: Password in plain
 * salt:: 0-8 chars of salt. Preceding \$1\$ is automatically skipped. Salt ends in \$ or nul.
 * buf:: must be at least 120 chars
 * return:: buf, nul terminated */

/* Called by:  authn_user, main, zx_pw_chk */
char* zx_md5_crypt(const char* pw, const char* salt, char* buf)
{
  const char* magic = "$1$";    /* magic prefix to identify algo */
  char* p;
  const char *sp, *ep;
  unsigned char final[16];
  int sl, pl, i, j;
  MD5_CTX ctx, ctx1;
  unsigned long l;

  /* Refine the Salt first */
  sp = salt;
  
  /* If it starts with the magic string, then skip that */
  if (!strncmp(sp, magic, strlen(magic)))
    sp += strlen(magic);
  
  /* It stops at the first '$', max 8 chars */
  for (ep = sp; *ep && *ep != '$' && ep < (sp + 8); ep++) ;
  sl = ep - sp;  /* get the length of the true salt */
  
  MD5_Init(&ctx);
  MD5_Update(&ctx, (unsigned const char *)pw, strlen(pw));       /* pw 1st, as it's most unknown */
  MD5_Update(&ctx, (unsigned const char *)magic, strlen(magic)); /* Then our magic string */
  MD5_Update(&ctx, (unsigned const char *)sp, sl);               /* Then the raw salt */
  
  /* Then just as many characters of the MD5(pw,salt,pw) */
  MD5_Init(&ctx1);
  MD5_Update(&ctx1, (unsigned const char *)pw, strlen(pw));
  MD5_Update(&ctx1, (unsigned const char *)sp, sl);
  MD5_Update(&ctx1, (unsigned const char *)pw, strlen(pw));
  MD5_Final(final, &ctx1);
  for (pl = strlen(pw); pl > 0; pl -= 16)
    MD5_Update(&ctx, (unsigned const char *)final, pl>16 ? 16 : pl);

  ZERO(final, sizeof(final)); /* Don't leave anything around in vm they could use. */
  
  /* Then something really weird... */
  for (j = 0, i = strlen(pw); i; i >>= 1)
    if (i & 1)
      MD5_Update(&ctx, (unsigned const char *)final+j, 1);
    else
      MD5_Update(&ctx, (unsigned const char *)pw+j, 1);
  
  strcpy(buf, magic);   /* Start the output string */
  strncat(buf, sp, sl);
  strcat(buf, "$");
  
  MD5_Final(final, &ctx);
  
  /* and now, just to make sure things don't run too fast
   * On a 60 Mhz Pentium this takes 34 msec, so you would
   * need 30 seconds to build a 1000 entry dictionary... */
  for (i = 0; i < 1000; i++) {
    MD5_Init(&ctx1);
    if (i & 1)
      MD5_Update(&ctx1, (unsigned const char *)pw, strlen(pw));
    else
      MD5_Update(&ctx1, (unsigned const char *)final, 16);
    
    if (i % 3)
      MD5_Update(&ctx1, (unsigned const char *)sp, sl);
    
    if (i % 7)
      MD5_Update(&ctx1, (unsigned const char *)pw, strlen(pw));
    
    if (i & 1)
      MD5_Update(&ctx1, (unsigned const char *)final, 16);
    else
      MD5_Update(&ctx1, (unsigned const char *)pw, strlen(pw));
    MD5_Final(final, &ctx1);
  }
  
  p = buf + strlen(buf);

  l = (final[0] << 16) | (final[6] << 8) | final[12];  to64(p, l, 4);  p += 4;
  l = (final[1] << 16) | (final[7] << 8) | final[13];  to64(p, l, 4);  p += 4;
  l = (final[2] << 16) | (final[8] << 8) | final[14];  to64(p, l, 4);  p += 4;
  l = (final[3] << 16) | (final[9] << 8) | final[15];  to64(p, l, 4);  p += 4;
  l = (final[4] << 16) | (final[10] << 8) | final[5];  to64(p, l, 4);  p += 4;
  l = final[11];                                       to64(p, l, 2);  p += 2;
  *p = '\0';

  ZERO(final, sizeof(final)); /* Don't leave anything around in vm they could use. */
  return buf;
}

/* EOF  -  zxcrypto.c */
