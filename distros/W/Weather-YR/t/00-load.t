#!/usr/bin/env perl
#
use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Weather::YR' );
}

diag( "Testing Weather::YR $Weather::YR::VERSION, Perl $], $^X" );

done_testing;
