#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::AutoDoc' ) || print "Bail out!
";
}

diag( "Testing Toader::AutoDoc $Toader::AutoDoc::VERSION, Perl $], $^X" );
