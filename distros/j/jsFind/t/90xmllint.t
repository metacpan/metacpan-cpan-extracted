#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

my $xmllint=eval { `which xmllint` };

if (! $xmllint) {
	ok(1, "skip xmllint");
} else {
	my $ok = eval { `xmllint --noout html/*/*.xml html/*/*/*.xml html/*/*/*/*.xml 2>&1` };
	cmp_ok($ok, '==', '' , "xmllint $ok");
}

