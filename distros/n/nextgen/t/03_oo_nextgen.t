#!/usr/bin/env perl

use Test::More tests => 3;

BEGIN {
	use_ok( 'nextgen' ) or exit;
	nextgen->import();
}

	package A;
	use nextgen;

	package B;
	use nextgen;
	extends qw(A);

	package C;
	use nextgen;
	extends qw(A);

	package D;
	use nextgen;
	extends qw(B C);

	use File::Basename qw(basename);

package main;

is_deeply( mro::get_linear_isa( 'D' ), [qw( D B C A Moose::Object)], 'mro should use C3' );

is ( D->new->can('basename') , undef, 'cleaned up File::Basename stuff' )
