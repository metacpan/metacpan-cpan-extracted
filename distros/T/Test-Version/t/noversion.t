#!/usr/bin/perl -T
use 5.006;
use strict;
use warnings;
use Test::Tester tests => 7;
use Test::Version version_ok => { ignore_unindexable => 0 };

check_test(
	sub {
		version_ok( 'corpus/noversion/FooBar.pm' );
	},
	{
		ok => 0,
		name => q[check version in 'corpus/noversion/FooBar.pm'],
		diag => q[No version was found in 'corpus/noversion/FooBar.pm' (FooBar).],
	},
	'no version'
);
