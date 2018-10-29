#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'WebService::HMRC::CreateTestUser' ) || print "Bail out!\n";
}

diag( "Testing WebService::HMRC::CreateTestUser $WebService::HMRC::CreateTestUser::VERSION, Perl $], $^X" );
