#! perl -w
use strict;

# $Id$

use Config;

use Test::More tests => 3;
BEGIN { use_ok( 'Test::Smoke::Util', 'get_ncpu' ); }

ok( defined &get_ncpu, "get_ncpu() is defined" );
SKIP: {
    my $ncpu = get_ncpu( $Config{osname} );
    skip "OS does not seem to be supported ($Config{osname})", 1
        unless $ncpu;
    like( $ncpu, '/^\d+/', "Found: $ncpu" );
}


