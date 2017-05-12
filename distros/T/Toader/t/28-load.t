#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::Render::AutoDoc::Cleanup' ) || print "Bail out!
";
}

diag( "Testing Toader::Render::AutoDoc::Cleanup $Toader::Render::AutoDoc::Cleanup::VERSION, Perl $], $^X" );
