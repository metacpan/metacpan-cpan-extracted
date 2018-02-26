#!/usr/bin/perl -T
use 5.006;
use strict;
use warnings;
use Test::Tester tests => 8;
use Test::More;
use Test::Version version_ok => { ignore_unindexable => 0 };

my $ret;
check_test(
	sub {
		$ret = version_ok( 'corpus/fail/FooBarBaz.pm' );
	},
	{
		ok => 0,
		name => q[check version in 'corpus/fail/FooBarBaz.pm'],
		diag => qq[The version 'v.Inf' found in 'corpus/fail/FooBarBaz.pm' (FooBarBaz) is invalid.],
	},
	'version invalid'
);

ok !$ret, "version_ok() returned false on fail";
