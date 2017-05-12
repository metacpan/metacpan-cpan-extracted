#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Varnish::CLI' ) || print "Bail out!
";
}

diag( "Testing Varnish::CLI $Varnish::CLI::VERSION, Perl $], $^X" );
