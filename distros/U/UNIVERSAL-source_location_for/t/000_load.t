#!perl -w
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok 'UNIVERSAL::source_location_for';
}

diag "Testing UNIVERSAL::source_location_for/$UNIVERSAL::source_location_for::VERSION";
