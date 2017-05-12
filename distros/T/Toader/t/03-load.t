#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::isaToaderDir' ) || print "Bail out!
";
}

diag( "Testing Toader::isaToaderDir $Toader::isaToaderDir::VERSION, Perl $], $^X" );
