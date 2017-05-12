#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::findToaderRoot' ) || print "Bail out!
";
}

diag( "Testing Toader::findToaderRoot $Toader::findToaderRoot::VERSION, Perl $], $^X" );
