#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Yandex::Audience' ) || print "Bail out!\n";
}

diag( "Testing Yandex::Audience $Yandex::Audience::VERSION, Perl $], $^X" );
