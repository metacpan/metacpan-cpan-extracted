#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'WebService::Bitly' ) || print "Bail out!
";
    use_ok( 'WebService::Bitly' ) || print "Bail out!
";
}

diag( "Testing WebService::Bitly $WebService::Bitly::VERSION, Perl $], $^X" );
