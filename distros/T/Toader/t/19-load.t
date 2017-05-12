#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::Render::General' ) || print "Bail out!
";
}

diag( "Testing Toader::Render::General $Toader::Render::General::VERSION, Perl $], $^X" );
