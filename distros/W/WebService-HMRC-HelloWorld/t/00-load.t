#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'WebService::HMRC::HelloWorld' ) || print "Bail out!\n";
}

diag( "Testing WebService::HMRC::HelloWorld $WebService::HMRC::HelloWorld::VERSION, Perl $], $^X" );
