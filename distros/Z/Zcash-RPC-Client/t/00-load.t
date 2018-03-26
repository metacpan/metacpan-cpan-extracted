#!perl -T
use 5.006;
use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok( 'Zcash::RPC::Client' ) || print "Bail out!\n";
}

diag( "Testing Zcash::RPC::Client $Zcash::RPC::Client::VERSION, Perl $], $^X" );
