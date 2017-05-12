/* VMS:Priv - Get and Set VMS Process privilidges
 *
 * Version: 1.1
 * Author:  Dan Sugalski <sugalsd@lbcc.cc.or.us>, with modifications
 *          by Charles Bailey <bailey@genetics.upenn.edu>
 * Revised: 08-July-1997
 *
 *
 * Revision History:
 *
 * 1.0  08-July-1997 Dan Sugalski <sugalsd@lbcc.cc.or.us>
 *      Original version created
 *
 * 1.1  11-Jul-1997 Charles Bailey <bailey@genetics.upenn.edu>
 *      Switched to hash ref and compressed code
 *      Removed dummy pid arg from set routines, and added prmflag
 *
 * 1.2  18-July-1997 Dan Sugalski <sugalsd@lbcc.cc.or.us>
 *      Applied some patches provided by Charles Bailey. We now have
 *      get_image_privs in there.
 */

#ifdef __cplusplus
extern "C" {
#endif
#include <starlet.h>
#include <descrip.h>
#include <prvdef.h>
#include <jpidef.h>
#include <uaidef.h>
#include <ssdef.h>
#include <stsdef.h>
  
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

typedef struct {short   buflen,          /* Length of output buffer */
                        itmcode;         /* Item code */
                void    *buffer;         /* Buffer address */
                void    *retlen;         /* Return length address */
                } ITMLST;  /* Layout of item-list elements */


/* Macro to fill in an item list entry */
#define init_itemlist(ile, length, code, bufaddr, retlen_addr) \
{ \
    (ile)->buflen = (length); \
    (ile)->itmcode = (code); \
    (ile)->buffer = (bufaddr); \
    (ile)->retlen = (retlen_addr) ;}


/* Order here must, of course, match the order of bits in a privilege
 * vector, from least significant to most significant. */
#define MAX_PRV_ALIASES 2
char *Prvnames[][MAX_PRV_ALIASES+1] =
  { { "CMKRNL", ""},    { "CMEXEC", ""},   { "SYSNAM", ""},   { "GRPNAM", ""},
#if __VMS_VER >= 70100000
    { "ALLSPOOL", ""},  { "DETACH", "IMPERSONATE"},   { "DIAGNOSE", ""}, { "LOG_IO", ""},
    { "GROUP", ""},     { "ACNT", "NOACNT", ""},              { "PRMCEB", ""}, 
    { "PRMMBX", ""},    { "PSWAPM", ""},   { "ALTPRI", "SETPRI", ""}, 
#else
    { "ALLSPOOL", ""},  { "DETACH", ""},   { "DIAGNOSE", ""}, { "LOG_IO", ""},
    { "GROUP", ""},     { "NOACNT", "ACNT", ""},              { "PRMCEB", ""}, 
    { "PRMMBX", ""},    { "PSWAPM", ""},   { "SETPRI", "ALTPRI", ""}, 
#endif
    { "SETPRV", ""},    { "TMPMBX", ""},   { "WORLD", ""},    { "MOUNT", ""},
    { "OPER", ""},      { "EXQUOTA", ""},  { "NETMBX", ""},   { "VOLPRO", ""},
    { "PHY_IO", ""},    { "BUGCHK", ""},   { "PRMGBL", ""},   { "SYSGBL", ""},
    { "PFNMAP", ""},    { "SHMEM", ""},    { "SYSPRV", ""},   { "BYPASS", ""},
    { "SYSLCK", ""},    { "SHARE", ""},    { "UPGRADE", ""},
    { "DOWNGRADE", ""}, { "GRPPRV", ""},   { "READALL", ""},  { "IMPORT", ""},
    { "AUDIT", ""},     { "SECURITY", ""}
  };

static SV *prvdef_to_hvref(union prvdef *prvstruct) {
  unsigned long int i, *mask;
  HV *prvhv = newHV();

  /* Priv mask is a quadword bit mask; we're just changing our view */
  mask = (unsigned long int *) prvstruct;
  for (i = 0; i < PRV$K_NUMBER_OF_PRIVS; i++) {
     if ( mask[i / (8 * sizeof(unsigned long int))] & /* bitwise & */
          (1 << (i % (8 * sizeof(unsigned long int)))))
       hv_store(prvhv, Prvnames[i][0], strlen(Prvnames[i][0]),&PL_sv_yes,0);
  }

  return newRV_noinc((SV *) prvhv);
}

static union prvdef *set_bit_by_name(union prvdef *prvstruct, char *name) {
  unsigned long int i, j, *mask;
  char upname[12];

  for (i = 0; i < sizeof upname / sizeof(char); i++) {
     if (name[i] == '\0') break;
     upname[i] = _toupper(name[i]);
  }
  upname[i] = '\0';

  /* Priv mask is a quadword bit mask; we're just changing our view */
  mask = (unsigned long int *) prvstruct;
  for (i = 0; i < PRV$K_NUMBER_OF_PRIVS; i++) {
    for (j = 0; j <= MAX_PRV_ALIASES; j++) {
      if (Prvnames[i][j][0] == '\0') break;       /* Out of aliases */
      if (Prvnames[i][j][0] != upname[0]) break;  /* Can't match    */
      if (strEQ(Prvnames[i][j],upname)) {
        mask[i / (8 * sizeof(unsigned long int))] |=
          1 << (i % (8 * sizeof(unsigned long int)));
        return prvstruct;
      }
    }
  }

  warn("Bad privilege name seen in VMS::Priv: \"%s\"",name);
  return prvstruct;
}
      
static SV *check_privs(Pid_t pid, short code) {

  union prvdef myprvs;
  unsigned short prvlen;
  int status;
  ITMLST jpilist[2];
  
  /* Clear out the itemlist array. */
  Zero(jpilist,2,ITMLST);  

  /* Fill in the item list. We want the current privs */
  init_itemlist(&jpilist[0],sizeof(myprvs),code,&myprvs,&prvlen);

  /* Make the call. We're blocking until we get it */
  status = sys$getjpiw(NULL,&pid,NULL,jpilist,0,NULL,0);
  
  /* Did we complete successfully? */
  if (status == SS$_NORMAL) return prvdef_to_hvref(&myprvs);
  else {
    SETERRNO(EVMSERR,status);
    return NULL;
  }
}



MODULE = VMS::Priv		PACKAGE = VMS::Priv		

PROTOTYPES: DISABLE

void
priv_names()
  PPCODE:
  {
    int i;
    EXTEND(sp,PRV$K_NUMBER_OF_PRIVS);
    for (i = 0; i < PRV$K_NUMBER_OF_PRIVS; i++)
       PUSHs(sv_2mortal(newSVpv(Prvnames[i][0],0)));
  }


void
get_current_privs(pid=0)
     unsigned int pid
   CODE:
     
  {
  SV *rslt = check_privs(pid,JPI$_CURPRIV);

  /* Did we complete successfully? */
  if (rslt) ST(0) = sv_2mortal(rslt);
  else ST(0) = &PL_sv_undef;
}
 
void
get_process_privs(pid=0)
     unsigned int pid
   CODE:
     
  {
  SV *rslt = check_privs(pid,JPI$_PROCPRIV);

  /* Did we complete successfully? */
  if (rslt) ST(0) = sv_2mortal(rslt);
  else ST(0) = &PL_sv_undef;
}
 
void
get_auth_privs(pid=0)
     unsigned int pid
   CODE:
     
  {
  SV *rslt = check_privs(pid,JPI$_AUTHPRIV);

  /* Did we complete successfully? */
  if (rslt) ST(0) = sv_2mortal(rslt);
  else ST(0) = &PL_sv_undef;
}
 
void
get_image_privs(pid=0)
     unsigned int pid
   CODE:
     
  {
  SV *rslt = check_privs(pid,JPI$_IMAGPRIV);

  /* Did we complete successfully? */
  if (rslt) ST(0) = sv_2mortal(rslt);
  else ST(0) = &PL_sv_undef;
}

void
get_default_privs(pid=0)
     unsigned int pid
   CODE:
     
  {
    char UserName[13];
    unsigned short int NameLen;
    ITMLST NameItemList[2];
    ITMLST UserDefaultPrivList[2];
    union prvdef myprvs;
    unsigned short myprvlen;
    int status;

    struct dsc$descriptor_s UserNameDesc;
    
    /* Clear the itemlist */
    Zero(NameItemList, 2, ITMLST);

    /* Fill in the blanks */
    init_itemlist(&NameItemList[0], 13, JPI$_USERNAME, UserName, &NameLen);

    /* Make the call and block until we get our info */
    status = sys$getjpiw(NULL, &pid, NULL, NameItemList, 0, NULL, 0);
    if (status == SS$_NORMAL) {
      /* Things went OK. Build up our descriptor and go get the info */
      UserNameDesc.dsc$a_pointer = UserName;
      UserNameDesc.dsc$w_length = NameLen;
      UserNameDesc.dsc$b_dtype = DSC$K_DTYPE_T;
      UserNameDesc.dsc$b_class = DSC$K_CLASS_S;
      
      /* Clear the list */
      Zero(UserDefaultPrivList, 2, ITMLST);

      /* Setup the list */
      init_itemlist(&UserDefaultPrivList[0], sizeof(myprvs), UAI$_DEF_PRIV,
                    &myprvs, &myprvlen);

      /* Make the call */
      status = sys$getuai(NULL, NULL, &UserNameDesc, UserDefaultPrivList,
                          NULL, NULL, NULL);

      /* Are we still OK? */
      if (status == SS$_NORMAL) {
        /* We've got the priv mask. Unpack it and return it to the caller */
        ST(0) = sv_2mortal(prvdef_to_hvref(&myprvs));
        
      } else {
        ST(0) = &PL_sv_undef;
        SETERRNO(EVMSERR,status);
      }
    } else {
      ST(0) = &PL_sv_undef;
      SETERRNO(EVMSERR,status);
    }
  }
 
void
add_current_privs(privref,...)
   SV	*privref
   CODE:
     
  {
  union prvdef PrivMask;
  unsigned short PrivMaskLength = 8;

  int status, ArgLoop, perm = 1;

  char *StringToCheck;

  AV *privs;

  if (items > 2) croak("Usage: add_current_privs(\\@privs[,perm])");
  if (items == 2) perm = SvTRUE(ST(1));

  if (!SvROK(privref)) croak("Priv list must be an array reference");
  privs = (AV *) SvRV(privref);

  /* Zero out the priv mask */
  Zero(&PrivMask,1,union prvdef);

  /* Run through the passed strings, looking for things we recognize */
  for (ArgLoop = 0; ArgLoop <= AvFILL(privs); ArgLoop++) {
    SV **priv = av_fetch(privs,ArgLoop,FALSE);
    if (!priv || !*priv || !SvPOK(*priv))
      continue;
    StringToCheck = SvPVX(*priv);

    set_bit_by_name(&PrivMask,StringToCheck);
  }

  /* Make the call. We're blocking until we get it */
  status = sys$setprv( 1, &PrivMask, perm, 0);

  /* Did we complete successfully? */
  if ((status == SS$_NORMAL) || (status = SS$_NOTALLPRIV)) {
    /* Yup, set the return value to the current privs. */
    /* We might want to throw an error if we didn't */
    /* get them all, but we won't for now. */
    ST(0) = check_privs(0,JPI$_CURPRIV);
    /* At least we'll tell them if they look for it */
    if (status == SS$_NOTALLPRIV) SETERRNO(EVMSERR,SS$_NOTALLPRIV);
  } else {
    /* We failed. Return undef and set the error codes */
    ST(0) = &PL_sv_undef;
    set_errno(EVMSERR);
    set_vaxc_errno(status);
  }
}
 
void
remove_current_privs(privref,...)
   SV	*privref
   CODE:
     
  {
  union prvdef PrivMask;
  unsigned short PrivMaskLength = 8;

  int status, ArgLoop, perm = 1;

  char *StringToCheck;

  AV *privs;

  if (items > 2) croak("Usage: remove_current_privs(\\@privs[,perm])");
  if (items == 2) perm = SvTRUE(ST(1));

  if (!SvROK(privref)) croak("Priv list must be an array reference");
  privs = (AV *) SvRV(privref);

  /* Zero out the priv mask */
  Zero(&PrivMask,1,union prvdef);

  /* Run through the passed strings, looking for things we recognize */
  for (ArgLoop = 0; ArgLoop <= AvFILL(privs); ArgLoop++) {
    SV **priv = av_fetch(privs,ArgLoop,FALSE);
    if (!priv || !*priv || !SvPOK(*priv))
      continue;
    StringToCheck = SvPVX(*priv);

    set_bit_by_name(&PrivMask,StringToCheck);
  }
    
  /* Make the call. We're blocking until we get it */
  status = sys$setprv( 0, &PrivMask, perm, 0);

  /* Did we complete successfully? */
  if ((status == SS$_NORMAL) || (status = SS$_NOTALLPRIV)) {
    /* Yup, set the return value to the current privs. */
    /* We might want to throw an error if we didn't */
    /* get them all, but we won't for now. */
    ST(0) = check_privs(0,JPI$_CURPRIV);
    /* At least we'll tell them if they look for it.  (Actually, I don't
     * think one can get SS$_NOTALLPRIV clearing privs, but just in case... */
    if (status == SS$_NOTALLPRIV) SETERRNO(EVMSERR,SS$_NOTALLPRIV);
  } else {
    /* We failed. Return undef and set the error codes */
    ST(0) = &PL_sv_undef;
    set_errno(EVMSERR);
    set_vaxc_errno(status);
  }
}
 
void
set_current_privs(privref,...)
   SV	*privref
   CODE:
     
  {
  union prvdef PrivMask, ClearMask;
  unsigned short PrivMaskLength = 8;

  int status, ArgLoop, perm = 1;

  char *StringToCheck;

  AV *privs;

  if (items > 2) croak("Usage: set_current_privs(\\@privs[,perm])");
  if (items == 2) perm = SvTRUE(ST(1));

  if (!SvROK(privref)) croak("Priv list must be an array reference");
  privs = (AV *) SvRV(privref);

  /* Zero out the priv mask so we can start clean */
  Zero(&PrivMask,1, union prvdef);

  /* Run through the passed strings, looking for things we recognize */
  /* We do this before clearing privs to minimize the time the process
   * is in a transition state, and also in case we need to display
   * warnings about bad privilege names. */
  for (ArgLoop = 0; ArgLoop <= AvFILL(privs); ArgLoop++) {
    SV **priv = av_fetch(privs,ArgLoop,FALSE);
    if (!priv || !*priv || !SvPOK(*priv))
      continue;
    StringToCheck = SvPVX(*priv);

    set_bit_by_name(&PrivMask,StringToCheck);
  }

  /* Set the priv mask to all ones */
  memset(&ClearMask, 255, sizeof(ClearMask));

  /* Use that filled priv mask to remove all the privs. We'll then add */
  /* the ones we want */
  status = sys$setprv( 0, &ClearMask, perm, 0);

  /* Set the privs that were asked for */
  if (status & 1) status = sys$setprv( 1, &PrivMask, perm, 0);

  /* Did we complete successfully? */
  if ((status == SS$_NORMAL) || (status = SS$_NOTALLPRIV)) {
    /* Yup, set the return value to the current privs. */
    /* We might want to throw an error if we didn't */
    /* get them all, but we won't for now. */
    ST(0) = check_privs(0,JPI$_CURPRIV);
    /* At least we'll tell them if they look for it */
    if (status == SS$_NOTALLPRIV) SETERRNO(EVMSERR,SS$_NOTALLPRIV);
  } else {
    /* We failed. Return undef and set the error codes */
    ST(0) = &PL_sv_undef;
    set_errno(EVMSERR);
    set_vaxc_errno(status);
  }
}
