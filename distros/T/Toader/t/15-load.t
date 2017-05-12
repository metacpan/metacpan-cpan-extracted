#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::Render::Page::Cleanup' ) || print "Bail out!
";
}

diag( "Testing Toader::Render::Page::Cleanup $Toader::Render::Page::Cleanup::VERSION, Perl $], $^X" );
