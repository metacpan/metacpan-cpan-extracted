#!/usr/bin/perl -w

# Load test the Test::Object module

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'arch'),
			catdir('blib', 'lib' ),
			catdir('lib'),
			);
	}
}

use Test::Builder::Tester tests => 2;
use Test::More;
use Test::Object;






#####################################################################
# Single Class - Single Registration

SCOPE: {
	package Foo;
	sub new { bless {}, shift }
	sub foo { 'bar' }
	1;
}

Test::Object->register(
	class => 'Foo',
	tests => 1,
	code  => sub { is( $_[0]->foo, 'bar', '->foo is bar' ) },
);

my $object = Foo->new;
isa_ok( $object, 'Foo' );
test_out("ok 1 - ->foo is bar");
object_ok( $object );
test_test("Single Class - Single Registration - OK");

1;
