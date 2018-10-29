#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 4;

BEGIN {
    use_ok( 'WebService::HMRC' ) || print "Bail out!\n";
    use_ok( 'WebService::HMRC::Request' ) || print "Bail out!\n";
    use_ok( 'WebService::HMRC::Response' ) || print "Bail out!\n";
    use_ok( 'WebService::HMRC::Authenticate' ) || print "Bail out!\n";
}

diag( "Testing WebService::HMRC $WebService::HMRC::VERSION, Perl $], $^X" );
