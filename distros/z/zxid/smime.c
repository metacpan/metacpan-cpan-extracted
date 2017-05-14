/* smime.c  -  Command line tool for testing smimeutil.c
 *
 * Copyright (c) 1999 Sampo Kellomaki <sampo@iki.fi>, All Rights Reserved.
 * License: This software may be distributed under the same license
 *          terms as openssl (i.e. free, but mandatory attribution).
 *
 * Official web site:  http://zxid.org/Net_SSLeay/smime.html
 *
 * 11.9.1999, Created. --Sampo
 * 13.9.1999, added decryption and sig verification --Sampo
 * 25.10.1999, added query sig to know who signed --Sampo
 * 17.11.1999, added detached verification functions --Sampo
 *
 * Memory management: most routines malloc the results. Freeing them is
 * application's responsibility. I use libc malloc, but if in doubt
 * it might be safer to just leak the memory (i.e. don't ever free it).
 * This library works entirely in memory, so maximum memory consumption
 * might be more than twice the total size of all files to be encrypted.
 *
 * This tool is not generic in any sense (for that see openssl tool). It has
 * many choices hard wired in a way that is convenient for me. They are
 * just one way that works. There are many others equally good, but not
 * implemented here.
 *
gcc -c -g smimeutil.c -I/usr/local/ssl/include -o smimeutil.o
gcc -c -g smime.c -I/usr/local/ssl/include -o smime.o
gcc -g smime.o smimeutil.o -L/usr/local/ssl/lib -lcrypto -o smime
 *
 * ### For importing to browsers (S/MIME)
 * openssl pkcs12 -name "End-CA" -nokey -inkey ca-priv.pem -in ca-cert.pem -export >end-ca.p12
 *
 * ### Note: to arrange for delivery of the certificate, arrange
 * ### for web server to send it using mimetype (or extension)
 *	AddType application/x-x509-ca-cert .crt
 *	AddType application/x-pkcs7-crl    .crl
 *
 * ### then just copy the pem file under extension .crt
 */

#include "smimeutil.h"

char usage[] =
SMIME_VERSION "\n"
"Copyright (c) 1999 Sampo Kellomaki <sampo@iki.fi>. All Rights Reserved.\n"
"See file LICENSE in distribution directory for full copyright and license\n"
"information. This file also explains OpenSSL and SSLeay licenses.\n"
"Copyright (c) 1999 The OpenSSL Project.  All rights reserved.\n"
"This product includes software developed by the OpenSSL Project\n"
"for use in the OpenSSL Toolkit (http://www.openssl.org/)\n"
"Copyright (C) 1995-1998 Eric Young (eay@cryptsoft.com), All rights reserved.\n"
"This product includes cryptographic software written by Eric Young\n"
"(eay@cryptsoft.com).  This product includes software written by Tim\n"
"Hudson (tjh@cryptsoft.com).\n\n"

"Official web site:  http://zxid.org/Net_SSLeay/smime.html\n\n"

"./smime -cs private password <mime-entity >smime  # clear sign\n"
"./smime -cv cert <smime-entity >data              # verify clear signature\n"
"./smime -ds private passwd <file >smime-sig       # make detached signature\n"
"./smime -dv file <cert+sig-entity                 # verify detached sig\n"
"./smime -s  private password <mime-entity >smime  # sign\n"
"./smime -qs <smime-entity >signing-cert-info      # find out who signed\n"
"./smime -v cert <smime-entity >signer-dn          # verify signature\n\n"
"./smime -vc cacert <cert                          # verify certificate\n\n"
"./smime -e public <mime-entity >smime-ent         # encrypt\n"
"./smime -d private password <smime-entity >mime   # decrypt\n\n"
"./smime -qr <req.pem    # Query all you can about request\n"
"./smime -qc <cert.pem   # Query all you can about certificate\n"
"./smime -ca ca_cert passwd serial <req.pem >cert.pem # sign a req into cert\n\n"
"./smime -p12-pem p12pw pempw <x.p12 >x.pem  # convert PKCS12 to pem\n"
"./smime -pem-p12 frindly@name.com pempw p12pw <x.pem >x.p12  # pem to PKCS12\n\n"
"./smime -m type1 file1 type2 file2 type3 file3 <text  # make multipart\n"
"./smime -m image/gif foo.gif <message | ./smime -s private pass >smime\n\n"
"./smime -kg attr passwd req.pem <dn >priv_ss.pem  # keygen\n\n"
"./smime -base64 <file >file.base64\n"
"./smime -unbase64 <file.base64 >file\n"
"./smime -mime text/plain <file >mime-entity\n"
"./smime -mime_base64 image/gif <file.gif >mime-entity\n"
"./smime -split dirprefix <multipart         # splits multipart into files\n"
"./smime -base64 <in | ./smime -unbase64 >out\n"
"./smime -cat <in >out   # copy input to output using slurp and barf\n\n"
"./smime -kg 'description=Test' secret req.pem <me.dn >ss.pem\n\n"
"echo 'countryName=PT|organizationName=Universidade|organizationalUnitName=IST|commonName=t11|emailAddress=t11@test.com' | ./smime -kg 'description=t11' secret r11.pem | tee t11.pem | ./smime -pem-p12 t11@test.com secret secret >t11.p12\n\n"
"./smime -p12-pem secret secret <t.p12 | ./smime -qc\n"
"./smime -m image/gif a.gif <text | ./smime -cs both.pem 1234 | ./smime -e both.pem | ./send.pl\n\n"
"WARNING: passing passwords on command line or environment is not secure. \n"
"  You can pass\n"
"  -\\d+     (`-' and a number) to cause the password to be read from fd, or\n"
"  -[A-Z]+  to cause the password to be taken from an environment variable.\n"
"  Like this: ./smime -s priv.pem -3 <me >sme\n"
"  The file descriptor method is the safest. Be careful.\n"
;

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define DETACHED_SIG_TYPE_FILE  "application/x-detached-file-signature-file"

/* Read all of a file descriptor to malloc'd buffer, return size.
 * This repeatedly reallocs the buffer (probably internally copying
 * the contents each time). This is a bit inefficient, but will do
 * for quick and dirty now.
 */

/* Called by:  get_passwd, main x22, mk_multipart, read_file */
static int slurp(FILE* fd, char** pb)
{
  int n = 0;
  int nn;
  if (!fd) /*return -1*/ exit(1);;
  if (!pb) /*return -1*/ exit(1);;
  if ((*pb = (char*)malloc(4097))==NULL) /*return -1;*/ exit(1);

  for(;;) {
    nn = fread((*pb)+n, 1, 4096, fd);
    if (nn <= 0) break;
    n+=nn;
    if ((*pb = (char*)realloc(*pb, n+4097))==NULL) /*return -1;*/ exit(1);
  }
  if (nn<0) /*return -1*/ exit(1);;
  
  /* add NULL termination and shrink the buffer */
  
  (*pb)[n] = '\0';
  if ((*pb = (char*)realloc(*pb, n+1))==NULL) /*return -1*/ exit(1);;
  return n;  /* returns file length */
}

/* Called by:  main x12, write_file */
static int barf(FILE* fd, char* b, int len)
{
  int n = 0;
  int nn;
  if (!fd) return -1;
  if (!b) return -1;

  for (;;) {
    /*nn = fwrite(b+n, 1, (len - n) > 4096 ? 4096 : (len-n), fd);*/
    nn = fwrite(b+n, 1, (len - n), fd);
    if (nn <= 0) break;
    n+=nn;
  }
  if (nn<0) return -1;
  return n;
}

/* Called by:  main x10, mk_multipart x3 */
static int read_file(char* file, char* type, char** data) {
  FILE* fd;
  int n;

  if (!(fd = fopen(file, "rb"))) {
    fprintf(stderr, "File `%s' not found? (type=%s)\n", file, type);
    perror(file);
    exit(1);
  }
  n = slurp(fd, data);
  fclose(fd);
  return n;   /* returns file length */
}

/* Called by:  main x2 */
static int write_file(char* file, char* type, char* data, int len) {
  FILE* fd;
  int n;

  if (!(fd = fopen(file, "wb"))) {
    fprintf(stderr, "Cant write file `%s' (type=%s)\n", file, type);
    perror(file);
    exit(1);
  }
  n = barf(fd, data, len);
  fclose(fd);
  return n;
}

/* --------------------- */

/* Get password from file descriptor or environment variable */

/* Called by:  main x10 */
const char* get_passwd(const char* pass)
{
  FILE* in = NULL;
  char* p;
  int fd;
  
  if (pass[0] != '-') return pass;
  p = (char*)(pass+1);
  if (strlen(p) == strspn(p, "ABCDEFGHIJKLMNOPQRSTUVWXYZ")) {
    /* Environment */
    if (!(p = getenv(p))) {
      fprintf(stderr, "No password environment variable `%s'\n", pass);
      exit(1);
    }
    return p;
  }
  
  if (strlen(p) != strspn(p, "0123456789")) return pass;
  
  /* Read it from file descriptor */

  fd = atoi(p);
  if (!(in = fdopen(fd, "r"))) {
    fprintf(stderr, "Cant open file descriptor %d for reading password\n", fd);
    perror("fdopen");
    exit(1);
  }
  slurp(in, &p);
  return p;
}

/* --------------------- */

/* Called by:  main */
static char* mk_multipart (int ac, char* av[]) {
    char* text;
    char* f1 = NULL;
    char* f2 = NULL;
    char* f3 = NULL;
    char* t1 = NULL;
    char* t2 = NULL;
    char* t3 = NULL;
    char* n1 = NULL;
    char* n2 = NULL;
    char* n3 = NULL;
    int l1 = 0, l2 = 0, l3 = 0;

    /* Read attachment files, if any */

    av++; ac--;
    if (ac>1) {
      t1 = *av;
      av++; ac--;
      l1 = read_file(n1=*av, t1, &f1);

      av++; ac--;
      if (ac>1) {
	t2 = *av;
	av++; ac--;
	l2 = read_file(n2=*av, t2, &f2);
	
	av++; ac--;
	if (ac>1) {
	  t3 = *av;
	  av++; ac--;
	  l3 = read_file(n3=*av, t3, &f3);
	}
      }
    }

    /* Read text from stdin */
    
    slurp(stdin, &text);
    
    return mime_mk_multipart(text,
			     f1, l1, t1, n1,
			     f2, l2, t2, n2,
			     f3, l3, t3, n3);    
}

#define TOO_FEW_OPTIONS(ac,n,s) if ((ac)<(n)) { \
      fprintf(stderr, "%s needs %d arguments (%d supplied).\n%s", (s), n, ac, \
      usage); exit(1); }

/* ===== M A I N ===== */

/* Called by: */
int main(int ac, char* av[]) {
  av++; ac--;

  if (ac < 1) {
    fprintf(stderr, "Too few options. Need to provide a command switch.\n%s",
	    usage);
    exit(1);
  }

  smime_init("random.txt", "ssaddsfa", 8 );
  
  /* ./smime -base64 <file >file.base64 */
  if (!strcmp(*av, "-base64")) {
    int n, nn;
    char* b;
    char* b64;
    n = slurp(stdin, &b);
    nn = smime_base64(1, b, n, &b64);
    fprintf(stderr, "%d bytes in, %d bytes out\n", n, nn);
    barf(stdout, b64, nn);
    exit(nn > 0 ? 0 : 1);
  }

  /* ./smime -unbase64 <file.base64 >file */
  if (!strcmp(*av, "-unbase64")) {
    int n, nn;
    char* b;
    char* b64;
    n = slurp(stdin, &b);
    nn = smime_base64(0, b, n, &b64);
    fprintf(stderr, "%d bytes in, %d bytes out\n", n, nn);
    barf(stdout, b64, nn);
    exit(nn > 0 ? 0 : 1);
  }

  /* ./smime -cat <in >out */
  if (!strcmp(*av, "-cat")) {
    int n;
    char* b;
    n = slurp(stdin, &b);
    fprintf(stderr, "%d bytes\n", n);
    barf(stdout, b, n);
    exit(n > 0 ? 0 : 1);
  }
  
  /* ./smime -mime text/plain <file >mime-entity */
  if (!strcmp(*av, "-mime")) {
    int n, nn;
    char* b;
    char* b64;

    ac--; av++;
    TOO_FEW_OPTIONS(ac,1,"-mime");

    n = slurp(stdin, &b);
    b64 = mime_raw_entity(b, av[0]);
    fprintf(stderr, "%d bytes in, %d bytes out\n", n, nn=strlen(b64));
    barf(stdout, b64, nn);
    exit(nn > 0 ? 0 : 1);
  }

  /* ./smime -split dirprefix <multipart   # splits multipart into files */
  if (!strcmp(*av, "-split")) {
    int n, nn;
    char* b;
    char* parts[100];
    int lengths[100];
    char file[4096];

    ac--; av++;
    TOO_FEW_OPTIONS(ac,1,"-split");
    
    n = slurp(stdin, &b);
    if ((nn = mime_split_multipart(b, 100, parts, lengths))==-1) {
      fprintf(stderr, "mime error\n%s", smime_get_errors());
      exit(1);
    }
    
    /* Write out the parts */
    
    for (n = 0; n < nn; n++) {
      snprintf(file, sizeof(file), "%s%d", av[0], n);
      fprintf(stderr, "%s\n", file);
      write_file(file, "part", parts[n], lengths[n]);      
    }
    
    exit(0);
  }

  /* ./smime -mime_base64 image/gif <file.gif >mime-entity */
  if (!strcmp(*av, "-mime_base64")) {
    int n, nn;
    char* b;
    char* b64;

    ac--; av++;
    TOO_FEW_OPTIONS(ac,1,"-mime_base64");

    n = slurp(stdin, &b);
    b64 = mime_base64_entity(b, n, av[0]);
    fprintf(stderr, "%d bytes in, %d bytes out\n", n, nn=strlen(b64));
    barf(stdout, b64, nn);
    exit(nn > 0 ? 0 : 1);
  }

  /* ./smime -m type1 file1 type2 file2 type3 file3 <text  # make multipart */
  if (!strcmp(*av, "-m")) {
    char* mime;
    if (!(mime = mk_multipart(ac, av))) exit(1);
    barf(stdout, mime, strlen(mime));
    exit(0);
  }
  
  /* ./smime -cs private password <mime-entity >smime */
  if (!strcmp(*av, "-cs")) {
    char* smime;
    char* mime;
    char* privkey;

    ac--; av++;
    TOO_FEW_OPTIONS(ac,2,"-cs");

    slurp(stdin, &mime);
    read_file(av[0], "privkey", &privkey);

    if (!(smime = smime_clear_sign(privkey, get_passwd(av[1]), mime))) {
      fprintf(stderr, "crypto error\n%s", smime_get_errors());
      exit(1);
    }
    barf(stdout, smime, strlen(smime));
    exit(0);
  }

  /* ./smime -s  private password <mime-entity >smime */
  if (!strcmp(*av, "-s")) {
    char* smime;
    char* mime;
    char* privkey;

    ac--; av++;
    TOO_FEW_OPTIONS(ac,2,"-s");

    slurp(stdin, &mime);
    read_file(av[0], "privkey", &privkey);

    if (!(smime = smime_sign(privkey, get_passwd(av[1]), mime))) {
      fprintf(stderr, "crypto error\n%s", smime_get_errors());
      exit(1);
    }
    barf(stdout, smime, strlen(smime));
    exit(0);
  }
  
  /* ./smime -v cert <smime-entity >signer-dn          # verify sig */
  if (!strcmp(*av, "-v")) {
    char* cert;
    char* smime;
    char* signed_data;
    int n = slurp(stdin, &smime);

    ac--; av++;
    TOO_FEW_OPTIONS(ac,1,"-v");

    fprintf(stderr, "%d bytes in\n", n);    
    read_file(av[0], "cert", &cert);    

    if (!(signed_data = smime_verify_signature(cert, smime, NULL, 0))) {
      fprintf(stderr, "crypto error\n%s", smime_get_errors());
      exit(1);
    }
    fputs(signed_data, stdout);  /* careful not to output trailing newline */
    exit(0);
  }

  /* ./smime -cv cert <smime-entity >signer-dn    # verify clear signature */
  if (!strcmp(*av, "-cv")) {
    char* cert;
    char* smime;
    char* parts[2];  /* parts[0] is the clear text, parts[1] is the sig */
    int lengths[2];
    char* signed_data;
    int n = slurp(stdin, &smime);
    
    ac--; av++;
    TOO_FEW_OPTIONS(ac,1,"-cv");
    
    fprintf(stderr, "%d bytes in\n", n);
    read_file(av[0], "cert", &cert);    
    
    /* multipart/signed has always exactly two parts */
    
    if (mime_split_multipart(smime, 2, parts, lengths) != 2) {
      fprintf(stderr, "mime error\n%s", smime_get_errors());
      exit(1);
    }
    
    if (!(signed_data =
	  smime_verify_signature(cert, parts[1] /*sig*/,
				 parts[0] /*plain*/, lengths[0]))) {
      fprintf(stderr, "crypto error\n%s", smime_get_errors());
      exit(1);
    }
    fputs(signed_data, stdout);  /* careful not to output trailing newline */
    exit(0);
  }
  
  /* ./smime -vc cacert <cert  # verify certificate */
  if (!strcmp(*av, "-vc")) {
    char* cert;
    char* ca_cert;
    int x;
    int n = slurp(stdin, &cert);
    
    ac--; av++;
    TOO_FEW_OPTIONS(ac,1,"-vc");

    fprintf(stderr, "%d bytes in\n", n);    
    read_file(av[0], "ca_cert", &ca_cert);    
    
    x = smime_verify_cert(ca_cert, cert);

    if (x == 1) {
      printf("OK\n");
      exit(0);
    }

    if (x == 0) {
      printf("NOT OK\n");
      exit(2);
    }

    fprintf(stderr, "crypto error\n%s", smime_get_errors());
    exit(1);
  }

  /* ./smime -ds private passwd <file >smime-sig  # make detached signature */

  if (!strcmp(*av, "-ds")) {
    char* file;
    char* smime;
    char* mime;
    char* privkey;
    char* parts[2];  /* parts[0] is the clear text, parts[1] is the sig */
    int lengths[2];
    int n;

    ac--; av++;
    TOO_FEW_OPTIONS(ac,2,"-ds");

    n = slurp(stdin, &file);
    read_file(av[0], "privkey", &privkey);
    
    if (!(mime = mime_base64_entity(file, n, DETACHED_SIG_TYPE_FILE))) {
      fprintf(stderr, "mime error\n%s", smime_get_errors());
      exit(1);
    }

    if (!(smime = smime_clear_sign(privkey, get_passwd(av[1]), mime))) {
      fprintf(stderr, "crypto error\n%s", smime_get_errors());
      exit(1);
    }

    if (mime_split_multipart(smime, 2, parts, lengths) != 2) {
      fprintf(stderr, "mime error\n%s", smime_get_errors());
      exit(1);
    }
    
    barf(stdout, parts[1], lengths[1]);
    exit(0);
  }

  /* ./smime -dv file <sig+cert  # verify detached signature */

  if (!strcmp(*av, "-dv")) {
    char* sig;
    char* file;
    char* cert;
    char* mime;
    char* canon;
    char* p;
    char c;
    int n;

    ac--; av++;
    TOO_FEW_OPTIONS(ac,1,"-dv");

    n = slurp(stdin, &sig);
    if (!(p = strstr(sig, "-----BEGIN CERTIFICATE-----"))) {
      fprintf(stderr, "No certificate found in stdin.\n");
      exit(1);
    }

    if (p == sig) {
      /* Certificate first, then signature */
      
      if (!(p = strstr(sig, "-----END CERTIFICATE-----"))) exit(1);
      p+=strlen("-----END CERTIFICATE-----");
      if (*p == '\015') p++;
      if (*p == '\012') p++;
      c = p[0];
      p[0] = '\0';
      cert = strdup(sig);
      p[0] = c;
      sig = p;

    } else {

      /* Signature first, then certificate */

      p[0] = '\0';
      sig = strdup(sig);
      p[0] = '-';
      cert = p;
    }

    n = read_file(av[0], "file", &file);
    
    /* wrap the file in mime entity */

    if (!(mime = mime_base64_entity(file, n, DETACHED_SIG_TYPE_FILE))) {
      fprintf(stderr, "mime error\n%s", smime_get_errors());
      exit(1);
    }

    /* Must canonize, otherwise the sig will not verify */

    if (!(canon = mime_canon(mime))) {
      fprintf(stderr, "canon error\n%s", smime_get_errors());
      exit(1);
    }
    
    if (!smime_verify_signature(cert, sig, canon, strlen(canon))) {
      fprintf(stderr, "crypto error\n%s", smime_get_errors());
      exit(1);
    }
    printf("Signature verified OK.\n");
    exit(0);
  }
  
  /* ./smime -e public <mime-entity >smime-ent */
  if (!strcmp(*av, "-e")) {
    char* smime;
    char* mime;
    char* cert;

    ac--; av++;
    TOO_FEW_OPTIONS(ac,1,"-e");
    
    slurp(stdin, &mime);
    read_file(av[0], "cert", &cert);

    if (!(smime = smime_encrypt(cert, mime))) {
      fprintf(stderr, "crypto error\n%s", smime_get_errors());
      exit(1);
    }
    barf(stdout, smime, strlen(smime));
    exit(0);
  }

  /* ./smime -d private password <smime-entity >mime   # decrypt */
  if (!strcmp(*av, "-d")) {
    char* smime;
    char* mime;
    char* privkey;
    int n;

    ac--; av++;
    TOO_FEW_OPTIONS(ac,2,"-d");
    
    n = slurp(stdin, &smime);
    read_file(av[0], "privkey", &privkey);
    
    if ((n = smime_decrypt(privkey, get_passwd(av[1]), smime, &mime)) < 0) {
      fprintf(stderr, "crypto error\n%s", smime_get_errors());
      exit(1);
    }
    barf(stdout, mime, n);
    exit(0);
  }

  /* ./smime -kg attr password priv_x509ss.pem req.pem <dn >modulus */

  if (!strcmp(*av, "-kg")) {
    char* dn;
    char* priv;
    char* x509ss;
    char* request;

    ac--; av++;
    TOO_FEW_OPTIONS(ac,2,"-kg");
    
    slurp(stdin, &dn);
    
    if (smime_keygen(dn, av[0] /*attr*/, get_passwd(av[1]),
	     "Test certificate. See http://www.bacus.pt/Net_SSLeay/smime.html",
	     &priv, &x509ss, &request)<0) {
      fprintf(stderr, "crypto error\n%s", smime_get_errors());
      exit(1);
    }
    
    puts(priv);
    puts(x509ss);    
    write_file(av[2], "pem", request, strlen(request));
    exit(0);
  }
  
  /* ./smime -qr <req.pem    # Query all you can about request */
  
  if (!strcmp(*av, "-qr")) {
    char* req;
    char* name;
    char* attr;
    char* mod;
    char* md5;
    char* hash;
    char block1[14];
    int n = slurp(stdin, &req);
    fprintf(stderr, "%d bytes in\n", n);    

    if (!(name = smime_get_req_name(req))) {
      fprintf(stderr, "crypto error\n%s", smime_get_errors());
      exit(1);
    }
    puts(name);

    if (!(attr = smime_get_req_attr(req))) {
      fprintf(stderr, "crypto error\n%s", smime_get_errors());
      exit(1);
    }
    puts(attr);

    if (!(mod = smime_get_req_modulus(req))) {
      fprintf(stderr, "crypto error\n%s", smime_get_errors());
      exit(1);
    }
    puts(mod);

    if (!(md5 = smime_md5(mod))) {
      fprintf(stderr, "crypto error\n%s", smime_get_errors());
      exit(1);
    }
    puts(md5);

    if (!(hash = smime_get_req_hash(req))) {
      fprintf(stderr, "crypto error\n%s", smime_get_errors());
      exit(1);
    }
    memcpy(block1, hash, 13);
    block1[13] = '\0';
    printf("\n*%s*\n*%s*\n", block1, hash+13);
    exit(0);
  }
  
  /* ./smime -qc <cert.pem   # Query all you can about certificate */
  
  if (!strcmp(*av, "-qc")) {
    char* cert;
    char* name;
    char* issuer;
    char* fingerprint;
    char* mod;
    char* md5;
    long serial;
    int n = slurp(stdin, &cert);
    fprintf(stderr, "%d bytes in\n", n);    

    if ((serial = smime_get_cert_names(cert, &name, &issuer)) == -1) {
      fprintf(stderr, "crypto error\n%s", smime_get_errors());
      exit(1);
    }
    puts(name);
    puts(issuer);
    printf("serial: %ld\n", serial);
    
    if ((serial = smime_get_cert_info(cert, &mod, &fingerprint)) == -1) {
      fprintf(stderr, "crypto error\n%s", smime_get_errors());
      exit(1);
    }
    
    printf("serial: %ld\n", serial);
    
    puts(fingerprint);
    puts(mod);
    
    if (!(md5 = smime_md5(mod))) {
      fprintf(stderr, "crypto error\n%s", smime_get_errors());
      exit(1);
    }
    puts(md5);
    exit(0);
  }

  /* ./smime -qs <smime-entity >signing-cert-info
   * find out who signed (query sig) */
  if (!strcmp(*av, "-qs")) {
    char* issuer;
    char* signed_entity;
    long serial;
    int sig_count = 0;
    int n = slurp(stdin, &signed_entity);
    fprintf(stderr, "%d bytes in\n", n);
    
    while ((serial = smime_get_signer_info(signed_entity,
					   sig_count, &issuer)) != -1) {
      puts(issuer);
      printf("serial: %ld\n", serial);
      sig_count++;
    }
    if (!sig_count) {
      fprintf(stderr, "crypto error\n%s", smime_get_errors());
      exit(1);
    }
    exit(0);
  }

  /* ./smime -ca ca_cert passwd serial <req.pem >cert.pem */

  if (!strcmp(*av, "-ca")) {
    char* req;
    char* ca_cert;
    char* cert;    
    slurp(stdin, &req);
    
    ac--; av++;
    TOO_FEW_OPTIONS(ac,3,"-ca");
    
    read_file(av[0], "ca_cert_pem", &ca_cert);
    
    if (!(cert = smime_ca(ca_cert, get_passwd(av[1]), req,
			  "today", "days:365", atoi(av[2]),
			  "CA:TRUE,pathlen:3",
			  "client,server,email,objsign,sslCA,emailCA,objCA",
			  "digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment,keyAgreement,keyCertSign,cRLSign",
			  "Test certificate. See http://www.bacus.pt/Net_SSLeay/smime.html"))) {
      fprintf(stderr, "crypto error\n%s", smime_get_errors());
      exit(1);
    }
    puts(cert);
    exit(0);
  }

  /* ./smime -p12-pem imppw0 exppw1 <x.p12 >x.pem */

  if (!strcmp(*av, "-p12-pem")) {
    char* x;
    char* pk;
    char* cert;
    int n = slurp(stdin, &x);

    ac--; av++;
    TOO_FEW_OPTIONS(ac,2,"-p12-pem");
    
    if (smime_pkcs12_to_pem(x, n, get_passwd(av[0]), get_passwd(av[1]),
			    &pk, &cert) == -1) {
      fprintf(stderr, "crypto error\n%s", smime_get_errors());
      exit(1);
    }

    puts(pk);
    puts(cert);
    exit(0);
  }

  /* ./smime -pem-p12 frindly@name0 pw1 pw2 <x.pem >x.p12 */

  if (!strcmp(*av, "-pem-p12")) {
    char* x;
    char* pkcs12;
    int n = slurp(stdin, &x);
    
    ac--; av++;
    TOO_FEW_OPTIONS(ac,3,"-pem-p12");
    
    if ((n = smime_pem_to_pkcs12(av[0], x /*cert*/, x /*privkey*/,
				 get_passwd(av[1]), get_passwd(av[2]),
				 &pkcs12)) == -1) {
      fprintf(stderr, "crypto error\n%s", smime_get_errors());
      exit(1);
    }
    
    barf(stdout, pkcs12, n);
    exit(0);
  }
  
  fprintf(stderr, "Unknown option.\n%s", usage);
  return 1;
}

/* EOF  -  smime.c */
