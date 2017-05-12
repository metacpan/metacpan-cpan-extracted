#!/usr/bin/perl
use 5.006;
use strict;
use warnings;
use Test::Tester tests => 8;
use Test::More;
use Test::Version version_ok => { ignore_unindexable => 0 };

my $ret;
check_test(
	sub {
		$ret = version_ok( 'corpus/pass/Foo.pm' );
	},
	{
		ok => 1,
		name => q[check version in 'corpus/pass/Foo.pm'],
		diag => '',
	},
	'version ok'
);

ok $ret, "version_ok() returned true on pass";
