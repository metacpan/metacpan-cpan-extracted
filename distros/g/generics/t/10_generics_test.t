#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 14;

BEGIN { 
	# load our test library
	unshift @INC => qw(t/test_lib/ test_lib/);
	
	# now we start testing
	# test we can load generics
	use_ok('generics');

}

use Session;

BEGIN {
	can_ok("generics", 'has_generic_params');
	ok(generics->has_generic_params("Session"), '... session has generic params');
}

# assign the generics
use generics Session => (
	SESSION_TIMEOUT => 20,
	SESSION_ID_LENGTH => sub { 50 }
	);

# now create a session object
can_ok("Session", 'new');
my $s = Session->new();

isa_ok($s, "Session");

can_ok($s, 'getTimeoutLength');
cmp_ok($s->getTimeoutLength(), '==', 20, '... it should be 20');
cmp_ok($s->SESSION_TIMEOUT(), '==', 20, '... it should be 20');

can_ok($s, 'getSessionId');
my $session_id = $s->getSessionId();

ok($session_id, '... session id was succefully generated');

cmp_ok(length($session_id), '==', 50, '... it should be 50 characters long');
cmp_ok($s->SESSION_ID_LENGTH(), '==', 50, '... it should be 50');


# now examine the innards
can_ok("generics", 'dump_params');
my %params = generics->dump_params("Session");
ok(eq_hash(
		\%params,
		{
			SESSION_TIMEOUT => 20,
			SESSION_ID_LENGTH => 50
		}
		), '... the generics should be the same');
