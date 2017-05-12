#!/usr/bin/env perl
#
use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More;

BEGIN {
    use_ok( 'URL::Normalize' ) || print "Bail out!\n";
}

diag( "Testing URL::Normalize $URL::Normalize::VERSION, Perl $], $^X" );

done_testing;
