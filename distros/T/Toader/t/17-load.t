#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::Render::Directory::backends::html' ) || print "Bail out!
";
}

diag( "Testing Toader::Render::Directory::backends::html $Toader::Render::Directory::backends::html::VERSION, Perl $], $^X" );
