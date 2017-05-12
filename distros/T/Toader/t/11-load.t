#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::Render::Directory::Cleanup' ) || print "Bail out!
";
}

diag( "Testing Toader::Render::Directory::Cleanup $Toader::Render::Directory::Cleanup::VERSION, Perl $], $^X" );
