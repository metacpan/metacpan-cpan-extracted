#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::Page::Helper' ) || print "Bail out!
";
}

diag( "Testing Toader::Page::Helper $Toader::Page::Helper::VERSION, Perl $], $^X" );
