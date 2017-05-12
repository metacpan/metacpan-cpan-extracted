# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;

BEGIN { use_ok( 'X11::IdleTime' ); }
require_ok( 'X11::IdleTime' );

$idle = GetIdleTime();

ok( defined $idle,	'GetIdleTime() returned something' );

#########################


