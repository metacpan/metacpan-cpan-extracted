/* zxcot.c  -  CoT (Circle-of-Trust) management tool: list CoT, add metadata to CoT
 * Copyright (c) 2012 Synergetics SA (sampo@synergetics.be), All Rights Reserved.
 * Copyright (c) 2009-2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxcot.c,v 1.5 2009-11-29 12:23:06 sampo Exp $
 *
 * 27.8.2009, created --Sampo
 * 24.4.2012, obsoleted PATH=/var/zxid/idp. From now on, just use /var/zxid/ or VPATH --Sampo
 */

#include "platform.h"  /* for dirent.h */

#include <string.h>
#include <stdio.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/stat.h>  /* for mkdir(2) */

#include "errmac.h"
#include "zx.h"
#include "zxid.h"
#include "zxidutil.h"
#include "zxidconf.h"
#include "c/zxidvers.h"
#include "c/zx-const.h"
#include "c/zx-ns.h"
#include "c/zx-data.h"

char* help =
"zxcot  -  Circle-of-Trust and metadata management tool R" ZXID_REL "\n\
Copyright (c) 2012-2013 Synergetics SA (sampo@synergetics.be), All Rights Reserved.\n\
Copyright (c) 2009-2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.\n\
NO WARRANTY, not even implied warranties. Licensed under Apache License v2.0\n\
See http://www.apache.org/licenses/LICENSE-2.0\n\
Send well researched bug reports to the author. Home: http://zxid.org\n\
\n\
Usage: zxcot [options] [cotdir]         # Gives listing of metadata\n\
       zxcot -c CPATH=/var/zxid/ -dirs  # Creates directory hierarchy\n\
       zxcot -a [options] [cotdir] <meta.xml  # Import metadata\n\
       zxcot -b [options] [dimddir] <epr.xml  # Register EPR\n\
       curl https://site.com/metadata.xml | zxcot -a [options] [cotdir]\n\
       zxcot -g https://site.com/metadata.xml [options] [cotdir]\n\
       zxcot -m [options] >meta.xml     # Generate our own metadata\n\
       zxcot -p https://site.com/metadata.xml\n\
  [dir]            CoT directory. Default /var/zxid/cot\n\
  -c CONF          Optional configuration string (default -c CPATH=/var/zxid/)\n\
                   Most of the configuration is read from " ZXID_CONF_PATH "\n\
                   N.B. If VURL and/or VPATH are used, you should set\n\
                   environment variables that affect virtualization, e.g.\n\
                     HTTP_HOST=example.com:8443 SERVER_PORT=8443 SCRIPT_NAME=zxidhlo zxcot -m\n\
  -ci              IdP conf, synonym for -c IDP_ENA=1\n\
  -dirs            Create configuration directory hierarchy\n\
  -a               Add (someone else's) metadata from stdin\n\
  -b               Register Web Service, add Service EPR from stdin\n\
  -bs              Register Web Service and Bootstrap, add Service EPR from stdin\n\
  -e endpoint abstract entid servicetype   Construct and dump EPR to stdout.\n\
  -g URL           Do HTTP(S) GET to URL (aka WKL) and add as metadata (if compiled w/libcurl)\n\
  -sign            Sign imported metadata (used with -a or -g). Used for Metadata Authority.\n\
  -n               Dryrun. Do not actually add the metadata. Instead print it to stdout.\n\
  -s               Swap columns, for easier sorting by URL\n\
  -m               Output metadata of this installation (our own metadata). Caveat: If your\n\
                   own code, or virtual hosting, sets options like URL, you need to supply\n\
                   them with appropriate -c CONF option. zxcot is not able to guess them!\n\
  -p ENTID         Print sha1 name corresponding to an entity ID.\n\
  -v               Verbose messages.\n\
  -q               Be extra quiet.\n\
  -d               Turn on debugging.\n\
  -dc              Dump configuration.\n\
  -h               This help message\n\
  --               End of options\n\
\n\
HTTP_HOST=idp.cloud-identity.eu SCRIPT_NAME=/idp e2etacot -c 'CPATH=/d/relifex/e2eta/' -m\n\
zxcot -e http://idp.tas3.pt:8081/zxididp?o=S 'TAS3 Default Discovery Service (ID-WSF 2.0)' http://idp.tas3.pt:8081/zxididp?o=B urn:liberty:disco:2006-08 | zxcot -b\n\
\n";

#define ZXID_MAX_MD (256*1024)

int sign_md = 0;
int swap = 0;
int addmd = 0;
int regsvc = 0;
int regbs = 0;
int genmd = 0;
int dryrun = 0;
int inflate_flag = 2;  /* Auto */
int verbose = 1;
char buf[ZXID_MAX_MD+1] = "PATH=/var/zxid/";
char* mdurl = 0;
char* entid = 0;
char* cotdir;
char* dimddir;
char* uiddir;
zxid_conf* cf = 0;

static void zx_mkdirs();

/* Called by:  main x8, zxbusd_main, zxbuslist_main, zxbustailf_main, zxcall_main, zxcot_main, zxdecode_main */
static void opt(int* argc, char*** argv, char*** env)
{
  int len;
  struct zx_str* ss;
  
  if (*argc <= 1) goto path_to_dir;
  
  while (1) {
    ++(*argv); --(*argc);
    
    if (!(*argc) || ((*argv)[0][0] != '-')) break;  /* normal exit from options loop */
    
    switch ((*argv)[0][1]) {
    case '-': if ((*argv)[0][2]) break;
      ++(*argv); --(*argc);
      DD("End of options by --");
      return;  /* -- ends the options */

    case 'a':
      switch ((*argv)[0][2]) {
      case '\0':
	++addmd;
	continue;
      }
      break;

    case 'b':
      switch ((*argv)[0][2]) {
      case 's':
	++regsvc;
	++regbs;
	continue;
      case '\0':
	++regsvc;
	continue;
      }
      break;

    case 'c':
      switch ((*argv)[0][2]) {
      case 'i':
	switch ((*argv)[0][3]) {
	case '\0':
	  cf->idp_ena = 1;
	  zxid_parse_conf(cf, buf); /* buf was statically initialised to "PATH=/var/zxid/" */
	  continue;
	}
	break;
      case '\0':
	++(*argv); --(*argc);
	if ((*argc) < 1) break;
	zxid_parse_conf(cf, (*argv)[0]);
	continue;
      }
      break;

    case 'e':
      switch ((*argv)[0][2]) {
      case '\0':
	if ((*argc) < 4) break;
	printf(
"<a:EndpointReference xmlns:a=\"http://www.w3.org/2005/08/addressing\" "
"xmlns:wsu=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd\" "
    "notOnOrAfter=\"2037-01-05T23:03:59.001Z\" "
    "wsu:Id=\"EPRID92lFPo3ZNEt_3rHtJFoU\">"
  "<a:Address>%s</a:Address>"
  "<a:Metadata>"
    "<sbf:Framework xmlns:sbf=\"urn:liberty:sb\" version=\"2.0\"></sbf:Framework>"
    "<di:Abstract xmlns:di=\"urn:liberty:disco:2006-08\">%s</di:Abstract>"
    "<di:ProviderID xmlns:di=\"urn:liberty:disco:2006-08\">%s</di:ProviderID>"
    "<di:ServiceType xmlns:di=\"urn:liberty:disco:2006-08\">%s</di:ServiceType>"
  "</a:Metadata>"
"</a:EndpointReference>", (*argv)[1], (*argv)[2], (*argv)[3], (*argv)[4]);
	exit(0);
      }
      break;

    case 'g':
      switch ((*argv)[0][2]) {
      case '\0':
	++(*argv); --(*argc);
	if ((*argc) < 1) break;
	mdurl = (*argv)[0];
	++addmd;
	continue;
      }
      break;

    case 'd':
      switch ((*argv)[0][2]) {
      case '\0':
	++errmac_debug;
	continue;
      case 'c':
	ss = zxid_show_conf(cf);
	fprintf(stderr, "\n======== CONF ========\n%.*s\n^^^^^^^^ CONF ^^^^^^^^\n",ss->len,ss->s);
	continue;
      }
      if (!strcmp((*argv)[0],"-dirs")) {
	zx_mkdirs();
	exit(0);
      }
      break;

    case 's':
      switch ((*argv)[0][2]) {
      case '\0':
	++swap;
	continue;
      case 'i':
	if (!strcmp((*argv)[0],"-sign")) {
	  sign_md = 1;
	  continue;
	}
	break;
      }
      break;

    case 'p':
      switch ((*argv)[0][2]) {
      case '\0':
	++(*argv); --(*argc);
	if ((*argc) < 1) break;
	entid = (*argv)[0];
	continue;
      }
      break;

    case 'm':
      switch ((*argv)[0][2]) {
      case '\0':
	++genmd;
	continue;
      }
      break;

    case 'n':
      switch ((*argv)[0][2]) {
      case '\0':
	++dryrun;
	continue;
      }
      break;

#if 0
    case 'l':
      switch ((*argv)[0][2]) {
      case 'i':
	if (!strcmp((*argv)[0],"-license")) {
	  extern char* license;
	  fprintf(stderr, license);
	  exit(0);
	}
	break;
      }
      break;
#endif

    case 'q':
      switch ((*argv)[0][2]) {
      case '\0':
	verbose = 0;
	continue;
      }
      break;

    case 'v':
      switch ((*argv)[0][2]) {
      case '\0':
	++verbose;
	continue;
      }
      break;

    } 
    /* fall thru means unrecognized flag */
    if (*argc)
      fprintf(stderr, "Unrecognized flag `%s'\n", (*argv)[0]);
    if (verbose>1) {
      printf("%s", help);
      exit(0);
    }
    fprintf(stderr, "%s", help);
    /*fprintf(stderr, "version=0x%06x rel(%s)\n", zxid_version(), zxid_version_str());*/
    exit(3);
  }
  if (*argc) {
    uiddir = dimddir = cotdir = (*argv)[0];
    len = strlen(cotdir);
    if (cotdir[len-1] != '/') {  /* Append slash as that is required */
      cotdir = malloc(len+1);
      strcpy(cotdir, (*argv)[0]);
      cotdir[len] = '/';
      cotdir[++len] = 0;
      uiddir = dimddir = cotdir;
    }
    if (!strcmp(uiddir+len-sizeof("/dimd/")+1, "/dimd/")) {
      uiddir = strdup(uiddir);
      strcpy(uiddir+len-sizeof("/dimd/")+1, "/uid/");
    }
  } else {
path_to_dir:
    len = strlen(cf->cpath);
    cotdir = malloc(len+sizeof(ZXID_COT_DIR));
    strcpy(cotdir, cf->cpath);
    strcpy(cotdir+len, ZXID_COT_DIR);

    dimddir = malloc(len+sizeof(ZXID_DIMD_DIR));
    strcpy(dimddir, cf->cpath);
    strcpy(dimddir+len, ZXID_DIMD_DIR);

    uiddir = malloc(len+sizeof(ZXID_UID_DIR));
    strcpy(uiddir, cf->cpath);
    strcpy(uiddir+len, ZXID_UID_DIR);
  }
}

/* --------- Make zxid config directories --------- */

static const char* mkdirs_list[] = {
"ses",
"user",
"uid",
"nid",
"log",
"log/rely",
"log/issue",
"pem",
"cot",
"inv",
"dimd",
"dcr",
"rsr",
"uid/.all",
"uid/.all/.bs",
"tmp",
"ch",
"ch/default",
"ch/default/.ack",
"ch/default/.del"
};

/* Called by:  opt */
static void zx_mkdirs()
{
  char path[ZXID_MAX_BUF];
  char* p;
  const char** dir;
  int len;
  struct stat st;
  
#define ZXID_PATH_LENGTH_MARGIN (sizeof("ch/default/.del")+10) /* Accommodate longest subdir */
  len = snprintf(path, sizeof(path)-ZXID_PATH_LENGTH_MARGIN, "%s", cf->cpath);
  if (len > sizeof(path)-ZXID_PATH_LENGTH_MARGIN) {
    ERR("CPATH %s too long. len=%d, space=%d", cf->cpath, len, (int)(sizeof(path)-ZXID_PATH_LENGTH_MARGIN));
    exit(1);
  }

  for (p = path+len-1; p > path && *p != '/'; --p) ;  /* Handle CPATH=/var/zxid/idp */

  if (MKDIR(path, 02770) < 0) {
    if (errno == EEXIST) {
      INFO("Directory %s already exists. Will still try to create hierarchy under it.", path);
    } else {
      ERR("Failed to create directory hierarchy at %s: %d (%s) (perhaps nonexistent parent directory or permissions problem)", path, errno, STRERROR(errno));
      exit(1);
    }
  } else {
    D("Created %s", path);
  }
  
  for (dir = mkdirs_list; *dir; ++dir) {
    len = snprintf(path, sizeof(path)-ZXID_PATH_LENGTH_MARGIN, "%s%s", cf->cpath, *dir);
    if (MKDIR(path, 02770) < 0) {
      ERR("Failed to create directory %s: %d (%s)", path, errno, STRERROR(errno));
    } else {
      D("Created %s", path);
    }
  }
  
  len = snprintf(path, sizeof(path)-ZXID_PATH_LENGTH_MARGIN, "%s" ZXID_CONF_FILE, cf->cpath);
  if (stat(path, &st)) {  /* error return from stat means file does not exist, create example */
    write_all_path_fmt("-dirs", sizeof(path), path, "%s%s", cf->cpath, ZXID_CONF_FILE,
"# This is example configuration file %s" ZXID_CONF_FILE "\n"
"# You should edit the values to suit your situation.\n"
"BURL=https://yourhost.example.com:8443/protected/saml\n"
"NICE_NAME=Configuration NICE_NAME: Set this to describe your site to humans, see %s" ZXID_CONF_FILE "\n"
"BUTTON_URL=https://example.com/YOUR_BRAND_saml2_icon_150x60.png\n"
"ORG_NAME=Unspecified ORG_NAME conf variable\n"
"LOCALITY=Lisboa\n"
"STATE=Lisboa\n"
"COUNTRY=PT\n"
"CONTACT_ORG=Your organization\n"
"CONTACT_NAME=Your Name\n"
"CONTACT_EMAIL=your@email.com\n"
"CONTACT_TEL=+351918731007\n", cf->cpath, cf->cpath);
  }

  INFO("Created directories. You should inspect their ownership and permissions to ensure the webserver can read and write them, yet outsiders can not access them. You may want to run  chown -R www-data %s", cf->cpath);
}

/* --------------- reg_svc --------------- */

/*() IdP and Discovery. Register service metadata to /var/zxid/idpdimd/XX,
 * and possibly boostrap to /var/zxid/idpuid/.all/.bs/YY
 *
 * bs_reg:: Register-also-as-bootstrap flag
 * dry_run:: nonzero: do not write anything
 * ddimd:: Discovery metadata directory, such as /var/zxid/idpdimd/
 * duid:: uid dir such as  /var/zxid/idpuid/
 * returns:: 0 on success, nonzero on error. */

/* Called by:  zxcot_main */
static int zxid_reg_svc(zxid_conf* cf, int bs_reg, int dry_run, const char* ddimd, const char* duid)
{
  char sha1_name[28];
  char path[ZXID_MAX_BUF];
  int got;
  fdtype fd;
  struct zx_root_s* r;
  zxid_epr* epr;
  struct zx_str* ss;
  struct zx_str* tt;
  
  read_all_fd(fdstdin, buf, sizeof(buf)-1, &got);  /* Read EPR */
  buf[got] = 0;
  
  r = zx_dec_zx_root(cf->ctx, got, buf, "cot reg_svc");
  if (!r || !r->EndpointReference) {
    ERR("Failed to parse <EndpointReference> buf(%.*s)", got, buf);
    return 1;
  }
  epr = r->EndpointReference;
  if (!ZX_SIMPLE_ELEM_CHK(epr->Address)) {
    ERR("<EndpointReference> MUST have <Address> element buf(%.*s)", got, buf);
    return 1;
  }
  if (!epr->Metadata) {
    ERR("<EndpointReference> MUST have <Metadata> element buf(%.*s)", got, buf);
    return 1;
  }
  if (!ZX_SIMPLE_ELEM_CHK(epr->Metadata->ProviderID)) {
    ERR("<EndpointReference> MUST have <Metadata> with <ProviderID> element buf(%.*s)", got, buf);
    return 1;
  }
  if (!epr->Metadata->ServiceType) {
    ERR("<EndpointReference> MUST have <ServiceType> element buf(%.*s)", got, buf);
    return 1;
  }

  /* *** possibly add something here and double check the required fields are available. */

  ss = zx_easy_enc_elem_opt(cf, &epr->gg);
  if (!ss)
    return 2;
  
#if 0
  // *** wrong
  tt = ZX_GET_CONTENT(epr->Metadata->ProviderID);
#else
  tt = ZX_GET_CONTENT(epr->Metadata->ServiceType);
#endif
  got = MIN(tt->len, sizeof(path)-1);
  memcpy(path, tt?tt->s:"", got);
  path[got] = 0;
  zxid_fold_svc(path, got);

  sha1_safe_base64(sha1_name, ss->len, ss->s);
  sha1_name[27] = 0;

  if (verbose)
    fprintf(stderr, "Registering metadata in %s%s,%s\n", ddimd, path, sha1_name);
  
  if (dry_run) {
    if (verbose)
      fprintf(stderr, "Register EPR dry run. Would have written to path(%s%s,%s). "
	      "You may also want to\n"
	      "  touch %s.all/.bs/%s,%s\n\n", ddimd, path, sha1_name, uiddir, path, sha1_name);
    fflush(stdin);
    write_all_fd(fdstdout, ss->s, ss->len);
    zx_str_free(cf->ctx, ss);
    return 0;
  }
  
  D("Register EPR path(%s%s,%s) in discovery metadata.", ddimd, path, sha1_name);
  fd = open_fd_from_path(O_CREAT | O_WRONLY | O_TRUNC, 0666, "zxcot -b", 1,
			 "%s%s,%s", ddimd, path, sha1_name);
  if (fd == BADFD) {
    perror("open epr for registering");
    ERR("Failed to open file for writing: sha1_name(%s,%s) to service registration", path, sha1_name);
    zx_str_free(cf->ctx, ss);
    return 1;
  }
  
  write_all_fd(fd, ss->s, ss->len);
  zx_str_free(cf->ctx, ss);
  close_file(fd, (const char*)__FUNCTION__);

  if (bs_reg) {
    if (verbose)
      fprintf(stderr, "Activating bootstrap %s.all/.bs/%s,%s", duid, path, sha1_name);

    if (!dryrun) {
      fd = open_fd_from_path(O_CREAT | O_WRONLY | O_TRUNC, 0666, "zxcot -bs", 1,
			     "%s.all/.bs/%s,%s", duid, path, sha1_name);
      if (fd == BADFD) {
	perror("open epr for bootstrap activation");
	ERR("Failed to open file for writing: sha1_name(%s,%s) to bootstrap activation", path, sha1_name);
	return 1;
      }
    
      write_all_fd(fd, "", 0);
      close_file(fd, (const char*)__FUNCTION__);
    }
  } else {
    D("You may also want to activate bootstrap by\n  touch %s.all/.bs/%s,%s", duid, path, sha1_name);
  }
  return 0;
}

/* --------------- addmd --------------- */

/*() Add metadata of a partner to the Circle-of-Trust, represented by the CoT dir */

/* Called by:  zxcot_main */
static int zxid_addmd(zxid_conf* cf, char* mdurl, int dry_run, const char* dcot)
{
  int got;
  fdtype fd;
  char* p;
  zxid_entity* ent;
  struct zx_str* ss;
  
  if (mdurl) {
    ent = zxid_get_meta(cf, mdurl);
  } else {
    read_all_fd(fdstdin, buf, sizeof(buf)-1, &got);
    buf[got] = 0;
    p = buf;
    ent = zxid_parse_meta(cf, &p, buf+got);
  }
  
  if (!ent) {
    ERR("***** Parsing metadata failed %d", 0);
    return 1;
  }

  for (; ent; ent = ent->n) {
    ss = zx_easy_enc_elem_opt(cf, &ent->ed->gg);
    if (!ss)
      return 2;
  
    if (dry_run) {
      write_all_fd(fdstdout, ss->s, ss->len);
      zx_str_free(cf->ctx, ss);
      if (verbose>1)
	printf("\n\nDry run ent(%s) to %s%s\n", ent->eid, dcot, ent->sha1_name);
      continue;
    }
    if (verbose)
      printf("Writing ent(%s) to %s%s\n", ent->eid, dcot, ent->sha1_name);
  
    fd = open_fd_from_path(O_CREAT | O_WRONLY | O_TRUNC, 0666, "zxcot -a", 1,
			   "%s%s", dcot, ent->sha1_name);
    if (fd == BADFD) {
      perror("open metadata for writing metadata to cache");
      ERR("Failed to open file for writing: sha1_name(%s) to metadata cache", ent->sha1_name);
      zx_str_free(cf->ctx, ss);
      return 1;
    }
    
    write_all_fd(fd, ss->s, ss->len);
    zx_str_free(cf->ctx, ss);
    close_file(fd, (const char*)__FUNCTION__);
  }
  return 0;
}

/* --------------- genmd --------------- */

/*() Generate our own metadata */

/* Called by:  zxcot_main */
static int zxid_genmd(zxid_conf* cf, int dry_run, const char* dcot)
{
  zxid_cgi cgi;
  struct zx_str* meta = zxid_sp_meta(cf, &cgi);
  ZERO(&cgi, sizeof(cgi));
  printf("%.*s", meta->len, meta->s);
  return 0;
}

/* --------------- lscot --------------- */

/*() Print a line of Circle-of-Trust listing */

/* Called by:  zxid_lscot x2 */
static int zxid_lscot_line(zxid_conf* cf, int col_swap, const char* dcot, const char* den)
{
  zxid_entity* ent;
  char* p;
  int got = read_all(ZXID_MAX_MD, buf, "zxcot line", 1, "%s%s", dcot, den);
  if (!got) {
    ERR("Zero data in file(%s%s). If cot directory does not exist consider running zxcot -dirs", dcot, den);
    return 1;
  }
  p = buf;
  ent = zxid_parse_meta(cf, &p, buf+got);
  if (!ent) {
    ERR("***** Parsing metadata failed for(%s%s)", dcot, den);
    return 2;
  }
  while (ent) {
    switch (col_swap) {
    case 1:  printf("%-50s %s%s %s\n", ent->eid, dcot, den, STRNULLCHKD(ent->dpy_name)); break;
    case 2:  printf("%s\n",       ent->eid); break;
    default: printf("%s%s %-50s %s\n", dcot, den, ent->eid, STRNULLCHKD(ent->dpy_name));
    }
    if (strcmp(*den?den:dcot, ent->sha1_name))
      fprintf(stderr, "Filename(%s) does not match sha1_name(%s)\n", *den?den:dcot, ent->sha1_name);
    ent = ent->n;
  }
  return 0;
}

/*() List the contents of the Circle-of-Trust, represented by the CoT directory,
 * in various formats. */

/* Called by:  zxcot_main */
static int zxid_lscot(zxid_conf* cf, int col_swap, const char* dcot)
{
  int got, ret;
  char* p;
  DIR* dir;
  struct dirent* de;

  dir = opendir(dcot);
  if (!dir) {
    perror("opendir for /var/zxid/cot (or other if configured) for loading cot cache");
    D("failed path(%s)", dcot);
    
    got = strlen(dcot);
    p = ZX_ALLOC(cf->ctx, got+1);
    memcpy(p, dcot, got-1);
    p[got-1] = 0;  /* chop off / */
    got = zxid_lscot_line(cf, col_swap, p, "");
    ZX_FREE(cf->ctx, p);
    return got;
  }
  
  while (de = readdir(dir)) {
    if (de->d_name[0] == '.' || de->d_name[strlen(de->d_name)-1] == '~')
      continue;
    ret = zxid_lscot_line(cf, col_swap, dcot, de->d_name);
    if (!ONE_OF_2(ret, 0, 2))
      return ret;
  }
  return 0;
}

/* ============== MAIN ============ */

#ifndef zxcot_main
#define zxcot_main main
#endif
extern int zxid_suppress_vpath_warning;

/*() Circle of Trust management tool */

/* Called by: */
int zxcot_main(int argc, char** argv, char** env)
{
  strncpy(errmac_instance, "cot", sizeof(errmac_instance));
  zxid_suppress_vpath_warning = 1;
  cf = zxid_new_conf_to_cf(0);

  opt(&argc, &argv, &env);
  
  if (entid) {
    char sha1_name[28];
    sha1_safe_base64(sha1_name, strlen(entid), entid);
    sha1_name[27] = 0;
    printf("%s\n", sha1_name);
    return 0;
  }
    
  if (addmd)
    return zxid_addmd(cf, mdurl, dryrun, cotdir);
  
  if (regsvc)
    return zxid_reg_svc(cf, regbs, dryrun, dimddir, uiddir);

  if (genmd)
    return zxid_genmd(cf, dryrun, cotdir);
  
  return zxid_lscot(cf, swap, cotdir);
}

/* EOF  --  zxcot.c */
