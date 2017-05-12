#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::Render::Gallery' ) || print "Bail out!
";
}

diag( "Testing Toader::Render::Gallery $Toader::Render::Gallery::VERSION, Perl $], $^X" );
