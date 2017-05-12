#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <gcrypt.h>

struct GCrypt_Cipher_s {
	GcryCipherHd h;
	int mode;
	unsigned int blklen, keylen;
};
typedef struct GCrypt_Cipher_s *GCrypt_Cipher;

MODULE = GCrypt		PACKAGE = GCrypt		

MODULE = GCrypt		PACKAGE = GCrypt::Cipher	PREFIX = gcry_cipher_

GCrypt_Cipher
gcry_cipher_new(...)
    INIT:
	char *klass = NULL;
	int algo, i;
	unsigned int flags;
	char *s;
    CODE:
	s = SvPV_nolen(ST(0));
	if (strcmp(s, "GCrypt::Cipher") == 0)
	  i = 1;
	else {
	  i = 0;
	  if (items == 4)
	    croak("GCrypt::Cipher::open: don't know how to construct %s", s);
	}
	if (items < i + 1 || items > i + 3)
	  croak("Usage: GCrypt::Cipher::new([class,] algo[, mode[, flags]])");
	New(0, RETVAL, 1, struct GCrypt_Cipher_s);
	if (SvIOK(ST(i))) {
	  algo = SvIV(ST(i));
	} else {
	  s = SvPV_nolen(ST(i));
	  if (!(algo = gcry_cipher_map_name(s)))
	    croak("unknown algorithm %s", s);
	}
	RETVAL->blklen = gcry_cipher_get_algo_blklen(algo);
	RETVAL->keylen  = gcry_cipher_get_algo_keylen(algo);
	if (++i < items) {
	  if (SvIOK(ST(i))) {
	    RETVAL->mode = SvIV(ST(i));
	  } else {
	    s = SvPV_nolen(ST(i));
	    RETVAL->mode = 0;
	    switch (s[0]) {
	      case 'e':
		if (strcmp(s+1, "cb") == 0)
		  RETVAL->mode = GCRY_CIPHER_MODE_ECB;
		break;
	      case 'c':
		if (strcmp(s+1, "fb") == 0)
		  RETVAL->mode = GCRY_CIPHER_MODE_CFB;
		else if (strcmp(s+1, "bc") == 0)
		  RETVAL->mode = GCRY_CIPHER_MODE_CBC;
		break;
	      case 's':
		if (strcmp(s+1, "tream") == 0)
		  RETVAL->mode = GCRY_CIPHER_MODE_STREAM;
		break;
	      case 'o':
		if (strcmp(s+1, "fb") == 0)
		  RETVAL->mode = GCRY_CIPHER_MODE_OFB;
		break;
	    }
	    if (!RETVAL->mode)
	      croak("unknown mode %s", s);
	  }
	  if (++i < items) {
	    if (SvIOK(ST(i))) {
	      flags = SvIV(ST(i));
	    } else {
	      size_t n;
	      s = SvPV_nolen(ST(i));
	      flags = 0;
	      while (*s) {
		n = strcspn(s, "|, \t\n");
		if (n == 0) {
		} else if (strncmp(s, "secure", n) == 0) {
		  flags |= GCRY_CIPHER_SECURE;
		} else if (strncmp(s, "enable_sync", n) == 0) {
		  flags |= GCRY_CIPHER_ENABLE_SYNC;
		} else
		  croak("unknown flag %s", s);
		s += n;
		s += strspn(s, "|, \t\n");
	      }
	    }
	  } else
	    flags = 0;
	} else {
	  RETVAL->mode = RETVAL->blklen > 1 ? GCRY_CIPHER_MODE_CBC
					    : GCRY_CIPHER_MODE_STREAM;
	  flags = 0;
	}
	if ((RETVAL->h = gcry_cipher_open(algo, RETVAL->mode, flags)) == NULL)
	    XSRETURN_UNDEF;
    OUTPUT:
	RETVAL

SV *
gcry_cipher_encrypt(cph, in)
	GCrypt_Cipher cph;
	SV *in;
    PREINIT:
	char *ibuf, *obuf;
	size_t len, ilen;
	int i, error;
    CODE:
	ibuf = SvPV(ST(1), ilen);
	if (1) {
	  if ((len = ilen % cph->blklen) == 0) {
	    len = ilen;
	  } else {
	    char *b;
	    len = ilen + cph->blklen - len;
	    New(0, b, len, char);
	    memcpy(b, ibuf, ilen);
	    memset(b + ilen, 0, len - ilen);
	    ibuf = b;
	  }
	} else {
	  len = ilen;
	}
	New(0, obuf, len, char);
	if ((error = gcry_cipher_encrypt(cph->h, obuf, len, ibuf, len)) != 0)
	  croak("encrypt: %s", gcry_strerror(error));
	if (len != ilen)
	  Safefree(ibuf);
	RETVAL = newSVpvn(obuf, len);
    OUTPUT:
	RETVAL

SV *
gcry_cipher_decrypt(cph, in)
	GCrypt_Cipher cph;
	SV *in;
    PREINIT:
	char *ibuf, *obuf;
	size_t len, ilen;
	int error;
    CODE:
	ibuf = SvPV(ST(1), ilen);
	if (1) {
	  if ((len = ilen % cph->blklen) == 0) {
	    len = ilen;
	  } else {
	    char *b;
	    len = ilen + cph->blklen - len;
	    New(0, b, len, char);
	    memcpy(b, ibuf, ilen);
	    memset(b + ilen, 0, len - ilen);
	    ibuf = b;
	  }
	} else {
	  len = ilen;
	}
	New(0, obuf, len, char);
	if ((error = gcry_cipher_decrypt(cph->h, obuf, len, ibuf, len)) != 0)
	  croak("decrypt: %s", gcry_strerror(error));
	if (len != ilen)
	  Safefree(ibuf);
	RETVAL = newSVpvn(obuf, len);
    OUTPUT:
	RETVAL

void
gcry_cipher_setkey(cph, key)
	GCrypt_Cipher cph;
	SV *key;
    PREINIT:
	char *k, *pk;
	size_t len;
    CODE:
	k = SvPV(ST(1), len);
	if (len >= cph->keylen) {
	  gcry_cipher_setkey(cph->h, k,  cph->keylen);
	} else {
	  New(0, pk, cph->keylen, char);
	  memcpy(pk, k, len);
	  memset(pk + len, 0, cph->keylen - len);
	  gcry_cipher_setkey(cph->h, pk, cph->keylen);
	  Safefree(pk);
	}

void
gcry_cipher_setiv(cph, ...)
	GCrypt_Cipher cph;
    PREINIT:
	char *iv;
	size_t len;
    CODE:
	New(0, iv, cph->blklen, char);
	if (items == 2) {
	  char *param;
	  param = SvPV(ST(1), len);
	  if (len > cph->blklen)
	    len = cph->blklen;
	  memcpy(iv, param, len);
	} else if (items == 1) {
	  len = 0;
	} else
	  croak("Usage: $cipher->setiv([iv])");
	memset(iv + len, 0, cph->blklen - len);
	gcry_cipher_setiv(cph->h, iv, cph->blklen);
	Safefree(iv);

void
gcry_cipher_sync(cph)
	GCrypt_Cipher cph;
    CODE:
	gcry_cipher_sync(cph->h);

int
gcry_cipher_keylen(cph)
	GCrypt_Cipher cph;
    CODE:
	RETVAL = cph->keylen;
    OUTPUT:
	RETVAL

int
gcry_cipher_blklen(cph)
	GCrypt_Cipher cph;
    CODE:
	RETVAL = cph->blklen;
    OUTPUT:
	RETVAL

void
gcry_cipher_DESTROY(cph)
	GCrypt_Cipher cph;
    CODE:
	gcry_cipher_close(cph->h);
	Safefree(cph);
