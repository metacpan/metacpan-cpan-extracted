/*
 * A simple wrapper program for the setrlimit(2) system call, which
 * can be used to run a subprocess under a different regime -- much
 * like "nice", "time", etc.  This is needed for IRSpy, since when it
 * runs against many servers simultaneously, it runs out of file
 * descriptors -- a condition, by the way, which Perl sometimes
 * reports very misleadingly (e.g. "Can't locate Scalar/Util.pm in
 * @INC" when the open() failure was due to EMFILE rather than
 * ENOENT).
 *
 * Since the file-descriptor limit can be raised (from the default of
 * 1024 in Ubuntu) only by root, this program often needs to run as
 * root -- hence the option for resetting the UID after performing the
 * limit-change.
 */

#include <getopt.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <sys/types.h>
#include <unistd.h>
#include <pwd.h>

static struct {
    int c;
    char *name;
    int value;
    long multiplier;
} types[] = {
    { 'a', "AS", RLIMIT_AS, 1024*1024 },
    { 'n', "NOFILE", RLIMIT_NOFILE, 1 },
};


int main(int argc, char **argv) {
    int verbose = 0;
    long values[26];
    char *user = 0;
    int i, c;

    for (i = 0; i < 26; i++) {
	values[i] = 0;
    }

    while ((c = getopt(argc, argv, "vu:a:n:")) != -1) {
	switch (c) {
	case 'v':
	    verbose++;
	    break;
	case 'u':
	    user = optarg;
	    break;
	case 'a':
	case 'n': 
	    values[c-'a'] = strtol(optarg, (char**) 0, 0);
	    break;
	default:
	USAGE:
	    fprintf(stderr, "Usage: %s [options] <command>\n\
	-v		Verbose mode\n\
	-u <user>	Run subcommand as <user>\n\
	-a <Mbytes>	Set maximum size of address-space (memory)\n\
	-n <number>	Set maximum open files to <number>\n",
		    argv[0]);
	    exit(1);
	}
    }

    if (optind == argc)
	goto USAGE;

    for (c = 'a'; c <= 'z'; c++) {
	long n = values[c - 'a'];
	if (n != 0) {
	    int i, ntypes = sizeof types/sizeof *types;
	    struct rlimit old, new;

	    for (i = 0; i < ntypes; i++) {
		if (types[i].c == c)
		    break;
	    }

	    if (i == ntypes) {
		fprintf(stderr, "%s: no such type '%c'\n", argv[0], c);
		exit(2);
	    }

	    n *= types[i].multiplier;
	    getrlimit(types[i].value, &old);
	    new = old;
	    new.rlim_cur = n;
	    if (n > new.rlim_max)
		new.rlim_max = n;
	    if (verbose) {
		if (new.rlim_cur != old.rlim_cur)
		    fprintf(stderr, "%s: changing soft %s from %ld to %ld\n",
			    argv[0], types[i].name,
			    (long) old.rlim_cur, (long) new.rlim_cur);
		if (new.rlim_max != old.rlim_max)
		    fprintf(stderr, "%s: changing hard %s from %ld to %ld\n",
			    argv[0], types[i].name,
			    (long) old.rlim_max, (long) new.rlim_max);
	    }
	    if (setrlimit(types[i].value, &new) < 0) {
		fprintf(stderr, "%s: setrlimit(%s=%ld): %s\n",
			argv[0], types[i].name, n, strerror(errno));
		exit(3);
	    }
	}
    }

    if (user != 0) {
	struct passwd *pwd;
	if ((pwd = getpwnam(user)) == 0) {
	    fprintf(stderr, "%s: user '%s' not known\n", argv[0], user);
	    exit(4);
	}

	if (setuid(pwd->pw_uid) < 0) {
	    fprintf(stderr, "%s: setuid('%s'=%ld): %s\n",
		    argv[0], user, (long) pwd->pw_uid, strerror(errno));
	    exit(5);
	}
    }

    if (verbose)
	fprintf(stderr, "%s: user='%s', optind=%d, new argc=%d, argv[0]='%s'\n",
		argv[0], user, optind, argc-optind, argv[optind]);

    execvp(argv[optind], argv+optind);
    fprintf(stderr, "%s: execvp('%s'): %s\n",
	    argv[0], argv[optind], strerror(errno));
    exit(6);
}
