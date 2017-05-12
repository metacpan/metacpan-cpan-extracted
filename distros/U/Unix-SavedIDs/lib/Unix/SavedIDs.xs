#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include <unistd.h>
#include <string.h>

#define UUSAGE "Usage: Unix::SavedIDs::setresuid(int ruid,int euid,int suid)"
#define GUSAGE "Usage: Unix::SavedIDs::setresgid(int rgid,int egid,int sgid)"

MODULE = Unix::SavedIDs     PACKAGE = Unix::SavedIDs

void 
getresuid()
	INIT:
		int err;
		uid_t ruid;
		uid_t euid;
		uid_t suid;
	PPCODE:
		err = getresuid(&ruid,&euid,&suid);
		if ( err ) {
				croak("%s",strerror(errno));	
		}
		XPUSHs(sv_2mortal(newSVuv(ruid)));
		XPUSHs(sv_2mortal(newSVuv(euid)));
		XPUSHs(sv_2mortal(newSVuv(suid)));

void 
getresgid()
	INIT:
		int err;
		gid_t rgid;
		gid_t egid;
		gid_t sgid;
	PPCODE:
		err = getresgid(&rgid,&egid,&sgid);
		if ( err ) {
				croak("%s",strerror(errno));	
		}
		XPUSHs(sv_2mortal(newSVuv(rgid)));
		XPUSHs(sv_2mortal(newSVuv(egid)));
		XPUSHs(sv_2mortal(newSVuv(sgid)));
		
void
_setresuid(ruid,euid,suid)
	uid_t ruid
	uid_t euid
	uid_t suid
	CODE:
		if ( setresuid(ruid,euid,suid) ) {
				croak("%s",strerror(errno));	
		}
#if PERL_REVISION < 5 || ( PERL_REVISION == 5 && PERL_VERSION < 15 ) || ( PERL_REVISON == 5 && PERL_VERSION == 15 && PERL_SUBVERSION < 9 )
	CLEANUP:
		PL_uid = getuid();
		PL_euid = geteuid();
#endif

void
_setresgid(rgid,egid,sgid)
	uid_t rgid
	uid_t egid
	uid_t sgid
	CODE:
		if ( setresgid(rgid,egid,sgid) ) {
				croak("%s",strerror(errno));	
		}
#if PERL_REVISION < 5 || ( PERL_REVISION == 5 && PERL_VERSION < 15 ) || ( PERL_REVISON == 5 && PERL_VERSION == 15 && PERL_SUBVERSION < 9 )
	CLEANUP:
		PL_gid = getgid();
		PL_egid = getegid();
#endif

