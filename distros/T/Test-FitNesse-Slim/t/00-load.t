#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::FitNesse::Slim' ) || print "Bail out!
";
}

diag( "Testing Test::FitNesse::Slim $Test::FitNesse::Slim::VERSION, Perl $], $^X" );
