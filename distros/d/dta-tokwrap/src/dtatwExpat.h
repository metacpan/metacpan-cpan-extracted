/*
 * File: dtatwExpat.h
 * Author: Bryan Jurish <configure.ac>
 * Description: DTA tokenizer wrappers: C utilities: common definitions for expat
 */

#ifndef DTATW_EXPAT_H
#define DTATW_EXPAT_H

#include "dtatwCommon.h"

#undef XML_DTD
#undef XML_NS
#undef XML_UNICODE
#undef XML_UNICODE_WHAT_T
#define XML_CONTEXT_BYTES 1024
#include <expat.h>

/*======================================================================
 * Utils: expat: attributes
 */

/*--------------------------------------------------------------
 * val = get_attr(name, attrs)
 */
static inline
const XML_Char *get_attr(const XML_Char *aname, const XML_Char **attrs)
{
  int i;
  for (i=0; attrs[i]; i += 2) {
    if (strcmp(aname,attrs[i])==0) return attrs[i+1];
  }
  return NULL;
}

/*--------------------------------------------------------------
 * idval = get_xmlid(name, attrs)
 *  + looks for "xml:id" or "id" attribute
 */
static inline
const XML_Char *get_xmlid(const XML_Char **attrs)
{
  int i;
  for (i=0; attrs[i]; i += 2) {
    if (strcmp("id",attrs[i])==0 || strcmp("xml:id",attrs[i])==0) return attrs[i+1];
  }
  return NULL;
}

/*======================================================================
 * Utils: expat: parser context
 */

/*--------------------------------------------------------------
 * get_error_context()
 *  + gets expat error context, with a surrounding window of ctx_want bytes
 */
static inline
const char *get_error_context(XML_Parser xp, int ctx_want, int *offset, int *len)
{
  int ctx_offset, ctx_size;
  const char *ctx_buf = XML_GetInputContext(xp, &ctx_offset, &ctx_size);
  int ctx_mystart, ctx_myend;
  ctx_mystart = ((ctx_offset <= ctx_want)              ? 0        : (ctx_offset-ctx_want));
  ctx_myend   = ((ctx_size   <= (ctx_offset+ctx_want)) ? ctx_size : (ctx_offset+ctx_want));
  *offset = ctx_offset - ctx_mystart;
  *len    = ctx_myend - ctx_mystart;
  return ctx_buf + ctx_mystart;
}

/*--------------------------------------------------------------
 * get_event_context()
 *  + gets current event context (analagous to perl XML::Parser::original_string())
 */
static inline
const char *get_event_context(XML_Parser xp, int *len)
{
  int ctx_offset, ctx_size;
  const char *ctx_buf = XML_GetInputContext(xp, &ctx_offset, &ctx_size);
  int cur_size = XML_GetCurrentByteCount(xp);
  assert(ctx_offset >= 0);
  assert(ctx_offset+cur_size <= ctx_size);
  *len = cur_size;
  return ctx_buf + ctx_offset;
}

/*======================================================================
 * Utils: expat: File Parsing
 */

// n_xmlbytes_read = expat_parse_file(xp,f,filename)
//   + exit()s on error
ByteOffset expat_parse_file(XML_Parser xp, FILE *f_in, const char *filename_in);

// n_xmlbytes_read = expat_parse_buffer(xp,buf,buflen,srcname)
//   + exit()s on error
ByteOffset expat_parse_string(XML_Parser xp, const char *buf, int buflen, const char *srcname);


#endif /* DTATW_EXPAT_H */

