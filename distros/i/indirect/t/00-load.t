#!perl -T

use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
 use_ok( 'indirect' );
}

diag( "Testing indirect $indirect::VERSION, Perl $], $^X" );
