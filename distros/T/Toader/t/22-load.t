#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::Templates' ) || print "Bail out!
";
}

diag( "Testing Toader::Templates $Toader::Templates::VERSION, Perl $], $^X" );
