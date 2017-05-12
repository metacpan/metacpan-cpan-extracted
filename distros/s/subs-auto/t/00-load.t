#!perl -T

use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
 use_ok( 'subs::auto' );
}

diag( "Testing subs::auto $subs::auto::VERSION, Perl $], $^X" );
