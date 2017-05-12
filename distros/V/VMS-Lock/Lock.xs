/*
 *  The XS for VMS::Lock
 */

#include <stdio.h>
#include <ssdef.h>
#include <lckdef.h>
#include <psldef.h>
#include <starlet.h>
#include <descrip.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static int vlock_debug = 0;

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
  errno = 0;

  if (vlock_debug) printf ("In constant XS - name [%s]...\n",name);

  if (strEQ(name, "VLOCK_NLMODE")) return LCK$K_NLMODE;
  if (strEQ(name, "VLOCK_CRMODE")) return LCK$K_CRMODE;
  if (strEQ(name, "VLOCK_CWMODE")) return LCK$K_CWMODE;
  if (strEQ(name, "VLOCK_PRMODE")) return LCK$K_PRMODE;
  if (strEQ(name, "VLOCK_PWMODE")) return LCK$K_PWMODE;
  if (strEQ(name, "VLOCK_EXMODE")) return LCK$K_EXMODE;

  if (strEQ(name, "VLOCK_KERNEL")) return PSL$C_KERNEL;
  if (strEQ(name, "VLOCK_EXEC"))   return PSL$C_EXEC;
  if (strEQ(name, "VLOCK_SUPER"))  return PSL$C_SUPER;
  if (strEQ(name, "VLOCK_USER"))   return PSL$C_USER;

  if (vlock_debug) printf ("Error in constant XS; name [%s] not found.\n",name);

  errno = EINVAL;
  return 0;
}

MODULE = VMS::Lock              PACKAGE = VMS::Lock
PROTOTYPES: DISABLE

int
_new (resource_name, syslock, access_mode, lock_id, value_block, inv_valblock, expedite, debug)
  char * resource_name
  int syslock
  int access_mode
  int lock_id = NO_INIT
  SV * value_block
  int inv_valblock = NO_INIT
  int expedite
  int debug

  CODE:
  int flags  = 0;
  int status = 0;
  int tdebug = 0;
  int i;

  struct {
    short status;
    short reserved;
    int lock_id;
    char value_block[16];
  } lksb;

  struct dsc$descriptor_s resnam = {0,DSC$K_DTYPE_T,DSC$K_CLASS_S,0};

  resnam.dsc$a_pointer = resource_name;
  resnam.dsc$w_length = strlen(resource_name);

  tdebug = vlock_debug || (debug & 2);
  if (tdebug) printf ("In _new XS for resource_name [%s]...\n",resource_name);

  flags = LCK$M_VALBLK;
  if (syslock  != 0) flags |= LCK$M_SYSTEM;
  if (expedite != 0) flags |= LCK$M_EXPEDITE;

  status = sys$enqw (0,          /* efn */
                     LCK$K_NLMODE, /* lock mode */
                     &lksb,        /* address of lock status block */
                     flags,        /* flags */
                     &resnam,      /* resource name descriptor*/
                     0,0,0,0,      /* many ignored things */
                     access_mode,  /* process access mode */
                     0);           /* one more ignored thing */

  if (tdebug) {
    printf ("  status           = [%8.8x]\n", status);
    printf ("  lksb.status      = [%8.8x]\n", lksb.status);
    printf ("  lksb.lock_id     = [%8.8x]\n", lksb.lock_id);
    printf ("  lksb.value_block = [%16s]\n", lksb.value_block);
    printf ("                   = [");
    for (i=0;i<=15;i++) { printf ("%x", lksb.value_block[i]); }
    printf ("]\n");
  }

  switch (status) {
    case SS$_ACCVIO:
    case SS$_BADPARAM:
    case SS$_EXDEPTH:  /* looking ahead to sublocks... */
    case SS$_EXENQLM:
    case SS$_INSFMEM:
    case SS$_IVBUFLEN:
    case SS$_IVLOCKID: /* looking ahead to sublocks... */
    case SS$_NOSYSLCK:
      if (tdebug) printf ("Error [%8.8x] in _new XS;  returning undef.\n",status);
      SETERRNO(EVMSERR,status);
      XSRETURN_UNDEF;
      break;  /*  just making sure  */
    case SS$_NORMAL:
      lock_id = lksb.lock_id;
      if (lksb.status == SS$_VALNOTVALID) {
        if (tdebug) printf("lksb.status == SS$_VALNOTVALID\nSetting VALUE_BLOCK to [undef], INV_VALBLOCK to 1.\n");
        value_block = &PL_sv_undef;
        inv_valblock = 1;
      }
      else {
        if (SvREADONLY(value_block)) {
          if (tdebug) printf("VALUE_BLOCK is readonly.\nSetting INV_VALBLOCK to 1.\n");
          inv_valblock = 1;
        }
        else {
          if (tdebug) printf("Setting value_block to [%s].\n", lksb.value_block);
          sv_setpvn(value_block, lksb.value_block, 16);
          inv_valblock = 0;
        }
      }
      RETVAL = 1;
      break;
    default: /* SS$_SYNCH, SS$_CVTUNGRANT, SS$_NOLOCKID, SS$_NOTQUEUED, SS$_PARNOTGRANT  */
      _ckvmssts(status);
  }

  if (tdebug) printf ("Leaving _new XS.\n");

  OUTPUT:
  lock_id
  value_block
  inv_valblock
  RETVAL

int
_convert (lock_id, lock_mode, value_block, noqueue, inv_valblock, deadlock, debug)
  int lock_id
  int lock_mode
  SV * value_block
  int noqueue
  int inv_valblock = NO_INIT
  int deadlock = NO_INIT
  int debug

  CODE:
  int status = 0;
  int flags  = 0;
  int tdebug = 0;
  int i;

  struct {
    short status;
    short reserved;
    int lock_id;
    char value_block[15];
  } lksb;

  tdebug = vlock_debug || (debug & 2);

  if (tdebug) printf ("In _convert XS for lock_id [%d], to mode [%d]...\n",lock_id,lock_mode);

  flags = LCK$M_CONVERT;
  if (noqueue != 0) flags |= LCK$M_NOQUEUE;

  lksb.lock_id = lock_id;

  if (SvPOK(value_block)) {
    flags |= LCK$M_VALBLK;
    Copy(SvPVX(value_block),lksb.value_block,16,char);
    if (tdebug) printf("Value block input: param=[%.16s] enq=[%.16s]\n",
                       SvPVX(value_block),lksb.value_block);
  }

  status = sys$enqw (0,              /* efn */
                     lock_mode,      /* lock mode */
                     &lksb,          /* address of lock status block */
                     flags,          /* flags */
                     0,0,0,0,0,0,0); /* many ignored things */

  if (tdebug) {
    printf ("  status           = %d\n", status);
    printf ("  lksb.status      = %d\n", lksb.status);
    printf ("  lksb.lock_id     = %d\n", lksb.lock_id);
    printf ("  lksb.value_block = %s\n", lksb.value_block);
    for (i=0;i<=15;i++) { printf ("  lksb.value_block[%d] = [%x]\n", i, lksb.value_block[i]); }
  }

  noqueue  = 0;
  deadlock = 0;

  switch (status) {
    case SS$_ACCVIO:
    case SS$_BADPARAM:
    case SS$_EXENQLM:
    case SS$_INSFMEM:
    case SS$_IVBUFLEN:
    case SS$_IVLOCKID: /* looking ahead to sublocks... */
      if (tdebug) printf ("Error [%8.8x] in _convert XS;  returning undef.\n",status);
      SETERRNO(EVMSERR,status);
      XSRETURN_UNDEF;
    case SS$_NOTQUEUED:
      noqueue = 1;
      SETERRNO(EVMSERR,SS$_NOTQUEUED);
      RETVAL = 0;
      break;
    case SS$_NORMAL:
      if (lksb.status == SS$_DEADLOCK) {
        deadlock = 1;
        SETERRNO(EVMSERR,SS$_DEADLOCK);
        RETVAL = 0;
        break;
      }
      if (lksb.status == SS$_VALNOTVALID) {
        value_block = &PL_sv_undef;
        inv_valblock = 1;
      }
      else {
        if (SvREADONLY(value_block)) {
          if (tdebug) printf("value_block readonly; discarding value\n");
          inv_valblock = 1;
        }
        else {
          if (tdebug) printf("Setting value_block to [%s].\n", lksb.value_block);
          sv_setpvn(value_block, lksb.value_block, 16);
          inv_valblock = 0;
        }
      }
      RETVAL = 1;
      break;
    default: /* SS$_EXDEPTH, SS$_SYNCH, SS$_CVTUNGRANT, SS$_NOLOCKID, SS$_NOSYSLCK, SS$_PARNOTGRANT  */
      _ckvmssts(status);
  }

  if (tdebug) printf ("Leaving _convert XS.\n");

  OUTPUT:
  value_block
  noqueue
  inv_valblock
  deadlock
  RETVAL

int
_deq (lock_id, debug)
  int lock_id
  int debug

  CODE:
  int status = 0;
  int tdebug = 0;

  tdebug = vlock_debug || (debug & 2);

  if (tdebug) printf ("Entering _deq XS for lock_id [%d]\n",lock_id);

  status = sys$deq (lock_id,0,0,0);

  if (tdebug) printf ("  status = %d\n", status);

  switch (status) {
    case SS$_NORMAL:
      RETVAL = 1;
      break;
    default:
      if (tdebug) printf ("Error [%d] in _deq XS;  returning undef.\n",status);
      SETERRNO(EVMSERR,status);
      XSRETURN_UNDEF;
  }

  if (tdebug) printf ("Leaving _deq XS.\n");

  OUTPUT:
  RETVAL

int
_debug (debug)
  int debug

  CODE:
  if (debug & 2) vlock_debug = 1;
  else           vlock_debug = 0;

  if (vlock_debug) printf ("In _debug XS, debug = [%d], vlock_debug = [%d]\n",debug,vlock_debug);

  RETVAL = vlock_debug;

  OUTPUT:
  RETVAL

double
constant(name,arg)
        char *          name
        int             arg

