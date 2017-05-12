#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader' ) || print "Bail out!
";
}

diag( "Testing Toader $Toader::VERSION, Perl $], $^X" );
