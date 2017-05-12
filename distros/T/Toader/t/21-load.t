#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::Config' ) || print "Bail out!
";
}

diag( "Testing Toader::Config $Toader::Config::VERSION, Perl $], $^X" );
