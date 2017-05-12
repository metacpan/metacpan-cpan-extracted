#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::Render::Page::backends::pod' ) || print "Bail out!
";
}

diag( "Testing Toader::Render::Page::backends::pod $Toader::Render::Page::backends::pod::VERSION, Perl $], $^X" );
