/* zxidmda.c  -  Metadata Authority
 * Copyright (c) 2013 Synergetics NV (sampo@synergetics.be), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidsimp.c,v 1.64 2010-01-08 02:10:09 sampo Exp $
 *
 * 11.12.2013, created --Sampo
 *
 * See also:: zxidepr.c - the code that queries metadata authority
 */

#include "platform.h"  /* needed on Win32 for pthread_mutex_lock() et al. */

#include <memory.h>
#include <string.h>
#include <stdlib.h>
#include <fcntl.h>

#include "errmac.h"
#include "zx.h"
#include "zxid.h"
#include "zxidutil.h"
#include "zxidconf.h"
#include "zxidpriv.h"
#include "wsf.h"
#include "c/zxidvers.h"
#include "c/zx-md-data.h"

/*() Metadata Authority - return metadata of entities in our Circle of Trust.
 * Metadata Authority is a service that, given succinct ID of an Entity,
 * will serve the metadata it knows about that entity.
 * This functionality is typically advertised in IdP metadata as
 *
 *   <md:AdditionalMetadataLocation namespace="#md-authority">someurl?o=b&c=</>
 *
 * where c= will be concatenated with the succinctID of the entity that is sought
 * after. Thus the http GET request might look something like
 *
 *  someurl?o=b&c=81_KLuey8863Alp9KwNY4tjES-4
 *
 * Check in your configuration that you have MD_AUTHORITY_ENA=1
 * Check in SP configuration that they have MD_FETCH=2 and
 * MD_AUTHORITY=your-entity-id
 *
 * N.B. The metadata is supposed to be signed, but the signature is not
 * applied here. Rather, you should run zxcot -a -s when importing metadata. */

char* zxid_simple_md_authority(zxid_conf* cf, zxid_cgi* cgi, int* res_len, int auto_flags)
{
#define sha1_name cdc  /* We reuse the CGI variable c (aka cdc) as the sha1_name */
  struct zx_str* ss;
  fdtype fd;
  int siz, n, got;
  char* md_buf;

  DD("sha1_name(%s)", cgi->sha1_name);
  if (!cgi->sha1_name) {
    ERR("The request ot Metadata Authority did not specify cgi->c (the succinct ID, aka sha1_name, of the entity whose metadata is being requested) %d", 0);
    ss = zx_dup_str(cf->ctx, "#ERR: Metadata Authority: Missing c CGI argument (the sha1_name aka succinct ID of the entity).");
    goto done;
  }

  fd = open_fd_from_path(O_RDONLY, 0, "mda", 1, "%s" ZXID_COT_DIR "%s", cf->cpath, cgi->sha1_name);
  if (fd == BADFD) {
    perror("open metadata to read");
    ERR("No metadata file found for sha1_name(%s)", cgi->sha1_name);
    ss = zx_dup_str(cf->ctx, "#ERR: No metadata file found for the entity.");
    goto done;
  }
  siz = get_file_size(fd);
  md_buf = ZX_ALLOC(cf->ctx, siz+1);
  n = read_all_fd(fd, md_buf, siz, &got);
  DD("==========sha1_name(%s)", cgi->sha1_name);
  if (n == -1) {
    perror("metadata to read error");
    ERR("Metadata read error for sha1_name(%s)", cgi->sha1_name);
    ss = zx_dup_str(cf->ctx, "#ERR: Metadata read error.");
    goto done;
  }
  close_file(fd, (const char*)__FUNCTION__);

  if (got <= 20) {
    ERR("Metadata found is too short, only %d bytes. sha1_name(%s) md_buf(%.*s)", got, cgi->sha1_name, got, md_buf);
    ss = zx_dup_str(cf->ctx, "#ERR: Metadata too short.");
    goto done;
  }
  DD("md_buf(%.*s) got=%d siz=%d sha1_name(%s)", got, md_buf, got, siz, cgi->sha1_name);
  ss = zx_ref_str(cf->ctx, md_buf);

done:
  return zxid_simple_show_page(cf, ss, ZXID_AUTO_METAC, ZXID_AUTO_METAH,
			       "b", "text/xml", res_len, auto_flags, 0);
}

/* EOF  --  zxidmda.c */
