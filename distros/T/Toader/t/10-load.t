#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::Render' ) || print "Bail out!
";
}

diag( "Testing Toader::Render $Toader::Render::VERSION, Perl $], $^X" );
