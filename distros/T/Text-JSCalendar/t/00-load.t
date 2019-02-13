#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Text::JSCalendar' ) || print "Bail out!\n";
}

diag( "Testing Text::JSCalendar $Text::JSCalendar::VERSION, Perl $], $^X" );
