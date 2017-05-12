#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;
use Test::Exception;

BEGIN { 
	# load our test library
	unshift @INC => qw(t/test_lib/ test_lib/);
	
	# now we start testing
	# test we can load generics
	use_ok('generics');
}

use Base;
use Session;

ok(!generics->has_generic_params("generics"), '... generics itself, does not have generic params');

# we try to load this module, and get an exception
# becuase Broken inherits from Base (TEST, TEST_2)
# and then tries to create TEST on its own, resulting
# in a duplicate parameter, and therefore an exception 
throws_ok{
	require Broken;
} qr/^generics exception/, '... this should die because of duplicate params';

# but we can still use the originals from Base
# they were succusfully installed into Broken
can_ok("Broken", 'TEST_2');
can_ok("Broken", 'TEST');

# now test Session and make sure that it dies if the 
# generics arent assigned to

# now create a session object
my $s = Session->new();
isa_ok($s, "Session");

throws_ok{
	$s->getTimeoutLength();
} qr/^generics exception/, '... this should die because of unassigned params';

throws_ok{
	$s->getSessionId();
} qr/^generics exception/, '... this should die because of unassigned params';


# now test what are basically syntax errors

throws_ok{
	require BrokenTwo;
} qr/^generics exception/, '... this should die because of messy params';

throws_ok{
	require BrokenThree;
} qr/^generics exception/, '... this should die because of messy params';


# test giving of bad params

throws_ok {
	generics->import("Session" => (TEST => 200)); 
} qr/^generics exception/, '... these are bad generic params';

