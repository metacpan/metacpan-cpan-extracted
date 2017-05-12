#!/usr/bin/perl -T

use Test::More 'no_plan';

BEGIN {
    use_ok( 'WWW::EchoNest' ); # || print "Bail out!\n";
}
diag( "Testing WWW::EchoNest $WWW::EchoNest::VERSION, Perl $], $^X" );
