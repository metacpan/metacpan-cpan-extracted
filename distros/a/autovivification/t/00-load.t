#!perl -T

use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
 use_ok( 'autovivification' );
}

diag( "Testing autovivification $autovivification::VERSION, Perl $], $^X" );
