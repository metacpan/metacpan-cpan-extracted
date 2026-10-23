#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

typedef int sysret_t;

MODULE = Unix::ResID				PACKAGE = Unix::ResID

TYPEMAP:<<END
uid_t T_IV
gid_t T_IV
sysret_t T_SYSRET
END

NO_OUTPUT int getresuid(OUTLIST uid_t ruid, OUTLIST uid_t euid, OUTLIST uid_t suid)
POSTCALL:
	if (RETVAL < 0)
		XSRETURN_EMPTY;

NO_OUTPUT int getresgid(OUTLIST gid_t rgid, OUTLIST gid_t egid, OUTLIST gid_t sgid)
POSTCALL:
	if (RETVAL < 0)
		XSRETURN_EMPTY;

sysret_t setresuid(uid_t ruid, uid_t euid, uid_t suid)

sysret_t setresgid(gid_t rgid, gid_t egid, gid_t sgid)
