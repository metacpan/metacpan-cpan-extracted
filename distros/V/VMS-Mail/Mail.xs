/* VMS::Mail - interface to vms callable mail routines from perl
 *
 * Version:	0.06
 * Author:	D. North, CCP  <rold5@tditx.com>
 * Date:	09.04.12
 * Extra credits:
 *		The itemlist manipulation code was originally modelled on the
 *		build_itmlst code from the VMS::Device module by Dan Sugalski.
 *		I pretty seriously hacked it up to suit my purposes, and as
 *		such, it bears little resemblance to the original code... still
 *		many thanks to Dan for the original example code (the hard
 *		part).
 *
 * Copyright:
 *		Copyright (c) 2000 David G. North, CCP <rold5@tditx.com>
 *		You may distribute under the terms of the Artistic License,
 *		as distributed with Perl.
 * Description:
 *		This module supplies a complete interface to callable the
 *		VMSMail routines for client-side access.
 *
 * Revision History:
 *
 * 0.01  00.07.09 DGN	Original version created
 * 0.02  00.07.17 DGN	First complete implementation - partially untested
 *			Initial external release for peer review
 * 0.03  00.07.21 DGN	Renamed from VMSMail to just Mail. Reversioned
 *			Several bugfixes, added an smg read kbd routine
 * 0.04  00.08.01 DGN	Changed &sv_undef to &PL_sv_undef for Perl 5.6
 * 0.05  00.08.01 DGN	Repackaged withOUT the VMS file attribs in the zipfile!
 * 0.06  09.04.12 Craig Berry
 *                      see Changes.
 */
#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <starlet.h>
#include <mail$routines.h>
#include <lib$routines.h>
#include <maildef.h>
#include <mailmsgdef.h>
#include <ssdef.h>
#include <descrip.h>
#include <varargs.h>

#include <smgdef.h>
#include <smgmsg.h>
#include <smg$routines.h>


typedef struct itmlst_3 {
  unsigned short int length;
  unsigned short int code;
  void *address;
  void *return_length;
} ITMLST_3;

typedef struct mailctxdef {
  union {
    long int m_flags;
    struct {
      unsigned mailfile	:1;	/* Type mailfile */
#define MCTX_M_MAILFILE 1
      unsigned message	:1;	/* Type message */
#define MCTX_M_MESSAGE  2
      unsigned send	:1;	/* Type send */
#define MCTX_M_SEND     4
      unsigned user	:1;	/* Type user */
#define MCTX_M_USER     8
      unsigned initd	:1;	/* Initialized */
#define MCTX_M_INITD    16
      unsigned closed	:1;	/* Context is closed */
#define MCTX_M_CLOSED   32
#define MCTX_M_TYPES      (MCTX_M_MAILFILE|MCTX_M_MESSAGE|MCTX_M_SEND|MCTX_M_USER)
    } v;
  } flags;
  unsigned long int context;
} MAILCTXDEF;

#define TYP_C_BAD 0		/* bad type */
#define TYP_C_STR 1		/* String data type */
#define TYP_C_LNG 2		/* Longword data type */
#define TYP_C_WRD 3		/* word data type */
#define TYP_C_VMD 4		/* VMS date time data type */
#define TYP_C_PRS 5		/* 'presence' data type */
#define TYP_C_CBK 6		/* Callback data type */
#define TYP_C_CBP 7		/* Callback parameter data type */
#define TYP_C_CTX 8		/* Context pointer (VMS level) */
#define TYP_C_BV1 9		/* bit vector */
#define TYP_C_BV2 10		/* bit vector */
#define TYP_C_BV4 11		/* bit vector */
#define TYP_C_EN1 12		/* enum val */
#define TYP_C_EN2 13		/* enum val */
#define TYP_C_EN4 14		/* enum val */

typedef struct itmdef {
  int  code;		/* Itmlst code */
  char *name;		/* PERL 'name' of item */
  int  buflen;		/* Length for associated bufferring t/f call */
  int  rettype;		/* Item type information */
  void *ptr1;		/* A parameter that can be stowed... */
} ITMDEF;

#define I_CSTR(nm,cod,len) {cod,nm,len,TYP_C_STR,0},
#define I_VMD(nm,cod) {cod,nm,8,TYP_C_VMD,0},
#define I_LNG(nm,cod) {cod,nm,4,TYP_C_LNG,0},
#define I_WRD(nm,cod) {cod,nm,2,TYP_C_WRD,0},
#define I_PRS(nm,cod) {cod,nm,0,TYP_C_PRS,0},
#define I_CTX(nm,cod,mapper) {cod,nm,0,TYP_C_CTX,(void*)mapper},
#define I_CBK(rnm,pnm,rcod,pcod,handler) \
             {rcod,rnm,0,TYP_C_CBK,(void*)handler},\
             {pcod,pnm,0,TYP_C_CBP,0},
#define I_BV2(nm,cod,mapdef) {cod,nm,2,TYP_C_BV2,(void*)mapdef},
#define I_BV4(nm,cod,mapdef) {cod,nm,4,TYP_C_BV4,(void*)mapdef},
#define I_EN2(nm,cod,mapdef) {cod,nm,2,TYP_C_EN2,(void*)mapdef},
#define I_EN4(nm,cod,mapdef) {cod,nm,4,TYP_C_EN4,(void*)mapdef},
#define I_TRM {0,0,0,0,0}
#define M_BIT(nm,mask) {1,nm,0,TYP_C_BAD,(void*)mask},
#define C_ENM(nm,enval) {1,nm,0,TYP_C_BAD,(void*)enval},
#define DEF_ITEMS(name) static ITMDEF name[] = {
#define END_ITEMS I_TRM };

DEF_ITEMS(null_itmdef) END_ITEMS

DEF_ITEMS(m_flags_bitvec)
  M_BIT("NEWMSG",MAIL$M_NEWMSG)
  M_BIT("REPLIED",MAIL$M_REPLIED)
  M_BIT("XDWMAIL",MAIL$M_DWMAIL)
  M_BIT("EXTMSG",MAIL$M_EXTMSG)
  M_BIT("EXTFNF",MAIL$M_EXTFNF)
  M_BIT("NOTRANS",MAIL$M_NOTRANS)
  M_BIT("EXTNSTD",MAIL$M_EXTNSTD)
  M_BIT("MARKED",MAIL$M_MARKED)
  M_BIT("RECMODE",MAIL$M_RECMODE)
END_ITEMS

DEF_ITEMS(c_username_type_enm)
  C_ENM("TO",MAIL$_TO)
  C_ENM("CC",MAIL$_CC)
END_ITEMS

DEF_ITEMS(c_msgret_type_enm)
  C_ENM("NULL",MAIL$_MESSAGE_NULL)
  C_ENM("HEADER",MAIL$_MESSAGE_HEADER)
  C_ENM("TEXT",MAIL$_MESSAGE_TEXT)
END_ITEMS

typedef struct itmmap {
  ITMDEF *idp;			/* Per-item pointer to the item's def entry */
  ITMLST_3 *ilep;		/* Per-item pointer to the itmlst3 entry */
  SV *sv;			/* An associated input SV if needed */
  unsigned long int ret_len;	/* A place to stuff a returned length */
  struct itmmap *im_link;	/* Used for callback params, bitvecs */
} ITMMAP;

static ITMLST_3 null_itmlst[] = { {0,0,0,0} };

#define PROTECT local_protect

static unsigned long int
local_protect(va_alist)
  va_dcl
{
  va_list args;
  int numargs,i;
  unsigned long int callargs[32];
  unsigned long int (*targ)();

  va_start(args);
  va_count(numargs);
  for (i=0;i<numargs;i++)
    callargs[i] = va_arg(args,long int);

  targ = (unsigned long int (*)()) callargs[0];
  callargs[0] = numargs-1;
  va_end(args);

  lib$establish(lib$sig_to_ret);
  return(lib$callg(callargs,targ));
}

static void
_map_alo_data(
  ITMMAP *imap)
{
  int i;
  char *q;
  for (i=0;imap[i].ilep;i++) {
    if (!imap[i].idp->buflen)
      continue;	/* These are 'presence' items */
    Newz(NULL,q,imap[i].idp->buflen,char);
    memset(q,' ',imap[i].idp->buflen);
    imap[i].ilep->length = imap[i].idp->buflen;
    imap[i].ilep->address = q; }
}

/* mapHVto_itmlst converts a hash into an itemlist-3 map and an
**   itemlist-3 partially constructed template.
**   An unsuccessful mapping leaves error codes set for exit to caller
**   and does NOT return allocated il3 or map data. Upon success, this
**   routine will return the number of items mapped and will allocate
**   and fill in the il3 & imap structures. These should later be
**   released by calling map_free().
**
**   Subsequent use of the mapping depends on the requirements of the
**   calling context... In general, since this is an HV, it will be an
**   *input* to an itmlst. AV's are used for *output* requests.
*/
static int
mapHVto_itmlst(
  ITMDEF   itemdefs[],
  ITMLST_3 **itemlist,
  ITMMAP   **itemmaps,
  HV *hash)
{
  int n_items,i,j;
  ITMLST_3 *il3;
  ITMMAP *imap;

  *itemlist = NULL;
  *itemmaps = NULL;
  n_items = hv_iterinit(hash);	/* Collect # keys */
  Newz(NULL, il3, n_items+1, ITMLST_3);
  Newz(NULL, imap, n_items+1, ITMMAP);
  for (i=0;i<n_items;i++) {
    char *aKey;
    I32 aKeyLen;
    SV *valueSV;

    if (!(valueSV=hv_iternextsv(hash,&aKey,&aKeyLen))) {
      Safefree(il3);
      Safefree(imap);
      SETERRNO(EVMSERR,SS$_BUGCHECK);
      return(-1); }

    for (j=0;itemdefs[j].name;j++)
      if (strEQ(aKey,itemdefs[j].name))
        break;

    if (!itemdefs[j].name) {
      Safefree(il3);
      Safefree(imap);
      SETERRNO(EVMSERR,SS$_BADPARAM);
      return(-1); }
    imap[i].sv = valueSV;
    imap[i].idp = &itemdefs[j];
    imap[i].ilep = &il3[i];
    imap[i].ilep->length = 0;
    imap[i].ilep->code = imap[i].idp->code;
    imap[i].ilep->address = 0;
    imap[i].ilep->return_length = &imap[i].ret_len;
  }
  *itemlist = il3;
  *itemmaps = imap;
  _map_alo_data(imap);	/* Allocate the map data areas */
  return(n_items);
}

/* mapAVto_itmlst converts a array into an itemlist-3 map and an
**   itemlist-3 partially constructed template.
**   An unsuccessful mapping leaves error codes set for exit to caller
**   and does NOT return allocated il3 or map data. Upon success, this
**   routine will return the number of items mapped and will allocate
**   and fill in the il3 & imap structures. These should later be
**   released by calling map_free().
**
**   Subsequent use of the mapping depends on the requirements of the
**   calling context... In general, since this is an AV, it will be an
**   *output* from an itmlst. HV's are used for *input* operations.
*/
static int
mapAVto_itmlst(
  ITMDEF   itemdefs[],
  ITMLST_3 **itemlist,
  ITMMAP   **itemmaps,
  AV *arry)
{
  int n_items,i,j;
  ITMLST_3 *il3;
  ITMMAP *imap;

  *itemlist = NULL;
  *itemmaps = NULL;

  n_items = 1+av_len(arry);	/* Get number of items in array */
  Newz(NULL, il3, n_items+1, ITMLST_3);
  Newz(NULL, imap, n_items+1, ITMMAP);
  for (i=0;i<n_items;i++) {
    char *memPtr;
    SV **memSVP;

    if (!(memSVP=av_fetch(arry,(I32)i,FALSE))) {
      Safefree(il3);
      Safefree(imap);
      SETERRNO(EVMSERR,SS$_BUGCHECK);
      return(-1); }

    memPtr = SvPVX(*memSVP);

    for (j=0;itemdefs[j].name;j++)
      if (strEQ(memPtr,itemdefs[j].name))
        break;

    if (!itemdefs[j].name) {
      Safefree(il3);
      Safefree(imap);
      SETERRNO(EVMSERR,SS$_BADPARAM);
      return(-1); }
    imap[i].sv = NULL; /* There IS no SV for these */
    imap[i].idp = &itemdefs[j];
    imap[i].ilep = &il3[i];
    imap[i].ilep->length = 0;
    imap[i].ilep->code = imap[i].idp->code;
    imap[i].ilep->address = 0;
    imap[i].ilep->return_length = &imap[i].ret_len;
  }
  *itemlist = il3;
  *itemmaps = imap;
  _map_alo_data(imap);	/* Allocate the map data areas */
  return(n_items);
}

static SV *
_map_bitvec_toAVref(
  ITMMAP *imap,
  int len)
{
  int i,j,k;
  AV *retAV;
  unsigned long int bitvec,mask;
  ITMDEF *itemdefs;

  itemdefs = (ITMDEF*)imap->idp->ptr1;
  switch (len) {
    case 1: bitvec = *(unsigned char *)imap->ilep->address; break;
    case 2: bitvec = *(unsigned short int *)imap->ilep->address; break;
    case 4: bitvec = *(unsigned long int *)imap->ilep->address; break;
    default: bitvec=0; break; }
  retAV = newAV();
  for (i=0,k=1,j=(len<<4);i<j && itemdefs[i].name;i++,k<<=1) {
    if (bitvec & ((unsigned long int)itemdefs[i].ptr1)) {
      av_push(retAV,newSVpv(itemdefs[i].name,strlen(itemdefs[i].name))); }
  }
  return(newRV_noinc((SV *) retAV));
}

static SV *
_map_enum_toSV(
  ITMMAP *imap,
  int len)
{
  int i,j,k;
  AV *retAV;
  unsigned long int enval,mask;
  ITMDEF *itemdefs;

  itemdefs = (ITMDEF*)imap->idp->ptr1;
  switch (len) {
    case 1: enval = *(unsigned char *)imap->ilep->address; break;
    case 2: enval = *(unsigned short int *)imap->ilep->address; break;
    case 4: enval = *(unsigned long int *)imap->ilep->address; break;
    default: enval=0; break; }
  for (i=0;itemdefs[i].name;i++)
    if (enval == ((unsigned long int)itemdefs[i].ptr1))
      return(newSVpv(itemdefs[i].name,strlen(itemdefs[i].name)));
  return(&PL_sv_undef);
}

static SV *
map_gen_retHVref(
  ITMMAP *imap)
{
  int i;
  HV *retHV;

  retHV = newHV();

  for (i = 0; imap && imap[i].ilep; i++) {
    switch (imap[i].idp->rettype) {
      case TYP_C_EN1:
        hv_store(retHV,imap[i].idp->name,
                    strlen(imap[i].idp->name),
                    _map_enum_toSV(&imap[i],1), 0);
        break;
      case TYP_C_EN2:
        hv_store(retHV,imap[i].idp->name,
                    strlen(imap[i].idp->name),
                    _map_enum_toSV(&imap[i],2), 0);
        break;
      case TYP_C_EN4:
        hv_store(retHV,imap[i].idp->name,
                    strlen(imap[i].idp->name),
                    _map_enum_toSV(&imap[i],4), 0);
        break;
      case TYP_C_BV1:
        hv_store(retHV,imap[i].idp->name,
                    strlen(imap[i].idp->name),
                    (SV*)_map_bitvec_toAVref(&imap[i],1), 0);
        break;
      case TYP_C_BV2:
        hv_store(retHV,imap[i].idp->name,
                    strlen(imap[i].idp->name),
                    (SV*)_map_bitvec_toAVref(&imap[i],2), 0);
        break;
      case TYP_C_BV4:
        hv_store(retHV,imap[i].idp->name,
                    strlen(imap[i].idp->name),
                    (SV*)_map_bitvec_toAVref(&imap[i],4), 0);
        break;
      case TYP_C_CTX:
        croak("contexts not allowed in output lists");
        break;
      case TYP_C_CBK:
      case TYP_C_CBP:
        croak("callback routines or parameters not allowed in output lists");
        break;
      case TYP_C_PRS:
        break;	/* Not a returned item as of yet - no mapping occurs */
      case TYP_C_STR:
        hv_store(retHV,imap[i].idp->name,
                    strlen(imap[i].idp->name),
                    newSVpv(imap[i].ilep->address,
                            imap[i].ret_len), 0);
        break;
      case TYP_C_VMD: {
        short int numbuf[7];
        char timetext[32];
        sys$numtim(numbuf,imap[i].ilep->address);
        sprintf(timetext, "%02hi-%3.3s-%hi %02hi:%02hi:%02hi.%hi",
                numbuf[2], &"JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC"
                           [3*(numbuf[1] - 1)],
                numbuf[0], numbuf[3], numbuf[4],
                numbuf[5], numbuf[6]);
        hv_store(retHV, imap[i].idp->name,
                 strlen(imap[i].idp->name),
                 newSVpv(timetext, 0), 0);
        break;
      case TYP_C_LNG: {
        long *pl;
        pl = imap[i].ilep->address;
        hv_store(retHV, imap[i].idp->name,
                 strlen(imap[i].idp->name),
                 newSViv(*pl),
                 0);
        break; }
      case TYP_C_WRD: {
        short *pl;
        pl = imap[i].ilep->address;
        hv_store(retHV, imap[i].idp->name,
                 strlen(imap[i].idp->name),
                 newSViv(*pl),
                 0);
        break; }
      }
    }
  }
  return(newRV_noinc((SV *) retHV));
}

static int
_mapAVto_bitvec_x(
  ITMMAP *imap,
  int len)
{
  int n_items,i,j;
  unsigned long int bitvec;
  AV *arry;
  ITMDEF *itemdefs;

  bitvec = 0;
  if (SvTYPE(SvRV(imap->sv)) != SVt_PVAV)
    croak("invalid bitmap array reference");
  arry = (AV*)SvRV(imap->sv);
  itemdefs = (ITMDEF*)imap->idp->ptr1;
  n_items = 1+av_len(arry);	/* Get number of items in array */
  for (i=0;i<n_items;i++) {
    char *memPtr;
    SV **memSVP;

    if (!(memSVP=av_fetch(arry,(I32)i,FALSE))) {
      SETERRNO(EVMSERR,SS$_BUGCHECK);
      return(-1); }

    memPtr = SvPVX(*memSVP);	/* Get the thing to look for */

    for (j=0;itemdefs[j].name;j++)
      if (strEQ(memPtr,itemdefs[j].name))
        break;

    if (!itemdefs[j].name) {
      SETERRNO(EVMSERR,SS$_BADPARAM);
      return(-1); }
    bitvec |= (unsigned long int)itemdefs[j].ptr1;
  }
  imap->ilep->length = len;
  switch (len) {
   case 1: *(unsigned char *)imap->ilep->address = bitvec; break;
   case 2: *(unsigned short int *)imap->ilep->address = bitvec; break;
   case 4: *(unsigned long int *)imap->ilep->address = bitvec; break;
   default:
     croak("bugcheck in bitvec mapping - invalid length");
  }
  return(1);
}

static int
_mapSVto_enum_x(
  ITMMAP *imap,
  int len)
{
  int n_items,i;
  unsigned long int enval;
  char *enumname;
  ITMDEF *itemdefs;

  enval = 0;
  enumname = SvPVX(imap->sv);	/* Get the thing to map */
  itemdefs = (ITMDEF*)imap->idp->ptr1;

  for (i=0;itemdefs[i].name;i++)
    if (strEQ(enumname,itemdefs[i].name))
      break;

  imap->ilep->length = len;
  if (itemdefs[i].name)
    enval = (unsigned long int)itemdefs[i].ptr1;
  switch (len) {
   case 1: *(unsigned char *)imap->ilep->address = enval; break;
   case 2: *(unsigned short int *)imap->ilep->address = enval; break;
   case 4: *(unsigned long int *)imap->ilep->address = enval; break;
   default:
     croak("bugcheck in enval mapping - invalid length");
  }
  return(1);
}

static int
_map_callback(
  ITMMAP *imap,
  ITMMAP *imap_par)
{
  CV *cv;
  SV *parm;
  SV *retSV;

  parm = imap->sv;
  imap->im_link = imap_par;
  imap->im_link->im_link = imap;
  cv = NULL;
  if (SvROK(parm)) {
    int svt;
    if ((svt=SvTYPE(SvRV(parm))) == SVt_PVCV) {
      cv = (CV*)SvRV(parm); }
    else
      croak("?Callback specification is NOT a reference to a CV\n"); }
  else {
    if (SvTYPE(parm) == SVt_PV) {
      cv = perl_get_cv(SvPVX(parm),FALSE);
      if (!cv)
        croak("Callback specification does not name a subroutine\n"); } }
  imap->sv = (SV*)cv;	/* Map the callable subroutine */
  imap->ilep->length = 4;
  imap->ilep->address = imap->idp->ptr1;	/* Map the C-level callback */
  imap->im_link->ilep->length = 4;
  imap->im_link->ilep->address = imap;
  return(1);		/* Ok value - sub mapped */
}

static void *
ret_MFCTX(
  SV *refctx)
{
  SV *ctx;
  MAILCTXDEF *mcdp;

  if (SvTYPE(SvRV(refctx)) != SVt_PVMG)
    croak("invalid mail context supplied");
  ctx = SvRV(refctx);
  mcdp = (MAILCTXDEF *) (IV) SvIV(ctx);
  return((void*)&mcdp->context);
}

static int
_map_context(
  ITMMAP *imap)
{
  SV *parm;
  MAILCTXDEF *mcdp;
  void *what;


  what = (*    (void*(*)())  imap->idp->ptr1)(imap->sv);
  if (what==NULL)
    croak("failed to convert supplied context to internal value");
  imap->ilep->length = 4;
  imap->ilep->address = what;
  return(1);		/* Ok value - sub mapped */
}

static void
map_copyin_SVdata(
  ITMMAP *imap)
{
  int i,j;
  unsigned long int ret;

  for (i=0;imap[i].ilep;i++) {
    char *p;
    unsigned int svLen;
  /*if (imap[i].idp->inout & IS_INPUT)*/
    switch (imap[i].idp->rettype) {
      case TYP_C_EN1:
        if (!_mapSVto_enum_x(&imap[i],1))
          croak("enum specification error");
        break;
      case TYP_C_EN2:
        if (!_mapSVto_enum_x(&imap[i],2))
          croak("enum specification error");
        break;
      case TYP_C_EN4:
        if (!_mapSVto_enum_x(&imap[i],4))
          croak("enum specification error");
        break;
      case TYP_C_BV1:
        if (!_mapAVto_bitvec_x(&imap[i],1))
          croak("bitvector specification error");
        break;
      case TYP_C_BV2:
        if (!_mapAVto_bitvec_x(&imap[i],2))
          croak("bitvector specification error");
        break;
      case TYP_C_BV4:
        if (!_mapAVto_bitvec_x(&imap[i],4))
          croak("bitvector specification error");
        break;
      case TYP_C_CTX:
        if (!_map_context(&imap[i]))
          croak("context specification error");
        break;
      case TYP_C_CBK:
        for (j=0;imap[j].ilep;j++)
          if (imap[j].idp->rettype == TYP_C_CBP)
            break;
        if (!imap[j].ilep)
          croak("callback must also supply user data parameter");
        if (!_map_callback(&imap[i],&imap[j]))
          croak("callback specification error");
        break;
      case TYP_C_CBP:
#if 0
  /* Callback parm's map nothing - done by CBK type only */
        if (i==0)
          croak("bug in input list construction in C module: bad CBK map");
        if (imap[i-1].sv) /* Then callback has been seen - can map */
          if (!_map_callback(&imap[i-1]))
            croak("callback specification error");
#endif
        break;
      case TYP_C_STR :
        p = SvPV(imap[i].sv, svLen );
        /* If there was something in the SV, then copy it over */
        if (svLen) {
          svLen = svLen < imap[i].idp->buflen ? svLen : imap[i].idp->buflen;
          Copy(p, imap[i].ilep->address, svLen, char);
          imap[i].ilep->length = svLen; }
        else
          imap[i].ilep->length = 0;
        break;
      case TYP_C_VMD: {
        struct dsc$descriptor_s d_time;

        /* Fill in the time string descriptor */
        p = SvPV(imap[i].sv, svLen );
        d_time.dsc$a_pointer = p;
        d_time.dsc$w_length = svLen;
        d_time.dsc$b_dtype = DSC$K_DTYPE_T;
        d_time.dsc$b_class = DSC$K_CLASS_S;

        /* Convert from an ascii rep to a VMS quadword date structure */
        ret = sys$bintim(&d_time, imap[i].ilep->address);
        if (~ret&1) {
            croak("Error converting time!"); }
        break;
        }
      case TYP_C_PRS:
        break;	/* Nothing is transferred.... mere presence is enough */
      case TYP_C_WRD:
        *(short int *)imap[i].ilep->address = SvIV(imap[i].sv);
        break;
      case TYP_C_LNG:
        *(long int *)imap[i].ilep->address = SvIV(imap[i].sv);
        break;
      default:
        croak("Unknown item type found!");
        break;
    }
  }
}

static void
map_free(
  ITMLST_3 *il3,
  ITMMAP   *imap)
{
  ITMMAP *imp;
  if (imap)
    for (imp=imap;imp->ilep;imp++)
      if(imp->idp->buflen)
        if(imp->ilep->address != NULL)
          Safefree(imp->ilep->address);
  if (il3)
    Safefree(il3);
  if (imap)
    Safefree(imap);
}

static SV *
_general_mail_xs(
  unsigned int (*mail_routine)(),	/* Call this routine */
  long int chk_flags,			/* Check THESE flags */
  long int proto_flags,			/* And they must be THIS prototype */
  ITMDEF *inItemDefs,			/* Input item list parsing template */
  ITMDEF *outItemDefs,			/* Output item list parsing template */
  SV *refctx,
  SV *inItemHash,
  SV *outItemArry)
{
  SV *rslt;
  SV *rsltrv;
  SV *ctx;
  MAILCTXDEF *mcdp;
  unsigned long int ret;
  ITMLST_3 *in_il3; ITMMAP *in_imap; int in_items;
  ITMLST_3 *out_il3; ITMMAP *out_imap; int out_items;
  SV *retHVref;

  if (!SvROK(refctx)) {
    printf("?Invalid reference for object's method call\n");
    SETERRNO(EVMSERR,SS$_BADPARAM);
    return(NULL); }

  ctx = SvRV(refctx);
  mcdp = (MAILCTXDEF *) (IV) SvIV(ctx);

  if (!mcdp->flags.v.initd) {	/* Always checked! */
    printf("?Context is not initialized\n");
    SETERRNO(EVMSERR,SS$_BADPARAM);
    return(NULL); }

  /* Check for type specified & unequal to what was passed */
  ret = chk_flags & MCTX_M_TYPES;
  if (ret && (ret & (mcdp->flags.m_flags^proto_flags))) {
    printf("?Context type flags are incorrect: %x %x %x\n",
           ret,mcdp->flags.m_flags,proto_flags);
    SETERRNO(EVMSERR,SS$_BADPARAM);
    return(NULL); }

  if (chk_flags & MCTX_M_CLOSED)
    if (~proto_flags & MCTX_M_CLOSED) {
      if (mcdp->flags.v.closed) {
        SETERRNO(EVMSERR,SS$_FILNOTACC);
        return(NULL); } }
    else
      if (!mcdp->flags.v.closed) {
        SETERRNO(EVMSERR,SS$_FILALRACC);
        return(NULL); }

  /* Now check for any remaining specified & unequal to what was passed */
  ret = chk_flags & ~(MCTX_M_INITD|MCTX_M_CLOSED|MCTX_M_MAILFILE|MCTX_M_MESSAGE|MCTX_M_SEND|MCTX_M_USER);
  if (ret && (ret & (mcdp->flags.m_flags^proto_flags))) {
    printf("?Context general flags are incorrect\n");
    SETERRNO(EVMSERR,SS$_BADPARAM);
    return(NULL); }

  /* Did we get an INPUT item list hash? */
  in_il3 = NULL;
  in_imap = NULL;
  if (inItemHash != &PL_sv_undef) {
    if (SvROK(inItemHash)) {
      if (SvTYPE(SvRV(inItemHash)) == SVt_PVHV) {
        in_items = mapHVto_itmlst(inItemDefs,
                                  &in_il3,&in_imap,
                                  (HV *)SvRV(inItemHash));
        if (in_items == -1) {
          printf("?Input itmlst mapping error\n");
          SETERRNO(EVMSERR,SS$_BUGCHECK);
          return(NULL); }
        map_copyin_SVdata(in_imap);
      } else {
        croak("Arg 2 should be a hash reference");
      }
    } else {
      croak("Arg 2 should be a hash reference");
    }
  }

  /* Did we get an OUTPUT item list hash? */
  out_il3 = NULL;
  out_imap = NULL;
  if (outItemArry != &PL_sv_undef) {
    if (SvROK(outItemArry)) {
      if (SvTYPE(SvRV(outItemArry)) == SVt_PVAV) {
        out_items = mapAVto_itmlst(outItemDefs,
                                   &out_il3,&out_imap,
                                   (AV *)SvRV(outItemArry));
        if (out_items == -1) {
          printf("?Output itmlst mapping error\n");
          SETERRNO(EVMSERR,SS$_BUGCHECK);
          map_free(in_il3,in_imap);
          return(NULL); }
      } else {
        croak("Arg 3 should be an array reference");
      }
    } else {
      croak("Arg 3 should be an array reference");
    }
  }

  ret=PROTECT(mail_routine,&mcdp->context,
              in_il3?in_il3:&null_itmlst[0],
              out_il3?out_il3:&null_itmlst[0]);
  map_free(in_il3,in_imap);
  if (~ret&1) {
    map_free(out_il3,out_imap);
    SETERRNO(EVMSERR,ret);
    return(NULL); }
  retHVref = map_gen_retHVref(out_imap);
  map_free(out_il3,out_imap);
  return(retHVref);
}

static unsigned long int
c_finfo_fldr_cbk(
  ITMMAP *icbk_map,
  struct dsc$descriptor_s *d_folder)
{
  SV *tmpSV;
  dSP;
  int n;
  unsigned long int retval;

  tmpSV = &PL_sv_undef;
  if (d_folder->dsc$w_length)
    tmpSV = newSVpv(d_folder->dsc$a_pointer,d_folder->dsc$w_length);
  ENTER;
  SAVETMPS;
  PUSHMARK(sp);
  XPUSHs(icbk_map->im_link->sv);
  XPUSHs(tmpSV);
  PUTBACK;
  n = perl_call_sv(icbk_map->sv,G_SCALAR);
  SPAGAIN;
  retval = SS$_BUGCHECK;	/* Return FAILURE by default! */
  if (n==1)
    retval = POPi;
  PUTBACK;
  FREETMPS;
  LEAVE;
  return(retval);
}

static unsigned long int
c_copy_msg_cbk(
  ITMMAP *icbk_map,
  struct dsc$descriptor_s *d_folder)
{
  SV *tmpSV;
  dSP;
  int n;
  unsigned long int retval;

  tmpSV = &PL_sv_undef;
  if (d_folder->dsc$w_length)
    tmpSV = newSVpv(d_folder->dsc$a_pointer,d_folder->dsc$w_length);
  ENTER;
  SAVETMPS;
  PUSHMARK(sp);
  XPUSHs(icbk_map->im_link->sv);
  XPUSHs(tmpSV);
  PUTBACK;
  n = perl_call_sv(icbk_map->sv,G_SCALAR);
  SPAGAIN;
  retval = SS$_BUGCHECK;	/* Return FAILURE by default! */
  if (n==1)
    retval = POPi;
  PUTBACK;
  FREETMPS;
  LEAVE;
  return(retval);
}

static unsigned long int
c_send_signals(
  ITMMAP *icbk_map,
  long *sigarr,		/* alpha 64 bits? */
  struct dsc$descriptor_s *d_recipient)
{
  SV *tmpSV;
  AV *tmpAV;
  SV *tmpAVrf;
  dSP;
  int i,n;
  unsigned long int retval;

  tmpSV = &PL_sv_undef;
  if (d_recipient->dsc$w_length)
    tmpSV = newSVpv(d_recipient->dsc$a_pointer,d_recipient->dsc$w_length);

  tmpAV = newAV();
  for (i=0;i<=sigarr[0];i++)
    av_push(tmpAV,newSViv(sigarr[i]));
  tmpAVrf = newRV_noinc((SV *) tmpAV);

  ENTER;
  SAVETMPS;
  PUSHMARK(sp);
  XPUSHs(icbk_map->im_link->sv);
  XPUSHs(tmpAVrf);
  XPUSHs(tmpSV);
  PUTBACK;
  n = perl_call_sv(icbk_map->sv,G_SCALAR);
  SPAGAIN;
  retval = SS$_BUGCHECK;	/* Return FAILURE by default! */
  if (n==1)
    retval = POPi;
  PUTBACK;
  FREETMPS;
  LEAVE;
  return(retval);
}

MODULE = VMS::Mail		PACKAGE = VMS::Mail		

PROTOTYPES: DISABLE

void
DESTROY(refctx)
  SV	*refctx
  CODE:
{
  SV *ctx;
  MAILCTXDEF *mcdp;

  if (SvROK(refctx)) {
    ctx = SvRV(refctx);
    mcdp = (MAILCTXDEF *) (IV) SvIV(ctx);
    if (mcdp->flags.v.initd)
      if (!mcdp->flags.v.closed)
        if (mcdp->flags.v.mailfile)
          mail$mailfile_end(&mcdp->context,&null_itmlst,&null_itmlst);
        else if (mcdp->flags.v.user)
          mail$user_end(&mcdp->context,&null_itmlst,&null_itmlst);
        else if (mcdp->flags.v.send)
          mail$send_end(&mcdp->context,&null_itmlst,&null_itmlst);
        else if (mcdp->flags.v.message)
          mail$message_end(&mcdp->context,&null_itmlst,&null_itmlst);
    memset(mcdp,'\xdd',sizeof(*mcdp));
    free(mcdp); }
}

void
new(class,...)
  SV *class
  CODE:
{
  SV *rslt;
  SV *rsltrv;
  HV *stash;
  int ival;
  unsigned int svalln;
  char *sval;
  MAILCTXDEF *mcdp;
  unsigned long int ret;

  /* Allocate a context for use */
  mcdp = malloc(sizeof(*mcdp));
  if (mcdp == NULL)
    croak("cannot allocate a context");
  memset(mcdp,'\0',sizeof(*mcdp));
  mcdp->flags.v.initd=1;
  mcdp->flags.v.closed=1;

  rslt = newSViv((int)mcdp);	/* Create context scalar */
  rsltrv = newRV_noinc(rslt);	/* Create reference to return */

  stash = gv_stashsv(class,0);
  sv_bless(rsltrv,stash);	/* Bless it into our package */
  ST(0) = sv_2mortal(rsltrv);
}

  /*----------------- Mailfile interface ---------------------------*/

SV *
end(refctx,inItemHash=&PL_sv_undef,outItemArry=&PL_sv_undef)
  SV *refctx
  SV *inItemHash
  SV *outItemArry
  CODE:
{
  SV *retHVref;
  SV *ctx;
  MAILCTXDEF *mcdp;
  unsigned int (*call_who)() = NULL;

  if (SvROK(refctx)) {
    ctx = SvRV(refctx);
    mcdp = (MAILCTXDEF *) (IV) SvIV(ctx);
    if (mcdp->flags.v.initd)
      if (!mcdp->flags.v.closed)
        if (mcdp->flags.v.mailfile)
          call_who = mail$mailfile_end;
        else if (mcdp->flags.v.user)
          call_who = mail$user_end;
        else if (mcdp->flags.v.send)
          call_who = mail$send_end;
        else if (mcdp->flags.v.message)
          call_who = mail$message_end; }

  if (call_who != NULL)
    retHVref = _general_mail_xs(
      call_who,				/* Target routine */
      0,				/* Check these flags */
      0,				/* To require these values */
      &null_itmdef[0],			/* Input item list parsing template */
      &null_itmdef[0],			/* Output item list parsing template */
      refctx,
      inItemHash,
      outItemArry);
  else
    retHVref = NULL;

  if (retHVref == NULL) {
    XSRETURN_UNDEF; }

  mcdp->flags.v.closed=1;
  mcdp->flags.v.mailfile=0;
  mcdp->flags.v.send=0;
  mcdp->flags.v.user=0;
  mcdp->flags.v.message=0;

  ST(0) = sv_2mortal(retHVref);
}

SV *
mailfile_begin(refctx,inItemHash=&PL_sv_undef,outItemArry=&PL_sv_undef)
  SV *refctx
  SV *inItemHash
  SV *outItemArry
  CODE:
{
DEF_ITEMS(o_itmdefs)
  I_CSTR("MAIL_DIRECTORY",MAIL$_MAILFILE_MAIL_DIRECTORY,255)
END_ITEMS

  SV *retHVref;
  MAILCTXDEF *mcdp;

  retHVref = _general_mail_xs(
    mail$mailfile_begin,		/* This routine */
    MCTX_M_CLOSED|			/* Check these flags */
         MCTX_M_TYPES,
    MCTX_M_CLOSED|			/* To require these values */
                    0,
    &null_itmdef[0],			/* Input item list parsing template */
    &o_itmdefs[0],			/* Output item list parsing template */
    refctx,
    inItemHash,
    outItemArry);

  if (retHVref == NULL) {
    XSRETURN_UNDEF; }

  mcdp = (MAILCTXDEF *) (IV) SvIV(SvRV(refctx));
  mcdp->flags.v.mailfile = 1;		/* Set context type */
  mcdp->flags.v.closed = 0;		/* Mark it 'open' */

  ST(0) = sv_2mortal(retHVref);
}

SV *
message_begin(refctx,inItemHash=&PL_sv_undef,outItemArry=&PL_sv_undef)
  SV *refctx
  SV *inItemHash
  SV *outItemArry
  CODE:
{
DEF_ITEMS(i_itmdefs)
  I_CTX("FILE_CTX",MAIL$_MESSAGE_FILE_CTX,ret_MFCTX)
END_ITEMS
DEF_ITEMS(o_itmdefs)
  I_LNG("SELECTED",MAIL$_MESSAGE_SELECTED)
END_ITEMS

  SV *retHVref;
  MAILCTXDEF *mcdp;

  retHVref = _general_mail_xs(
    mail$message_begin,		/* This routine */
    MCTX_M_CLOSED|			/* Check these flags */
         MCTX_M_TYPES,
    MCTX_M_CLOSED|			/* To require these values */
                    0,
    &i_itmdefs[0],			/* Input item list parsing template */
    &o_itmdefs[0],			/* Output item list parsing template */
    refctx,
    inItemHash,
    outItemArry);

  if (retHVref == NULL) {
    XSRETURN_UNDEF; }

  mcdp = (MAILCTXDEF *) (IV) SvIV(SvRV(refctx));
  mcdp->flags.v.message = 1;		/* Set context type */
  mcdp->flags.v.closed = 0;		/* Mark it 'open' */

  ST(0) = sv_2mortal(retHVref);
}

SV *
send_begin(refctx,inItemHash=&PL_sv_undef,outItemArry=&PL_sv_undef)
  SV *refctx
  SV *inItemHash
  SV *outItemArry
  CODE:
{
DEF_ITEMS(i_itms_w_no_home)
  I_PRS("NOOP",MAIL$_NOOP)	/* ??? */
  I_PRS("NOSIGNAL",MAIL$_NOSIGNAL)	/* ??? */
  I_PRS("FOREIGN",MAIL$_SEND_FOREIGN)	/* ??? */
END_ITEMS
DEF_ITEMS(i_itmdefs)
  I_CSTR("PERS_NAME",MAIL$_SEND_PERS_NAME,127)
  I_PRS("NO_PERS_NAME",MAIL$_SEND_NO_PERS_NAME)
#if defined(MAIL$_SEND_SIGFILE)
  I_CSTR("SIGFILE",MAIL$_SEND_SIGFILE,255)
  I_PRS("NO_SIGFILE",MAIL$_SEND_NO_SIGFILE)
#endif
  I_CSTR("DEFAULT_TRANSPORT",MAIL$_SEND_DEFAULT_TRANSPORT,255)	/* ???pv */
  I_PRS("NO_DEFAULT_TRANSPORT",MAIL$_SEND_NO_DEFAULT_TRANSPORT)	/* ???pv */
END_ITEMS
DEF_ITEMS(o_itmdefs)
  I_LNG("COPY_FORWARD",MAIL$_SEND_COPY_FORWARD)
  I_LNG("COPY_SEND",MAIL$_SEND_COPY_SEND)
  I_LNG("COPY_REPLY",MAIL$_SEND_COPY_REPLY)
  I_CSTR("SEND_USER",MAIL$_SEND_USER,255)
END_ITEMS

  SV *retHVref;
  MAILCTXDEF *mcdp;

  retHVref = _general_mail_xs(
    mail$send_begin,			/* This routine */
    MCTX_M_CLOSED|			/* Check these flags */
         MCTX_M_TYPES,
    MCTX_M_CLOSED|			/* To require these values */
                    0,
    &i_itmdefs[0],			/* Input item list parsing template */
    &o_itmdefs[0],			/* Output item list parsing template */
    refctx,
    inItemHash,
    outItemArry);

  if (retHVref == NULL) {
    XSRETURN_UNDEF; }

  mcdp = (MAILCTXDEF *) (IV) SvIV(SvRV(refctx));
  mcdp->flags.v.send = 1;		/* Set context type */
  mcdp->flags.v.closed = 0;		/* Mark it 'open' */

  ST(0) = sv_2mortal(retHVref);
}

SV *
user_begin(refctx,inItemHash=&PL_sv_undef,outItemArry=&PL_sv_undef)
  SV *refctx
  SV *inItemHash
  SV *outItemArry
  CODE:
{
DEF_ITEMS(o_itmdefs)
  I_LNG("AUTO_PURGE",MAIL$_USER_AUTO_PURGE)
  I_LNG("CAPTIVE",MAIL$_USER_CAPTIVE)
  I_LNG("CC_PROMPT",MAIL$_USER_CC_PROMPT)
  I_LNG("COPY_FORWARD",MAIL$_USER_COPY_FORWARD)
  I_LNG("COPY_REPLY",MAIL$_USER_COPY_REPLY)
  I_LNG("COPY_SEND",MAIL$_USER_COPY_SEND)
  I_CSTR("FORWARDING",MAIL$_USER_FORWARDING,255)
  I_CSTR("FORM",MAIL$_USER_FORM,255)
  I_CSTR("FULL_DIRECTORY",MAIL$_USER_FULL_DIRECTORY,255)
  I_WRD("NEW_MESSAGES",MAIL$_USER_NEW_MESSAGES)
  I_CSTR("PERSONAL_NAME",MAIL$_USER_PERSONAL_NAME,127)
  I_CSTR("QUEUE",MAIL$_USER_QUEUE,255)
  I_CSTR("RETURN_USERNAME",MAIL$_USER_RETURN_USERNAME,255)
#if defined(MAIL$_USER_SIGFILE)
  I_CSTR("SIGFILE",MAIL$_USER_SIGFILE,255)
#endif
  I_CSTR("RETURN_SUB_DIRECTORY",MAIL$_USER_SUB_DIRECTORY,255)
  I_CSTR("TRANSPORT",MAIL$_USER_TRANSPORT,255)	/* ???pv */
  I_CSTR("USER1",MAIL$_USER_USER1,255)	/* ???pv */
  I_CSTR("USER2",MAIL$_USER_USER2,255)	/* ???pv */
  I_CSTR("USER3",MAIL$_USER_USER3,255)	/* ???pv */
  I_CSTR("USER3",MAIL$_USER_USER3,255)	/* ???pv */
END_ITEMS

  SV *retHVref;
  MAILCTXDEF *mcdp;

  retHVref = _general_mail_xs(
    mail$user_begin,			/* This routine */
    MCTX_M_CLOSED|			/* Check these flags */
         MCTX_M_TYPES,
    MCTX_M_CLOSED|			/* To require these values */
                    0,
    &null_itmdef[0],			/* Input item list parsing template */
    &o_itmdefs[0],			/* Output item list parsing template */
    refctx,
    inItemHash,
    outItemArry);

  if (retHVref == NULL) {
    XSRETURN_UNDEF; }

  mcdp = (MAILCTXDEF *) (IV) SvIV(SvRV(refctx));
  mcdp->flags.v.user = 1;		/* Set context type */
  mcdp->flags.v.closed = 0;		/* Mark it 'open' */

  ST(0) = sv_2mortal(retHVref);
}

void
open(refctx,inItemHash=&PL_sv_undef,outItemArry=&PL_sv_undef)
  SV *refctx
  SV *inItemHash
  SV *outItemArry
  CODE:
{
DEF_ITEMS(i_itmdefs)
  I_CSTR("DEFAULT_NAME",MAIL$_MAILFILE_DEFAULT_NAME, 255)
  I_CSTR("NAME",MAIL$_MAILFILE_NAME, 255)
END_ITEMS
DEF_ITEMS(o_itmdefs)
  I_CSTR("WASTEBASKET",MAIL$_MAILFILE_WASTEBASKET,255)
  I_CSTR("RESULTSPEC",MAIL$_MAILFILE_RESULTSPEC,255)
END_ITEMS

  SV *retHVref;

  retHVref = _general_mail_xs(
    mail$mailfile_open,			/* This routine */
    MCTX_M_MAILFILE|MCTX_M_CLOSED,	/* Check these flags */
    MCTX_M_MAILFILE|0,			/* To require these values */
    &i_itmdefs[0],			/* Input item list parsing template */
    &o_itmdefs[0],			/* Output item list parsing template */
    refctx,
    inItemHash,
    outItemArry);

  if (retHVref == NULL) {
    XSRETURN_UNDEF; }

  ST(0) = sv_2mortal(retHVref);
}

void
close(refctx,inItemHash=&PL_sv_undef,outItemArry=&PL_sv_undef)
  SV *refctx
  SV *inItemHash
  SV *outItemArry
  CODE:
{
DEF_ITEMS(i_itmdefs)
  I_PRS("FULL_CLOSE",MAIL$_MAILFILE_FULL_CLOSE)
END_ITEMS
DEF_ITEMS(o_itmdefs)
  I_LNG("DATA_RECLAIM",MAIL$_MAILFILE_DATA_RECLAIM)
  I_LNG("DATA_SCAN",MAIL$_MAILFILE_DATA_SCAN)
  I_LNG("INDEX_RECLAIM",MAIL$_MAILFILE_INDEX_RECLAIM)
  I_LNG("TOTAL_RECLAIM",MAIL$_MAILFILE_TOTAL_RECLAIM)
  I_LNG("MESSAGES_DELETED",MAIL$_MAILFILE_MESSAGES_DELETED)
END_ITEMS
  SV *retHVref;

  retHVref = _general_mail_xs(
    mail$mailfile_close,		/* This routine */
    MCTX_M_MAILFILE|MCTX_M_CLOSED,	/* Check these flags */
    MCTX_M_MAILFILE|0,			/* To require these values */
    &i_itmdefs[0],			/* Input item list parsing template */
    &o_itmdefs[0],			/* Output item list parsing template */
    refctx,
    inItemHash,
    outItemArry);

  if (retHVref == NULL) {
    XSRETURN_UNDEF; }

  ST(0) = sv_2mortal(retHVref);
}

void
info_file(refctx,inItemHash=&PL_sv_undef,outItemArry=&PL_sv_undef)
  SV *refctx
  SV *inItemHash
  SV *outItemArry
  CODE:
{
DEF_ITEMS(i_itmdefs)
  I_CSTR("DEFAULT_NAME",MAIL$_MAILFILE_DEFAULT_NAME, 255)
  I_CSTR("NAME",MAIL$_MAILFILE_NAME, 255)
  I_CBK("FOLDER_ROUTINE", "USER_DATA",
        MAIL$_MAILFILE_FOLDER_ROUTINE,MAIL$_MAILFILE_USER_DATA,
        c_finfo_fldr_cbk)
END_ITEMS
DEF_ITEMS(o_itmdefs)
  I_LNG("DELETED_BYTES",MAIL$_MAILFILE_DELETED_BYTES)
  I_CSTR("WASTEBASKET",MAIL$_MAILFILE_WASTEBASKET,255)
  I_CSTR("RESULTSPEC",MAIL$_MAILFILE_RESULTSPEC,255)
END_ITEMS

  SV *retHVref;

  retHVref = _general_mail_xs(
    mail$mailfile_info_file,		/* This routine */
    MCTX_M_MAILFILE|MCTX_M_CLOSED,	/* Check these flags */
    MCTX_M_MAILFILE|0,			/* To require these values */
    &i_itmdefs[0],			/* Input item list parsing template */
    &o_itmdefs[0],			/* Output item list parsing template */
    refctx,
    inItemHash,
    outItemArry);

  if (retHVref == NULL) {
    XSRETURN_UNDEF; }

  ST(0) = sv_2mortal(retHVref);
}

void
compress(refctx,inItemHash=&PL_sv_undef,outItemArry=&PL_sv_undef)
  SV *refctx
  SV *inItemHash
  SV *outItemArry
  CODE:
{
DEF_ITEMS(i_itmdefs)
  I_PRS("FULL_CLOSE",MAIL$_MAILFILE_FULL_CLOSE)
  I_CSTR("DEFAULT_NAME",MAIL$_MAILFILE_DEFAULT_NAME, 255)
  I_CSTR("NAME",MAIL$_MAILFILE_NAME, 255)
END_ITEMS
DEF_ITEMS(o_itmdefs)
  I_CSTR("RESULTSPEC",MAIL$_MAILFILE_RESULTSPEC,255)
END_ITEMS

  SV *retHVref;

  retHVref = _general_mail_xs(
    mail$mailfile_compress,		/* This routine */
    MCTX_M_MAILFILE|MCTX_M_CLOSED,	/* Check these flags */
    MCTX_M_MAILFILE|0,			/* To require these values */
    &i_itmdefs[0],			/* Input item list parsing template */
    &o_itmdefs[0],			/* Output item list parsing template */
    refctx,
    inItemHash,
    outItemArry);

  if (retHVref == NULL) {
    XSRETURN_UNDEF; }

  ST(0) = sv_2mortal(retHVref);
}

void
purge_waste(refctx,inItemHash=&PL_sv_undef,outItemArry=&PL_sv_undef)
  SV *refctx
  SV *inItemHash
  SV *outItemArry
  CODE:
{
DEF_ITEMS(i_itmdefs)
  I_PRS("RECLAIM",MAIL$_MAILFILE_RECLAIM)
END_ITEMS
DEF_ITEMS(o_itmdefs)
  I_LNG("DATA_RECLAIM",MAIL$_MAILFILE_DATA_RECLAIM)
  I_LNG("DATA_SCAN",MAIL$_MAILFILE_DATA_SCAN)
  I_LNG("INDEX_RECLAIM",MAIL$_MAILFILE_INDEX_RECLAIM)
  I_LNG("DELETED_BYTES",MAIL$_MAILFILE_DELETED_BYTES)
  I_LNG("TOTAL_RECLAIM",MAIL$_MAILFILE_TOTAL_RECLAIM)
  I_LNG("MESSAGES_DELETED",MAIL$_MAILFILE_MESSAGES_DELETED)
END_ITEMS

  SV *retHVref;

  retHVref = _general_mail_xs(
    mail$mailfile_purge_waste,		/* This routine */
    MCTX_M_MAILFILE|MCTX_M_CLOSED,	/* Check these flags */
    MCTX_M_MAILFILE|0,			/* To require these values */
    &i_itmdefs[0],			/* Input item list parsing template */
    &o_itmdefs[0],			/* Output item list parsing template */
    refctx,
    inItemHash,
    outItemArry);

  if (retHVref == NULL) {
    XSRETURN_UNDEF; }

  ST(0) = sv_2mortal(retHVref);
}

void
modify(refctx,inItemHash=&PL_sv_undef,outItemArry=&PL_sv_undef)
  SV *refctx
  SV *inItemHash
  SV *outItemArry
  CODE:
{
  /* THIS IS A MUTLIPLE-TYPE ROUTINE! */
DEF_ITEMS(if_itmdefs)
  I_CSTR("DEFAULT_NAME",MAIL$_MAILFILE_DEFAULT_NAME, 255)
  I_CSTR("NAME",MAIL$_MAILFILE_NAME, 255)
  I_CSTR("WASTEBASKET_NAME",MAIL$_MAILFILE_WASTEBASKET_NAME, 39)
END_ITEMS
DEF_ITEMS(of_itmdefs)
  I_CSTR("RESULTSPEC",MAIL$_MAILFILE_RESULTSPEC,255)
END_ITEMS
DEF_ITEMS(im_itmdefs)
  I_LNG("BACK",MAIL$_MESSAGE_BACK)
  I_BV2("FLAGS",MAIL$_MESSAGE_FLAGS,&m_flags_bitvec)
  I_LNG("ID",MAIL$_MESSAGE_ID)
  I_LNG("NEXT",MAIL$_MESSAGE_NEXT)
  I_LNG("UFLAGS",MAIL$_MESSAGE_UFLAGS)	/* ???pv */
END_ITEMS
DEF_ITEMS(om_itmdefs)
  I_LNG("CURRENT_ID",MAIL$_MESSAGE_CURRENT_ID)
END_ITEMS

  SV *retHVref;
  SV *ctx;
  MAILCTXDEF *mcdp;

  if (!SvROK(refctx))
    croak("invalid reference in modify method");
  ctx = SvRV(refctx);
  mcdp = (MAILCTXDEF *) (IV) SvIV(ctx);
  if (!mcdp->flags.v.initd)
    croak("uninitialized context sent to modify method");
  if (mcdp->flags.v.mailfile)
  retHVref = _general_mail_xs(
    mail$mailfile_modify,		/* This routine */
    MCTX_M_MAILFILE|MCTX_M_CLOSED,	/* Check these flags */
    MCTX_M_MAILFILE|0,			/* To require these values */
    &if_itmdefs[0],			/* Input item list parsing template */
    &of_itmdefs[0],			/* Output item list parsing template */
    refctx,
    inItemHash,
    outItemArry);
  else if (mcdp->flags.v.message)
  retHVref = _general_mail_xs(
    mail$message_modify,		/* This routine */
    MCTX_M_MESSAGE|MCTX_M_CLOSED,	/* Check these flags */
    MCTX_M_MESSAGE|0,			/* To require these values */
    &im_itmdefs[0],			/* Input item list parsing template */
    &om_itmdefs[0],			/* Output item list parsing template */
    refctx,
    inItemHash,
    outItemArry);
  else
    croak("modify method not valid for this object type");

  if (retHVref == NULL) {
    XSRETURN_UNDEF; }

  ST(0) = sv_2mortal(retHVref);
}

void
info(refctx,inItemHash=&PL_sv_undef,outItemArry=&PL_sv_undef)
  SV *refctx
  SV *inItemHash
  SV *outItemArry
  CODE:
{
DEF_ITEMS(i_itmdefs)
  I_LNG("BACK",MAIL$_MESSAGE_BACK)
  I_LNG("ID",MAIL$_MESSAGE_ID)
  I_LNG("NEXT",MAIL$_MESSAGE_NEXT)
END_ITEMS
DEF_ITEMS(o_itmdefs)
  I_VMD("BINARY_DATE",MAIL$_MESSAGE_BINARY_DATE)
  I_CSTR("CC",MAIL$_MESSAGE_CC, 255)
  I_LNG("CURRENT_ID",MAIL$_MESSAGE_CURRENT_ID)
  I_CSTR("DATE",MAIL$_MESSAGE_DATE, 255)
  I_CSTR("EXTID",MAIL$_MESSAGE_EXTID, 255)
  I_CSTR("FROM",MAIL$_MESSAGE_FROM, 255)
  I_CSTR("REPLY_PATH",MAIL$_MESSAGE_REPLY_PATH, 255)
  I_BV2("RETURN_FLAGS",MAIL$_MESSAGE_RETURN_FLAGS,&m_flags_bitvec)
  I_CSTR("SENDER",MAIL$_MESSAGE_SENDER, 255)
  I_LNG("SIZE",MAIL$_MESSAGE_SIZE)
  I_CSTR("SUBJECT",MAIL$_MESSAGE_SUBJECT, 255)
  I_CSTR("TO",MAIL$_MESSAGE_TO, 255)
#if defined(MAIL$_MESSAGE_PARSE_QUOTES)
  I_LNG("PARSE_QUOTES",MAIL$_MESSAGE_PARSE_QUOTES)	/* ???pv */
#endif
  I_LNG("RETURN_UFLAGS",MAIL$_MESSAGE_RETURN_UFLAGS)	/* ???pv */
END_ITEMS

  SV *retHVref;

  retHVref = _general_mail_xs(
    mail$message_info,			/* This routine */
    MCTX_M_MESSAGE|MCTX_M_CLOSED,	/* Check these flags */
    MCTX_M_MESSAGE|0,			/* To require these values */
    &i_itmdefs[0],			/* Input item list parsing template */
    &o_itmdefs[0],			/* Output item list parsing template */
    refctx,
    inItemHash,
    outItemArry);

  if (retHVref == NULL) {
    XSRETURN_UNDEF; }

  ST(0) = sv_2mortal(retHVref);
}

void
get(refctx,inItemHash=&PL_sv_undef,outItemArry=&PL_sv_undef)
  SV *refctx
  SV *inItemHash
  SV *outItemArry
  CODE:
{
DEF_ITEMS(i_itmdefs)
  I_PRS("AUTO_NEWMAIL",MAIL$_MESSAGE_AUTO_NEWMAIL)
  I_LNG("BACK",MAIL$_MESSAGE_BACK)
  I_LNG("UFLAGS",MAIL$_MESSAGE_UFLAGS)	/* ??? */
  I_PRS("CONTINUE",MAIL$_MESSAGE_CONTINUE)
  I_LNG("ID",MAIL$_MESSAGE_ID)
  I_LNG("NEXT",MAIL$_MESSAGE_NEXT)
END_ITEMS
DEF_ITEMS(o_itmdefs)
  I_VMD("BINARY_DATE",MAIL$_MESSAGE_BINARY_DATE)
  I_CSTR("CC",MAIL$_MESSAGE_CC, 255)
  I_LNG("CURRENT_ID",MAIL$_MESSAGE_CURRENT_ID)
  I_CSTR("DATE",MAIL$_MESSAGE_DATE, 255)
  I_CSTR("EXTID",MAIL$_MESSAGE_EXTID, 255)
  I_CSTR("FROM",MAIL$_MESSAGE_FROM, 255)
  I_CSTR("RECORD",MAIL$_MESSAGE_RECORD, 255)
  I_EN2("RECORD_TYPE",MAIL$_MESSAGE_RECORD_TYPE,&c_msgret_type_enm)
  I_CSTR("REPLY_PATH",MAIL$_MESSAGE_REPLY_PATH, 255)
  I_BV2("RETURN_FLAGS",MAIL$_MESSAGE_RETURN_FLAGS,&m_flags_bitvec)
  I_LNG("RETURN_UFLAGS",MAIL$_MESSAGE_RETURN_UFLAGS)	/* ???pv */
  I_CSTR("SENDER",MAIL$_MESSAGE_SENDER, 255)
  I_LNG("SIZE",MAIL$_MESSAGE_SIZE)
  I_CSTR("SUBJECT",MAIL$_MESSAGE_SUBJECT, 255)
  I_CSTR("TO",MAIL$_MESSAGE_TO, 255)
#if defined(MAIL$_MESSAGE_PARSE_QUOTES)
  I_LNG("PARSE_QUOTES",MAIL$_MESSAGE_PARSE_QUOTES)	/* ???pv */
#endif
END_ITEMS

  SV *retHVref;

  retHVref = _general_mail_xs(
    mail$message_get,			/* This routine */
    MCTX_M_MESSAGE|MCTX_M_CLOSED,	/* Check these flags */
    MCTX_M_MESSAGE|0,			/* To require these values */
    &i_itmdefs[0],			/* Input item list parsing template */
    &o_itmdefs[0],			/* Output item list parsing template */
    refctx,
    inItemHash,
    outItemArry);

  if (retHVref == NULL) {
    XSRETURN_UNDEF; }

  ST(0) = sv_2mortal(retHVref);
}

void
select(refctx,inItemHash=&PL_sv_undef,outItemArry=&PL_sv_undef)
  SV *refctx
  SV *inItemHash
  SV *outItemArry
  CODE:
{
DEF_ITEMS(i_itmdefs)
  I_CSTR("BEFORE",MAIL$_MESSAGE_BEFORE,32)
  I_CSTR("CC_SUBSTRING",MAIL$_MESSAGE_CC_SUBSTRING, 255)
  I_BV2("FLAGS",MAIL$_MESSAGE_FLAGS,&m_flags_bitvec)
  I_BV2("FLAGS_MBZ",MAIL$_MESSAGE_FLAGS_MBZ,&m_flags_bitvec)
  I_CSTR("FOLDER",MAIL$_MESSAGE_FOLDER, 255)
  I_CSTR("FROM_SUBSTRING",MAIL$_MESSAGE_FROM_SUBSTRING, 255)
  I_CSTR("SINCE",MAIL$_MESSAGE_SINCE,32)
  I_CSTR("TO_SUBSTRING",MAIL$_MESSAGE_TO_SUBSTRING, 255)
  I_CSTR("SUBJ_SUBSTRING",MAIL$_MESSAGE_SUBJ_SUBSTRING, 255)
  I_LNG("UFLAGS",MAIL$_MESSAGE_UFLAGS)	/* ???pv */
END_ITEMS
DEF_ITEMS(o_itmdefs)
  I_LNG("SELECTED",MAIL$_MESSAGE_SELECTED)
END_ITEMS

  SV *retHVref;

  retHVref = _general_mail_xs(
    mail$message_select,		/* This routine */
    MCTX_M_MESSAGE|MCTX_M_CLOSED,	/* Check these flags */
    MCTX_M_MESSAGE|0,			/* To require these values */
    &i_itmdefs[0],			/* Input item list parsing template */
    &o_itmdefs[0],			/* Output item list parsing template */
    refctx,
    inItemHash,
    outItemArry);

  if (retHVref == NULL) {
    XSRETURN_UNDEF; }

  ST(0) = sv_2mortal(retHVref);
}

void
delete(refctx,inItemHash=&PL_sv_undef,outItemArry=&PL_sv_undef)
  SV *refctx
  SV *inItemHash
  SV *outItemArry
  CODE:
{
DEF_ITEMS(i_itmdefs)
  I_LNG("ID",MAIL$_MESSAGE_ID)
END_ITEMS

  SV *retHVref;

  retHVref = _general_mail_xs(
    mail$message_delete,		/* This routine */
    MCTX_M_MESSAGE|MCTX_M_CLOSED,	/* Check these flags */
    MCTX_M_MESSAGE|0,			/* To require these values */
    &i_itmdefs[0],			/* Input item list parsing template */
    &null_itmdef[0],			/* Output item list parsing template */
    refctx,
    inItemHash,
    outItemArry);

  if (retHVref == NULL) {
    XSRETURN_UNDEF; }

  ST(0) = sv_2mortal(retHVref);
}

void
copy(refctx,inItemHash=&PL_sv_undef,outItemArry=&PL_sv_undef)
  SV *refctx
  SV *inItemHash
  SV *outItemArry
  CODE:
{
DEF_ITEMS(i_itmdefs)
  I_PRS("BACK",MAIL$_MESSAGE_BACK)
  I_CSTR("DEFAULT_NAME",MAIL$_MESSAGE_DEFAULT_NAME, 255)
  I_PRS("DELETE",MAIL$_MESSAGE_DELETE)
  I_PRS("ERASE",MAIL$_MESSAGE_ERASE) /* ??? */
  I_CBK("FILE_ACTION", "USER_DATA",
        MAIL$_MESSAGE_FILE_ACTION,MAIL$_MESSAGE_USER_DATA,
        c_copy_msg_cbk)
  I_CSTR("FILENAME",MAIL$_MESSAGE_FILENAME, 255)
  I_CSTR("FOLDER",MAIL$_MESSAGE_FOLDER, 255)
  I_CBK("FOLDER_ACTION", "USER_DATA",  /* This second occurrence is bogus! */
        MAIL$_MESSAGE_FOLDER_ACTION,MAIL$_MESSAGE_USER_DATA,
        c_copy_msg_cbk)
  I_LNG("ID",MAIL$_MESSAGE_ID)
  I_PRS("NEXT",MAIL$_MESSAGE_NEXT)
END_ITEMS
DEF_ITEMS(o_itmdefs)
  I_LNG("FILE_CREATED",MAIL$_MESSAGE_FILE_CREATED)
  I_LNG("FOLDER_CREATED",MAIL$_MESSAGE_FOLDER_CREATED)
  I_LNG("RESULTSPEC",MAIL$_MESSAGE_RESULTSPEC)
END_ITEMS

  SV *retHVref;

  retHVref = _general_mail_xs(
    mail$message_copy,			/* This routine */
    MCTX_M_MESSAGE|MCTX_M_CLOSED,	/* Check these flags */
    MCTX_M_MESSAGE|0,			/* To require these values */
    &i_itmdefs[0],			/* Input item list parsing template */
    &o_itmdefs[0],			/* Output item list parsing template */
    refctx,
    inItemHash,
    outItemArry);

  if (retHVref == NULL) {
    XSRETURN_UNDEF; }

  ST(0) = sv_2mortal(retHVref);
}

void
abort(refctx,inItemHash=&PL_sv_undef,outItemArry=&PL_sv_undef)
  SV *refctx
  SV *inItemHash
  SV *outItemArry
  CODE:
{
  SV *retHVref;

  retHVref = _general_mail_xs(
    mail$send_abort,			/* This routine */
    MCTX_M_SEND|MCTX_M_CLOSED,		/* Check these flags */
    MCTX_M_SEND|0,			/* To require these values */
    &null_itmdef[0],			/* Input item list parsing template */
    &null_itmdef[0],			/* Output item list parsing template */
    refctx,
    inItemHash,
    outItemArry);

  if (retHVref == NULL) {
    XSRETURN_UNDEF; }

  ST(0) = sv_2mortal(retHVref);
}


void
add_address(refctx,inItemHash=&PL_sv_undef,outItemArry=&PL_sv_undef)
  SV *refctx
  SV *inItemHash
  SV *outItemArry
  CODE:
{
DEF_ITEMS(i_itmdefs)
  I_CSTR("USERNAME",MAIL$_SEND_USERNAME, 255)
  I_EN2("USERNAME_TYPE",MAIL$_SEND_USERNAME_TYPE, &c_username_type_enm)
#if defined(MAIL$_SEND_PARSE_QUOTES)
  I_PRS("PARSE_QUOTES",MAIL$_SEND_PARSE_QUOTES)	/* ???pv */
#endif
END_ITEMS
  SV *retHVref;

  retHVref = _general_mail_xs(
    mail$send_add_address,		/* This routine */
    MCTX_M_SEND|MCTX_M_CLOSED,	/* Check these flags */
    MCTX_M_SEND|0,			/* To require these values */
    &i_itmdefs[0],			/* Input item list parsing template */
    &null_itmdef[0],			/* Output item list parsing template */
    refctx,
    inItemHash,
    outItemArry);

  if (retHVref == NULL) {
    XSRETURN_UNDEF; }

  ST(0) = sv_2mortal(retHVref);
}

void
add_attribute(refctx,inItemHash=&PL_sv_undef,outItemArry=&PL_sv_undef)
  SV *refctx
  SV *inItemHash
  SV *outItemArry
  CODE:
{
DEF_ITEMS(i_itmdefs)
  I_CSTR("CC_LINE",MAIL$_SEND_CC_LINE, 255)
  I_CSTR("FROM_LINE",MAIL$_SEND_FROM_LINE, 255)
  I_CSTR("SUBJECT",MAIL$_SEND_SUBJECT, 255)
  I_CSTR("TO_LINE",MAIL$_SEND_TO_LINE, 255)
  I_LNG("UFLAGS",MAIL$_SEND_UFLAGS)	/* ???pv (something to do w/Dnet Phs) */
END_ITEMS
  SV *retHVref;

  retHVref = _general_mail_xs(
    mail$send_add_attribute,		/* This routine */
    MCTX_M_SEND|MCTX_M_CLOSED,	/* Check these flags */
    MCTX_M_SEND|0,			/* To require these values */
    &i_itmdefs[0],			/* Input item list parsing template */
    &null_itmdef[0],			/* Output item list parsing template */
    refctx,
    inItemHash,
    outItemArry);

  if (retHVref == NULL) {
    XSRETURN_UNDEF; }

  ST(0) = sv_2mortal(retHVref);
}

void
add_bodypart(refctx,inItemHash=&PL_sv_undef,outItemArry=&PL_sv_undef)
  SV *refctx
  SV *inItemHash
  SV *outItemArry
  CODE:
{
DEF_ITEMS(i_itmdefs)
  I_CSTR("DEFAULT_NAME",MAIL$_SEND_DEFAULT_NAME, 255)
  /*I_CSTR("FID",MAIL$_SEND_FID, 255)*/
  I_CSTR("FILENAME",MAIL$_SEND_FILENAME, 255)
  I_CSTR("RECORD",MAIL$_SEND_RECORD, 255)
END_ITEMS
DEF_ITEMS(o_itmdefs)
  I_CSTR("SEND_RESULTSPEC",MAIL$_SEND_RESULTSPEC, 255)
END_ITEMS
  SV *retHVref;

  retHVref = _general_mail_xs(
    mail$send_add_bodypart,		/* This routine */
    MCTX_M_SEND|MCTX_M_CLOSED,	/* Check these flags */
    MCTX_M_SEND|0,			/* To require these values */
    &i_itmdefs[0],			/* Input item list parsing template */
    &o_itmdefs[0],			/* Output item list parsing template */
    refctx,
    inItemHash,
    outItemArry);

  if (retHVref == NULL) {
    XSRETURN_UNDEF; }

  ST(0) = sv_2mortal(retHVref);
}

void
message(refctx,inItemHash=&PL_sv_undef,outItemArry=&PL_sv_undef)
  SV *refctx
  SV *inItemHash
  SV *outItemArry
  CODE:
{
DEF_ITEMS(i_itmdefs)
  I_CBK("ERROR_ENTRY", "USER_DATA",
        MAIL$_SEND_ERROR_ENTRY,MAIL$_SEND_USER_DATA,
        c_send_signals)
  I_CBK("SUCCESS_ENTRY", "USER_DATA",
        MAIL$_SEND_ERROR_ENTRY,MAIL$_SEND_USER_DATA,
        c_send_signals)
END_ITEMS
  SV *retHVref;

  retHVref = _general_mail_xs(
    mail$send_message,		/* This routine */
    MCTX_M_SEND|MCTX_M_CLOSED,	/* Check these flags */
    MCTX_M_SEND|0,			/* To require these values */
    &i_itmdefs[0],			/* Input item list parsing template */
    &null_itmdef[0],			/* Output item list parsing template */
    refctx,
    inItemHash,
    outItemArry);

  if (retHVref == NULL) {
    XSRETURN_UNDEF; }

  ST(0) = sv_2mortal(retHVref);
}

void
delete_info(refctx,inItemHash=&PL_sv_undef,outItemArry=&PL_sv_undef)
  SV *refctx
  SV *inItemHash
  SV *outItemArry
  CODE:
{
DEF_ITEMS(i_itmdefs)
  I_CSTR("USERNAME",MAIL$_USER_USERNAME,31)
END_ITEMS
  SV *retHVref;

  retHVref = _general_mail_xs(
    mail$user_delete_info,		/* This routine */
    MCTX_M_USER|MCTX_M_CLOSED,	/* Check these flags */
    MCTX_M_USER|0,			/* To require these values */
    &i_itmdefs[0],			/* Input item list parsing template */
    &null_itmdef[0],			/* Output item list parsing template */
    refctx,
    inItemHash,
    outItemArry);

  if (retHVref == NULL) {
    XSRETURN_UNDEF; }

  ST(0) = sv_2mortal(retHVref);
}

void
set_info(refctx,inItemHash=&PL_sv_undef,outItemArry=&PL_sv_undef)
  SV *refctx
  SV *inItemHash
  SV *outItemArry
  CODE:
{
DEF_ITEMS(i_itmdefs)
  I_PRS("CREATE_IF",MAIL$_USER_CREATE_IF)
  I_PRS("SET_AUTO_PURGE",MAIL$_USER_SET_AUTO_PURGE)
  I_PRS("SET_NO_AUTO_PURGE",MAIL$_USER_SET_NO_AUTO_PURGE)
  I_PRS("SET_CC_PROMPT",MAIL$_USER_SET_CC_PROMPT)
  I_PRS("SET_NO_CC_PROMPT",MAIL$_USER_SET_NO_CC_PROMPT)
  I_PRS("SET_COPY_FORWARD",MAIL$_USER_SET_COPY_FORWARD)
  I_PRS("SET_NO_COPY_FORWARD",MAIL$_USER_SET_NO_COPY_FORWARD)
  I_PRS("SET_COPY_REPLY",MAIL$_USER_SET_COPY_REPLY)
  I_PRS("SET_NO_COPY_REPLY",MAIL$_USER_SET_NO_COPY_REPLY)
  I_PRS("SET_COPY_SEND",MAIL$_USER_SET_COPY_SEND)
  I_PRS("SET_NO_COPY_SEND",MAIL$_USER_SET_NO_COPY_SEND)
  I_CSTR("SET_EDITOR",MAIL$_USER_SET_EDITOR,255)
  I_PRS("SET_NO_EDITOR",MAIL$_USER_SET_NO_EDITOR)
  I_CSTR("SET_FORM",MAIL$_USER_SET_FORM,255)
  I_PRS("SET_NO_FORM",MAIL$_USER_SET_NO_FORM)
  I_CSTR("SET_FORWARDING",MAIL$_USER_SET_FORWARDING,255)
  I_PRS("SET_NO_FORWARDING",MAIL$_USER_SET_NO_FORWARDING)
  I_WRD("SET_NEW_MESSAGES",MAIL$_USER_SET_NEW_MESSAGES)
  I_CSTR("SET_QUEUE",MAIL$_USER_SET_QUEUE,255)
  I_PRS("SET_NO_QUEUE",MAIL$_USER_SET_NO_QUEUE)
#if defined(MAIL$_USER_SET_SIGFILE)
  I_CSTR("SET_SIGFILE",MAIL$_USER_SET_SIGFILE,255)
  I_PRS("SET_NO_SIGFILE",MAIL$_USER_SET_NO_SIGFILE)
#endif
  I_CSTR("SET_SUB_DIRECTORY",MAIL$_USER_SET_SUB_DIRECTORY,255)
  I_PRS("SET_NO_SUB_DIRECTORY",MAIL$_USER_SET_NO_SUB_DIRECTORY)
  I_CSTR("SET_PERSONAL_NAME",MAIL$_USER_SET_PERSONAL_NAME,127)
  I_PRS("SET_NO_PERSONAL_NAME",MAIL$_USER_SET_NO_PERSONAL_NAME)
  I_CSTR("USERNAME",MAIL$_USER_USERNAME,31)
  I_CSTR("SET_USER1",MAIL$_USER_SET_USER1,255)	/* ???pv */
  I_PRS("SET_NO_USER1",MAIL$_USER_SET_NO_USER1)	/* ???pv */
  I_CSTR("SET_USER2",MAIL$_USER_SET_USER2,255)	/* ???pv */
  I_PRS("SET_NO_USER2",MAIL$_USER_SET_NO_USER2)	/* ???pv */
  I_CSTR("SET_USER3",MAIL$_USER_SET_USER3,255)	/* ???pv */
  I_PRS("SET_NO_USER3",MAIL$_USER_SET_NO_USER3)	/* ???pv */
  I_CSTR("SET_TRANSPORT",MAIL$_USER_SET_TRANSPORT,255)	/* ???pv */
  I_PRS("SET_NO_TRANSPORT",MAIL$_USER_SET_NO_TRANSPORT)	/* ???pv */
END_ITEMS
  SV *retHVref;

  retHVref = _general_mail_xs(
    mail$user_set_info,		/* This routine */
    MCTX_M_USER|MCTX_M_CLOSED,	/* Check these flags */
    MCTX_M_USER|0,			/* To require these values */
    &i_itmdefs[0],			/* Input item list parsing template */
    &null_itmdef[0],			/* Output item list parsing template */
    refctx,
    inItemHash,
    outItemArry);

  if (retHVref == NULL) {
    XSRETURN_UNDEF; }

  ST(0) = sv_2mortal(retHVref);
}


void
get_info(refctx,inItemHash=&PL_sv_undef,outItemArry=&PL_sv_undef)
  SV *refctx
  SV *inItemHash
  SV *outItemArry
  CODE:
{
DEF_ITEMS(i_itmdefs)
  I_PRS("FIRST",MAIL$_USER_FIRST)
  I_PRS("NEXT",MAIL$_USER_NEXT)
  I_CSTR("USERNAME",MAIL$_USER_USERNAME,31)
END_ITEMS
DEF_ITEMS(o_itmdefs)
  I_LNG("AUTO_PURGE",MAIL$_USER_AUTO_PURGE)
  I_LNG("CC_PROMPT",MAIL$_USER_CC_PROMPT)
  I_LNG("COPY_FORWARD",MAIL$_USER_COPY_FORWARD)
  I_LNG("COPY_REPLY",MAIL$_USER_COPY_REPLY)
  I_LNG("COPY_SEND",MAIL$_USER_COPY_SEND)
  I_CSTR("EDITOR",MAIL$_USER_EDITOR,255)
  I_CSTR("FORM",MAIL$_USER_EDITOR,255)
  I_CSTR("FORWARDING",MAIL$_USER_FORWARDING,255)
  I_CSTR("FULL_DIRECTORY",MAIL$_USER_FULL_DIRECTORY,255)
  I_CSTR("PERSONAL_NAME",MAIL$_USER_PERSONAL_NAME,127)
  I_CSTR("QUEUE",MAIL$_USER_QUEUE,255)
  I_CSTR("RETURN_USERNAME",MAIL$_USER_RETURN_USERNAME,255)
#if defined(MAIL$_USER_SIGFILE)
  I_CSTR("SIGFILE",MAIL$_USER_SIGFILE,255)
#endif
  I_CSTR("SUB_DIRECTORY",MAIL$_USER_SUB_DIRECTORY,255)
  I_WRD("NEW_MESSAGES",MAIL$_USER_NEW_MESSAGES)
  I_CSTR("TRANSPORT",MAIL$_USER_TRANSPORT,255)	/* ???pv */
  I_CSTR("USER1",MAIL$_USER_USER1,255)	/* ???pv */
  I_CSTR("USER2",MAIL$_USER_USER2,255)	/* ???pv */
  I_CSTR("USER3",MAIL$_USER_USER3,255)	/* ???pv */
  I_CSTR("USER3",MAIL$_USER_USER3,255)	/* ???pv */
END_ITEMS
  SV *retHVref;

  retHVref = _general_mail_xs(
    mail$user_get_info,			/* This routine */
    MCTX_M_USER|MCTX_M_CLOSED,		/* Check these flags */
    MCTX_M_USER|0,			/* To require these values */
    &i_itmdefs[0],			/* Input item list parsing template */
    &o_itmdefs[0],			/* Output item list parsing template */
    refctx,
    inItemHash,
    outItemArry);

  if (retHVref == NULL) {
    XSRETURN_UNDEF; }

  ST(0) = sv_2mortal(retHVref);
}

void
smg_read(prompt,keydef_fnm=&PL_sv_undef,keydef_dnm=&PL_sv_undef)
  SV *prompt
  SV *keydef_fnm
  SV *keydef_dnm
  CODE:
{
  static unsigned long int kbd_id=0;
  static unsigned long int ktb_id=0;
  static unsigned long int ldkl=0;

  unsigned long int ret,ret2;
  unsigned short int termid;
  SV *retstr;
  struct dsc$descriptor_s d_resul={0,0,0,0};
  struct dsc$descriptor_s d_prompt={0,0,0,0};
  char promptbuf[512];

  /* Establish the connection to smg... */
  if (!kbd_id) {
    $DESCRIPTOR(d_sysin,"SYS$INPUT");
    char *kfnm = "PERL_VMS_MAIL_KEYDEFS";
    char *kdnm = "SYS$LOGIN:.DAT";
    struct dsc$descriptor_s d_kfnm = { 0,0,0,0 };
    struct dsc$descriptor_s d_kdnm = { 0,0,0,0 };
    unsigned int svLen;

    if (keydef_fnm != &PL_sv_undef)
      kfnm = SvPV(keydef_fnm,svLen);
    if (keydef_dnm != &PL_sv_undef)
      kdnm = SvPV(keydef_dnm,svLen);
    d_kfnm.dsc$w_length = strlen(
    d_kfnm.dsc$a_pointer = kfnm);
    d_kdnm.dsc$w_length = strlen(
    d_kdnm.dsc$a_pointer = kdnm);

    if (~(ret=smg$create_virtual_keyboard(&kbd_id,&d_sysin))&1) {
      SETERRNO(EVMSERR,ret);
      XSRETURN_UNDEF; }
#if 0
    if (~(ret=smg$create_virtual_keyboard(&kbdx_id,&d_sysin))&1) {
      SETERRNO(EVMSERR,ret);
      XSRETURN_UNDEF; }
#endif
    if (~(ret=smg$create_key_table(&ktb_id))&1) {
      SETERRNO(EVMSERR,ret);
      XSRETURN_UNDEF; }
    ret2=smg$load_key_defs(&ktb_id,&d_kfnm,&d_kdnm,&ldkl); }

  d_prompt.dsc$w_length = strlen(
  d_prompt.dsc$a_pointer = SvPVX(prompt));
  d_resul.dsc$w_length = sizeof(promptbuf)-1;
  d_resul.dsc$a_pointer = promptbuf;
  ret = smg$read_composed_line(&kbd_id, &ktb_id,
                                     &d_resul,
                                     &d_prompt,
                                     &d_resul,
                                     0,		/* disp id */
                                     0,		/* flags */
                                     0,		/* initial string */
                                     0,		/* timeout */
                                     0,		/* rendition set */
                                     0,		/* rendition complement */
                                     &termid);
#if 0
      else {
        tmplength = d_resul->dsc$w_length-1;
        modifiers = TRM$M_TM_NOECHO|TRM$M_TM_NORECALL|TRM$M_TM_PURGE;
        ret = smg$read_string(&kbdx_id,
                                     d_resul,
                                     d_prompt,
                                     &tmplength,   /* max len */
                                     &modifiers,
                                     0, /* tmo */
                                     0, /* terminator-set */
                                     d_resul,
                                     &termid);
        { unsigned long int a[2] = { 2,(unsigned long int)"\r\n" };
        /* do NOT use lib_put_output here - something is wonky with it */
        write((struct dsc$descriptor_s *)a); } }
#endif
  if (ret == SMG$_EOF) {
    SETERRNO(EVMSERR,SS$_ENDOFFILE);
    XSRETURN_UNDEF; }
  if (ret == RMS$_EOF) {
    SETERRNO(EVMSERR,SS$_ENDOFFILE);
    XSRETURN_UNDEF; }
  if (~ret&1) {
    SETERRNO(EVMSERR,ret);
    XSRETURN_UNDEF; }

  /* if caller wants an array, we should return ("string","terminator") */
  retstr = newSVpv(d_resul.dsc$a_pointer,d_resul.dsc$w_length);
  ST(0) = sv_2mortal(retstr);
}
