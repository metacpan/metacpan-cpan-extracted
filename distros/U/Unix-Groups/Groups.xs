#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include <sys/types.h>
#include <unistd.h>
#include <grp.h>

MODULE = Unix::Groups	PACKAGE = Unix::Groups

PROTOTYPES: DISABLE

IV
NGROUPS_MAX()
  CODE:
{
  RETVAL=sysconf(_SC_NGROUPS_MAX);
}
  OUTPUT:
    RETVAL

void
getgroups()
  PPCODE:
{
  int rc, i;
  long ngroups_max=sysconf(_SC_NGROUPS_MAX)+1;
  gid_t groups[ngroups_max];

  if( (rc=getgroups(ngroups_max, groups))>=0 ) {
    for(i=0; i<rc; i++) {
      mXPUSHi(groups[i]);
    }
  }
}

void
setgroups(...)
  PPCODE:
{
  int rc, i;
  gid_t groups[items];

  for(i=0; i<items; i++) {
    groups[i]=SvIV(ST(i));
  }

  if( (rc=setgroups(items, groups))>=0 ) {
    mXPUSHi(1);
  }
}

## Local Variables: ##
## mode: c ##
## End: ##
