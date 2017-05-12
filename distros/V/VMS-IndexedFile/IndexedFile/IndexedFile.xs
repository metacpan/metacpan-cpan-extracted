
/* VMS::IndexedFile

VERSION 0.02

Copyright (c) 1996 Kent A. Covert and Toni L. Harbaugh-Blackford.
All rights reserved.  This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.


History:
    0.02 04/29/99  BH      Repackaged as VMS::IndexedFile
                           Dan's patch from 3/99 applied
    0.01 04/01/96  KAC     Initial beta program version (covertka@muohio.edu)
                             -adapted from Toni L. Harbaugh-Blackford's
                              VDBM application.
*/

#include <file.h>
#include <rms.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ssdef.h>
#include <starlet.h>
#include <libdef.h>
#include <fdl$routines.h>
#include <fdldef.h>
#include <lib$routines.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

int vmdbm_debug = 0;

/* For some strange reason, DEC created these nice macros and then completely messed them up in XABKEYDEF.H */
#undef xab$w_pos
#undef xab$b_siz
/* The following lines are copied from the XABKEYDEF.H file, BEFORE they're "corrupted" */
#define xab$w_pos xab$r_pos_overlay.xab$w_pos
#define xab$b_siz xab$r_siz_overlay.xab$b_siz

typedef struct _VMSMDBM_STRUCT_
{
  struct FAB      fab;
  struct NAM      nam;
  struct RAB      rab;
  struct XABKEY   xabkey;
  char *          key;
  char            es[256];
  int             replace;
} VMSMDBM;
          /* a VMSMDBM ptr is returned by vmsdbm_TIEHASH() */

typedef VMSMDBM *   VMDBM;

static double
constant(name, arg)
char *name;
int arg;
{
  errno = 0;

  if (vmdbm_debug) printf("in constant - name: %s\n",name);

  switch (*name) {
    case 'O':  if (strEQ(name, "O_RDONLY")) return O_RDONLY;
               if (strEQ(name, "O_WRONLY")) return O_WRONLY;
               if (strEQ(name, "O_RDWR"))   return O_RDWR;
               if (strEQ(name, "O_CREAT"))  return O_CREAT;
               if (strEQ(name, "O_TRUNC"))  return O_TRUNC;
               if (strEQ(name, "O_EXCL"))   return O_EXCL;
	             break;
  }
  errno = EINVAL;
  return 0;
}

int
vmdbm_store(VMDBM vms_db,SV *record)
{
  unsigned long int retsts;
  char * recval;
  STRLEN reclen;
  int tmpbool;
  int retval;

  SETERRNO(0,SS$_NORMAL);
  retval = 0;

  if (vmdbm_debug) printf("vmdbm_store\n");

  recval = SvPV(record,reclen);

  if (vmdbm_debug) printf("  record to be stored: %s\n",recval);

  vms_db->rab.rab$b_rac =   RAB$C_KEY;
  vms_db->rab.rab$l_rbf =   recval;
  vms_db->rab.rab$w_rsz =   reclen;
  vms_db->rab.rab$l_rop =   RAB$M_RLK | RAB$M_RRL | (RAB$M_UIF * vms_db->replace);

  retsts =   sys$put(&(vms_db->rab));
  if (retsts == RMS$_NORMAL || retsts == RMS$_OK_DUP) {
    retval = 1;
  } else {
    if (vmdbm_debug) printf("store returned: %d\n",retsts);
    SETERRNO(65535,retsts);
  }
  return retval;
}

void
vmdbm_cleanup(VMDBM vms_db) {
  if (vms_db != NULL) {
    if (vms_db->rab.rab$l_ubf != NULL) free(vms_db->rab.rab$l_ubf);
    if (vms_db->key != NULL) free(vms_db->key);
    free(vms_db);
  }
}


MODULE = VMS::IndexedFile PACKAGE = VMS::IndexedFile PREFIX = vmsmdbm_

int
replace(vms_db,status=1,...)
  VMDBM vms_db
  int   status
  CODE:
  {
    RETVAL = vms_db->replace;
    vms_db->replace = status;
  }
  OUTPUT:
  RETVAL

int
debug(vms_db,status=1,...)
  VMDBM vms_db
  int   status
  CODE:
  {
    RETVAL = vmdbm_debug;
    vmdbm_debug = status;
    if (status) printf("VMS::IndexedFile debugging enabled.\n");
    else printf("VMS::IndexedFile debugging disabled.\n");
  }
  OUTPUT:
  RETVAL

VMDBM
vmsmdbm_TIEHASH(dbtype,filename,index=0,flags=O_RDWR,fdldata="",...)
  char *	dbtype
  char *  filename
  int	index
  int flags
  char *  fdldata
  CODE:
  {
    VMDBM newmdbm = NULL;
    unsigned long int retsts = RMS$_NORMAL;
    unsigned int filenamelen;

    RETVAL = NULL;
    SETERRNO(0,SS$_NORMAL);

    if (vmdbm_debug) printf("open - items: %d  index: %d  flags: %d  o_creat: %d   fdldesc: %s\n",items,index,flags,O_CREAT,fdldata);

    /* Check for conflicting arguments */
    if ((flags & O_CREAT || flags & O_TRUNC) && !strcmp(fdldata,"")) {
      SETERRNO(65535, SS$_INSFARG); goto vmsmdbm_TIEHASH_error;
    }

    Newz(0, newmdbm, 1, VMSMDBM);
    if ( newmdbm  == NULL ) {
      SETERRNO(65535,LIB$_INSVIRMEM); goto vmsmdbm_TIEHASH_error;
    } 

    newmdbm->fab           =   cc$rms_fab;          /* Initialize FAB       */
    newmdbm->fab.fab$b_fac =   FAB$M_DEL | FAB$M_GET | FAB$M_PUT | FAB$M_UPD;
    newmdbm->fab.fab$l_fna =   filename;
    newmdbm->fab.fab$b_fns =   strlen(filename);
    newmdbm->fab.fab$b_shr =   FAB$M_MSE | FAB$M_SHRPUT | FAB$M_SHRGET | FAB$M_SHRDEL | FAB$M_SHRUPD;
    newmdbm->fab.fab$l_xab =   (char *) &(newmdbm->xabkey);
    newmdbm->fab.fab$l_nam =   &(newmdbm->nam);
  
    newmdbm->nam           =   cc$rms_nam;         /* Iniitialize NAM       */
    newmdbm->nam.nam$l_esa =   newmdbm->es;
    newmdbm->nam.nam$b_ess =   255;
    newmdbm->nam.nam$l_rlf =   NULL;
    newmdbm->nam.nam$l_rsa =   NULL;
    newmdbm->nam.nam$b_rss =   0;
    newmdbm->nam.nam$b_rsl =   0;

    newmdbm->xabkey           = cc$rms_xabkey;     /* Initialize XABKEY     */
    newmdbm->xabkey.xab$b_ref = index;
    newmdbm->xabkey.xab$l_nxt = NULL;

    newmdbm->key              = NULL;
  
    /* Handle flags */
    newmdbm->fab.fab$b_fac =   FAB$M_GET;
    newmdbm->replace       =   1;

    if (flags & O_WRONLY) {
      newmdbm->fab.fab$b_fac =   FAB$M_PUT;
      newmdbm->replace       =   0;
    }
    if (flags & O_RDWR) {
      newmdbm->fab.fab$b_fac =   FAB$M_GET | FAB$M_DEL | FAB$M_PUT | FAB$M_UPD;
      newmdbm->replace       =   1;
    }

    /* Does the file already exist? */
    retsts = sys$parse(&(newmdbm->fab));
    if (vmdbm_debug) printf("  sys$parse returned: %d\n",retsts);
    if (vmdbm_debug) printf("  es: %d - (%s)\n",(int)newmdbm->nam.nam$b_esl,newmdbm->nam.nam$l_esa);
    if (retsts != RMS$_NORMAL) {
      SETERRNO(65535,retsts); goto vmsmdbm_TIEHASH_error;
    }
    retsts = sys$search(&(newmdbm->fab));
    if (vmdbm_debug) printf("  sys$search returned: %d\n",retsts);
    if ((retsts != RMS$_NORMAL) && (retsts != RMS$_FNF)) {
      SETERRNO(65535,retsts); goto vmsmdbm_TIEHASH_error;
    }

    if ((flags & O_CREAT) && (flags & O_EXCL) && retsts != RMS$_FNF) {
      SETERRNO(EEXIST,retsts); goto vmsmdbm_TIEHASH_error;
    }

    if (((flags & O_CREAT) && retsts == RMS$_FNF) || (flags & O_TRUNC)) {
      unsigned int fdlflags;
      unsigned int sts,stv;
      $DESCRIPTOR(fdldesc,"");
      $DESCRIPTOR(fnamedesc,"");
    
      if (vmdbm_debug) printf("creating new file\n");
      fnamedesc.dsc$a_pointer = filename;
      fnamedesc.dsc$w_length  = strlen(filename);
      if (*fdldata == '<') {
        fdldesc.dsc$a_pointer = fdldata + 1;
        fdldesc.dsc$w_length  = strlen(fdldata + 1);
        fdlflags = 0;
      } else {
        fdldesc.dsc$a_pointer = fdldata;
        fdldesc.dsc$w_length  = strlen(fdldata);
        fdlflags = FDL$M_FDL_STRING;
      }
      retsts = fdl$create(&fdldesc, &fnamedesc, 0, 0, 0, &fdlflags, 0, 0, &sts, &stv, 0);
      if (retsts != RMS$_NORMAL) {
        SETERRNO(65535,retsts); goto vmsmdbm_TIEHASH_error;
      }
    }

    if ((retsts = sys$open(&(newmdbm->fab))) != RMS$_NORMAL) {
      SETERRNO(65535,retsts); goto vmsmdbm_TIEHASH_error;
    }
  
    if (vmdbm_debug) {
      int seg;
      printf("  number of segments: %d\n",(int)newmdbm->xabkey.xab$b_nsg);
      printf("  total key size:     %d\n",(int)newmdbm->xabkey.xab$b_tks);
      for(seg=0;seg<=7;seg++)
        printf("  seg %d pos: %2d size: %2d\n", seg, (int)newmdbm->xabkey.xab$w_pos[seg], (int)newmdbm->xabkey.xab$b_siz[seg]);
    }
  
    newmdbm->rab           =   cc$rms_rab;               /* Initialize RAB         */
    newmdbm->rab.rab$l_fab =   &(newmdbm->fab);
    newmdbm->rab.rab$l_ubf =   NULL;
    newmdbm->rab.rab$b_krf =   index;
    newmdbm->rab.rab$w_usz =   newmdbm->fab.fab$w_mrs;
  
    if ((retsts = sys$connect(&(newmdbm->rab))) != RMS$_NORMAL) {
      SETERRNO(65535,retsts); goto vmsmdbm_TIEHASH_error;
    }
    if (vmdbm_debug) printf("open (TIEHASH) ---- newmdbm = %p\n",newmdbm);
    RETVAL = newmdbm;
    SETERRNO(65535,retsts);

    vmsmdbm_TIEHASH_error:
    if (RETVAL == NULL) {
      vmdbm_cleanup(newmdbm);
    }
  }
  OUTPUT:
  RETVAL

int
vmsmdbm_DESTROY(vms_db)
  VMDBM	vms_db
  CODE:
  {
    unsigned long int retsts;

    SETERRNO(0,SS$_NORMAL);
    RETVAL = 0;

    if (vmdbm_debug) printf("destroy - %p\n",vms_db);

    retsts = sys$close(&(vms_db->fab));
    if (retsts & 1)
    {
      vmdbm_cleanup(vms_db);
      RETVAL = 1;
    }
    else
    {
      printf ("ERROR: unable to close dbm: %lu\n",retsts);
      SETERRNO(65535,retsts);
    }
  }
  OUTPUT:
  RETVAL

int
was_store(vms_db,record,...)
  VMDBM   vms_db
  SV *  record
  ALIAS:
    store = 1
  CODE:
  {
    RETVAL = vmdbm_store(vms_db,record);
  }
  OUTPUT:
  RETVAL

void
vmsmdbm_STORE(vms_db,key,record)
  VMDBM	vms_db
  SV *	key
  SV *	record
  PPCODE:
  {
    vmdbm_store(vms_db,record);
  }

int
vmsmdbm_EXISTS(vms_db,key)
  VMDBM	vms_db
  SV *	key
  CODE:
  {    
    unsigned long int retsts;
    char * keyval;
    STRLEN keylen;

    RETVAL = 0;
    SETERRNO(65535,SS$_NORMAL);

    if (vmdbm_debug) printf("exists\n");

    keyval = SvPV(key,keylen);

    vms_db->rab.rab$l_kbf =   keyval;
    vms_db->rab.rab$b_ksz =   keylen;
    vms_db->rab.rab$b_rac =   RAB$C_KEY;
    vms_db->rab.rab$l_rop =   RAB$M_NLK | RAB$M_RRL;

    retsts =   sys$find(&(vms_db->rab));
    if (retsts == RMS$_NORMAL || retsts == RMS$_OK_RRL)
    { 
        RETVAL = 1;
    }
    SETERRNO(65535,retsts);
  }             
  OUTPUT:
  RETVAL

void
vmsmdbm_FETCH(vms_db,key)
  VMDBM	vms_db
  SV *	key
  PPCODE:
  {
    unsigned long int retsts;
    char * keyval;
    STRLEN keylen;
    int contentval_len;
    int k;

    SETERRNO(0,SS$_NORMAL);

    if (vmdbm_debug) printf("fetch\n");

    keyval = SvPV(key,keylen);

    if (vmdbm_debug) printf("  - key to be fetched: %s\n",keyval);

    PUSHs(sv_newmortal());

    if (vms_db->rab.rab$l_ubf == NULL && ( (vms_db->rab.rab$l_ubf = (char *) malloc(vms_db->fab.fab$w_mrs)) == NULL )) {
        SETERRNO(65535,LIB$_INSVIRMEM);
    }
    else
    {
      if (keylen) {
        vms_db->rab.rab$l_kbf =   keyval;
        vms_db->rab.rab$b_ksz =   keylen;
        vms_db->rab.rab$b_rac =   RAB$C_KEY;
      } else {
        vms_db->rab.rab$b_rac =   RAB$C_SEQ;
      }
      vms_db->rab.rab$l_rop =   RAB$M_NLK | RAB$M_RRL;
    
      retsts =   sys$get(&(vms_db->rab));
      if (!(retsts & 1))
      {
        if (vmdbm_debug) printf ("failed sys$get:status=%lu\n",retsts);
        SETERRNO(65535,retsts);
      }
      else
      {
        ST(0) = sv_2mortal(newSVpv(vms_db->rab.rab$l_ubf,vms_db->rab.rab$w_rsz));
      }
    }
  }
    
int
vmsmdbm_DELETE(vms_db,key)
  VMDBM	vms_db
  SV *	key
  CODE:
  {
    unsigned long int retsts = RMS$_NORMAL;
    char * keyval;
    int keyval_len;
    STRLEN keylen;

    RETVAL = 0;
    SETERRNO(65535,SS$_NORMAL);

    if (vmdbm_debug) printf("delete\n");

    keyval = SvPV(key,keylen);

    vms_db->rab.rab$l_kbf =   keyval;
    vms_db->rab.rab$b_ksz =   keylen;
    vms_db->rab.rab$b_rac =   RAB$C_KEY;
    vms_db->rab.rab$l_rop =   RAB$M_RLK | RAB$M_RRL;

    if (keylen) {
      retsts =   sys$find(&(vms_db->rab));
      if (vmdbm_debug) printf("  sys$find result: %d",retsts);
    }
    if (retsts == RMS$_NORMAL)
    {
      retsts =   sys$delete(&(vms_db->rab));
      if (vmdbm_debug) printf("  sys$delete result: %d",retsts);
      if (retsts == RMS$_NORMAL) {
        RETVAL = 1;
      }
    }
    SETERRNO(65535,retsts);
  }
  OUTPUT:
  RETVAL

void
vmsmdbm_FIRSTKEY(vms_db)
  VMDBM	vms_db
  PPCODE:
  {
    unsigned long int retsts;
    char * keyval;
    int keyval_len;

    if (vmdbm_debug) printf("firstkey\n");

    SETERRNO(0,SS$_NORMAL);
    PUSHs(sv_newmortal());

    retsts =   sys$rewind(&(vms_db->rab));
                                               
    if (vms_db->rab.rab$l_ubf == NULL && ( (vms_db->rab.rab$l_ubf = (char *) malloc(vms_db->fab.fab$w_mrs)) == NULL )) {
        SETERRNO(65535,LIB$_INSVIRMEM);
    }
    else
    {
      vms_db->rab.rab$b_rac =   RAB$C_SEQ;
      vms_db->rab.rab$l_rop =   RAB$M_NLK | RAB$M_RRL;

      retsts =   sys$get(&(vms_db->rab));
      if (retsts != RMS$_NORMAL && retsts != RMS$_OK_RRL) {
        if (vmdbm_debug) printf("  firstkey error: %d",retsts);
        SETERRNO(65535,retsts);
      }
      else {
        if (vms_db->key == NULL && ( (vms_db->key = (char *) malloc(vms_db->xabkey.xab$b_tks)) == NULL )) {
          SETERRNO(65535,LIB$_INSVIRMEM);
        }
        else {
          int seg;
          char *curseg;

          curseg = vms_db->key;
          for (seg=0;seg<vms_db->xabkey.xab$b_nsg;seg++) {
            if (vmdbm_debug) printf("  seg: %d   pos: %d  size: %d",seg,
                vms_db->xabkey.xab$w_pos[seg],vms_db->xabkey.xab$b_siz[seg]);
            memcpy(curseg, vms_db->rab.rab$l_ubf + vms_db->xabkey.xab$w_pos[seg], vms_db->xabkey.xab$b_siz[seg]);
            curseg += vms_db->xabkey.xab$b_siz[seg];
            if (vmdbm_debug) printf("  data so far: %*.*s\n", curseg - vms_db->key, curseg - vms_db->key, vms_db->key);
          }
          ST(0) = sv_2mortal(newSVpv(vms_db->key,vms_db->xabkey.xab$b_tks));
        }
      }  
    }
  }

void
vmsmdbm_NEXTKEY(vms_db, ...)
  VMDBM	vms_db
  PPCODE:
  {
    unsigned long int retsts;

    if (vmdbm_debug) printf("nextkey\n");

    SETERRNO(0,SS$_NORMAL);
    PUSHs(sv_newmortal());

    if (vms_db->rab.rab$l_ubf == NULL && ( (vms_db->rab.rab$l_ubf = (char *) malloc(vms_db->fab.fab$w_mrs)) == NULL )) {
        SETERRNO(65535,LIB$_INSVIRMEM);
    }
    else
    {
      vms_db->rab.rab$b_rac =   RAB$C_SEQ;
      vms_db->rab.rab$l_rop =   RAB$M_NLK | RAB$M_RRL;

      retsts =   sys$get(&(vms_db->rab));
      if (retsts != RMS$_NORMAL && retsts != RMS$_OK_RRL) {
        if (vmdbm_debug) printf("  nextkey error: %d",retsts);
        SETERRNO(65535,retsts);
      }
      else {
        if (vms_db->key == NULL && ( (vms_db->key = (char *) malloc(vms_db->xabkey.xab$b_tks)) == NULL )) {
          SETERRNO(65535,LIB$_INSVIRMEM);
        }
        else {
          int seg;
          char *curseg;

          curseg = vms_db->key;
          for (seg=0;seg<vms_db->xabkey.xab$b_nsg;seg++) {
            if (vmdbm_debug) printf("  seg: %d   pos: %d  size: %d",seg,
                vms_db->xabkey.xab$w_pos[seg],vms_db->xabkey.xab$b_siz[seg]);
            memcpy(curseg, vms_db->rab.rab$l_ubf + vms_db->xabkey.xab$w_pos[seg], vms_db->xabkey.xab$b_siz[seg]);
            curseg += vms_db->xabkey.xab$b_siz[seg];
            if (vmdbm_debug) printf("  data so far: %*.*s\n", curseg - vms_db->key, curseg - vms_db->key, vms_db->key);
          }
          ST(0) = sv_2mortal(newSVpv(vms_db->key,vms_db->xabkey.xab$b_tks));
        }
      }
    }
  }

int
vmsmdbm_CLEAR(vms_db)
  VMDBM	vms_db
  CODE:
  {
    unsigned long int retsts;

    if (vmdbm_debug) printf("clear\n");

    RETVAL = 0;
    SETERRNO(0,SS$_NORMAL);

    retsts =   sys$rewind(&(vms_db->rab));
                                               
    vms_db->rab.rab$b_rac =   RAB$C_SEQ;
    vms_db->rab.rab$l_rop =   RAB$M_RLK | RAB$M_RRL;

    while ((retsts = sys$get(&(vms_db->rab))) == RMS$_NORMAL || retsts == RMS$_OK_RRL) {
      retsts =   sys$delete(&(vms_db->rab));
    }
    if (retsts == RMS$_EOF) {
      RETVAL = 1;
    }
    SETERRNO(65535,retsts);
  }
  OUTPUT:
  RETVAL


double
constant(name,arg)
	char *		name
	int		arg
