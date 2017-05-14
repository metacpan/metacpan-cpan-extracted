/* zxsizeof.c  -  Print sizes of various data types
 * Copyright (c) 2010-2012 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id$
 */

#include <zx/zx.h>
#include <zx/zxid.h>
#include <zx/c/zx-ns.h>
#include <zx/c/zx-data.h>
#include <zx/c/zxidvers.h>
#include <zx/hiios.h>

/* Called by: */
int main(int argc, char** argv)
{
  printf("  -- zxid version: %s\n\n", ZXID_REV);

  printf("  -- sizeof(struct zx_ctx): %d\n", sizeof(struct zx_ctx));
  printf("  -- sizeof(zxid_conf): %d\n", sizeof(zxid_conf));
  printf("  -- sizeof(zxid_cgi): %d\n", sizeof(zxid_cgi));
  printf("  -- sizeof(zxid_ses): %d\n", sizeof(zxid_ses));
  printf("  -- sizeof(zxid_entity): %d\n\n", sizeof(zxid_entity));

  printf("  -- sizeof(zxid_a7n): %d\n", sizeof(zxid_a7n));
  printf("  -- sizeof(struct zx_root_s): %d\n", sizeof(struct zx_root_s));
  printf("  -- sizeof(struct zx_str): %d\n", sizeof(struct zx_str));
  printf("  -- sizeof(struct zx_elem_s): %d\n", sizeof(struct zx_elem_s));
  printf("  -- sizeof(struct zx_attr_s): %d\n\n", sizeof(struct zx_attr_s));

  printf("  -- sizeof(struct zx_ns_s): %d\n", sizeof(struct zx_ns_s));
  printf("  -- sizeof(zx_ns_tab): %d\n", sizeof(zx_ns_tab));
  printf("  --   fyll: %d/%d (%.1f%%)\n", zx_N_NS, zx__NS_MAX, 100.0*zx_N_NS/zx__NS_MAX);

  printf("  -- sizeof(struct zx_at_tok): %d\n", sizeof(struct zx_at_tok));
  printf("  -- sizeof(zx_at_tab): %d\n", sizeof(zx_at_tab));
  printf("  --   fyll: %d/%d (%.1f%%)\n", zx_N_ATTR, zx__ATTR_MAX, 100.0*zx_N_ATTR/zx__ATTR_MAX);

  printf("  -- sizeof(struct zx_el_tok): %d\n", sizeof(struct zx_el_tok));
  printf("  -- sizeof(zx_el_tab): %d\n", sizeof(zx_el_tab));
  printf("  -- sizeof(struct zx_el_desc): %d\n", sizeof(struct zx_el_desc));
  printf("  --   fyll: %d/%d (%.1f%%); n_el_descs=%d\n", zx_N_ELEM, zx__ELEM_MAX, 100.0*zx_N_ELEM/zx__ELEM_MAX, zx_N_EL_DESC);

  printf("\n  -- sizeof(struct hi_io): %d\n", sizeof(struct hi_io));
  printf("  -- sizeof(struct hi_pdu): %d\n", sizeof(struct hi_pdu));
  printf("  -- sizeof(struct hi_qel): %d\n", sizeof(struct hi_qel));
  printf("  -- sizeof(struct hi_lock): %d\n", sizeof(struct hi_lock));
  printf("  -- sizeof(struct hi_ent): %d\n", sizeof(struct hi_ent));
  printf("  -- sizeof(struct hi_ch): %d\n", sizeof(struct hi_ch));
  printf("  -- sizeof(struct hi_ack): %d\n", sizeof(struct hi_ack));
  printf("  -- sizeof(struct hi_host_spec): %d\n", sizeof(struct hi_host_spec));
  printf("  -- sizeof(struct hi_thr): %d\n", sizeof(struct hi_thr));
  printf("  -- sizeof(struct hiios): %d\n", sizeof(struct hiios));
  return 0;
}

/* EOF  --  zxsizeof.c */
