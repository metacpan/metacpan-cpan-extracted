#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Test2::Tools::Explain' ) || print "Bail out!\n";
}

diag( "Testing Test2::Tools::Explain $Test2::Tools::Explain::VERSION, Perl $], $^X" );
