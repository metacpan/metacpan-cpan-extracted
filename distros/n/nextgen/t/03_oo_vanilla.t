#!/usr/bin/env perl

use Test::More tests => 3;

BEGIN
{
	use_ok( 'nextgen' ) or exit;
	nextgen->import();
}


	package A;
	$A::VERSION = 1;

	package B;
	@B::ISA = 'A';

	package C;
	@C::ISA = 'A';

	package D;
	use nextgen;
	use Carp qw(croak);
	@D::ISA = qw( B C );
	sub new { bless \my $foo };

package main;

is_deeply( mro::get_linear_isa( 'D' ), [qw( D B C A )], 'mro should use C3' );

is ( D->new->can('croak') , undef, 'cleaned up stuff left from Croak' )
