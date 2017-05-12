#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::Render::CSS' ) || print "Bail out!
";
}

diag( "Testing Toader::Render::CSS $Toader::Render::CSS::VERSION, Perl $], $^X" );
