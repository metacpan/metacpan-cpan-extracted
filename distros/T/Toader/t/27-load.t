#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::Render::AutoDoc' ) || print "Bail out!
";
}

diag( "Testing Toader::Render::AutoDoc $Toader::Render::AutoDoc::VERSION, Perl $], $^X" );
