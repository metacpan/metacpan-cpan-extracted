/*
 * Copyright (C) 2007-2014 Collax GmbH
 *                    (Bastian Friedrich <bastian.friedrich@collax.com>)
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <pwd.h>
#include <unistd.h>

MODULE = User::getgrouplist PACKAGE = User::getgrouplist

PROTOTYPES: ENABLE

AV *
getgrouplist(username)
        const char *username
    PREINIT:
	int count = 0;
	int max;		/* OpenBSD/darwin overwrite input value */
	int i;
	gid_t *groups = NULL;
	struct passwd *pw;
    PPCODE:
	pw = getpwnam(username);
	RETVAL = NULL;

	if (pw != NULL) { /* Only execute when user exists */
#if defined __OpenBSD__ || defined __MACH__
		/*
		 * The getgrouplist implementation in OpenBSD and MacOS X/
		 * darwin/MACH will not return the number of groups if it
		 * is larger than the input count argument.
		 * Thus, we need to find a list size. Start with an
		 * arbitrary number (32), and duplicate it on each iteration.
		 *
		 * 32 is a random number. NGROUPS_MAX defaults to 16 on my
		 * OpenBSD.
		 */
		max = 32;
		count = max;
		groups = (gid_t *) malloc(count * sizeof (gid_t));
		while (groups && (getgrouplist(username, pw->pw_gid, groups, &count) < 0) && (count < sysconf(_SC_NGROUPS_MAX))) {
			max *= 2;
			count = max;	/* Re-set. Was overwritten by last getgrouplist call */
			groups = (gid_t *) realloc(groups, count * sizeof (gid_t));
			if (!groups) {
				count = 0;
				continue;
			}
		}
#else
#if defined __CYGWIN__
		/* Cygwin behaves differently than Linux -- will return count even if groups is NULL */
		if (getgrouplist(username, pw->pw_gid, NULL, &count) > 0) {
#else
		if (getgrouplist(username, pw->pw_gid, NULL, &count) < 0) {
#endif
			groups = (gid_t *) malloc(count * sizeof (gid_t));
			if (groups) {
				getgrouplist(username, pw->pw_gid, groups, &count);
			}
		}
#endif
		if (groups) {
			for (i = 0; i < count; i++) {
				XPUSHs(sv_2mortal(newSViv(groups[i])));
			}
			free(groups);
		}
	}
