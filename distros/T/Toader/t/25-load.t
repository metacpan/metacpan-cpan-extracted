#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::pathHelper' ) || print "Bail out!
";
}

diag( "Testing Toader::pathHelper $Toader::pathHelper::VERSION, Perl $], $^X" );
