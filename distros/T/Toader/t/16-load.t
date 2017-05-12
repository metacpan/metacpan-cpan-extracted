#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::Render::Page::backends::html' ) || print "Bail out!
";
}

diag( "Testing Toader::Render::Page::backends::html $Toader::Render::Page::backends::html::VERSION, Perl $], $^X" );
