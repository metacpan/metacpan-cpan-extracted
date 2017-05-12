#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 17;

BEGIN { 
	# load our test library
	unshift @INC => qw(t/test_lib/ test_lib/);
	
	# now we start testing
	# test we can load generics
	use_ok('generics');
}

use Base;
use Derived;

BEGIN {
	ok(generics->has_generic_params("Base"), '... Derived has generic params');
	ok(generics->has_generic_params("Derived"), '... Derived has generic params');
}

# assign the generics

use generics Derived => (
	TEST => 500,
	DERIVED_TEST => [ 1 .. 10 ]
	);

# now create a derived session object
can_ok("Derived", 'new');
my $d = Derived->new();

isa_ok($d, "Base");

can_ok($d, 'TEST');
cmp_ok($d->TEST(), '==', 500, '... it should be 500');

can_ok($d, 'TEST_2');
is($d->TEST_2(), "Hello World", '... it should be "Hello World"');

can_ok($d, 'DERIVED_TEST');
ok(eq_array($d->DERIVED_TEST(), [1 .. 10]), '... it should be the same array');

# now create a session object
can_ok("Base", 'new');
my $b = Base->new();

isa_ok($b, "Base");

can_ok($d, 'TEST');
cmp_ok($b->TEST(), '==', 100, '... it should be 100');

can_ok($b, 'TEST_2');
is($b->TEST_2(), "Hello World", '... it should be "Hello World"');

