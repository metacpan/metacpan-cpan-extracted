#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::findToaderDirs' ) || print "Bail out!
";
}

diag( "Testing Toader::findToaderDirs $Toader::findToaderDirs::VERSION, Perl $], $^X" );
