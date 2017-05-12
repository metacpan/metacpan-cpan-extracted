/* -*- Mode: C; tab-width: 8; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/*****************************************************************
** ExpatXS.xs
**
** This file is derived from the original Expat.xs file written 
** for XML::Parser by Larry Wall and Clark Cooper.
**
** The file has been modified for purposes of XML::SAX::ExpatXS 
** by Matt Sergeant and Petr Cimprich.
**
** Copyright 1998-2007 by authors of respective parts.
** All rights reserved.
**
** This program is free software; you can redistribute it and/or
** modify it under the same terms as Perl itself.
**
*/


#include <expat.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#undef convert

#include "patchlevel.h"
#include "encoding.h"

#include <string.h>

/* Version 5.005_5x (Development version for 5.006) doesn't like sv_...
   anymore, but 5.004 doesn't know about PL_sv..
   Don't want to push up required version just for this. */

#if PATCHLEVEL < 5
#define PL_sv_undef sv_undef
#define PL_sv_no    sv_no
#define PL_sv_yes   sv_yes
#define PL_na       na
#endif

#define BUFSIZE 32768

#define NSDELIM -1

typedef struct {
  SV* self_sv;
  XML_Parser p;

  AV* context;
  AV *ns_stack;

  int skip_until;
  int feat_join;
  int feat_nsatts;
  int feat_locator;
  int feat_recstring;
  int feat_xmlns;
  int feat_perlxmlns;
  int feat_entgen;
  int feat_entpar;

  SV *recstring;
  char * delim;
  STRLEN delimlen;

  unsigned ns:1;
  unsigned no_expand:1;

  /* Callback handlers */
  SV* start_sv;
  SV* end_sv;
  SV* char_sv;
  SV* comment_sv;

  HV* atts;
  int atts_ready;

  HV* locator_hv;
  HV* extern_hv;  
  SV* chrbuffer;
  HV* chr_hv;

} CallbackVector;


static HV* EncodingTable = NULL;

static XML_Char nsdelim[] = {NSDELIM, '\0'};

static char *QuantChar[] = {"", "?", "*", "+"};

static U32 PrefixHash; /* pre-computed */
static U32 NamespaceURIHash;
static U32 NameHash;
static U32 LocalNameHash;
static U32 AttributesHash;
static U32 ValueHash;
static U32 DataHash;
static U32 TargetHash;
static U32 VersionHash;
static U32 XMLVersionHash;
static U32 EncodingHash;
static U32 PublicIdHash;
static U32 SystemIdHash;

static SV *empty_sv;

/* These are few macros used within C functions */

/* Macro to generate external entity name key */
#define xse_extern_ent_key(key, base, sysid, pubid) \
key = strncat(strncat(strncpy(key, base ? base : "", 299), \
sysid ? sysid : "", 299), pubid ? pubid : "", 299);

/* Macro to emit characters */
#define xse_characters(userData, buffer) \
if (SvCUR(buffer) > 0) {\
    sendCharacterData(userData, buffer);\
    sv_setpv(buffer, "");\
}

/* Macro to determine current end position */
#define xse_get_end_position(p, ln, cl, string, len) \
ln = XML_GetCurrentLineNumber(p); \
cl = XML_GetCurrentColumnNumber(p); \
for (i = 0; i < len; i++) { \
  if (string[i] < 0xffffff80 || string[i] > 0xffffffbf) cl++; \
  if (string[i] == '\n') {if (i < len - 1) {ln++; cl=0;}} \
};

/* Forward declarations */

#if PATCHLEVEL < 5 && SUBVERSION < 5

/* ================================================================
** This is needed where the length is explicitly given. The expat
** library may sometimes give us zero-length strings. Perl's newSVpv
** interprets a zero length as a directive to do a strlen. This
** function is used when we want to force length to mean length, even
** if zero.
*/

static SV *
newSVpvn(char *s, STRLEN len)
{
  register SV *sv;

  sv = newSV(0);
  sv_setpvn(sv, s, len);
  return sv;
}  /* End newSVpvn */

#define ERRSV GvSV(errgv)
#endif

#ifdef SvUTF8_on

static SV *
newUTF8SVpv(char *s, STRLEN len) {
  register SV *sv;

  sv = newSVpv(s, len);
  SvUTF8_on(sv);
  return sv;
}  /* End new UTF8SVpv */

static SV *
newUTF8SVpvn(char *s, STRLEN len) {
  register SV *sv;

  sv = newSV(0);
  sv_setpvn(sv, s, len);
  SvUTF8_on(sv);
  return sv;
}

#else  /* SvUTF8_on not defined */

#define newUTF8SVpv newSVpv
#define newUTF8SVpvn newSVpvn
#define SvUTF8_on(a) (a)

#endif

static void*
mymalloc(size_t size) {
#ifndef LEAKTEST
  return safemalloc(size);
#else
  return safexmalloc(328,size);
#endif
}

static void*
myrealloc(void *p, size_t s) {
#ifndef LEAKTEST
  return saferealloc(p, s);
#else
  return safexrealloc(p, s);
#endif
}

static void
myfree(void *p) {
  Safefree(p);
}

static XML_Memory_Handling_Suite ms = {mymalloc, myrealloc, myfree};

static int 
get_feature(CallbackVector *cbv, char *fname)
{
    SV ** aux = hv_fetch((HV*)SvRV(cbv->self_sv), "Features", 8, 0);
    if (! aux) {
        return 0;
    } else {
        aux = hv_fetch((HV*)SvRV(*aux), fname, strlen(fname), 0);
        if (! aux) {
            return 0;
        } else {
            return SvIV(*aux);
        }
    }
}

static HV*
add_ns_mapping(AV *ns_stack, char *prefix, char *uri)
{
    HV *ret;
    SV *sv_prefix, *sv_uri;
    AV *new_entry;

    /* warn("add_ns_mapping(%s => %s)\n", prefix, uri); */

    sv_prefix = (prefix == NULL) ? SvREFCNT_inc(empty_sv) 
                                 : newUTF8SVpv(prefix, strlen(prefix));
    sv_uri = (uri == NULL) ? SvREFCNT_inc(empty_sv)
                           : newUTF8SVpv(uri, strlen(uri));

    ret = newHV();
    hv_store(ret, "Prefix", 6, sv_prefix, PrefixHash);
    hv_store(ret, "NamespaceURI", 12, sv_uri, NamespaceURIHash);

    new_entry = newAV();
    av_push(new_entry, newSVsv(sv_prefix));
    av_push(new_entry, newSVsv(sv_uri));

    /* store at front of array for faster access */
    av_unshift(ns_stack, 1);
    av_store(ns_stack, 0, newRV_noinc((SV*)new_entry));

    return ret;
}

static void
del_ns_mapping(AV *ns_stack, char *prefix)
{
    SV *entry;
    I32 key = 0;

    /* warn("del_ns_mapping: %s\n", prefix); */

    entry = av_shift(ns_stack);
    if (entry) SvREFCNT_dec(entry);
}

static AV*
get_ns_mapping(AV *ns_stack, char *prefix, char *uri)
{
    SV **entry;
    I32 key = 0;

    for (key = 0; key <= av_len(ns_stack); key++) {
        entry = av_fetch(ns_stack, key, 0);
        if (entry && *entry && SvOK(*entry)) {
            SV **svthing = av_fetch((AV*)SvRV(*entry), prefix == NULL ? 1 : 0, 0);
            if (svthing && *svthing && (strcmp(SvPV(*svthing, PL_na), prefix == NULL ? uri : prefix) == 0)) {
                return (AV*)SvRV(*entry);
            }
        }
    }

    return NULL;
}

static void
append_error(XML_Parser parser, char * err)
{
  dSP;
  CallbackVector * cbv;
  HV * exc = newHV();
  SV **public;
  SV **system;	  
  char *msg;

  cbv = (CallbackVector*) XML_GetUserData(parser);

  if (! err)
       err = (char *) XML_ErrorString(XML_GetErrorCode(parser));

  msg = (char *)mymalloc(strlen(err) + 50);
  sprintf(msg, "%s at line %d, column %d, byte %d",
          err,
          (int)XML_GetCurrentLineNumber(parser),
          (int)XML_GetCurrentColumnNumber(parser)+1,
          (int)XML_GetCurrentByteIndex(parser));

  public = hv_fetch(cbv->locator_hv, "PublicId", 8, 0);
  system = hv_fetch(cbv->locator_hv, "SystemId", 8, 0);

  hv_store(exc, "PublicId", 8, 
           public ? *public : SvREFCNT_inc(empty_sv), PublicIdHash);
  hv_store(exc, "SystemId", 8, 
	   system ? *system : SvREFCNT_inc(empty_sv), SystemIdHash);
  hv_store(exc, "Message", 7, newUTF8SVpv((char*)msg, 0), 0);
  hv_store(exc, "Exception", 9, newUTF8SVpv((char*)err, 0), 0);
  hv_store(exc, "LineNumber", 10, 
           newSViv((IV)XML_GetCurrentLineNumber(parser)), 0);
  hv_store(exc, "ColumnNumber", 12, 
           newSViv((IV)XML_GetCurrentColumnNumber(parser)+1), 0);

  hv_store((HV*)SvRV(cbv->self_sv), "ErrorMessage", 12, 
           newUTF8SVpv((char*)msg, 0), 0);

  ENTER;
  SAVETMPS;
  PUSHMARK(sp);
  EXTEND(sp, 2);
  PUSHs(cbv->self_sv);
  PUSHs(newRV_noinc((SV*)exc));
  PUTBACK;
  perl_call_method("fatal_error", G_DISCARD);
  FREETMPS;
  LEAVE;

  myfree(msg);

}  /* End append_error */


static SV *
generate_model(XML_Content *model) {
  HV * hash = newHV();
  SV * obj = newRV_noinc((SV *) hash);

  sv_bless(obj, gv_stashpv("XML::SAX::ExpatXS::ContentModel", 1));

  hv_store(hash, "Type", 4, newSViv(model->type), 0);
  if (model->quant != XML_CQUANT_NONE) {
    hv_store(hash, "Quant", 5, newSVpv(QuantChar[model->quant], 1), 0);
  }

  switch(model->type) {
  case XML_CTYPE_NAME:
    hv_store(hash, "Tag", 3, newSVpv((char *)model->name, 0), 0);
    break;

  case XML_CTYPE_MIXED:
  case XML_CTYPE_CHOICE:
  case XML_CTYPE_SEQ:
    if (model->children && model->numchildren)
      {
    AV * children = newAV();
    int i;

    for (i = 0; i < model->numchildren; i++) {
      av_push(children, generate_model(&model->children[i]));
    }

    hv_store(hash, "Children", 8, newRV_noinc((SV *) children), 0);
      }
    break;
  }

  return obj;
}
  /* End generate_model */

static int
parse_stream(XML_Parser parser, SV * ioref)
{
  dSP;
  SV *      tbuff;
  SV *      tsiz;
  char *    linebuff;
  STRLEN    lblen;
  STRLEN    br = 0;
  int       buffsize;
  int       done = 0;
  int       ret = 1;
  char *    msg = NULL;
  CallbackVector * cbv;
  char      *buff = (char *) 0;

  cbv = (CallbackVector*) XML_GetUserData(parser);

  ENTER;
  SAVETMPS;

  if (cbv->delim) {
    int cnt;
    SV *tline;

    PUSHMARK(SP);
    XPUSHs(ioref);
    PUTBACK ;

    cnt = perl_call_method("getline", G_SCALAR);

    SPAGAIN;

    if (cnt != 1)
      croak("getline method call failed");

    tline = POPs;

    if (! SvOK(tline)) {
      lblen = 0;
    }
    else {
      char *    chk;
      linebuff = SvPV(tline, lblen);
      chk = &linebuff[lblen - cbv->delimlen - 1];

      if (lblen > cbv->delimlen + 1
      && *chk == *cbv->delim
      && chk[cbv->delimlen] == '\n'
      && strnEQ(++chk, cbv->delim + 1, cbv->delimlen - 1))
    lblen -= cbv->delimlen + 1;
    }

    PUTBACK ;
    buffsize = lblen;
    done = lblen == 0;
  }
  else {
    tbuff = newSV(0);
    tsiz = newSViv(BUFSIZE);
    buffsize = BUFSIZE;
  }

  while (! done)
    {
      char *buffer = XML_GetBuffer(parser, buffsize);

      if (! buffer)
    croak("Ran out of memory for input buffer");

      SAVETMPS;

      if (cbv->delim) {
    Copy(linebuff, buffer, lblen, char);
    br = lblen;
    done = 1;
      }
      else {
    int cnt;
    SV * rdres;
    char * tb;

    PUSHMARK(SP);
    EXTEND(SP, 3);
    PUSHs(ioref);
    PUSHs(tbuff);
    PUSHs(tsiz);
    PUTBACK ;

    cnt = perl_call_method("read", G_SCALAR);

    SPAGAIN ;

    if (cnt != 1)
      croak("read method call failed");

    rdres = POPs;

    if (! SvOK(rdres))
      croak("read error");

    tb = SvPV(tbuff, br);
    if (br > 0)
      Copy(tb, buffer, br, char);
    else
      done = 1;

    PUTBACK ;
      }

      ret = XML_ParseBuffer(parser, br, done);

      SPAGAIN; /* resync local SP in case callbacks changed global stack */

      if (! ret)
    break;

      FREETMPS;
    }

  if (! ret)
    append_error(parser, msg);

  if (! cbv->delim) {
    SvREFCNT_dec(tsiz);
    SvREFCNT_dec(tbuff);
  }

  FREETMPS;
  LEAVE;

  return ret;
}  /* End parse_stream */

static HV *
gen_ns_node(const char * name, AV * ns_stack)
{
  char *pos = strchr(name, NSDELIM);
  HV *ret = newHV();

  if (pos && pos > name)
  {
      SV *new_name;
      SV *uri = newUTF8SVpv((char *)name, pos - name);
      AV *ns_entry = get_ns_mapping(ns_stack, NULL, SvPV(uri, PL_na));
      SV **prefix = av_fetch(ns_entry, 0, 0);

      if (SvOK(*prefix)) {
          /* generate Name = prefix:localname */
          if (SvCUR(*prefix)) {
              char *localname = pos;
              localname++;
              new_name = newSVsv(*prefix);
              sv_catpvn(new_name, ":", 1);
              sv_catpv(new_name, localname);
              SvUTF8_on(new_name);
          }
          else {
              /* xmlns default */
              char *localname = pos;
              localname++;
              new_name = newUTF8SVpv(localname, 0);
          }
      }
      else {
          new_name = newUTF8SVpv((char *)name, 0);
      }

      hv_store(ret, "Name", 4, new_name, NameHash);
      hv_store(ret, "Prefix", 6, newSVsv(*prefix), PrefixHash);
      hv_store(ret, "NamespaceURI", 12, uri, NamespaceURIHash);
      hv_store(ret, "LocalName", 9, newUTF8SVpv((char *)++pos, 0), LocalNameHash);
  }
  else {
    SV *svname = newUTF8SVpv((char *)name, 0);
    hv_store(ret, "Name", 4, svname, NameHash);
    hv_store(ret, "Prefix", 6, SvREFCNT_inc(empty_sv), PrefixHash);
    hv_store(ret, "NamespaceURI", 12, SvREFCNT_inc(empty_sv), NamespaceURIHash);
    hv_store(ret, "LocalName", 9, SvREFCNT_inc(svname), LocalNameHash);
  }

  return ret;
}  /* End gen_ns_node */

static void
sendCharacterData(void *userData, SV *buffer)
{
  dSP;
  CallbackVector* cbv = (CallbackVector*) userData;
  SV *data;

  if (cbv->feat_locator && !cbv->feat_join)
    XML_DefaultCurrent(cbv->p);

  /* warn("char refcnt: %d\n", SvREFCNT(cbv->chr_hv)); */
  if (SvREFCNT(cbv->chr_hv) == 1) {
      SvREFCNT_inc(cbv->chr_hv);

  } else {
      cbv->chr_hv = newHV();
  }

  /* can't be the same struct as buffer */
  data = newSVsv(buffer);

  ENTER;
  SAVETMPS;

  hv_store(cbv->chr_hv, "Data", 4, data, DataHash);

  PUSHMARK(sp);
  EXTEND(sp, 1);
  /* PUSHs(cbv->self_sv); */
  PUSHs(sv_2mortal(newRV_noinc((SV*)cbv->chr_hv)));
  PUTBACK;
  perl_call_sv(cbv->char_sv, G_DISCARD);

  FREETMPS;
  LEAVE;

  /* warn("leaving ch: %d\n", SvREFCNT((SV*)cvbv->chr_hv)); */
} /* End sendCharacterData */

static void
characterData(void *userData, const char *s, int len)
{
  dSP;
  CallbackVector* cbv = (CallbackVector*) userData;

  /* joining character data or not */
  if (cbv->feat_join) {
    sv_catsv(cbv->chrbuffer, sv_2mortal(newUTF8SVpv((char *)s, len)));
    if (cbv->feat_locator) XML_DefaultCurrent(cbv->p);

  } else {
    sendCharacterData(userData, sv_2mortal(newUTF8SVpv((char *)s, len)));
  }

}  /* End characterData */

static void
startElement(void *userData, const char *name, const char **atts)
{
    dSP;
    CallbackVector* cbv = (CallbackVector*) userData;
    SV ** pcontext;
    HV *node;
    SV *element;

    xse_characters(userData, cbv->chrbuffer);
    if (cbv->feat_locator) XML_DefaultCurrent(cbv->p);

    if (!cbv->atts_ready) cbv->atts = newHV();

    node = gen_ns_node(name, cbv->ns_stack);

    while (*atts)
    {
        HV * attname;
        SV *keyname;
        char *key;
        STRLEN klen;
        char  *pos = strchr(*atts, NSDELIM);
        key = (char *)*atts;

        attname = gen_ns_node(key, cbv->ns_stack);

        atts++;
        if (*atts) {
            hv_store(attname, "Value", 5, newUTF8SVpv((char*)*atts++,0), ValueHash);
        }

        keyname = newUTF8SVpv("{", 1);
        if (pos && pos > key) {
            sv_catpvn(keyname, key, pos - key);
	    // -pc -
            sv_catpvn(keyname, "}", 1);
            sv_catpv(keyname, strchr(key, NSDELIM)+1);

        }
        else {
            sv_catpvn(keyname, "}", 1);
            sv_catpv(keyname, key);
        }
        hv_store_ent(cbv->atts, keyname, newRV_noinc((SV*)attname), 0);
        SvREFCNT_dec(keyname);
    }
    hv_store(node, "Attributes", 10, newRV_noinc((SV*)cbv->atts), AttributesHash);

    ENTER;
    SAVETMPS;

    element = newRV_noinc((SV*)node);

    PUSHMARK(sp);
    EXTEND(sp, 1);
    /* PUSHs(cbv->self_sv); */
    PUSHs(element);
    PUTBACK;
    perl_call_sv(cbv->start_sv, G_DISCARD);

    FREETMPS;
    LEAVE;

    av_push(cbv->context, element);
    cbv->atts_ready = 0;

  /* warn("leaving: %d\n", SvREFCNT((SV*)element)); */
} /* End startElement */

static void
endElement(void *userData, const char *name)
{
  dSP;
  CallbackVector* cbv = (CallbackVector*) userData;
  SV *top;
  HV *node;
  HV *end_node;
  HE *next;

  xse_characters(userData, cbv->chrbuffer);
  if (cbv->feat_locator) XML_DefaultCurrent(cbv->p);

  top = av_pop(cbv->context);

  ENTER;
  SAVETMPS;

  node = (HV*)SvRV(top);
  /* warn("startEl refcnt: %d\n", SvREFCNT(node)); */

  if (SvREFCNT(node) == 1) {
      /* reusing the same struct as in start_element */
      end_node = node;
      hv_delete(end_node, "Attributes", 10, G_DISCARD);
      SvREFCNT_inc(node);

  } else {
      /* copy the node (can't be the same struct as in start_element */
      end_node = newHV();

      hv_iterinit(node);
      while (next = hv_iternext(node)) {
          U32 keylen;
          char *key = hv_iterkey(next, &keylen);
          SV *value = hv_iterval(node, next);
          if (strncmp(key, "Attributes", 10) != 0) {
              // copy everything except attributes 
              hv_store(end_node, key, keylen, newSVsv(value), 0);
          }
      }
  }

  PUSHMARK(sp);
  EXTEND(sp, 1);
  /* PUSHs(cbv->self_sv); */
  PUSHs(sv_2mortal(newRV_noinc((SV*)end_node)));
  PUTBACK;
  perl_call_sv(cbv->end_sv, G_DISCARD);

  FREETMPS;
  LEAVE;

  SvREFCNT_dec(top);
}  /* End endElement */

static void
processingInstruction(void *userData, const char *target, const char *data)
{
  dSP;
  CallbackVector* cbv = (CallbackVector*) userData;
  HV *thing = newHV();

  xse_characters(userData, cbv->chrbuffer);
  if (cbv->feat_locator) XML_DefaultCurrent(cbv->p);

  hv_store(thing, "Target", 6, newUTF8SVpv((char*)target, 0), TargetHash);
  if (data)
    hv_store(thing, "Data", 4, newUTF8SVpv((char*)data, 0), DataHash);

  ENTER;
  SAVETMPS;

  PUSHMARK(sp);
  EXTEND(sp, 3);
  PUSHs(cbv->self_sv);
  PUSHs(sv_2mortal(newRV_noinc((SV*)thing)));
  PUTBACK;
  perl_call_method("processing_instruction", G_DISCARD);

  FREETMPS;
  LEAVE;

}  /* End processingInstruction */

static void
commenthandle(void *userData, const char *string)
{
  dSP;
  CallbackVector * cbv = (CallbackVector*) userData;
  HV *thing = newHV();

  xse_characters(userData, cbv->chrbuffer);

  hv_store(thing, "Data", 4, newUTF8SVpv((char*)string, 0), DataHash);

  ENTER;
  SAVETMPS;

  PUSHMARK(sp);
  EXTEND(sp, 1);
  /* PUSHs(cbv->self_sv); */
  PUSHs(sv_2mortal(newRV_noinc((SV*)thing)));
  PUTBACK;
  perl_call_sv(cbv->comment_sv, G_DISCARD);
  /* perl_call_method("comment", G_DISCARD); */

  FREETMPS;
  LEAVE;

}  /* End commenthandler */

static void
startCdata(void *userData)
{
    dSP;
    CallbackVector* cbv = (CallbackVector*) userData;

    xse_characters(userData, cbv->chrbuffer);

    ENTER;
    SAVETMPS;

    PUSHMARK(sp);
    XPUSHs(cbv->self_sv);
    PUTBACK;
    perl_call_method("start_cdata", G_DISCARD);

    FREETMPS;
    LEAVE;
}  /* End startCdata */

static void
endCdata(void *userData)
{
    dSP;
    CallbackVector* cbv = (CallbackVector*) userData;

    xse_characters(userData, cbv->chrbuffer);

    ENTER;
    SAVETMPS;

    PUSHMARK(sp);
    XPUSHs(cbv->self_sv);
    PUTBACK;
    perl_call_method("end_cdata", G_DISCARD);

    FREETMPS;
    LEAVE;
}  /* End endCdata */

static void
nsStart(void *userdata, const XML_Char *prefix, const XML_Char *uri){
  dSP;
  CallbackVector* cbv = (CallbackVector*) userdata;
  HV *nsatt = newHV();

  xse_characters(userdata, cbv->chrbuffer);
  if (cbv->feat_locator) XML_DefaultCurrent(cbv->p);	

  /* NS declarations are reported as common attributes or not */
  if (cbv->feat_nsatts) {
    char *keyname;

    keyname = (char *) mymalloc(prefix ? (strlen(prefix) + 37) : 37);

    if (!cbv->atts_ready) {
      cbv->atts = newHV();
      cbv->atts_ready = 1;
    }     

    if (prefix) {
      char *a_name;

      a_name = (char *) mymalloc(strlen(prefix) + 7);
      strcpy(a_name, "xmlns:");
      strcat(a_name, prefix);

      strcpy(keyname, (cbv->feat_perlxmlns || cbv->feat_xmlns) 
             ? "{http://www.w3.org/2000/xmlns/}" : "{}");

      hv_store(nsatt, "Name", 4, newUTF8SVpv(a_name, strlen(a_name)), NameHash);
      hv_store(nsatt, "Prefix", 6, newUTF8SVpv("xmlns", 5), PrefixHash);
      hv_store(nsatt, "LocalName", 9, 
               newUTF8SVpv((char*)prefix, strlen(prefix)), LocalNameHash);
      hv_store(nsatt, "NamespaceURI", 12, (cbv->feat_perlxmlns || cbv->feat_xmlns) ?
               newUTF8SVpv("http://www.w3.org/2000/xmlns/", 29) 
               : SvREFCNT_inc(empty_sv), NamespaceURIHash);

      myfree(a_name);

    } else {

      strcpy(keyname, cbv->feat_xmlns ? "{http://www.w3.org/2000/xmlns/}" : "{}");

      hv_store(nsatt, "Name", 4, newUTF8SVpv("xmlns", 5), NameHash);
      hv_store(nsatt, "Prefix", 6, SvREFCNT_inc(empty_sv), PrefixHash);
      hv_store(nsatt, "LocalName", 9, newUTF8SVpv("xmlns", 5), LocalNameHash);
      hv_store(nsatt, "NamespaceURI", 12, cbv->feat_xmlns ?
               newUTF8SVpv("http://www.w3.org/2000/xmlns/", 29) 
               : SvREFCNT_inc(empty_sv), NamespaceURIHash);
    }

    strcat(keyname, prefix ? prefix : "xmlns");

    hv_store(nsatt, "Value", 5, 
             uri ? newUTF8SVpv((char*)uri, strlen(uri)) : SvREFCNT_inc(empty_sv), 
             ValueHash);

    hv_store(cbv->atts, keyname, strlen(keyname), newRV_noinc((SV*)nsatt), 0);

    myfree(keyname);
  }

  ENTER;
  SAVETMPS;
  
  PUSHMARK(sp);
  EXTEND(sp, 3);
  PUSHs(cbv->self_sv);
  PUSHs(sv_2mortal(newRV_noinc((SV*)add_ns_mapping(cbv->ns_stack, (char *)prefix, (char *)uri))));
  PUTBACK;
  perl_call_method("start_prefix_mapping", G_DISCARD);
  
  FREETMPS;
  LEAVE;
  
}  /* End nsStart */

static void
nsEnd(void *userdata, const XML_Char *prefix) {
  dSP;
  CallbackVector* cbv = (CallbackVector*) userdata;
  HV *node = newHV();

  xse_characters(userdata, cbv->chrbuffer);
  if (cbv->feat_locator) XML_DefaultCurrent(cbv->p);	

  hv_store(node, "Prefix", 6, (prefix == NULL) ? SvREFCNT_inc(empty_sv) 
                              : newUTF8SVpv((char *)prefix, 0), PrefixHash);

  ENTER;
  SAVETMPS;

  PUSHMARK(sp);
  EXTEND(sp, 2);
  PUSHs(cbv->self_sv);
  PUSHs(sv_2mortal(newRV_noinc((SV*)node)));
  PUTBACK;
  perl_call_method("end_prefix_mapping", G_DISCARD);

  FREETMPS;
  LEAVE;

  del_ns_mapping(cbv->ns_stack, (char*)prefix);
}  /* End nsEnd */

static void
elementDecl(void *data,
        const char *name,
        XML_Content *model) {
  dSP;
  CallbackVector *cbv = (CallbackVector*) data;
  HV *thing = newHV();
  SV *cmod;

  ENTER;
  SAVETMPS;

  cmod = generate_model(model);

  hv_store(thing, "Name", 4, newUTF8SVpv((char*)name, 0), NameHash);
  hv_store(thing, "Model", 5, cmod, 0);

  Safefree(model);
  PUSHMARK(sp);
  EXTEND(sp, 3);
  PUSHs(cbv->self_sv);
  PUSHs(sv_2mortal(newRV_noinc((SV*)thing)));
  PUTBACK;
  perl_call_method("element_decl", G_DISCARD);
  FREETMPS;
  LEAVE;

}  /* End elementDecl */

static void
attributeDecl(void * data,
          const char * elname,
          const char * attname,
          const char * att_type,
          const char * dflt,
          int          reqorfix) {
  dSP;
  CallbackVector *cbv = (CallbackVector*) data;
  HV * node = newHV();
  SV * dfltsv;
  SV * valsv;

  if (dflt && reqorfix) {
      dfltsv = newUTF8SVpv("#FIXED", 0);
      valsv = newUTF8SVpv((char*)dflt, 0);
  }
  else if (dflt) {
      dfltsv = &PL_sv_undef;
      valsv = newUTF8SVpv((char*)dflt, 0);
  }
  else {
      dfltsv = newUTF8SVpv(reqorfix ? "#REQUIRED" : "#IMPLIED", 0);
      valsv = &PL_sv_undef;
  }

  hv_store(node, "eName", 5, newUTF8SVpv((char *)elname, 0), 0);
  hv_store(node, "aName", 5, newUTF8SVpv((char *)attname, 0), 0);
  hv_store(node, "Type", 4, newUTF8SVpv((char *)att_type, 0), 0);
  hv_store(node, "Mode", 4, dfltsv, 0);
  hv_store(node, "Value", 5, valsv, ValueHash);

  ENTER;
  SAVETMPS;
  PUSHMARK(sp);
  EXTEND(sp, 5);
  PUSHs(cbv->self_sv);
  PUSHs(sv_2mortal(newRV_noinc((SV*)node)));
  PUTBACK;
  perl_call_method("attribute_decl", G_DISCARD);

  FREETMPS;
  LEAVE;
}  /* End attributeDecl */

static void 
skippedEntity(void * data, 
              const char * name, 
              int isparam) {
    dSP;
    CallbackVector* cbv = (CallbackVector*) data;
    HV * entity = newHV();
    char* pname;
    
    xse_characters(data, cbv->chrbuffer);
    if (cbv->feat_locator) XML_DefaultCurrent(cbv->p);
    
    pname = (char*) mymalloc(strlen(name) + 2);
    strcpy(pname, "%");

    hv_store(entity, "Name", 4, 
             newUTF8SVpv((char*)(isparam ? strcat(pname, name) : name), 0), 
             NameHash);

    myfree(pname);
    
    ENTER;
    SAVETMPS;
    PUSHMARK(sp);
    EXTEND(sp, 2);
    PUSHs(cbv->self_sv);
    PUSHs(sv_2mortal(newRV_noinc((SV*)entity)));
    PUTBACK;
    perl_call_method("skipped_entity", G_DISCARD);

    FREETMPS;
    LEAVE;
    
} /* skippedEntity */

static void
entityDecl(void *data,
       const char *name,
       int isparam,
       const char *value,
       int vlen,
       const char *base,
       const char *sysid,
       const char *pubid,
       const char *notation) {
  dSP;
  CallbackVector *cbv = (CallbackVector*) data;
  HV * node = newHV();
  char* pname; 

  pname = (char*) mymalloc(strlen(name) + 2);
  strcpy(pname, "%");

  hv_store(node, "Name", 4, 
           newUTF8SVpv((char *)(isparam ? strcat(pname, name) : name), 0), 
	   NameHash);

  myfree(pname);

  ENTER;
  SAVETMPS;
  PUSHMARK(sp);
  EXTEND(sp, 2);
  PUSHs(cbv->self_sv);

  /* --- internal entity --- */
  if (value) {
    hv_store(node, "Value", 5, newUTF8SVpv((char *)value, vlen), 0);

    PUSHs(sv_2mortal(newRV_noinc((SV*)node)));
    PUTBACK;
    perl_call_method("internal_entity_decl", G_DISCARD);

  /* --- external parsed entity --- */
  } else {
    char* key;

    hv_store(node, "SystemId", 8, 
	     sysid ? newUTF8SVpv((char*)sysid, 0) : SvREFCNT_inc(empty_sv), 
	     SystemIdHash);
    hv_store(node, "PublicId", 8, 
             pubid ? newUTF8SVpv((char*)pubid, 0) : SvREFCNT_inc(empty_sv), 
	     PublicIdHash);

    PUSHs(sv_2mortal(newRV_noinc((SV*)node)));
    PUTBACK;
    perl_call_method("external_entity_decl", G_DISCARD);

    /* storing entity name */
    key = (char*) mymalloc(300);
    xse_extern_ent_key(key, base, sysid, pubid);
    hv_store(cbv->extern_hv, key, strlen(key),
             newUTF8SVpv((char*)name, 0), 0);
    myfree(key);
  }
 
  FREETMPS;
  LEAVE;

}  /* End entityDecl */

static void
doctypeStart(void *userData,
         const char* name,
         const char* sysid,
         const char* pubid,
         int hasinternal) {
  dSP;
  CallbackVector *cbv = (CallbackVector*) userData;
  HV *node = newHV();
  char* key;

  hv_store(node, "Name", 4, newUTF8SVpv((char*)name, 0), NameHash);
  hv_store(node, "SystemId", 8, 
           sysid ? newUTF8SVpv((char*)sysid, 0) : SvREFCNT_inc(empty_sv), 
	   SystemIdHash);
  hv_store(node, "PublicId", 8, 
           pubid ? newUTF8SVpv((char*)pubid, 0) : SvREFCNT_inc(empty_sv), 
	   PublicIdHash);

  ENTER;
  SAVETMPS;

  PUSHMARK(sp);
  EXTEND(sp, 2);
  PUSHs(cbv->self_sv);
  PUSHs(sv_2mortal(newRV_noinc((SV*)node)));
  PUTBACK;
  perl_call_method("start_dtd", G_DISCARD);
  FREETMPS;
  LEAVE;

  /* storing entity name */
  key = (char*) mymalloc(300);
  xse_extern_ent_key(key, "", sysid, pubid);
  hv_store(cbv->extern_hv, key, strlen(key),
           newUTF8SVpv("[dtd]", 0), 0);
  myfree(key);

}  /* End doctypeStart */

static void
doctypeEnd(void *userData) {
  dSP;
  CallbackVector *cbv = (CallbackVector*) userData;

  ENTER;
  SAVETMPS;

  PUSHMARK(sp);
  EXTEND(sp, 1);
  PUSHs(cbv->self_sv);
  PUTBACK;
  perl_call_method("end_dtd", G_DISCARD);
  FREETMPS;
  LEAVE;
}  /* End doctypeEnd */

static void
xmlDecl(void *userData,
    const char *version,
    const char *encoding,
    int standalone) 
{
  dSP;
  CallbackVector *cbv = (CallbackVector*) userData;
  HV *node = newHV();

  hv_store(node, "Version", 7, version ? newUTF8SVpv((char*)version, 0) 
		 : SvREFCNT_inc(empty_sv), VersionHash);
  hv_store(node, "Encoding", 8, encoding ? newUTF8SVpv((char*)encoding, 0)
		 : SvREFCNT_inc(empty_sv), EncodingHash);
  hv_store(node, "Standalone", 10, standalone == -1 ? &PL_sv_undef
		 : (standalone ? newUTF8SVpv("yes",0) : newUTF8SVpv("no",0)), 0);

  /* 1/0 instead of 'yes'/'no'
  hv_store(node, "Standalone", 10, standalone == -1 ? &PL_sv_undef
		 : (standalone ? &PL_sv_yes : &PL_sv_no), 0); 
  */

  /* writing to locator */
  hv_store(cbv->locator_hv, "XMLVersion", 10, version ? 
           newUTF8SVpv((char*)version, 0) : newUTF8SVpv("1.0", 3), XMLVersionHash);
  if (SvCUR(*(hv_fetch(cbv->locator_hv, "Encoding", 8, 0))) == 0) {
    hv_store(cbv->locator_hv, "Encoding", 8, encoding ? 
             newUTF8SVpv((char*)encoding, 0) : newUTF8SVpv("utf-8",5), EncodingHash);
  } 

  ENTER;
  SAVETMPS;

  PUSHMARK(sp);
  EXTEND(sp, 2);
  PUSHs(cbv->self_sv);
  PUSHs(sv_2mortal(newRV_noinc((SV*)node)));
  PUTBACK;
  perl_call_method("xml_decl", G_DISCARD);
  FREETMPS;
  LEAVE;
}  /* End xmlDecl */

static void
unparsedEntityDecl(void *userData,
           const char* entity,
           const char* base,
           const char* sysid,
           const char* pubid,
           const char* notation)
{
  dSP;
  CallbackVector* cbv = (CallbackVector*) userData;
  HV *node = newHV();

  hv_store(node, "Name", 4, newUTF8SVpv((char*)entity, 0), NameHash);
  hv_store(node, "PublicId", 8, pubid ? newUTF8SVpv((char*)pubid, 0) 
                  : SvREFCNT_inc(empty_sv), PublicIdHash);
  hv_store(node, "SystemId", 8, newUTF8SVpv((char*)sysid, 0), SystemIdHash);
  hv_store(node, "Notation", 8, newUTF8SVpv((char*)notation, 0), 0);

  ENTER;
  SAVETMPS;

  PUSHMARK(sp);
  EXTEND(sp, 6);
  PUSHs(cbv->self_sv);
  PUSHs(sv_2mortal(newRV_noinc((SV*)node)));
  PUTBACK;
  perl_call_method("unparsed_entity_decl", G_DISCARD);

  FREETMPS;
  LEAVE;
}  /* End unparsedEntityDecl */

static void
notationDecl(void *userData,
         const char *name,
         const char *base,
         const char *sysid,
         const char *pubid)
{
  dSP;
  CallbackVector* cbv = (CallbackVector*) userData;
  HV *node = newHV();

  hv_store(node, "Name", 4, newUTF8SVpv((char*)name, 0), NameHash);
  hv_store(node, "SystemId", 8, sysid ? newUTF8SVpv((char*)sysid, 0) 
		 : SvREFCNT_inc(empty_sv), SystemIdHash);
  hv_store(node, "PublicId", 8, pubid ? newUTF8SVpv((char*)pubid, 0) 
		 : SvREFCNT_inc(empty_sv), PublicIdHash);

  PUSHMARK(sp);
  XPUSHs(cbv->self_sv);
  XPUSHs(sv_2mortal(newRV_noinc((SV*)node)));
  PUTBACK;
  perl_call_method("notation_decl", G_DISCARD);
}  /* End notationDecl */

static int
externalEntityRef(XML_Parser parser,
          const char* open,
          const char* base,
          const char* sysid,
          const char* pubid)
{
  dSP;
#if defined(USE_THREADS) && PATCHLEVEL==6
  dTHX;
#endif
  int count;
  int ret = 0;
  int parse_done = 0;
  CallbackVector* cbv = (CallbackVector*) XML_GetUserData(parser);
  char* key;
  SV **name;
  HV *start = newHV();
  HV *end = newHV();
  char* pname;

  xse_characters((void*)cbv, cbv->chrbuffer);

  /* fetching entity name */
  key = (char*) mymalloc(300);
  xse_extern_ent_key(key, base, sysid, pubid);
  name = hv_fetch(cbv->extern_hv, key, strlen(key), 0);
  myfree(key);

  pname = SvPV_nolen(*name);

  if (( (pname[0] == '[' || pname[0] == '%') && !cbv->feat_entpar) || 
      ( (pname[0] != '[' && pname[0] != '%') && !cbv->feat_entgen)) {

      skippedEntity(cbv, pname, 0);
      return 1;
  }

  ENTER ;
  SAVETMPS ;

  /* start_entity */
  hv_store(start, "Name", 4, SvREFCNT_inc(*name), NameHash);

  PUSHMARK(sp);
  EXTEND(sp, 2);
  PUSHs(cbv->self_sv);
  PUSHs(sv_2mortal(newRV_noinc((SV*)start)));
  PUTBACK;
  perl_call_method("start_entity", G_DISCARD);
  SPAGAIN;

  /* open the entity */
  PUSHMARK(sp);
  EXTEND(sp, 4);
  PUSHs(cbv->self_sv);
  PUSHs(base ? sv_2mortal(newUTF8SVpv((char*) base, 0)) : &PL_sv_undef);
  PUSHs(sysid ? sv_2mortal(newUTF8SVpv((char*) sysid, 0)) : &PL_sv_undef);
  PUSHs(pubid ? sv_2mortal(newUTF8SVpv((char*) pubid, 0)) : &PL_sv_undef);
  PUTBACK;
  count = perl_call_method("_get_external_entity", G_SCALAR);

  SPAGAIN;

  if (count >= 1) {
    SV * result = POPs;

    int type;

    if (result && (type = SvTYPE(result)) > 0) {
      SV **pval = hv_fetch((HV*)SvRV(cbv->self_sv), "Parser", 6, 0);

      if (! pval || ! SvIOK(*pval)) {
        append_error(parser, 
	"Can't find parser entry in XML::SAX::ExpatXS object");

      } else {
        XML_Parser entpar;
	char *errmsg = (char *) 0;

	entpar = XML_ExternalEntityParserCreate(parser, open, 0);

	XML_SetBase(entpar, XML_GetBase(parser));

	sv_setiv(*pval, (IV) entpar);

	cbv->p = entpar;

	PUSHMARK(sp);
	EXTEND(sp, 2);
	PUSHs(*pval);
	PUSHs(result);
	PUTBACK;
	count = perl_call_pv("XML::SAX::ExpatXS::Do_External_Parse",
		               G_SCALAR | G_EVAL);
        SPAGAIN;

	if (SvTRUE(ERRSV)) {
	  char  *hold;
	  STRLEN   len;

	  POPs;
          hold = SvPV(ERRSV, len);
          New(326, errmsg, len + 1, char);
          if (len)
            Copy(hold, errmsg, len, char);
          goto Extparse_Cleanup;
	}

        if (count > 0)
        ret = POPi;
	/* warn("external parsing return value: %d", ret); */
        parse_done = 1;

        Extparse_Cleanup:
        cbv->p = parser;
        sv_setiv(*pval, (IV) parser);
        XML_ParserFree(entpar);

        if (SvTRUE(ERRSV))
          append_error(parser, SvPV(ERRSV, PL_na));
      }
    }
  }

  if (! ret && ! parse_done)
    append_error(parser, "Handler couldn't resolve external entity");

  /* end entity */
  hv_store(end, "Name", 4, SvREFCNT_inc(*name), NameHash);

  PUSHMARK(sp);
  EXTEND(sp, 2);
  PUSHs(cbv->self_sv);
  PUSHs(sv_2mortal(newRV_noinc((SV*)end)));
  PUTBACK;
  perl_call_method("end_entity", G_DISCARD);

  FREETMPS ;
  LEAVE ;

  return ret;

}  /* End externalEntityRef */

/*================================================================
** This is the function that expat calls to convert multi-byte sequences
** for external encodings. Each byte in the sequence is used to index
** into the current map to either set the next map or, in the case of
** the final byte, to get the corresponding Unicode scalar, which is
** returned.
*/

static int
convert_to_unicode(void *data, const char *seq) {
  Encinfo *enc = (Encinfo *) data;
  PrefixMap *curpfx;
  int count;
  int index = 0;

  for (count = 0; count < 4; count++) {
    unsigned char byte = (unsigned char) seq[count];
    unsigned char bndx;
    unsigned char bmsk;
    int offset;

    curpfx = &enc->prefixes[index];
    offset = ((int) byte) - curpfx->min;
    if (offset < 0)
      break;
    if (offset >= curpfx->len && curpfx->len != 0)
      break;

    bndx = byte >> 3;
    bmsk = 1 << (byte & 0x7);

    if (curpfx->ispfx[bndx] & bmsk) {
      index = enc->bytemap[curpfx->bmap_start + offset];
    }
    else if (curpfx->ischar[bndx] & bmsk) {
      return enc->bytemap[curpfx->bmap_start + offset];
    }
    else
      break;
  }

  return -1;
}  /* End convert_to_unicode */

static int
unknownEncoding(void *unused, const char *name, XML_Encoding *info)
{
  SV ** encinfptr;
  Encinfo *enc;
  int namelen;
  int i;
  char buff[42];

  namelen = strlen(name);
  if (namelen > 40)
    return 0;

  /* Make uppercase */
  for (i = 0; i < namelen; i++) {
    char c = name[i];
    if (c >= 'a' && c <= 'z')
      c -= 'a' - 'A';
    buff[i] = c;
  }

  if (! EncodingTable) {
    EncodingTable = perl_get_hv("XML::SAX::ExpatXS::Encoding::Encoding_Table", FALSE);
    if (! EncodingTable)
      croak("Can't find XML::SAX::ExpatXS::Encoding::Encoding_Table");
  }

  encinfptr = hv_fetch(EncodingTable, buff, namelen, 0);

  if (! encinfptr || ! SvOK(*encinfptr)) {
    /* Not found, so try to autoload */
    dSP;
    int count;

    ENTER;
    SAVETMPS;
    PUSHMARK(sp);
    XPUSHs(sv_2mortal(newSVpvn(buff,namelen)));
    PUTBACK;
    perl_call_pv("XML::SAX::ExpatXS::Encoding::load_encoding", G_DISCARD);

    encinfptr = hv_fetch(EncodingTable, buff, namelen, 0);
    FREETMPS;
    LEAVE;

    if (! encinfptr || ! SvOK(*encinfptr))
      return 0;
  }

  if (! sv_derived_from(*encinfptr, "XML::SAX::ExpatXS::Encinfo"))
    croak("Entry in XML::SAX::ExpatXS::Encoding::Encoding_Table not an Encinfo object");

  enc = (Encinfo *) SvIV((SV*)SvRV(*encinfptr));
  Copy(enc->firstmap, info->map, 256, int);
  info->release = NULL;
  if (enc->prefixes_size) {
    info->data = (void *) enc;
    info->convert = convert_to_unicode;
  }
  else {
    info->data = NULL;
    info->convert = NULL;
  }

  return 1;
}  /* End unknownEncoding */


static void
recString(void *userData, const char *string, int len)
{
  int i, ln = 0, cl = 0;

  CallbackVector *cbv = (CallbackVector*) userData;
  xse_get_end_position(cbv->p, ln, cl, string, len);
  
  /* printf("-->%d, %d\n", ln, cl); */
  hv_store(cbv->locator_hv, "LineNumber", 10, newSViv(ln), 0);
  hv_store(cbv->locator_hv, "ColumnNumber", 12, newSViv(cl), 0);

  if (cbv->feat_recstring) {
    if (SvCUR(cbv->chrbuffer) > 0) {
      sv_setsv(cbv->recstring, cbv->chrbuffer);
    } else {
      sv_setpvn(cbv->recstring, (char *) string, len);
    }
  }
}  /* End recString */

MODULE = XML::SAX::ExpatXS PACKAGE = XML::SAX::ExpatXS    PREFIX = XML_

PROTOTYPES: DISABLE

BOOT:
    PERL_HASH(PrefixHash, "Prefix", 6);
    PERL_HASH(NamespaceURIHash, "NamespaceURI", 12);
    PERL_HASH(NameHash, "Name", 4);
    PERL_HASH(LocalNameHash, "LocalName", 9);
    PERL_HASH(AttributesHash, "Attributes", 10);
    PERL_HASH(ValueHash, "Value", 5);
    PERL_HASH(DataHash, "Data", 4);
    PERL_HASH(TargetHash, "Target", 6);
    PERL_HASH(VersionHash, "Version", 7);
    PERL_HASH(XMLVersionHash, "XMLVersion", 10);
    PERL_HASH(EncodingHash, "Encoding", 8);
    PERL_HASH(PublicIdHash, "PublicId", 8);
    PERL_HASH(SystemIdHash, "SystemId", 8);
    empty_sv = newUTF8SVpv("", 0);

XML_Parser
XML_ParserCreate(self_sv, enc_sv, namespaces)
    SV *            self_sv
    SV *            enc_sv
    int            namespaces
    CODE:
    {
      CallbackVector *cbv;
      enum XML_ParamEntityParsing pep = XML_PARAM_ENTITY_PARSING_UNLESS_STANDALONE;
      char *enc = (char *) (SvTRUE(enc_sv) ? SvPV(enc_sv,PL_na) : 0);
      SV ** spp;

      Newz(320, cbv, 1, CallbackVector);
      cbv->self_sv = SvREFCNT_inc(self_sv);

      spp = hv_fetch((HV*)SvRV(cbv->self_sv), "NoExpand", 8, 0);
      if (spp && SvTRUE(*spp))
        cbv->no_expand = 1;

      spp = hv_fetch((HV*)SvRV(cbv->self_sv), "Context", 7, 0);
      if (! spp || ! *spp || !SvROK(*spp))
        croak("XML::SAX::ExpatXS instance missing Context");

      cbv->context = (AV*) SvRV(*spp);

      spp = hv_fetch((HV*)SvRV(cbv->self_sv), "Namespace_Stack",
            15, FALSE);

      if (!spp || !*spp || !SvROK(*spp))
        croak("XML::SAX::ExpatXS instance missing Namespace_Stack");

      cbv->ns_stack = (AV *)SvRV(*spp);

      cbv->ns = (unsigned) namespaces;
      if (namespaces)
        {
          RETVAL = XML_ParserCreate_MM(enc, &ms, nsdelim);
          XML_SetNamespaceDeclHandler(RETVAL, nsStart, nsEnd);
        }
      else
        {
          RETVAL = XML_ParserCreate_MM(enc, &ms, NULL);
        }

      cbv->p = RETVAL;
      XML_SetUserData(RETVAL, (void *) cbv);

      XML_SetElementHandler(RETVAL, startElement, endElement);
      XML_SetCharacterDataHandler(RETVAL, characterData);
      XML_SetProcessingInstructionHandler(RETVAL, processingInstruction);
      XML_SetCommentHandler(RETVAL, commenthandle);
      XML_SetCdataSectionHandler(RETVAL, startCdata, endCdata);
      XML_SetElementDeclHandler(RETVAL, elementDecl);
      XML_SetAttlistDeclHandler(RETVAL, attributeDecl);
      XML_SetEntityDeclHandler(RETVAL, entityDecl);
      XML_SetUnparsedEntityDeclHandler(RETVAL, unparsedEntityDecl);
      XML_SetNotationDeclHandler(RETVAL, notationDecl);
      XML_SetExternalEntityRefHandler(RETVAL, externalEntityRef);
      XML_SetXmlDeclHandler(RETVAL, xmlDecl);
      XML_SetStartDoctypeDeclHandler(RETVAL, doctypeStart);
      XML_SetEndDoctypeDeclHandler(RETVAL, doctypeEnd);
      XML_SetSkippedEntityHandler(RETVAL, skippedEntity);
      XML_SetUnknownEncodingHandler(RETVAL, unknownEncoding, 0);

      /* reading features */
      cbv->feat_perlxmlns = get_feature(cbv, "http://xmlns.perl.org/sax/xmlns-uris");
      cbv->feat_xmlns = cbv->feat_perlxmlns 
          ? 0 : get_feature(cbv, "http://xml.org/sax/features/xmlns-uris");
      cbv->feat_join = get_feature(cbv, "http://xmlns.perl.org/sax/join-character-data");
      cbv->feat_nsatts = get_feature(cbv, "http://xmlns.perl.org/sax/ns-attributes");
      cbv->feat_locator = get_feature(cbv, "http://xmlns.perl.org/sax/locator");
      cbv->feat_recstring = get_feature(cbv, "http://xmlns.perl.org/sax/recstring");
      cbv->feat_entgen = get_feature(cbv, "http://xml.org/sax/features/external-general-entities");
      cbv->feat_entpar = get_feature(cbv, "http://xml.org/sax/features/external-parameter-entities");
      /* end of reading features */

      if (cbv->no_expand)
	XML_SetDefaultHandler(RETVAL, recString);
      else
	XML_SetDefaultHandlerExpand(RETVAL, recString);

      if (!cbv->feat_entpar) {
          spp = hv_fetch((HV*)SvRV(cbv->self_sv), "ParseParamEnt",
                         13, FALSE);

          if (spp && SvTRUE(*spp)) {
              cbv->feat_entpar = 1;
          }
      }

      XML_SetParamEntityParsing(RETVAL, pep);

      cbv->atts_ready = 0;
      cbv->chrbuffer = newUTF8SVpv("", 0);
      cbv->chr_hv = newHV();
    }
    OUTPUT:
    RETVAL

void
XML_ParserRelease(parser)
      XML_Parser parser
    CODE:
      {
        CallbackVector * cbv = (CallbackVector *) XML_GetUserData(parser);

	 SvREFCNT_dec(cbv->self_sv);
      }

void
XML_ParserFree(parser)
    XML_Parser parser
    CODE:
    {
      CallbackVector * cbv = (CallbackVector *) XML_GetUserData(parser);

      SvREFCNT_dec(cbv->start_sv);
      SvREFCNT_dec(cbv->end_sv);
      SvREFCNT_dec(cbv->char_sv);
      SvREFCNT_dec(cbv->comment_sv);
      SvREFCNT_dec(cbv->chrbuffer);
      SvREFCNT_dec(cbv->self_sv);

      SvREFCNT_dec(cbv->locator_hv);
      SvREFCNT_dec(cbv->extern_hv);
      SvREFCNT_dec(cbv->chr_hv);

      Safefree(cbv);
      XML_ParserFree(parser);
    }

int
XML_ParseString(parser, str)
        XML_Parser            parser
        SV *                  str
    CODE:
        {
      CallbackVector * cbv;
      char * s;
      STRLEN len;
      
      s = SvPV(str, len);

          cbv = (CallbackVector *) XML_GetUserData(parser);

      RETVAL = XML_Parse(parser, s, len, 1);
      SPAGAIN; /* XML_Parse might have changed stack pointer */
      if (! RETVAL)
        append_error(parser, NULL);
    }

    OUTPUT:
    RETVAL

int
XML_ParseStream(parser, ioref, delim=NULL)
    XML_Parser            parser
    SV *                ioref
    SV *                delim
    CODE:
    {
      SV **delimsv;
      CallbackVector * cbv;

      cbv = (CallbackVector *) XML_GetUserData(parser);
      if (delim && SvOK(delim)) {
        cbv->delim = SvPV(delim, cbv->delimlen);
      }
      else {
        cbv->delim = (char *) 0;
      }

      RETVAL = parse_stream(parser, ioref);
      SPAGAIN; /* parse_stream might have changed stack pointer */
    }

    OUTPUT:
    RETVAL

int
XML_ParsePartial(parser, str)
    XML_Parser            parser
    SV *                  str
    CODE:
    {
      CallbackVector * cbv = (CallbackVector *) XML_GetUserData(parser);
      char * s;
      STRLEN len;
      
      s = SvPV(str, len);

      RETVAL = XML_Parse(parser, s, len, 0);
      if (! RETVAL)
        append_error(parser, NULL);
    }

    OUTPUT:
    RETVAL


int
XML_ParseDone(parser)
    XML_Parser            parser
    CODE:
    {
      RETVAL = XML_Parse(parser, "", 0, 1);
      if (! RETVAL)
        append_error(parser, NULL);
    }

    OUTPUT:
    RETVAL


void
XML_SetBase(parser, base)
    XML_Parser            parser
    SV *                base
    CODE:
    {
      char * b;

      if (! SvOK(base)) {
        b = (char *) 0;
      }
      else {
        b = SvPV(base, PL_na);
      }

      XML_SetBase(parser, b);
    }


SV *
XML_GetBase(parser)
    XML_Parser            parser
    CODE:
    {
      const char *ret = XML_GetBase(parser);
      if (ret) {
        ST(0) = sv_newmortal();
        sv_setpv(ST(0), ret);
      }
      else {
        ST(0) = &PL_sv_undef;
      }
    }


HV *
XML_GetLocator(parser, pubid, sysid, encoding)
    XML_Parser            parser
    SV *		  pubid
    SV *		  sysid
    SV *		  encoding
    CODE:
    {
      CallbackVector * cbv = (CallbackVector *) XML_GetUserData(parser);

      cbv->locator_hv = newHV();
      hv_store(cbv->locator_hv, "LineNumber", 10, 
               newSViv(1), 0);
      hv_store(cbv->locator_hv, "ColumnNumber", 12, 
               newSViv(1), 0);
      hv_store(cbv->locator_hv, "XMLVersion", 10, 
               newUTF8SVpv("1.0", 3), XMLVersionHash);
      hv_store(cbv->locator_hv, "Encoding", 8, 
               SvCUR(encoding) > 0 ? SvREFCNT_inc(encoding) : newUTF8SVpv("", 0), 
               EncodingHash);	       
      hv_store(cbv->locator_hv, "SystemId", 8, 
               SvCUR(sysid) > 0 ? SvREFCNT_inc(sysid) : newUTF8SVpv("", 0), 
               SystemIdHash);
      hv_store(cbv->locator_hv, "PublicId", 8, 
               SvCUR(pubid) > 0 ? SvREFCNT_inc(pubid) : newUTF8SVpv("", 0), 
               PublicIdHash);

      RETVAL = cbv->locator_hv;
    }

    OUTPUT:
    RETVAL


SV *
XML_GetRecognizedString(parser)
    XML_Parser            parser
    CODE:
    {
      CallbackVector * cbv = (CallbackVector *) XML_GetUserData(parser);

      cbv->recstring = newUTF8SVpvn("", 0);

      RETVAL = newRV_noinc(cbv->recstring);
    }

    OUTPUT:
    RETVAL


HV *
XML_GetExternEnt(parser)
    XML_Parser            parser
    CODE:
    {
      CallbackVector * cbv = (CallbackVector *) XML_GetUserData(parser);

      cbv->extern_hv = newHV();

      RETVAL = cbv->extern_hv;
    }

    OUTPUT:
    RETVAL

void
XML_SetCallbacks(parser, start, end, chars, comment)
    XML_Parser            parser
    SV *		  start
    SV *		  end
    SV *		  chars
    SV *		  comment
    CODE:
    {
      CallbackVector * cbv = (CallbackVector *) XML_GetUserData(parser);

      if (cbv->start_sv) sv_setsv(cbv->start_sv, start);    
      else cbv->start_sv = SvREFCNT_inc(start);

      if (cbv->end_sv) sv_setsv(cbv->end_sv, end);    
      else cbv->end_sv = SvREFCNT_inc(end);

      if (cbv->char_sv) sv_setsv(cbv->char_sv, chars);    
      else cbv->char_sv = SvREFCNT_inc(chars);

      if (cbv->comment_sv) sv_setsv(cbv->comment_sv, comment);    
      else cbv->comment_sv = SvREFCNT_inc(comment);
    }

void
XML_PositionContext(parser, lines)
    XML_Parser            parser
    int                lines
    PREINIT:
    int parsepos;
        int size;
        const char *pos = XML_GetInputContext(parser, &parsepos, &size);
    const char *markbeg;
    const char *limit;
    const char *markend;
    int length, relpos;
    int  cnt;

    PPCODE:
      if (! pos)
            return;

      for (markbeg = &pos[parsepos], cnt = 0; markbeg >= pos; markbeg--)
        {
          if (*markbeg == '\n')
        {
          cnt++;
          if (cnt > lines)
            break;
        }
        }

      markbeg++;

          relpos = 0;
      limit = &pos[size];
      for (markend = &pos[parsepos + 1], cnt = 0;
           markend < limit;
           markend++)
        {
          if (*markend == '\n')
        {
          if (cnt == 0)
                     relpos = (markend - markbeg) + 1;
          cnt++;
          if (cnt > lines)
            {
              markend++;
              break;
            }
        }
        }

      length = markend - markbeg;
          if (relpos == 0)
            relpos = length;

          EXTEND(sp, 2);
      PUSHs(sv_2mortal(newSVpvn((char *) markbeg, length)));
      PUSHs(sv_2mortal(newSViv(relpos)));

void
XML_DefaultCurrent(parser)
    XML_Parser            parser
    CODE:
    {
      CallbackVector * cbv = (CallbackVector *) XML_GetUserData(parser);

      XML_DefaultCurrent(parser);
    }

int
XML_GetErrorCode(parser)
    XML_Parser            parser

int
XML_GetCurrentLineNumber(parser)
    XML_Parser            parser

int
XML_GetCurrentColumnNumber(parser)
    XML_Parser            parser

const char *
XML_ExpatVersion()

long
XML_GetCurrentByteIndex(parser)
    XML_Parser            parser

int
XML_GetSpecifiedAttributeCount(parser)
    XML_Parser            parser

char *
XML_ErrorString(code)
    int                code
    CODE:
    const char *ret = XML_ErrorString(code);
    ST(0) = sv_newmortal();
    sv_setpv((SV*)ST(0), ret);

SV *
XML_LoadEncoding(data, size)
    char *             data
    int                size
    CODE:
    {
      Encmap_Header *emh = (Encmap_Header *) data;
      unsigned pfxsize, bmsize;

      if (size < sizeof(Encmap_Header)
          || ntohl(emh->magic) != ENCMAP_MAGIC) {
        RETVAL = &PL_sv_undef;
      }
      else {
        Encinfo    *entry;
        SV        *sv;
        PrefixMap    *pfx;
        unsigned short *bm;
        int namelen;
        int i;

        pfxsize = ntohs(emh->pfsize);
        bmsize  = ntohs(emh->bmsize);

        if (size != (sizeof(Encmap_Header)
             + pfxsize * sizeof(PrefixMap)
             + bmsize * sizeof(unsigned short))) {
          RETVAL = &PL_sv_undef;
        }
        else {
          /* Convert to uppercase and get name length */

          for (i = 0; i < sizeof(emh->name); i++) {
        char c = emh->name[i];

          if (c == (char) 0)
            break;

        if (c >= 'a' && c <= 'z')
          emh->name[i] -= 'a' - 'A';
          }
          namelen = i;

          RETVAL = newSVpvn(emh->name, namelen);

          New(322, entry, 1, Encinfo);
          entry->prefixes_size = pfxsize;
          entry->bytemap_size  = bmsize;
          for (i = 0; i < 256; i++) {
            entry->firstmap[i] = ntohl(emh->map[i]);
          }

          pfx = (PrefixMap *) &data[sizeof(Encmap_Header)];
          bm = (unsigned short *) (((char *) pfx)
                       + sizeof(PrefixMap) * pfxsize);

          New(323, entry->prefixes, pfxsize, PrefixMap);
          New(324, entry->bytemap, bmsize, unsigned short);

          for (i = 0; i < pfxsize; i++, pfx++) {
        PrefixMap *dest = &entry->prefixes[i];

        dest->min = pfx->min;
        dest->len = pfx->len;
        dest->bmap_start = ntohs(pfx->bmap_start);
        Copy(pfx->ispfx, dest->ispfx,
             sizeof(pfx->ispfx) + sizeof(pfx->ischar), unsigned char);
          }

          for (i = 0; i < bmsize; i++)
        entry->bytemap[i] = ntohs(bm[i]);

          sv = newSViv(0);
          sv_setref_pv(sv, "XML::SAX::ExpatXS::Encinfo", (void *) entry);

          if (! EncodingTable) {
        EncodingTable
          = perl_get_hv("XML::SAX::ExpatXS::Encoding::Encoding_Table",
                FALSE);
        if (! EncodingTable)
          croak("Can't find XML::SAX::ExpatXS::Encoding::Encoding_Table");
          }

          hv_store(EncodingTable, emh->name, namelen, sv, 0);
        }
      }
    }
    OUTPUT:
    RETVAL

void
XML_FreeEncoding(enc)
    Encinfo *            enc
    CODE:
    Safefree(enc->bytemap);
    Safefree(enc->prefixes);
    Safefree(enc);

SV *
XML_OriginalString(parser)
    XML_Parser            parser
    CODE:
    {
      int parsepos, size;
      const char *buff = XML_GetInputContext(parser, &parsepos, &size);
      if (buff) {
        RETVAL = newSVpvn((char *) &buff[parsepos],
                  XML_GetCurrentByteCount(parser));
      }
      else {
        RETVAL = newSVpv("", 0);
      }
    }
    OUTPUT:
    RETVAL

int
XML_Do_External_Parse(parser, result)
    XML_Parser          parser
    SV *                result
    CODE:
    {
     int type;

      CallbackVector * cbv = (CallbackVector *) XML_GetUserData(parser);

      if (SvROK(result) && SvOBJECT(SvRV(result))) {
        RETVAL = parse_stream(parser, result);
      }
      else if (isGV(result)) {
        RETVAL = parse_stream(parser,
                  sv_2mortal(newRV((SV*) GvIOp(result))));
      }
      else if (SvPOK(result)) {
        STRLEN  eslen;
        int pret;
        char *entstr = SvPV(result, eslen);

        RETVAL = XML_Parse(parser, entstr, eslen, 1);
      }
    }
    OUTPUT:
    RETVAL
