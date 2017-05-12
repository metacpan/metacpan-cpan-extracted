#!perl -T
use 5.010001;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'WWW::Piwik::API' ) || print "Bail out!\n";
}

diag( "Testing WWW::Piwik::API $WWW::Piwik::API::VERSION, Perl $], $^X" );
