#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Text::CSV::Easy_XS' ) || print "Bail out!\n";
}

diag( "Testing Text::CSV::Easy_XS $Text::CSV::Easy_XS::VERSION, Perl $], $^X" );
