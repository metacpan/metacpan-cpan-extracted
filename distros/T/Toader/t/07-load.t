#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::Page' ) || print "Bail out!
";
}

diag( "Testing Toader::Page $Toader::Page::VERSION, Perl $], $^X" );
