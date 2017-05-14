/* zxbusprod.c  -  Liberty oriented logging facility with log signing and encryption
 * Copyright (c) 2012-2013 Synergetics (sampo@synergetics.be), All Rights Reserved.
 * Copyright (c) 2010-2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2006-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id$
 *
 * 17.8.2012,  creted, based on zxlog.c --Sampo
 * 19.8.2012,  added tolerance for CRLF where strictly LF is meant --Sampo
 * 6.9.2012,   added SSL support --Sampo
 * 9.9.2012,   added persist support --Sampo
 * 30.11.2013, fixed seconds handling re gmtime_r() - found by valgrind --Sampo
 *
 * Apart from formatting code, this is effectively a STOMP 1.1 client. Typically
 * it will talk to zxbusd instances configured using BUS_URL options.
 *
 * See also:  http://stomp.github.com/stomp-specification-1.1.html (20110331)
 * Todo: implement anti fragmentation option (tcp CORK (check Nagle algo) or
 * bundle writes in this code).
 */

#include "platform.h"  /* needed on Win32 for pthread_mutex_lock() et al. */

#include <fcntl.h>
#include <string.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <time.h>
#include <sys/types.h>
#include <sys/stat.h>
#ifdef MINGW
# include <winsock.h>
# ifndef EINPROGRESS
 #  define EINPROGRESS WSAEINPROGRESS   /* Missing in mingw 1.0, 3.0 defines this in errno.h*/
 # endif
 #else
 # include <netdb.h>
 # include <netinet/in.h>  /* struct sockaddr_in */
 #endif

 #ifdef USE_OPENSSL
 #include <openssl/x509.h>
 #include <openssl/rsa.h>
 #include <openssl/evp.h>
 #include <openssl/aes.h>
 #include <openssl/ssl.h>
 #endif

 #include "errmac.h"
 #include "zxid.h"
 #include "zxidutil.h"  /* for zx_zlib_raw_deflate(), safe_basis_64, and name_from_path */
 #include "zxidconf.h"
 #include "c/zx-data.h" /* Generated. If missing, run `make dep ENA_GEN=1' */

 #define ZXBUS_BUF_SIZE 4096
 /* Alias some struct fields for headers that can not be seen together. */
 #define receipt   host
 #define rcpt_id   host
 #define acpt_vers vers
 #define tx_id     vers
 #define session   login
 #define subs_id   login
 #define subsc     login
 #define server    pw
 #define ack       pw
 #define msg_id    pw
 #define heart_bt  dest
 #define zx_rcpt_sig dest

 #define STOMP_MIN_PDU_SIZE (sizeof("ACK\n\n\0\n")-1)
 extern int zxbus_persist_flag; /* This is defined by option processing of zxbuslist */
 int zxbus_verbose = 0;         /* This is set by option processing in zxbustailf */
 int zxbus_ascii_color = 0;     /* Defined in option processing of zxbustailf or zxbuslist */

 #define SSL_ENCRYPTED_HINT "TLS or SSL connection wanted but other end did not speak protocol.\n"
 #define ZXBUS_TIME_FMT "%04d%02d%02d-%02d%02d%02d.%03ld"
 #define ZXBUS_TIME_ARG(t,usec) t.tm_year + 1900, t.tm_mon + 1, t.tm_mday, \
				t.tm_hour, t.tm_min, t.tm_sec, usec/1000

 #if 0
 /*() Allocate memory for logging purposes.
  * Generally memory allocation goes via zx_alloc() family of functions. However
  * dues to special requirements of cryptographically implemeted logging,
  * we maintain this special allocation function (which backends to zx_alloc()).
  * Among the special features: This function makes sure the buffer size is
  * rounded up to multiple of nonce to accommodate block ciphers.
  *
  * This function is considered internal. Do not use unless you know what you are doing. */

 /* Called by:  zxbus_write_line x3 */
 static char* zxbus_alloc_zbuf(zxid_conf* cf, int *zlen, char* zbuf, int len, char* sig, int nonce)
 {
   char* p;
   int siz = nonce + 2 + len + *zlen;
   ROUND_UP(siz, nonce);        /* Round up to block size */
   p = ZX_ALLOC(cf->ctx, siz);
   if (nonce)
     zx_rand(p, nonce);
   p[nonce] = (len >> 8) & 0xff;
   p[nonce+1] = len & 0xff;
   if (len) {
     memcpy(p+nonce+2, sig, len);
     ZX_FREE(cf->ctx, sig);
   }
   memcpy(p+nonce+2+len, zbuf, *zlen);
   ZX_FREE(cf->ctx, zbuf);
   *zlen += nonce + 2 + len;
   return p;
 }

 /*() Write a line to a log, taking care of all formalities of locking and
 * observing all special options for signing and encryption of the logs.
 * Not usually called directly (but you can if you want to), this is the
 * work horse behind zxbus().
 *
 * cf::  ZXID configuration object, used for memory allocation.
 * c_path:: Path to the log file, as C string
 * encflags:: Encryption flags. See LOG_ERR or LOG_ACT configuration options in zxidconf.h
 * n:: length of log data
 * logbuf:: The data that should be logged
 */

 /* Called by: */
 void zxbus_write_line(zxid_conf* cf, char* c_path, int encflags, int n, const char* logbuf)
 {
   EVP_PKEY* log_sign_pkey;
   struct rsa_st* rsa_pkey;
   struct aes_key_st aes_key;
   int len = 0, blen, zlen;
   char sigletter = 'P';
   char encletter = 'P';
   char* p;
   char* sig = 0;
   char* zbuf;
   char* b64;
   char sigbuf[28+4];   /* Space for "SP " and sha1 */
   char keybuf[16];
   char ivec[16];
   if (n == -2)
     n = strlen(logbuf);
   if (encflags & 0x70) {          /* Encrypt check */
     zbuf = zx_zlib_raw_deflate(cf->ctx, n-1, logbuf, &zlen);
     switch (encflags & 0x06) {     /* Sign check */
     case 0x02:      /* Sx plain sha1 */
       sigletter = 'S';
       sig = ZX_ALLOC(cf->ctx, 20);
       SHA1((unsigned char*)zbuf, zlen, (unsigned char*)sig);
       len = 20;
       break;
     case 0x04:      /* Rx RSA-SHA1 signature */
       sigletter = 'R';
       LOCK(cf->mx, "logsign-wrln");      
       if (!(log_sign_pkey = cf->log_sign_pkey))
	 log_sign_pkey = cf->log_sign_pkey = zxid_read_private_key(cf, "logsign-nopw-cert.pem");
       UNLOCK(cf->mx, "logsign-wrln");      
       if (!log_sign_pkey)
	 break;
len = zxsig_data(cf->ctx, zlen, zbuf, &sig, log_sign_pkey, "enc log line", 0);
       break;
     case 0x06:      /* Dx DSA-SHA1 signature */
       ERR("DSA-SHA1 sig not implemented in encrypted mode. Use RSA-SHA1 or none. %x", encflags);
       break;
     case 0: break;  /* Px no signing */
     }

     switch (encflags & 0x70) {
     case 0x10:  /* xZ RFC1951 zip + safe base64 */
       encletter = 'Z';
       zbuf = zxbus_alloc_zbuf(cf, &zlen, zbuf, len, sig, 0);
       break;
     case 0x20:  /* xA RSA-AES */
       encletter = 'A';
       zbuf = zxbus_alloc_zbuf(cf, &zlen, zbuf, len, sig, 16);
       zx_rand(keybuf, 16);
       AES_set_encrypt_key((unsigned char*)keybuf, 128, &aes_key);
       memcpy(ivec, zbuf, sizeof(ivec));
       AES_cbc_encrypt((unsigned char*)zbuf+16, (unsigned char*)zbuf+16, zlen-16, &aes_key, (unsigned char*)ivec, 1);
       ROUND_UP(zlen, 16);        /* Round up to block size */

       LOCK(cf->mx, "logenc-wrln");
       if (!cf->log_enc_cert)
	 cf->log_enc_cert = zxid_read_cert(cf, "logenc-nopw-cert.pem");
       rsa_pkey = zx_get_rsa_pub_from_cert(cf->log_enc_cert, "log_enc_cert");
       UNLOCK(cf->mx, "logenc-wrln");
       if (!rsa_pkey)
	 break;

       len = RSA_size(rsa_pkey);
       sig = ZX_ALLOC(cf->ctx, len);
       if (RSA_public_encrypt(16, (unsigned char*)keybuf, (unsigned char*)sig, rsa_pkey, RSA_PKCS1_OAEP_PADDING) < 0) {
	 ERR("RSA enc fail %x", encflags);
	 zx_report_openssl_err("zxbus rsa enc");
	 return;
       }
       p = ZX_ALLOC(cf->ctx, 2 + len + zlen);
       p[0] = (len >> 8) & 0xff;
       p[1] = len & 0xff;
       memcpy(p+2, sig, len);
       memcpy(p+2+len, zbuf, zlen);
       ZX_FREE(cf->ctx, sig);
       ZX_FREE(cf->ctx, zbuf);
       zbuf = p;
       zlen += 2 + len;
       break;
     case 0x30:  /* xT RSA-3DES */
       encletter = 'T';
       ERR("Enc not implemented %x", encflags);
       break;
     case 0x40:  /* xB AES */
       encletter = 'B';
       zbuf = zxbus_alloc_zbuf(cf, &zlen, zbuf, len, sig, 16);
       if (!cf->log_symkey[0])
	 zx_get_symkey(cf, "logenc.key", cf->log_symkey);
       AES_set_encrypt_key((unsigned char*)cf->log_symkey, 128, &aes_key);
       memcpy(ivec, zbuf, sizeof(ivec));
       AES_cbc_encrypt((unsigned char*)zbuf+16, (unsigned char*)zbuf+16, zlen-16, &aes_key, (unsigned char*)ivec, 1);
       ROUND_UP(zlen, 16);        /* Round up to block size */
       break;
     case 0x50:  /* xU 3DES */
       encletter = 'U';
       ERR("Enc not implemented %x", encflags);
       break;
     default:
       ERR("Enc not implemented %x", encflags);
       break;
     }

     blen = SIMPLE_BASE64_LEN(zlen) + 3 + 1;
     b64 = ZX_ALLOC(cf->ctx, blen);
     b64[0] = sigletter;
     b64[1] = encletter;
     b64[2] = ' ';
     p = base64_fancy_raw(zbuf, zlen, b64+3, safe_basis_64, 1<<31, 0, 0, '.');
     blen = p-b64 + 1;
     *p = '\n';
     write2_or_append_lock_c_path(c_path, 0, 0, blen, b64, "zxbus enc", SEEK_END, O_APPEND);
     return;
   }

   /* Plain text, possibly signed. */

   switch (encflags & 0x06) {
   case 0x02:   /* SP plain sha1 */
     strcpy(sigbuf, "SP ");
     sha1_safe_base64(sigbuf+3, n-1, logbuf);
     sigbuf[3+27] = ' ';
     len = 3+27+1;
     p = sigbuf;
     break;
   case 0x04:   /* RP RSA-SHA1 signature */
     LOCK(cf->mx, "logsign-wrln");      
     if (!(log_sign_pkey = cf->log_sign_pkey))
       log_sign_pkey = cf->log_sign_pkey = zxid_read_private_key(cf, "logsign-nopw-cert.pem");
     UNLOCK(cf->mx, "logsign-wrln");
     if (!log_sign_pkey)
       break;
zlen = zxsig_data(cf->ctx, n-1, logbuf, &zbuf, log_sign_pkey, "log line", 0);
     len = SIMPLE_BASE64_LEN(zlen) + 4;
     sig = ZX_ALLOC(cf->ctx, len);
     strcpy(sig, "RP ");
     p = base64_fancy_raw(zbuf, zlen, sig+3, safe_basis_64, 1<<31, 0, 0, '.');
     len = p-sig + 1;
     *p = ' ';
     p = sig;
     break;
   case 0x06:   /* DP DSA-SHA1 signature */
     ERR("DSA-SHA1 signature not implemented %x", encflags);
     break;
   case 0:      /* Plain logging, no signing, no encryption. */
     len = 5;
     p = "PP - ";
     break;
   }
   write2_or_append_lock_c_path(c_path, len, p, n, logbuf, "zxbus sig", SEEK_END, O_APPEND);
   if (sig)
     ZX_FREE(cf->ctx, sig);
 }

 /*() Helper function for formatting all kinds of logs. */

 static int zxbus_fmt(zxid_conf* cf,   /* 1 */
		      int len, char* logbuf,
		      struct timeval* ourts,  /* 2 null allowed, will use current time */
		      struct timeval* srcts,  /* 3 null allowed, will use start of unix epoch... */
		      const char* ipport,     /* 4 null allowed, -:- or cf->ipport if not given */
		      struct zx_str* entid,   /* 5 null allowed, - if not given */
		      struct zx_str* msgid,   /* 6 null allowed, - if not given */
		      struct zx_str* a7nid,   /* 7 null allowed, - if not given */
		      struct zx_str* nid,     /* 8 null allowed, - if not given */
		      const char* sigval,     /* 9 null allowed, - if not given */
		      const char* res,        /* 10 */
		      const char* op,         /* 11 */
		      const char* arg,        /* 12 null allowed, - if not given */
		      const char* fmt,        /* 13 null allowed as format, ends the line */
		      va_list ap)
 {
   int n;
   char* p;
   char sha1_name[28];
   struct tm ot;
   struct tm st;
   struct timeval ourtsdefault;
   struct timeval srctsdefault;

   /* Prepare values */

   if (!ourts) {
     ourts = &ourtsdefault;
     GETTIMEOFDAY(ourts, 0);
   }
   if (!srcts) {
     srcts = &srctsdefault;
     srctsdefault.tv_sec = 0;
     srctsdefault.tv_usec = 501000;
   }
   GMTIME_R(ourts->tv_sec, ot);
   GMTIME_R(srcts->tv_sec, st);

   if (entid && entid->len && entid->s) {
     sha1_safe_base64(sha1_name, entid->len, entid->s);
     sha1_name[27] = 0;
   } else {
     sha1_name[0] = '-';
     sha1_name[1] = 0;
   }

   if (!ipport) {
     ipport = cf->ipport;
     if (!ipport)
       ipport = "-:-";
   }

   /* Format */

   n = snprintf(logbuf, len-3, ZXBUS_TIME_FMT " " ZXBUS_TIME_FMT
		" %s %s"  /* ipport  sha1_name-of-ent */
		" %.*s"
		" %.*s"
		" %.*s"
		" %s %s %s %s %s ",
		ZXBUS_TIME_ARG(ot, ourts->tv_usec), ZXBUS_TIME_ARG(st, srcts->tv_usec),
		ipport, sha1_name,
		msgid?msgid->len:1, msgid?msgid->s:"-",
		a7nid?a7nid->len:1, a7nid?a7nid->s:"-",
		nid?nid->len:1,     nid?nid->s:"-",
		errmac_instance, STRNULLCHKD(sigval), res, op, arg?arg:"-");
   logbuf[len-1] = 0; /* must terminate manually as on win32 nul is not guaranteed */
   if (n <= 0 || n >= len-3) {
     if (n < 0)  platform_broken_snprintf(n, __FUNCTION__, len-3, "zxbus msg frame");
     D("Log buffer too short: %d chars needed", n);
     if (n <= 0)
       n = 0;
     else
       n = len-3;
   } else { /* Space left: try printing the format string as well! */
     p = logbuf+n;
     if (fmt && fmt[0]) {
       n = vsnprintf(p, len-n-2, fmt, ap);
       logbuf[len-1] = 0;  /* must terminate manually as on win32 nul term is not guaranteed */
       if (n <= 0 || n >= len-(p-logbuf)-2) {
	 if (n < 0)  platform_broken_snprintf(n, __FUNCTION__, len-n-2, fmt);
	 D("Log buffer truncated during format print: %d chars needed", n);
	 if (n <= 0)
	   n = p-logbuf;
	 else
	   n = len-(p-logbuf)-2;
       } else
	 n += p-logbuf;
     } else {
       logbuf[n++] = '-';
     }
   }
   logbuf[n++] = '\n';
   logbuf[n] = 0;
   /*logbuf[len-1] = 0;*/
   return n;
 }
 #endif

 /*() Clear current PDU from read buffer, moving the data after
  * it (i.e. next PDU in buffer) in position to be read. */

 /* Called by:  zxbus_close x3, zxbus_listen_msg x4, zxbus_open_bus_url x2, zxbus_send_cmdf x3 */
 static void zxbus_shift_read_buf(zxid_conf* cf, struct zxid_bus_url* bu, struct stomp_hdr* stomp)
 {
   if (stomp->end_of_pdu) {
     memmove(bu->m, stomp->end_of_pdu, bu->ap-stomp->end_of_pdu);
     bu->ap = bu->m + (bu->ap-stomp->end_of_pdu);
     D("shifted read_buf(%.*s)", (int)(bu->ap-bu->m), bu->m);
   }
   stomp->end_of_pdu = 0;
 }

 /*() Read and parse a frame from STOMP 1.1 connection (from zxbusd).
  * Blocks until frame has been read.
  *
  * Return:: 1 on success, 0 on failure.
  *
  * In case of failure, caller should close the connection. The PDU
  * data is left in bu->m, possibly with the following pdu as well. The
  * caller should clean the buffer without loosing the next pdu
  * fragment before calling this function again. For example:
  *   memmove(bu->m, stomp->end_of_pdu, bu->ap-stomp->end_of_pdu);
  *   bu->ap = bu->m + (bu->ap-stomp->end_of_pdu);
  *   stomp->end_of_pdu = 0;
  * or by calling
  *   zxbus_shift_read_buf(cf, bu, stomp);
  *
  * The parsed headers are returned in the struct stomp_hdr. */

 /* Called by:  zxbus_close, zxbus_listen_msg, zxbus_open_bus_url, zxbus_send_cmdf */
 int zxbus_read_stomp(zxid_conf* cf, struct zxid_bus_url* bu, struct stomp_hdr* stomp)
 {
   int need = 0, len = 0, got;
   char* hdr;
   char* h;
   char* v;
   char* p;

   memset(stomp, 0, sizeof(struct stomp_hdr));

   while (bu->ap - bu->m < ZXBUS_BUF_SIZE) {
     D("read, already buf(%.*s) need=%d len=%d buf_avail=%d", (int)(bu->ap-bu->m), bu->m, need, (int)(bu->ap-bu->m), (int)(ZXBUS_BUF_SIZE-(bu->ap - bu->m)));
     if (need || bu->ap == bu->m) {
 #ifdef USE_OPENSSL
       if (bu->ssl) {
	 got = SSL_read(bu->ssl, bu->ap, ZXBUS_BUF_SIZE - (bu->ap - bu->m));
	 if (got < 0) {
	   ERR("SSL_read(%x) bu_%p: (%d) %d %s", bu->fd, bu, got, errno, STRERROR(errno));
	   zx_report_openssl_err("zxbus_read-ssl");
	   return 0;
	 }
       } else {
	 got = recv((SOCKET)bu->fd, bu->ap, ZXBUS_BUF_SIZE - (bu->ap - bu->m), 0);
	 if (got < 0) {
	   ERR("recv(%x) bu_%p: %d %s", bu->fd, bu, errno, STRERROR(errno));
	   return 0;
	 }
       }
 #else
       got = recv((SOCKET)bu->fd, bu->ap, ZXBUS_BUF_SIZE - (bu->ap - bu->m), 0);
       if (got < 0) {
	 ERR("recv: %d %s", errno, STRERROR(errno));
	 return 0;
       }
 #endif
       if (!got) {
	 D("recv: returned empty, gotten=%ld", (long)(bu->ap - bu->m));
	 return 0;
       }
       HEXDUMP("read:", bu->ap, bu->ap+got, /*16*/ 256);
       bu->ap += got;
     }
     for (p = bu->m; p < bu->ap && ONE_OF_2(*p, '\n', '\r'); ++p) ;
     if (p > bu->m) {
       /* Wipe out initial newlines */
       memmove(bu->m, p, bu->ap - p);
       bu->ap -= p - bu->m;
       p = bu->m;
     }
     if (bu->ap - p < STOMP_MIN_PDU_SIZE)
       goto read_more;

     /* Extract command (always in beginning of buf) */

     hdr = memchr(p, '\n', bu->ap - p);
     if (!hdr || ++hdr == bu->ap)
       goto read_more;
     p = hdr;

     /* Decode headers
      * 01234 5 6 7
      * STOMP\n\n\0
      *         ^-p
      * 01234 5 6 7 8 9
      * STOMP\r\n\r\n\0
      *           ^-p
      * STOMP\nhost:foo\n\n\0
      *        ^-p        ^-pp
      * STOMP\r\nhost:foo\r\n\r\n\0
      *          ^-p          ^-pp
      * STOMP\nhost:foo\naccept-version:1.1\n\n\0
      *        ^-p       ^-pp                 ^-ppp
      * STOMP\r\nhost:foo\r\naccept-version:1.1\r\n\r\n\0
      *          ^-p         ^-pp                   ^-ppp
      */

     while (!ONE_OF_2(*p,'\n','\r')) { /* Empty line separates headers from body. */
       h = p;
       p = memchr(p, '\n', bu->ap - p);
       if (!p || ++p == bu->ap)
	 goto read_more;
       v = memchr(h, ':', p-h);
       if (!v) {
	 ERR("Header missing colon. hdr(%.*s)", (int)(bu->ap-h), h);
	 return 0;
       }
       ++v; /* skip : */

 #define HDR(hdr, field, val) } else if (!memcmp(h, hdr, sizeof(hdr)-1)) { if (!stomp->field) stomp->field = (val)

       if (!memcmp(h, "content-length:", sizeof("content-length:")-1)) {
	 if (!stomp->len) stomp->len = len = atoi(v); D("len=%d", stomp->len);
       HDR("host:",           host,      v);
       HDR("receipt:",        receipt,   v);
       HDR("receipt-id:",     rcpt_id,   v);
       HDR("zx-rcpt-sig:",    zx_rcpt_sig, v);
       HDR("version:",        vers,      v);
       HDR("accept-version:", acpt_vers, v);
       HDR("transaction:",    tx_id,     v);
       HDR("login:",          login,     v);
       HDR("passcode:",       pw,        v);
       HDR("session:",        session,   v);
       HDR("id:",             subs_id,   v);
       HDR("subscription:",   subsc,     v);
       HDR("server:",         server,    v);
       HDR("ack:",            ack,       v);
       HDR("message-id:",     msg_id,    v);
       HDR("destination:",    dest,      v);
       HDR("heart-beat:",     heart_bt,  v);
       } else if (!memcmp(h, "message:", sizeof("message:")-1)) { /* ignore */
       } else if (!memcmp(h, "content-type:", sizeof("content-type:")-1)) { /* ignore */
       } else {
	 D("Unknown header(%.*s) ignored.", (int)(p-h), h);
       }
     }

     /* Now body */

     if (*p == '\r') ++p;
     stomp->body = ++p;

     if (len) {
       if (len < bu->ap - p) {
	 /* Got complete with content-length */
	 p += len;
	 if (!*p++)
	   goto done;
	 ERR("No nul to terminate body. %d",0);
	 return 0;
       } else {
	 goto read_more;
       }
     } else {
       /* Scan until nul */
       while (1) {
	 if (bu->ap - p < 1) {   /* too little, need more */
	   goto read_more;
	 }
	 if (!*p++) {
	   stomp->len = p - stomp->body - 1;
	   goto done;
	 }
       }
     }
   read_more:
     need = 1;
     continue;
   }
   if (bu->ap - bu->m >= ZXBUS_BUF_SIZE) {
     ERR("PDU does not fit in buffer %d", (int)(bu->ap-bu->m));
     return 0;
   }
  done:
   stomp->end_of_pdu = p;
   return 1;
 }

 /*() ACK a message to STOMP 1.1 connection.
  * N.B. ACK is not a command. Thus no RECEIPT is expected from server
  * end (ACK really is the receipt for MESSAGE sent by server).
  *
  * Returns:: zero on failure and 1 on success. */

 /* Called by:  zxbus_listen_msg */
 int zxbus_ack_msg(zxid_conf* cf, struct zxid_bus_url* bu, struct stomp_hdr* stompp)
 {
   int len;
   char sigbuf[1024];
   char buf[1024];
   int subs_id_len, msg_id_len;
   subs_id_len = strchr(stompp->subs_id, '\n') - stompp->subs_id;
   msg_id_len = strchr(stompp->msg_id, '\n') - stompp->msg_id;

   zxbus_mint_receipt(cf, sizeof(sigbuf), sigbuf,
		      msg_id_len, stompp->msg_id,
		      -2, stompp->dest,
		      -1, bu->eid,  /* entity to which we issue this receipt */
		      stompp->len, stompp->body);
   len = snprintf(buf, sizeof(buf), "ACK\nsubscription:%.*s\nmessage-id:%.*s\nzx-rcpt-sig:%s\n\n%c",
		  subs_id_len, stompp->subs_id, msg_id_len, stompp->msg_id, sigbuf, 0);
   HEXDUMP(" ack:", buf, buf+len, /*16*/ 256);
 #ifdef USE_OPENSSL
   if (bu->ssl)
     SSL_write(bu->ssl, buf, len);
   else
 #endif
     send_all_socket(bu->fd, buf, len);
   return 1;
 }

 /*() NACK a message to STOMP 1.1 connection, signalling trouble persisting it.
  * N.B. NACK is not a command. Thus no RECEIPT is expected from server
  * end (NACK really is the receipt for MESSAGE sent by server).
  *
  * Returns:: zero on failure and 1 on success. */

 /* Called by:  zxbus_listen_msg x2 */
 int zxbus_nack_msg(zxid_conf* cf, struct zxid_bus_url* bu, struct stomp_hdr* stompp, const char* errmsg)
 {
   int len;
   char buf[1024];
   int subs_id_len, msg_id_len;
   subs_id_len = strchr(stompp->subs_id, '\n') - stompp->subs_id;
   msg_id_len = strchr(stompp->msg_id, '\n') - stompp->msg_id;

   len = snprintf(buf, sizeof(buf), "NACK\nsubscription:%.*s\nmessage-id:%.*s\nmessage:%s\n\n%c",
		  subs_id_len, stompp->subs_id, msg_id_len, stompp->msg_id, errmsg, 0);
   HEXDUMP("nack:", buf, buf+len, /*16*/ 256);
 #ifdef USE_OPENSSL
   if (bu->ssl)
     SSL_write(bu->ssl, buf, len);
   else
 #endif
     send_all_socket(bu->fd, buf, len);
   return 1;
 }

 /*() Listen for a MESSAGE from the STOMP 1.1 connection and ACK it.
  * Returns pointer to the body (which is nul terminated as the
  * STOMP 1.1 frame ends in nul). Returns NULL on error.
  * N.B. Depending on situation, you may NOT want automatic ACK.
  * In that case you should call zxbus_read() and zxbus_ack_msg()
  * directly and do your persistence in between.
  *
  * See also:: zxbus_persist() */

 /* Called by:  zxbuslist_main */
 char* zxbus_listen_msg(zxid_conf* cf, struct zxid_bus_url* bu)
 {
   struct stomp_hdr stomp;
   int dest_len;
   char* dest;
   char c_path[ZXID_MAX_BUF];
   if (zxbus_read_stomp(cf, bu, &stomp)) {
     if (!memcmp(bu->m, "MESSAGE", sizeof("MESSAGE")-1)) {
       if (zxbus_persist_flag) {
	 if (!(dest = stomp.dest)) {
	   ERR("SEND MUST specify destination header, i.e. channel to send to. %p", dest);
	   zxbus_nack_msg(cf, bu, &stomp, "no destination channel. server error.");
	   zxbus_shift_read_buf(cf, bu, &stomp);
	   return 0;
	 }
	 dest_len = (char*)memchr(dest, '\n', bu->ap - dest) - dest;  /* there will be \n in STOMP header */
	 DD("persist(%.*s)", dest_len, dest);

	 if (!zxbus_persist_msg(cf, sizeof(c_path), c_path, dest_len, dest, bu->ap - bu->m,bu->m)) {
	   zxbus_nack_msg(cf, bu, &stomp, "difficulty in persisting (temporary client/local err)");
	   zxbus_shift_read_buf(cf, bu, &stomp);
	   return 0;
	 }
       }
       if (zxbus_verbose) {
	 if (zxbus_ascii_color>1) {
	   if (zxbus_verbose>1) {
	     fprintf(stdout, "\e[42m%.*s\e[0m\n", (int)(bu->ap - bu->m), bu->m);
	   } else {
	     fprintf(stdout, "\e[42m%.*s\e[0m\n", stomp.len, stomp.body);
	   }
	 } else {
	   if (zxbus_verbose>1) {
	     fprintf(stdout, "%.*s\n", (int)(bu->ap - bu->m), bu->m);
	   } else {
	     fprintf(stdout, "%.*s\n", stomp.len, stomp.body);
	   }
	 }
       }
       zxbus_ack_msg(cf, bu, &stomp);
       zxbus_shift_read_buf(cf, bu, &stomp);
       return stomp.body;  /* normal successful return */
     } else {
       ERR("Unknown command received(%.*s)", (int)(bu->ap - bu->m), bu->m);
       zxbus_shift_read_buf(cf, bu, &stomp);
       return 0;
     }
   } else {
     ERR("Read from %s failed.", bu->s);
     return 0;
   }
 }

 #ifdef USE_OPENSSL
 //int zxbus_cert_verify_cb(X509_STORE_CTX* st_ctx, void* arg) {  zxid_conf* cf = arg;  return 0; }

 /* Called by: */
 static void zx_ssl_info_cb(const SSL *ssl, int where, int ret)
 {
   const char *str;

   if ((where & ~SSL_ST_MASK) & SSL_ST_CONNECT) str="SSL_connect";
   else if ((where & ~SSL_ST_MASK) & SSL_ST_ACCEPT) str="SSL_accept";
   else str="undefined";

   if (where & SSL_CB_LOOP) {
     D("%s:%s",str,SSL_state_string_long(ssl));
   } else if (where & SSL_CB_ALERT) {
     str=(where & SSL_CB_READ)?"read":"write";
     D("SSL3 alert %s:%s:%s",str,SSL_alert_type_string_long(ret),SSL_alert_desc_string_long(ret));
   } else if (where & SSL_CB_EXIT) {
     if (ret == 0)
       D("%s:failed in %s",str,SSL_state_string_long(ssl));
     else if (ret < 0)
       D("%s:error in %s",str,SSL_state_string_long(ssl));
   }
 }
 #endif

 /*() Open a bus_url, i.e. STOMP 1.1 connection to zxbusd.
  *
  * return:: 0 on failure, 1 on success. */

 /* Called by:  zxbus_send_cmd, zxbuslist_main */
 int zxbus_open_bus_url(zxid_conf* cf, struct zxid_bus_url* bu)
 {
 #ifdef USE_OPENSSL
   X509* peer_cert;
   zxid_entity* meta;
 #endif
   long vfy_err;
   int len,tls;
   char buf[1024];
   struct hostent* he;
   struct sockaddr_in sin;
   struct stomp_hdr stomp;
   int host_len;
   char* proto;
   char* host;
   char* port;
   char* local;
   char* qs;
   char* eid;
   char* p;

   /* Parse the bus_url */

   if (!bu || !bu->s || !*bu->s) {
     ERR("Null arguments or empty bus_url supplied %p", bu);
     return 0;
   }

   host = strstr(bu->s, "://");
   if (!host) {
     ERR("Malformed bus_url(%s): missing protocol field", bu->s);
     proto = "stomps:";
     host = bu->s;
   } else {
     proto = bu->s;
     host += 3;
   }

   if (!memcmp(proto, "stomps:", sizeof("stomps:")-1)) {
     tls = 1;
   } else if (!memcmp(proto, "stomp:", sizeof("stomp:")-1)) {
     tls = 0;
   } else {
     ERR("Unknown protocol(%.*s)", 6, proto);
     return 0;
   }

   port = strchr(host, ':');
   if (!port) {
     port = tls ? ":2229/" : ":2228/";  /* ZXID default ports for stomps: and plain stomp: */
     local = strchr(host, '/');
     if (!local) {
       qs = strchr(host, '?');
       if (!qs) {
	 host_len = strlen(host);
       } else {
	 host_len = qs-host;
       }
     } else {
       host_len = local-host;
       qs = strchr(local, '?');
     }
   } else {
     host_len = port-host;
     local = strchr(port, '/');
     if (!local) {
       qs = strchr(port, '?');
     } else {
       qs = strchr(local, '?');
     }
   }

   bu->m = bu->ap = ZX_ALLOC(cf->ctx, ZXBUS_BUF_SIZE);

   memcpy(bu->m, host, MIN(host_len, ZXBUS_BUF_SIZE-2));
   bu->m[MIN(host_len, ZXBUS_BUF_SIZE-2)] = 0;
   he = gethostbyname(bu->m);
   if (!he) {
     ERR("hostname(%s) did not resolve(%d) bu->s(%s) host_len=%d %d host(%.*s) %p port(%s) %p", bu->m, h_errno, bu->s, host_len, MIN(host_len, ZXBUS_BUF_SIZE-2), host_len, host, host, port, port);
     exit(5);
   }

   memset(&sin, 0, sizeof(sin));
   sin.sin_family = AF_INET;
   sin.sin_port = htons(atoi(port+1));
   memcpy(&(sin.sin_addr.s_addr), he->h_addr, sizeof(sin.sin_addr.s_addr));

   if ((bu->fd = (fdtype)socket(AF_INET, SOCK_STREAM, 0)) == (fdtype)-1) {
     ERR("Unable to create socket(AF_INET, SOCK_STREAM, 0) %d %s", errno, STRERROR(errno));
     return 0;
   }

 #if 0
   nonblock(bu->fd);
   if (nkbuf)
     setkernelbufsizes(bu->fd, nkbuf, nkbuf);
 #endif

   D("connecting(%x) hs(%s)", bu->fd, bu->s);
   if ((connect((SOCKET)bu->fd, (struct sockaddr*)&sin, sizeof(sin)) == -1) && (errno != EINPROGRESS)) {
     ERR("Connection to %s failed: %d %s", bu->s, errno, STRERROR(errno));
     goto errout;
   }

   D("connected(%x) at TCP layer hs(%s)", bu->fd, bu->s);

   if (tls) {
 #ifdef USE_OPENSSL
     if (!cf->ssl_ctx) {
       SSL_load_error_strings();
       SSL_library_init();
 #if 0
       cf->ssl_ctx = SSL_CTX_new(SSLv23_method());
 #else
       cf->ssl_ctx = SSL_CTX_new(TLSv1_client_method());
 #endif
     }
     if (!cf->ssl_ctx) {
       ERR("TLS/SSL connection to(%s) can not be made. SSL context initialization problem", bu->s);
       zx_report_openssl_err("open_bus_url-ssl_ctx");
       goto errout;
     } else {
       if (errmac_debug>1) {
	D("OpenSSL header-version(%lx) lib-version(%lx)(%s) %s %s %s %s", OPENSSL_VERSION_NUMBER, SSLeay(), SSLeay_version(SSLEAY_VERSION), SSLeay_version(SSLEAY_CFLAGS), SSLeay_version(SSLEAY_BUILT_ON), SSLeay_version(SSLEAY_PLATFORM), SSLeay_version(SSLEAY_DIR));
	SSL_CTX_set_info_callback(cf->ssl_ctx, zx_ssl_info_cb);
      }
      SSL_CTX_set_mode(cf->ssl_ctx, SSL_MODE_AUTO_RETRY);  /* R/W only return when complete. */
      /* Verification strategy: do not attempt verification at SSL layer. Instead
       * check the result afterwards against metadata based cert. */
      SSL_CTX_set_verify(cf->ssl_ctx, SSL_VERIFY_NONE,0);
      //SSL_CTX_set_verify(cf->ssl_ctx, SSL_VERIFY_PEER,0);
      //SSL_CTX_set_cert_verify_callback(cf->ssl_ctx, zxbus_cert_verify_cb, cf);
      /*SSL_CTX_load_verify_locations() SSL_CTX_set_client_CA_list(3) SSL_CTX_set_cert_store(3) */
      LOCK(cf->mx, "logenc wrln");
      if (!cf->enc_cert)
	cf->enc_cert = zxid_read_cert(cf, "enc-nopw-cert.pem");
      if (!cf->enc_pkey)
	cf->enc_pkey = zxid_read_private_key(cf, "enc-nopw-cert.pem");
      UNLOCK(cf->mx, "logenc wrln");
      if (!SSL_CTX_use_certificate(cf->ssl_ctx, cf->enc_cert)) {
	ERR("TLS/SSL connection to(%s) can not be made. SSL certificate problem", bu->s);
	zx_report_openssl_err("open_bus_url-cert");
	goto errout;
      }
      if (!SSL_CTX_use_PrivateKey(cf->ssl_ctx, cf->enc_pkey)) {
	ERR("TLS/SSL connection to(%s) can not be made. SSL private key problem", bu->s);
	zx_report_openssl_err("open_bus_url-privkey");
	goto errout;
      }
      if (!SSL_CTX_check_private_key(cf->ssl_ctx)) {
	ERR("TLS/SSL connection to(%s) can not be made. SSL certificate-private key consistency problem", bu->s);
	zx_report_openssl_err("open_bus_url-chk-privkey");
	goto errout;
      }
      /*SSL_CTX_add_extra_chain_cert(cf->ssl_ctx, ca_cert);*/
    }
    bu->ssl = SSL_new(cf->ssl_ctx);
    if (!bu->ssl) {
      ERR("TLS/SSL connection to(%s) can not be made. SSL object initialization problem", bu->s);
      zx_report_openssl_err("open_bus_url-ssl");
      goto errout;
    }
    if (!SSL_set_fd(bu->ssl, (int)bu->fd)) {
      ERR("TLS/SSL connection to(%s) can not be made. SSL fd(%x) initialization problem", bu->s, bu->fd);
      zx_report_openssl_err("open_bus_url-set_fd");
      goto sslerrout;
    }
    
    switch (vfy_err = SSL_get_error(bu->ssl, SSL_connect(bu->ssl))) {
    case SSL_ERROR_NONE: break;
      /*case SSL_ERROR_WANT_ACCEPT:  documented, but undeclared */
    case SSL_ERROR_WANT_READ:
    case SSL_ERROR_WANT_CONNECT:
    case SSL_ERROR_WANT_WRITE:
    default:
      ERR("TLS/SSL connection to(%s) can not be made. SSL connect or handshake problem (%ld)", bu->s, vfy_err);
      zx_report_openssl_err("open_bus_url-ssl_connect");
      send((SOCKET)bu->fd, SSL_ENCRYPTED_HINT, sizeof(SSL_ENCRYPTED_HINT)-1, 0);
      goto sslerrout;
    }

    if (errmac_debug>1) D("SSL_version(%s) cipher(%s)",SSL_get_version(bu->ssl),SSL_get_cipher(bu->ssl));

    vfy_err = SSL_get_verify_result(bu->ssl);
    switch (vfy_err) {
    case X509_V_OK: break;
    case X509_V_ERR_DEPTH_ZERO_SELF_SIGNED_CERT:
      D("TLS/SSL connection to(%s) made, but certificate err. (%ld)", bu->s, vfy_err);
      zx_report_openssl_err("open_bus_url-verify_res");
      break;
    default:
      ERR("TLS/SSL connection to(%s) made, but certificate not acceptable. (%ld)", bu->s, vfy_err);
      zx_report_openssl_err("open_bus_url-verify_res");
      goto sslerrout;
    }

    if (!(peer_cert = SSL_get_peer_certificate(bu->ssl))) {
      ERR("TLS/SSL connection to(%s) made, but peer did not send certificate", bu->s);
      zx_report_openssl_err("open_bus_url-peer_cert");
      goto sslerrout;
    }
    meta = zxid_get_ent(cf, bu->eid);
    if (!meta) {
      ERR("Unable to find metadata for eid(%s) in verify peer cert", bu->eid);
      goto sslerrout;
    }
    if (!meta->enc_cert) {
      ERR("Metadata for eid(%s) does not contain enc cert", bu->eid);
      goto sslerrout;
    }
    if (X509_cmp(meta->enc_cert, peer_cert)) {
      ERR("Peer certificate does not match metadata for eid(%s)", bu->eid);
      D("compare: %d", memcmp(meta->enc_cert->sha1_hash, peer_cert->sha1_hash, SHA_DIGEST_LENGTH));
      PEM_write_X509(ERRMAC_DEBUG_LOG, peer_cert);
      goto sslerrout;
    }
    /* *** should we free peer_cert? */
    /*SSL_get_verify_result(bu->ssl); no need as SSL_VERIFY_PEER causes SSL_connect() to fail. */
#else
    ERR("TLS/SSL connection to(%s) can not be made. SSL not compiled in", bu->s);
    goto errout;
#endif
  }

  eid = zxid_my_ent_id_cstr(cf);
  if (!eid)
    return 0;
  for (p = eid; *p; ++p)
    if (*p == ':')  /* deal with colon that is forbidden character in STOMP 1.1 header */
      *p = '|';
  
  if (cf->bus_pw) {
    len = snprintf(buf, sizeof(buf)-1, "STOMP\naccept-version:1.1\nhost:%s\nlogin:%s\npasscode:%s\n\n%c", bu->m, eid, cf->bus_pw, 0);
  } else {
    len = snprintf(buf, sizeof(buf)-1, "STOMP\naccept-version:1.1\nhost:%s\nlogin:%s\n\n%c", bu->m, eid, 0);
  }
  HEXDUMP("conn:", buf, buf+len, /*16*/ 256);
#ifdef USE_OPENSSL
  if (bu->ssl)
    SSL_write(bu->ssl, buf, len);
  else
#endif
    send_all_socket(bu->fd, buf, len);

  memset(&stomp, 0, sizeof(struct stomp_hdr));
  if (zxbus_read_stomp(cf, bu, &stomp)) {
    if (!memcmp(bu->m, "CONNECTED", sizeof("CONNECTED")-1)) {
      zxbus_shift_read_buf(cf, bu, &stomp);
      D("STOMP got CONNECTED bu-s(%s)", bu->s);
      return 1;
    }
    zxbus_shift_read_buf(cf, bu, &stomp);
  }
  ERR("Connection to %s failed. Other end did not send CONNECTED", bu->s);
#ifdef USE_OPENSSL
 sslerrout:
  if (bu->ssl) {
    SSL_shutdown(bu->ssl);
    SSL_free(bu->ssl);
    bu->ssl = 0;
  }
#endif
 errout:
  closesocket((SOCKET)bu->fd);
  bu->fd = 0;
  return 0;
}

/*() SEND a STOMP 1.1 DISCONNECT to audit bus and wait for RECEIPT.
 *
 * Returns:: zero on failure and 1 on success. Connection is closed in either case. */

/* Called by:  zxbus_close_all */
int zxbus_close(zxid_conf* cf, struct zxid_bus_url* bu)
{
  int len;
  char buf[1024];
  struct stomp_hdr stomp;

  D("closing(%x) bu_%p", bu->fd, bu);
  
  if (!bu || !bu->s || !bu->s[0] || !bu->fd)
    return 0;         /* No bus_url configured means audit bus reporting is disabled. */

  /* *** implement intelligent lbfo algo */
  
  D("disconnecting(%p) bu->s(%s)", bu, bu->s);

  len = snprintf(buf, sizeof(buf), "DISCONNECT\nreceipt:%d\n\n%c", bu->cur_rcpt-1, 0);
  send_all_socket(bu->fd, buf, len);

  memset(&stomp, 0, sizeof(struct stomp_hdr));
  if (zxbus_read_stomp(cf, bu, &stomp)) {
    if (!memcmp(bu->m, "RECEIPT", sizeof("RECEIPT")-1)) {
      if (atoi(stomp.rcpt_id) == bu->cur_rcpt - 1) {
	zxbus_shift_read_buf(cf, bu, &stomp);
	D("DISCONNECT got RECEIPT %d", bu->cur_rcpt-1);
#ifdef USE_OPENSSL
	if (bu->ssl) {
	  SSL_shutdown(bu->ssl);
	  SSL_free(bu->ssl);
	  bu->ssl = 0;
	}
#endif
	closesocket((SOCKET)bu->fd);
	bu->fd = 0;
	return 1;
      } else {
	ERR("DISCONNECT to %s failed. RECEIPT number(%.*s)=%d mismatch cur_rcpt-1=%d", bu->s, (int)(bu->ap - stomp.rcpt_id), stomp.rcpt_id, atoi(stomp.rcpt_id), bu->cur_rcpt-1);
	zxbus_shift_read_buf(cf, bu, &stomp);
	goto errout;
      }
    } else {
      ERR("DISCONNECT to %s failed. Other end did not send RECEIPT(%.*s)", bu->s, (int)(bu->ap - bu->m), bu->m);
      zxbus_shift_read_buf(cf, bu, &stomp);
    }
  } else {
    ERR("DISCONNECT to %s failed. Other end did not send RECEIPT. Read error. Probably connection drop.", bu->s);
  }
 errout:
#ifdef USE_OPENSSL
  if (bu->ssl) {
    SSL_shutdown(bu->ssl);
    SSL_free(bu->ssl);
    bu->ssl = 0;
  }
#endif
  closesocket((SOCKET)bu->fd);
  bu->fd = 0;
  return 0;
}

/*() SEND a STOMP 1.1 DISCONNECT to audit bus and wait for RECEIPT.
 * Returns:: nothing. Ignores any errors (but errors cause fd to be closed). */

/* Called by:  zxbuslist_main, zxbustailf_main */
void zxbus_close_all(zxid_conf* cf)
{
  struct zxid_bus_url* bu;
  for (bu = cf->bus_url; bu; bu = bu->n)
    zxbus_close(cf, bu);
}

/*() Log successful receipt (the message should have been logged earlier separately)
 *
 * cf:: zxid configuration object
 * bu:: URL and eid of the destination audit bus node
 * mid:: message ID
 * dest:: Destination channel where message was sent
 * sha1_buf:: The sha1 over the message as was used to log the message in issue directory
 * rcpt_len:: Length of the receipt data returned by remote
 * rcpt:: Receipt data returned by remote
 *
 * Log format is as follows
 *   R1 YYYYMMDD-HHMMSS.sss URL SHA1-OF-EID MID CHANNEL SHA1-OF-MSG INST O K RCPT receipt_data
 * where receipt_data is like
 *   AB1 https://buslist.zxid.org/?o=B ACK RP 20120923-170431.868 76 3aSMhrZHtsviQnl3jnb8swYuxe_5uRnegGP0_i-hgPD6pzNkLtJdC7_qA7Ry-Iz1_cSDR7L91Oe9qgQZ64CzqC1qb0l5sSVoHNVQAzUWXgXOuHvXEgkMheAoLAUT8SKM_H9cUlPCrgCkVFWPXcLAR2FHAW7sNrGe7Mcm4MFFXqM.
 */

/* Called by:  zxbus_send_cmdf */
static void zxbus_log_receipt(zxid_conf* cf, struct zxid_bus_url* bu, int mid_len, const char* mid, int dest_len, const char* dest, const char* sha1_buf, int rcpt_len, const char* rcpt)
{
  int len;
  struct tm ot;
  struct timeval ourts;
  char sha1_name[28];
  char buf[1024];
  char c_path[ZXID_MAX_BUF];

  GETTIMEOFDAY(&ourts, 0);
  GMTIME_R(ourts.tv_sec, ot);
  sha1_safe_base64(sha1_name, -2, bu->eid);
  sha1_name[27] = 0;

  if (!mid)
    mid_len = 0;
  if (mid_len == -1)
    mid_len = strlen(mid);
  else if (mid_len == -2)
    mid_len = strchr(mid, '\n') - mid;

  if (!dest)
    dest_len = 0;
  if (dest_len == -1)
    dest_len = strlen(dest);
  else if (dest_len == -2)
    dest_len = strchr(dest, '\n') - dest;

  len = snprintf(buf, sizeof(buf)-1, "R1 " ZXLOG_TIME_FMT " "
		 " %s %s"  /* url  sha1_name-of-ent */
		 " %.*s %.*s %s"  /* mid, sha1 of the message (see zxlog_blob() call), dest */
		 " %s %s %s %s"
		 " %.*s\n",
		 ZXLOG_TIME_ARG(ot, ourts.tv_usec),
		 bu->s, sha1_name,
		 mid_len, mid, dest_len, dest, sha1_buf,
		 errmac_instance, "O", "K", "RCPT",
		 rcpt_len, rcpt);
  buf[sizeof(buf)-1] = 0; /* must terminate manually as on win32 nul is not guaranteed */
  if (len < 0) platform_broken_snprintf(len, __FUNCTION__, sizeof(buf)-1, "zxbus receipt frame");
  name_from_path(c_path, sizeof(c_path), "%s" ZXID_LOG_DIR "rcpt", cf->cpath);
  write2_or_append_lock_c_path(c_path, len, buf, 0,0, "zxbus_send_cmdf",SEEK_END,O_APPEND);
}

/*() Send the specified STOMP 1.1 message to audit bus and wait for RECEIPT.
 * Blocks until the transaction completes (or fails). Figures out
 * from configuration, which bus daemon to contact (looks at bus_urls).
 * The fmt must contain command, headers, and double newline that
 * separates the body.
 * Will also log the message to /var/zxid/buscli/issue/SUCCINCT/wir/SHA1
 * and receipt to /var/zxid/buscli/log/rcpt
 *
 * return:: zero on failure and 1 on success. */

/* Called by:  zxbus_send_cmd, zxbuslist_main */
int zxbus_send_cmdf(zxid_conf* cf, struct zxid_bus_url* bu, int body_len, const char* body, const char* fmt, ...)
{
  va_list ap;
  int len, siglen, ver;
  char* eid;
  char* dest;
  char* rcpt;
  char buf[1024];
  char sha1_buf[28];
  struct zx_str sha1_ss;
  struct zx_str eid_ss;
  struct zx_str* logpath;
  struct stomp_hdr stomp;

  if (body_len == -1 && body)
    body_len = strlen(body);
  
  va_start(ap, fmt);
  len = vsnprintf(buf, sizeof(buf), fmt, ap);
  va_end(ap);

  rcpt = strstr(buf, "\nreceipt:");
  if (rcpt)
    rcpt += sizeof("\nreceipt:")-1;
  else
    rcpt = "\n";

  dest = strstr(buf, "\ndestination:");
  if (dest)
    dest += sizeof("\ndestination:")-1;
  else
    dest = "\n";

  if (cf->log_issue_msg) {
    /* Path will be composed of sha1 hash of the data in buf. */
    sha1_safe_base64(sha1_buf, len, buf);
    sha1_buf[27] = 0;
    sha1_ss.len = 27;
    sha1_ss.s = sha1_buf;
    eid_ss.len = strlen(bu->eid);
    eid_ss.s = bu->eid;
    logpath = zxlog_path(cf, &eid_ss, &sha1_ss, ZXLOG_ISSUE_DIR, ZXLOG_WIR_KIND, 1);
    if (logpath) {
      eid_ss.len = body_len;
      eid_ss.s = (char*)body;
      zxlog_blob(cf, cf->log_issue_msg, logpath, &eid_ss, "zxbus_send_cmdf");
      zx_str_free(cf->ctx, logpath);
    }
  }

  HEXDUMP(" buf:", buf, buf+len, /*16*/ 256);
  if (body) HEXDUMP("body:", body, body+body_len, /*16*/ 256);

#ifdef USE_OPENSSL
  if (bu->ssl) {
    SSL_write(bu->ssl, buf, len);
    if (body)
      SSL_write(bu->ssl, body, body_len);
    SSL_write(bu->ssl, "\0", 1);
  } else {
    send_all_socket(bu->fd, buf, len);
    if (body)
      send_all_socket(bu->fd, body, body_len);
    send_all_socket(bu->fd, "\0", 1);
  }
#else
  send_all_socket(bu->fd, buf, len);
  if (body)
    send_all_socket(bu->fd, body, body_len);
  send_all_socket(bu->fd, "\0", 1);
#endif

  memset(&stomp, 0, sizeof(struct stomp_hdr));
  if (zxbus_read_stomp(cf, bu, &stomp)) {
    if (!memcmp(bu->m, "RECEIPT", sizeof("RECEIPT")-1)) {
      if (atoi(stomp.rcpt_id) == bu->cur_rcpt - 1) {
	D("%.*s got RECEIPT %d", 4, buf, bu->cur_rcpt-1);

	siglen = stomp.zx_rcpt_sig ? (strchr(stomp.zx_rcpt_sig, '\n') - stomp.zx_rcpt_sig) : 0;
	eid = zxid_my_ent_id_cstr(cf);
	ver = zxbus_verify_receipt(cf, bu->eid,
				   siglen, siglen?stomp.zx_rcpt_sig:"",
				   -2, rcpt,
				   -2, dest,
				   -1, eid,  /* our eid, the receipt was issued to us */
				   body_len, body);
	ZX_FREE(cf->ctx, eid);
	if (ver != ZXSIG_OK) {
	  ERR("RECEIPT signature validation failed: %d sig(%.*s) body(%.*s)", ver, siglen, siglen?stomp.zx_rcpt_sig:"", body_len, body);
	  return 0;
	}

	if (zxbus_verbose) {
	  fprintf(stdout, "%.*s(%.*s) got RECEIPT %d\n", 4, buf, body?body_len:0, body?body:"", bu->cur_rcpt-1);
	}
	if (cf->log_rely_msg) {   /* Log the receipt */
	  zxbus_log_receipt(cf, bu, -2, rcpt, -2, dest, sha1_buf, siglen, siglen?stomp.zx_rcpt_sig:"");
	}
	zxbus_shift_read_buf(cf, bu, &stomp);
	return 1;  /* normal successful return */
      } else {
	ERR("Send to %s failed. RECEIPT number(%.*s)=%d mismatch cur_rcpt-1=%d (%s)", bu->s, (int)(bu->ap - stomp.rcpt_id), stomp.rcpt_id, atoi(stomp.rcpt_id), bu->cur_rcpt-1, bu->m);
	zxbus_shift_read_buf(cf, bu, &stomp);
	goto errout;
      }
    } else {
      ERR("Send to %s failed. Other end did not send RECEIPT(%.*s)", bu->s, (int)(bu->ap - bu->m), bu->m);
      zxbus_shift_read_buf(cf, bu, &stomp);
    }
  } else {
    ERR("Send to %s failed. Other end did not send RECEIPT. Read error.", bu->s);
  }
 errout:
#ifdef USE_OPENSSL
  if (bu->ssl) {
    SSL_shutdown(bu->ssl);
    SSL_free(bu->ssl);
    bu->ssl = 0;
  }
#endif
  closesocket((SOCKET)bu->fd);
  bu->fd = 0;
  return 0;
}

/*() Send the specified STOMP 1.1 message to audit bus and wait for RECEIPT.
 * Blocks until the transaction completes (or fails). Figures out
 * from configuration, which bus daemon to contact (looks at bus_urls).
 *
 * Returns:: zero on failure and 1 on success. */

/* Called by:  zxbus_send, zxbustailf_main */
int zxbus_send_cmd(zxid_conf* cf, const char* cmd, const char* dest, int n, const char* logbuf)
{
  struct zxid_bus_url* bu;
  bu = cf->bus_url;
  if (!bu || !bu->s || !bu->s[0])
    return 0;         /* No bus_url configured means audit bus reporting is disabled. */

  /* *** implement intelligent lbfo algo */

  if (!bu->fd)
    zxbus_open_bus_url(cf, bu);
  if (!bu->fd)
    return 0;
  return zxbus_send_cmdf(cf, bu, n, logbuf, "%s\ndestination:%s\nreceipt:%d\ncontent-length:%d\n\n", cmd, dest, bu->cur_rcpt++, n);
}

/*() SEND a STOMP 1.1 message to audit bus and wait for RECEIPT.
 * Blocks until the transaction completes (or fails). Figures out
 * from configuration, which bus daemon to contact (looks at bus_urls).
 *
 * Returns:: zero on failure and 1 on success. */

/* Called by:  zxbustailf_main x2 */
int zxbus_send(zxid_conf* cf, const char* dest, int n, const char* logbuf)
{
  return zxbus_send_cmd(cf, "SEND", dest, n, logbuf);
}

#if 0
/*(i) Log to activity and/or error log depending on ~res~ and configuration settings.
 * This is the main audit logging function you should call. Please see <<link:../../html/zxid-log.html: zxid-log.pd>>
 * for detailed description of the log format and features. See <<link:../../html/zxid-conf.html: zxid-conf.pd>> for
 * configuration options governing the logging. (*** check the links)
 *
 * Proper audit trail is essential for any high value transactions based on SSO. Also
 * some SAML protocol Processing Rules, such as duplicate detection, depend on the
 * logging.
 *
 * cf     (1)::  ZXID configuration object, used for configuration options and memory allocation
 * ourts  (2)::  Timestamp as observed by localhost. Typically the wall clock
 *     time. See gettimeofday(3)
 * srcts  (3)::  Timestamp claimed by the message to which the log entry pertains
 * ipport (4)::  IP address and port number from which the message appears to have originated
 * entid  (5)::  Entity ID to which the message pertains, usually the issuer. Null ok.
 * msgid  (6)::  Message ID, can be used for correlation to establish audit trail continuity
 *     from request to response. Null ok.
 * a7nid  (7)::  Assertion ID, if message contained assertion (outermost and first
 *     assertion if there are multiple relevant assertions). Null ok.
 * nid    (8)::  Name ID pertaining to the message
 * sigval (9)::  Signature validation letters
 * res   (10)::  Result letters
 * op    (11)::  Operation code for the message
 * arg   (12)::  Operation specific argument
 * fmt, ...  ::  Free format message conveying additional information
 * return:: 0 on success, nonzero on failure (often ignored as zxbus() is very
 *     robust and rarely fails - and when it does, situation is so hopeless that
 *     you would not be able to report its failure anyway)
 */

/* Called by:  zxid_an_page_cf, zxid_anoint_sso_a7n, zxid_anoint_sso_resp, zxid_chk_sig, zxid_decode_redir_or_post x2, zxid_fed_mgmt_cf, zxid_get_ent_by_sha1_name, zxid_get_ent_ss, zxid_get_meta x2, zxid_idp_dispatch, zxid_idp_select_zxstr_cf_cgi, zxid_idp_soap_dispatch x2, zxid_idp_soap_parse, zxid_parse_conf_raw, zxid_parse_meta, zxid_saml_ok x2, zxid_simple_render_ses, zxid_simple_ses_active_cf, zxid_sp_anon_finalize, zxid_sp_deref_art x5, zxid_sp_dig_sso_a7n x2, zxid_sp_dispatch, zxid_sp_meta, zxid_sp_mni_redir, zxid_sp_mni_soap, zxid_sp_slo_redir, zxid_sp_slo_soap, zxid_sp_soap_dispatch x2, zxid_sp_soap_parse, zxid_sp_sso_finalize x2, zxid_start_sso_url x3 */
int zxbus(zxid_conf* cf,   /* 1 */
	  struct timeval* ourts,  /* 2 null allowed, will use current time */
	  struct timeval* srcts,  /* 3 null allowed, will use start of unix epoch + 501 usec */
	  const char* ipport,     /* 4 null allowed, -:- or cf->ipport if not given */
	  struct zx_str* entid,   /* 5 null allowed, - if not given */
	  struct zx_str* msgid,   /* 6 null allowed, - if not given */
	  struct zx_str* a7nid,   /* 7 null allowed, - if not given */
	  struct zx_str* nid,     /* 8 null allowed, - if not given */
	  const char* sigval,     /* 9 null allowed, - if not given */
	  const char* res,        /* 10 */
	  const char* op,         /* 11 */
	  const char* arg,        /* 12 null allowed, - if not given */
	  const char* fmt, ...)   /* 13 null allowed as format, ends the line w/o further ado */
{
  int n;
  char logbuf[1024];
  va_list ap;
  
  /* Avoid computation if logging is hopeless. */
  
  if (!((cf->log_err_in_act || res[0] == 'K') && cf->log_act)
      && !(cf->log_err && res[0] != 'K')) {
    return 0;
  }

  va_start(ap, fmt);
  n = zxbus_fmt(cf, sizeof(logbuf), logbuf,
		ourts, srcts, ipport, entid, msgid, a7nid, nid, sigval, res,
		op, arg, fmt, ap);
  va_end(ap);
  return zxbus_output(cf, n, logbuf, res);
}
#endif

/* EOF  --  zxbusprod.c */
