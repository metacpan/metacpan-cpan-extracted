#!/usr/bin/env perl

use Test::More tests => 3;

*CORE::GLOBAL::require = sub { die "foobar" };

BEGIN
{
	use_ok( 'nextgen' ) or exit;
	nextgen->import();
}

eval 'require "foo";';
like ( $@, qr/foobar/, 'died via the chained sub (require)' );

eval 'use foo;';
like ( $@, qr/foobar/, 'died via the chained sub (use)' );
