#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'WebService::HMRC::VAT' ) || print "Bail out!\n";
}

diag( "Testing WebService::HMRC::VAT $WebService::HMRC::VAT::VERSION, Perl $], $^X" );
