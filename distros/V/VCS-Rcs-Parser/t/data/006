head	1.2;
access;
symbols
	rel-0-1:1.1.1.1 ziya:1.1.1;
locks; strict;
comment	@# @;


1.2
date	2001.10.03.15.34.44;	author ziya;	state Exp;
branches;
next	1.1;

1.1
date	2001.09.11.12.26.01;	author ziya;	state Exp;
branches
	1.1.1.1;
next	;

1.1.1.1
date	2001.09.11.12.26.01;	author ziya;	state Exp;
branches;
next	;


desc
@@


1.2
log
@reflecting namespace change on test.pl and examples.
@
text
@# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use VCS::Rcs::Parser;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

@


1.1
log
@Initial revision
@
text
@d11 1
a11 1
use Rcs::Parser;
@


1.1.1.1
log
@Initial release.
@
text
@@
