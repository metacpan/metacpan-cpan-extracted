#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::Render::Entry::Cleanup' ) || print "Bail out!
";
}

diag( "Testing Toader::Render::Entry::Cleanup $Toader::Render::Entry::Cleanup::VERSION, Perl $], $^X" );
