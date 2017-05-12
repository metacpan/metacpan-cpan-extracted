#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'WWW::Mechanize::Tor' ) || print "Bail out!\n";
}

diag( "Testing WWW::Mechanize::Tor $WWW::Mechanize::Tor::VERSION, Perl $], $^X" );
