#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::3Taps::API' ) || print "Bail out!
";
}

diag( "Testing WWW::3Taps::API $WWW::3Taps::API::VERSION, Perl $], $^X" );
