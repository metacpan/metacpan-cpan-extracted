#! /usr/bin/perl
#---------------------------------------------------------------------

use Test::More tests => 1;

BEGIN {
use_ok( 'Tie::CPHash' );
}

diag( "Testing Tie::CPHash $Tie::CPHash::VERSION" );
