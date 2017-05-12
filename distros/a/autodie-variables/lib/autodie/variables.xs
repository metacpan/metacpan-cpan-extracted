#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef CopHINTHASH_get
#define CopHINTHASH_get(c) ((c)->cop_hints_hash)
#endif

#ifndef cophh_fetch_pvs
#define cophh_fetch_pvs(cophh, key, flags) Perl_refcounted_he_fetch(aTHX_ cophh, NULL, STR_WITH_LEN(key), 0, flags)
#endif

#if PERL_VERSION < 15 || PERL_VERSION == 15 && PERL_SUBVERSION < 8
#define PL_delaymagic_uid PL_uid
#define PL_delaymagic_euid PL_euid
#define PL_delaymagic_gid PL_gid
#define PL_delaymagic_egid PL_egid
#endif

#if defined(HAS_GETGROUPS) || defined(HAS_SETGROUPS)
#  ifdef I_GRP
#    include <grp.h>
#  endif
#endif

#if defined(HAS_SETGROUPS)
#  ifndef NGROUPS
#    define NGROUPS 32
#  endif
#endif

static int autodie_variables(pTHX) {
	SV* val = cophh_fetch_pvs(CopHINTHASH_get(PL_curcop), "autodie_variables", 0);
	if (val != &PL_sv_placeholder)
		return SvIV(val);
	return 0;
}

static int new_magic_set(pTHX_ SV *sv, MAGIC *mg) {
	dVAR;
	register const char *s;
	I32 i;
	STRLEN len;
	MAGIC *tmg;
	int ret = 0;

#ifdef PERL_ARGS_ASSERT_MAGIC_SET
	PERL_ARGS_ASSERT_MAGIC_SET;
#endif

	if (!autodie_variables(aTHX))
		return Perl_magic_set(aTHX_ sv, mg);

	switch (*mg->mg_ptr) {
	case '<':
		{
		const Uid_t new_uid = SvIV(sv);
		if (PL_delaymagic) {
			PL_delaymagic_uid = new_uid;
			PL_delaymagic |= DM_RUID;
			break;								/* don't do magic till later */
		}
#ifdef HAS_SETRESUID
		ret = setresuid((Uid_t)new_uid, (Uid_t)-1, (Uid_t)-1);
#else
#ifdef HAS_SETRUID
		ret = setruid((Uid_t)new_uid);
#else
#ifdef HAS_SETREUID
		ret = setreuid((Uid_t)new_uid, (Uid_t)-1);
#else
		if (new_uid == geteuid()) {				/* special case $< = $> */
#ifdef PERL_DARWIN
			/* workaround for Darwin's setuid peculiarity, cf [perl #24122] */
			if (new_uid != 0 && PerlProc_getuid() == 0)
				(void)PerlProc_setuid(0);
#endif
			ret = PerlProc_setuid(new_uid);
		} else {
			Perl_croak(aTHX_ "setruid() not implemented");
		}
#endif
#endif
#endif
		if (ret < 0)
			Perl_croak(aTHX_ "setruid(%d) failed: %s", new_uid, Strerror(errno));
#ifdef PL_uid
		PL_uid = PerlProc_getuid();
#endif
		break;
		}
	case '>':
		{
		const Uid_t new_euid = SvIV(sv);
		if (PL_delaymagic) {
			PL_delaymagic_euid = new_euid;
			PL_delaymagic |= DM_EUID;
			break;								/* don't do magic till later */
		}
#ifdef HAS_SETRESUID
		ret = setresuid((Uid_t)-1, (Uid_t)new_euid, (Uid_t)-1);
#else
#ifdef HAS_SETEUID
		ret = seteuid((Uid_t)new_euid);
#else
#ifdef HAS_SETREUID
		(void)setreuid((Uid_t)-1, (Uid_t)new_euid);
#else
		if (new_euid == PerlProc_getuid())				/* special case $> = $< */
			ret = PerlProc_setuid(new_euid);
		else {
			Perl_croak(aTHX_ "seteuid() not implemented");
		}
#endif
#endif
#endif
		if (ret < 0)
			Perl_croak(aTHX_ "seteuid(%d) failed: %s", new_euid, Strerror(errno));
#ifdef PL_euid
		PL_euid = PerlProc_geteuid();
#endif
		break;
		}
	case '(':
		{
		const Gid_t new_gid = SvIV(sv);
		if (PL_delaymagic) {
			PL_delaymagic_gid = new_gid;
			PL_delaymagic |= DM_RGID;
			break;								/* don't do magic till later */
		}
#ifdef HAS_SETRESGID
		ret = setresgid((Gid_t)new_gid, (Gid_t)-1, (Gid_t) -1);
#else
#ifdef HAS_SETRGID
		ret = setrgid((Gid_t)new_gid);
#else
#ifdef HAS_SETREGID
		ret = setregid((Gid_t)new_gid, (Gid_t)-1);
#else
		if (new_gid == PerlProc_getegid())						/* special case $( = $) */
			ret = PerlProc_setgid(new_gid);
		else {
			Perl_croak(aTHX_ "setrgid() not implemented");
		}
#endif
#endif
#endif
		if (ret < 0)
			Perl_croak(aTHX_ "setrgid(%d) failed: %s", new_gid, Strerror(errno));
#ifdef PL_gid
		PL_gid = PerlProc_getgid();
#endif
		break;
		}
	case ')':
		{
		gid_t new_egid;
#ifdef HAS_SETGROUPS
		{
			const char *p = SvPV_const(sv, len);
			const char *additional = NULL;
			Groups_t *gary = NULL;
#ifdef _SC_NGROUPS_MAX
			int maxgrp = sysconf(_SC_NGROUPS_MAX);

			if (maxgrp < 0)
				maxgrp = NGROUPS;
#else
			int maxgrp = NGROUPS;
#endif

			while (isSPACE(*p))
				++p;
			new_egid = Atol(p);
			for (i = 0; i < maxgrp; ++i) {
				while (*p && !isSPACE(*p))
					++p;
				while (isSPACE(*p))
					++p;
				if (!additional)
					additional = p;
				if (!*p)
					break;
				if(!gary)
					Newx(gary, i + 1, Groups_t);
				else
					Renew(gary, i + 1, Groups_t);
				gary[i] = Atol(p);
			}
			if (i) {
				if (setgroups(i, gary) < 0) {
					Perl_croak(aTHX_ "setgroups(%s) failed: %s", additional, Strerror(errno));
				}
			}
			
			Safefree(gary);
		}
#else  /* HAS_SETGROUPS */
		new_egid = SvIV(sv);
#endif /* HAS_SETGROUPS */
		if (PL_delaymagic) {
			PL_delaymagic_egid = new_egid;
			PL_delaymagic |= DM_EGID;
			break;								/* don't do magic till later */
		}
#ifdef HAS_SETRESGID
		ret = setresgid((Gid_t)-1, (Gid_t)new_egid, (Gid_t)-1);
#else
#ifdef HAS_SETEGID
		ret = setegid((Gid_t)new_egid);
#else
#ifdef HAS_SETREGID
		ret = setregid((Gid_t)-1, (Gid_t)new_egid);
#else
		if (new_egid == PerlProc_getgid())						/* special case $) = $( */
			ret = PerlProc_setgid(new_egid);
		else {
			Perl_croak(aTHX_ "setegid() not implemented");
		}
#endif
#endif
#endif
		if (ret < 0)
			Perl_croak(aTHX_ "setegid(%d) failed: %s", new_egid, Strerror(errno));
#ifdef PL_egid
		PL_egid = PerlProc_getegid();
#endif
		}
		break;
		default:
			return Perl_magic_set(aTHX_ sv, mg);
	}
}

const MGVTBL new_vtable = { Perl_magic_get, new_magic_set };

MODULE = autodie::variables                PACKAGE = autodie::variables

void
_reset_global(var)
	SV* var;
    CODE:
		MAGIC* magic = mg_find(var, PERL_MAGIC_sv);
		magic->mg_virtual = (MGVTBL*)&new_vtable;
