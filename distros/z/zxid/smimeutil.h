/* smimeutil.h  -  Utility functions for performing S/MIME signatures
 *                 and encryption.
 *
 * Copyright (c) 1999 Sampo Kellomaki <sampo@iki.fi>, All Rights Reserved.
 * License: This software may be distributed under the same license
 *          terms as openssl (i.e. free, but mandatory attribution).
 *
 * Official web site:  http://www.bacus.pt/Net_SSLeay/smime.html
 * $Id: smimeutil.h,v 1.1 2009-08-30 15:09:26 sampo Exp $
 *
 * 11.9.1999, Created. --Sampo
 * 1.10.1999, added error codes. --Sampo
 * 5.10.1999, split interface to character based PEM interface (old) and
 *            data structure based internal interface. --Sampo
 * 29.10.1999, added prototypes for certification authority. --Sampo
 *
 * This module has been developed to support a Lingo XTRA that is supposed
 * to provide crypto functionality. It may, however, be useful for other
 * purposes as well. See also smime.c for command line tool.
 *
 * Memory management: most routines malloc the results. Freeing them
 * is application's responsibility. I use libc malloc, but if in doubt
 * it might be safer to just leak the memory (i.e. don't ever free
 * it). The library never attempts to free arguments passed to it
 * (i.e. you can safely pass in pointers to buffers on stack or
 * string constants).
 *
 * ERROR HANDLING
 *
 * Most library functions return NULL (pointer) or -1 (length) upon
 * error.  If you want to know in more detail what happened you should
 * call smime_get_errors() function. Most error messages are
 * meaningless to an average application and its user. Meaningful
 * error messages start by two digit number. Any message not starting
 * by number should be assumed to be (in this order)
 *   - lack of memory ("no memory?" is a strong indication of this, but
 *     could also mean that the malloc arena has been corrupted, beware!)
 *   - application passed in bad arguments (application programmer error)
 *   - internal library error (library programmer error or OpenSSL error)
 *
 * These meaningful error codes exist
 *   01  bad private key file or password, private key couldn't be
 *       decrypted (wrong file? bad line endings?)
 *   02  bad PKCS12 file format (perhaps wrong file? corrupt file?)
 *   03  bad PKCS12 import password
 *   04  bad X509_REQ (pem)file format (perhaps wrong file or bad line endings)
 *   05  mismatched X509 certificate and private key (wrong files?)
 *   06  bad DN component name (must be one of the registered ones)
 *   07  bad attribute name (must be one of the registered ones)
 *   08  bad characters in DN or attribute value
 *   09  missing `=' in DN component or attribute value specification or
 *       specification otherwise badly formatted (perhaps missing newlines?)
 *   10  bad X509_REQ (pem)file format (perhaps wrong file or bad line endings)
 *   11  corrupt p7m message (perhaps whitespace or newlines were added)
 *   12  message decryption failed. Either message was not encrypted
 *       for the recipient as indicated by certificate (issuer and serial
 *       number fields do not match recipient info) or private key
 *       could not open the encryption, i.e. wrong private key. Could
 *       also indicate sophisticated message corruption.
 *   13  No signatures found in signature blob. Perhaps its corrupt or
 *       is really encrypted blob instead.
 *   14  signature did not verify. Check for message corruption or
 *       unexpected white space (esp. if message was clear signed)
 *   15  signed entity did not contain any signed data (corrupt entity?)
 *   16  missing mime header, e.g. Content-type: multipart/...
 *
 */

#ifndef _SMIMEUTIL_H
#define _SMIMEUTIL_H
#ifdef __cplusplus
extern "C" {
#endif

#define SMIME_VERSION "smimeutils v0.7 17.11.1999"

#include <stdio.h>  /* snprintf() */
#if defined(SMIME_INTERNALS) && !defined(__DIRECTORYSCRIPT__)
# include <openssl/bio.h>
# include <openssl/x509.h>
# include <openssl/evp.h>
# include <openssl/pkcs12.h>
#endif

#ifndef DSEXPORT
#define DSEXPORT
#endif

/* ======= M I M E   M U L T I P A R T   M A N I P U L A T I O N ======= */

/* Create MIME multipart/mixed mime entity containing some text and
 * then up to 3 attachmets. All attachments are base64 encoded so they
 * can be binary if needed. */

DSEXPORT char*
mime_mk_multipart(const char* text,
	  const char* file1, int len1, const char* type1, const char* name1,
	  const char* file2, int len2, const char* type2, const char* name2,
	  const char* file3, int len3, const char* type3, const char* name3);

/* Create multipart/signed entity (given that detached sig already exists,
 * see also smime_clear_sign()) */

DSEXPORT char*  /* returns smime encoded clear sig blob, or NULL if error */
smime_mk_multipart_signed(const char* mime_entity, const char* sig_entity);

/* Finds boundary marker from `Content-type: multipart/...; boundary=sep'
 * header and splits the multiparts into array parts. Lengths of each
 * part go to lengths array. If parts is NULL, just returns the number
 * of parts found. Memory for each part is obtained from Malloc. Only
 * one level of multipart encoding is interpretted, i.e. if one of the
 * contained parts happens to be a multipart, it needs to be separately
 * interpretted on a second pass.
 *
 * *** WARNING: this is not totally robust and mime compliant, improvements
 *              welcome. --Sampo
 */

DSEXPORT int  /* returns number of parts, -1 on error */
mime_split_multipart(const char* entity,
		     int max_parts,  /* how big following arrays are */
		     char* parts[],  /* NULL --> just count the parts */
		     int lengths[]);

/* Add headers */

DSEXPORT char* mime_raw_entity(const char* text, const char* type);

/* Apply base64 and add headers */

DSEXPORT char* mime_base64_entity(const char* data, int len, const char* type);

/* CR->CRLF (Mac) and LF->CRLF (Unix) conversion */

DSEXPORT char* mime_canon(const char* s);

/* ============= S I G N I N G   &   E N C R Y P T I O N ============= */

/* Typically signing and encryption involves a sequence of calls like
 *
 *  msg = smime_encrypt(pubkey,
 *           smime_clear_sign(privkey, password,
 *              mime_mk_multipart(text, file1, type1, name1,
 *                                      NULL,  NULL,  NULL,
 *                                      NULL,  NULL,  NULL)));
 */

/* Sign a mime entity, such as produced by mime_mk_multipart(). Signature
 * is stored as separate mime entity so the message proper stays visible.  */

DSEXPORT char*  /* Returns malloc'd buffer which caller must free. NULL on error */
smime_clear_sign(const char* privkey,
		 const char* password,
		 const char* mime_entity);

/* Sign a mime entity, such as produced by mime_mk_multipart(). Signature
 * and entity are output as one base64 blob so the entity is not trivially
 * visible. */

DSEXPORT char*  /* Returns malloc'd buffer which caller must free. NULL on error */
smime_sign(const char* privkey,
	   const char* password,
	   const char* mime_entity);

/* Encrypt a mime entity such as produced by smime_clear_sign(). */

DSEXPORT char*  /* Returns malloc'd buffer which caller must free. NULL on error */
smime_encrypt(const char* pubkey, const char* mime_entity);

/* ============= S I G N A T U R E   V E R I F I C A T I O N ==============*/
/* ============= A N D   D E C R Y P T I O N ============================= */

/* Typically receiver has to know in what order the signature and encryption
 * were applied (usually encryption is outermost) and then call these
 * functions in right order, e.g:
 */

DSEXPORT int  /* returns size of data, -1 on error */
smime_decrypt(const char* privkey,
	      const char* passwd,
	      const char* enc_entity,
	      char** data_out);

DSEXPORT long  /* return serial on success, -1 on failure */
smime_get_signer_info(const char* signed_entity,
		      int info_ix,      /* 0 = first signer. Used to iterate */
		      char** issuer);   /* DN of the issuer */

/* smime_verify_signature can be used to verify both signed entities
 * and clear signatures. In the first case you must pass NULL on
 * detached_data parameter. The contents of signed entity are malloc'd
 * and returned (i.e. you must free it). In the clear sig case, detached
 * data is returned without malloc. */

DSEXPORT char* /* returns contents of the signed message, NULL if error */
smime_verify_signature(const char* pubkey,
		       const char* sig_entity,     /* signed entity
						      or just the sigature */
		       const char* detached_data,  /* possibly NULL */
		       int detached_data_len);

DSEXPORT int  /* returns -1 if error, 0 if verfy fail, and 1 if verify OK */
smime_verify_cert(const char* ca_cert_pem, const char* cert_pem);

DSEXPORT char*  /* returns pem encoded certificate, or NULL if error */
smime_ca(const char* ca_id_pem,
	 const char* passwd,
	 const char* req_pem,
	 const char* start_date,
	 const char* end_date,
	 long serial,
	 const char* basic_constraints,
	 const char* cert_type,
	 const char* key_usage,
	 const char* comment);

/* ============= K E Y   G E N E R A T I O N ==============*/

/* char** values are out parameters. They return malloced values.
 * random is extra random number seed. passowrd is the password used
 * to encrypt the private key. identifiaction is a newline separated list
 * of attributes to include in certification request. Each line has
 * format: `name=value\n'
 */

DSEXPORT int
smime_keygen(const char* dn,      /* distinguished name  to include in cert */
	     const char* attr,    /* additional attributes to send */
	     const char* passwd,  /* password for encrypting the private key */
	     const char* comment, /* comment to include in self signed cert */
	     char** priv,         /* pem encoded private key */
	     char** x509ss,       /* pem encoded self signed cert */
	     char** request);     /* pem encoded certificate request */

/* Convert pem formatted certificate and private key into PKCS12
 * object suitable for importing to browsers.
 *
 * openssl pkcs12 -name "Test friendly name" -info -in cert.pem -inkey priv.pem -chain -export >pkcs12
 */

DSEXPORT int
smime_pem_to_pkcs12(const char* friendly_name,  /* e.g. foo@bar.com */
		    const char* x509_cert_pem,  /* must have only one */
		    const char* priv_key_pem,
		    const char* priv_passwd,    /* used to open private key */
		    const char* pkcs12_passwd,  /* used to encrypt pkcs12 */
		    char** pkcs12);

/* more generic version that allows inclusion of multiple certificates */

DSEXPORT int
smime_pem_to_pkcs12_generic(const char* friendly_name,  /* e.g. foo@bar.com */
			    const char* x509_certs_pem,  /* can have many */
		    const char* priv_key_pem,
		    const char* priv_passwd,    /* used to open private key */
		    const char* pkcs12_passwd,  /* used to encrypt pkcs12 */
		    char** pkcs12);

/* Extract certificate(s) and public key(s) from PKCS12 structure.
 * Can be used to extract only one or the other by passing NULL
 * to appropriate OUT parameter. Can only extract last private key
 * and last certificate (so beware if passing a certificate chain).
 *
 * openssl pkcs12 <foo.p12
 */

DSEXPORT int
smime_pkcs12_to_pem(const char* pkcs12, int pkcs12_len,
		    const char* pkcs12_passwd,  /* used to decrypt pkcs12 */
		    const char* priv_passwd,    /* used to enc. private key */
		    char** priv_key_pem,        /* OUT private key */
		    char** x509_cert_pem);      /* OUT certificate */

/* more generic because handles multiple certificates and private keys
   in key bags */

DSEXPORT int
smime_pkcs12_to_pem_generic(const char* pkcs12, int pkcs12_len,
		    const char* pkcs12_passwd,  /* used to decrypt pkcs12 */
		    const char* priv_passwd,    /* used to enc. private key */
		    char** priv_key_pem,        /* OUT private key(s) */
		    char** x509_cert_pem);      /* OUT certificate(s) */

/* Obtain some human readable descriptions of the certificate. This is
 * important, for example, to verify if two certificates have the same
 * public key modulus.
 */

DSEXPORT long  /* return serial number, -1 on failure */
smime_get_cert_info(const char* x509_cert_pem,
		    char** modulus,      /* public key modulus */
		    char** fingerprint); /* finger print that identifies */

DSEXPORT char* /* public key modulus */
smime_get_req_modulus(const char* request_pem);

/* Get distinguished name information from the certificate */

DSEXPORT long  /* return serial number, -1 on failure */
smime_get_cert_names(const char* x509_cert_pem,
		    char** subject_DN,   /* who the certificate belongs to */
		    char** issuer_DN);   /* who signed the certificate */

DSEXPORT char* /* subject_DN - who the request belongs to */
smime_get_req_name(const char* request_pem);

DSEXPORT char* /* string representation of some attributes */
smime_get_req_attr(const char* request_pem);

/* Calculate a hash over any string (I use it for modulus) */

DSEXPORT char*  /* returns the md5 hash as hex dump */
smime_md5(const char* modulus);

DSEXPORT char* /* 25 bit hash as string like `*Z4K67W*' or NULL if error */
smime_get_req_hash(const char* request_pem);

#ifdef SMIME_INTERNALS

/* These are binary versions of the above functions. Generally these
 * eat and return OpenSSL data structures instead of pem encodings. */

DSEXPORT PKCS12*
x509_and_pkey_to_pkcs12(const char* friendly_name,  /* e.g. foo@bar.com */
	      X509*       x509,           /* cert that goes with the pkey */
	      EVP_PKEY*   pkey,           /* private key */
	      const char* pkcs12_passwd); /* used to encrypt pkcs12 */

DSEXPORT int
pkcs12_to_x509_and_pkey(PKCS12* p12,
	      const char* pkcs12_passwd,  /* used to decrypt pkcs12 */
	      X509**      x509_out,       /* cert that goes with the pkey */
	      EVP_PKEY**  pkey_out);      /* private key */

DSEXPORT long  /* return serial number, -1 on failure */
get_cert_info(X509* x509,
	      char** modulus,       /* public key modulus */
	      char** fingerprint);  /* finger print that identifies */

DSEXPORT long  /* return serial number, -1 on failure */
get_cert_names(X509* x509,
	       char** subject_DN,   /* who the certificate belongs to */
	       char** issuer_DN);    /* who signed the certificate */

DSEXPORT char* /* public key modulus */
get_req_modulus(X509_REQ* req);

DSEXPORT char* /* subject_DN - who the request belongs to */
get_req_name(X509_REQ* req);

DSEXPORT char* /* new line separated list of attribute value pairs */
get_req_attr(X509_REQ* req);

DSEXPORT char*  /* hash, ready to print, or NULL if error */
get_req_hash(X509_REQ* req);

DSEXPORT char*  /* returns smime encoded clear signed blob, or NULL if error */
clear_sign(X509* x509, EVP_PKEY* pkey, const char* mime_entity);

DSEXPORT char*  /* returns smime blob, NULL if error */
sign(X509* x509, EVP_PKEY* pkey, const char* mime_entity);

DSEXPORT int  /* returns -1 if error, 0 if verfy fail, and 1 if verify OK */
verify_cert(X509* ca_cert, X509* cert);

DSEXPORT char* encrypt1(X509* x509, const char* mime_entity);

DSEXPORT int  /* return size of data, -1 on failure */
decrypt(X509* x509, EVP_PKEY* pkey, const char* enc_entity, char** data_out);

DSEXPORT int
keygen(const char* dn, const char* attr, const char* comment,
       EVP_PKEY** pkey_out,
       X509** x509ss_out,
       X509_REQ** req_out);

/* sign a request into a X509 certificate */

DSEXPORT X509*  /* returns signed certificate, or NULL if error */
certification_authority(X509* ca_cert,
			EVP_PKEY* ca_pkey,
			X509_REQ* req,
			const char* start_date,
			const char* end_date,
			long serial,
			const char* basic_constraints,
			const char* cert_type,
			const char* key_usage,
			const char* comment);

#endif

/* ======================= U T I L I T I E S ======================= */

extern char randomfile[256];

/* initializes EVP algorithm tables and injects randomness into
 * system. If random file existed it is read as well and 0 (for
 * success) is returned. If random file did not exist, it will be
 * created (if permissions allow) and -1 is returned. On that occasion
 * it is advisable to arrange some real randomness (such as movements of
 * mouse, times between key presses, /dev/random, etc.) and call
 * init again. */

DSEXPORT int smime_init(const char* random_file, const char* randomness, int randlen);

/* encp=0 base64->binary, enc=1 binary->base64 */

DSEXPORT int smime_base64(int encp, const char* data, int len, char** b64);

/* stores smime library level error. The buffer only has meaningful
 * values if an error has happened. You must detect the error from
 * return value of a function (NULL or -1) before looking here or
 * calling smime_get_errors(). */
extern char smime_error_buf[256];

DSEXPORT char* smime_get_errors();
DSEXPORT char* smime_hex(const char* data, int len);
DSEXPORT char* smime_dotted_hex(const char* data, int len);

/* ================= I N T E R N A L   U T I L I T I E S ================ */

#ifdef SMIME_INTERNALS

/* Hard coded mime separators. Hope the content will never have these. */

#define SEP "42_is_the_answer"   /* MIME multipart boundary separator */
#define SIG "42_is_the_question" /* MIME multipart/signed boundary sep */

/* To guard agains any macintosh brain damage where \n == \015 */

#define CR    "\015"
#define LF    "\012"
#define CRLF  "\015\012"

/* Initialize a memory BIO to have certain content */

DSEXPORT BIO* set_read_BIO_from_buf(const char* buf, int len);

DSEXPORT int get_written_BIO_data(BIO* wbio, char** data);

/* Get private key from buffer full of encrypted stuff */

DSEXPORT EVP_PKEY* open_private_key(const char* privatekey_pem, const char* password);
DSEXPORT int write_private_key(EVP_PKEY* pkey, const char* passwd, char** priv);

/* Extract a certificate from pem encoding */

DSEXPORT X509* extract_certificate(const char* cert);

DSEXPORT int /* returns length of the PEM encoding */
write_certificate(X509* x509, char** x509_cert_pem);

DSEXPORT X509_REQ* extract_request(const char* req);
DSEXPORT int write_request(X509_REQ* x509_req, char** x509_req_pem);

DSEXPORT PKCS12* load_PKCS12(const char* pkcs12, int pkcs12_len);
DSEXPORT int save_PKCS12(PKCS12* p12, char** pkcs12_out);

DSEXPORT int password_callback(char* buf, int buf_size, int x /*not used*/, void* password);

DSEXPORT char* concat(char* b, const char* s);
DSEXPORT char* concatmem(char* b, const char* s, int len);

/* WARNING: returned value can not be freed */
DSEXPORT char*  /* returns pointer to within buf. Buf is modified. */
cut_pem_markers_off(char* buf, int len, char* algo_name);

DSEXPORT char*  /* returns new buf */
wrap_in_pem_markers(const char* buf, char* algo_name);

/* Adds some of the most commonly wanted extensions
 *
 * Examples:
 *   basic_constraints: CA:TRUE,pathlen:3
 *   cert_type: client,server,email,objsign,sslCA,emailCA,objCA
 *   key_usage: digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment,keyAgreement,keyCertSign,cRLSign
 *   comment: dont trust me ;-)
 */

DSEXPORT int
add_some_X509v3_extensions(X509* cert,
			   const char* basic_constraints,
			   const char* cert_type,
			   const char* key_usage,
			   const char* comment);

/* Macro to make error reporting more friendly while still easy. */

#if 1
# define GOTO_ERR(x) do{ snprintf(smime_error_buf, sizeof(smime_error_buf), \
      "%s (%s:%d)\n", (x), __FILE__, __LINE__); \
      smime_error_buf[sizeof(smime_error_buf)-1]='\0'; goto err; }while(0)
#else
# define GOTO_ERR(x) goto err
#endif

#undef DEBUGLOG

#ifdef DEBUGLOG
extern FILE* Log;
# define LOG(x) do{ if (Log) { fprintf(Log, "%s %d: %s\n", \
                  __FILE__, __LINE__, (x)); fflush(Log); } }while(0)
# define LOG2(s,x) do{ if (Log) { fprintf(Log, "%s %d: " s "\n", \
                  __FILE__, __LINE__, (x)); fflush(Log); } }while(0)
#else
#if !defined(DSPROXY) && !defined(__DIRECTORYSCRIPT__)
#define LOG(x)
#define LOG2(s,x)
#endif
#endif

#endif /* SMIME_INTERNALS */

#ifdef __cplusplus
}
#endif

#endif /* _SMIMEUTIL_H */
