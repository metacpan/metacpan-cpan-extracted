#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::Render::Directory::backends::pod' ) || print "Bail out!
";
}

diag( "Testing Toader::Render::Directory::backends::pod $Toader::Render::Directory::backends::pod::VERSION, Perl $], $^X" );
