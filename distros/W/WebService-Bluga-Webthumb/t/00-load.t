#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WebService::Bluga::Webthumb' ) || print "Bail out!
";
}

diag( "Testing WebService::Bluga::Webthumb $WebService::Bluga::Webthumb::VERSION, Perl $], $^X" );
