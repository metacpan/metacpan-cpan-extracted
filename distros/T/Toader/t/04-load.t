#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::Entry' ) || print "Bail out!
";
}

diag( "Testing Toader::Entry $Toader::Entry::VERSION, Perl $], $^X" );
