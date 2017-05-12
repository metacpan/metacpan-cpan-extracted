#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'WWW::Yandex::PDD' ) || print "Bail out!\n";
}

diag( "Testing WWW::Yandex::PDD $WWW::Yandex::PDD::VERSION, Perl $], $^X" );
