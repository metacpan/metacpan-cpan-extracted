#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::Render::Entry::backends::html' ) || print "Bail out!
";
}

diag( "Testing Toader::Render::Entry::backends::html $Toader::Render::Entry::backends::html::VERSION, Perl $], $^X" );
